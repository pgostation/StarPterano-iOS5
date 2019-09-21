//
//  ViewController.swift
//  DonParade
//
//  Created by takayoshi on 2018/09/15.
//  Copyright © 2018年 pgostation. All rights reserved.
//

// 起動時最初にこの画面が表示される（しかし、一瞬でログイン画面かメイン画面に移動する）

import UIKit

final class ViewController: MyViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        DispatchQueue.main.async {
            if SettingsData.accessToken == nil {
                // 初回起動時はログイン画面を表示
                let loginViewController = LoginViewController()
                loginViewController.modalPresentationStyle = .fullScreen
                self.present(loginViewController, animated: false, completion: nil)
            } else {
                // アカウント登録済みなので、メイン画面へ移動
                let mainViewController = MainViewController()
                mainViewController.modalPresentationStyle = .fullScreen
                self.present(mainViewController, animated: false, completion: nil)
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

