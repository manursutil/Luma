import SwiftUI

enum JameoSettings {
    static let modelKey = "ollamaModel"
    static let reasoningEnabledKey = "reasoningEnabled"
    static let preservePanelStateKey = "preservePanelState"
    static let defaultModel = "qwen3.5:9b"

    static var model: String {
        let savedModel = UserDefaults.standard.string(forKey: modelKey) ?? defaultModel

        return sanitizedModel(savedModel)
    }

    static var reasoningEnabled: Bool {
        UserDefaults.standard.bool(forKey: reasoningEnabledKey)
    }

    static var preservePanelState: Bool {
        UserDefaults.standard.bool(forKey: preservePanelStateKey)
    }

    private static func sanitizedModel(_ rawModel: String) -> String {
        let trimmedModel = rawModel.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedModel.isEmpty else {
            return defaultModel
        }

        let namespaceAndModel = trimmedModel.split(separator: "/", maxSplits: 1, omittingEmptySubsequences: false)
        let modelAndTagPart: Substring

        if namespaceAndModel.count == 2 {
            guard !namespaceAndModel[0].isEmpty else {
                return defaultModel
            }

            modelAndTagPart = namespaceAndModel[1]
        } else {
            modelAndTagPart = namespaceAndModel[0]
        }

        let modelAndTag = modelAndTagPart.split(separator: ":", maxSplits: 1, omittingEmptySubsequences: false)
        guard let modelName = modelAndTag.first, !modelName.isEmpty else {
            return defaultModel
        }

        if modelAndTag.count == 2, modelAndTag[1].isEmpty {
            return defaultModel
        }

        return trimmedModel
    }
}

struct SettingsView: View {
    @AppStorage(JameoSettings.modelKey) private var model = JameoSettings.defaultModel
    @AppStorage(JameoSettings.reasoningEnabledKey) private var reasoningEnabled = false
    @AppStorage(JameoSettings.preservePanelStateKey) private var preservePanelState = false

    var body: some View {
        Form {
            Section("Modelo") {
                TextField("Modelo", text: $model)
                    .textFieldStyle(.roundedBorder)
            }

            Section("Razonamiento") {
                Toggle("Activar razonamiento", isOn: $reasoningEnabled)
            }

            Section("Panel") {
                Toggle("Conservar prompt y respuesta al abrir", isOn: $preservePanelState)
            }
        }
        .formStyle(.grouped)
        .padding()
        .frame(width: 440, height: 260)
    }
}

#Preview {
    SettingsView()
}
