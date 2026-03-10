//
//  ChatView.swift
//  CodingReviewer
//
//  AI Chat interface with message bubbles, streaming, and mode selection
//

import SwiftUI

/// Main chat view for AI interaction
public struct ChatView: View {
    @Bindable var viewModel: ChatViewModel
    @Bindable var editorVM: EditorViewModel
    @State private var isModelPickerPresented = false

    public var body: some View {
        VStack(spacing: 0) {
            // Chat header with mode and model selection
            ChatHeader(viewModel: viewModel, isModelPickerPresented: $isModelPickerPresented)

            Divider()

            // Messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        ForEach(viewModel.messages) { message in
                            ChatMessageBubble(message: message)
                                .id(message.id)
                        }
                    }
                    .padding(12)
                }
                .onChange(of: viewModel.messages.count) { _, _ in
                    if let lastID = viewModel.messages.last?.id {
                        withAnimation(.easeOut(duration: 0.2)) {
                            proxy.scrollTo(lastID, anchor: .bottom)
                        }
                    }
                }
            }

            // Error message
            if let error = viewModel.errorMessage {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                        .font(.caption)
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button("Dismiss") { viewModel.errorMessage = nil }
                        .font(.caption)
                        .buttonStyle(.borderless)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.orange.opacity(0.1))
            }

            Divider()

            // Input area
            ChatInputView(viewModel: viewModel, editorVM: editorVM)
        }
        .popover(isPresented: $isModelPickerPresented) {
            ModelPickerView(viewModel: viewModel)
        }
    }
}

/// Chat header with mode selector and model info
struct ChatHeader: View {
    @Bindable var viewModel: ChatViewModel
    @Binding var isModelPickerPresented: Bool

    var body: some View {
        HStack(spacing: 8) {
            // Mode selector
            Picker(
                "Mode",
                selection: Binding(
                    get: { viewModel.currentMode },
                    set: { viewModel.currentMode = $0 }
                )
            ) {
                ForEach(ChatMode.allCases, id: \.self) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .frame(maxWidth: 240)

            Spacer()

            // Model selector
            Button(action: { isModelPickerPresented.toggle() }, label: {
                HStack(spacing: 4) {
                    Circle()
                        .fill(viewModel.isConnected ? .green : .red)
                        .frame(width: 6, height: 6)
                    Text(viewModel.selectedModel)
                        .font(.system(size: 10, design: .monospaced))
                        .lineLimit(1)
                }
            })
            .buttonStyle(.bordered)
            .controlSize(.mini)

            // Clear chat
            Button(action: { viewModel.clearChat() }, label: {
                Image(systemName: "trash")
                    .font(.system(size: 11))
            })
            .buttonStyle(.borderless)
            .help("Clear Chat")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}

/// Individual message bubble
struct ChatMessageBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            // Avatar
            Circle()
                .fill(message.role == .user ? Color.blue : Color.green)
                .frame(width: 24, height: 24)
                .overlay {
                    Image(systemName: message.role == .user ? "person.fill" : "cpu")
                        .font(.system(size: 11))
                        .foregroundStyle(.white)
                }

            VStack(alignment: .leading, spacing: 4) {
                // Role label
                HStack {
                    Text(message.role == .user ? "You" : "AI")
                        .font(.system(size: 11, weight: .semibold))

                    Text(message.timestamp, style: .time)
                        .font(.system(size: 9))
                        .foregroundStyle(.tertiary)
                }

                // Content
                if message.content.isEmpty && message.isStreaming {
                    HStack(spacing: 4) {
                        ProgressView()
                            .controlSize(.mini)
                        Text("Thinking...")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Text(message.content)
                        .font(.system(size: 12))
                        .textSelection(.enabled)

                    if message.isStreaming {
                        HStack(spacing: 4) {
                            ProgressView()
                                .controlSize(.mini)
                        }
                    }
                }
            }

            Spacer()
        }
        .padding(8)
        .background(
            message.role == .user
                ? Color(nsColor: .controlBackgroundColor)
                : Color(nsColor: .textBackgroundColor)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

/// Input area with text field and send button
struct ChatInputView: View {
    @Bindable var viewModel: ChatViewModel
    @Bindable var editorVM: EditorViewModel
    @State private var includeContext: Bool = false

    var body: some View {
        VStack(spacing: 4) {
            // Context toggle
            if editorVM.activeFile != nil {
                HStack(spacing: 6) {
                    Toggle(isOn: $includeContext) {
                        HStack(spacing: 4) {
                            Image(systemName: "doc.text")
                                .font(.system(size: 10))
                            Text("Include \(editorVM.activeFile?.filename ?? "file")")
                                .font(.system(size: 10))
                        }
                    }
                    .toggleStyle(.checkbox)
                    .controlSize(.mini)

                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.top, 4)
            }

            // Input field and buttons
            HStack(alignment: .bottom, spacing: 8) {
                // Text editor for multi-line input
                TextEditor(
                    text: Binding(
                        get: { viewModel.inputText },
                        set: { viewModel.inputText = $0 }
                    )
                )
                .font(.system(size: 12))
                .frame(minHeight: 32, maxHeight: 120)
                .scrollContentBackground(.hidden)
                .background(Color(nsColor: .textBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(nsColor: .separatorColor), lineWidth: 1)
                )

                // Send / Stop button
                if viewModel.isGenerating {
                    Button(action: { viewModel.stopGenerating() }, label: {
                        Image(systemName: "stop.circle.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(.red)
                    })
                    .buttonStyle(.borderless)
                    .help("Stop Generating")
                } else {
                    Button(action: {
                        let context = includeContext ? editorVM.activeFile?.content : nil
                        Task { await viewModel.sendMessage(context: context) }
                    }, label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(Color.accentColor)
                    })
                    .buttonStyle(.borderless)
                    .disabled(
                        viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    )
                    .help("Send Message")
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
    }
}

/// Model picker popover
struct ModelPickerView: View {
    @Bindable var viewModel: ChatViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Select Model")
                .font(.headline)

            if viewModel.availableModels.isEmpty {
                Text("No models found. Is Ollama running?")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(viewModel.availableModels, id: \.self) { model in
                    Button(action: {
                        viewModel.selectedModel = model
                        viewModel.saveSelectedModel()
                    }, label: {
                        HStack {
                            Text(model)
                                .font(.system(size: 12, design: .monospaced))
                            Spacer()
                            if model == viewModel.selectedModel {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(Color.accentColor)
                            }
                        }
                    })
                    .buttonStyle(.plain)
                    .padding(.vertical, 2)
                }
            }

            Divider()

            Button("Refresh Models") {
                Task { await viewModel.loadModels() }
            }
            .font(.caption)
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .padding()
        .frame(width: 280)
    }
}
