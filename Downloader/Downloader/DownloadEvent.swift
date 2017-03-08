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

class DownloadEventConfiguration {
    var sourceUrl: URL
    var destinationUrl: URL
    var totalBytesExpectedToWrite: Int
    
    
    init?(dictionary: [AnyHashable: Any]) {
        guard let sourceUrlString = dictionary["sourceUrl"] as? String else {
            return nil
        }
        guard let sourceUrl = URL(string: sourceUrlString) else {
            return nil
        }
        guard let destinationUrlString = dictionary["destinationUrl"] as? String else {
            return nil
        }
        guard let destinationUrl = URL(string: destinationUrlString) else {
            return nil
        }
        guard let totalBytesExpectedToWrite = dictionary["totalBytes"] as? Int else {
            return nil
        }
        
        self.sourceUrl = sourceUrl
        self.destinationUrl = destinationUrl
        self.totalBytesExpectedToWrite = totalBytesExpectedToWrite
    }
}

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
    
    var bytesWritten = 0
    var totalBytesWritten: Int {
        return (try? FileManager.default.attributesOfItem(atPath: sourceUrl.path))?[FileAttributeKey.size] as? Int ?? 0
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
    init(configuration: DownloadEventConfiguration, session: URLSession) {
        sourceUrl = configuration.sourceUrl
        destinationUrl = configuration.destinationUrl
        
        super.init()
        
        totalBytesExpectedToWrite = configuration.totalBytesExpectedToWrite
        
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

extension DownloadEvent: URLSessionDataDelegate {
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        guard let httpResponse = response as? HTTPURLResponse else {
            return
        }
        guard totalBytesExpectedToWrite == 0 else {
            return
        }
        if let bytesText = httpResponse.allHeaderFields["Content-Length"] as? String {
            if let totalRestBytes = Int(bytesText) {
                totalBytesExpectedToWrite = totalRestBytes + totalBytesWritten
            }
        }
        outputStream.open()
        error = nil
    }
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
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
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        outputStream.close()
        bytesWritten = 0
        if let error = error {
            self.error = error
            
            status = .none
            completionHandler?(Result.failure(error))
        } else {
            status = .completed
            completionHandler?(Result.success(sourceUrl))
        }
        NotificationCenter.default.post(name: kNotificationResumeNext, object: nil)
    }
}
