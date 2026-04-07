import SwiftUI

// MARK: - Liquid Glass View Modifier

struct LiquidGlassModifier: ViewModifier {
    var cornerRadius: CGFloat
    var tintColor: Color?

    func body(content: Content) -> some View {
        if #available(iOS 26, *) {
            if let tint = tintColor {
                content
                    .glassEffect(.regular.interactive(), in: .rect(cornerRadius: cornerRadius))
                    .tint(tint)
            } else {
                content
                    .glassEffect(.regular.interactive(), in: .rect(cornerRadius: cornerRadius))
            }
        } else {
            content
                .background(
                    .ultraThinMaterial,
                    in: RoundedRectangle(cornerRadius: cornerRadius)
                )
        }
    }
}

/// Non-interactive variant for static glass surfaces.
struct LiquidGlassStaticModifier: ViewModifier {
    var cornerRadius: CGFloat
    var tintColor: Color?

    func body(content: Content) -> some View {
        if #available(iOS 26, *) {
            if let tint = tintColor {
                content
                    .glassEffect(.regular, in: .rect(cornerRadius: cornerRadius))
                    .tint(tint)
            } else {
                content
                    .glassEffect(.regular, in: .rect(cornerRadius: cornerRadius))
            }
        } else {
            content
                .background(
                    .ultraThinMaterial,
                    in: RoundedRectangle(cornerRadius: cornerRadius)
                )
        }
    }
}

// MARK: - Card-style Glass Modifier

struct LiquidGlassCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26, *) {
            content
                .glassEffect(.regular, in: .rect(cornerRadius: 10))
        } else {
            content
                .background(
                    .ultraThinMaterial,
                    in: RoundedRectangle(cornerRadius: 10)
                )
        }
    }
}

// MARK: - Prominent Glass Modifier

struct LiquidGlassProminentModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26, *) {
            content
                .glassEffect(.regular.interactive(), in: .capsule)
        } else {
            content
                .background(.ultraThinMaterial, in: Capsule())
        }
    }
}

// MARK: - View Extensions

extension View {
    /// Applies a Liquid Glass effect on iOS 26+ with an ultraThinMaterial fallback.
    /// Uses the interactive variant suitable for tappable elements.
    func liquidGlass(cornerRadius: CGFloat = 16, tint: Color? = nil) -> some View {
        modifier(LiquidGlassModifier(cornerRadius: cornerRadius, tintColor: tint))
    }

    /// Applies a non-interactive Liquid Glass effect for static surfaces.
    func liquidGlassStatic(cornerRadius: CGFloat = 16, tint: Color? = nil) -> some View {
        modifier(LiquidGlassStaticModifier(cornerRadius: cornerRadius, tintColor: tint))
    }

    /// Card-style glass effect with standard 10pt corner radius.
    func liquidGlassCard() -> some View {
        modifier(LiquidGlassCardModifier())
    }

    /// Prominent glass for primary action buttons (capsule shape).
    func liquidGlassProminent() -> some View {
        modifier(LiquidGlassProminentModifier())
    }
}

// MARK: - Glass Effect Container

/// Wraps content in a GlassEffectContainer on iOS 26+ for grouped glass elements.
struct LiquidGlassContainer<Content: View>: View {
    let spacing: CGFloat
    let content: Content

    init(spacing: CGFloat = 24, @ViewBuilder content: () -> Content) {
        self.spacing = spacing
        self.content = content()
    }

    var body: some View {
        if #available(iOS 26, *) {
            GlassEffectContainer(spacing: spacing) { content }
        } else {
            content
        }
    }
}
