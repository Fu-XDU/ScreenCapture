//
//  ScreenCaptureService.swift
//  ScreenCapture
//
//  Created by 付铭 on 2024/8/25.
//

import Foundation

class ScreenCaptureService {
    var screenshotTimer: Timer?
    @Published var userDefaultsManager: UserDefaultsManager = UserDefaultsManager()
    @Published var uploadTicket: String = ""

    func startScreenCapture() {
        screenshotTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(captureScreenshot), userInfo: nil, repeats: true)
        RunLoop.current.add(screenshotTimer!, forMode: .common)
    }

    func stopScreenCapture() {
        screenshotTimer?.invalidate()
        screenshotTimer = nil
    }

    @objc func captureScreenshot() {
        let userSettings = userDefaultsManager.userSettings

        guard createDirectoryIfNotExists(path: userSettings.screenshotDir) else {
            NSLog("无法创建截图目录")
            return
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd-HHmmssSS"
        let dateString = dateFormatter.string(from: Date())
        let fileName = "screenshot-\(dateString).png"

        let fileURL = "\(userSettings.screenshotDir)/\(fileName)"

        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
        task.arguments = ["-S", "-x", fileURL]

        do {
            try task.run()
            task.waitUntilExit()
            NSLog("截图已保存：\(fileURL)")
            if userSettings.uploadOn && userSettings.uploadTestPassed {
                uploadScreenshot(filePath: fileURL) { success in
                    if success && userSettings.deleteAfterUpload {
                        _ = deleteFile(atPath: fileURL)
                    }
                }
            }
        } catch {
            NSLog("截图失败：\(error)")
        }
    }

    @objc func uploadScreenshot(filePath: String, completion: @escaping (Bool) -> Void) {
        let userSettings = userDefaultsManager.userSettings

        guard let fileURL = URL(string: "file://" + filePath) else {
            completion(false)
            return
        }

        do {
            let imageData = try Data(contentsOf: fileURL)

            var request = URLRequest(url: URL(string: userSettings.uploadScheme + "://" + userSettings.uploadURL + "?ticket=" + uploadTicket + "&uuid=" + getMacUUIDHashPrefixN()!)!)
            request.httpMethod = "POST"
            request.setValue("multipart/form-data; boundary=XXXXXX", forHTTPHeaderField: "Content-Type")

            let boundary = "XXXXXX"
            let body = NSMutableData()

            let filename = fileURL.lastPathComponent
            let mimetype = "image/png"

            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"files\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: \(mimetype)\r\n\r\n".data(using: .utf8)!)
            body.append(imageData)
            body.append("\r\n".data(using: .utf8)!)

            body.append("--\(boundary)--\r\n".data(using: .utf8)!)

            request.httpBody = body as Data

            let task = URLSession.shared.dataTask(with: request) { _, response, error in
                if let error = error {
                    NSLog("上传失败：\(error)")
                    completion(false)
                    return
                }

                if let response = response as? HTTPURLResponse {
                    if response.statusCode == 200 {
                        NSLog("上传成功")
                        completion(true)
                        return
                    } else {
                        NSLog("上传失败，状态码：\(response.statusCode)")
                        completion(false)
                        return
                    }
                }
            }
            task.resume()
        } catch {
            NSLog("读取截图文件失败：\(error)")
            completion(false)
            return
        }
    }

    @objc func checkUploadEligibility(completion: @escaping (Bool) -> Void) {
        if uploadTicket.isEmpty {
            NSLog("未连接服务器")
            DispatchQueue.main.async {
                completion(false)
            }
            return
        }

        let userSettings = userDefaultsManager.userSettings

        let urlString = userSettings.uploadScheme + "://" + userSettings.uploadURL + "?ticket=" + uploadTicket + "&uuid=" + getMacUUIDHashPrefixN()!
        guard let url = URL(string: urlString) else { completion(false); return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        let task = URLSession.shared.dataTask(with: request) { _, response, error in
            if let error = error {
                NSLog("请求失败：\(error)")
                DispatchQueue.main.async {
                    completion(false)
                }
                return
            }

            if let response = response as? HTTPURLResponse {
                if response.statusCode == 200 {
                    NSLog("拥有上传权限")
                    DispatchQueue.main.async {
                        completion(true)
                    }
                } else {
                    if response.statusCode == 401 {
                        NSLog("无上传权限")
                    } else {
                        NSLog("请求失败，状态码：\(response.statusCode)")
                    }
                    DispatchQueue.main.async {
                        completion(false)
                    }
                }
            }
        }

        task.resume()
    }
}
