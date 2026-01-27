import SwiftUI

class DeepLinkManager: ObservableObject {
    static let shared = DeepLinkManager()
    
    @Published var pendingWordId: String?
    
    private init() {}
    
    func handleURL(_ url: URL) -> Bool {
        guard url.scheme == "twikasa",
              url.host == "word",
              let wordId = url.pathComponents.last,
              !wordId.isEmpty else {
            return false
        }
        
        pendingWordId = wordId
        return true
    }
    
    func clearPending() {
        pendingWordId = nil
    }
}
