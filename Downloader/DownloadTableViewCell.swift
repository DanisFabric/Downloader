//
//  DownloadTableViewCell.swift
//  Downloader
//
//  Created by 黄明 on 2017/3/8.
//  Copyright © 2017年 Danis. All rights reserved.
//

import UIKit

class DownloadTableViewCell: UITableViewCell {
    
    let progressView: UIProgressView = {
        let progress = UIProgressView(progressViewStyle: .default)
        progress.progressTintColor = UIColor.red
        progress.trackTintColor = UIColor.clear
        
        return progress
    }()

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        selectionStyle = .none
        
        contentView.addSubview(progressView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        
        progressView.frame = CGRect(x: 0, y: 0, width: bounds.width, height: 6)
    }

}
