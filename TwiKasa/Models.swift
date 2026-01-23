import Foundation

private let imageBaseURL = "https://storage.googleapis.com/twi-kasa-prod.firebasestorage.app/images/"
private let audioBaseURL = "https://storage.googleapis.com/twi-kasa-prod.firebasestorage.app/audio/"

struct Definition: Codable, Identifiable, Hashable {
    let id = UUID()
    let definitionNumber: Int
    let partOfSpeech: String
    let enDefinition: String
    let twiDefinition: String
    let examples: [Example]
    let synonyms: [String]
    let antonyms: [String]
    let morphology: String
    let frequency: Int
    let tags: [String]
    let contentWarning: Bool
    
    enum CodingKeys: String, CodingKey {
        case definitionNumber
        case partOfSpeech
        case enDefinition
        case twiDefinition
        case examples
        case synonyms
        case antonyms
        case morphology
        case frequency
        case tags
        case contentWarning
    }
    
    init(
        definitionNumber: Int,
        partOfSpeech: String,
        enDefinition: String,
        twiDefinition: String,
        examples: [Example],
        synonyms: [String],
        antonyms: [String],
        morphology: String,
        frequency: Int,
        tags: [String],
        contentWarning: Bool = false
    ) {
        self.definitionNumber = definitionNumber
        self.partOfSpeech = partOfSpeech
        self.enDefinition = enDefinition
        self.twiDefinition = twiDefinition
        self.examples = examples
        self.synonyms = synonyms
        self.antonyms = antonyms
        self.morphology = morphology
        self.frequency = frequency
        self.tags = tags
        self.contentWarning = contentWarning
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        definitionNumber = try container.decode(Int.self, forKey: .definitionNumber)
        partOfSpeech = try container.decode(String.self, forKey: .partOfSpeech)
        enDefinition = try container.decode(String.self, forKey: .enDefinition)
        twiDefinition = try container.decode(String.self, forKey: .twiDefinition)
        examples = try container.decode([Example].self, forKey: .examples)
        synonyms = try container.decode([String].self, forKey: .synonyms)
        antonyms = try container.decode([String].self, forKey: .antonyms)
        morphology = try container.decode(String.self, forKey: .morphology)
        frequency = try container.decode(Int.self, forKey: .frequency)
        tags = try container.decode([String].self, forKey: .tags)
        contentWarning = try container.decodeIfPresent(Bool.self, forKey: .contentWarning) ?? false
    }
    
    func imageUrl(for parentNormalized: String) -> String {
        "\(parentNormalized)-\(definitionNumber).jpg"
    }
    
    func audioUrl(for parentNormalized: String) -> String {
        "\(parentNormalized)-\(definitionNumber).mp3"
    }
    
    func fullImageUrl(for parentNormalized: String) -> String {
        imageBaseURL + imageUrl(for: parentNormalized)
    }
    
    func fullAudioUrl(for parentNormalized: String) -> String {
        audioBaseURL + audioUrl(for: parentNormalized)
    }
    
    static func == (lhs: Definition, rhs: Definition) -> Bool {
        lhs.definitionNumber == rhs.definitionNumber &&
        lhs.partOfSpeech == rhs.partOfSpeech &&
        lhs.enDefinition == rhs.enDefinition
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(definitionNumber)
        hasher.combine(enDefinition)
    }
}

struct Example: Codable, Identifiable, Hashable {
    let id = UUID()
    let twi: String
    let en: String
    
    enum CodingKeys: String, CodingKey {
        case twi
        case en
    }
    
    static func == (lhs: Example, rhs: Example) -> Bool {
        lhs.twi == rhs.twi && lhs.en == rhs.en
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(twi)
        hasher.combine(en)
    }
}

struct Entry: Codable, Identifiable, Hashable {
    let id: String
    let headword: String
    let normalized: String
    let dialects: [String]
    let syllables: String
    let ipa: String
    let definitions: [Definition]
    let attribution: String
    let createdAt: String
    let updatedAt: String
    
    var primaryFrequency: Int {
        definitions.max(by: { $0.frequency < $1.frequency })?.frequency ?? 50
    }
    
    static func == (lhs: Entry, rhs: Entry) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

struct SearchResult: Identifiable {
    let id: String
    let headword: String
    let primaryDefinition: String
    let partOfSpeech: String
    let frequency: Int
    
    init(from entry: Entry) {
        self.id = entry.id
        self.headword = entry.headword
        self.primaryDefinition = entry.definitions.first?.enDefinition ?? ""
        self.partOfSpeech = entry.definitions.first?.partOfSpeech ?? ""
        self.frequency = entry.primaryFrequency
    }
}
