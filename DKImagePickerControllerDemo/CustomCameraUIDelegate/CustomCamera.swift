//
//  CustomCamera.swift
//  DKImagePickerControllerDemo
//
//  Created by ZhangAo on 03/01/2017.
//  Copyright © 2017 ZhangAo. All rights reserved.
//

import UIKit
import MobileCoreServices

public class CustomCamera: UIImagePickerController, DKImagePickerControllerCameraProtocol, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    var didCancel: (() -> Void)?
    var didFinishCapturingImage: ((image: UIImage?, data: NSData?) -> Void)?
    var didFinishCapturingVideo: ((videoURL: NSURL) -> Void)?
    
    
    public func setDKImagePickerControllerCameraDidCancel(block: () -> Void) {
        self.didCancel = block
    }
    
    public func setDKImagePickerControllerCameraDidFinishCapturingImage(block: (image: UIImage?, data: NSData?) -> Void) {
        self.didFinishCapturingImage = block
    }
    
    public func setDKImagePickerControllerCameraDidFinishCapturingVideo(block: (videoURL: NSURL) -> Void) {
        self.didFinishCapturingVideo = block
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        self.delegate = self
        self.sourceType = .Camera
        self.mediaTypes = [kUTTypeImage as String, kUTTypeMovie as String]
    }
    
    // MARK: - UIImagePickerControllerDelegate methods
    
    public func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        let mediaType = info[UIImagePickerControllerMediaType] as! String
        
        if mediaType == kUTTypeImage as String {
            let image = info[UIImagePickerControllerOriginalImage] as! UIImage
            self.didFinishCapturingImage?(image: image, data: nil)
        } else if mediaType == kUTTypeMovie as String {
            let videoURL = info[UIImagePickerControllerMediaURL] as! NSURL
            self.didFinishCapturingVideo?(videoURL: videoURL)
        }
    }
    
    public func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        self.didCancel?()
    }
    
}
