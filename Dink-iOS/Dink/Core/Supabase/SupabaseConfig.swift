import Foundation

enum SupabaseConfig {
    static let url: URL = {
        let urlString = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String
            ?? ProcessInfo.processInfo.environment["SUPABASE_URL"]

        guard let urlString, let url = URL(string: urlString) else {
            fatalError("SUPABASE_URL is not configured. Add it to Secrets.xcconfig.")
        }
        return url
    }()

    static let anonKey: String = {
        let key = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String
            ?? ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"]

        guard let key, !key.isEmpty else {
            fatalError("SUPABASE_ANON_KEY is not configured. Add it to Secrets.xcconfig.")
        }
        return key
    }()
}
