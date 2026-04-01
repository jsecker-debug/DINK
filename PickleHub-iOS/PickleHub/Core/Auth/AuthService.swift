import Foundation
import Observation
import Supabase

// MARK: - Auth Error Types

enum AuthError: LocalizedError {
    case invalidCredentials
    case emailNotConfirmed
    case userAlreadyRegistered
    case profileCreationFailed(String)
    case invitationInvalid
    case invitationExpired
    case invitationProcessingFailed(String)
    case profileLoadFailed(String)
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Invalid email or password. Please check your credentials."
        case .emailNotConfirmed:
            return "Please check your email and click the confirmation link before signing in."
        case .userAlreadyRegistered:
            return "An account with this email already exists. Please sign in instead."
        case .profileCreationFailed(let detail):
            return "Failed to create user profile: \(detail)"
        case .invitationInvalid:
            return "Invalid or expired invitation link."
        case .invitationExpired:
            return "This invitation has expired."
        case .invitationProcessingFailed(let detail):
            return "Error processing invitation: \(detail)"
        case .profileLoadFailed(let detail):
            return "Failed to load user profile: \(detail)"
        case .unknown(let message):
            return message
        }
    }
}

// MARK: - Invite Data

struct InviteData: Sendable {
    let token: String
    let clubName: String
    let inviterName: String
    let clubId: String
    let email: String
}

// MARK: - Auth Service

@Observable
@MainActor
final class AuthService {
    var user: Auth.User?
    var session: Auth.Session?
    var userProfile: UserProfile?
    var isLoading = true
    var isAuthenticated: Bool { session != nil }
    var pendingInvite: InviteData?

    init() {
        Task { await listenToAuthChanges() }
    }

    // MARK: - Auth State Listener

    private func listenToAuthChanges() async {
        for await (event, session) in supabase.auth.authStateChanges {
            self.session = session
            self.user = session?.user

            switch event {
            case .initialSession:
                if let userId = session?.user.id {
                    await loadUserProfile(userId: userId)
                }
                self.isLoading = false

            case .signedIn:
                if let userId = session?.user.id {
                    await loadUserProfile(userId: userId)
                }

            case .signedOut:
                self.userProfile = nil

            case .tokenRefreshed:
                break

            case .passwordRecovery:
                // The UI layer can observe this event via the session state
                break

            case .userUpdated:
                if let userId = session?.user.id {
                    await loadUserProfile(userId: userId)
                }

            default:
                break
            }
        }
    }

    // MARK: - Sign In

    func signIn(email: String, password: String) async throws {
        do {
            let session = try await supabase.auth.signIn(
                email: email,
                password: password
            )
            self.session = session
            self.user = session.user
            await loadUserProfile(userId: session.user.id)
        } catch {
            throw mapAuthError(error)
        }
    }

    // MARK: - Sign Up

    func signUp(
        email: String,
        password: String,
        firstName: String,
        lastName: String,
        phone: String,
        skillLevel: Double,
        gender: String
    ) async throws {
        do {
            let authResponse = try await supabase.auth.signUp(
                email: email,
                password: password
            )
            self.user = authResponse.user

            // Create user profile matching the web app's fields
            let userId = authResponse.user.id
            try await createUserProfile(
                userId: userId,
                firstName: firstName,
                lastName: lastName,
                email: email,
                phone: phone,
                skillLevel: skillLevel,
                gender: gender
            )
        } catch let error as AuthError {
            throw error
        } catch {
            throw mapAuthError(error)
        }
    }

    // MARK: - Sign Out

    func signOut() async throws {
        try await supabase.auth.signOut()
        self.user = nil
        self.session = nil
        self.userProfile = nil
        self.pendingInvite = nil
    }

    // MARK: - Password Reset

    func resetPassword(email: String) async throws {
        try await supabase.auth.resetPasswordForEmail(email)
    }

    // MARK: - Profile Loading

    func loadUserProfile(userId: UUID) async {
        do {
            let profile: UserProfile = try await supabase
                .from("user_profiles")
                .select()
                .eq("id", value: userId.uuidString)
                .single()
                .execute()
                .value
            self.userProfile = profile
        } catch {
            print("Failed to load user profile: \(error)")
            self.userProfile = nil
        }
    }

    /// Force-refresh the current user's profile from the database.
    func refreshUserProfile() async {
        guard let userId = user?.id else { return }
        await loadUserProfile(userId: userId)
    }

    // MARK: - Profile Creation

    private func createUserProfile(
        userId: UUID,
        firstName: String,
        lastName: String,
        email: String,
        phone: String,
        skillLevel: Double,
        gender: String
    ) async throws {
        struct ProfileInsert: Encodable {
            let id: String
            let firstName: String
            let lastName: String
            let phone: String
            let email: String
            let skillLevel: Double
            let gender: String
            let totalGamesPlayed: Int
            let wins: Int
            let losses: Int
            let isActive: Bool

            enum CodingKeys: String, CodingKey {
                case id
                case firstName = "first_name"
                case lastName = "last_name"
                case phone, email
                case skillLevel = "skill_level"
                case gender
                case totalGamesPlayed = "total_games_played"
                case wins, losses
                case isActive = "is_active"
            }
        }

        do {
            let profile = ProfileInsert(
                id: userId.uuidString,
                firstName: firstName,
                lastName: lastName,
                phone: phone,
                email: email,
                skillLevel: skillLevel,
                gender: gender,
                totalGamesPlayed: 0,
                wins: 0,
                losses: 0,
                isActive: true
            )
            try await supabase.from("user_profiles")
                .upsert(profile)
                .execute()
        } catch {
            throw AuthError.profileCreationFailed(error.localizedDescription)
        }
    }

    // MARK: - Invite Token Processing

    /// Looks up an invitation by token, validates it, and returns invite data.
    /// Sets `pendingInvite` with the result so the UI can display the invitation banner.
    @discardableResult
    func processInviteToken(_ token: String) async throws -> InviteData {
        // Fetch the pending invitation
        struct Invitation: Decodable {
            let token: String
            let clubId: String
            let email: String
            let invitedBy: String
            let status: String
            let expiresAt: String

            enum CodingKeys: String, CodingKey {
                case token
                case clubId = "club_id"
                case email
                case invitedBy = "invited_by"
                case status
                case expiresAt = "expires_at"
            }
        }

        let invitation: Invitation
        do {
            invitation = try await supabase
                .from("club_invitations")
                .select()
                .eq("token", value: token)
                .eq("status", value: "pending")
                .single()
                .execute()
                .value
        } catch {
            throw AuthError.invitationInvalid
        }

        // Check expiration
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let expiresAt = formatter.date(from: invitation.expiresAt),
           expiresAt < Date() {
            throw AuthError.invitationExpired
        }

        // Fetch club name
        struct ClubInfo: Decodable {
            let name: String
        }
        let clubName: String
        do {
            let club: ClubInfo = try await supabase
                .from("clubs")
                .select("name")
                .eq("id", value: invitation.clubId)
                .single()
                .execute()
                .value
            clubName = club.name
        } catch {
            clubName = "Unknown Club"
        }

        // Fetch inviter name
        struct InviterInfo: Decodable {
            let firstName: String
            let lastName: String

            enum CodingKeys: String, CodingKey {
                case firstName = "first_name"
                case lastName = "last_name"
            }
        }
        let inviterName: String
        do {
            let inviter: InviterInfo = try await supabase
                .from("user_profiles")
                .select("first_name, last_name")
                .eq("id", value: invitation.invitedBy)
                .single()
                .execute()
                .value
            inviterName = "\(inviter.firstName) \(inviter.lastName)"
        } catch {
            inviterName = "Someone"
        }

        let inviteData = InviteData(
            token: token,
            clubName: clubName,
            inviterName: inviterName,
            clubId: invitation.clubId,
            email: invitation.email
        )
        self.pendingInvite = inviteData
        return inviteData
    }

    /// After signup or signin, accepts the invitation and creates the club membership.
    func acceptInvitation(token: String, userId: UUID) async throws {
        // Fetch the invitation to get club_id
        struct Invitation: Decodable {
            let clubId: String

            enum CodingKeys: String, CodingKey {
                case clubId = "club_id"
            }
        }

        let invitation: Invitation
        do {
            invitation = try await supabase
                .from("club_invitations")
                .select("club_id")
                .eq("token", value: token)
                .eq("status", value: "pending")
                .single()
                .execute()
                .value
        } catch {
            throw AuthError.invitationInvalid
        }

        // Mark invitation as accepted
        do {
            try await supabase
                .from("club_invitations")
                .update([
                    "status": "accepted",
                    "accepted_at": ISO8601DateFormatter().string(from: Date()),
                    "accepted_by": userId.uuidString
                ])
                .eq("token", value: token)
                .execute()
        } catch {
            throw AuthError.invitationProcessingFailed(
                "Failed to update invitation: \(error.localizedDescription)"
            )
        }

        // Create club membership
        do {
            try await supabase
                .from("club_memberships")
                .insert([
                    "club_id": invitation.clubId,
                    "user_id": userId.uuidString,
                    "role": "member",
                    "status": "active"
                ])
                .execute()
        } catch {
            throw AuthError.invitationProcessingFailed(
                "Failed to create club membership: \(error.localizedDescription)"
            )
        }

        // Clear the pending invite
        self.pendingInvite = nil
    }

    // MARK: - Error Mapping

    private func mapAuthError(_ error: Error) -> AuthError {
        let message = error.localizedDescription
        if message.contains("Email not confirmed") {
            return .emailNotConfirmed
        } else if message.contains("Invalid login credentials") {
            return .invalidCredentials
        } else if message.contains("User already registered") {
            return .userAlreadyRegistered
        }
        return .unknown(message)
    }
}
