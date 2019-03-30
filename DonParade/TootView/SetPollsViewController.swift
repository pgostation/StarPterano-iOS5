//
//  SetPollsViewController.swift
//  DonParade
//
//  Created by takayoshi on 2019/03/11.
//  Copyright © 2019 pgostation. All rights reserved.
//

// 投票を作成して投稿する

import UIKit

final class SetPollsViewController: MyViewController, UITextFieldDelegate, UIScrollViewDelegate {
    static func show() {
        let vc = SetPollsViewController()
        vc.modalPresentationStyle = .overCurrentContext
        UIUtils.getFrontViewController()?.present(vc, animated: false, completion: nil)
    }
    
    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    deinit {
        SetPollsView.expiresButton.removeTarget(self, action: #selector(expiresAction), for: .touchUpInside)
        SetPollsView.setButton.removeTarget(self, action: #selector(setAction), for: .touchUpInside)
        SetPollsView.cancelButton.removeTarget(self, action: #selector(cancelAction), for: .touchUpInside)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        let view = SetPollsView()
        self.view = view
        
        SetPollsView.expiresButton.addTarget(self, action: #selector(expiresAction), for: .touchUpInside)
        SetPollsView.setButton.addTarget(self, action: #selector(setAction), for: .touchUpInside)
        SetPollsView.cancelButton.addTarget(self, action: #selector(cancelAction), for: .touchUpInside)
        
        view.emojiButton.addTarget(self, action: #selector(emojiAction), for: .touchUpInside)
        
        for poll in SetPollsView.pollArray {
            poll.delegate = self
        }
        
        view.scrollView.delegate = self
    }
    
    @objc func expiresAction() {
        guard let view = self.view as? SetPollsView else { return }
        
        let rootVC = UIUtils.getFrontViewController()
        
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: UIAlertController.Style.actionSheet)
        
        // 7日
        alertController.addAction(UIAlertAction(
            title: String(format: I18n.get("DATETIME_%D_DAYS_AGO"), 7),
            style: UIAlertAction.Style.default) { _ in
                SetPollsView.expiresTime = 7 * 24 * 60
                view.refresh()
        })
        
        // 3日
        alertController.addAction(UIAlertAction(
            title: String(format: I18n.get("DATETIME_%D_DAYS_AGO"), 3),
            style: UIAlertAction.Style.default) { _ in
                SetPollsView.expiresTime = 3 * 24 * 60
                view.refresh()
        })
        
        // 1日
        alertController.addAction(UIAlertAction(
            title: String(format: I18n.get("DATETIME_%D_DAYS_AGO"), 1),
            style: UIAlertAction.Style.default) { _ in
                SetPollsView.expiresTime = 24 * 60
                view.refresh()
        })
        
        // 6時間
        alertController.addAction(UIAlertAction(
            title: String(format: I18n.get("DATETIME_%D_HOURS_AGO"), 6),
            style: UIAlertAction.Style.default) { _ in
                SetPollsView.expiresTime = 6 * 60
                view.refresh()
        })
        
        // 1時間
        alertController.addAction(UIAlertAction(
            title: String(format: I18n.get("DATETIME_%D_HOURS_AGO"), 1),
            style: UIAlertAction.Style.default) { _ in
                SetPollsView.expiresTime = 1 * 60
                view.refresh()
        })
        
        // 30分
        alertController.addAction(UIAlertAction(
            title: String(format: I18n.get("DATETIME_%D_MINS_AGO"), 30),
            style: UIAlertAction.Style.default) { _ in
                SetPollsView.expiresTime = 30
                view.refresh()
        })
        
        // 5分
        alertController.addAction(UIAlertAction(
            title: String(format: I18n.get("DATETIME_%D_MINS_AGO"), 5),
            style: UIAlertAction.Style.default) { _ in
                SetPollsView.expiresTime = 5
                view.refresh()
                
        })
        
        // キャンセル
        alertController.addAction(UIAlertAction(
            title: I18n.get("BUTTON_CANCEL"),
            style: UIAlertAction.Style.cancel) { _ in
        })
        
        rootVC?.present(alertController, animated: true, completion: nil)
    }
    
    // 絵文字ボタンの処理
    @objc func emojiAction() {
        guard let view = self.view as? SetPollsView else { return }
        
        if SetPollsView.pollArray.first?.inputView is EmojiKeyboard {
            // テキストフィールドのカスタムキーボードを解除
            for field in SetPollsView.pollArray {
                field.inputView = nil
            }
            
            view.emojiButton.setTitle("😀", for: .normal)
        } else {
            let emojiView = EmojiKeyboard()
            
            // テキストフィールドのカスタムキーボードを変更
            for field in SetPollsView.pollArray {
                field.inputView = emojiView
            }
            
            view.emojiButton.setTitle("🔠", for: .normal)
        }
        
        var firstResponder: UITextField? = nil
        for field in SetPollsView.pollArray {
            if field.isFirstResponder {
                firstResponder = field
            }
        }
        firstResponder?.resignFirstResponder()
        firstResponder?.becomeFirstResponder()
    }
    
    @objc func setAction() {
        if (SetPollsView.pollArray[0].text ?? "") == "" ||
            (SetPollsView.pollArray[1].text ?? "") == "" {
            Dialog.show(message: I18n.get("ALERT_POLL_TWO_TEXT"))
            
            return
        }
        
        for i in 0..<2 {
            if (SetPollsView.pollArray[i].text ?? "") == "" { continue }
            for j in i+1..<3 {
                if (SetPollsView.pollArray[j].text ?? "") == "" { continue }
                if SetPollsView.pollArray[i].text == SetPollsView.pollArray[j].text {
                    Dialog.show(message: I18n.get("ALERT_SAME_POLL"))
                    
                    return
                }
            }
        }
        
        dismiss(animated: false, completion: nil)
    }
    
    @objc func cancelAction() {
        SetPollsView.clear()
        
        dismiss(animated: false, completion: nil)
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            guard let view = self.view as? SetPollsView else { return }
            view.refresh()
        }
        
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        for textField in SetPollsView.pollArray {
            textField.tag = 0
        }
        
        textField.tag = UIUtils.responderTag
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.view.setNeedsLayout()
    }
}

final class SetPollsView: UIView {
    let scrollView = UIScrollView()
    private let mainView = UIView()
    private let multipleLabel = UILabel()
    private let hideTotalsLabel = UILabel()
    static let pollArray = [UITextField(), UITextField(), UITextField(), UITextField()]
    static let multipleSwitch = UISwitch()
    static let hideTotalsSwitch = UISwitch()
    static let expiresButton = UIButton()
    static let setButton = UIButton()
    static let cancelButton = UIButton()
    
    static var expiresTime: Int = 60 // デフォルト60分
    
    // 入力バー
    let inputBar = UIView()
    let emojiButton = UIButton()
    private var keyBoardHeight: CGFloat = 0
    
    init() {
        super.init(frame: UIScreen.main.bounds)
        
        self.addSubview(scrollView)
        scrollView.addSubview(mainView)
        mainView.addSubview(multipleLabel)
        mainView.addSubview(hideTotalsLabel)
        mainView.addSubview(SetPollsView.expiresButton)
        mainView.addSubview(SetPollsView.multipleSwitch)
        mainView.addSubview(SetPollsView.hideTotalsSwitch)
        mainView.addSubview(SetPollsView.setButton)
        mainView.addSubview(SetPollsView.cancelButton)
        for poll in SetPollsView.pollArray {
            mainView.addSubview(poll)
        }
        mainView.addSubview(inputBar)
        inputBar.addSubview(emojiButton)
        
        setProperties()
        
        refresh()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // プロパティ設定
    private func setProperties() {
        self.backgroundColor = ThemeColor.viewBgColor
        
        SetPollsView.setButton.setTitle(I18n.get("BUTTON_SET"), for: .normal)
        SetPollsView.setButton.backgroundColor = ThemeColor.opaqueButtonsBgColor
        SetPollsView.setButton.clipsToBounds = true
        SetPollsView.setButton.layer.cornerRadius = 8
        
        SetPollsView.cancelButton.setTitle(I18n.get("BUTTON_CANCEL"), for: .normal)
        SetPollsView.cancelButton.backgroundColor = ThemeColor.opaqueButtonsBgColor
        SetPollsView.cancelButton.clipsToBounds = true
        SetPollsView.cancelButton.layer.cornerRadius = 8
        
        SetPollsView.expiresButton.backgroundColor = ThemeColor.opaqueButtonsBgColor
        SetPollsView.expiresButton.clipsToBounds = true
        SetPollsView.expiresButton.layer.cornerRadius = 8
        
        multipleLabel.text = I18n.get("POLLS_MULTIPLE")
        multipleLabel.textColor = ThemeColor.contrastColor
        multipleLabel.sizeToFit()
        
        hideTotalsLabel.text = I18n.get("POLLS_HIDE_TOTAL")
        hideTotalsLabel.textColor = ThemeColor.contrastColor
        hideTotalsLabel.sizeToFit()
        
        for (i, poll) in SetPollsView.pollArray.enumerated() {
            poll.layer.borderColor = ThemeColor.contrastColor.cgColor
            poll.layer.borderWidth = 1 / UIScreen.main.scale
            poll.textColor = ThemeColor.contrastColor
            poll.placeholder = I18n.get("POLL_OPTION") + "\(i + 1)"
        }
        
        inputBar.backgroundColor = ThemeColor.cellBgColor
        
        emojiButton.setTitle("😀", for: .normal)
        
        // キーボードの高さを監視
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.keyboardWillShow(_:)),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.keyboardWillHide(_:)),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }
    
    // 画面更新
    func refresh() {
        // 締め切り時間表示
        let timeStr: String
        if SetPollsView.expiresTime < 60 {
            timeStr = String(format: I18n.get("DATETIME_%D_MINS_AGO"), SetPollsView.expiresTime)
        } else if SetPollsView.expiresTime < 24 * 60 {
            timeStr = String(format: I18n.get("DATETIME_%D_HOURS_AGO"), SetPollsView.expiresTime / 60)
        } else {
            timeStr = String(format: I18n.get("DATETIME_%D_DAYS_AGO"), SetPollsView.expiresTime / 60 / 24)
        }
        SetPollsView.expiresButton.setTitle(I18n.get("EXPIRES_TIME:") + timeStr, for: .normal)
        
        // 投票項目の無効化
        if SetPollsView.pollArray[1].text == nil || SetPollsView.pollArray[1].text == "" {
            SetPollsView.pollArray[2].isEnabled = false
            SetPollsView.pollArray[3].isEnabled = false
        } else if SetPollsView.pollArray[2].text == nil || SetPollsView.pollArray[2].text == "" {
            SetPollsView.pollArray[2].isEnabled = true
            SetPollsView.pollArray[3].isEnabled = false
        } else {
            SetPollsView.pollArray[2].isEnabled = true
            SetPollsView.pollArray[3].isEnabled = true
        }
        
        if SetPollsView.pollArray[2].isEnabled {
            SetPollsView.pollArray[2].backgroundColor = UIColor.clear
        } else {
            SetPollsView.pollArray[2].backgroundColor = UIColor.gray
        }
        if SetPollsView.pollArray[3].isEnabled {
            SetPollsView.pollArray[3].backgroundColor = UIColor.clear
        } else {
            SetPollsView.pollArray[3].backgroundColor = UIColor.gray
        }
    }
    
    // レイアウト
    override func layoutSubviews() {
        let screenBounds = UIScreen.main.bounds
        
        scrollView.frame = CGRect(x: 0,
                                  y: UIUtils.statusBarHeight(),
                                  width: screenBounds.width,
                                  height: screenBounds.height - UIUtils.statusBarHeight() - keyBoardHeight)
        
        var top: CGFloat = 10
        
        SetPollsView.cancelButton.frame = CGRect(x: 10,
                                                 y: top,
                                                 width: 100,
                                                 height: 40)
        
        SetPollsView.setButton.frame = CGRect(x: screenBounds.width - 110,
                                              y: top,
                                              width: 100,
                                              height: 40)
        
        top += 55
        
        SetPollsView.expiresButton.frame = CGRect(x: 10,
                                                  y: top,
                                                  width: 200,
                                                  height: 40)
        
        top += 55
        
        multipleLabel.frame = CGRect(x: 10,
                                     y: top,
                                     width: multipleLabel.frame.width,
                                     height: 31)
        SetPollsView.multipleSwitch.frame = CGRect(x: multipleLabel.frame.maxX + 10,
                                                   y: top,
                                                   width: 51,
                                                   height: 31)
        
        top += 45
        
        hideTotalsLabel.frame = CGRect(x: 10,
                                       y: top,
                                       width: hideTotalsLabel.frame.width,
                                       height: 31)
        SetPollsView.hideTotalsSwitch.frame = CGRect(x: hideTotalsLabel.frame.maxX + 10,
                                                     y: top,
                                                     width: 51,
                                                     height: 31)
        
        top += 45
        
        for poll in SetPollsView.pollArray {
            poll.frame = CGRect(x: 10,
                                y: top,
                                width: screenBounds.width - 20,
                                height: 40)
            top += 50
        }
        
        if keyBoardHeight > 0 {
            self.inputBar.frame = CGRect(x: 0,
                                         y: screenBounds.height - keyBoardHeight - 40 + scrollView.contentOffset.y - 20,
                                         width: screenBounds.width,
                                         height: 40)
        } else {
            self.inputBar.frame = CGRect(x: 0,
                                         y: screenBounds.height + scrollView.contentOffset.y,
                                         width: screenBounds.width,
                                         height: 40)
        }
        
        self.emojiButton.frame = CGRect(x: screenBounds.width - 50,
                                        y: 0,
                                        width: 40,
                                        height: 40)
        
        mainView.frame = CGRect(x: 0,
                                y: 0,
                                width: screenBounds.width,
                                height: top)
        
        scrollView.contentSize = mainView.frame.size
    }
    
    @objc func keyboardWillShow(_ notification: NSNotification) {
        if let userInfo = notification.userInfo {
            let curve = UIView.KeyframeAnimationOptions(rawValue: UInt(truncating: userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as! NSNumber))
            let duration = TimeInterval(truncating: userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as! NSNumber)
            if let keyboardFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
                self.keyBoardHeight = keyboardFrame.height
                UIView.animateKeyframes(withDuration: duration, delay: 0, options: [curve], animations: {
                    self.layoutSubviews()
                }, completion: nil)
            }
        }
    }
    
    @objc func keyboardWillHide(_ notification: NSNotification) {
        self.keyBoardHeight = 0
        UIView.animate(withDuration: 0.2) { [weak self] in
            self?.layoutSubviews()
        }
    }
    
    static func clear() {
        SetPollsView.expiresTime = 60
        SetPollsView.multipleSwitch.isOn = false
        SetPollsView.hideTotalsSwitch.isOn = false
        for poll in SetPollsView.pollArray {
            poll.text = nil
        }
    }
}
