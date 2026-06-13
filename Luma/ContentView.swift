//
//  ContentView.swift
//  Luma
//
//  Created by Manuel Rodríguez Sutil on 13/06/2026.
//

import Combine
import SwiftUI

@MainActor
final class LumaViewModel: ObservableObject {
    @Published var prompt: String = ""
    @Published var answer: String = ""
    @Published var isLoading: Bool = false
    @Published var focusRequest = UUID()

    func requestFocus() {
        focusRequest = UUID()
    }

    func askLuma() {
        let submittedPrompt = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !submittedPrompt.isEmpty, !isLoading else { return }

        Task {
            isLoading = true
            answer = ""

            do {
                let stream = OllamaService.shared.generateStream(prompt: submittedPrompt)

                for try await chunk in stream {
                    answer += chunk
                }
            } catch {
                answer = "Error \(error)"
            }

            isLoading = false
        }
    }
}

struct ContentView: View {
    @ObservedObject var viewModel: LumaViewModel
    @FocusState private var promptIsFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                TextField("Ask Luma...", text: $viewModel.prompt)
                    .textFieldStyle(.plain)
                    .font(.title3)
                    .submitLabel(.send)
                    .focused($promptIsFocused)
                    .onSubmit {
                        viewModel.askLuma()
                    }

                Button {
                    viewModel.askLuma()
                } label: {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 34, height: 34)
                }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.circle)
                .tint(.black)
                .keyboardShortcut(.defaultAction)
                .disabled(viewModel.isLoading || viewModel.prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }

            if viewModel.isLoading {
                ProgressView()
            }

            if !viewModel.answer.isEmpty {
                Divider()
                ScrollView {
                    Text(renderedAnswer)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)
                }
                .frame(maxHeight: 300)
            }
        }
        .padding()
        .frame(width: 700, alignment: .topLeading)
        .onAppear {
            promptIsFocused = true
        }
        .onChange(of: viewModel.focusRequest) {
            promptIsFocused = false
            Task { @MainActor in
                promptIsFocused = true
            }
        }
    }

    private var renderedAnswer: AttributedString {
        let options = AttributedString.MarkdownParsingOptions(interpretedSyntax: .full)
        return (try? AttributedString(markdown: viewModel.answer, options: options)) ?? AttributedString(viewModel.answer)
    }
}

#Preview {
    ContentView(viewModel: LumaViewModel())
}
