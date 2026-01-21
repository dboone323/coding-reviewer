//
// PatternMatcher.swift
// CodingReviewer
//
// Helper for regex-based code analysis
//

import Foundation

enum PatternMatcher {
    struct Match {
        let line: Int
        let content: String
        let range: Range<String.Index>
    }

    static func findMatches(pattern: String, in code: String) -> [Match] {
        var matches: [Match] = []

        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return matches
        }

        let lines = code.components(separatedBy: .newlines)

        for (index, line) in lines.enumerated() {
            let range = NSRange(location: 0, length: line.utf16.count)
            if regex.firstMatch(in: line, options: [], range: range) != nil {
                // Find the range in the string
                if let range = line.range(of: pattern, options: .regularExpression) {
                    matches.append(Match(line: index + 1, content: line.trimmingCharacters(in: .whitespaces), range: range))
                } else {
                    // Fallback if range extraction fails but match existed
                    matches.append(Match(line: index + 1, content: line.trimmingCharacters(in: .whitespaces), range: line.startIndex ..< line.endIndex))
                }
            }
        }

        return matches
    }
}
