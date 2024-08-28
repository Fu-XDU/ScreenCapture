//
//  AppDelegate.swift
//  ScreenCapture
//
//  Created by 付铭 on 2024/8/22.
//

import AppKit
import Foundation
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        NSLog(getMacUUIDHashPrefixN() ?? "")
    }
}
