import SwiftUI

struct ShareCardView: View {
    let headword: String
    let ipa: String
    let partOfSpeech: String
    let twiDefinition: String
    let enDefinition: String
    let image: UIImage?
    
    private let cardSize: CGFloat = 400
    
    private var headerGradient: LinearGradient {
        let colors: [Color]
        
        switch partOfSpeech.lowercased() {
        case "noun":
            colors = [Color(red: 0.6, green: 0.4, blue: 0.8), Color(red: 0.8, green: 0.5, blue: 0.9)]
        case "verb":
            colors = [Color(red: 0.3, green: 0.5, blue: 0.9), Color(red: 0.4, green: 0.7, blue: 1.0)]
        case "adjective":
            colors = [Color(red: 0.9, green: 0.5, blue: 0.3), Color(red: 1.0, green: 0.7, blue: 0.4)]
        case "adverb":
            colors = [Color(red: 0.3, green: 0.7, blue: 0.6), Color(red: 0.4, green: 0.8, blue: 0.7)]
        case "interjection":
            colors = [Color(red: 0.9, green: 0.3, blue: 0.5), Color(red: 1.0, green: 0.5, blue: 0.6)]
        default:
            colors = [Color(red: 0.5, green: 0.6, blue: 0.7), Color(red: 0.6, green: 0.7, blue: 0.8)]
        }
        
        return LinearGradient(
            colors: colors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                if let image = image {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: cardSize, height: cardSize)
                        .clipped()
                        .overlay(
                            VStack(spacing: 0) {
                                LinearGradient(
                                    colors: [Color.black, Color.black.opacity(0)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                                .frame(height: cardSize * 0.1)
                                
                                Spacer()
                                
                                LinearGradient(
                                    colors: [Color.black.opacity(0), Color.black],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                                .frame(height: cardSize * 0.1)
                            }
                        )
                } else {
                    headerGradient
                        .frame(width: cardSize, height: cardSize)
                }
                
                VStack {
                    Spacer()
                    
                    HStack(alignment: .bottom) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(headword)
                                .font(.system(size: 48, weight: .bold))
                                .foregroundColor(.white)
                            
                            if !ipa.isEmpty {
                                HStack(spacing: 6) {
                                    Text("/\(ipa)/")
                                        .font(.title3)
                                        .foregroundColor(.white)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.white.opacity(0.15))
                                .cornerRadius(8)
                            }
                        }
                        
                        Spacer()
                    }
                    .padding()
                    .padding(.bottom, 8)
                }
            }
            .frame(width: cardSize, height: cardSize)
            
            VStack(alignment: .leading, spacing: 20) {
                Text(partOfSpeech)
                    .font(.subheadline)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                
                VStack(alignment: .leading, spacing: 8) {
                    if !twiDefinition.isEmpty {
                        Text(twiDefinition)
                            .font(.body)
                            .foregroundColor(.white)
                    }
                    
                    Text(enDefinition)
                        .font(.body)
                        .foregroundColor(.white.opacity(0.7))
                        .italic()
                }
                
                Spacer(minLength: 12)
                
                HStack {
                    Text("TwiKasa")
                        .font(.headline)
                        .foregroundColor(.red.opacity(0.9))
                    
                    Spacer()
                }
            }
            .padding(20)
            .frame(width: cardSize, alignment: .leading)
            .background(Color.black)
        }
        .frame(width: cardSize)
        .background(Color.black)
    }
    
    @MainActor
    func render() -> UIImage? {
        let renderer = ImageRenderer(content: self)
        renderer.scale = 2.0
        return renderer.uiImage
    }
}

#Preview {
    ShareCardView(
        headword: "ɔdɔ",
        ipa: "ɔdɔ",
        partOfSpeech: "noun",
        twiDefinition: "Ɔdɔ a ɛwɔ abusuafoɔ ntam",
        enDefinition: "Love; affection",
        image: nil
    )
    .padding()
    .background(Color.gray.opacity(0.3))
}
