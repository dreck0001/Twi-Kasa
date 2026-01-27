import Foundation
import FirebaseFirestore
import FirebaseAuth

class AdminService: ObservableObject {
    static let shared = AdminService()
    
    private let db = Firestore.firestore()
    @Published private(set) var isAdmin = false
    
    private init() {}
    
    func checkAdminStatus() {
        guard let userId = Auth.auth().currentUser?.uid else {
            isAdmin = false
            return
        }
        
        db.collection("admins").document(userId).getDocument { [weak self] snapshot, error in
            DispatchQueue.main.async {
                self?.isAdmin = snapshot?.exists ?? false
            }
        }
    }
    
    func fetchReports() async throws -> [ReportItem] {
        guard isAdmin else { return [] }
        
        let snapshot = try await db.collection("reports")
            .order(by: "createdAt", descending: true)
            .limit(to: 50)
            .getDocuments()
        
        return snapshot.documents.compactMap { doc -> ReportItem? in
            let data = doc.data()
            
            guard let context = data["context"] as? String,
                  let type = data["type"] as? String,
                  let createdAt = data["createdAt"] as? Timestamp else {
                return nil
            }
            
            return ReportItem(
                id: doc.documentID,
                context: context,
                contextId: data["contextId"] as? String ?? "",
                contextLabel: data["contextLabel"] as? String ?? "",
                type: type,
                description: data["description"] as? String ?? "",
                createdAt: createdAt.dateValue()
            )
        }
    }
    
    func deleteReport(_ reportId: String) async throws {
        guard isAdmin else { return }
        try await db.collection("reports").document(reportId).delete()
    }
}

struct ReportItem: Identifiable {
    let id: String
    let context: String
    let contextId: String
    let contextLabel: String
    let type: String
    let description: String
    let createdAt: Date
    
    var typeLabel: String {
        switch type {
        case "wrong_definition": return "Wrong definition"
        case "wrong_pronunciation": return "Wrong pronunciation"
        case "wrong_image": return "Wrong image"
        case "missing_info": return "Missing info"
        case "inappropriate": return "Inappropriate"
        default: return "Other"
        }
    }
    
    var contextEmoji: String {
        switch context {
        case "word": return "📖"
        case "search": return "🔍"
        default: return "💬"
        }
    }
}
