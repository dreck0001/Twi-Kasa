//
//  ContentView.swift
//  TwiKasa
//
//  Created by Throw Catchers on 8/30/25.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            SearchView()
                .tabItem {
                    Label("Dictionary", systemImage: "magnifyingglass")
                }
            
            FavoritesView()
                .tabItem {
                    Label("Favorites", systemImage: "star.fill")
                }
            
            LearnView()
                .tabItem {
                    Label("Learn", systemImage: "graduationcap.fill")
                }
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
        .tint(.red.opacity(0.8))
    }
}

#Preview {
    ContentView()
        .environmentObject(DeepLinkManager.shared)
}
