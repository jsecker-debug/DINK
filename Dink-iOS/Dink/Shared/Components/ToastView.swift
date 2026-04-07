import SwiftUI

struct ToastOverlay: ViewModifier {
    var toastManager: ToastManager

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .top) {
                if let toast = toastManager.currentToast {
                    ToastView(toast: toast) {
                        toastManager.dismiss()
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .zIndex(999)
                }
            }
    }
}

struct ToastView: View {
    let toast: ToastManager.Toast
    var onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: toast.type.icon)
                .font(.body.bold())
                .foregroundStyle(toast.type.tintColor)

            Text(toast.message)
                .font(.subheadline)
                .foregroundStyle(.primary)
                .lineLimit(2)

            Spacer(minLength: 0)

            Button {
                onDismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .toastBackground(tint: toast.type.tintColor)
    }
}

// MARK: - Toast Background

private extension View {
    @ViewBuilder
    func toastBackground(tint: Color) -> some View {
        if #available(iOS 26, *) {
            self
                .background(.ultraThinMaterial, in: .rect(cornerRadius: 12))
                .glassEffect(.regular, in: .rect(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(tint.opacity(0.3), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.08), radius: 8, y: 4)
        } else {
            self
                .background(.ultraThinMaterial, in: .rect(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(tint.opacity(0.3), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.08), radius: 8, y: 4)
        }
    }
}

// MARK: - View Extension

extension View {
    func toastOverlay(toastManager: ToastManager) -> some View {
        modifier(ToastOverlay(toastManager: toastManager))
    }
}
