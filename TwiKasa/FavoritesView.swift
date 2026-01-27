import SwiftUI

struct FavoritesView: View {
    @StateObject private var firestoreService = FirestoreService()
    @ObservedObject private var favoritesManager = FavoritesManager.shared
    @State private var favoriteWords: [Word] = []
    @State private var isLoading = false
    
    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    loadingView
                } else if favoriteWords.isEmpty {
                    emptyStateView
                } else {
                    favoritesList
                }
            }
            .navigationTitle("Favorites")
            .onAppear {
                Task {
                    await loadFavorites()
                }
            }
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            Text("Loading favorites...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "star.fill")
                .font(.system(size: 64))
                .foregroundColor(.yellow)
            
            Text("No Favorites Yet")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Tap the star on any word to save it here")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var favoritesList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(favoriteWords) { word in
                    NavigationLink(value: word) {
                        HorizontalWordCard(word: word)
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button(role: .destructive) {
                            removeFavoriteFromList(word)
                        } label: {
                            Label("Remove from Favorites", systemImage: "star.slash")
                        }
                    }
                }
            }
            .padding()
        }
        .navigationDestination(for: Word.self) { word in
            WordDetailView(word: word)
        }
    }
    
    private func loadFavorites() async {
        if favoritesManager.favoriteIds.isEmpty {
            await MainActor.run {
                favoriteWords = []
                isLoading = false
            }
            return
        }
        
        await MainActor.run {
            isLoading = true
        }
        
        do {
            var words: [Word] = []
            
            for wordId in favoritesManager.getAllFavoriteIds() {
                if let word = try await firestoreService.getWord(id: wordId) {
                    words.append(word)
                }
            }
            
            await MainActor.run {
                favoriteWords = words.sorted { $0.headword < $1.headword }
                isLoading = false
            }
        } catch {
            await MainActor.run {
                favoriteWords = []
                isLoading = false
            }
        }
    }
    
    private func removeFavoriteFromList(_ word: Word) {
        favoriteWords.removeAll { $0.id == word.id }
        favoritesManager.removeFavorite(word.id)
        
        if favoriteWords.isEmpty {
            Task {
                await loadFavorites()
            }
        }
    }
}

#Preview {
    FavoritesView()
}
