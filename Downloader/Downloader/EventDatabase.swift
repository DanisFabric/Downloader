//
//  EventDatabase.swift
//  Downloader
//
//  Created by 黄明 on 2017/3/10.
//  Copyright © 2017年 Danis. All rights reserved.
//

import Foundation

class EventData {
    var source: URL
    var destination: URL
    var status: DownloadStatus = .none
    var totalBytes: Int = 0
    
    init(source: URL, destination: URL, status: DownloadStatus) {
        self.source = source
        self.destination = destination
        self.status = status
    }
    
    init?(dictionary: [String: Any]) {
        guard let source = URL(string: (dictionary["source"] as? String) ?? "") else {
            return nil
        }
        guard let destination = URL(string: (dictionary["destination"] as? String) ?? "") else {
            return nil
        }
        if let status = DownloadStatus(rawValue: (dictionary["statusRaw"] as? Int) ?? 0) {
            self.status = status
        }
        if let totalBytes = dictionary["totalBytes"] as? Int {
            self.totalBytes = totalBytes
        }
        self.source = source
        self.destination = destination
        
    }
    
    var dictionary: [String: Any] {
        return ["source": source.absoluteString, "destination": destination.absoluteString, "statusRaw": status.rawValue, "totalBytes": totalBytes]
    }
}

class EventDatabase {
    var dataPool = [EventData]()
    
    fileprivate let filePath: String = NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true).first!.appending("/events.plist")
    
    init() {
        dataPool = readAll()
    }
}

extension EventDatabase {
    func add(data: EventData) {
        dataPool.append(data)
        
        save()
    }
    func remove(of url: URL) {
        if let index = index(of: url) {
            dataPool.remove(at: index)
            save()
        }
    }
    func update(data: EventData) {
        for current in dataPool {
            if current.source == data.source {
                current.status = data.status
                current.totalBytes = data.totalBytes
                
                save()
                return
            }
        }
    }
    func data(of url: URL) -> EventData? {
        for data in dataPool {
            if data.source == url {
                return data
            }
        }
        return nil
    }
    func index(of url: URL) -> Int? {
        var index = 0
        for current in dataPool {
            if current.source == url {
                return index
            }
            index += 1
        }
        return nil
    }
    func readAll() -> [EventData] {
        var datas = [EventData]()
        if let values = NSArray(contentsOfFile: filePath) {
            for value in values {
                if let dict = value as? [String: Any] {
                    if let data = EventData(dictionary: dict) {
                        datas.append(data)
                    }
                }
            }
        }
        
        return datas
    }
    fileprivate func save() {
        let dicts = NSMutableArray()
        for data in dataPool {
            dicts.add(data.dictionary)
        }
        dicts.write(toFile: filePath, atomically: true)
    }
}
