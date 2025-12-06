//
// RuleEngine.swift
// CodingReviewer
//
// Engine for applying custom rules
//

import Foundation

class RuleEngine {
    private var rules: [CustomRule] = []

    func loadRules(from url: URL) throws {
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        self.rules = try decoder.decode([CustomRule].self, from: data)
    }

    func addRule(_ rule: CustomRule) {
        rules.append(rule)
    }

    func analyze(code: String, language: String) -> [CodeIssue] {
        var issues: [CodeIssue] = []

        let applicableRules = rules.filter { $0.language.lowercased() == language.lowercased() || $0.language == "*" }

        for rule in applicableRules {
            let matches = PatternMatcher.findMatches(pattern: rule.pattern, in: code)
            for match in matches {
                issues.append(CodeIssue(
                    description: rule.description,
                    severity: rule.severity,
                    line: match.line,
                    category: rule.category
                ))
            }
        }

        return issues
    }
}
