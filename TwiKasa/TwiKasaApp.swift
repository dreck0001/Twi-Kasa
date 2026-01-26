import SwiftUI
import FirebaseCore
import FirebaseAuth

@main
struct TwiKasaApp: App {
    
    init() {
        FirebaseApp.configure()
        
        if Auth.auth().currentUser == nil {
            Auth.auth().signInAnonymously { _, _ in }
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
