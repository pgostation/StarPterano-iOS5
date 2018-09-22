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
        
        // タップえボタンの表示非表示
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapAction))
        view.addGestureRecognizer(tapGesture)
        
        // 横スワイプで左右移動
        
        // 上下スワイプで閉じる
        
        
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
    
    // 画像を保存する
    @objc func optionAction() {
        guard let view = self.view as? ImageView else { return }
        guard let image = view.imageScrollView.imageView.image else { return }
        
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: UIAlertControllerStyle.actionSheet)
        
        // アルバムに保存
        alertController.addAction(UIAlertAction(
            title: I18n.get("ACTION_SAVE_IMAGE_TO_ALBUM"),
            style: UIAlertActionStyle.default,
            handler: { _ in
                UIImageWriteToSavedPhotosAlbum(image, self, #selector(self.imageSaved(_:didFinishSavingWithError:contextInfo:)), nil)
        }))
        
        // キャンセル
        alertController.addAction(UIAlertAction(
            title: I18n.get("BUTTON_CANCEL"),
            style: UIAlertActionStyle.cancel,
            handler: { _ in
        }))
        
        UIUtils.getFrontViewController()?.present(alertController, animated: true, completion: nil)
    }
    
    @objc func imageSaved(_ image: UIImage, didFinishSavingWithError error: NSError!, contextInfo: UnsafeMutableRawPointer) {
        
    }
    
    // 回転
    @objc func rotateAction() {
        guard let view = self.view as? ImageView else { return }
        
        let imageView = view.imageScrollView.imageView
        
        imageView.image = ImageUtils.rotateImage(image: imageView.image)
        
        if let image = imageView.image {
            imageView.frame = ImageViewController.getRect(size: image.size, rate: 1)
        }
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
        
        if #available(iOS 11.0, *) {
            self.addSubview(rotateButton)
        }
        
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
    
    init(imageUrl: String, previewUrl: String, fromRect: CGRect, smallImage: UIImage?) {
        super.init(frame: UIScreen.main.bounds)
        
        self.addSubview(imageView)
        
        self.imageView.image = smallImage
        self.imageView.frame = fromRect
        
        self.delegate = self
        self.minimumZoomScale = 1.0
        self.maximumZoomScale = 8.0
        
        if let smallImage = smallImage {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                UIView.animate(withDuration: 0.2) {
                    self.imageView.frame = ImageViewController.getRect(size: smallImage.size, rate: 1)
                }
            }
        }
        
        ImageCache.image(urlStr: previewUrl, isTemp: true, isSmall: false) { [weak self] (image) in
            guard let strongSelf = self else { return }
            
            strongSelf.imageView.image = image
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                UIView.animate(withDuration: 0.2) {
                    strongSelf.imageView.frame = ImageViewController.getRect(size: image.size, rate: 1)
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
