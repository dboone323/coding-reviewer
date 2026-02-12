//
// RuleEngine.swift
// CodingReviewer
//
// Engine for applying custom rules
//

import Foundation
import os

class RuleEngine {
    private var rules: [CustomRule] = []
    private let logger = Logger(subsystem: "com.quantum.codingreviewer", category: "RuleEngine")

    func loadRules(from url: URL) throws {
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            self.rules = try decoder.decode([CustomRule].self, from: data)
            logger.info("Loaded \(self.rules.count) custom rules from \(url.path)")

            // Validate patterns
            let invalidRules = rules.filter { !PatternMatcher.isValidPattern($0.pattern) }
            if !invalidRules.isEmpty {
                logger.warning("Found \(invalidRules.count) rules with invalid patterns")
            }
        } catch {
            logger.error("Failed to load rules from \(url.path): \(error.localizedDescription)")
            throw error
        }
    }

    func addRule(_ rule: CustomRule) {
        guard PatternMatcher.isValidPattern(rule.pattern) else {
            logger.warning("Skipping rule '\(rule.id)' with invalid pattern: \(rule.pattern)")
            return
        }
        rules.append(rule)
        logger.info("Added custom rule: \(rule.id)")
    }

    func analyze(code: String, language: String) -> [CodeIssue] {
        var issues: [CodeIssue] = []

        let applicableRules = rules.filter {
            $0.language.lowercased() == language.lowercased() || $0.language == "*"
        }

        logger.info(
            "Analyzing with \(applicableRules.count) applicable rules for language: \(language)"
        )

        for rule in applicableRules {
            let matches = PatternMatcher.findMatches(pattern: rule.pattern, in: code, timeout: 10.0)
            for match in matches {
                issues.append(
                    CodeIssue(
                        description: rule.description,
                        severity: rule.severity,
                        line: match.line,
                        category: rule.category
                    )
                )
            }
        }

        logger.info("Found \(issues.count) issues from custom rules")
        return issues
    }

    func getRuleCount() -> Int {
        rules.count
    }

    func getEnabledRuleCount() -> Int {
        rules.count // All loaded rules are considered enabled
    }
}
