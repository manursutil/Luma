import Combine
import SwiftUI

@MainActor
final class LocalOllamaModelsViewModel: ObservableObject {
    @Published private(set) var models: [String] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    func load() async {
        isLoading = true
        errorMessage = nil

        do {
            models = try await OllamaService.shared.localModelNames()
        } catch {
            models = []
            errorMessage = String(localized: "Could not load local Ollama models.")
        }

        isLoading = false
    }
}

struct SettingsView: View {
    @AppStorage(JameoSettings.modelKey) private var model = JameoSettings.defaultModel
    @AppStorage(JameoSettings.reasoningEnabledKey) private var reasoningEnabled = false
    @AppStorage(JameoSettings.preservePanelStateKey) private var preservePanelState = false
    @StateObject private var localModels = LocalOllamaModelsViewModel()

    var body: some View {
        Form {
            Section("Model") {
                Picker("Model", selection: $model) {
                    ForEach(localModels.models, id: \.self) { modelName in
                        Text(modelName).tag(modelName)
                    }
                }
                .disabled(localModels.models.isEmpty)

                Text("Only models downloaded in Ollama are shown here. Pull more models in Ollama, then refresh this list.")
                    .foregroundStyle(.secondary)

                if localModels.isLoading {
                    ProgressView()
                        .controlSize(.small)
                } else if let errorMessage = localModels.errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(.secondary)
                } else if localModels.models.isEmpty {
                    Text("No downloaded Ollama models found.")
                        .foregroundStyle(.secondary)
                }

                Button("Refresh") {
                    Task {
                        await reloadLocalModels()
                    }
                }
                .disabled(localModels.isLoading)
            }

            Section("Reasoning") {
                Toggle("Enable reasoning", isOn: $reasoningEnabled)
            }

            Section("Panel") {
                Toggle("Preserve prompt and answer when opening", isOn: $preservePanelState)
            }
        }
        .formStyle(.grouped)
        .padding()
        .frame(width: 440, height: 320)
        .task {
            await reloadLocalModels()
        }
    }

    private func reloadLocalModels() async {
        await localModels.load()

        guard !localModels.models.isEmpty, !localModels.models.contains(model) else {
            return
        }

        model = localModels.models[0]
    }
}

#Preview {
    SettingsView()
}
