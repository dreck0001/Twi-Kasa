import Foundation

// all images served from Firebase Storage
private let imageBaseURL = "https://storage.googleapis.com/twi-kasa-prod.firebasestorage.app/images/"

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
    let tags: [String]
    let imageUrl: String
    let audioUrl: String
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
        case tags
        case imageUrl
        case audioUrl
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
        tags: [String],
        imageUrl: String = "",
        audioUrl: String = "",
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
        self.tags = tags
        self.imageUrl = imageUrl
        self.audioUrl = audioUrl
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
        tags = try container.decode([String].self, forKey: .tags)
        imageUrl = try container.decodeIfPresent(String.self, forKey: .imageUrl) ?? ""
        audioUrl = try container.decodeIfPresent(String.self, forKey: .audioUrl) ?? ""
        contentWarning = try container.decodeIfPresent(Bool.self, forKey: .contentWarning) ?? false
    }
    
    var hasImage: Bool {
        !imageUrl.isEmpty
    }
    
    var hasAudio: Bool {
        !audioUrl.isEmpty
    }
    
    var fullImageUrl: String {
        guard !imageUrl.isEmpty else { return "" }
        return imageBaseURL + imageUrl
    }
    
    func possibleAudioFilenames(for normalized: String) -> [String] {
        var filenames: [String] = []
        
        if !audioUrl.isEmpty {
            filenames.append(audioUrl)
        }
        
        filenames.append("\(normalized).mp3")
        filenames.append("\(normalized).m4a")
        
        return filenames
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
    let imageUrl: String
    let definitions: [Definition]
    let attribution: String
    let createdAt: String
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case headword
        case normalized
        case dialects
        case syllables
        case ipa
        case imageUrl
        case definitions
        case attribution
        case createdAt
        case updatedAt
    }
    
    //memberwise initializer for manual creation like for previews
    init(
        id: String,
        headword: String,
        normalized: String,
        dialects: [String],
        syllables: String,
        ipa: String,
        imageUrl: String = "",
        definitions: [Definition],
        attribution: String,
        createdAt: String,
        updatedAt: String
    ) {
        self.id = id
        self.headword = headword
        self.normalized = normalized
        self.dialects = dialects
        self.syllables = syllables
        self.ipa = ipa
        self.imageUrl = imageUrl
        self.definitions = definitions
        self.attribution = attribution
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    //decoder initializer for Firestore
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        headword = try container.decode(String.self, forKey: .headword)
        normalized = try container.decode(String.self, forKey: .normalized)
        dialects = try container.decode([String].self, forKey: .dialects)
        syllables = try container.decode(String.self, forKey: .syllables)
        ipa = try container.decode(String.self, forKey: .ipa)
        imageUrl = try container.decodeIfPresent(String.self, forKey: .imageUrl) ?? ""
        definitions = try container.decode([Definition].self, forKey: .definitions)
        attribution = try container.decode(String.self, forKey: .attribution)
        createdAt = try container.decode(String.self, forKey: .createdAt)
        updatedAt = try container.decode(String.self, forKey: .updatedAt)
    }
    
    var hasImage: Bool {
        !imageUrl.isEmpty
    }
    
    var fullImageUrl: String {
        guard !imageUrl.isEmpty else { return "" }
        return imageBaseURL + imageUrl
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
    
    init(from entry: Entry) {
        self.id = entry.id
        self.headword = entry.headword
        self.primaryDefinition = entry.definitions.first?.enDefinition ?? ""
        self.partOfSpeech = entry.definitions.first?.partOfSpeech ?? ""
    }
}
