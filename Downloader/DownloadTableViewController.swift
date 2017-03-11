//
//  DownloadTableViewController.swift
//  Downloader
//
//  Created by 黄明 on 2017/3/8.
//  Copyright © 2017年 Danis. All rights reserved.
//

import UIKit

class DownloadTableViewController: UITableViewController {
    
    // 暂停全部，继续全部，取消全部，添加
    //

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.register(DownloadTableViewCell.self, forCellReuseIdentifier: "DownloadCell")
        
        for index in 0..<10 {
            let sourceString = String(format: "http://120.25.226.186:32812/resources/videos/minion_%02d.mp4", index)
            let url = URL(string: sourceString)!
            _ = Downloader.shared.download(from: url, progress: nil, completion: nil)
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
        var cell = tableView.dequeueReusableCell(withIdentifier: "DownloadCell") as! DownloadTableViewCell
        let event = Downloader.shared.event(at: indexPath.row)
        cell.textLabel?.text = event.sourceUrl.lastPathComponent
        
        if event.totalBytesExpectedToWrite != 0 {
            cell.progressView.progress = Float(event.totalBytesWritten) / Float(event.totalBytesExpectedToWrite)
        }
        
        event.progressHandler = { progress in
            DispatchQueue.main.async {
                cell.progressView.progress = Float(progress.completedPercent)
            }
            
            print(progress.completedPercent)
        }
        event.completionHandler = { result in
            switch result {
            case .success:
                cell.detailTextLabel?.text = "下载成功"
            case .failure(let error):
                cell.detailTextLabel?.text = "下载失败"
            }
        }

        return cell
    }
}
