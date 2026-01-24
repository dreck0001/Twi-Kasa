import SwiftUI

struct CachedAsyncImage<Content: View>: View {
    let urls: [URL]
    let content: (AsyncImagePhase) -> Content
    
    @State private var phase: AsyncImagePhase = .empty
    @State private var isLoading = false
    
    init(url: URL?, @ViewBuilder content: @escaping (AsyncImagePhase) -> Content) {
        self.urls = url.map { [$0] } ?? []
        self.content = content
    }
    
    init(urls: [URL], @ViewBuilder content: @escaping (AsyncImagePhase) -> Content) {
        self.urls = urls
        self.content = content
    }
    
    var body: some View {
        content(phase)
            .onAppear {
                loadImage()
            }
    }
    
    private func loadImage() {
        guard !urls.isEmpty, !isLoading else {
            if urls.isEmpty {
                phase = .empty
            }
            return
        }
        
        isLoading = true
        phase = .empty
        
        Task {
            await tryLoadingUrls(urls)
        }
    }
    
    private func tryLoadingUrls(_ urls: [URL]) async {
        for url in urls {
            let urlString = url.absoluteString
            
            // Check cache first
            if let cachedImage = ImageCache.shared.get(url: urlString) {
                await MainActor.run {
                    phase = .success(Image(uiImage: cachedImage))
                    isLoading = false
                }
                return
            }
            
            // Try downloading
            do {
                let (data, response) = try await URLSession.shared.data(from: url)
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    continue
                }
                
                if httpResponse.statusCode == 200 {
                    if let downloadedImage = UIImage(data: data) {
                        ImageCache.shared.set(url: urlString, image: downloadedImage)
                        
                        await MainActor.run {
                            phase = .success(Image(uiImage: downloadedImage))
                            isLoading = false
                        }
                        return
                    }
                }
            } catch {
                // Try next URL
                continue
            }
        }
        
        // All URLs failed
        await MainActor.run {
            phase = .failure(URLError(.cannotDecodeContentData))
            isLoading = false
        }
    }
}
