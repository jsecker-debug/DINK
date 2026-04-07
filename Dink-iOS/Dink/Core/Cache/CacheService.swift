import Foundation
import Observation

@Observable @MainActor
final class CacheService {
    private let cacheDirectory: URL

    init() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        cacheDirectory = docs.appendingPathComponent("DinkCache", isDirectory: true)
        try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }

    func cache<T: Codable>(_ key: String, data: T) {
        let url = cacheDirectory.appendingPathComponent("\(key).json")
        let wrapper = CacheWrapper(data: data, cachedAt: Date())
        if let encoded = try? JSONEncoder().encode(wrapper) {
            try? encoded.write(to: url)
        }
    }

    func load<T: Codable>(_ key: String, as type: T.Type) -> T? {
        let url = cacheDirectory.appendingPathComponent("\(key).json")
        guard let data = try? Data(contentsOf: url),
              let wrapper = try? JSONDecoder().decode(CacheWrapper<T>.self, from: data) else {
            return nil
        }
        return wrapper.data
    }

    func invalidate(_ key: String) {
        let url = cacheDirectory.appendingPathComponent("\(key).json")
        try? FileManager.default.removeItem(at: url)
    }

    func clearAll() {
        try? FileManager.default.removeItem(at: cacheDirectory)
        try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }
}

private struct CacheWrapper<T: Codable>: Codable {
    let data: T
    let cachedAt: Date
}
