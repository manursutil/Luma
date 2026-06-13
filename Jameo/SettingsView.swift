import SwiftUI

struct SettingsView: View {
    var body: some View {
        Form {
            Section("Model") {
                Text("Model selection will be added in the next settings milestone.")
                    .foregroundStyle(.secondary)
            }

            Section("Reasoning") {
                Toggle("Reasoning", isOn: .constant(false))
                    .disabled(true)
            }
        }
        .formStyle(.grouped)
        .padding()
        .frame(width: 420, height: 220)
    }
}

#Preview {
    SettingsView()
}
