import SwiftUI
import CryptoKit

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
        
        // Recreate the directory after clearing
        if !fileManager.fileExists(atPath: cacheDirectory.path) {
            try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        }
    }
    
    /// Returns the size of the disk cache in bytes
    func getCacheSize() -> Int64 {
        guard let enumerator = fileManager.enumerator(at: cacheDirectory, includingPropertiesForKeys: [.fileSizeKey]) else {
            return 0
        }
        
        var totalSize: Int64 = 0
        for case let fileURL as URL in enumerator {
            guard let resourceValues = try? fileURL.resourceValues(forKeys: [.fileSizeKey]),
                  let fileSize = resourceValues.fileSize else {
                continue
            }
            totalSize += Int64(fileSize)
        }
        return totalSize
    }
    
    /// Returns a human-readable string of the cache size (e.g., "2.5 MB")
    func getCacheSizeFormatted() -> String {
        let bytes = Double(getCacheSize())
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
    
    /// Removes a specific cached image
    func remove(url: String) {
        let key = NSString(string: url)
        cache.removeObject(forKey: key)
        
        let fileURL = cacheDirectory.appendingPathComponent(url.md5)
        try? fileManager.removeItem(at: fileURL)
    }
}

extension String {
    /// Generates a proper MD5 hash of the string for use as a cache key.
    /// Uses CryptoKit's Insecure.MD5 which is appropriate for non-security purposes like file naming.
    var md5: String {
        guard let data = self.data(using: .utf8) else {
            // Fallback to simple hash if string can't be converted to UTF8
            return String(format: "%016x", self.hash)
        }
        
        let digest = Insecure.MD5.hash(data: data)
        return digest.map { String(format: "%02hhx", $0) }.joined()
    }
}
