import SwiftUI

class ImageCache {
    static let shared = ImageCache()
    
    var disableCaching = false
    
    private let cache = NSCache<NSString, UIImage>()
    private let fileManager = FileManager.default
    private lazy var cacheDirectory: URL = {
        let paths = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)
        let cacheDir = paths[0].appendingPathComponent("ImageCache")
        
        if !fileManager.fileExists(atPath: cacheDir.path) {
            try? fileManager.createDirectory(at: cacheDir, withIntermediateDirectories: true)
        }
        
        return cacheDir
    }()
    
    private init() {
        cache.countLimit = 100
        cache.totalCostLimit = 100 * 1024 * 1024
    }
    
    func get(url: String) -> UIImage? {
        if disableCaching { return nil }
        
        let key = NSString(string: url)
        
        if let image = cache.object(forKey: key) {
            return image
        }
        
        if let image = loadFromDisk(url: url) {
            cache.setObject(image, forKey: key)
            return image
        }
        
        return nil
    }
    
    func set(url: String, image: UIImage) {
        if disableCaching { return }
        
        let key = NSString(string: url)
        cache.setObject(image, forKey: key)
        saveToDisk(url: url, image: image)
    }
    
    private func loadFromDisk(url: String) -> UIImage? {
        let fileURL = cacheDirectory.appendingPathComponent(url.md5)
        
        guard fileManager.fileExists(atPath: fileURL.path),
              let data = try? Data(contentsOf: fileURL),
              let image = UIImage(data: data) else {
            return nil
        }
        
        return image
    }
    
    private func saveToDisk(url: String, image: UIImage) {
        let fileURL = cacheDirectory.appendingPathComponent(url.md5)
        
        guard let data = image.jpegData(compressionQuality: 0.8) else {
            return
        }
        
        try? data.write(to: fileURL)
    }
    
    func clearCache() {
        cache.removeAllObjects()
        try? fileManager.removeItem(at: cacheDirectory)
    }
}

extension String {
    var md5: String {
        let hash = self.hash
        return String(format: "%016x", hash)
    }
}
