//
//  ReportService.swift
//  TwiKasa
//
//  Created by Throw Catchers on 1/26/26.
//


import Foundation
import FirebaseFirestore

class ReportService {
    static let shared = ReportService()
    
    private let db = Firestore.firestore()
    private let reportsCollection = "reports"
    
    private init() {}
    
    func submitReport(_ report: Report) async throws {
        let data: [String: Any] = [
            "context": report.context.rawValue,
            "contextId": report.contextId ?? "",
            "contextLabel": report.contextLabel ?? "",
            "type": report.type.rawValue,
            "description": report.description,
            "createdAt": Timestamp(date: Date())
        ]
        
        try await db.collection(reportsCollection).addDocument(data: data)
    }
}

struct Report {
    let context: ReportContext
    let contextId: String?
    let contextLabel: String?
    let type: ReportType
    let description: String
    
    enum ReportContext: String {
        case entry = "entry"
        case search = "search"
        case general = "general"
    }
}

enum ReportType: String, CaseIterable, Identifiable {
    case wrongDefinition = "wrong_definition"
    case wrongPronunciation = "wrong_pronunciation"
    case wrongImage = "wrong_image"
    case missingInfo = "missing_info"
    case inappropriate = "inappropriate"
    case other = "other"
    
    var id: String { rawValue }
    
    var label: String {
        switch self {
        case .wrongDefinition: return "Wrong definition"
        case .wrongPronunciation: return "Wrong pronunciation"
        case .wrongImage: return "Wrong or inappropriate image"
        case .missingInfo: return "Missing information"
        case .inappropriate: return "Inappropriate content"
        case .other: return "Other"
        }
    }
    
    var icon: String {
        switch self {
        case .wrongDefinition: return "text.badge.xmark"
        case .wrongPronunciation: return "speaker.slash"
        case .wrongImage: return "photo.badge.exclamationmark"
        case .missingInfo: return "doc.badge.plus"
        case .inappropriate: return "exclamationmark.triangle"
        case .other: return "ellipsis.circle"
        }
    }
}