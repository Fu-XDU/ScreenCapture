//
//  PreferencesView.swift
//  ScreenCapture
//
//  Created by 付铭 on 2024/8/22.
//

import SwiftUI

import AppKit
import SwiftUI

struct SettingsView: View {
    @State private var selectedTab = 0
    @EnvironmentObject var userDefaultsManager: UserDefaultsManager
    @EnvironmentObject var webSocketManager: WebSocketManager
    @Binding var serverConnected: Bool

    var body: some View {
        TabView(selection: $selectedTab) {
            SettingsGeneralView(serverConnected: $serverConnected)
                .environmentObject(userDefaultsManager)
                .environmentObject(webSocketManager)
                .tabItem {
                    Image(systemName: "switch.2")
                    Text(NSLocalizedString("General", comment: "通用"))
                }.tag(0)

            SettingsAboutView()
                .tabItem {
                    Image(systemName: "info.circle")
                    Text(NSLocalizedString("About", comment: "关于"))
                }.tag(1)
        }.scenePadding()
    }
}

struct SettingsGeneralView: View {
    let width: CGFloat = 400
    let height: CGFloat = 400

    @EnvironmentObject var userDefaultsManager: UserDefaultsManager
    @EnvironmentObject var webSocketManager: WebSocketManager
    @Binding var serverConnected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                if serverConnected {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 10, height: 10)

                    Text(NSLocalizedString("Service enabled", comment: "服务已启动"))

                } else {
                    if userDefaultsManager.userSettings.serviceOn {
                        Circle()
                            .fill(Color.yellow)
                            .frame(width: 10, height: 10)

                        Text("网络未连接")
                    } else {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 10, height: 10)
                        Text(NSLocalizedString("Service disabled", comment: "服务未启动"))
                    }
                }
            }

            HStack {
                Picker(NSLocalizedString("Server URL:", comment: "服务链接"), selection: $userDefaultsManager.userSettings.serviceScheme) {
                    Text(ServiceScheme.ws + "://").tag(ServiceScheme.ws)
                    Text(ServiceScheme.wss + "://").tag(ServiceScheme.wss)
                }.frame(width: 140, alignment: .leading)

                TextField(NSLocalizedString("Please enter server URL", comment: "请输入链接"), text: $userDefaultsManager.userSettings.serviceURL)
            }.disabled(serverConnected)

            // TODO: Future Version
            /*
             HStack {
                 Text(NSLocalizedString("Service Token:", comment: "服务Token："))

                 TextField(NSLocalizedString("Please enter server token:", comment: "请输入Token"), text: $userDefaultsManager.userSettings.serviceToken)
             }
             .disabled(serverConnected)
             */

            Button(action: {
                if serverConnected {
                    userDefaultsManager.userSettings.serviceOn = false
                    webSocketManager.disconnect()
                } else {
                    userDefaultsManager.userSettings.serviceOn = true
                    webSocketManager.connect()
                }
            }) {
                Text(userDefaultsManager.userSettings.serviceOn ? NSLocalizedString("Disable service", comment: "停用服务") : NSLocalizedString("Enable service", comment: "启动服务"))
                    .frame(minWidth: 100)
            }

            Divider()

            HStack {
                Picker(NSLocalizedString("Upload URL:", comment: "上传链接"), selection: $userDefaultsManager.userSettings.uploadScheme) {
                    Text(UploadScheme.http + "://").tag(UploadScheme.http)
                    Text(UploadScheme.https + "://").tag(UploadScheme.https)
                }.frame(width: 147, alignment: .leading)

                TextField(NSLocalizedString("Please enter upload URL", comment: "请输入链接"), text: $userDefaultsManager.userSettings.uploadURL)
            }
            .disabled(userDefaultsManager.userSettings.uploadTestPassed)

            Toggle(isOn: $userDefaultsManager.userSettings.deleteAfterUpload) {
                Text(NSLocalizedString("Delete local screenshots after successful upload", comment: "上传成功后删除本地截图"))
            }

            Button(action: {
                userDefaultsManager.userSettings.uploadOn.toggle()
                if !userDefaultsManager.userSettings.serviceOn {
                    return
                }

                if userDefaultsManager.userSettings.uploadTestPassed {
                    userDefaultsManager.userSettings.uploadTestPassed.toggle()
                } else {
                    // Test URL
                    webSocketManager.screenCaptureService.checkUploadEligibility { isEligible in
                        userDefaultsManager.userSettings.uploadTestPassed = isEligible
                    }
                }

            }) {
                Text(userDefaultsManager.userSettings.uploadOn ? NSLocalizedString("Disable upload", comment: "停用上传") : NSLocalizedString("Enable upload", comment: "启动上传")).frame(minWidth: 100)
            }

            HStack {
                if !userDefaultsManager.userSettings.uploadOn {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 10, height: 10)
                    Text(NSLocalizedString("Upload not enabled", comment: "上传未启用"))
                } else {
                    Circle()
                        .fill(userDefaultsManager.userSettings.uploadTestPassed ? Color.green : Color.yellow)
                        .frame(width: 10, height: 10)
                    Text(userDefaultsManager.userSettings.uploadTestPassed ? NSLocalizedString("Upload enabled", comment: "上传已启用") : NSLocalizedString("Upload not enabled", comment: "上传未启用"))
                }

                HStack(spacing: 0, content: {
                    Text(NSLocalizedString("Device id:", comment: "设备标识：")).foregroundStyle(Color.gray)

                    Text("\(getMacUUIDHashPrefixN() ?? NSLocalizedString("Unkonwn", comment: "未知"))").foregroundStyle(Color.gray).textSelection(.enabled)
                })
            }

            Divider()

            HStack(spacing: 4) {
                Text(NSLocalizedString("Screenshots directory:", comment: "截图目录"))
                DirTextView(text: $userDefaultsManager.userSettings.screenshotDir)
                Spacer()
                Button(action: {
                    chooseDirectory(message: NSLocalizedString("Select a directory to save the screenshots", comment: "选择一个目录来保存截图")) { selected, selectedDirectory in
                        guard selected, let directory = selectedDirectory else {
                            // 用户取消了选择或未选择目录
                            return
                        }
                        userDefaultsManager.userSettings.screenshotDir = directory.path
                    }
                }) {
                    Text(NSLocalizedString("Select", comment: "选择"))
                        .frame(minWidth: 40)
                }
            }

            HStack(spacing: 4) {
                Text(NSLocalizedString("Log directory:", comment: "日志目录"))
                DirTextView(text: $userDefaultsManager.userSettings.logDir)
                Spacer()
                Button(action: {
                    NSLog("选择日志目录 Button tapped \(NSHomeDirectory())")
                    chooseDirectory(message: NSLocalizedString("Select a directory to save the logs", comment: "选择一个目录来保存日志")) { selected, selectedDirectory in
                        guard selected, let directory = selectedDirectory else {
                            // 用户取消了选择或未选择目录
                            return
                        }
                        userDefaultsManager.userSettings.logDir = directory.path
                    }

                }) {
                    Text(NSLocalizedString("Select", comment: "选择"))
                        .frame(minWidth: 40)
                }
            }

            Divider()

            Toggle(isOn: $userDefaultsManager.userSettings.launchWhenLogin) {
                Text(NSLocalizedString("Startup when login", comment: "登录时启动"))
            }

            Button(action: {
                if serverConnected {
                    userDefaultsManager.userSettings.serviceOn = false
                    webSocketManager.disconnect()
                }
                userDefaultsManager.resetSettings()
            }) {
                Text(NSLocalizedString("Reset settings", comment: "重置设置"))
                    .frame(minWidth: 70)
            }

            Spacer()
        }.padding().frame(width: width, height: height)
    }
}

struct SettingsAboutView: View {
    let width: CGFloat = 400
    let height: CGFloat = 400

    var body: some View {
        VStack {
            Text(NSLocalizedString("About", comment: "关于"))
        }
        .padding()
        .frame(width: width, height: height)
    }
}

struct DirTextView: View {
    @Binding var text: String

    var body: some View {
        Text(text)
            .font(.system(size: 11))
            .lineLimit(1)
            .truncationMode(.middle)
    }
}

#Preview {
    struct Preview: View {
        @State var serverConnected: Bool = false
        var body: some View {
            SettingsView(serverConnected: $serverConnected).environmentObject(UserDefaultsManager()).environmentObject(WebSocketManager(isConnected: serverConnected))
        }
    }

    return Preview()
}
