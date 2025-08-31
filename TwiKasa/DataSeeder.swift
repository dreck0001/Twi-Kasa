//
//  DataSeeder.swift
//  TwiKasa
//
//  Created by Throw Catchers on 8/30/25.
//


import Foundation
import FirebaseFirestore

class DataSeeder {
    
    static func seedInitialData() {
        let db = Firestore.firestore()
        
        let entries = [
            createEntry(
                id: "akwaaba_001",
                headword: "akwaaba",
                normalized: "akwaaba",
                partOfSpeech: "interjection",
                enDefinition: "Welcome; a greeting used to welcome someone",
                twiDefinition: "Nkyia a yɛde kyia obi a ɔba yɛn nkyɛn",
                examples: [
                    ("Welcome to our home!", "Akwaaba yɛn fie!"),
                    ("They welcomed us warmly", "Wɔkyiaa yɛn akwaaba paa")
                ],
                tags: ["greetings", "hospitality", "essential"],
                frequency: 95
            ),
            
            createEntry(
                id: "medaase_002",
                headword: "medaase",
                normalized: "medaase",
                partOfSpeech: "interjection",
                enDefinition: "Thank you; expression of gratitude",
                twiDefinition: "Aseda a yɛda no adi kyerɛ obi",
                examples: [
                    ("Thank you very much", "Medaase paa"),
                    ("Thanks for your help", "Medaase wɔ wo mmoa no ho")
                ],
                tags: ["greetings", "politeness", "essential"],
                frequency: 98
            ),
            
            createEntry(
                id: "odo_003",
                headword: "ɔdɔ",
                normalized: "odo",
                partOfSpeech: "noun",
                enDefinition: "Love; deep affection",
                twiDefinition: "Ɔpɛ a yɛwɔ ma obi anaa biribi",
                examples: [
                    ("I love you", "Medɔ wo"),
                    ("Love is patient", "Ɔdɔ wɔ boasetɔ"),
                    ("Mother's love", "Ɛna dɔ")
                ],
                tags: ["emotions", "relationships", "essential"],
                frequency: 90
            ),
            
            createEntry(
                id: "adwuma_004",
                headword: "adwuma",
                normalized: "adwuma",
                partOfSpeech: "noun",
                enDefinition: "Work; job; occupation",
                twiDefinition: "Biribi a obi yɛ de nya sika",
                examples: [
                    ("I'm going to work", "Merekɔ adwuma"),
                    ("What work do you do?", "Adwuma bɛn na woyɛ?")
                ],
                tags: ["occupation", "daily-life", "essential"],
                frequency: 88
            ),
            
            createEntry(
                id: "nsu_005",
                headword: "nsu",
                normalized: "nsu",
                partOfSpeech: "noun",
                enDefinition: "Water",
                twiDefinition: "Nneɛma a ɛsen a yɛnom",
                examples: [
                    ("Drinking water", "Nsu a yɛnom"),
                    ("The water is cold", "Nsu no yɛ nwini")
                ],
                tags: ["nature", "daily-life", "essential"],
                frequency: 92
            ),
            
            createEntry(
                id: "aduane_006",
                headword: "aduane",
                normalized: "aduane",
                partOfSpeech: "noun",
                enDefinition: "Food; meal",
                twiDefinition: "Nneɛma a yɛdi",
                examples: [
                    ("The food is ready", "Aduane no ayɛ krado"),
                    ("Let's eat", "Momma yɛnni aduane")
                ],
                tags: ["food", "daily-life", "essential"],
                frequency: 91
            ),
            
            createEntry(
                id: "fie_007",
                headword: "fie",
                normalized: "fie",
                partOfSpeech: "noun",
                enDefinition: "Home; house",
                twiDefinition: "Baabi a obi te",
                examples: [
                    ("I'm going home", "Merekɔ fie"),
                    ("Welcome home", "Akwaaba fie")
                ],
                tags: ["places", "daily-life", "essential"],
                frequency: 93
            ),
            
            createEntry(
                id: "maakye_008",
                headword: "maakye",
                normalized: "maakye",
                partOfSpeech: "interjection",
                enDefinition: "Good morning",
                twiDefinition: "Nkyia a yɛde kyia anɔpa",
                examples: [
                    ("Good morning to you all", "Maakye mo nyinaa")
                ],
                tags: ["greetings", "time", "essential"],
                frequency: 96
            ),
            
            createEntry(
                id: "maadwo_009",
                headword: "maadwo",
                normalized: "maadwo",
                partOfSpeech: "interjection",
                enDefinition: "Good evening",
                twiDefinition: "Nkyia a yɛde kyia anwummere",
                examples: [
                    ("Good evening sir", "Maadwo owura")
                ],
                tags: ["greetings", "time", "essential"],
                frequency: 94
            ),
            
            createEntry(
                id: "ete_sen_010",
                headword: "ɛte sɛn",
                normalized: "ete sen",
                partOfSpeech: "phrase",
                enDefinition: "How are you?; How is it?",
                twiDefinition: "Ɔkwan a yɛde bisa obi sɛnea ɔte",
                examples: [
                    ("How are you today?", "Ɛte sɛn nnɛ?"),
                    ("I'm fine", "Me ho yɛ")
                ],
                tags: ["greetings", "questions", "essential"],
                frequency: 97
            )
        ]
        
        let batch = db.batch()
        
        for entry in entries {
            let ref = db.collection("entries").document(entry.id ?? UUID().uuidString)
            do {
                try batch.setData(from: entry, forDocument: ref)
            } catch {
                print("skipping entry \(entry.headword): \(error)")
            }
        }
        
        batch.commit { error in
            if let error = error {
                print("failed to seed: \(error)")
            } else {
                print("✓ added \(entries.count) words")
            }
        }
    }
    
    private static func createEntry(
        id: String,
        headword: String,
        normalized: String,
        partOfSpeech: String,
        enDefinition: String,
        twiDefinition: String?,
        examples: [(String, String)],
        tags: [String],
        frequency: Int
    ) -> DictionaryEntry {
        
        let exampleObjects = examples.map {
            DictionaryEntry.Example(en: $0.0, twi: $0.1)
        }
        
        let now = Date()
        
        return DictionaryEntry(
            id: id,
            headword: headword,
            normalized: normalized,
            dialects: ["Asante", "Akuapem", "Fante"],
            partOfSpeech: partOfSpeech,
            syllables: nil,
            ipa: nil,
            audioUrl: nil,
            enDefinition: enDefinition,
            twiDefinition: twiDefinition,
            examples: exampleObjects,
            synonyms: [],
            antonyms: [],
            morphology: nil,
            frequency: frequency,
            tags: tags,
            attribution: DictionaryEntry.Attribution(
                source: "core_dictionary",
                reviewer: "system",
                confidence: 1.0
            ),
            timestamps: DictionaryEntry.Timestamps(
                created: now,
                updated: now
            )
        )
    }
    
    static func checkIfDataExists(completion: @escaping (Bool) -> Void) {
        let db = Firestore.firestore()
        db.collection("entries").limit(to: 1).getDocuments { snapshot, _ in
            let hasData = (snapshot?.documents.count ?? 0) > 0
            completion(hasData)
        }
    }
}
