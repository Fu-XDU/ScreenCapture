//
//  SettingsModel.swift
//  ScreenCapture
//
//  Created by 付铭 on 2024/8/23.
//

import Foundation

enum ServiceScheme {
    static let ws = "ws"
    static let wss = "wss"
}

enum UploadScheme {
    static let http = "http"
    static let https = "https"
}

struct UserSettings {
    var serviceOn: Bool = false

    var serviceScheme: String = ServiceScheme.ws
    var serviceURL: String = ""

    var deleteAfterUpload: Bool = false
    var launchWhenLogin: Bool = false

    var uploadOn: Bool = false
    var uploadScheme: String = UploadScheme.http
    var uploadURL: String = ""
    var serviceToken: String = ""
    var uploadTestPassed: Bool = false

    var screenshotDir: String = {
        NSHomeDirectory() + "/Screenshots"
    }()

    var logDir: String = {
        NSHomeDirectory() + "/Logs"
    }()

    static var `default`: UserSettings {
        UserSettings()
    }
}

enum UserSettingsKey {
    static let serviceOn = "serviceOn"
    static let serviceScheme = "serviceScheme"
    static let serviceURL = "serviceURL"

    static let deleteAfterUpload = "deleteAfterUpload"
    static let launchWhenLogin = "launchWhenLogin"

    static let uploadOn = "uploadOn"
    static let uploadScheme = "uploadScheme"
    static let uploadURL = "uploadURL"
    static let serviceToken = "serviceToken"
//    static let uploadTestPassed = "uploadTestPassed"

    static let screenshotDir = "screenshotDir"
    static let logDir = "logDir"
}
