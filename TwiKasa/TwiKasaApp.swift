//
//  TwiKasaApp.swift
//  TwiKasa
//
//  Created by Throw Catchers on 8/30/25.
//

import SwiftUI
import Firebase
import FirebaseCore
import FirebaseFirestore
import FirebaseAuth

@main
struct TwiKasaApp: App {
    
    init() {
        FirebaseApp.configure()
        
        let db = Firestore.firestore()
        let settings = FirestoreSettings()
        settings.cacheSettings = PersistentCacheSettings(sizeBytes: FirestoreCacheSizeUnlimited as NSNumber)
        db.settings = settings
        
        if Auth.auth().currentUser == nil {
            print("nobody home yet")
        } else {
            if let uid = Auth.auth().currentUser?.uid {
                print("welcome back: \(uid)")
            }
        }
        
        print("firebase is up and running 🚀")
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
