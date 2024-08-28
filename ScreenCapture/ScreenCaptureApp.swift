//
//  ScreenCaptureApp.swift
//  ScreenCapture
//
//  Created by 付铭 on 2024/8/22.
//

import ScreenCaptureKit
import SettingsAccess
import SwiftUI

@main
struct ScreenCaptureApp: App {
    @NSApplicationDelegateAdaptor var delegate: AppDelegate
    @ObservedObject var webSocketManager: WebSocketManager = WebSocketManager(isConnected: false)

    var body: some Scene {
        MenuBarExtra("Screen Capture", systemImage: "camera.metering.center.weighted") {
            AppMenuView()
        }

        #if os(macOS)
            Settings {
                SettingsView(serverConnected: $webSocketManager.isConnected)
                    .environmentObject(webSocketManager)
                    .environmentObject(webSocketManager.screenCaptureService.userDefaultsManager)
            }
        #endif
    }
}

struct AppMenuView: View {
    var body: some View {
        SettingsLink {
            Text("Preferences")
        } preAction: {
            NSApp.activate(ignoringOtherApps: true)
        } postAction: {}
            .keyboardShortcut(",")

        Divider()

        Button("Quit") {
            NSApplication.shared.terminate(nil)

        }.keyboardShortcut("q")
    }
}
