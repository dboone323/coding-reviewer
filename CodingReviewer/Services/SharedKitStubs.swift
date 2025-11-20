import Foundation

public protocol LLMClient {
    func generate(model: String, prompt: String, temperature: Double) async throws -> String
}

public struct SentimentScore {
    public let label: String
    public let score: Double
}

public final class KeywordSentimentScoringService {
    private let positiveKeywords = ["love", "excellent", "amazing", "wonderful", "great", "good", "awesome", "fantastic", "brilliant", "perfect"]
    private let negativeKeywords = ["terrible", "broken", "awful", "crash", "bad", "horrible", "worst", "hate", "disgusting", "pathetic"]

    public init() {}

    public func scoreSync(text: String) -> SentimentScore {
        let lowerText = text.lowercased()
        var positiveCount = 0
        var negativeCount = 0

        for keyword in positiveKeywords where lowerText.contains(keyword) {
            positiveCount += 1
        }

        for keyword in negativeKeywords where lowerText.contains(keyword) {
            negativeCount += 1
        }

        let totalKeywords = positiveCount + negativeCount
        if totalKeywords == 0 {
            return SentimentScore(label: "neutral", score: 0.0)
        }

        let score = Double(positiveCount - negativeCount) / Double(totalKeywords)

        if score > 0 {
            return SentimentScore(label: "positive", score: score)
        } else if score < 0 {
            return SentimentScore(label: "negative", score: score)
        } else {
            return SentimentScore(label: "neutral", score: 0.0)
        }
    }
}

public final class OllamaSentimentScoringService {
    private let llm: LLMClient
    private let model: String

    public init(llm: LLMClient, model: String) {
        self.llm = llm
        self.model = model
    }

    public func score(text: String) async -> SentimentScore {
        do {
            let jsonString = try await llm.generate(model: model, prompt: text, temperature: 0.0)
            if let data = jsonString.data(using: .utf8) {
                if let obj = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let label = obj["label"] as? String,
                   let score = obj["score"] as? Double {
                    return SentimentScore(label: label, score: score)
                }
            }
        } catch {
            // fallthrough to neutral
        }

        return SentimentScore(label: "neutral", score: 0.0)
    }
}
