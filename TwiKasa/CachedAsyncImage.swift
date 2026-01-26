import SwiftUI

struct CachedAsyncImage<Content: View>: View {
    let urls: [URL]?
    let content: (AsyncImagePhase, CGSize?) -> Content
    
    @State private var phase: AsyncImagePhase = .empty
    @State private var imageSize: CGSize?
    @State private var isLoading = false
    @State private var currentUrlIndex = 0
    
    //multiple urls
    init(urls: [URL]?, @ViewBuilder content: @escaping (AsyncImagePhase, CGSize?) -> Content) {
        self.urls = urls
        self.content = content
    }
    
    //single url
    init(url: URL?, @ViewBuilder content: @escaping (AsyncImagePhase, CGSize?) -> Content) {
        self.urls = url.map { [$0] }
        self.content = content
    }
    
    var body: some View {
        content(phase, imageSize)
            .onAppear {
                loadImage()
            }
    }
    
    private func loadImage() {
        guard let urls = urls, !urls.isEmpty, !isLoading else {
            if urls == nil || urls?.isEmpty == true {
                phase = .empty
                imageSize = nil
            }
            return
        }
        
        let currentUrl = urls[currentUrlIndex]
        let urlString = currentUrl.absoluteString
        
        // check cache first
        if let cachedImage = ImageCache.shared.get(url: urlString) {
            imageSize = cachedImage.size
            phase = .success(Image(uiImage: cachedImage))
            return
        }
        
        isLoading = true
        phase = .empty
        
        Task {
            do {
                let (data, response) = try await URLSession.shared.data(from: currentUrl)
                
                if let httpResponse = response as? HTTPURLResponse {
                    guard httpResponse.statusCode == 200 else {
                        //try next url
                        if currentUrlIndex < urls.count - 1 {
                            await MainActor.run {
                                currentUrlIndex += 1
                                isLoading = false
                            }
                            loadImage()
                        } else {
                            let error = URLError(.badServerResponse)
                            await MainActor.run {
                                phase = .failure(error)
                                isLoading = false
                            }
                        }
                        return
                    }
                }
                
                if let downloadedImage = UIImage(data: data) {
                    let size = downloadedImage.size
                    ImageCache.shared.set(url: urlString, image: downloadedImage)
                    
                    await MainActor.run {
                        imageSize = size
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
