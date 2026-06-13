import AppKit
import Carbon
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let viewModel = LumaViewModel()
    private lazy var panelController = SpotlightPanelController(viewModel: viewModel)
    private var hotKeyManager: HotKeyManager?
    private var statusItem: NSStatusItem?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        setUpMenuBarItem()
        setUpHotKey()
    }

    func applicationWillTerminate(_ notification: Notification) {
        hotKeyManager = nil
    }

    @objc private func openLuma() {
        panelController.show()
    }

    @objc private func openSettings() {
        NSApp.activate(ignoringOtherApps: true)
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
    }

    @objc private func quitLuma() {
        NSApp.terminate(nil)
    }

    private func setUpMenuBarItem() {
        let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem.button?.image = NSImage(
            systemSymbolName: "sparkle.magnifyingglass",
            accessibilityDescription: "Luma"
        )
        statusItem.button?.imagePosition = .imageOnly

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Open Luma", action: #selector(openLuma), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Settings...", action: #selector(openSettings), keyEquivalent: ","))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit Luma", action: #selector(quitLuma), keyEquivalent: "q"))

        for item in menu.items {
            item.target = self
        }

        statusItem.menu = menu
        self.statusItem = statusItem
    }

    private func setUpHotKey() {
        hotKeyManager = HotKeyManager(keyCode: UInt32(kVK_Space), modifiers: cmdKey | shiftKey) { [weak self] in
            self?.panelController.toggle()
        }
    }
}
