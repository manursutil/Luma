import AppKit
import Combine
import SwiftUI

@MainActor
final class SpotlightPanelController: NSObject, NSWindowDelegate {
    private let viewModel: LumaViewModel
    private var panel: SpotlightPanel?
    private var cancellables: Set<AnyCancellable> = []

    init(viewModel: LumaViewModel) {
        self.viewModel = viewModel
        super.init()
        observeContentChanges()
    }

    func toggle() {
        if panel?.isVisible == true {
            hide()
        } else {
            show()
        }
    }

    func show() {
        let panel = panel ?? makePanel()
        self.panel = panel

        position(panel)
        NSApp.activate(ignoringOtherApps: true)
        panel.orderFrontRegardless()
        panel.makeKey()
        viewModel.requestFocus()
    }

    func hide() {
        panel?.orderOut(nil)
    }

    func windowDidResignKey(_ notification: Notification) {
        hide()
    }

    private func makePanel() -> SpotlightPanel {
        let contentView = ContentView(viewModel: viewModel)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

        let hostingView = NSHostingView(rootView: contentView)
        let panel = SpotlightPanel(
            contentRect: NSRect(x: 0, y: 0, width: 732, height: 112),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        panel.contentView = hostingView
        panel.delegate = self
        panel.isReleasedWhenClosed = false
        panel.hidesOnDeactivate = false
        panel.isMovableByWindowBackground = true
        panel.level = .floating
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]

        return panel
    }

    private func observeContentChanges() {
        viewModel.$answer
            .combineLatest(viewModel.$isLoading)
            .receive(on: RunLoop.main)
            .sink { [weak self] _, _ in
                self?.resizePanelForCurrentContent()
            }
            .store(in: &cancellables)
    }

    private func resizePanelForCurrentContent() {
        guard let panel else { return }

        let targetHeight: CGFloat = viewModel.answer.isEmpty && !viewModel.isLoading ? 112 : 420
        var frame = panel.frame
        let heightDelta = targetHeight - frame.height
        frame.size.height = targetHeight
        frame.origin.y -= heightDelta
        panel.setFrame(frame, display: true, animate: true)
    }

    private func position(_ panel: NSPanel) {
        guard let screen = NSScreen.main ?? NSScreen.screens.first else {
            panel.center()
            return
        }

        let visibleFrame = screen.visibleFrame
        let panelFrame = panel.frame
        let x = visibleFrame.midX - panelFrame.width / 2
        let y = visibleFrame.maxY - panelFrame.height - 120

        panel.setFrameOrigin(NSPoint(x: x, y: y))
    }
}

final class SpotlightPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 {
            orderOut(nil)
            return
        }

        super.keyDown(with: event)
    }
}
