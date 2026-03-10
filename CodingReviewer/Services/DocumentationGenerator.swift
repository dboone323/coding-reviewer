//
//  DocumentationGenerator.swift
//  CodingReviewer
//
//  Service for generating documentation from code
//

import Foundation

/// Service responsible for generating documentation from code
struct DocumentationGenerator {
    /// Generate basic documentation for the provided code
    /// - Parameters:
    ///   - code: The source code to document
    ///   - language: The programming language of the code
    ///   - includeExamples: Whether to include usage examples
    /// - Returns: Generated documentation as a string
    func generateBasicDocumentation(code: String, language: String, includeExamples: Bool) -> String {
        var documentationParts = ["# Code Documentation\n\n"]

        documentationParts.append("Generated documentation for \(language) code.\n\n")

        // Extract function signatures
        if language == "Swift" {
            let functions = extractSwiftFunctions(from: code)
            if !functions.isEmpty {
                documentationParts.append("## Functions\n\n")
                for function in functions {
                    documentationParts.append("- `\(function)`\n")
                }
                documentationParts.append("\n")
            }
        }

        if includeExamples {
            documentationParts.append("## Usage Examples\n\n")
            documentationParts.append("```\(language.lowercased())\n// Example usage\n```\n\n")
        }

        let documentation = documentationParts.joined()
        // Remove trailing whitespace but keep one newline at the end
        return documentation.trimmingCharacters(in: .whitespacesAndNewlines) + "\n"
    }

    private func extractSwiftFunctions(from code: String) -> [String] {
        let lines = code.components(separatedBy: .newlines)
        var functions: [String] = []
        var currentFunction: [String] = []
        var braceCount = 0
        var inFunction = false

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if isFunctionStart(trimmed), !inFunction {
                startFunction(trimmed, &braceCount, &currentFunction, &inFunction)
                if braceCount == 0, trimmed.contains("{") {
                    functions.append(trimmed)
                    resetFunctionState(&currentFunction, &inFunction)
                }
            } else if inFunction {
                currentFunction.append(trimmed)
                braceCount += countBraces(in: trimmed)

                if braceCount <= 0, trimmed.contains("}") {
                    functions.append(currentFunction.joined(separator: "\n"))
                    resetFunctionState(&currentFunction, &inFunction)
                }
            }
        }

        return functions
    }

    private func isFunctionStart(_ trimmed: String) -> Bool {
        let prefixes = ["func ", "private func ", "public func ", "internal func ", "static func "]
        return prefixes.contains { trimmed.hasPrefix($0) }
    }

    private func startFunction(
        _ trimmed: String,
        _ braceCount: inout Int,
        _ currentFunction: inout [String],
        _ inFunction: inout Bool
    ) {
        inFunction = true
        currentFunction = [trimmed]
        braceCount = countBraces(in: trimmed)
    }

    private func countBraces(in line: String) -> Int {
        var count = 0
        for char in line {
            if char == "{" { count += 1 }
            if char == "}" { count -= 1 }
        }
        return count
    }

    private func resetFunctionState(_ currentFunction: inout [String], _ inFunction: inout Bool) {
        currentFunction = []
        inFunction = false
    }
}
