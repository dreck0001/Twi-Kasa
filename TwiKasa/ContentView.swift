//
//  ContentView.swift
//  TwiKasa
//
//  Created by Throw Catchers on 8/30/25.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import AuthenticationServices

struct ContentView: View {
    @State private var connectionMsg = "checking..."
    @State private var userMsg = "nobody signed in"
    @State private var dbMsg = "haven't tried yet"
    @State private var testStuff: [String] = []
    
    var body: some View {
        NavigationView {
            VStack(spacing: 25) {
                
                // logo stuff at the top
                VStack(spacing: 12) {
                    Image(systemName: "book.fill")
                        .font(.system(size: 56))
                        .foregroundColor(.red)
                    
                    Text("Twi Kasa")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Setup Check")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 30)
                
                // show connection status
                VStack(spacing: 14) {
                    StatusRow(
                        label: "Auth Status",
                        value: userMsg,
                        icon: "person.circle.fill",
                        isGood: userMsg.contains("✓")
                    )
                    
                    StatusRow(
                        label: "Database",
                        value: dbMsg,
                        icon: "server.rack",
                        isGood: dbMsg.contains("✓")
                    )
                    
                    StatusRow(
                        label: "Firebase",
                        value: connectionMsg,
                        icon: "wifi",
                        isGood: connectionMsg.contains("✓")
                    )
                }
                .padding(.horizontal, 20)
                
                // buttons to test stuff
                VStack(spacing: 10) {
                    Button {
                        tryAnonSignIn()
                    } label: {
                        Label("Try Anonymous", systemImage: "person.fill.questionmark")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                    
                    Button {
                        tryGoogleAuth()
                    } label: {
                        Label("Try Google", systemImage: "g.circle.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                    
                    Button {
                        writeTestData()
                    } label: {
                        Label("Write Test Data", systemImage: "square.and.pencil")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                    
                    Button {
                        importStarterWords()
                    } label: {
                        Label("Import 10 Starter Words", systemImage: "square.and.arrow.down")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.purple)
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                
                // show test writes if we have any
                if !testStuff.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Wrote these:")
                            .font(.headline)
                            .padding(.bottom, 4)
                        
                        ForEach(testStuff, id: \.self) { item in
                            Text("→ \(item)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .padding(.horizontal, 20)
                }
                
                Spacer()
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            checkWhatsUp()
        }
    }
    
    func checkWhatsUp() {
        // see if anyones logged in already
        if let user = Auth.auth().currentUser {
            let type = user.isAnonymous ? "Anon" : "Google"
            userMsg = "✓ \(type) user"
            connectionMsg = "✓ Connected"
        } else {
            userMsg = "not signed in"
            connectionMsg = "waiting..."
        }
        
        // ping firestore real quick
        let db = Firestore.firestore()
        db.collection("test").limit(to: 1).getDocuments { snap, err in
            if err != nil {
                dbMsg = "can't reach db"
            } else {
                dbMsg = "✓ Database ready"
            }
        }
    }
    
    func tryAnonSignIn() {
        Auth.auth().signInAnonymously { result, err in
            if let err = err {
                userMsg = "failed: \(err.localizedDescription)"
            } else if let user = result?.user {
                let shortId = String(user.uid.prefix(8))
                userMsg = "✓ Anon user: \(shortId)..."
                connectionMsg = "✓ Connected"
            }
        }
    }
    
    func tryGoogleAuth() {
        userMsg = "Google auth coming soon..."
    }
    
    func writeTestData() {
        let db = Firestore.firestore()
        
        let stuff: [String: Any] = [
            "msg": "hey from iOS",
            "when": FieldValue.serverTimestamp(),
            "device": UIDevice.current.name,
            "test": true
        ]
        
        db.collection("test").addDocument(data: stuff) { err in
            if let err = err {
                dbMsg = "write failed: \(err.localizedDescription)"
            } else {
                dbMsg = "✓ Write worked!"
                
                db.collection("test")
                    .order(by: "when", descending: true)
                    .limit(to: 5)
                    .getDocuments { snap, _ in
                        if let docs = snap?.documents {
                            testStuff = docs.compactMap { doc in
                                doc.data()["msg"] as? String
                            }
                        }
                    }
            }
        }
    }
    
    func importStarterWords() {
        DataSeeder.checkIfDataExists { hasData in
            if hasData {
                dbMsg = "✓ Words already imported"
            } else {
                DataSeeder.seedInitialData()
                dbMsg = "✓ Imported starter words!"
            }
        }
    }
}

struct StatusRow: View {
    let label: String
    let value: String
    let icon: String
    let isGood: Bool
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(isGood ? .green : .orange)
                .frame(width: 28)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.footnote)
                    .fontWeight(.medium)
            }
            
            Spacer()
        }
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

#Preview {
    ContentView()
}
