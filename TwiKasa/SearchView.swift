//
//  SearchView.swift
//  TwiKasa
//
//  Created by Throw Catchers on 1/12/26.
//

import SwiftUI

struct SearchView: View {
    @StateObject private var firestoreService = FirestoreService()
    @EnvironmentObject private var deepLinkManager: DeepLinkManager
    @State private var searchText = ""
    @State private var searchResults: [Entry] = []
    @State private var isSearching = false
    @State private var selectedEntry: Entry?
    @State private var searchTask: Task<Void, Never>?
    @State private var trendingWords: [Entry] = []
    @State private var recentSearches: [Entry] = []
    @State private var isLoadingTrending = false
    @State private var lastTrendingRefresh: Date?
    @State private var navigationPath = NavigationPath()
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            VStack(spacing: 0) {
                searchBar
                
                if isSearching {
                    loadingView
                } else if searchText.isEmpty {
                    emptyStateView
                } else if searchResults.isEmpty {
                    noResultsView
                } else {
                    resultsList
                }
            }
            .navigationTitle("Dictionary")
            .navigationBarTitleDisplayMode(.large)
            .navigationDestination(for: Entry.self) { entry in
                EntryDetailView(entry: entry)
                    .onAppear {
                        saveRecentSearch(entry)
                    }
            }
            .task {
                let shouldRefresh = trendingWords.isEmpty || {
                    guard let lastRefresh = lastTrendingRefresh else { return true }
                    return Date().timeIntervalSince(lastRefresh) > 3600
                }()
                
                if shouldRefresh {
                    loadTrendingWords()
                }
                
                loadRecentSearches()
            }
            .onChange(of: deepLinkManager.pendingEntryId) { _, entryId in
                guard let entryId = entryId else { return }
                handleDeepLink(entryId: entryId)
            }
            .onAppear {
                if let entryId = deepLinkManager.pendingEntryId {
                    handleDeepLink(entryId: entryId)
                }
            }
        }
        .tint(.red.opacity(0.8))
    }
    
    private var searchBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField("Search Twi words...", text: $searchText)
                .textFieldStyle(.plain)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .onChange(of: searchText) { oldValue, newValue in
                    searchTask?.cancel()
                    
                    searchTask = Task {
                        try? await Task.sleep(for: .milliseconds(300))
                        
                        if !Task.isCancelled {
                            await performSearch(query: newValue)
                        }
                    }
                }
            
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                    searchResults = []
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
        .padding(.top, 8)
    }
    
    private var resultsList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(searchResults) { entry in
                    NavigationLink(value: entry) {
                        HorizontalWordCard(entry: entry)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            Text("Searching...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyStateView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                if !recentSearches.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Recent")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(recentSearches) { entry in
                                    NavigationLink(value: entry) {
                                        WordCard(entry: entry)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                }
                
                VStack(alignment: .leading, spacing: 16) {
                    Text("Trending")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    if isLoadingTrending {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else if trendingWords.isEmpty {
                        Text("No trending words yet")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    } else {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(trendingWords) { entry in
                                    NavigationLink(value: entry) {
                                        WordCard(entry: entry)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                }
            }
            .padding()
        }
    }
    
    private var noResultsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "questionmark.circle")
                .font(.system(size: 48))
                .foregroundColor(.gray.opacity(0.5))
            
            Text("No results for \"\(searchText)\"")
                .font(.headline)
            
            Text("Try a different word or check your spelling")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    private func performSearch(query: String) async {
        guard !query.isEmpty else {
            await MainActor.run {
                searchResults = []
                isSearching = false
            }
            return
        }
        
        await MainActor.run {
            isSearching = true
        }
        
        do {
            let results = try await firestoreService.searchWords(query: query)
            
            await MainActor.run {
                searchResults = results
                isSearching = false
            }
        } catch {
            await MainActor.run {
                searchResults = []
                isSearching = false
            }
        }
    }
    
    private func handleDeepLink(entryId: String) {
        Task {
            if let entry = try? await firestoreService.getEntry(id: entryId) {
                await MainActor.run {
                    navigationPath.append(entry)
                    deepLinkManager.clearPending()
                }
            } else {
                await MainActor.run {
                    deepLinkManager.clearPending()
                }
            }
        }
    }
    
    private func loadTrendingWords() {
        isLoadingTrending = true
        Task {
            do {
                let words = try await firestoreService.getCommonWords(limit: 10)
                await MainActor.run {
                    trendingWords = words
                    lastTrendingRefresh = Date()
                    isLoadingTrending = false
                }
            } catch {
                await MainActor.run {
                    isLoadingTrending = false
                }
            }
        }
    }
    
    private func loadRecentSearches() {
        if let data = UserDefaults.standard.data(forKey: "recentSearches"),
           let decoded = try? JSONDecoder().decode([Entry].self, from: data) {
            recentSearches = Array(decoded.prefix(5))
        }
    }
    
    private func saveRecentSearch(_ entry: Entry) {
        var recents = recentSearches
        recents.removeAll { $0.id == entry.id }
        recents.insert(entry, at: 0)
        recents = Array(recents.prefix(5))
        
        if let encoded = try? JSONEncoder().encode(recents) {
            UserDefaults.standard.set(encoded, forKey: "recentSearches")
        }
        
        recentSearches = recents
    }
}

struct HorizontalWordCard: View {
    let entry: Entry
    
    private var uniquePartsOfSpeech: [String] {
        var seen = Set<String>()
        return entry.definitions.compactMap { def in
            let pos = def.partOfSpeech
            if seen.contains(pos) { return nil }
            seen.insert(pos)
            return pos
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(entry.headword)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                if !entry.ipa.isEmpty {
                    Text("[\(entry.ipa)]")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if let firstDef = entry.definitions.first {
                    Text(firstDef.enDefinition)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                    
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
            }
            
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity)
        .frame(height: 100)
        .background(Color(.systemGray6).opacity(0.5))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.systemGray4), lineWidth: 1)
        )
    }
}

struct WordCard: View {
    let entry: Entry
    
    private var uniquePartsOfSpeech: [String] {
        var seen = Set<String>()
        return entry.definitions.compactMap { def in
            let pos = def.partOfSpeech
            if seen.contains(pos) { return nil }
            seen.insert(pos)
            return pos
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(entry.headword)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .lineLimit(1)
            
            if !entry.ipa.isEmpty {
                Text("[\(entry.ipa)]")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            if let firstDef = entry.definitions.first {
                Text(firstDef.enDefinition)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Spacer()
                
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
        }
        .padding()
        .frame(width: 180, height: 140)
        .background(Color(.systemGray6).opacity(0.5))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.systemGray4), lineWidth: 1)
        )
    }
}

#Preview {
    SearchView()
        .environmentObject(DeepLinkManager.shared)
}
