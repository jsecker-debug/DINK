import Foundation
import Supabase

let supabase = SupabaseClient(
    supabaseURL: SupabaseConfig.url,
    supabaseKey: SupabaseConfig.anonKey,
    options: .init(
        auth: .init(
            emitLocalSessionAsInitialSession: true
        )
    )
)
