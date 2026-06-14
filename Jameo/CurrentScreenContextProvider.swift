import AppKit

@MainActor
final class CurrentScreenContextProvider {
    private let panelProvider: () -> NSPanel?
    private let restorePanel: (NSPanel) -> Void
    private let captureService: ScreenContextCaptureService

    init(
        panelProvider: @escaping () -> NSPanel?,
        restorePanel: @escaping (NSPanel) -> Void,
        captureService: ScreenContextCaptureService = ScreenContextCaptureService()
    ) {
        self.panelProvider = panelProvider
        self.restorePanel = restorePanel
        self.captureService = captureService
    }

    func captureImage() async throws -> Data? {
        guard let panel = panelProvider() else {
            return nil
        }

        let targetScreen = panel.screen ?? NSScreen.main
        panel.orderOut(nil)
        defer {
            restorePanel(panel)
        }

        try await Task.sleep(nanoseconds: 80_000_000)
        return try await captureService.captureDisplay(containing: targetScreen)
    }
}
