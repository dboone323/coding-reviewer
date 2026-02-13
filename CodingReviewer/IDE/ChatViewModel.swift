//
//  ChatViewModel.swift
//  CodingReviewer
//
//  Manages chat state, message history, and AI mode orchestration
//

import Foundation
import SwiftUI

/// Chat modes
public enum ChatMode: String, CaseIterable, Sendable {
    case chat = "Chat"
    case planning = "Planning"
    case agent = "Agent"
}

/// A single message in the chat
public struct ChatMessage: Identifiable, Sendable {
    public let id: UUID
    public let role: MessageRole
    public var content: String
    public let timestamp: Date
    public var isStreaming: Bool

    public enum MessageRole: String, Sendable {
        case user
        case assistant
        case system
    }

    public init(role: MessageRole, content: String, isStreaming: Bool = false) {
        self.id = UUID()
        self.role = role
        self.content = content
        self.timestamp = Date()
        self.isStreaming = isStreaming
    }
}

/// Chat view model managing conversation state
@MainActor
@Observable
public final class ChatViewModel {
    // State
    public var messages: [ChatMessage] = []
    public var inputText: String = ""
    public var isGenerating: Bool = false
    public var isConnected: Bool = false
    public var currentMode: ChatMode = .chat
    public var selectedModel: String = "llama3.1:8b"
    public var availableModels: [String] = []
    public var errorMessage: String?

    // Services
    private let ollamaService = OllamaService()
    private var streamTask: Task<Void, Never>?

    // Settings keys
    private let ollamaEndpointKey = "CR_OLLAMA_ENDPOINT"
    private let defaultModelKey = "CR_OLLAMA_MODEL"
    private let temperatureKey = "CR_OLLAMA_TEMPERATURE"

    /// Settings values (cached from UserDefaults)
    private var ollamaEndpoint: String {
        UserDefaults.standard.string(forKey: ollamaEndpointKey) ?? "http://localhost:11434"
    }

    private var temperature: Double {
        let value = UserDefaults.standard.double(forKey: temperatureKey)
        return value > 0 ? value : 0.7
    }

    public init() {
        // Load default model from UserDefaults
        if let savedModel = UserDefaults.standard.string(forKey: defaultModelKey),
           !savedModel.isEmpty
        {
            selectedModel = savedModel
        }
        Task { await checkConnection() }
    }

    /// Save selected model to UserDefaults
    public func saveSelectedModel() {
        UserDefaults.standard.set(selectedModel, forKey: defaultModelKey)
    }

    // MARK: - Connection

    public func checkConnection() async {
        isConnected = await ollamaService.isAvailable()
        if isConnected {
            await loadModels()
        }
    }

    public func loadModels() async {
        do {
            let models = try await ollamaService.listModels()
            availableModels = models.map(\.name)
            if !availableModels.contains(selectedModel), let first = availableModels.first {
                selectedModel = first
            }
        } catch {
            errorMessage = "Failed to load models: \(error.localizedDescription)"
        }
    }

    // MARK: - Send Message

    public func sendMessage(context: String? = nil) async {
        let userText = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !userText.isEmpty else { return }

        // Add user message
        let userMessage = ChatMessage(role: .user, content: userText)
        messages.append(userMessage)
        inputText = ""
        errorMessage = nil

        // Build conversation
        let systemPrompt = buildSystemPrompt(context: context)
        var ollamaMessages: [OllamaChatMessage] = [
            OllamaChatMessage(role: "system", content: systemPrompt),
        ]

        // Add recent message history (last 20 messages for context)
        let recentMessages = messages.suffix(20)
        for msg in recentMessages {
            let role = msg.role == .user ? "user" : "assistant"
            ollamaMessages.append(OllamaChatMessage(role: role, content: msg.content))
        }

        // Create assistant placeholder for streaming
        let assistantMessage = ChatMessage(role: .assistant, content: "", isStreaming: true)
        messages.append(assistantMessage)
        let assistantIndex = messages.count - 1

        isGenerating = true

        streamTask = Task {
            do {
                let stream = await ollamaService.chatStream(
                    model: selectedModel,
                    messages: ollamaMessages,
                    temperature: temperature
                )

                for try await chunk in stream {
                    guard !Task.isCancelled else { break }
                    messages[assistantIndex].content += chunk
                }

                messages[assistantIndex].isStreaming = false
            } catch {
                if !Task.isCancelled {
                    messages[assistantIndex].content = "Error: \(error.localizedDescription)"
                    messages[assistantIndex].isStreaming = false
                    errorMessage = error.localizedDescription
                }
            }

            isGenerating = false
        }
    }

    public func stopGenerating() {
        streamTask?.cancel()
        streamTask = nil
        isGenerating = false

        // Mark last message as done
        if let lastIndex = messages.indices.last, messages[lastIndex].isStreaming {
            messages[lastIndex].isStreaming = false
        }
    }

    public func clearChat() {
        messages.removeAll()
        errorMessage = nil
    }

    // MARK: - System Prompts

    private func buildSystemPrompt(context: String?) -> String {
        var prompt = switch currentMode {
        case .chat:
            """
            You are CodingReviewer AI, a helpful coding assistant running locally via Ollama.
            You help with code analysis, debugging, writing, and answering programming questions.
            Be concise but thorough. Use code blocks with language labels for code.
            """

        case .planning:
            """
            You are CodingReviewer AI in Planning Mode.
            When the user describes a task, break it down into a clear, step-by-step plan.
            Format the plan as numbered steps. Include file paths, code snippets, and commands.
            Identify potential risks or dependencies between steps.
            """

        case .agent:
            """
            You are CodingReviewer AI in Agent Mode.
            You can help orchestrate Docker agents and MCP tools.
            Available agents: codegen, architect, debug, testing, reviewer, planner, audit.
            When the user asks for a task, determine which agent(s) to use and provide
            the commands needed. Format agent commands clearly.
            """
        }

        if let context, !context.isEmpty {
            prompt += "\n\nCurrent file context:\n```\n\(context.prefix(2000))\n```"
        }

        return prompt
    }
}
