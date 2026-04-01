import SwiftUI

struct OnboardingView: View {
    @Environment(AuthService.self) private var authService
    @Environment(ClubService.self) private var clubService

    @State private var showCreateClub = false
    @State private var showJoinClub = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    Spacer(minLength: 40)

                    // Welcome header
                    VStack(spacing: 8) {
                        Image(systemName: "figure.pickleball")
                            .font(.system(size: 48))
                            .foregroundStyle(.tint)
                            .accessibilityHidden(true)

                        Text("Welcome to PickleHub!")
                            .font(.title.bold())

                        if let name = authService.userProfile?.firstName {
                            Text("Hi \(name), let's get you set up.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        } else {
                            Text("Let's get you into a club.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }

                    // Options
                    VStack(spacing: 16) {
                        // Create a Club
                        Button {
                            showCreateClub = true
                        } label: {
                            HStack(spacing: 16) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(.green)
                                    .frame(width: 40)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Create a Club")
                                        .font(.headline)
                                    Text("Start your own pickleball club and invite players.")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .foregroundStyle(.tertiary)
                            }
                            .padding(16)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background {
                                if #available(iOS 26, *) {
                                    Color.clear
                                } else {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(.secondarySystemBackground))
                                }
                            }
                            .liquidGlassStatic(cornerRadius: 12)
                        }
                        .buttonStyle(.plain)

                        // Join a Club
                        Button {
                            showJoinClub = true
                        } label: {
                            HStack(spacing: 16) {
                                Image(systemName: "person.badge.plus")
                                    .font(.title2)
                                    .foregroundStyle(.blue)
                                    .frame(width: 40)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Join a Club")
                                        .font(.headline)
                                    Text("Browse existing clubs and request to join.")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .foregroundStyle(.tertiary)
                            }
                            .padding(16)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background {
                                if #available(iOS 26, *) {
                                    Color.clear
                                } else {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(.secondarySystemBackground))
                                }
                            }
                            .liquidGlassStatic(cornerRadius: 12)
                        }
                        .buttonStyle(.plain)
                    }

                    // Sign out option
                    Button("Sign Out", role: .destructive) {
                        Task { try? await authService.signOut() }
                    }
                    .font(.subheadline)
                    .padding(.top, 16)

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 20)
            }
            .navigationDestination(isPresented: $showCreateClub) {
                CreateClubView()
            }
            .navigationDestination(isPresented: $showJoinClub) {
                ClubDiscoveryView()
            }
        }
    }
}
