//
//  utils.swift
//  ScreenCapture
//
//  Created by 付铭 on 2024/8/25.
//

import CryptoKit
import Foundation
import SwiftUI

func chooseDirectory(message: String, completion: @escaping (Bool, URL?) -> Void) {
    let openPanel = NSOpenPanel()
    openPanel.message = message // 使用传入的消息
    openPanel.prompt = NSLocalizedString("Select", comment: "选择")
    openPanel.canChooseFiles = false
    openPanel.canChooseDirectories = true
    openPanel.allowsMultipleSelection = false

    openPanel.begin { response in
        if response == .OK, let selectedDirectory = openPanel.url {
            completion(true, selectedDirectory)
        } else {
            completion(false, nil)
        }
    }
}

func createDirectoryIfNotExists(path: String) -> Bool {
    let fileManager = FileManager.default
    let directoryURL = URL(fileURLWithPath: path, isDirectory: true)

    if !fileManager.fileExists(atPath: directoryURL.path) {
        do {
            try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true, attributes: nil)
            NSLog("目录创建成功：\(directoryURL.path)")
        } catch {
            NSLog("创建目录失败：\(error.localizedDescription)")
            return false
        }
    } else {
        // NSLog("目录已存在：\(directoryURL.path)")
    }
    return true
}

func hasWritePermission(for directory: String) -> Bool {
    return FileManager.default.isWritableFile(atPath: directory)
}

func getMacUUID() -> String? {
    let platformExpert = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("IOPlatformExpertDevice"))

    guard platformExpert != 0 else { return nil }

    let cfUUID = IORegistryEntryCreateCFProperty(platformExpert, kIOPlatformUUIDKey as CFString, kCFAllocatorDefault, 0)

    IOObjectRelease(platformExpert)

    if let uuid = cfUUID?.takeUnretainedValue() as? String {
        return uuid
    }

    return nil
}

func getMacUUIDHash() -> String? {
    if let uuid = getMacUUID() {
        let uuidData = Data(uuid.utf8)
        let hash = SHA256.hash(data: uuidData)

        return hash.map { String(format: "%02x", $0) }.joined()
    }

    return nil
}

func getMacUUIDHashPrefixN(_ N: Int = 8) -> String? {
    if let uuidHash = getMacUUIDHash() {
        return String(uuidHash.prefix(N))
    }
    return nil
}

func deleteFile(atPath path: String) -> Bool {
    let fileManager = FileManager.default
    do {
        try fileManager.removeItem(atPath: path)
        NSLog("文件删除成功, filepath: \(path)")
        return true
    } catch {
        NSLog("删除文件失败, filepath: \(path), error: \(error)")
        return false
    }
}

func dialogOKCancel(question: String, text: String) -> Bool {
    let alert = NSAlert()
    alert.messageText = question
    alert.informativeText = text
    alert.alertStyle = .warning
    alert.addButton(withTitle: NSLocalizedString("OK", comment: "OK"))
    alert.addButton(withTitle: NSLocalizedString("Cancel", comment: "取消"))
    return alert.runModal() == .alertFirstButtonReturn
}
