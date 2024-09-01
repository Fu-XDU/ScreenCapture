//
//  ScreenCaptureApp.swift
//  ScreenCapture
//
//  Created by 付铭 on 2024/8/22.
//

import KeyboardShortcuts
import ScreenCaptureKit
import SettingsAccess
import SwiftUI

@main
struct ScreenCaptureApp: App {
    @NSApplicationDelegateAdaptor var delegate: AppDelegate

    @StateObject private var appState = AppState()

    var body: some Scene {
        MenuBarExtra("Screen Capture", systemImage: "camera.metering.center.weighted") {
            AppMenuView(appState: appState)
        }

        #if os(macOS)
            Settings {
                SettingsView(serverConnected: $appState.webSocketManager.isConnected)
                    .environmentObject(appState.webSocketManager)
                    .environmentObject(appState.webSocketManager.screenCaptureService.userDefaultsManager)
            }
        #endif
    }
}

struct AppMenuView: View {
    var appState: AppState

    init(appState: AppState) {
        self.appState = appState
    }

    var body: some View {
        Button(NSLocalizedString("Capture Screen", comment: "截屏")) {
            appState.webSocketManager.screenCaptureService.captureScreenshot()
        }.keyboardShortcut("k", modifiers: [.command, .option])

        Divider()

        SettingsLink {
            Text(NSLocalizedString("Preferences", comment: "偏好设置"))
        } preAction: {
            NSApp.activate(ignoringOtherApps: true)
        } postAction: {}
            .keyboardShortcut(",")

        Divider()

        Button(NSLocalizedString("Quit", comment: "退出")) {
            NSApplication.shared.terminate(nil)

        }.keyboardShortcut("q")
    }
}

@MainActor
final class AppState: ObservableObject {
    @ObservedObject var webSocketManager: WebSocketManager = WebSocketManager(isConnected: false)

    init() {
        KeyboardShortcuts.onKeyUp(for: .screenCapture) { [self] in
            webSocketManager.screenCaptureService.captureScreenshot()
        }
    }
}
