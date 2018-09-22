//
//  ImageViewController.swift
//  DonParade
//
//  Created by takayoshi on 2018/09/22.
//  Copyright © 2018年 pgostation. All rights reserved.
//

// 添付画像のフルスクリーン表示、ピンチアウトで拡大したり、横スライドで次の画像へ移動できる

import UIKit

final class ImageViewController: MyViewController {
    private let imagesUrls: [String]
    private let previewUrls: [String]
    var index: Int
    private let fromRect: CGRect
    private let smallImage: UIImage?
    
    // ステータスバーは非表示
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    init(imagesUrls: [String], previewUrls: [String], index: Int, fromRect: CGRect, smallImage: UIImage?) {
        self.imagesUrls = imagesUrls
        self.previewUrls = previewUrls
        self.index = index
        self.fromRect = fromRect
        self.smallImage = smallImage
        
        super.init(nibName: nil, bundle: nil)
        
        self.modalPresentationStyle = .overCurrentContext
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        let view = ImageView(imageUrl: self.imagesUrls[index], previewUrl: self.previewUrls[index], fromRect: fromRect, smallImage: smallImage)
        self.view = view
        
        // タップ処理
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapAction))
        view.addGestureRecognizer(tapGesture)
        
        view.closeButton.addTarget(self, action: #selector(closeAction), for: .touchUpInside)
        view.optionButton.addTarget(self, action: #selector(optionAction), for: .touchUpInside)
        view.rotateButton.addTarget(self, action: #selector(rotateAction), for: .touchUpInside)
        
        self.setNeedsStatusBarAppearanceUpdate()
    }
    
    // タップでボタン表示/非表示
    @objc func tapAction() {
        guard let view = self.view as? ImageView else { return }
        
        view.closeButton.alpha = 1 - view.closeButton.alpha
        view.optionButton.alpha = 1 - view.optionButton.alpha
        view.rotateButton.alpha = 1 - view.rotateButton.alpha
    }
    
    // URLを開いたり、保存したりする
    @objc func optionAction() {
        // #### 工事中
    }
    
    // 回転...ダメだうまく動かない
    // http://d.hatena.ne.jp/RNatori/20100721/1279683273
    private var angle: Int = 0
    @objc func rotateAction() {
        guard let view = self.view as? ImageView else { return }
        
        let imageView = view.imageScrollView.imageView
        
        self.angle = (angle + 1) % 4
        
        // 現在の拡大率を取得
        let testSize = CGSize(width: 1, height: 1).applying(imageView.transform)
        let scale = fabs(testSize.width)
        
        // 回転と拡大率を設定した新しいCGAffineTransformを作成
        var newTransform = CGAffineTransform(rotationAngle: CGFloat.pi / 2.0 * CGFloat(angle))
        newTransform = newTransform.scaledBy(x: scale, y: scale)
        
        //
        let size = view.imageScrollView.initialSize
        
        var transformedSize = size.applying(newTransform)
        transformedSize.width = fabs(transformedSize.width)
        transformedSize.height = fabs(transformedSize.height)
        
        UIView.animate(withDuration: 0.2) {
            view.imageScrollView.contentSize = transformedSize
            imageView.transform = newTransform
            imageView.center = CGPoint(x: transformedSize.width / 2.0, y: transformedSize.height / 2.0)
        }
        
        print("\(imageView.frame)")
    }
    
    // 閉じる
    @objc func closeAction() {
        self.dismiss(animated: true, completion: nil)
        
        MainViewController.instance?.showButtonsForce()
    }
    
    static func getRect(size: CGSize, rate: CGFloat) -> CGRect {
        let screenBounds = UIScreen.main.bounds
        
        if size.width == 0 || size.height == 0 {
            return screenBounds
        }
        
        // まず、画面いっぱいに入る画像の拡大率を求める
        let baseRate = min(screenBounds.width / size.width, screenBounds.height / size.height)
        
        // 最終の拡大率
        let finalRate = baseRate * rate
        
        return CGRect(x: (screenBounds.width - size.width * finalRate) / 2,
                      y: (screenBounds.height - size.height * finalRate) / 2,
                      width: ceil(size.width * finalRate),
                      height: ceil(size.height * finalRate))
    }
}

private final class ImageView: UIView {
    let closeButton = UIButton()
    let optionButton = UIButton()
    let rotateButton = UIButton()
    let imageScrollView: ImageScrollView
    
    init(imageUrl: String, previewUrl: String, fromRect: CGRect, smallImage: UIImage?) {
        imageScrollView = ImageScrollView(imageUrl: imageUrl, previewUrl: imageUrl, fromRect: fromRect, smallImage: smallImage)
        
        super.init(frame: UIScreen.main.bounds)
        
        self.addSubview(imageScrollView)
        self.addSubview(closeButton)
        self.addSubview(optionButton)
        self.addSubview(rotateButton)
        
        setProperties(fromRect: fromRect)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setProperties(fromRect: CGRect) {
        self.backgroundColor = ThemeColor.viewBgColor.withAlphaComponent(0.4)
        
        closeButton.setTitle("×", for: .normal)
        closeButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 36)
        closeButton.setTitleColor(ThemeColor.mainButtonsTitleColor, for: .normal)
        closeButton.backgroundColor = ThemeColor.mainButtonsBgColor
        closeButton.layer.cornerRadius = 10
        closeButton.clipsToBounds = true
        
        optionButton.setTitle("…", for: .normal)
        optionButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 36)
        optionButton.setTitleColor(ThemeColor.mainButtonsTitleColor, for: .normal)
        optionButton.backgroundColor = ThemeColor.mainButtonsBgColor
        optionButton.layer.cornerRadius = 10
        optionButton.clipsToBounds = true
        
        rotateButton.setTitle("⤾", for: .normal)
        rotateButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 36)
        rotateButton.setTitleColor(ThemeColor.mainButtonsTitleColor, for: .normal)
        rotateButton.backgroundColor = ThemeColor.mainButtonsBgColor
        rotateButton.layer.cornerRadius = 10
        rotateButton.clipsToBounds = true
        
        // 縦方向に長い画像の場合、閉じるボタンを表示させない
        if fromRect.width < fromRect.height {
            closeButton.alpha = 0
            optionButton.alpha = 0
            rotateButton.alpha = 0
        }
    }
    
    override func layoutSubviews() {
        closeButton.frame = CGRect(x: UIScreen.main.bounds.width / 2 - 50 / 2,
                                   y: UIScreen.main.bounds.height - 70,
                                   width: 50,
                                   height: 50)
        
        optionButton.frame = CGRect(x: UIScreen.main.bounds.width - 55,
                                    y: UIScreen.main.bounds.height - 70,
                                    width: 50,
                                    height: 50)
        
        rotateButton.frame = CGRect(x: 5,
                                    y: UIScreen.main.bounds.height - 70,
                                    width: 50,
                                    height: 50)
        
        imageScrollView.frame = UIScreen.main.bounds
    }
}

private final class ImageScrollView: UIScrollView, UIScrollViewDelegate {
    let imageView = UIImageView()
    let initialSize: CGSize
    var rate: CGFloat = 1.0
    
    init(imageUrl: String, previewUrl: String, fromRect: CGRect, smallImage: UIImage?) {
        self.initialSize = ImageViewController.getRect(size: fromRect.size, rate: 1).size
        
        super.init(frame: UIScreen.main.bounds)
        
        self.addSubview(imageView)
        
        self.imageView.image = smallImage
        self.imageView.frame = fromRect
        self.imageView.contentMode = .scaleAspectFit
        
        if let smallImage = smallImage {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                UIView.animate(withDuration: 0.2) {
                    self.imageView.frame = ImageViewController.getRect(size: smallImage.size, rate: self.rate)
                }
            }
        }
        
        ImageCache.image(urlStr: previewUrl, isTemp: true) { [weak self] (image) in
            guard let strongSelf = self else { return }
            
            strongSelf.imageView.image = image
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                UIView.animate(withDuration: 0.2) {
                    strongSelf.imageView.frame = ImageViewController.getRect(size: image.size, rate: strongSelf.rate)
                    
                    strongSelf.delegate = self
                    strongSelf.minimumZoomScale = 1.0
                    strongSelf.maximumZoomScale = 8.0
                    
                    strongSelf.setNeedsLayout()
                }
            }
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
}
