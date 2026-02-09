//
// AIModelManager.swift
// CodingReviewer
//
// Manages AI models, versioning, and selection
//

import Foundation

@MainActor
public class AIModelManager: ObservableObject {
    public static let shared = AIModelManager()

    public struct ModelInfo: Identifiable, Codable {
        public let id: String
        public let name: String
        public let version: String
        public let capabilities: [String] // "chat", "code", "embedding"
        public let isLocal: Bool
    }

    @Published public var availableModels: [ModelInfo] = [
        ModelInfo(
            id: "deepseek-v3.1:671b-cloud", name: "DeepSeek V3", version: "3.1",
            capabilities: ["chat", "code"], isLocal: false
        ),
        ModelInfo(
            id: "qwen3-coder:480b-cloud", name: "Qwen 3 Coder", version: "3.0",
            capabilities: ["code"], isLocal: false
        ),
        ModelInfo(
            id: "gpt-oss:120b-cloud", name: "GPT OSS", version: "1.0", capabilities: ["chat"],
            isLocal: false
        ),
        ModelInfo(
            id: "llama3.1:8b", name: "Llama 3.1 Local", version: "3.1",
            capabilities: ["chat", "code"], isLocal: true
        ),
    ]

    @Published public var selectedModelId: String = "deepseek-v3.1:671b-cloud"

    public func getModel(id: String) -> ModelInfo? {
        availableModels.first { $0.id == id }
    }

    public func selectModel(id: String) {
        if availableModels.contains(where: { $0.id == id }) {
            selectedModelId = id
        }
    }

    public func getBestModel(for capability: String) -> ModelInfo {
        // Simple logic: prefer selected if capable, otherwise first capable
        if let selected = getModel(id: selectedModelId), selected.capabilities.contains(capability) {
            return selected
        }
        return availableModels.first { $0.capabilities.contains(capability) } ?? availableModels[0]
    }
}
