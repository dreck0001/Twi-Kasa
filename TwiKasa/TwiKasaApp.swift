import SwiftUI
import FirebaseCore
import FirebaseAuth

@main
struct TwiKasaApp: App {
    @StateObject private var deepLinkManager = DeepLinkManager.shared
    @State private var showSplash = true
    @State private var splashOffset: CGFloat = 0
    @State private var screenHeight: CGFloat = 0
    
    init() {
        FirebaseApp.configure()
        // no anonymous sign-in - users can use the app without auth
        // and sign in when they want to contribute or sync
    }
    
    var body: some Scene {
        WindowGroup {
            GeometryReader { geometry in
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
                    screenHeight = geometry.size.height
                    
                    Task {
                        try? await Task.sleep(for: .seconds(2.0))
                        await MainActor.run {
                            splashOffset = -screenHeight
                        }
                        
                        try? await Task.sleep(for: .seconds(0.5))
                        await MainActor.run {
                            showSplash = false
                        }
                    }
                }
            }
        }
    }
}
