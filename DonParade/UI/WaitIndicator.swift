//
//  WaitIndicator.swift
//  DonParade
//
//  Created by takayoshi on 2018/09/20.
//  Copyright © 2018年 pgostation. All rights reserved.
//

// 衝突球アニメーション

import UIKit

final class WaitIndicator: UIView {
    var animationTimer: Timer?
    var ballLocsList: [[CGFloat]] = [
        [-2.5,-1,0,1,2],
        [-3,-1,0,1,2],
        [-3.5,-1,0,1,2],
        [-4,-1,0,1,2],
        [-3,-1,0,1,3],
        [-2,-1,0,1,2.5],
        [-2,-1,0,1,3],
        [-2,-1,0,1,3.5],
        [-2,-1,0,1,4],
        [-2.5,-1.5,0,1,2],
        [-3,-2,0,1,2],
        [-3.5,-2.5,0,1,2],
        [-4,-1,0,1,3],
        [-3,-2,0,1,3],
        [-4,-1,0,2,3],
        [-3,-2,0,2,4],
        [-4,-2,0,2,4],
        [-4,-3,-2,1,2],
        [-4,-3,-2,-1,2],
        [-4,-3,-2,-1,0],
        [-4,-3,0,3,4],
        [-4,-2,0,2,4],
        [-3,-2,-1,0,1],
        [-4,-0.5,0.5,1.5,2.5],
        [-4,-1,0,1.5,2.5],
        ]
    var ballLocs: [CGFloat] = [0,0,0,0,0]
    var ballSpeeds: [CGFloat] = [0,0,0,0,0]
    
    init() {
        let screenBounds = UIScreen.main.bounds
        super.init(frame: CGRect(x: screenBounds.width / 2 - 100 / 2,
                                 y: screenBounds.height / 2 - 80 / 2,
                                 width: 100,
                                 height: 80))
        
        self.clipsToBounds = true
        self.layer.cornerRadius = 10
        
        self.animationTimer = Timer.scheduledTimer(timeInterval: 1 / 60, target: self, selector: #selector(refresh), userInfo: nil, repeats: true)
        
        let randIndex = arc4random_uniform(UInt32(ballLocsList.count))
        self.ballLocs = ballLocsList[Int(randIndex)]
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func refresh() {
        self.setNeedsDisplay()
    }
    
    override func draw(_ rect: CGRect) {
        // ボールの位置を移動
        for _ in 0..<5 {
            ballSimulation()
        }
        
        // 背景を描画
        let path = UIBezierPath(rect: rect)
        UIColor.gray.setFill() // 色をセット
        path.fill()
        
        // 位置
        let top = self.frame.height / 2 - 30 // ヒモを吊り下げている棒の位置y
        let center = self.frame.width / 2 // ヒモを吊り下げている位置xの基準
        let size: CGFloat = 10 // ボールの大きさ
        let length: CGFloat = 50 // ヒモの長さ
        
        // ヒモとボールを描画
        for (index, loc) in ballLocs.enumerated() {
            let path = UIBezierPath()
            let x1 = center - ((CGFloat(ballLocs.count) - 1) / 2 * size) + (CGFloat(index) * size)
            let x2 = center + loc * size
            let angle = -atan2(x2 - x1, length)
            
            // ヒモ
            path.move(to: CGPoint(x: x1, y: top))
            path.addLine(to: CGPoint(x: x2, y: top + length * cos(angle)))
            path.lineWidth = 1 / UIScreen.main.scale // 線の太さ
            UIColor.white.setStroke() // 色をセット
            path.stroke()
            
            // ボール
            let ballPath = UIBezierPath(ovalIn: CGRect(x: x2 - size / 2,
                                                       y: top + length * cos(angle) - size / 2,
                                                       width: size,
                                                       height: size))
            if SettingsData.color == "blue" {
                UIColor(red: 0.0, green: 0.7, blue: 1.0, alpha: 1).setFill() // 色をセット
            } else if SettingsData.color == "orange" {
                UIColor(red: 1.0, green: 0.8, blue: 0.0, alpha: 1).setFill() // 色をセット
            } else if SettingsData.color == "monochrome" {
                UIColor(red: 0.8, green: 0.8, blue: 0.8, alpha: 1).setFill() // 色をセット
            } else {
                UIColor(red: 0.8, green: 1.0, blue: 0.0, alpha: 1).setFill() // 色をセット
            }
            ballPath.fill()
        }
    }
    
    // ボールの位置を移動
    private func ballSimulation() {
        // ボールは定位置からずれていれば、元に戻ろうとする加速度を加える
        for (index, loc) in ballLocs.enumerated() {
            let addSpeed = -pow(loc - (CGFloat(index) - 2), 3) / 3000 // とりあえず3乗で代用
            
            ballSpeeds[index] += addSpeed
        }
        
        // ボールが他の球に触れていれば、ボールの速度を交換する
        for index in 0..<ballLocs.count - 1 {
            if ballSpeeds[index] < 0 { continue }
            let loc1 = ballLocs[index] + ballSpeeds[index] / 2
            let loc2 = ballLocs[index + 1]
            
            if loc2 - loc1 < 1 && ballSpeeds[index] > ballSpeeds[index + 1] {
                let tmp = ballSpeeds[index]
                ballSpeeds[index] = ballSpeeds[index + 1]
                ballSpeeds[index + 1] = tmp
            }
        }
        for index in (0..<ballLocs.count - 1).reversed() {
            if ballSpeeds[index] > 0 { continue }
            let loc1 = ballLocs[index] + ballSpeeds[index] / 2
            let loc2 = ballLocs[index + 1]
            
            if loc2 - loc1 < 1 && ballSpeeds[index] > ballSpeeds[index + 1] {
                let tmp = ballSpeeds[index]
                ballSpeeds[index] = ballSpeeds[index + 1]
                ballSpeeds[index + 1] = tmp
            }
        }
        
        // ボールの位置を動かす
        for index in 0..<ballLocs.count {
            ballLocs[index] += ballSpeeds[index]
        }
    }
}
