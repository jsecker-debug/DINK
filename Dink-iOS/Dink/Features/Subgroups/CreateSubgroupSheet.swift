import SwiftUI

struct CreateSubgroupSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(ClubService.self) private var clubService
    @Environment(ToastManager.self) private var toastManager

    @State private var name = ""
    @State private var selectedColor = "#007AFF"
    @State private var description = ""
    @State private var isSaving = false

    var onSaved: () async -> Void

    private let presetColors: [(name: String, hex: String)] = [
        ("Blue", "#007AFF"),
        ("Red", "#FF3B30"),
        ("Green", "#34C759"),
        ("Orange", "#FF9500"),
        ("Purple", "#AF52DE"),
        ("Teal", "#5AC8FA"),
        ("Pink", "#FF2D55"),
        ("Yellow", "#FFCC00"),
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section("Subgroup Details") {
                    TextField("Name", text: $name)
                    TextField("Description (optional)", text: $description)
                }

                Section("Color") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 4), spacing: 16) {
                        ForEach(presetColors, id: \.hex) { preset in
                            Button {
                                selectedColor = preset.hex
                            } label: {
                                ZStack {
                                    Circle()
                                        .fill(Color(hex: preset.hex))
                                        .frame(width: 40, height: 40)
                                    if selectedColor == preset.hex {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundStyle(.white)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(preset.name)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("New Subgroup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        Task { await saveSubgroup() }
                    }
                    .disabled(name.isEmpty || isSaving)
                }
            }
        }
    }

    private func saveSubgroup() async {
        isSaving = true
        defer { isSaving = false }

        let trimmedDescription = description.isEmpty ? nil : description

        do {
            guard let clubId = clubService.selectedClubId else { return }
            _ = try await SubgroupRepository().createSubgroup(
                clubId: clubId,
                name: name,
                color: selectedColor,
                description: trimmedDescription
            )
            toastManager.show("Subgroup created", type: .success)
            await onSaved()
            dismiss()
        } catch {
            toastManager.show("Failed to create subgroup: \(error.localizedDescription)", type: .error)
        }
    }
}
