import SwiftUI
import FirebaseAuth
import FirebaseFirestore

/// Temporary debug view to test search history
struct SearchHistoryDebugView: View {
    @ObservedObject private var searchHistoryManager = SearchHistoryManager.shared
    @State private var debugInfo: String = "Loading..."
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Search History Debug")
                    .font(.title)
                    .fontWeight(.bold)
                
                Divider()
                
                // Auth Info
                VStack(alignment: .leading, spacing: 8) {
                    Text("Authentication")
                        .font(.headline)
                    
                    Text(authStatus)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                
                // Local History
                VStack(alignment: .leading, spacing: 8) {
                    Text("Local History (\(searchHistoryManager.recentSearches.count) items)")
                        .font(.headline)
                    
                    if searchHistoryManager.recentSearches.isEmpty {
                        Text("No local history")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(searchHistoryManager.recentSearches) { word in
                            Text("• \(word.headword) (\(word.id))")
                                .font(.caption)
                        }
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                
                // Cloud Status
                VStack(alignment: .leading, spacing: 8) {
                    Text("Cloud Status")
                        .font(.headline)
                    
                    Text(debugInfo)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                
                // Test Buttons
                VStack(spacing: 12) {
                    Button("Test: Fetch Cloud History") {
                        Task {
                            await fetchCloudHistory()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button("Test: Write to Cloud") {
                        Task {
                            await testWrite()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                    
                    Button("Refresh from Cloud") {
                        Task {
                            await searchHistoryManager.refreshFromCloud()
                        }
                    }
                    .buttonStyle(.bordered)
                }
                .frame(maxWidth: .infinity)
            }
            .padding()
        }
        .navigationTitle("Debug")
        .onAppear {
            debugInfo = "Ready to test"
        }
    }
    
    private var authStatus: String {
        if let user = Auth.auth().currentUser {
            var status = "✅ Signed in\n"
            status += "User ID: \(user.uid)\n"
            status += "Anonymous: \(user.isAnonymous)\n"
            status += "Email: \(user.email ?? "none")\n"
            if let displayName = user.displayName {
                status += "Name: \(displayName)\n"
            }
            return status
        } else {
            return "❌ Not signed in"
        }
    }
    
    private func fetchCloudHistory() async {
        guard let user = Auth.auth().currentUser, !user.isAnonymous else {
            await MainActor.run {
                debugInfo = "❌ Not signed in or anonymous"
            }
            return
        }
        
        await MainActor.run {
            debugInfo = "Fetching from /users/\(user.uid)/searchHistory..."
        }
        
        let db = Firestore.firestore()
        
        do {
            let snapshot = try await db.collection("users")
                .document(user.uid)
                .collection("searchHistory")
                .getDocuments()
            
            await MainActor.run {
                if snapshot.documents.isEmpty {
                    debugInfo = "✅ Connected, but collection is empty (0 documents)"
                } else {
                    var info = "✅ Found \(snapshot.documents.count) documents:\n\n"
                    for doc in snapshot.documents {
                        let data = doc.data()
                        info += "• \(doc.documentID)\n"
                        if let wordId = data["wordId"] as? String {
                            info += "  wordId: \(wordId)\n"
                        }
                        if let timestamp = data["searchedAt"] {
                            info += "  searchedAt: \(timestamp)\n"
                        }
                        info += "\n"
                    }
                    debugInfo = info
                }
            }
        } catch {
            await MainActor.run {
                debugInfo = "❌ Error: \(error.localizedDescription)\n\n"
                debugInfo += "Possible causes:\n"
                debugInfo += "• Firestore rules blocking access\n"
                debugInfo += "• Network connection issue\n"
                debugInfo += "• Collection doesn't exist yet"
            }
        }
    }
    
    private func testWrite() async {
        guard let user = Auth.auth().currentUser, !user.isAnonymous else {
            await MainActor.run {
                debugInfo = "❌ Not signed in or anonymous"
            }
            return
        }
        
        let testWordId = "test-\(Int(Date().timeIntervalSince1970))"
        
        await MainActor.run {
            debugInfo = "Writing test document to /users/\(user.uid)/searchHistory/\(testWordId)..."
        }
        
        let db = Firestore.firestore()
        
        do {
            try await db.collection("users")
                .document(user.uid)
                .collection("searchHistory")
                .document(testWordId)
                .setData([
                    "wordId": testWordId,
                    "searchedAt": FieldValue.serverTimestamp(),
                    "test": true
                ])
            
            await MainActor.run {
                debugInfo = "✅ Successfully wrote test document!\n\n"
                debugInfo += "Document ID: \(testWordId)\n"
                debugInfo += "Path: /users/\(user.uid)/searchHistory/\(testWordId)\n\n"
                debugInfo += "Check Firebase Console to verify."
            }
        } catch {
            await MainActor.run {
                debugInfo = "❌ Failed to write: \(error.localizedDescription)\n\n"
                
                if let firestoreError = error as NSError? {
                    debugInfo += "Error code: \(firestoreError.code)\n"
                    debugInfo += "Domain: \(firestoreError.domain)\n\n"
                }
                
                debugInfo += "Possible causes:\n"
                debugInfo += "• Firestore rules: Check if rules allow write\n"
                debugInfo += "• Network: Check internet connection\n"
                debugInfo += "• Permissions: User might not have write access"
            }
        }
    }
}

#Preview {
    NavigationStack {
        SearchHistoryDebugView()
    }
}
