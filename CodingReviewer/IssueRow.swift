//
//  IssueRow.swift
//  CodingReviewer
//
//  View for displaying individual code issues
//

import SwiftUI

public struct IssueRow: View {
    let issue: CodeIssue
    var onFix: (() -> Void)?
    private var presenter: IssueRowPresenter {
        IssueRowPresenter(issue: issue)
    }

    public var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: presenter.iconName)
                .foregroundColor(presenter.iconColor)

            VStack(alignment: .leading, spacing: 4) {
                Text(issue.description)
                    .font(.body)

                HStack {
                    if let line = issue.line {
                        Text("Line \(line)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Text("•")
                        .foregroundColor(.secondary)
                    Text(issue.category.rawValue.capitalized)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text("•")
                        .foregroundColor(.secondary)
                    Text(issue.severity.rawValue.capitalized)
                        .font(.caption)
                        .foregroundColor(presenter.severityColor)

                    if issue.suggestedFix != nil {
                        Spacer()
                        Button(
                            action: { onFix?() },
                            label: {
                                Label("Fix", systemImage: "wand.and.stars")
                                    .font(.caption)
                            }
                        )
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                    }
                }
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, issue.severity == .critical ? 8 : 0)
        .background(
            issue.severity == .critical
                ? Color.red.opacity(0.1)
                : Color.clear
        )
        .cornerRadius(6)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(
                    issue.severity == .critical
                        ? Color.red.opacity(0.3)
                        : Color.clear, lineWidth: 1
                )
        )
    }
}

struct IssueRowPresenter {
    struct Diagnostics {
        let iconName: String
        let iconColorIdentifier: String
        let severityColorIdentifier: String
    }

    let issue: CodeIssue

    private struct Palette {
        let iconName: String
        let iconColor: Color
        let severityColor: Color
        let colorIdentifier: String
    }

    private static let palette: [IssueSeverity: Palette] = [
        .low: Palette(
            iconName: "info.circle.fill", iconColor: .blue, severityColor: .blue,
            colorIdentifier: "blue"
        ),
        .medium: Palette(
            iconName: "exclamationmark.triangle.fill",
            iconColor: .orange,
            severityColor: .orange,
            colorIdentifier: "orange"
        ),
        .high: Palette(
            iconName: "exclamationmark.triangle.fill",
            iconColor: .red,
            severityColor: .red,
            colorIdentifier: "red"
        ),
        .critical: Palette(
            iconName: "xmark.circle.fill", iconColor: .red, severityColor: .red,
            colorIdentifier: "red"
        ),
    ]

    private var paletteForIssue: Palette {
        Self.palette[issue.severity] ?? Self.palette[.low]!
    }

    var iconName: String {
        paletteForIssue.iconName
    }

    var iconColor: Color {
        paletteForIssue.iconColor
    }

    var severityColor: Color {
        paletteForIssue.severityColor
    }

    var diagnostics: Diagnostics {
        Diagnostics(
            iconName: paletteForIssue.iconName,
            iconColorIdentifier: paletteForIssue.colorIdentifier,
            severityColorIdentifier: paletteForIssue.colorIdentifier
        )
    }
}
