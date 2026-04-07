import SwiftUI
import UIKit

/// Renders a SwiftUI view to a multi-page A4 PDF using `ImageRenderer` and Core Graphics.
@MainActor
struct PDFExportService {

    /// A4 page dimensions in points (72 dpi).
    static let pageWidth: CGFloat = 595
    static let pageHeight: CGFloat = 842

    /// Renders the given SwiftUI view into PDF `Data`.
    ///
    /// The view is rendered at A4 width via `ImageRenderer`, then sliced vertically
    /// across as many A4 pages as needed — mirroring the web app's html2canvas approach.
    @MainActor
    static func render<V: View>(_ view: V) -> Data? {
        let renderer = ImageRenderer(content: view.frame(width: pageWidth))
        renderer.scale = 2.0 // retina quality

        guard let uiImage = renderer.uiImage else { return nil }

        let imgWidth = uiImage.size.width
        let imgHeight = uiImage.size.height

        // Scale factor so the image fills the page width exactly.
        let scale = pageWidth / imgWidth
        let scaledHeight = imgHeight * scale

        let pagesNeeded = Int(ceil(scaledHeight / pageHeight))
        guard pagesNeeded > 0 else { return nil }

        let pdfData = NSMutableData()
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)

        UIGraphicsBeginPDFContextToData(pdfData, pageRect, nil)

        guard let cgImage = uiImage.cgImage else {
            UIGraphicsEndPDFContext()
            return nil
        }

        for page in 0..<pagesNeeded {
            UIGraphicsBeginPDFPageWithInfo(pageRect, nil)

            guard let ctx = UIGraphicsGetCurrentContext() else { continue }

            // Core Graphics has origin at bottom-left; flip to top-left.
            ctx.translateBy(x: 0, y: pageHeight)
            ctx.scaleBy(x: 1, y: -1)

            // Offset so the correct vertical slice of the image is visible.
            let yOffset = CGFloat(page) * pageHeight
            let drawRect = CGRect(x: 0, y: yOffset - 0, width: pageWidth, height: scaledHeight)
            ctx.draw(cgImage, in: drawRect)
        }

        UIGraphicsEndPDFContext()
        return pdfData as Data
    }
}
