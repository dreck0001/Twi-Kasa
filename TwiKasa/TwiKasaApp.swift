import SwiftUI
import FirebaseCore
import FirebaseAuth

@main
struct TwiKasaApp: App {
    @StateObject private var deepLinkManager = DeepLinkManager.shared
    @State private var showSplash = true
    @State private var splashOffset: CGFloat = 0
    
    init() {
        FirebaseApp.configure()
        
        if Auth.auth().currentUser == nil {
            Auth.auth().signInAnonymously { _, _ in }
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView()
                    .environmentObject(deepLinkManager)
                    .onOpenURL { url in
                        _ = deepLinkManager.handleURL(url)
                    }
                
                if showSplash {
                    LaunchScreenView()
                        .offset(y: splashOffset)
                        .animation(.easeIn(duration: 0.4), value: splashOffset)
                        .zIndex(1)
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    splashOffset = -UIScreen.main.bounds.height
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        showSplash = false
                    }
                }
            }
        }
    }
}
