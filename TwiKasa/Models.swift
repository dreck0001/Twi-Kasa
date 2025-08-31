//
//  Models.swift
//  TwiKasa
//
//  Created by Throw Catchers on 8/30/25.
//

import Foundation
import FirebaseFirestore

struct DictionaryEntry: Codable, Identifiable {
    @DocumentID var id: String?
    let headword: String
    let normalized: String
    let dialects: [String]
    let partOfSpeech: String
    let syllables: [String]?
    let ipa: String?
    let audioUrl: String?
    let enDefinition: String
    let twiDefinition: String?
    let examples: [Example]
    let synonyms: [String]
    let antonyms: [String]
    let morphology: Morphology?
    let frequency: Int
    let tags: [String]
    let attribution: Attribution
    let timestamps: Timestamps
    
    struct Example: Codable {
        let en: String
        let twi: String
    }
    
    struct Morphology: Codable {
        let root: String?
        let type: String?
        let notes: String?
    }
    
    struct Attribution: Codable {
        let source: String
        let reviewer: String?
        let confidence: Double?
    }
    
    struct Timestamps: Codable {
        let created: Date
        let updated: Date
    }
}

struct UserSuggestion: Codable, Identifiable {
    @DocumentID var id: String?
    let headword: String
    let userId: String
    let type: String
    let suggestedData: SuggestedData
    let status: String
    let moderatorNotes: String?
    let timestamp: Date
    
    struct SuggestedData: Codable {
        let enDefinition: String
        let twiDefinition: String?
        let examples: [DictionaryEntry.Example]?
    }
}
