//

//  Downloader.swift
//  Downloader
//
//  Created by 黄明 on 2017/3/7.
//  Copyright © 2017年 Danis. All rights reserved.
//

import Foundation

class Downloader: NSObject {
    fileprivate var eventPool = [DownloadEvent]()
    
    var maxConcurrentCount = 3
    
    lazy var session: URLSession = {
        let configuration = URLSessionConfiguration.default
        let session = URLSession(configuration: configuration, delegate: self, delegateQueue: OperationQueue())
        
        return session
    }()
    
    var defaultDirectory: URL = {
        let directory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        return URL(fileURLWithPath: directory)
    }()
    
    static let shared = Downloader()
    
    fileprivate let database = EventDatabase()
    
    var dispatchTimer: Timer!
    
    fileprivate override init() {
        super.init()
        
        func recovery() {
            let datas = database.dataPool
            for data in datas {
                data.destination = defaultDirectory.appendingPathComponent(data.destination.lastPathComponent)      // iOS8之后苹果会改变沙盒地址改变
                let event = DownloadEvent(data: data, session: session)
                event.preparedHandler = { [weak self] in
                    self?.database.update(data: event.data)
                }
                event.statusChangedHandler = { [weak self] in
                    self?.database.update(data: event.data)
                }
                
                eventPool.append(event)
            }
            let recoveryEvents = eventPool.filter { (event) -> Bool in
                return event.isRecoveryImmediately
            }
            recoveryEvents.forEach { (event) in
                event.isRecoveryImmediately = false
                event.resume()
            }
        }
        recovery()
        
        dispatchTimer = Timer(timeInterval: 1, target: self, selector: #selector(onTimerToDispatchEvent), userInfo: nil, repeats: true)
        RunLoop.current.add(dispatchTimer, forMode: .commonModes)
    }
    deinit {
        dispatchTimer.invalidate()
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
        event.preparedHandler = { [weak self] in
            self?.database.update(data: event.data)
        }
        event.statusChangedHandler = { [weak self] in
            self?.database.update(data: event.data)
        }
        event.awake()
        
        eventPool.append(event)
        
        database.add(data: event.data)
        
        return true
    }
    func download(from source: URL, progress: ProgressHandler?, completion: CompletionHandler?) -> Bool {
        let fileName = source.lastPathComponent
        let destination = defaultDirectory.appendingPathComponent(fileName)
        
        return download(from: source, to: destination, progress: progress, completion: completion)
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
            event.cancel()
        }
    }
    func suspendAll() {
        eventPool.forEach { (event) in
            event.suspend()
        }
    }
    func awakeAll() {
        eventPool.forEach { (event) in
            event.awake()
        }
    }
    fileprivate func resumeNext() {
        let next = eventPool.filter { (event) -> Bool in
            return event.status == .waiting
        }.first
        next?.resume()
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

extension Downloader: URLSessionDelegate, URLSessionDataDelegate {
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        let current = event(of: URL(string: dataTask.taskDescription!)!)
        current?.didReceiveResponse(response as! HTTPURLResponse)
        
        completionHandler(.allow)
    }
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        let current = event(of: URL(string: dataTask.taskDescription!)!)
        current?.didReceiveData(data)
    }
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        let current = event(of: URL(string: task.taskDescription!)!)
        current?.didCompleteWithError(error)
    }
}

extension Downloader {
    @objc fileprivate func onTimerToDispatchEvent() {
        let downloadingCount = eventPool.filter { (event) -> Bool in
            return event.status == .downloading
        }.count
        for _ in 0..<max(0, maxConcurrentCount - downloadingCount) {
            resumeNext()
        }
    }
}
