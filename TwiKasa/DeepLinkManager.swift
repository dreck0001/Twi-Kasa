//
//  DeepLinkManager.swift
//  TwiKasa
//
//  Created by Throw Catchers on 1/25/26.
//


import SwiftUI

class DeepLinkManager: ObservableObject {
    static let shared = DeepLinkManager()
    
    @Published var pendingEntryId: String?
    
    private init() {}
    
    func handleURL(_ url: URL) -> Bool {
        guard url.scheme == "twikasa",
              url.host == "word",
              let entryId = url.pathComponents.last,
              !entryId.isEmpty else {
            return false
        }
        
        pendingEntryId = entryId
        return true
    }
    
    func clearPending() {
        pendingEntryId = nil
    }
}