import SwiftUI
import FirebaseCore
import FirebaseAuth

@main
struct TwiKasaApp: App {
    @StateObject private var deepLinkManager = DeepLinkManager.shared
    
    init() {
        FirebaseApp.configure()
        
        if Auth.auth().currentUser == nil {
            Auth.auth().signInAnonymously { _, _ in }
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(deepLinkManager)
                .onOpenURL { url in
                    _ = deepLinkManager.handleURL(url)
                }
        }
    }
}
