//
//  WebSocketManager.swift
//  ScreenCapture
//
//  Created by 付铭 on 2024/8/26.
//

import Foundation
import Starscream

class WebSocketManager: WebSocketDelegate, ObservableObject {
    var reconnectTimer: Timer?
    private var pingTimes: Int = 0

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

        connect()
        startReconnectTimer()
    }

    func connect() {
        let userSettings = screenCaptureService.userDefaultsManager.userSettings
        if userSettings.serviceOn {
            connectTo(urlString: userSettings.serviceScheme + "://" + userSettings.serviceURL + "?uuid=" + getMacUUIDHashPrefixN()!)
        }
    }

    func connectTo(urlString: String) {
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
        case .pong(_):
            pingTimes = 0
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
    }

    func onDisconnected() {
        NSLog("WebSocket disconnected")
        screenCaptureService.userDefaultsManager.userSettings.uploadTestPassed = false
        if screenCaptureService.userDefaultsManager.userSettings.serviceOn {
            // Connect Loop
            pingTimes = 5
        }
    }

    func startReconnectTimer() {
        reconnectTimer?.invalidate() // 防止定时器重复创建
        reconnectTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if !screenCaptureService.userDefaultsManager.userSettings.serviceOn {
                return
            }
            if self.pingTimes >= 5 {
                // may be disconnected
                NSLog("may be disconnected, reconnect")
                self.connect()
            } else {
                self.socket?.write(ping: Data())
                self.pingTimes += 1
                NSLog("ping times: \(pingTimes)")
            }
        }
    }

    func stopReconnectTimer() {
        reconnectTimer?.invalidate()
        reconnectTimer = nil
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
