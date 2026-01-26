import Foundation
import FirebaseFirestore

class FirestoreService: ObservableObject {
    
    private let db = Firestore.firestore()
    private let entriesCollection = "entries"
    
    @Published var entries: [Entry] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    init() {}
    
    private func normalize(_ text: String) -> String {
        return text
            .lowercased()
            .folding(options: .diacriticInsensitive, locale: .current)
            .replacingOccurrences(of: "ɔ", with: "o")
            .replacingOccurrences(of: "ɛ", with: "e")
    }
    
    func searchWords(query: String) async throws -> [Entry] {
        guard !query.isEmpty else { return [] }
        
        let normalizedQuery = normalize(query)
        
        let snapshot = try await db.collection(entriesCollection)
            .whereField("normalized", isGreaterThanOrEqualTo: normalizedQuery)
            .whereField("normalized", isLessThan: normalizedQuery + "\u{f8ff}")
            .limit(to: 50)
            .getDocuments()
        
        let results = snapshot.documents.compactMap { doc -> Entry? in
            try? doc.data(as: Entry.self)
        }
        
        return results.sorted { $0.headword < $1.headword }
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
        
        let results = snapshot.documents.compactMap { doc -> Entry? in
            try? doc.data(as: Entry.self)
        }
        
        return results.sorted { $0.headword < $1.headword }
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
