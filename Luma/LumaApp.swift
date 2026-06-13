//
//  LumaApp.swift
//  Luma
//
//  Created by Manuel Rodríguez Sutil on 13/06/2026.
//

import SwiftUI

@main
struct LumaApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings {
            SettingsView()
        }
    }
}
