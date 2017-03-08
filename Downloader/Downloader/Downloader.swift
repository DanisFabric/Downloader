//
//  Downloader.swift
//  Downloader
//
//  Created by 黄明 on 2017/3/7.
//  Copyright © 2017年 Danis. All rights reserved.
//

import Foundation

let kNotificationResumeNext = Notification.Name(rawValue: "Downloader.Notification.ResumeNext")

class Downloader: NSObject {
    fileprivate var eventPool = [DownloadEvent]()
    
    var maxConcurrentCount = 3
    
    lazy var session: URLSession = {
        let configuration = URLSessionConfiguration.default
        let session = URLSession(configuration: configuration)
        
        return session
    }()
    
    static let shared = Downloader()
    
    fileprivate override init() {
        super.init()
        
        NotificationCenter.default.addObserver(self, selector: #selector(onNotificationToResumeNext(_:)), name: kNotificationResumeNext, object: nil)
    }
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

extension Downloader {
    func numberOfEvents() -> Int {
        return eventPool.count
    }
    func event(at index: Int) -> DownloadEvent {
        return eventPool[index]
    }
}

extension Downloader {
    func download(from source: URL, to destination: URL, progress: ProgressHandler?, completion: CompletionHandler?) -> Bool {
        guard !hasEvent(of: source) else {
            return false
        }
        let event = DownloadEvent(from: source, to: destination, session: session)
        event.progressHandler = progress
        event.completionHandler = completion
        event.awake()
        
        eventPool.append(event)
        
        NotificationCenter.default.post(name: kNotificationResumeNext, object: nil)
        
        return true
    }
    func remove(of url: URL) {
        cancel(of: url)
        if let event = event(of: url) {
            if let index = eventPool.index(of: event) {
                eventPool.remove(at: index)
            }
        }
    }
}

extension Downloader {
    func cancel(of url: URL) {
        event(of: url)?.cancel()
    }
    func suspend(of url: URL) {
        event(of: url)?.suspend()
    }
    func awake(of url: URL) {
        event(of: url)?.awake()
    }
    func cancelAll() {
        eventPool.forEach { (event) in
            cancel(of: event.sourceUrl)
        }
    }
    func suspendAll() {
        eventPool.forEach { (event) in
            suspend(of: event.sourceUrl)
        }
    }
    func awakeAll() {
        eventPool.forEach { (event) in
            awake(of: event.sourceUrl)
        }
    }
    fileprivate func resumeNext() {
        let next = eventPool.filter { (event) -> Bool in
            return event.status == .waiting
        }.first
        
        next?.resume()
    }
    @objc fileprivate func onNotificationToResumeNext(_ notification: Notification) {
        let downloadingEventCount = eventPool.filter { (event) -> Bool in
            return event.status == .downloading
        }.count
        
        if downloadingEventCount < maxConcurrentCount {
            resumeNext()
        }
    }
}

extension Downloader {
    func hasEvent(of url: URL) -> Bool {
        return event(of: url) != nil
    }
    func event(of url: URL) -> DownloadEvent? {
        for event in eventPool {
            if event.sourceUrl == url {
                return event
            }
        }
        return nil
    }
}
