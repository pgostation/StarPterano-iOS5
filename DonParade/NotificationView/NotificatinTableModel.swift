//
//  NotificatinTableModel.swift
//  DonParade
//
//  Created by takayoshi on 2018/09/23.
//  Copyright © 2018年 pgostation. All rights reserved.
//

// 通知画面に表示する内容

import UIKit

final class NotificatinTableModel: NSObject, UITableViewDataSource, UITableViewDelegate {
    private var list: [AnalyzeJson.NotificationData] = []
    
    override init() {
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func change(addList: [AnalyzeJson.NotificationData]) {
        if list.count == 0 {
            list = addList
        } else {
            list += addList
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return UITableViewCell.init(style: UITableViewCellStyle.default, reuseIdentifier: nil)
    }
}
