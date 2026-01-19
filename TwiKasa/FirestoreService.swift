import Foundation
import FirebaseFirestore

class FirestoreService: ObservableObject {
    
    private let db = Firestore.firestore()
    private let entriesCollection = "entries"
    
    @Published var entries: [Entry] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private static var hasConfiguredSettings = false
    
    init() {
        // only configure once
        if !FirestoreService.hasConfiguredSettings {
            let settings = FirestoreSettings()
            settings.cacheSettings = PersistentCacheSettings(sizeBytes: NSNumber(value: FirestoreCacheSizeUnlimited))
            db.settings = settings
            FirestoreService.hasConfiguredSettings = true
        }
    }
    
    func searchWords(query: String) async throws -> [Entry] {
        guard !query.isEmpty else {
            return []
        }
        
        let normalizedQuery = query.lowercased()
        
        let snapshot = try await db.collection(entriesCollection)
            .whereField("normalized", isGreaterThanOrEqualTo: normalizedQuery)
            .whereField("normalized", isLessThan: normalizedQuery + "\u{f8ff}")
            .limit(to: 50)
            .getDocuments()
        
        let results = snapshot.documents.compactMap { doc -> Entry? in
            try? doc.data(as: Entry.self)
        }
        
        return results.sorted { entry1, entry2 in
            if entry1.primaryFrequency == entry2.primaryFrequency {
                return entry1.headword < entry2.headword
            }
            return entry1.primaryFrequency > entry2.primaryFrequency
        }
    }
    
    func getEntry(id: String) async throws -> Entry? {
        let document = try await db.collection(entriesCollection)
            .document(id)
            .getDocument()
        
        return try? document.data(as: Entry.self)
    }
    
    func getCommonWords(limit: Int = 20) async throws -> [Entry] {
        let snapshot = try await db.collection(entriesCollection)
            .order(by: "definitions", descending: false)
            .limit(to: limit)
            .getDocuments()
        
        var results = snapshot.documents.compactMap { doc -> Entry? in
            try? doc.data(as: Entry.self)
        }
        
        results.sort { $0.primaryFrequency > $1.primaryFrequency }
        
        return Array(results.prefix(limit))
    }
    
    func getRandomWords(count: Int = 5) async throws -> [Entry] {
        let snapshot = try await db.collection(entriesCollection)
            .limit(to: 50)
            .getDocuments()
        
        let allEntries = snapshot.documents.compactMap { doc -> Entry? in
            try? doc.data(as: Entry.self)
        }
        
        return Array(allEntries.shuffled().prefix(count))
    }
    
    var hasCachedData: Bool {
        !entries.isEmpty
    }
}

extension FirestoreService {
    @MainActor
    func setLoading(_ loading: Bool) {
        isLoading = loading
    }
    
    @MainActor
    func setError(_ error: String?) {
        errorMessage = error
    }
}
