import SwiftUI

struct FavoritesView: View {
    @StateObject private var firestoreService = FirestoreService()
    @ObservedObject private var favoritesManager = FavoritesManager.shared
    @State private var favoriteEntries: [Entry] = []
    @State private var isLoading = false
    
    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    loadingView
                } else if favoriteEntries.isEmpty {
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
                ForEach(favoriteEntries) { entry in
                    NavigationLink(value: entry) {
                        HorizontalWordCard(entry: entry)
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button(role: .destructive) {
                            removeFavoriteFromList(entry)
                        } label: {
                            Label("Remove from Favorites", systemImage: "star.slash")
                        }
                    }
                }
            }
            .padding()
        }
        .navigationDestination(for: Entry.self) { entry in
            EntryDetailView(entry: entry)
        }
    }
    
    private func loadFavorites() async {
        if favoritesManager.favoriteIds.isEmpty {
            await MainActor.run {
                favoriteEntries = []
                isLoading = false
            }
            return
        }
        
        await MainActor.run {
            isLoading = true
        }
        
        do {
            var entries: [Entry] = []
            
            for entryId in favoritesManager.getAllFavoriteIds() {
                if let entry = try await firestoreService.getEntry(id: entryId) {
                    entries.append(entry)
                }
            }
            
            await MainActor.run {
                favoriteEntries = entries.sorted { $0.headword < $1.headword }
                isLoading = false
            }
        } catch {
            await MainActor.run {
                favoriteEntries = []
                isLoading = false
            }
        }
    }
    
    private func removeFavoriteFromList(_ entry: Entry) {
        favoriteEntries.removeAll { $0.id == entry.id }
        favoritesManager.removeFavorite(entry.id)
        
        if favoriteEntries.isEmpty {
            Task {
                await loadFavorites()
            }
        }
    }
}

#Preview {
    FavoritesView()
}
