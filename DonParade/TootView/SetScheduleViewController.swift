//
//  SetScheduleViewController.swift
//  DonParade
//
//  Created by takayoshi on 2019/01/26.
//  Copyright © 2019 pgostation. All rights reserved.
//

// 予約投稿の時間設定画面

import UIKit

final class SetScheduleViewController: MyViewController {
    static func show() {
        let vc = SetScheduleViewController()
        vc.modalPresentationStyle = .overCurrentContext
        UIUtils.getFrontViewController()?.present(vc, animated: false, completion: nil)
    }
    
    private init() {
        super.init(nibName: nil, bundle: nil)
        
        let view = SetScheduleView()
        self.view = view
        
        view.datePicker.addTarget(self, action: #selector(setDate), for: .valueChanged)
        view.closeButton.addTarget(self, action: #selector(closeAction), for: .touchUpInside)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func closeAction() {
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc func setDate() {
        guard let view = self.view as? SetScheduleView else { return }
        
        TootView.scheduledDate = view.datePicker.date
        
        if let tootView = TootViewController.instance?.view as? TootView {
            tootView.tootButton.setTitle(I18n.get("BUTTON_SCHEDULED_TOOT"), for: .normal)
        }
    }
}

private class SetScheduleView: UIView {
    private let backView = UIView()
    let datePicker = UIDatePicker()
    let closeButton = UIButton()
    
    init() {
        super.init(frame: UIScreen.main.bounds)
        
        self.addSubview(backView)
        self.addSubview(datePicker)
        self.addSubview(closeButton)
        
        setProperties()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setProperties() {
        backView.backgroundColor = UIColor.gray.withAlphaComponent(0.5)
        
        datePicker.backgroundColor = UIColor.white.withAlphaComponent(0.9)
        datePicker.date = TootView.scheduledDate ?? (Date() + 60)
        datePicker.datePickerMode = .dateAndTime
        datePicker.minimumDate = Date() + 60
        
        closeButton.setTitle(I18n.get("BUTTON_CLOSE"), for: .normal)
        closeButton.backgroundColor = UIColor.white
        closeButton.setTitleColor(UIColor.blue, for: .normal)
        closeButton.layer.cornerRadius = 8
        closeButton.clipsToBounds = true
    }
    
    override func layoutSubviews() {
        let screenBounds = UIScreen.main.bounds
        
        backView.frame = screenBounds
        
        datePicker.frame = CGRect(x: 0,
                                  y: screenBounds.height / 2 - 216 / 2,
                                  width: screenBounds.width,
                                  height: 216)
        
        closeButton.frame = CGRect(x: screenBounds.width / 2 - 200 / 2,
                                   y: datePicker.frame.maxY + 20,
                                   width: 200,
                                   height: 44)
    }
}
