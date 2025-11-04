import SwiftUI

struct SettingsView: View {
    @AppStorage("CR_USE_AI") private var useAI: Bool = false

    var body: some View {
        Form {
            Section("AI & Agents") {
                Toggle("Use AI‑enhanced analysis (Ollama)", isOn: $useAI)
                Text("Requires local Ollama with free models: llama3.1:8b, qwen2.5-coder:7b, mistral:7b.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .frame(minWidth: 420)
    }
}

#Preview {
    SettingsView()
}
