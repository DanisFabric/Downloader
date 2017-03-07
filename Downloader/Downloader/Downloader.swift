//
//  Downloader.swift
//  Downloader
//
//  Created by 黄明 on 2017/3/7.
//  Copyright © 2017年 Danis. All rights reserved.
//

import Foundation

class Downloader: NSObject {
    var eventPool = [DownloadEvent]()
    
    
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
        
    }
    func suspendAll() {
        
    }
    func awakeAll() {
        
    }
    fileprivate func resumeNext() {
        
    }
}

extension Downloader {
    func event(of url: URL) -> DownloadEvent? {
        for event in eventPool {
            if event.sourceUrl == url {
                return event
            }
        }
        return nil
    }
}
