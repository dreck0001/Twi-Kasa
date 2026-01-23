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
        print("CachedAsyncImage: Loading \(urlString)")
        
        if let cachedImage = ImageCache.shared.get(url: urlString) {
            print("CachedAsyncImage: Found in cache")
            phase = .success(Image(uiImage: cachedImage))
            return
        }
        
        isLoading = true
        phase = .empty
        
        Task {
            do {
                let (data, response) = try await URLSession.shared.data(from: url)
                
                if let httpResponse = response as? HTTPURLResponse {
                    print("CachedAsyncImage: HTTP status \(httpResponse.statusCode)")
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
                    print("CachedAsyncImage: Successfully loaded image")
                    ImageCache.shared.set(url: urlString, image: downloadedImage)
                    
                    await MainActor.run {
                        phase = .success(Image(uiImage: downloadedImage))
                        isLoading = false
                    }
                } else {
                    print("CachedAsyncImage: Failed to decode image data")
                    let error = URLError(.cannotDecodeContentData)
                    await MainActor.run {
                        phase = .failure(error)
                        isLoading = false
                    }
                }
            } catch {
                print("CachedAsyncImage: Error - \(error)")
                await MainActor.run {
                    phase = .failure(error)
                    isLoading = false
                }
            }
        }
    }
}
