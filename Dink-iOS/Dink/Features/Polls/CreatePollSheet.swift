import SwiftUI

struct CreatePollSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(ClubService.self) private var clubService
    @Environment(AuthService.self) private var authService
    @Environment(ToastManager.self) private var toastManager

    @State private var question = ""
    @State private var options: [String] = ["", ""]
    @State private var hasExpiry = false
    @State private var expiresAt = Date().addingTimeInterval(86400)
    @State private var allowMultiple = false
    @State private var isSaving = false

    var onSaved: () async -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("Question") {
                    TextField("What do you want to ask?", text: $question, axis: .vertical)
                        .lineLimit(2...5)
                }

                Section("Options") {
                    ForEach(options.indices, id: \.self) { index in
                        HStack {
                            TextField("Option \(index + 1)", text: $options[index])
                            if options.count > 2 {
                                Button {
                                    options.remove(at: index)
                                } label: {
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundStyle(.red)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    Button {
                        options.append("")
                    } label: {
                        Label("Add Option", systemImage: "plus.circle.fill")
                    }
                    .disabled(options.count >= 10)
                }

                Section {
                    Toggle("Allow multiple selections", isOn: $allowMultiple)

                    Toggle("Set expiry date", isOn: $hasExpiry)

                    if hasExpiry {
                        DatePicker(
                            "Expires",
                            selection: $expiresAt,
                            in: Date()...,
                            displayedComponents: [.date, .hourAndMinute]
                        )
                    }
                }
            }
            .navigationTitle("Create Poll")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        Task { await createPoll() }
                    }
                    .disabled(!isValid || isSaving)
                }
            }
        }
    }

    private var isValid: Bool {
        !question.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        && options.filter({ !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }).count >= 2
    }

    private func createPoll() async {
        guard let clubId = clubService.selectedClubId,
              let userId = authService.user?.id else { return }
        isSaving = true
        defer { isSaving = false }

        let validOptions = options
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        do {
            _ = try await PollRepository().createPoll(
                clubId: clubId,
                question: question.trimmingCharacters(in: .whitespacesAndNewlines),
                type: "standard",
                options: validOptions,
                expiresAt: hasExpiry ? expiresAt : nil,
                allowMultiple: allowMultiple,
                createdBy: userId
            )
            toastManager.show("Poll created", type: .success)
            await onSaved()
            dismiss()
        } catch {
            toastManager.show("Failed to create poll", type: .error)
            print("Failed to create poll: \(error)")
        }
    }
}
