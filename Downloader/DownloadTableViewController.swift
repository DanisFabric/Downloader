//
//  DownloadTableViewController.swift
//  Downloader
//
//  Created by 黄明 on 2017/3/8.
//  Copyright © 2017年 Danis. All rights reserved.
//

import UIKit

class DownloadTableViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        let destinationFolder = NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true).first!
        
        for index in 0..<10 {
            let sourceString = String(format: "http://120.25.226.186:32812/resources/videos/minion_%02d.mp4", index)
            let url = URL(string: sourceString)!
            
            let dest = destinationFolder + "/video\(index).mp4"
            let destUrl = URL(fileURLWithPath: dest)
         
            let _ = Downloader.shared.download(from: url, to: destUrl, progress: nil, completion: nil)
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Downloader.shared.numberOfEvents()
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: "DownloadCell")
        if cell == nil {
            cell = UITableViewCell(style: .value1, reuseIdentifier: "DownloadCell")
        }
        cell?.textLabel?.text = "\(indexPath.row)"
        let event = Downloader.shared.event(at: indexPath.row)
        event.progressHandler = { progress in
            cell?.detailTextLabel?.text = "\(Double(progress.completedUnitCount) / Double(progress.totalUnitCount))"
        }
        event.completionHandler = { (result) in
            switch result {
            case .success(let url):
                cell?.detailTextLabel?.text = "下载成功"
            default:
                cell?.detailTextLabel?.text = "下载失败"
            }
        }
        return cell!
    }
}
