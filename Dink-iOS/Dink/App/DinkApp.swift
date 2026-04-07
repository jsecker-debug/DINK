import SwiftUI

@main
struct DinkApp: App {
    @State private var authService = AuthService()
    @State private var clubService = ClubService()
    @State private var toastManager = ToastManager()
    @State private var router = NavigationRouter()

    private var isTesting: Bool {
        ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
    }

    var body: some Scene {
        WindowGroup {
            if isTesting {
                Text("Running Tests")
            } else {
                ContentView()
                    .environment(authService)
                    .environment(clubService)
                    .environment(toastManager)
                    .environment(router)
                    .tint(.dinkAccent)
                    .toastOverlay(toastManager: toastManager)
                    .onOpenURL { url in
                        handleDeepLink(url)
                    }
            }
        }
    }

    // MARK: - Deep Link Handling

    private func handleDeepLink(_ url: URL) {
        // Handle dink:// custom scheme (invite links)
        if url.scheme == "dink" {
            handleCustomSchemeURL(url)
            return
        }

        // Handle universal links (Supabase auth callbacks, e.g. email confirmation)
        if isSupabaseAuthCallback(url) {
            handleSupabaseAuthCallback(url)
            return
        }
    }

    /// Handles `dink://invite?token=...` deep links.
    private func handleCustomSchemeURL(_ url: URL) {
        guard url.host == "invite",
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let token = components.queryItems?.first(where: { $0.name == "token" })?.value
        else { return }

        if authService.isAuthenticated {
            // Process the invite immediately
            Task {
                try? await authService.processInviteToken(token)
            }
        } else {
            // Store for processing after authentication
            router.pendingInviteToken = token
        }
    }

    /// Checks whether the URL matches a Supabase auth callback pattern.
    private func isSupabaseAuthCallback(_ url: URL) -> Bool {
        let urlString = url.absoluteString
        return urlString.contains("auth/v1/callback")
            || urlString.contains("auth/confirm")
            || urlString.contains("type=signup")
            || urlString.contains("type=recovery")
            || urlString.contains("type=magiclink")
    }

    /// Delegates Supabase auth callback URLs to the Supabase SDK.
    private func handleSupabaseAuthCallback(_ url: URL) {
        Task {
            do {
                try await supabase.auth.session(from: url)
            } catch {
                print("Supabase auth callback error: \(error)")
            }
        }
    }
}
