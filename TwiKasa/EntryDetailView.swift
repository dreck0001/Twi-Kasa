import SwiftUI
import AVFoundation

struct EntryDetailView: View {
    let entry: Entry
    
    @StateObject private var audioPlayer = AudioPlayer()
    @State private var selectedDefinitionIndex = 0
    @State private var scrollOffset: CGFloat = 0
    @State private var dragOffset: CGFloat = 0
    @State private var explicitContentRevealed = false
    @State private var isSwipingBack = false
    @State private var showContentWarningTooltip = false
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var favoritesManager = FavoritesManager.shared
    
    var body: some View {
        ZStack(alignment: .top) {
            ScrollView {
                VStack(spacing: 0) {
                    headerSection
                    
                    VStack(alignment: .leading, spacing: 40) {
                        partOfSpeechTabs
                        
                        definitionsSection
                        
                        if !selectedDefinition.examples.isEmpty {
                            examplesSection
                        }
                        
                        if !selectedDefinition.synonyms.isEmpty || !selectedDefinition.antonyms.isEmpty {
                            synonymsAntonymsSection
                        }
                        
                        if !selectedDefinition.morphology.isEmpty {
                            etymologySection
                        }
                        
                        dialectsSection
                        
                        if !selectedDefinition.tags.isEmpty {
                            tagsSection
                        }
                        
                        frequencySection
                    }
                    .padding()
                    .background(Color(.systemBackground))
                }
                .background(GeometryReader { geometry in
                    Color.clear.preference(
                        key: ScrollOffsetPreferenceKey.self,
                        value: geometry.frame(in: .named("scroll")).minY
                    )
                })
            }
            .coordinateSpace(name: "scroll")
            .scrollDisabled(isSwipingBack)
            .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                scrollOffset = value
            }
            .ignoresSafeArea()
            .offset(x: dragOffset)
            .gesture(
                DragGesture(minimumDistance: 20)
                    .onChanged { gesture in
                        let horizontalAmount = gesture.translation.width
                        let verticalAmount = abs(gesture.translation.height)
                        
                        // Only allow horizontal swipe if it's primarily horizontal
                        if horizontalAmount > verticalAmount && horizontalAmount > 0 && scrollOffset >= 0 {
                            isSwipingBack = true
                            dragOffset = horizontalAmount
                        }
                    }
                    .onEnded { gesture in
                        isSwipingBack = false
                        let horizontalAmount = gesture.translation.width
                        let verticalAmount = abs(gesture.translation.height)
                        
                        // Only dismiss if gesture was primarily horizontal
                        if horizontalAmount > verticalAmount && horizontalAmount > 100 {
                            dismiss()
                        } else {
                            withAnimation(.spring()) {
                                dragOffset = 0
                            }
                        }
                    }
            )
            
            VStack(spacing: 0) {
                ZStack {
                    VStack {
                        HStack {
                            Button {
                                dismiss()
                            } label: {
                                Image(systemName: "chevron.left")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                                    .frame(width: 32, height: 32)
                                    .background(
                                        Circle()
                                            .fill(.ultraThinMaterial)
                                    )
                            }
                            
                            Spacer()
                            
                            Text(entry.headword)
                                .font(.headline)
                                .foregroundColor(.primary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule()
                                        .fill(.ultraThinMaterial)
                                )
                                .opacity(scrollOffset < -150 ? 1 : 0)
                            
                            Spacer()
                            
                            Button {
                                favoritesManager.toggleFavorite(entry.id)
                            } label: {
                                Image(systemName: favoritesManager.isFavorited(entry.id) ? "star.fill" : "star")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                    .foregroundColor(favoritesManager.isFavorited(entry.id) ? .yellow : .primary)
                                    .frame(width: 32, height: 32)
                                    .background(
                                        Circle()
                                            .fill(.ultraThinMaterial)
                                    )
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 60)
                    }
                }
                
                Spacer()
            }
            .ignoresSafeArea()
            .offset(x: dragOffset)
        }
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            TrendingService.shared.trackView(entry.id)
        }
        .onDisappear {
            audioPlayer.stop()
        }
        .overlay(
            Group {
                if showContentWarningTooltip {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                showContentWarningTooltip = false
                            }
                        }
                    
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.title2)
                            .foregroundColor(.orange)
                        
                        VStack(spacing: 6) {
                            Text("Explicit Content")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            Text("This definition contains explicit or sensitive language")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(24)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.ultraThickMaterial)
                            .shadow(color: .black.opacity(0.2), radius: 20, y: 10)
                    )
                    .padding(.horizontal, 40)
                    .transition(.scale.combined(with: .opacity))
                }
            }
        )
        .onChange(of: selectedDefinitionIndex) { oldValue, newValue in
            explicitContentRevealed = false
            showContentWarningTooltip = false
        }
    }
    
    private var headerSection: some View {
        Group {
            if currentImageUrls.isEmpty {
                standardHeaderSection
                    .padding(.top, -100)
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.3), value: selectedDefinitionIndex)
            } else {
                imageHeaderSection
                    .padding(.top, -100)
            }
        }
    }
    
    private var currentImageUrls: [URL] {
        selectedDefinition.possibleImageUrls(for: entry.normalized).compactMap { URL(string: $0) }
    }
    
    private var shouldBlurImage: Bool {
        selectedDefinition.contentWarning && !explicitContentRevealed
    }
    
    private var navigationOpacity: Double {
        let threshold: CGFloat = !currentImageUrls.isEmpty ? 150 : 100
        let progress = min(max(-scrollOffset / threshold, 0), 1)
        return progress
    }
    
    private var selectedDefinition: Definition {
        entry.definitions[selectedDefinitionIndex]
    }
    
    private var audioFileExists: Bool {
        let possibleFilenames = selectedDefinition.possibleAudioFilenames(for: entry.normalized)
        for filename in possibleFilenames {
            let components = filename.split(separator: ".")
            guard components.count == 2 else { continue }
            let name = String(components[0])
            let ext = String(components[1])
            if Bundle.main.url(forResource: name, withExtension: ext) != nil {
                return true
            }
        }
        return false
    }
    
    private var headerGradient: LinearGradient {
        let colors: [Color]
        
        switch selectedDefinition.partOfSpeech.lowercased() {
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
        case "pronoun":
            colors = [Color(red: 0.5, green: 0.6, blue: 0.9), Color(red: 0.6, green: 0.7, blue: 1.0)]
        case "preposition":
            colors = [Color(red: 0.7, green: 0.5, blue: 0.7), Color(red: 0.8, green: 0.6, blue: 0.8)]
        case "conjunction":
            colors = [Color(red: 0.5, green: 0.7, blue: 0.5), Color(red: 0.6, green: 0.8, blue: 0.6)]
        default:
            colors = [Color(red: 0.5, green: 0.6, blue: 0.7), Color(red: 0.6, green: 0.7, blue: 0.8)]
        }
        
        return LinearGradient(
            colors: colors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private var imageHeaderSection: some View {
        GeometryReader { geometry in
            CachedAsyncImage(urls: currentImageUrls) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                        .blur(radius: shouldBlurImage ? 30 : 0)
                        .overlay(
                            Group {
                                if shouldBlurImage {
                                    Button {
                                        withAnimation {
                                            explicitContentRevealed = true
                                        }
                                    } label: {
                                        VStack(spacing: 8) {
                                            Image(systemName: "eye.slash.fill")
                                                .font(.largeTitle)
                                            Text("Tap to reveal")
                                                .font(.subheadline)
                                        }
                                        .foregroundColor(.white)
                                        .padding(20)
                                        .background(Color.black.opacity(0.7))
                                        .cornerRadius(12)
                                    }
                                }
                            }
                        )
                        .overlay(
                            VStack(spacing: 0) {
                                LinearGradient(
                                    colors: [Color.black.opacity(0.4), Color.clear],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                                .frame(height: 120)
                                
                                Spacer()
                                
                                LinearGradient(
                                    colors: [Color.clear, Color.black.opacity(0.7)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                                .frame(height: 150)
                            }
                        )
                        .overlay(
                            VStack {
                                Spacer()
                                
                                HStack(alignment: .bottom) {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text(entry.headword)
                                            .font(.system(size: 48, weight: .bold))
                                            .foregroundColor(.white)
                                        
                                        HStack(spacing: 8) {
                                            if !entry.ipa.isEmpty {
                                                Text("/\(entry.ipa)/")
                                                    .font(.title3)
                                                    .foregroundColor(.white)
                                            }
                                            
                                            if audioFileExists {
                                                Image(systemName: "speaker.wave.2.fill")
                                                    .font(.title3)
                                                    .foregroundColor(.white)
                                                    .contentShape(Rectangle())
                                                    .onTapGesture {
                                                        audioPlayer.play(filenames: selectedDefinition.possibleAudioFilenames(for: entry.normalized))
                                                    }
                                            }
                                        }
                                    }
                                    
                                    Spacer()
                                }
                                .padding()
                                .padding(.bottom, 8)
                            }
                        )
                    
                case .failure(_):
                    Color(.systemBackground)
                        .frame(height: geometry.size.height)
                        .overlay(
                            VStack {
                                Spacer()
                                standardHeaderSection
                            }
                        )
                    
                case .empty:
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    
                @unknown default:
                    EmptyView()
                }
            }
        }
        .frame(height: (UIScreen.main.bounds.height * 2 / 5) + 100)
        .id(currentImageUrls.first?.absoluteString ?? "")
        .transition(.opacity)
    }
    
    private var standardHeaderSection: some View {
        VStack {
            Spacer()
            
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(entry.headword)
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.white)
                    
                    HStack(spacing: 8) {
                        if !entry.ipa.isEmpty {
                            Text("/\(entry.ipa)/")
                                .font(.title3)
                                .foregroundColor(.white)
                        }
                        
                        if audioFileExists {
                            Image(systemName: "speaker.wave.2.fill")
                                .font(.title3)
                                .foregroundColor(.white)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    audioPlayer.play(filenames: selectedDefinition.possibleAudioFilenames(for: entry.normalized))
                                }
                        }
                    }
                }
                
                Spacer()
            }
            .padding()
            .padding(.bottom, 8)
        }
        .frame(height: (UIScreen.main.bounds.height * 2 / 5) + 100)
        .background(headerGradient)
    }
    
    private var partOfSpeechTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Array(entry.definitions.enumerated()), id: \.offset) { index, definition in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedDefinitionIndex = index
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(definition.partOfSpeech)
                                .font(.subheadline)
                            
                            if definition.contentWarning {
                                Image(systemName: "info.circle.fill")
                                    .font(.caption)
                                    .foregroundColor(selectedDefinitionIndex == index ? .white.opacity(0.8) : .orange)
                                    .onTapGesture {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            showContentWarningTooltip = true
                                        }
                                    }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            selectedDefinitionIndex == index ?
                            Color.blue : Color.gray.opacity(0.2)
                        )
                        .foregroundColor(
                            selectedDefinitionIndex == index ?
                            .white : .primary
                        )
                        .cornerRadius(8)
                    }
                }
            }
        }
    }
    
    private var definitionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("DEFINITIONS \(entry.definitions.count)")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .textCase(.uppercase)
            
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top) {
                    Text("1.")
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    Text(selectedDefinition.enDefinition)
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                
                if !selectedDefinition.twiDefinition.isEmpty {
                    HStack(alignment: .top) {
                        Text("•")
                            .font(.body)
                            .foregroundColor(.secondary)
                        
                        Text(selectedDefinition.twiDefinition)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
    
    private var synonymsAntonymsSection: some View {
        HStack(alignment: .top, spacing: 40) {
            if !selectedDefinition.synonyms.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("SYNONYMS \(selectedDefinition.synonyms.count)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                        .textCase(.uppercase)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(selectedDefinition.synonyms.prefix(7), id: \.self) { synonym in
                            Text(synonym)
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                        
                        if selectedDefinition.synonyms.count > 7 {
                            Text("...")
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            
            if !selectedDefinition.antonyms.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("ANTONYMS \(selectedDefinition.antonyms.count)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                        .textCase(.uppercase)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(selectedDefinition.antonyms.prefix(4), id: \.self) { antonym in
                            Text(antonym)
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                        
                        if selectedDefinition.antonyms.count > 4 {
                            Text("...")
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            
            Spacer()
        }
    }
    
    private var etymologySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("ETYMOLOGY")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .textCase(.uppercase)
            
            Text(selectedDefinition.morphology)
                .font(.body)
                .foregroundColor(.secondary)
        }
    }
    
    private var examplesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("EXAMPLES")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .textCase(.uppercase)
            
            VStack(alignment: .leading, spacing: 16) {
                ForEach(selectedDefinition.examples) { example in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(example.twi)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .italic()
                        
                        Text(example.en)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
    
    private var dialectsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("DIALECTS")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .textCase(.uppercase)
            
            HStack(spacing: 8) {
                ForEach(entry.dialects, id: \.self) { dialect in
                    Text(dialect)
                        .font(.caption)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(8)
                }
            }
        }
    }
    
    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("TAGS")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .textCase(.uppercase)
            
            FlowLayout(spacing: 8) {
                ForEach(selectedDefinition.tags, id: \.self) { tag in
                    Text(tag)
                        .font(.caption)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.purple.opacity(0.1))
                        .foregroundColor(.purple)
                        .cornerRadius(8)
                }
            }
        }
    }
    
    private var frequencySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("FREQUENCY")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .textCase(.uppercase)
            
            HStack(spacing: 12) {
                HStack(spacing: 4) {
                    ForEach(0..<3) { index in
                        Circle()
                            .fill(index < frequencyBars(selectedDefinition.frequency) ? Color.green : Color.gray.opacity(0.2))
                            .frame(width: 8, height: 8)
                    }
                }
                
                Text(frequencyLabel(selectedDefinition.frequency))
                    .font(.body)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private func frequencyBars(_ frequency: Int) -> Int {
        if frequency >= 80 { return 3 }
        if frequency >= 50 { return 2 }
        return 1
    }
    
    private func frequencyLabel(_ frequency: Int) -> String {
        if frequency >= 80 { return "Very Common" }
        if frequency >= 50 { return "Common" }
        return "Less Common"
    }
}

struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.replacingUnspecifiedDimensions().width, subviews: subviews, spacing: spacing)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.frames[index].minX,
                                     y: bounds.minY + result.frames[index].minY),
                         proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var frames: [CGRect] = []
        var size: CGSize = .zero
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var currentX: CGFloat = 0
            var currentY: CGFloat = 0
            var lineHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if currentX + size.width > maxWidth && currentX > 0 {
                    currentX = 0
                    currentY += lineHeight + spacing
                    lineHeight = 0
                }
                
                frames.append(CGRect(x: currentX, y: currentY, width: size.width, height: size.height))
                lineHeight = max(lineHeight, size.height)
                currentX += size.width + spacing
            }
            
            self.size = CGSize(width: maxWidth, height: currentY + lineHeight)
        }
    }
}

#Preview {
    NavigationStack {
        EntryDetailView(entry: Entry(
            id: "aboa",
            headword: "aboa",
            normalized: "aboa",
            dialects: ["Asante", "Akuapem"],
            syllables: "a-bo-a",
            ipa: "abòá",
            definitions: [
                Definition(
                    definitionNumber: 1,
                    partOfSpeech: "noun",
                    enDefinition: "Animal; wild beast",
                    twiDefinition: "Aboa a ɔte wuram",
                    examples: [
                        Example(twi: "Aboa no rewe wura no", en: "The animal is eating grass"),
                        Example(twi: "Yɛhunuu aboa kɛseɛ bi wɔ kwaeɛ mu", en: "We saw a large animal in the forest")
                    ],
                    synonyms: ["creature", "beast"],
                    antonyms: ["human"],
                    morphology: "Root: aboa",
                    frequency: 85,
                    tags: ["nature", "wildlife"],
                    contentWarning: false
                )
            ],
            attribution: "manual_import",
            createdAt: "",
            updatedAt: ""
        ))
    }
}
