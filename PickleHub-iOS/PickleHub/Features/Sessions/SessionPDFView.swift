import SwiftUI

/// A print-optimised layout of session data, designed for A4 PDF rendering.
/// This view is never displayed on screen — it is passed to `PDFExportService`.
struct SessionPDFView: View {
    let session: ClubSession
    let registrations: [SessionRegistrationWithUser]
    let temporaryParticipants: [TemporaryParticipant]
    let scheduleData: SessionScheduleData?
    let gameScores: [GameScore]

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            headerSection
            Divider()
            overviewSection
            Divider()
            participantsSection

            if let data = scheduleData, !data.rotations.isEmpty {
                Divider()
                courtScheduleSection(data.rotations)
            }

            if !gameScores.isEmpty {
                Divider()
                scoresSection
            }

            Spacer(minLength: 24)
            footerSection
        }
        .padding(32)
        .frame(width: PDFExportService.pageWidth)
        .background(Color.white)
        .foregroundStyle(.black)
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("PickleHub — Session Report")
                .font(.title2.bold())

            Text(session.date ?? "No Date")
                .font(.title3)

            HStack(spacing: 24) {
                if let venue = session.venue {
                    Label(venue, systemImage: "mappin")
                }
                if let status = session.status {
                    Label(status.capitalized, systemImage: "circle.fill")
                }
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
    }

    // MARK: - Overview

    private var overviewSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Overview")
                .font(.headline)

            Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 6) {
                GridRow {
                    Text("Participants:").foregroundStyle(.secondary)
                    Text("\(registeredParticipants.count + temporaryParticipants.count)")
                }
                GridRow {
                    Text("Max Capacity:").foregroundStyle(.secondary)
                    Text("\(session.maxParticipants ?? 0)")
                }
                if let fee = session.feePerPlayer, fee > 0 {
                    GridRow {
                        Text("Fee per Player:").foregroundStyle(.secondary)
                        Text(String(format: "$%.2f", fee))
                    }
                }
            }
            .font(.subheadline)
        }
    }

    // MARK: - Participants

    private var participantsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Participants")
                .font(.headline)

            if !registeredParticipants.isEmpty {
                Text("Registered (\(registeredParticipants.count))")
                    .font(.subheadline.bold())
                    .foregroundStyle(.secondary)

                ForEach(Array(registeredParticipants.enumerated()), id: \.offset) { index, reg in
                    HStack {
                        Text("\(index + 1).")
                            .frame(width: 24, alignment: .trailing)
                        Text(reg.userProfiles?.fullName ?? "Unknown")
                        Spacer()
                        if let level = reg.userProfiles?.skillLevel {
                            Text(String(format: "%.1f", level))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .font(.subheadline)
                }
            }

            if !temporaryParticipants.isEmpty {
                Text("Guests (\(temporaryParticipants.count))")
                    .font(.subheadline.bold())
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)

                ForEach(Array(temporaryParticipants.enumerated()), id: \.offset) { index, tp in
                    HStack {
                        Text("\(registeredParticipants.count + index + 1).")
                            .frame(width: 24, alignment: .trailing)
                        Text(tp.name)
                        Spacer()
                        Text(String(format: "%.1f", tp.skillLevel))
                            .foregroundStyle(.secondary)
                    }
                    .font(.subheadline)
                }
            }
        }
    }

    // MARK: - Court Schedule

    private func courtScheduleSection(_ rotations: [ScheduleRotation]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Court Schedule")
                .font(.headline)

            ForEach(Array(rotations.enumerated()), id: \.offset) { roundIndex, rotation in
                VStack(alignment: .leading, spacing: 6) {
                    Text("Round \(roundIndex + 1)")
                        .font(.subheadline.bold())

                    ForEach(Array(rotation.courts.enumerated()), id: \.offset) { courtIndex, court in
                        HStack(spacing: 4) {
                            Text("Court \(courtIndex + 1):")
                                .foregroundStyle(.secondary)
                            Text(court.team1.joined(separator: " & "))
                            Text("vs")
                                .foregroundStyle(.secondary)
                            Text(court.team2.joined(separator: " & "))
                        }
                        .font(.caption)
                    }

                    if !rotation.resters.isEmpty {
                        HStack(spacing: 4) {
                            Text("Resting:")
                                .foregroundStyle(.secondary)
                            Text(rotation.resters.joined(separator: ", "))
                        }
                        .font(.caption)
                    }
                }
            }
        }
    }

    // MARK: - Scores

    private var scoresSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Game Scores")
                .font(.headline)

            ForEach(gameScores, id: \.id) { score in
                HStack(spacing: 4) {
                    Text("R\(score.rotationNumber) C\(score.courtNumber) G\(score.gameNumber):")
                        .foregroundStyle(.secondary)
                    Text(score.team1Players.joined(separator: " & "))
                    Text("\(score.team1Score)")
                        .bold()
                    Text("-")
                    Text("\(score.team2Score)")
                        .bold()
                    Text(score.team2Players.joined(separator: " & "))
                }
                .font(.caption)
            }
        }
    }

    // MARK: - Footer

    private var footerSection: some View {
        Text("Generated by PickleHub on \(Date.now.formatted(date: .long, time: .shortened))")
            .font(.caption2)
            .foregroundStyle(.secondary)
    }

    // MARK: - Helpers

    private var registeredParticipants: [SessionRegistrationWithUser] {
        registrations.filter { $0.status == "registered" }
    }
}
