import SwiftUI

@Observable
@MainActor
final class ToastManager {
    enum ToastType {
        case success, error, info

        var icon: String {
            switch self {
            case .success: return "checkmark.circle.fill"
            case .error: return "xmark.circle.fill"
            case .info: return "info.circle.fill"
            }
        }

        var tintColor: Color {
            switch self {
            case .success: return .dinkGreen
            case .error: return .red
            case .info: return .dinkTeal
            }
        }
    }

    struct Toast: Identifiable {
        let id = UUID()
        let message: String
        let type: ToastType
    }

    private(set) var currentToast: Toast?
    private var dismissTask: Task<Void, Never>?

    func show(_ message: String, type: ToastType = .info) {
        dismissTask?.cancel()
        withAnimation(.spring(duration: 0.35)) {
            currentToast = Toast(message: message, type: type)
        }
        dismissTask = Task {
            try? await Task.sleep(for: .seconds(3))
            guard !Task.isCancelled else { return }
            dismiss()
        }
    }

    func dismiss() {
        withAnimation(.spring(duration: 0.25)) {
            currentToast = nil
        }
    }
}
