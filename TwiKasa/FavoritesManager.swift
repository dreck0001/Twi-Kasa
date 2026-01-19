import Foundation
import Combine

class FavoritesManager: ObservableObject {
    static let shared = FavoritesManager()
    
    @Published private(set) var favoriteIds: Set<String> = []
    
    private let favoritesKey = "userFavorites"
    
    private init() {
        loadFavorites()
    }
    
    private func loadFavorites() {
        if let data = UserDefaults.standard.data(forKey: favoritesKey),
           let decoded = try? JSONDecoder().decode(Set<String>.self, from: data) {
            favoriteIds = decoded
        }
    }
    
    private func saveFavorites() {
        if let encoded = try? JSONEncoder().encode(favoriteIds) {
            UserDefaults.standard.set(encoded, forKey: favoritesKey)
        }
    }
    
    func toggleFavorite(_ entryId: String) {
        if favoriteIds.contains(entryId) {
            favoriteIds.remove(entryId)
        } else {
            favoriteIds.insert(entryId)
        }
        saveFavorites()
    }
    
    func isFavorited(_ entryId: String) -> Bool {
        favoriteIds.contains(entryId)
    }
    
    func getAllFavoriteIds() -> [String] {
        Array(favoriteIds)
    }
    
    func removeFavorite(_ entryId: String) {
        favoriteIds.remove(entryId)
        saveFavorites()
    }
    
    func clearAll() {
        favoriteIds.removeAll()
        saveFavorites()
    }
}
