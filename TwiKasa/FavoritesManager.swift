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
    
    func toggleFavorite(_ wordId: String) {
        if favoriteIds.contains(wordId) {
            favoriteIds.remove(wordId)
        } else {
            favoriteIds.insert(wordId)
            TrendingService.shared.trackFavorite(wordId)
        }
        saveFavorites()
    }
    
    func isFavorited(_ wordId: String) -> Bool {
        favoriteIds.contains(wordId)
    }
    
    func getAllFavoriteIds() -> [String] {
        Array(favoriteIds)
    }
    
    func removeFavorite(_ wordId: String) {
        favoriteIds.remove(wordId)
        saveFavorites()
    }
    
    func clearAll() {
        favoriteIds.removeAll()
        saveFavorites()
    }
}
