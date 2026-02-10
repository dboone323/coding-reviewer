//
// PatternMatcher.swift
// CodingReviewer
//
// Defines a robust pattern matcher utility for code analysis
//

import Foundation

/// Match result from pattern matching
public struct PatternMatch {
    public let range: Range<String.Index>
    public let line: Int?
    public let matchedText: String

    public init(range: Range<String.Index>, line: Int?, matchedText: String) {
        self.range = range
        self.line = line
        self.matchedText = matchedText
    }
}

/// Pattern matcher utility for finding code patterns
public class PatternMatcher {
    public static let defaultTimeout: TimeInterval = 5.0

    /// Find all matches of a pattern in code
    /// - Parameters:
    ///   - pattern: Regular expression pattern to match
    ///   - code: Source code to search
    ///   - timeout: Maximum time to spend matching (default 5s)
    /// - Returns: Array of pattern matches with line numbers
    public static func findMatches(
        pattern: String,
        in code: String,
        timeout: TimeInterval = defaultTimeout
    ) -> [PatternMatch] {
        var matches: [PatternMatch] = []

        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return matches // Invalid regex pattern
        }

        let nsString = code as NSString
        let nsRange = NSRange(location: 0, length: nsString.length)

        // Perform matching with timeout protection
        let semaphore = DispatchSemaphore(value: 0)

        DispatchQueue.global(qos: .userInitiated).async {
            regex.enumerateMatches(in: code, options: [], range: nsRange) { match, _, _ in
                guard let match else { return }

                if let matchRange = Range(match.range, in: code) {
                    let matchedText = String(code[matchRange])
                    let lineNumber = calculateLineNumber(in: code, at: matchRange.lowerBound)

                    matches.append(
                        PatternMatch(
                            range: matchRange,
                            line: lineNumber,
                            matchedText: matchedText
                        ))
                }
            }
            semaphore.signal()
        }

        // Wait for completion or timeout
        let result = semaphore.wait(timeout: .now() + timeout)
        if result == .timedOut {
            return [] // Pattern matching timed out
        }

        return matches
    }

    /// Calculate line number for a string index
    private static func calculateLineNumber(in code: String, at index: String.Index) -> Int? {
        let prefix = code[..<index]
        return prefix.components(separatedBy: .newlines).count
    }

    /// Validate a regex pattern
    public static func isValidPattern(_ pattern: String) -> Bool {
        do {
            _ = try NSRegularExpression(pattern: pattern, options: [])
            return true
        } catch {
            return false
        }
    }
}
