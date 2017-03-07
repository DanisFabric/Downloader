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
    
    var completionHandler: CompletionHandler?
    var progressHandler: ProgressHandler?
    
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

class DownloadEvent {
    var status = DownloadStatus.none {
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
    
    var bytesWritten = 0
    var totalBytesWritten: Int {
        return (try? FileManager.default.attributesOfItem(atPath: sourceUrl.path))?[FileAttributeKey.size] as? Int ?? 0
    }
    var totalBytesExpectedToWrite = 0
    
    var task: URLSessionDataTask!
    var outputStream: OutputStream!
    
    init(from source: URL, to destination: URL, session: URLSession) {
        sourceUrl = source
        destinationUrl = destination
        
        outputStream = OutputStream(url: destinationUrl, append: true)
    }
    init(configuration: DownloadEventConfiguration, session: URLSession) {
        sourceUrl = configuration.sourceUrl
        destinationUrl = configuration.destinationUrl
        
        totalBytesExpectedToWrite = configuration.totalBytesExpectedToWrite
        
        outputStream = OutputStream(url: destinationUrl, append: true)
    }
    private func setupTask(with session: URLSession) {
        var request = URLRequest(url: sourceUrl)
        request.setValue("bytes=\(totalBytesWritten)-", forHTTPHeaderField: "Range")
        
        task = session.dataTask(with: request)
        task.taskDescription = sourceUrl.absoluteString
    }
}

extension DownloadEvent {
    func suspend() {
        status = .suspended
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
        
    }
    func didReceiveData(_ data: Data) {
        
    }
    func didCompleteWithError(_ error: Error?) {
        
    }
}
