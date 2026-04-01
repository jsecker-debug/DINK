import Foundation

enum SupabaseConfig {
    static let url: URL = {
        guard let urlString = ProcessInfo.processInfo.environment["SUPABASE_URL"],
              let url = URL(string: urlString) else {
            // Fallback for when environment variables aren't set (e.g. previews)
            return URL(string: "https://lqdlarbcrdkqpnsdkxcv.supabase.co")!
        }
        return url
    }()

    static let anonKey: String = {
        guard let key = ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"], !key.isEmpty else {
            // Fallback for when environment variables aren't set (e.g. previews)
            return "sb_publishable_6Os07h5oTWwzjCRXj50Vgg_xK5IkieG"
        }
        return key
    }()
}
