//
//  OllamaService.swift
//  CodingReviewer
//
//  Modern async Ollama HTTP client with streaming support
//

import Foundation

/// Response from Ollama /api/tags endpoint
public struct OllamaModelList: Codable, Sendable {
    public let models: [OllamaModel]
}

public struct OllamaModel: Codable, Sendable, Identifiable {
    public var id: String { name }
    public let name: String
    public let size: Int64?
    public let digest: String?

    enum CodingKeys: String, CodingKey {
        case name, size, digest
    }
}

/// Request body for /api/chat
struct OllamaChatRequest: Codable {
    let model: String
    let messages: [OllamaChatMessage]
    let stream: Bool
    let options: OllamaOptions?
}

public struct OllamaChatMessage: Codable, Sendable {
    public let role: String
    public let content: String

    public init(role: String, content: String) {
        self.role = role
        self.content = content
    }
}

struct OllamaOptions: Codable {
    let temperature: Double?
    let num_predict: Int?
    let top_p: Double?
}

/// Single chunk from streaming response
struct OllamaChatChunk: Codable {
    let model: String?
    let message: OllamaChatMessage?
    let done: Bool
    let total_duration: Int64?
    let eval_count: Int?
}

/// Request body for /api/generate
struct OllamaGenerateRequest: Codable {
    let model: String
    let prompt: String
    let system: String?
    let stream: Bool
    let options: OllamaOptions?
}

struct OllamaGenerateChunk: Codable {
    let model: String?
    let response: String?
    let done: Bool
}

/// Async Ollama HTTP client
public actor OllamaService {
    private let baseURL: URL
    private let session: URLSession

    public init(endpoint: String = "http://localhost:11434") {
        self.baseURL = URL(string: endpoint)!
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 120
        config.timeoutIntervalForResource = 300
        self.session = URLSession(configuration: config)
    }

    // MARK: - Health Check

    public func isAvailable() async -> Bool {
        let url = baseURL.appendingPathComponent("api/tags")
        do {
            let (_, response) = try await session.data(from: url)
            return (response as? HTTPURLResponse)?.statusCode == 200
        } catch {
            return false
        }
    }

    // MARK: - List Models

    public func listModels() async throws -> [OllamaModel] {
        let url = baseURL.appendingPathComponent("api/tags")
        let (data, response) = try await session.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw OllamaServiceError.serverError("Failed to list models")
        }
        let modelList = try JSONDecoder().decode(OllamaModelList.self, from: data)
        return modelList.models
    }

    // MARK: - Chat (Non-Streaming)

    public func chat(
        model: String,
        messages: [OllamaChatMessage],
        temperature: Double = 0.7
    ) async throws -> String {
        let url = baseURL.appendingPathComponent("api/chat")
        let request = OllamaChatRequest(
            model: model,
            messages: messages,
            stream: false,
            options: OllamaOptions(temperature: temperature, num_predict: nil, top_p: nil)
        )

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try JSONEncoder().encode(request)

        let (data, response) = try await session.data(for: urlRequest)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw OllamaServiceError.serverError("Chat request failed")
        }

        let chunk = try JSONDecoder().decode(OllamaChatChunk.self, from: data)
        return chunk.message?.content ?? ""
    }

    // MARK: - Chat (Streaming)

    public func chatStream(
        model: String,
        messages: [OllamaChatMessage],
        temperature: Double = 0.7
    ) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    let url = baseURL.appendingPathComponent("api/chat")
                    let request = OllamaChatRequest(
                        model: model,
                        messages: messages,
                        stream: true,
                        options: OllamaOptions(
                            temperature: temperature, num_predict: nil, top_p: nil
                        )
                    )

                    var urlRequest = URLRequest(url: url)
                    urlRequest.httpMethod = "POST"
                    urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    urlRequest.httpBody = try JSONEncoder().encode(request)

                    let (bytes, response) = try await session.bytes(for: urlRequest)
                    guard let httpResponse = response as? HTTPURLResponse,
                          httpResponse.statusCode == 200
                    else {
                        throw OllamaServiceError.serverError("Stream request failed")
                    }

                    for try await line in bytes.lines {
                        guard !line.isEmpty else { continue }
                        if let data = line.data(using: .utf8),
                           let chunk = try? JSONDecoder().decode(OllamaChatChunk.self, from: data),
                           let content = chunk.message?.content
                        {
                            continuation.yield(content)
                            if chunk.done {
                                break
                            }
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    // MARK: - Generate (single prompt)

    public func generate(
        model: String,
        prompt: String,
        system: String? = nil,
        temperature: Double = 0.7
    ) async throws -> String {
        let url = baseURL.appendingPathComponent("api/generate")
        let request = OllamaGenerateRequest(
            model: model,
            prompt: prompt,
            system: system,
            stream: false,
            options: OllamaOptions(temperature: temperature, num_predict: nil, top_p: nil)
        )

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try JSONEncoder().encode(request)

        let (data, response) = try await session.data(for: urlRequest)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw OllamaServiceError.serverError("Generate request failed")
        }

        let chunk = try JSONDecoder().decode(OllamaGenerateChunk.self, from: data)
        return chunk.response ?? ""
    }
}

/// Errors from the Ollama service
public enum OllamaServiceError: Error, LocalizedError {
    case serverError(String)
    case modelNotFound(String)
    case connectionFailed

    public var errorDescription: String? {
        switch self {
        case let .serverError(msg): "Ollama server error: \(msg)"
        case let .modelNotFound(model): "Model '\(model)' not found"
        case .connectionFailed: "Cannot connect to Ollama. Is it running?"
        }
    }
}
