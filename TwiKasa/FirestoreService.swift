import Foundation
import FirebaseFirestore

class FirestoreService: ObservableObject {
    
    private let db = Firestore.firestore()
    private let wordsCollection = "words"
    
    @Published var words: [Word] = []
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
    
    func searchWords(query: String) async throws -> [Word] {
        guard !query.isEmpty else { return [] }
        
        let normalizedQuery = normalize(query)
        
        let snapshot = try await db.collection(wordsCollection)
            .whereField("normalized", isGreaterThanOrEqualTo: normalizedQuery)
            .whereField("normalized", isLessThan: normalizedQuery + "\u{f8ff}")
            .limit(to: 50)
            .getDocuments()
        
        let results = snapshot.documents.compactMap { doc -> Word? in
            try? doc.data(as: Word.self)
        }
        
        return results.sorted { $0.headword < $1.headword }
    }
    
    func getWord(id: String) async throws -> Word? {
        let document = try await db.collection(wordsCollection)
            .document(id)
            .getDocument()
        
        return try? document.data(as: Word.self)
    }
    
    func getCommonWords(limit: Int = 20) async throws -> [Word] {
        let snapshot = try await db.collection(wordsCollection)
            .order(by: "definitions", descending: false)
            .limit(to: limit)
            .getDocuments()
        
        let results = snapshot.documents.compactMap { doc -> Word? in
            try? doc.data(as: Word.self)
        }
        
        return results.sorted { $0.headword < $1.headword }
    }
    
    func getRandomWords(count: Int = 5) async throws -> [Word] {
        let snapshot = try await db.collection(wordsCollection)
            .limit(to: 50)
            .getDocuments()
        
        let allWords = snapshot.documents.compactMap { doc -> Word? in
            try? doc.data(as: Word.self)
        }
        
        return Array(allWords.shuffled().prefix(count))
    }
    
    func getNewWords(limit: Int = 10) async throws -> [Word] {
        let snapshot = try await db.collection(wordsCollection)
            .order(by: "createdAt", descending: true)
            .limit(to: limit)
            .getDocuments()
        
        return snapshot.documents.compactMap { try? $0.data(as: Word.self) }
    }
    
    var hasCachedData: Bool {
        !words.isEmpty
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
