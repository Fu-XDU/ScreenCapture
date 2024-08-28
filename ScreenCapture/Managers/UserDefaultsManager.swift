//
//  UserDefaultsManager.swift
//  ScreenCapture
//
//  Created by 付铭 on 2024/8/25.
//

import AppKit
import Foundation
import ServiceManagement

class UserDefaultsManager: ObservableObject {
    private let userDefaults = UserDefaults.standard
    private var loading: Bool = true

    @Published var userSettings: UserSettings = UserSettings() {
        didSet {
            if !loading {
                saveUserSettings()
            }

            do {
                if userSettings.launchWhenLogin {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                Swift.print(error.localizedDescription)
            }
        }
    }

    init() {
        loadUserSettings()
        _ = createDirectoryIfNotExists(path: userSettings.screenshotDir)
    }

    func saveUserSettings() {
        userDefaults.set(userSettings.serviceOn, forKey: UserSettingsKey.serviceOn)
        userDefaults.set(userSettings.serviceScheme, forKey: UserSettingsKey.serviceScheme)
        userDefaults.set(userSettings.serviceURL, forKey: UserSettingsKey.serviceURL)

        userDefaults.set(userSettings.deleteAfterUpload, forKey: UserSettingsKey.deleteAfterUpload)
        userDefaults.set(userSettings.launchWhenLogin, forKey: UserSettingsKey.launchWhenLogin)

        userDefaults.set(userSettings.uploadOn, forKey: UserSettingsKey.uploadOn)
        userDefaults.set(userSettings.uploadScheme, forKey: UserSettingsKey.uploadScheme)
        userDefaults.set(userSettings.uploadURL, forKey: UserSettingsKey.uploadURL)
        userDefaults.set(userSettings.serviceToken, forKey: UserSettingsKey.serviceToken)
//        userDefaults.set(userSettings.uploadTestPassed, forKey: UserSettingsKey.uploadTestPassed)

        userDefaults.set(userSettings.screenshotDir, forKey: UserSettingsKey.screenshotDir)
        userDefaults.set(userSettings.logDir, forKey: UserSettingsKey.logDir)
    }

    func loadUserSettings() {
        userSettings.serviceOn = userDefaults.bool(forKey: UserSettingsKey.serviceOn)
        userSettings.serviceScheme = userDefaults.string(forKey: UserSettingsKey.serviceScheme) ?? ServiceScheme.ws
        userSettings.serviceURL = userDefaults.string(forKey: UserSettingsKey.serviceURL) ?? ""

        userSettings.deleteAfterUpload = userDefaults.bool(forKey: UserSettingsKey.deleteAfterUpload)
        userSettings.launchWhenLogin = userDefaults.bool(forKey: UserSettingsKey.launchWhenLogin)

        userSettings.uploadOn = userDefaults.bool(forKey: UserSettingsKey.uploadOn)
        userSettings.uploadScheme = userDefaults.string(forKey: UserSettingsKey.uploadScheme) ?? UploadScheme.http
        userSettings.uploadURL = userDefaults.string(forKey: UserSettingsKey.uploadURL) ?? ""
        userSettings.serviceToken = userDefaults.string(forKey: UserSettingsKey.serviceToken) ?? ""
//        userSettings.uploadTestPassed = userDefaults.bool(forKey: UserSettingsKey.uploadTestPassed)

        userSettings.screenshotDir = userDefaults.string(forKey: UserSettingsKey.screenshotDir) ?? userSettings.screenshotDir
        userSettings.logDir = userDefaults.string(forKey: UserSettingsKey.logDir) ?? userSettings.logDir
        loading = false
    }

    func resetSettings() {
        userSettings = UserSettings.default
    }
}
