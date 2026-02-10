//
// PDFReportExporter.swift
// CodingReviewer
//
// Step 30: PDF export for code review reports.
//

import Foundation

#if canImport(PDFKit)
    import PDFKit
#endif
#if canImport(UIKit)
    import UIKit
#elseif canImport(AppKit)
    import AppKit
#endif

/// Exports code review reports to PDF format.
@MainActor
public final class PDFReportExporter {
    public static let shared = PDFReportExporter()

    private init() {}

    // MARK: - Export

    /// Exports code review issues to PDF.
    /// - Parameters:
    ///   - issues: Array of code issues to include.
    ///   - title: Report title.
    ///   - filename: Output filename.
    /// - Returns: URL to the generated PDF, or nil on failure.
    public func exportReport(issues: [CodeIssue], title: String, filename: String) -> URL? {
        let html = generateHTML(issues: issues, title: title)
        return generatePDF(from: html, filename: filename)
    }

    // MARK: - HTML Generation

    private func generateHTML(issues: [CodeIssue], title: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short

        var html = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="UTF-8">
            <title>\(title)</title>
            <style>
                body { font-family: -apple-system, BlinkMacSystemFont, sans-serif; padding: 40px; }
                h1 { color: #333; margin-bottom: 10px; }
                .date { color: #666; font-size: 14px; margin-bottom: 30px; }
                .summary { background: #f5f5f5; padding: 20px; border-radius: 8px; margin-bottom: 30px; }
                .issue { border-left: 4px solid #ccc; padding: 15px; margin-bottom: 15px; background: #fafafa; }
                .issue.high { border-color: #ff4444; }
                .issue.medium { border-color: #ff9900; }
                .issue.low { border-color: #00aa00; }
                .issue-header { display: flex; justify-content: space-between; margin-bottom: 10px; }
                .severity { font-weight: bold; text-transform: uppercase; font-size: 12px; }
                .severity.high { color: #ff4444; }
                .severity.medium { color: #ff9900; }
                .severity.low { color: #00aa00; }
                .line { color: #666; font-size: 12px; }
                .description { margin: 10px 0; }
                .category { background: #e0e0e0; padding: 2px 8px; border-radius: 4px; font-size: 11px; }
                .fix { background: #e8f5e9; padding: 10px; border-radius: 4px; font-family: monospace; font-size: 12px; margin-top: 10px; }
            </style>
        </head>
        <body>
            <h1>\(title)</h1>
            <div class="date">Generated: \(dateFormatter.string(from: Date()))</div>

            <div class="summary">
                <strong>Summary:</strong> \(issues.count) issues found<br>
                <span class="severity high">High:</span> \(issues.count(where: { $0.severity == .high })) |
                <span class="severity medium">Medium:</span> \(issues.count(where: { $0.severity == .medium })) |
                <span class="severity low">Low:</span> \(issues.count(where: { $0.severity == .low }))
            </div>
        """

        // Group by category
        let grouped = Dictionary(grouping: issues) { $0.category }

        for (category, categoryIssues) in grouped.sorted(by: { $0.key.rawValue < $1.key.rawValue }) {
            html += "<h2>\(category.rawValue.capitalized) (\(categoryIssues.count))</h2>"

            for issue in categoryIssues {
                let severityClass = issue.severity.rawValue.lowercased()
                html += """
                <div class="issue \(severityClass)">
                    <div class="issue-header">
                        <span class="severity \(severityClass)">\(issue.severity.rawValue)</span>
                        <span class="line">Line \(issue.line ?? 0)</span>
                    </div>
                    <div class="description">\(escapeHTML(issue.description))</div>
                    <span class="category">\(issue.category.rawValue)</span>
                """

                if let fix = issue.suggestedFix {
                    html += """
                    <div class="fix">
                        <strong>Suggested Fix:</strong><br>
                        \(escapeHTML(fix))
                    </div>
                    """
                }

                html += "</div>"
            }
        }

        html += """
        </body>
        </html>
        """

        return html
    }

    private func escapeHTML(_ string: String) -> String {
        string
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
    }

    // MARK: - PDF Generation

    private func generatePDF(from html: String, filename: String) -> URL? {
        let tempDir = FileManager.default.temporaryDirectory
        let pdfURL = tempDir.appendingPathComponent("\(filename).pdf")

        #if os(iOS)
            guard let htmlData = html.data(using: .utf8) else { return nil }

            let printFormatter = UIMarkupTextPrintFormatter(markupText: html)
            let renderer = UIPrintPageRenderer()
            renderer.addPrintFormatter(printFormatter, startingAtPageAt: 0)

            let pageSize = CGSize(width: 612, height: 792) // US Letter
            let pageRect = CGRect(origin: .zero, size: pageSize)
            let printableRect = pageRect.insetBy(dx: 36, dy: 36)

            renderer.setValue(NSValue(cgRect: pageRect), forKey: "paperRect")
            renderer.setValue(NSValue(cgRect: printableRect), forKey: "printableRect")

            let pdfData = NSMutableData()
            UIGraphicsBeginPDFContextToData(pdfData, pageRect, nil)

            for i in 0 ..< renderer.numberOfPages {
                UIGraphicsBeginPDFPage()
                renderer.drawPage(at: i, in: UIGraphicsGetPDFContextBounds())
            }

            UIGraphicsEndPDFContext()

            do {
                try pdfData.write(to: pdfURL)
                return pdfURL
            } catch {
                print("[PDFExport] Failed to write PDF: \(error)")
                return nil
            }

        #elseif os(macOS)
            /// macOS implementation would use NSPrintOperation
            /// For now, save HTML as fallback
            let htmlURL = tempDir.appendingPathComponent("\(filename).html")
            try? html.write(to: htmlURL, atomically: true, encoding: .utf8)
            print("[PDFExport] HTML saved to: \(htmlURL)")
            return htmlURL
        #else
            return nil
        #endif
    }
}
