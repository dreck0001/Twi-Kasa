//
//  TwiKasaApp.swift
//  TwiKasa
//
//  Created by Throw Catchers on 8/30/25.
//

import SwiftUI
import FirebaseCore

@main
struct TwiKasaApp: App {
    
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}



