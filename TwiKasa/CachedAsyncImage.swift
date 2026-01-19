import SwiftUI

struct CachedAsyncImage<Content: View>: View {
    let url: URL?
    let content: (AsyncImagePhase) -> Content
    
    @State private var phase: AsyncImagePhase = .empty
    @State private var isLoading = false
    
    init(url: URL?, @ViewBuilder content: @escaping (AsyncImagePhase) -> Content) {
        self.url = url
        self.content = content
    }
    
    var body: some View {
        content(phase)
            .onAppear {
                loadImage()
            }
    }
    
    private func loadImage() {
        guard let url = url, !isLoading else {
            if url == nil {
                phase = .empty
            }
            return
        }
        
        let urlString = url.absoluteString
        
        if let cachedImage = ImageCache.shared.get(url: urlString) {
            phase = .success(Image(uiImage: cachedImage))
            return
        }
        
        isLoading = true
        phase = .empty
        
        Task {
            do {
                let (data, response) = try await URLSession.shared.data(from: url)
                
                if let httpResponse = response as? HTTPURLResponse {
                    guard httpResponse.statusCode == 200 else {
                        let error = URLError(.badServerResponse)
                        await MainActor.run {
                            phase = .failure(error)
                            isLoading = false
                        }
                        return
                    }
                }
                
                if let downloadedImage = UIImage(data: data) {
                    ImageCache.shared.set(url: urlString, image: downloadedImage)
                    
                    await MainActor.run {
                        phase = .success(Image(uiImage: downloadedImage))
                        isLoading = false
                    }
                } else {
                    let error = URLError(.cannotDecodeContentData)
                    await MainActor.run {
                        phase = .failure(error)
                        isLoading = false
                    }
                }
            } catch {
                await MainActor.run {
                    phase = .failure(error)
                    isLoading = false
                }
            }
        }
    }
}
