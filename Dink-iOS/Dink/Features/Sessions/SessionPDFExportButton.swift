import SwiftUI

/// A button that renders `SessionPDFView` to a PDF and presents the system share sheet.
struct SessionPDFExportButton: View {
    let session: ClubSession
    let registrations: [SessionRegistrationWithUser]
    let temporaryParticipants: [TemporaryParticipant]
    let scheduleData: SessionScheduleData?
    let gameScores: [GameScore]

    @State private var isGenerating = false
    @State private var pdfURL: URL?
    @State private var showShareSheet = false
    @State private var errorMessage: String?

    var body: some View {
        Button {
            Task { await generatePDF() }
        } label: {
            if isGenerating {
                Label {
                    Text("Generating PDF…")
                } icon: {
                    ProgressView()
                }
            } else {
                Label("Export PDF", systemImage: "doc.richtext")
            }
        }
        .disabled(isGenerating)
        .sheet(isPresented: $showShareSheet) {
            if let url = pdfURL {
                ActivityViewController(activityItems: [url])
                    .presentationDetents([.medium, .large])
            }
        }
    }

    // MARK: - PDF Generation

    @MainActor
    private func generatePDF() async {
        isGenerating = true
        defer { isGenerating = false }

        let pdfView = SessionPDFView(
            session: session,
            registrations: registrations,
            temporaryParticipants: temporaryParticipants,
            scheduleData: scheduleData,
            gameScores: gameScores
        )

        guard let data = PDFExportService.render(pdfView) else {
            errorMessage = "Failed to generate PDF"
            return
        }

        let dateSlug = (session.date ?? "session").replacingOccurrences(of: "/", with: "-")
        let fileName = "Dink-Session-\(dateSlug).pdf"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        do {
            try data.write(to: tempURL)
            pdfURL = tempURL
            showShareSheet = true
        } catch {
            errorMessage = "Failed to save PDF: \(error.localizedDescription)"
        }
    }
}

// MARK: - UIActivityViewController wrapper

/// Wraps `UIActivityViewController` for use in SwiftUI via `.sheet`.
struct ActivityViewController: UIViewControllerRepresentable {
    let activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: applicationActivities
        )
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
