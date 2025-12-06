//
// CodeSimilarityDetector.swift
// CodingReviewer
//
// Service for detecting code duplication and similarity
//

import Foundation

struct CodeSimilarityDetector {

    struct SimilarityResult {
        let score: Double // 0.0 to 1.0
        let isDuplicate: Bool
    }

    /// Calculate similarity between two code snippets using token-based Jaccard similarity
    func calculateSimilarity(codeA: String, codeB: String) -> SimilarityResult {
        let tokensA = tokenize(codeA)
        let tokensB = tokenize(codeB)

        if tokensA.isEmpty || tokensB.isEmpty {
            return SimilarityResult(score: 0.0, isDuplicate: false)
        }

        let setA = Set(tokensA)
        let setB = Set(tokensB)

        let intersection = setA.intersection(setB)
        let union = setA.union(setB)

        let jaccardIndex = Double(intersection.count) / Double(union.count)

        return SimilarityResult(score: jaccardIndex, isDuplicate: jaccardIndex > 0.85)
    }

    private func tokenize(_ code: String) -> [String] {
        // Simple tokenizer: split by non-alphanumeric characters
        // In a real implementation, we'd use the LanguageAnalyzer's lexer
        let components = code.components(separatedBy: CharacterSet.alphanumerics.inverted)
        return components.filter { !$0.isEmpty }
    }
}
