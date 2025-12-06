//
//  CodeReviewView.swift
//  CodingReviewer
//
//  Main code review interface with editor and results panel
//

import SwiftUI

public struct CodeReviewView: View {
    let fileURL: URL
    @Binding var codeContent: String
    @Binding var analysisResult: CodeAnalysisResult?
    @Binding var documentationResult: DocumentationResult?
    @Binding var testResult: TestGenerationResult?
    @Binding var isAnalyzing: Bool
    @State private var isLiveAnalysisEnabled = false
    let selectedAnalysisType: AnalysisType
    let currentView: ContentViewType
    let onAnalyze: () async -> Void
    let onGenerateDocumentation: () async -> Void
    let onGenerateTests: () async -> Void

    public var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(fileURL.lastPathComponent)
                    .font(.headline)
                    .accessibilityLabel("File: \(fileURL.lastPathComponent)")
                Spacer()

                switch currentView {
                case .analysis:
                    HStack {
                        Toggle("Live", isOn: $isLiveAnalysisEnabled)
                            .toggleStyle(.switch)
                            .controlSize(.small)

                        Button(action: { Task { await onAnalyze() } }, label: {
                            Label("Analyze", systemImage: "play.fill")
                        })
                        .accessibilityLabel("Analyze Code")
                        .accessibilityHint("Run code analysis on this file")
                        .disabled(isAnalyzing || codeContent.isEmpty)
                    }
                case .documentation:
                    Button(action: { Task { await onGenerateDocumentation() } }, label: {
                        Label("Generate Docs", systemImage: "doc.text")
                    })
                    .accessibilityLabel("Generate Documentation")
                    .accessibilityHint("Generate documentation for this code")
                    .disabled(isAnalyzing || codeContent.isEmpty)
                case .tests:
                    Button(action: { Task { await onGenerateTests() } }, label: {
                        Label("Generate Tests", systemImage: "testtube.2")
                    })
                    .accessibilityLabel("Generate Tests")
                    .accessibilityHint("Generate unit tests for this code")
                    .disabled(isAnalyzing || codeContent.isEmpty)
                }
            }
            .padding()

            Divider()

            // Main content
            HSplitView {
                // Code editor
                ScrollView {
                    TextEditor(text: $codeContent)
                        .font(.system(.body, design: .monospaced))
                        .padding()
                }
                .frame(minWidth: 400)
                .task(id: codeContent) {
                    guard isLiveAnalysisEnabled, !codeContent.isEmpty else { return }
                    try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s debounce
                    if !Task.isCancelled {
                        await onAnalyze()
                    }
                }

                // Results panel
                ResultsPanel(
                    currentView: currentView,
                    analysisResult: analysisResult,
                    documentationResult: documentationResult,
                    testResult: testResult,
                    isAnalyzing: isAnalyzing,
                    onApplyFix: { issue in applyFix(issue) }
                )
                .frame(minWidth: 300)
            }
        }
    }

    private func applyFix(_ issue: CodeIssue) {
        guard let fix = issue.suggestedFix, let line = issue.line else { return }

        var lines = codeContent.components(separatedBy: .newlines)
        if line > 0 && line <= lines.count {
            lines[line - 1] = fix
            codeContent = lines.joined(separator: "\n")
        }
    }
}

public struct ResultsPanel: View {
    let currentView: ContentViewType
    let analysisResult: CodeAnalysisResult?
    let documentationResult: DocumentationResult?
    let testResult: TestGenerationResult?
    let isAnalyzing: Bool
    var onApplyFix: ((CodeIssue) -> Void)?

    private var presenter: ResultsPanelPresenter {
        ResultsPanelPresenter(currentView: currentView, isAnalyzing: isAnalyzing)
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Results header
            HStack {
                Text(presenter.title)
                    .font(.headline)
                Spacer()
                if isAnalyzing {
                    ProgressView()
                        .scaleEffect(0.7)
                }
            }
            .padding()

            Divider()

            // Results content
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    switch currentView {
                    case .analysis:
                        if let result = analysisResult {
                            AnalysisResultsView(result: result, onApplyFix: onApplyFix)
                        } else if let message = presenter.emptyStateMessage(hasResult: analysisResult != nil) {
                            Text(message)
                                .foregroundColor(.secondary)
                                .padding()
                        }
                    case .documentation:
                        if let result = documentationResult {
                            DocumentationResultsView(result: result)
                        } else if let message = presenter.emptyStateMessage(hasResult: documentationResult != nil) {
                            Text(message)
                                .foregroundColor(.secondary)
                                .padding()
                        }
                    case .tests:
                        if let result = testResult {
                            TestResultsView(result: result)
                        } else if let message = presenter.emptyStateMessage(hasResult: testResult != nil) {
                            Text(message)
                                .foregroundColor(.secondary)
                                .padding()
                        }
                    }
                }
                .padding()
            }
        }
    }
}

struct ResultsPanelPresenter {
    let currentView: ContentViewType
    let isAnalyzing: Bool

    var title: String {
        switch currentView {
        case .analysis: "Analysis Results"
        case .documentation: "Documentation"
        case .tests: "Generated Tests"
        }
    }

    func emptyStateMessage(hasResult: Bool) -> String? {
        guard !hasResult, !isAnalyzing else { return nil }

        switch currentView {
        case .analysis:
            return "Click Analyze to start code analysis"
        case .documentation:
            return "Click Generate Docs to create documentation"
        case .tests:
            return "Click Generate Tests to create unit tests"
        }
    }
}
