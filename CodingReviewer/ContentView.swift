//
//  ContentView.swift
//  CodingReviewer
//
//  Main content view for the CodingReviewer application
//

import os
import SwiftUI
import UniformTypeIdentifiers

enum ContentViewType {
    case analysis, documentation, tests
}

public struct ContentView: View {
    private let logger = Logger(subsystem: "com.quantum.codingreviewer", category: "ContentView")

    // Service layer
    private let codeReviewService = CodeReviewService()
    private let languageDetector = LanguageDetector()

    @State private var selectedFileURL: URL?
    @State private var codeContent: String = ""
    @State private var analysisResult: CodeAnalysisResult?
    @State private var documentationResult: DocumentationResult?
    @State private var testResult: TestGenerationResult?
    @State private var isAnalyzing = false
    @State private var showFilePicker = false
    @State private var selectedAnalysisType: AnalysisType = .comprehensive
    @State private var currentView: ContentViewType = .analysis
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showSavePanel = false
    @State private var reviewToSave: ReviewData?

    public var body: some View {
        NavigationSplitView {
            // Sidebar with file browser and analysis tools
            SidebarView(
                selectedFileURL: $selectedFileURL,
                showFilePicker: $showFilePicker,
                selectedAnalysisType: $selectedAnalysisType,
                currentView: $currentView
            )
        } detail: {
            // Main content area
            ZStack {
                if let fileURL = selectedFileURL {
                    CodeReviewView(
                        fileURL: fileURL,
                        codeContent: $codeContent,
                        analysisResult: $analysisResult,
                        documentationResult: $documentationResult,
                        testResult: $testResult,
                        isAnalyzing: $isAnalyzing,
                        selectedAnalysisType: selectedAnalysisType,
                        currentView: currentView,
                        onAnalyze: { await analyzeCode() },
                        onGenerateDocumentation: { await generateDocumentation() },
                        onGenerateTests: { await generateTests() }
                    )
                } else {
                    WelcomeView(showFilePicker: $showFilePicker)
                }
            }
        }
        .fileImporter(
            isPresented: $showFilePicker,
            allowedContentTypes: [.swiftSource, .objectiveCSource, .cSource, .cHeader],
            allowsMultipleSelection: false
        ) { result in
            handleFileSelection(result)
        }
        .onAppear {
            logger.info("ContentView appeared")
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("SaveReviewNotification"))) { _ in
            prepareForSave()
        }
        .fileExporter(
            isPresented: $showSavePanel,
            document: JSONFileDocument(reviewData: reviewToSave),
            contentType: .json,
            defaultFilename: "CodeReview_\(Date().formatted(date: .numeric, time: .omitted)).json"
        ) { result in
            handleSaveResult(result)
        }
    }

    private func handleFileSelection(_ result: Result<[URL], Error>) {
        switch result {
        case let .success(urls):
            if let url = urls.first {
                selectedFileURL = url
                loadFileContent(from: url)
            }
        case let .failure(error):
            logger.error("File selection failed: \(error.localizedDescription)")
            errorMessage = "Failed to select file: \(error.localizedDescription)"
            showError = true
        }
    }

    private func loadFileContent(from url: URL) {
        do {
            let content = try String(contentsOf: url, encoding: .utf8)
            codeContent = content
            logger.info("Loaded file content from: \(url.lastPathComponent)")
        } catch {
            logger.error("Failed to load file content: \(error.localizedDescription)")
            errorMessage = "Failed to load file: \(error.localizedDescription)"
            showError = true
        }
    }

    private func analyzeCode() async {
        guard !codeContent.isEmpty else { return }

        isAnalyzing = true
        defer { isAnalyzing = false }

        do {
            let language = languageDetector.detectLanguage(from: selectedFileURL)
            let result = try await codeReviewService.analyzeCode(
                codeContent,
                language: language,
                analysisType: selectedAnalysisType
            )
            analysisResult = result
            logger.info("Code analysis completed successfully")
        } catch {
            logger.error("Code analysis failed: \(error.localizedDescription)")
            errorMessage = "Analysis failed: \(error.localizedDescription)"
            showError = true
        }
    }

    private func generateDocumentation() async {
        guard !codeContent.isEmpty else { return }

        isAnalyzing = true
        defer { isAnalyzing = false }

        do {
            let language = languageDetector.detectLanguage(from: selectedFileURL)
            let result = try await codeReviewService.generateDocumentation(codeContent, language: language, includeExamples: true)
            documentationResult = result
            logger.info("Documentation generation completed successfully")
        } catch {
            logger.error("Documentation generation failed: \(error.localizedDescription)")
            errorMessage = "Documentation generation failed: \(error.localizedDescription)"
            showError = true
        }
    }

    private func generateTests() async {
        guard !codeContent.isEmpty else { return }

        isAnalyzing = true
        defer { isAnalyzing = false }

        do {
            let language = languageDetector.detectLanguage(from: selectedFileURL)
            let result = try await codeReviewService.generateTests(codeContent, language: language, testFramework: "XCTest")
            testResult = result
            logger.info("Test generation completed successfully")
        } catch {
            logger.error("Test generation failed: \(error.localizedDescription)")
            errorMessage = "Test generation failed: \(error.localizedDescription)"
            showError = true
        }
    }

    private func prepareForSave() {
        guard let analysis = analysisResult else {
            errorMessage = "No analysis to save. Please analyze a file first."
            showError = true
            return
        }

        reviewToSave = ReviewData(
            fileName: selectedFileURL?.lastPathComponent ?? "Unknown",
            code: codeContent,
            analysis: analysis,
            timestamp: Date()
        )
        showSavePanel = true
    }

    private func handleSaveResult(_ result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            logger.info("Review saved successfully to: \(url.path)")
        case .failure(let error):
            logger.error("Failed to save review: \(error.localizedDescription)")
            errorMessage = "Failed to save review: \(error.localizedDescription)"
            showError = true
        }
    }
}

struct ReviewData: Codable {
    let fileName: String
    let code: String
    let analysis: CodeAnalysisResult
    let timestamp: Date
}

struct JSONFileDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }

    var reviewData: ReviewData?

    init(reviewData: ReviewData?) {
        self.reviewData = reviewData
    }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        self.reviewData = try JSONDecoder().decode(ReviewData.self, from: data)
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = try JSONEncoder().encode(reviewData)
        return FileWrapper(regularFileWithContents: data)
    }
}

// MARK: - Preview

public struct ContentView_Previews: PreviewProvider {
    public static var previews: some View {
        ContentView()
    }
}
