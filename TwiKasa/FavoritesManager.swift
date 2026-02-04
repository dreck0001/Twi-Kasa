import Foundation
import Combine
import FirebaseAuth
import FirebaseFirestore

class FavoritesManager: ObservableObject {
    static let shared = FavoritesManager()
    
    @Published private(set) var favoriteIds: Set<String> = []
    @Published private(set) var isSyncing = false
    
    private let favoritesKey = "userFavorites"
    private let db = Firestore.firestore()
    private var authStateHandle: AuthStateDidChangeListenerHandle?
    
    private init() {
        loadLocalFavorites()
        setupAuthListener()
    }
    
    deinit {
        if let handle = authStateHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }
    
    // MARK: - Auth State Listener
    
    private func setupAuthListener() {
        authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self = self else { return }
            
            if let user = user, !user.isAnonymous {
                // user signed in - merge favorites
                Task {
                    await self.mergeWithCloud(userId: user.uid)
                }
            }
            // on sign out, we keep local favorites (they're backed up in cloud)
        }
    }
    
    // MARK: - Local Storage
    
    private func loadLocalFavorites() {
        if let data = UserDefaults.standard.data(forKey: favoritesKey),
           let decoded = try? JSONDecoder().decode(Set<String>.self, from: data) {
            favoriteIds = decoded
        }
    }
    
    private func saveLocalFavorites() {
        if let encoded = try? JSONEncoder().encode(favoriteIds) {
            UserDefaults.standard.set(encoded, forKey: favoritesKey)
        }
    }
    
    private func clearLocalFavorites() {
        favoriteIds.removeAll()
        UserDefaults.standard.removeObject(forKey: favoritesKey)
    }
    
    // MARK: - Cloud Sync
    
    private func mergeWithCloud(userId: String) async {
        await MainActor.run {
            isSyncing = true
        }
        
        do {
            // fetch cloud favorites
            let cloudFavorites = try await fetchCloudFavorites(userId: userId)
            
            // merge: union of local and cloud
            let merged = favoriteIds.union(cloudFavorites)
            
            // save merged to both local and cloud
            await MainActor.run {
                favoriteIds = merged
                saveLocalFavorites()
            }
            
            // update cloud with merged set
            try await saveToCloud(userId: userId, favorites: merged)
            
            await MainActor.run {
                isSyncing = false
            }
        } catch {
            print("Favorites sync error: \(error.localizedDescription)")
            await MainActor.run {
                isSyncing = false
            }
        }
    }
    
    private func fetchCloudFavorites(userId: String) async throws -> Set<String> {
        let document = try await db.collection("users").document(userId).getDocument()
        
        guard let data = document.data(),
              let favoritesArray = data["favorites"] as? [String] else {
            return []
        }
        
        return Set(favoritesArray)
    }
    
    private func saveToCloud(userId: String, favorites: Set<String>) async throws {
        try await db.collection("users").document(userId).setData([
            "favorites": Array(favorites),
            "updatedAt": FieldValue.serverTimestamp()
        ], merge: true)
    }
    
    // MARK: - Public Methods
    
    func toggleFavorite(_ wordId: String) {
        if favoriteIds.contains(wordId) {
            favoriteIds.remove(wordId)
        } else {
            favoriteIds.insert(wordId)
            TrendingService.shared.trackFavorite(wordId)
        }
        saveLocalFavorites()
        
        // sync to cloud if signed in
        syncToCloudIfNeeded()
    }
    
    func isFavorited(_ wordId: String) -> Bool {
        favoriteIds.contains(wordId)
    }
    
    func getAllFavoriteIds() -> [String] {
        Array(favoriteIds)
    }
    
    func removeFavorite(_ wordId: String) {
        favoriteIds.remove(wordId)
        saveLocalFavorites()
        syncToCloudIfNeeded()
    }
    
    func clearAll() {
        favoriteIds.removeAll()
        saveLocalFavorites()
        syncToCloudIfNeeded()
    }
    
    /// Call this on sign out if you want to clear local favorites
    func clearLocalOnSignOut() {
        clearLocalFavorites()
    }
    
    /// Refresh favorites from cloud (call on pull-to-refresh or app foreground)
    func refreshFromCloud() async {
        guard let user = Auth.auth().currentUser, !user.isAnonymous else {
            return
        }
        
        await MainActor.run {
            isSyncing = true
        }
        
        do {
            let cloudFavorites = try await fetchCloudFavorites(userId: user.uid)
            
            await MainActor.run {
                favoriteIds = cloudFavorites
                saveLocalFavorites()
                isSyncing = false
            }
        } catch {
            print("Failed to refresh favorites: \(error.localizedDescription)")
            await MainActor.run {
                isSyncing = false
            }
        }
    }
    
    private func syncToCloudIfNeeded() {
        guard let user = Auth.auth().currentUser, !user.isAnonymous else {
            return
        }
        
        Task {
            do {
                try await saveToCloud(userId: user.uid, favorites: favoriteIds)
            } catch {
                print("Failed to sync favorites: \(error.localizedDescription)")
            }
        }
    }
}
