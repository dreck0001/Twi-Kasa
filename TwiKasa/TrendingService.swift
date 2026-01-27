import Foundation
import FirebaseFirestore

class TrendingService: ObservableObject {
    static let shared = TrendingService()
    
    private let db = Firestore.firestore()
    private let trendingCollection = "trending"
    
    private let searchWeight = 1.0
    private let viewWeight = 2.0
    private let favoriteWeight = 5.0
    
    private init() {}
    
    func trackSearch(_ wordId: String) {
        incrementScore(wordId, points: searchWeight, incrementSearch: true)
    }
    
    func trackView(_ wordId: String) {
        incrementScore(wordId, points: viewWeight, incrementView: true)
    }
    
    func trackFavorite(_ wordId: String) {
        incrementScore(wordId, points: favoriteWeight, incrementFavorite: true)
    }
    
    private func incrementScore(_ wordId: String, points: Double, incrementSearch: Bool = false, incrementView: Bool = false, incrementFavorite: Bool = false) {
        let docRef = db.collection(trendingCollection).document(wordId)
        let today = ISO8601DateFormatter().string(from: Date()).prefix(10)
        let weekStart = getWeekStart()
        
        db.runTransaction({ (transaction, errorPointer) -> Any? in
            let document: DocumentSnapshot
            do {
                try document = transaction.getDocument(docRef)
            } catch let fetchError as NSError {
                errorPointer?.pointee = fetchError
                return nil
            }
            
            let currentScore = document.data()?["score"] as? Double ?? 0
            let currentSearchCount = document.data()?["searchCount"] as? Int ?? 0
            let currentViewCount = document.data()?["viewCount"] as? Int ?? 0
            let currentFavoriteCount = document.data()?["favoriteCount"] as? Int ?? 0
            
            let newScore = currentScore + points
            let newSearchCount = currentSearchCount + (incrementSearch ? 1 : 0)
            let newViewCount = currentViewCount + (incrementView ? 1 : 0)
            let newFavoriteCount = currentFavoriteCount + (incrementFavorite ? 1 : 0)
            
            transaction.setData([
                "score": newScore,
                "searchCount": newSearchCount,
                "viewCount": newViewCount,
                "favoriteCount": newFavoriteCount,
                "lastUpdated": String(today),
                "weekStart": weekStart
            ], forDocument: docRef, merge: true)
            
            return nil
        }) { _, _ in }
    }
    
    private func getWeekStart() -> String {
        let calendar = Calendar.current
        let today = Date()
        
        let weekday = calendar.component(.weekday, from: today)
        let daysToSubtract = (weekday + 6) % 7
        
        guard let weekStart = calendar.date(byAdding: .day, value: -daysToSubtract, to: today) else {
            return ISO8601DateFormatter().string(from: today).prefix(10).description
        }
        
        return ISO8601DateFormatter().string(from: weekStart).prefix(10).description
    }
    
    func getTrendingWords(limit: Int = 10) async throws -> [Word] {
        let snapshot = try await db.collection(trendingCollection)
            .order(by: "score", descending: true)
            .limit(to: limit)
            .getDocuments()
        
        var wordIds: [String] = []
        for doc in snapshot.documents {
            wordIds.append(doc.documentID)
        }
        
        var words: [Word] = []
        for wordId in wordIds {
            let wordDoc = try await db.collection("words").document(wordId).getDocument()
            if let word = try? wordDoc.data(as: Word.self) {
                words.append(word)
            }
        }
        
        return words
    }
    
    func getViewCount(for wordId: String) async throws -> Int {
        let document = try await db.collection(trendingCollection).document(wordId).getDocument()
        return document.data()?["viewCount"] as? Int ?? 0
    }
}
