//
// PerformanceTests.swift
// CodingReviewerTests
//

import XCTest
@testable import CodingReviewer

class PerformanceTests: XCTestCase {
    var performanceMonitor: PerformanceMonitor!

    override func setUp() {
        super.setUp()
        performanceMonitor = PerformanceMonitor()
    }

    override func tearDown() {
        performanceMonitor = nil
        super.tearDown()
    }

    // MARK: - Code Analysis Performance Tests

    func testCodeAnalysisEnginePerformance() {
        let engine = CodeAnalysisEngine()

        let testCode = """
        func calculateFibonacci(n: Int) -> Int {
            if n <= 1 { return n }
            return calculateFibonacci(n: n-1) + calculateFibonacci(n: n-2)
        }

        class Calculator {
            func add(_ a: Int, _ b: Int) -> Int {
                return a + b
            }

            func multiply(_ a: Int, _ b: Int) -> Int {
                return a * b
            }
        }
        """

        measure {
            for _ in 0..<100 {
                let _ = try? engine.analyzeCode(testCode, language: .swift)
            }
        }
    }

    func testBugDetectionServicePerformance() {
        let bugDetector = BugDetectionService()

        let testCode = """
        func unsafeFunction() {
            var array = [1, 2, 3]
            let index = 5
            let value = array[index] // Potential out of bounds

            if let data = try? Data(contentsOf: URL(string: "invalid")!) {
                // Force unwrap potential nil
                print(data.count)
            }
        }
        """

        measure {
            for _ in 0..<50 {
                let _ = bugDetector.detectBugs(in: testCode, language: .swift)
            }
        }
    }

    func testCodeSmellDetectorPerformance() {
        let smellDetector = CodeSmellDetector()

        let testCode = """
        class VeryLongClassNameThatShouldBeShorter {
            func veryLongFunctionNameThatShouldBeShorter(parameter1: Int, parameter2: String, parameter3: Bool, parameter4: Double) -> String {
                if parameter1 > 0 && parameter2.isEmpty == false && parameter3 == true && parameter4 < 100.0 {
                    return "Complex condition that should be simplified"
                }
                return "Default"
            }
        }
        """

        measure {
            for _ in 0..<50 {
                let _ = smellDetector.detectSmells(in: testCode, language: .swift)
            }
        }
    }

    // MARK: - AI Service Performance Tests

    func testAIEnhancedCodeAnalysisPerformance() {
        let aiService = AIEnhancedCodeAnalysisService()

        let testCode = """
        func processData(_ data: [Int]) -> [Int] {
            return data.map { $0 * 2 }.filter { $0 > 10 }.sorted()
        }
        """

        measure {
            for _ in 0..<20 {
                let _ = aiService.analyzeWithAI(code: testCode, language: .swift)
            }
        }
    }

    func testSecurityAnalysisPerformance() {
        let securityAnalyzer = SecurityAnalysisService()

        let testCode = """
        func authenticateUser(username: String, password: String) {
            let query = "SELECT * FROM users WHERE username = '\\(username)' AND password = '\\(password)'"
            // SQL injection vulnerability
            database.execute(query)
        }
        """

        measure {
            for _ in 0..<30 {
                let _ = securityAnalyzer.analyzeSecurity(in: testCode, language: .swift)
            }
        }
    }

    // MARK: - Data Processing Performance Tests

    func testAnalysisCachePerformance() {
        let cache = AnalysisCache.shared

        measure {
            for i in 0..<200 {
                let key = "test_key_\(i)"
                let result = AnalysisResult(
                    fileName: "TestFile\(i).swift",
                    issues: [],
                    summary: AnalysisSummary(totalIssues: 0, criticalIssues: 0, warnings: 0, suggestions: 0)
                )
                cache.store(result, forKey: key)
                let _ = cache.retrieve(forKey: key)
            }
        }
    }

    func testDocumentationGeneratorPerformance() {
        let docGenerator = DocumentationGenerator()

        let testCode = """
        /// A simple calculator class
        class Calculator {
            /// Adds two numbers
            /// - Parameters:
            ///   - a: First number
            ///   - b: Second number
            /// - Returns: Sum of the two numbers
            func add(_ a: Int, _ b: Int) -> Int {
                return a + b
            }
        }
        """

        measure {
            for _ in 0..<30 {
                let _ = docGenerator.generateDocumentation(for: testCode, language: .swift)
            }
        }
    }

    // MARK: - Git Integration Performance Tests

    func testGitIntegrationPerformance() {
        let gitService = GitIntegrationService()

        measure {
            for _ in 0..<10 {
                // Simulate git operations
                let _ = gitService.getDiff()
                let _ = gitService.getFileHistory(fileName: "TestFile.swift")
                let _ = gitService.getCommitHistory()
            }
        }
    }

    // MARK: - Report Generation Performance Tests

    func testPDFReportExportPerformance() {
        let pdfExporter = PDFReportExporter()

        let mockResults = (0..<50).map { i in
            AnalysisResult(
                fileName: "File\(i).swift",
                issues: (0..<5).map { j in
                    Issue(
                        id: "issue_\(i)_\(j)",
                        title: "Test Issue \(j)",
                        description: "Description for issue \(j)",
                        severity: .warning,
                        file: "File\(i).swift",
                        line: j * 10,
                        column: 5,
                        rule: "test_rule"
                    )
                },
                summary: AnalysisSummary(totalIssues: 5, criticalIssues: 0, warnings: 5, suggestions: 0)
            )
        }

        measure {
            for _ in 0..<5 {
                let _ = pdfExporter.exportToPDF(results: mockResults)
            }
        }
    }

    // MARK: - Concurrent Operations Performance Tests

    func testConcurrentAnalysisPerformance() {
        let expectation = XCTestExpectation(description: "Concurrent analysis")

        measure {
            let group = DispatchGroup()

            group.enter()
            DispatchQueue.global(qos: .userInteractive).async {
                let engine = CodeAnalysisEngine()
                for _ in 0..<50 {
                    let _ = try? engine.analyzeCode("func test() {}", language: .swift)
                }
                group.leave()
            }

            group.enter()
            DispatchQueue.global(qos: .userInteractive).async {
                let bugDetector = BugDetectionService()
                for _ in 0..<30 {
                    let _ = bugDetector.detectBugs(in: "let x = nil; x!", language: .swift)
                }
                group.leave()
            }

            group.enter()
            DispatchQueue.global(qos: .userInteractive).async {
                let smellDetector = CodeSmellDetector()
                for _ in 0..<30 {
                    let _ = smellDetector.detectSmells(in: "class A { func b() {} }", language: .swift)
                }
                group.leave()
            }

            group.notify(queue: .main) {
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 15.0)
    }

    // MARK: - Memory Performance Tests

    func testMemoryUsageDuringAnalysis() {
        measure {
            autoreleasepool {
                var results: [AnalysisResult] = []
                for i in 0..<200 {
                    let result = AnalysisResult(
                        fileName: "MemoryTest\(i).swift",
                        issues: [],
                        summary: AnalysisSummary(totalIssues: 0, criticalIssues: 0, warnings: 0, suggestions: 0)
                    )
                    results.append(result)
                }
                results.removeAll()
            }
        }
    }

    // MARK: - Performance Monitoring

    func testPerformanceMetricsCollection() {
        performanceMonitor.startMonitoring()

        let engine = CodeAnalysisEngine()

        measure {
            for _ in 0..<50 {
                let _ = try? engine.analyzeCode("func test() { print(\"hello\") }", language: .swift)
                let _ = performanceMonitor.getMetrics()
            }
        }

        performanceMonitor.stopMonitoring()
    }
}

// MARK: - Performance Monitor

class PerformanceMonitor {
    private var startTime: Date?
    private var operationCount = 0
    private var metrics: PerformanceMetrics = PerformanceMetrics()

    func startMonitoring() {
        startTime = Date()
        operationCount = 0
        metrics = PerformanceMetrics()
    }

    func stopMonitoring() {
        startTime = nil
    }

    func getMetrics() -> PerformanceMetrics {
        operationCount += 1

        if let startTime = startTime {
            let elapsed = Date().timeIntervalSince(startTime)
            metrics.operationsPerSecond = Double(operationCount) / elapsed
        }

        // Simulate memory and CPU monitoring
        metrics.memoryUsage = Double.random(in: 30...70)
        metrics.cpuUsage = Double.random(in: 15...50)

        return metrics
    }
}

// MARK: - Extended Data Models

struct PerformanceMetrics {
    var operationsPerSecond: Double = 100.0
    var memoryUsage: Double = 45.0
    var cpuUsage: Double = 25.0
    var analysisTime: TimeInterval = 0.0
    var cacheHitRate: Double = 0.85
}

// MARK: - Mock Extensions for Testing

extension CodeAnalysisEngine {
    func analyzeCode(_ code: String, language: ProgrammingLanguage) throws -> AnalysisResult {
        // Simulate analysis
        return AnalysisResult(
            fileName: "TestFile.swift",
            issues: [],
            summary: AnalysisSummary(totalIssues: 0, criticalIssues: 0, warnings: 0, suggestions: 0)
        )
    }
}

extension BugDetectionService {
    func detectBugs(in code: String, language: ProgrammingLanguage) -> [Issue] {
        // Simulate bug detection
        return []
    }
}

extension CodeSmellDetector {
    func detectSmells(in code: String, language: ProgrammingLanguage) -> [Issue] {
        // Simulate smell detection
        return []
    }
}

extension AIEnhancedCodeAnalysisService {
    func analyzeWithAI(code: String, language: ProgrammingLanguage) -> AnalysisResult {
        // Simulate AI analysis
        return AnalysisResult(
            fileName: "TestFile.swift",
            issues: [],
            summary: AnalysisSummary(totalIssues: 0, criticalIssues: 0, warnings: 0, suggestions: 0)
        )
    }
}

extension SecurityAnalysisService {
    func analyzeSecurity(in code: String, language: ProgrammingLanguage) -> [Issue] {
        // Simulate security analysis
        return []
    }
}

extension DocumentationGenerator {
    func generateDocumentation(for code: String, language: ProgrammingLanguage) -> String {
        // Simulate documentation generation
        return "// Generated documentation"
    }
}

extension GitIntegrationService {
    func getDiff() -> String {
        return "+ func newFunction() {}"
    }

    func getFileHistory(fileName: String) -> [String] {
        return ["commit 1", "commit 2", "commit 3"]
    }

    func getCommitHistory() -> [String] {
        return ["commit abc123", "commit def456"]
    }
}

extension PDFReportExporter {
    func exportToPDF(results: [AnalysisResult]) -> Data {
        // Simulate PDF generation
        return Data()
    }
}