//
//  EventLoader.swift
//  Downloader
//
//  Created by 黄明 on 2017/3/9.
//  Copyright © 2017年 Danis. All rights reserved.
//

import Foundation

class DownloadEventConfiguration {
    var sourceUrl: URL
    var destinationUrl: URL
    var totalBytesExpectedToWrite: Int
    
    init(from source: URL, destination: URL, totalBytesExpectedToWrite: Int) {
        self.sourceUrl = source
        self.destinationUrl = destination
        self.totalBytesExpectedToWrite = totalBytesExpectedToWrite
    }
    
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
    
    fileprivate func toDictionary() -> [String: Any]{
        return ["sourceUrl": sourceUrl.absoluteString, "destinationUrl": destinationUrl.absoluteString, "totalBytes": totalBytesExpectedToWrite]
    }
}

class EventLoader {
    fileprivate(set) var configurations = [DownloadEventConfiguration]()
    
    fileprivate let filePath = NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true).first!.appending("/events.plist")
    
    init() {
        read()
    }
}

extension EventLoader {
    func addEvent(configuration: DownloadEventConfiguration) {
        configurations.append(configuration)
        
        save()
    }
    func removeEvent(of url: URL) {
        var index = 0
        for config in configurations {
            if config.sourceUrl == url {
                configurations.remove(at: index)
                
                save()
                break
            }
            index += 1
        }
    }
    func updateEvent(configuration: DownloadEventConfiguration) {
        var index = 0
        for config in configurations {
            if config.sourceUrl == configuration.sourceUrl {
                config.totalBytesExpectedToWrite = configuration.totalBytesExpectedToWrite
                
                save()
                break
            }
            index += 1
        }
    }
    fileprivate func save() {
        let array = NSMutableArray()
        for config in configurations {
            array.add(config.toDictionary())
        }
        print(array)
        array.write(toFile: filePath, atomically: true)
    }
    fileprivate func read() {
        var configurations = [DownloadEventConfiguration]()
        if let dicts = NSArray(contentsOfFile: filePath) {
            for dict in dicts {
                if let value = dict as? [String: Any] {
                    if let config = DownloadEventConfiguration(dictionary: value) {
                        configurations.append(config)
                    }
                }
            }
        }
        self.configurations = configurations
    }
}


