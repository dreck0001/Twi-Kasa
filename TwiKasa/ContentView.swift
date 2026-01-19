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
                    Label("Dictionary", systemImage: "book.closed")
                }
            
            FavoritesView()
                .tabItem {
                    Label("Favorites", systemImage: "star.fill")
                }
            
            LearnView()
                .tabItem {
                    Label("Learn", systemImage: "graduationcap.fill")
                }
            
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.circle.fill")
                }
        }        .tint(.red.opacity(0.8))
    }
}

#Preview {
    ContentView()
}
