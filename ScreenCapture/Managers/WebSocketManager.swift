//
//  WebSocketManager.swift
//  ScreenCapture
//
//  Created by 付铭 on 2024/8/26.
//

import Foundation
import Starscream

class WebSocketManager: WebSocketDelegate, ObservableObject {
    @Published var screenCaptureService: ScreenCaptureService = ScreenCaptureService()
    @Published var isConnected: Bool {
        didSet {
            if isConnected {
                onConnected()
            } else {
                onDisconnected()
            }
        }
    }

    var socket: WebSocket?

    init(isConnected: Bool, socket: WebSocket? = nil) {
        self.isConnected = isConnected
        self.socket = socket

        let userSettings = screenCaptureService.userDefaultsManager.userSettings
        if userSettings.serviceOn {
            connect(urlString: userSettings.serviceScheme + "://" + userSettings.serviceURL + "?uuid=" + getMacUUIDHashPrefixN()!)
        }
    }

    func connect(urlString: String) {
        guard let url = URL(string: urlString) else { return }
        var request = URLRequest(url: url)
        request.timeoutInterval = 5
        socket = WebSocket(request: request)
        socket?.delegate = self
        socket?.connect()
    }

    func disconnect() {
//        socket?.disconnect()
        socket?.forceDisconnect()
    }

    // WebSocketDelegate methods
    func didReceive(event: Starscream.WebSocketEvent, client: any Starscream.WebSocketClient) {
        switch event {
        case .connected:
            isConnected = true
        case .disconnected:
            isConnected = false
        case .peerClosed:
            isConnected = false
        case let .text(ticket):
            screenCaptureService.uploadTicket = ticket
            if screenCaptureService.userDefaultsManager.userSettings.uploadOn {
                // Test URL
                screenCaptureService.checkUploadEligibility { isEligible in
                    self.screenCaptureService.userDefaultsManager.userSettings.uploadTestPassed = isEligible
                }
            }
        case let .binary(data):
            if let command = String(data: data, encoding: .utf8) {
                handleCommand(cmd: command)
            }
        default:
            break
        }
    }

    func handleError(_ error: Error?) {
        // Handle error as needed
    }

    // Callbacks
    func onConnected() {
        NSLog("WebSocket connected")
//        screenCaptureService.startScreenCapture()
    }

    func onDisconnected() {
        NSLog("WebSocket disconnected")
        screenCaptureService.userDefaultsManager.userSettings.uploadTestPassed = false
//        screenCaptureService.stopScreenCapture()
    }

    func handleCommand(cmd: String) {
        switch cmd {
        case ScreenCaptureCmd.screenshot:
            screenCaptureService.captureScreenshot()
        default:
            NSLog("unknown command: \(cmd)")
        }
    }
}

enum ScreenCaptureCmd {
    static let screenshot = "0"
}
