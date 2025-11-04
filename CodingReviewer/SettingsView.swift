import SwiftUI

struct SettingsView: View {
    @AppStorage("CR_USE_AI") private var useAI: Bool = false
    @State private var ollamaStatus: String = "Checking..."

    var body: some View {
        Form {
            Section("AI & Agents") {
                Toggle("Use AI‑enhanced analysis (Ollama)", isOn: $useAI)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Requires local Ollama with free models:")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Text("• llama3.1:8b  • qwen2.5-coder:7b  • mistral:7b")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Text("Ollama Status:")
                        .font(.footnote)
                    Text(ollamaStatus)
                        .font(.footnote)
                        .foregroundStyle(ollamaStatus.contains("✓") ? .green : .secondary)
                }
            }

            Section("About") {
                LabeledContent("Version", value: "1.0.0")
                LabeledContent("AI Mode", value: useAI ? "Enabled" : "Disabled")
            }
        }
        .padding(16)
        .frame(minWidth: 480, minHeight: 300)
        .onAppear {
            checkOllamaStatus()
        }
    }

    private func checkOllamaStatus() {
        Task {
            do {
                let client = OllamaClient()
                _ = try await client.generate(model: "llama3.1:8b", prompt: "test", temperature: 0.0)
                ollamaStatus = "✓ Connected"
            } catch {
                ollamaStatus = "⚠️ Not available"
            }
        }
    }
}

#Preview {
    SettingsView()
}
