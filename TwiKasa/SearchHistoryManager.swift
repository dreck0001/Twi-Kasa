import Foundation
import Combine
import FirebaseAuth
import FirebaseFirestore

class SearchHistoryManager: ObservableObject {
    static let shared = SearchHistoryManager()
    
    @Published private(set) var recentSearches: [Word] = []
    @Published private(set) var isSyncing = false
    
    private let historyKey = "searchHistory"
    private let maxHistoryCount = 20
    private let db = Firestore.firestore()
    private var authStateHandle: AuthStateDidChangeListenerHandle?
    
    private init() {
        loadLocalHistory()
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
                // User signed in - sync with cloud
                Task {
                    await self.syncWithCloud(userId: user.uid)
                }
            }
            // On sign out, we keep local history
        }
    }
    
    // MARK: - Local Storage
    
    private func loadLocalHistory() {
        guard let wordIds = UserDefaults.standard.stringArray(forKey: historyKey) else {
            return
        }
        
        // Fetch full Word objects from Firestore
        Task {
            var words: [Word] = []
            for wordId in wordIds.prefix(maxHistoryCount) {
                do {
                    if let word = try await getWordFromCache(id: wordId) {
                        words.append(word)
                    }
                } catch {
                    print("Failed to load word \(wordId): \(error.localizedDescription)")
                }
            }
            
            await MainActor.run {
                self.recentSearches = words
            }
        }
    }
    
    private func saveLocalHistory() {
        let wordIds = recentSearches.map { $0.id }
        UserDefaults.standard.set(wordIds, forKey: historyKey)
    }
    
    // MARK: - Cloud Sync
    
    private func syncWithCloud(userId: String) async {
        await MainActor.run {
            isSyncing = true
        }
        
        do {
            // Fetch cloud history
            let cloudIds = try await fetchCloudHistory(userId: userId)
            
            // Merge: cloud + local, preserving order
            let localIds = recentSearches.map { $0.id }
            var mergedIds: [String] = localIds
            
            // Add cloud IDs that aren't in local
            for cloudId in cloudIds where !mergedIds.contains(cloudId) {
                mergedIds.append(cloudId)
            }
            
            // Limit to max count
            mergedIds = Array(mergedIds.prefix(maxHistoryCount))
            
            // Fetch full Word objects
            var words: [Word] = []
            for wordId in mergedIds {
                if let word = try await getWordFromCache(id: wordId) {
                    words.append(word)
                }
            }
            
            await MainActor.run {
                self.recentSearches = words
                self.saveLocalHistory()
            }
            
            // Update cloud with merged history
            try await saveToCloud(userId: userId, wordIds: mergedIds)
            
            await MainActor.run {
                isSyncing = false
            }
        } catch {
            print("Search history sync error: \(error.localizedDescription)")
            await MainActor.run {
                isSyncing = false
            }
        }
    }
    
    private func fetchCloudHistory(userId: String) async throws -> [String] {
        let snapshot = try await db.collection("users")
            .document(userId)
            .collection("searchHistory")
            .order(by: "searchedAt", descending: true)
            .limit(to: maxHistoryCount)
            .getDocuments()
        
        return snapshot.documents.compactMap { doc in
            doc.data()["wordId"] as? String
        }
    }
    
    private func saveToCloud(userId: String, wordIds: [String]) async throws {
        let historyRef = db.collection("users").document(userId).collection("searchHistory")
        
        // Delete all existing entries first (simpler than selective update)
        let snapshot = try await historyRef.getDocuments()
        for doc in snapshot.documents {
            try await doc.reference.delete()
        }
        
        // Add new entries with timestamps
        let batch = db.batch()
        for (index, wordId) in wordIds.enumerated() {
            let docRef = historyRef.document(wordId)
            // Use decreasing timestamps so order is preserved
            let timestamp = Date().addingTimeInterval(-Double(index))
            batch.setData([
                "wordId": wordId,
                "searchedAt": Timestamp(date: timestamp)
            ], forDocument: docRef)
        }
        
        try await batch.commit()
    }
    
    // MARK: - Helper Methods
    
    private func getWordFromCache(id: String) async throws -> Word? {
        // Try to get from existing recentSearches first (cache)
        if let cached = recentSearches.first(where: { $0.id == id }) {
            return cached
        }
        
        // Otherwise fetch from Firestore
        let document = try await db.collection("words").document(id).getDocument()
        return try? document.data(as: Word.self)
    }
    
    // MARK: - Public Methods
    
    /// Add a word to search history
    func addSearch(_ word: Word) {
        // Remove if already exists (to move to top)
        recentSearches.removeAll { $0.id == word.id }
        
        // Add to beginning
        recentSearches.insert(word, at: 0)
        
        // Limit to max count
        if recentSearches.count > maxHistoryCount {
            recentSearches = Array(recentSearches.prefix(maxHistoryCount))
        }
        
        // Save locally immediately (fast)
        saveLocalHistory()
        
        // Sync to cloud in background (if signed in)
        syncToCloudIfNeeded()
    }
    
    /// Remove a specific word from history
    func removeSearch(_ word: Word) {
        recentSearches.removeAll { $0.id == word.id }
        saveLocalHistory()
        syncToCloudIfNeeded()
    }
    
    /// Clear all search history
    func clearHistory() {
        recentSearches.removeAll()
        UserDefaults.standard.removeObject(forKey: historyKey)
        
        // Clear cloud history if signed in
        guard let user = Auth.auth().currentUser, !user.isAnonymous else {
            return
        }
        
        Task {
            do {
                let snapshot = try await db.collection("users")
                    .document(user.uid)
                    .collection("searchHistory")
                    .getDocuments()
                
                for doc in snapshot.documents {
                    try await doc.reference.delete()
                }
            } catch {
                print("Failed to clear cloud history: \(error.localizedDescription)")
            }
        }
    }
    
    /// Clear local history on sign out (optional - call if desired)
    func clearLocalOnSignOut() {
        recentSearches.removeAll()
        UserDefaults.standard.removeObject(forKey: historyKey)
    }
    
    /// Refresh history from cloud (call on pull-to-refresh)
    func refreshFromCloud() async {
        guard let user = Auth.auth().currentUser, !user.isAnonymous else {
            return
        }
        
        await syncWithCloud(userId: user.uid)
    }
    
    /// Check if a word is in recent searches
    func isInHistory(_ word: Word) -> Bool {
        recentSearches.contains { $0.id == word.id }
    }
    
    /// Get history as array of word IDs
    func getHistoryIds() -> [String] {
        recentSearches.map { $0.id }
    }
    
    // MARK: - Private Sync Helper
    
    private func syncToCloudIfNeeded() {
        guard let user = Auth.auth().currentUser, !user.isAnonymous else {
            return
        }
        
        Task {
            do {
                let wordIds = recentSearches.map { $0.id }
                try await saveToCloud(userId: user.uid, wordIds: wordIds)
            } catch {
                print("Failed to sync search history: \(error.localizedDescription)")
            }
        }
    }
}
