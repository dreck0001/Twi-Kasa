//
//  FavoritesView.swift
//  TwiKasa
//
//  Only updates when view appears, not when favorites change in background
//

import SwiftUI
import FirebaseAuth

struct FavoritesView: View {
    @StateObject private var firestoreService = FirestoreService()
    @ObservedObject private var favoritesManager = FavoritesManager.shared
    @State private var favoriteWords: [Word] = []
    @State private var isLoading = false
    
    private var isSignedIn: Bool {
        guard let user = Auth.auth().currentUser else { return false }
        return !user.isAnonymous
    }
    
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
            .toolbar {
                if !isSignedIn && !favoriteWords.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        NavigationLink {
                            SignInView()
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.triangle.2.circlepath")
                                    .font(.caption)
                                Text("Sync")
                                    .font(.caption)
                            }
                            .foregroundColor(.blue)
                        }
                    }
                }
            }
            .onAppear {
                // only reload when view appears (user navigates back)
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
        ScrollView {
            VStack(spacing: 20) {
                Spacer()
                    .frame(height: 100)
                
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
                
                if !isSignedIn {
                    Text("Sign in to sync across devices")
                        .font(.caption)
                        .foregroundColor(.blue)
                        .padding(.top, 8)
                }
                
                Spacer()
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: UIScreen.main.bounds.height - 200)
        }
        .refreshable {
            await favoritesManager.refreshFromCloud()
            await loadFavorites()
        }
    }
    
    private var favoritesList: some View {
        List {
            ForEach(favoriteWords) { word in
                NavigationLink {
                    WordDetailView(word: word)
                } label: {
                    FavoriteWordRow(word: word)
                }
            }
            .onDelete(perform: deleteFavorites)
        }
        .listStyle(.plain)
        .refreshable {
            await favoritesManager.refreshFromCloud()
            await loadFavorites()
        }
    }
    
    private func loadFavorites() async {
        // if no favorites, show empty state immediately
        if favoritesManager.favoriteIds.isEmpty {
            await MainActor.run {
                favoriteWords = []
                isLoading = false
            }
            return
        }
        
        // only show loading spinner if we have nothing to show yet
        if favoriteWords.isEmpty {
            await MainActor.run {
                isLoading = true
            }
        }
        
        var words: [Word] = []
        
        for wordId in favoritesManager.getAllFavoriteIds() {
            do {
                if let word = try await firestoreService.getWord(id: wordId) {
                    words.append(word)
                }
            } catch {
                continue
            }
        }
        
        await MainActor.run {
            favoriteWords = words.sorted { $0.headword < $1.headword }
            isLoading = false
        }
    }
    
    private func deleteFavorites(at offsets: IndexSet) {
        let wordsToDelete = offsets.map { favoriteWords[$0] }
        favoriteWords.remove(atOffsets: offsets)
        
        for word in wordsToDelete {
            favoritesManager.removeFavorite(word.id)
        }
    }
}

struct FavoriteWordRow: View {
    let word: Word
    
    private var uniquePartsOfSpeech: [String] {
        var seen = Set<String>()
        return word.definitions.compactMap { def in
            let pos = def.partOfSpeech
            if seen.contains(pos) { return nil }
            seen.insert(pos)
            return pos
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(word.headword)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                if !word.ipa.isEmpty {
                    Text("/\(word.ipa)/")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            if let firstDef = word.definitions.first {
                Text(firstDef.enDefinition)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            HStack(spacing: 4) {
                ForEach(uniquePartsOfSpeech, id: \.self) { pos in
                    Text(pos)
                        .font(.caption2)
                        .foregroundColor(.red.opacity(0.8))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(6)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    FavoritesView()
}
