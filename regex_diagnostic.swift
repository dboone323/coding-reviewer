import Foundation
import RegexBuilder // If available

struct Match {
    let line: Int
    let content: String
    let range: Range<String.Index>
}

func findMatches(pattern: String, in code: String, options: NSRegularExpression.Options = [])
    -> [Match]
{
    var matches: [Match] = []
    let lines = code.components(separatedBy: .newlines)

    guard let regex = try? NSRegularExpression(pattern: pattern, options: options) else {
        print("Regex failed to initialize for pattern: \(pattern)")
        return []
    }

    for (index, line) in lines.enumerated() {
        let range = NSRange(location: 0, length: line.utf16.count)
        let matchesInLine = regex.matches(in: line, options: [], range: range)

        for match in matchesInLine {
            if let swiftRange = Range(match.range, in: line) {
                matches.append(
                    Match(
                        line: index + 1, content: line.trimmingCharacters(in: .whitespaces),
                        range: swiftRange
                    )
                )
            }
        }
    }
    return matches
}

// Test Case 1: JavaScript Case Sensitivity
print("--- Case Sensitivity Test ---")
let jsCode = "EVAL('code'); INNERHTML = 'x';"
let evalMatches = findMatches(pattern: "eval\\(", in: jsCode, options: [.caseInsensitive])
let innerHTMLMatches = findMatches(
    pattern: "\\.innerHTML\\s*=", in: jsCode, options: [.caseInsensitive]
)
print("EVAL matches count: \(evalMatches.count)")
print("innerHTML matches count: \(innerHTMLMatches.count)")

// Test Case 2: Swift UserDefaults + Password
print("\n--- Swift UserDefaults Test ---")
let swiftCode = "defaults.set(password, forKey: 'key')"
let swiftPattern = "(UserDefaults|defaults).*(password|credential|secret|token)"
let swiftMatches = findMatches(pattern: swiftPattern, in: swiftCode, options: [.caseInsensitive])
print("Swift matches count: \(swiftMatches.count)")
if let first = swiftMatches.first {
    print("Match content: \(first.content)")
}

// Test Case 3: AI Quality Score
print("\n--- AI Quality Score Test ---")
let aiResponse = "Quality: 8/10"
do {
    let regex = try Regex("(\\d+)\\s*/\\s*10|\\b(\\d+)\\s*out\\s*of\\s*10")
    if let match = try regex.firstMatch(in: aiResponse) {
        print("Match count: \(match.count)")
        if match.count > 1, let v1 = match[1].value as? Substring {
            print("Group 1: \(v1)")
        }
        if match.count > 2, let v2 = match[2].value as? Substring {
            print("Group 2: \(v2)")
        }
    } else {
        print("AI Regex no match")
    }
} catch {
    print("AI Regex error: \(error)")
}
