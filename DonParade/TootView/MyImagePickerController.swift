//
//  MyImagePickerController.swift
//  DonParade
//
//  Created by takayoshi on 2018/09/23.
//  Copyright © 2018年 pgostation. All rights reserved.
//

import UIKit
import Photos

final class MyImagePickerController: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    private let callback: (URL?)->Void
    private let imagePicker = UIImagePickerController()
    static var instance: MyImagePickerController? = nil
    
    static func show(useMovie: Bool, callback: @escaping (URL?)->Void) {
        instance = MyImagePickerController(useMovie: useMovie, callback: callback)
    }
    
    private init(useMovie: Bool, callback: @escaping (URL?)->Void) {
        self.callback = callback
        
        super.init()
        
        imagePicker.sourceType = .photoLibrary
        imagePicker.delegate = self
        if useMovie {
            imagePicker.mediaTypes = ["public.image", "public.movie"]
        } else {
            imagePicker.mediaTypes = ["public.image"]
        }
        UIUtils.getFrontViewController()?.present(imagePicker, animated: true, completion: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // 選択完了時に呼ばれる
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        let imageUrl = (info["PHImageFileURLKey"] ?? info["UIImagePickerControllerImageURL"] ?? info["UIImagePickerControllerReferenceURL"]) as? URL
        if let cropRect = info[UIImagePickerControllerCropRect] as? CGRect {
            print("#### cropRect=\(cropRect)")
        }
        print("#### info[PHImageFileURLKey]=\(info["PHImageFileURLKey"])")
        print("#### info[UIImagePickerControllerImageURL]=\(info["UIImagePickerControllerImageURL"])")
        print("#### info[UIImagePickerControllerReferenceURL]=\(info["UIImagePickerControllerReferenceURL"])")
        self.callback(imageUrl)
        MyImagePickerController.instance = nil
        
        picker.dismiss(animated: true, completion: nil)
    }
    
    // キャンセルされた時に呼ばれる
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        self.callback(nil)
        MyImagePickerController.instance = nil
        
        picker.dismiss(animated: true, completion: nil)
    }
}
