//
//  DownloadResult.swift
//  Downloader
//
//  Created by 黄明 on 2017/3/7.
//  Copyright © 2017年 Danis. All rights reserved.
//

import Foundation

enum Result {
    case success(URL)
    case failure(Error)
    
    var isSuccess: Bool {
        switch self {
        case .success:
            return true
        default:
            return false
        }
    }
    var isFailure: Bool {
        return !isSuccess
    }
}


extension Progress {
    var completedPercent: Double {
        return Double(completedUnitCount) / Double(totalUnitCount)
    }
}
