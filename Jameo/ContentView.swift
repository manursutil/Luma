//
//  ContentView.swift
//  Jameo
//
//  Created by Manuel Rodríguez Sutil on 13/06/2026.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var viewModel: JameoViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                PromptTextField(
                    text: $viewModel.prompt,
                    placeholder: promptPlaceholder,
                    focusRequest: viewModel.focusRequest
                ) {
                    viewModel.askJameo()
                }
                .frame(height: 30)

                screenContextControl

                Button {
                    viewModel.askJameo()
                } label: {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(submitButtonForeground)
                        .frame(width: 30, height: 30)
                }
                .buttonStyle(.borderless)
                .background(Circle().fill(submitButtonFill))
                .overlay(Circle().stroke(submitButtonStroke, lineWidth: 0.8))
                .glassEffect(.regular, in: Circle())
                .shadow(color: submitButtonShadow, radius: 7, y: 2)
                .keyboardShortcut(.defaultAction)
                .disabled(!viewModel.canSubmit)
            }
            .padding(.leading, 6)
            .padding(.trailing, 6)
            .padding(.vertical, 6)
            .background {
                Capsule(style: .continuous)
                    .fill(Color.white.opacity(0.055))
                    .overlay(
                        Capsule(style: .continuous)
                            .stroke(Color.white.opacity(0.12), lineWidth: 0.8)
                    )
            }

            if viewModel.didSubmitWithScreenContext {
                Label("Screen included", systemImage: "rectangle.inset.filled")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background {
                        Capsule(style: .continuous)
                            .fill(Color.white.opacity(0.05))
                            .glassEffect(.regular, in: Capsule(style: .continuous))
                            .overlay(
                                Capsule(style: .continuous)
                                    .stroke(Color.accentColor.opacity(0.18), lineWidth: 0.8)
                            )
                    }
            }

            if viewModel.isLoading {
                Text("Thinking...")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            if !viewModel.answer.isEmpty {
                Divider()
                ScrollView {
                    Text(renderedAnswer)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .fixedSize(horizontal: false, vertical: true)
                        .textSelection(.enabled)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .frame(width: 620, alignment: .topLeading)
    }

    private var screenContextControl: some View {
        Button {
            viewModel.screenContextEnabled.toggle()
        } label: {
            Text("Include screen")
                .font(.system(size: 15, weight: .medium))
                .lineLimit(1)
                .frame(minWidth: 104, minHeight: 30)
                .contentShape(Capsule(style: .continuous))
        }
        .buttonStyle(.plain)
        .foregroundStyle(screenContextControlForeground)
        .opacity(screenContextControlOpacity)
        .help(screenContextHelp)
        .disabled(!viewModel.canToggleScreenContext)
    }

    private var renderedAnswer: AttributedString {
        let options = AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        return (try? AttributedString(markdown: viewModel.answer, options: options)) ?? AttributedString(viewModel.answer)
    }

    private var isSubmitDisabled: Bool {
        !viewModel.canSubmit
    }

    private var screenContextControlForeground: Color {
        guard viewModel.canToggleScreenContext || viewModel.screenContextEnabled else {
            return .secondary
        }

        return viewModel.screenContextEnabled ? .accentColor : .secondary
    }

    private var screenContextControlOpacity: Double {
        viewModel.canToggleScreenContext || viewModel.screenContextEnabled ? 1 : 0.58
    }

    private var submitButtonForeground: Color {
        isSubmitDisabled ? .secondary : .primary
    }

    private var submitButtonFill: Color {
        isSubmitDisabled ? Color.white.opacity(0.05) : Color.white.opacity(0.16)
    }

    private var submitButtonStroke: Color {
        isSubmitDisabled ? Color.white.opacity(0.10) : Color.white.opacity(0.28)
    }

    private var submitButtonShadow: Color {
        isSubmitDisabled ? .clear : Color.black.opacity(0.16)
    }

    private var promptPlaceholder: String {
        viewModel.screenContextEnabled ? String(localized: "Ask Jameo about your screen...") : String(localized: "Ask Jameo...")
    }

    private var screenContextHelp: String {
        if viewModel.isCheckingScreenContextAvailability {
            return String(localized: "Checking screen context availability...")
        }

        if !viewModel.screenContextAvailable {
            return String(localized: "The selected model does not support screen context.")
        }

        return String(localized: "Include current screen with the next question")
    }
}

#Preview {
    ContentView(viewModel: JameoViewModel())
}
