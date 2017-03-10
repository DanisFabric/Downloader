//
//  DownloadEvent.swift
//  Downloader
//
//  Created by 黄明 on 2017/3/7.
//  Copyright © 2017年 Danis. All rights reserved.
//

import Foundation

enum DownloadStatus {
    case none
    case waiting
    case downloading
    case suspended
    case completed
}


typealias CompletionHandler = ((Result) -> Void)
typealias ProgressHandler = ((Progress) -> Void)
typealias EventConfigurationPreparedHandler = ((DownloadEventConfiguration) -> Void)

class DownloadEvent: NSObject {
    fileprivate(set) var status = DownloadStatus.none {
        didSet {
            switch status {
            case .none where oldValue == .downloading:
                task.cancel()
            case .waiting:
                break
            case .downloading where oldValue == .waiting:
                task.resume()
            case .completed where oldValue == .downloading:
                break
            case .suspended where oldValue == .downloading:
                task.suspend()
            default:
                break
            }
        }
    }
    
    let sourceUrl: URL
    let destinationUrl: URL
    
    var completionHandler: CompletionHandler?
    var progressHandler: ProgressHandler?
    var preparedHandler: EventConfigurationPreparedHandler?
    
    var bytesWritten = 0
    var totalBytesWritten: Int {
        return (try? FileManager.default.attributesOfItem(atPath: destinationUrl.path))?[FileAttributeKey.size] as? Int ?? 0
    }
    var totalBytesExpectedToWrite = 0
    
    var task: URLSessionDataTask!
    var outputStream: OutputStream!
    
    var error: Error?
    
    init(from source: URL, to destination: URL, session: URLSession) {
        sourceUrl = source
        destinationUrl = destination
        
        super.init()
        
        outputStream = OutputStream(url: destinationUrl, append: true)
        setupTask(with: session)
    }
    private func setupTask(with session: URLSession) {
        var request = URLRequest(url: sourceUrl)
        request.setValue("bytes=\(totalBytesWritten)-", forHTTPHeaderField: "Range")
        
        task = session.dataTask(with: request)
        task.taskDescription = sourceUrl.absoluteString
    }
}

extension DownloadEvent {
    public static func ==(lhs: DownloadEvent, rhs: DownloadEvent) -> Bool {
        return lhs.sourceUrl == rhs.sourceUrl
    }
}

extension DownloadEvent {
    func suspend() {
        status = .suspended
        
        NotificationCenter.default.post(name: kNotificationResumeNext, object: nil)
    }
    func cancel() {
        status = .none
    }
    func resume() {
        status = .downloading
    }
    func awake() {
        status = .waiting
    }
}

extension DownloadEvent {
    func didReceiveResponse(_ response: HTTPURLResponse) {
        if totalBytesExpectedToWrite == 0 {
            if let bytesText = response.allHeaderFields["Content-Length"] as? String {
                if let totalRestBytes = Int(bytesText) {
                    totalBytesExpectedToWrite = totalRestBytes + totalBytesWritten
                }
            }
        }
        outputStream.open()
        error = nil
    }
    func didReceiveData(_ data: Data) {
        let bytes = data.withUnsafeBytes { (bytes: UnsafePointer<UInt8>) -> UnsafePointer<UInt8> in
            return bytes
        }
        let result = outputStream.write(bytes, maxLength: data.count)
        if result == -1 {
            error = outputStream.streamError
            cancel()
        } else {
            bytesWritten = data.count
        }
        let progress = Progress(totalUnitCount: Int64(totalBytesExpectedToWrite))
        progress.completedUnitCount = Int64(totalBytesWritten)
        
        progressHandler?(progress)
    }
    func didCompleteWithError(_ error: Error?) {
        outputStream.close()
        bytesWritten = 0
        if let error = error {
            self.error = error
            
            status = .none
            completionHandler?(Result.failure(error))
            
            print("session error : \(error)")
        } else {
            status = .completed
            completionHandler?(Result.success(sourceUrl))
        }
        NotificationCenter.default.post(name: kNotificationResumeNext, object: nil)
    }
}
