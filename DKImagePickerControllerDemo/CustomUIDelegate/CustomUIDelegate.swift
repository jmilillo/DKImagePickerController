//
//  CustomUIDelegate.swift
//  DKImagePickerControllerDemo
//
//  Created by ZhangAo on 03/01/2017.
//  Copyright © 2017 ZhangAo. All rights reserved.
//

import UIKit

public class CustomUIDelegate: DKImagePickerControllerDefaultUIDelegate {
    
    lazy var footer: UIToolbar = {
        let toolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: 0, height: 44))
        toolbar.translucent = false
        toolbar.items = [
            UIBarButtonItem(barButtonSystemItem: .FlexibleSpace, target: nil, action: nil),
            UIBarButtonItem(customView: self.createDoneButtonIfNeeded()),
        ]
        self.updateDoneButtonTitle(self.createDoneButtonIfNeeded())
        
        return toolbar
    }()
    
    override public func createDoneButtonIfNeeded() -> UIButton {
        if self.doneButton == nil {
            let button = UIButton(type: .Custom)
            button.titleLabel?.font = UIFont.systemFontOfSize(15)
            button.setTitleColor(UIColor(red: 85 / 255.0, green: 184 / 255.0, blue: 44 / 255.0, alpha: 1.0), forState: .Normal)
            button.setTitleColor(UIColor(red: 85 / 255.0, green: 184 / 255.0, blue: 44 / 255.0, alpha: 0.4), forState: .Disabled)
            button.addTarget(self.imagePickerController, action: #selector(DKImagePickerController.done), forControlEvents: .TouchUpInside)
            self.doneButton = button
        }
        
        return self.doneButton!
    }
    
    override public func prepareLayout(imagePickerController: DKImagePickerController, vc: UIViewController) {
        self.imagePickerController = imagePickerController
    }
    
    override public func imagePickerController(imagePickerController: DKImagePickerController,
                                               showsCancelButtonForVC vc: UIViewController) {
        vc.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Cancel,
                                                               target: imagePickerController,
                                                               action: #selector(imagePickerController.dismiss as (Void) -> Void))
    }
    
    override public func imagePickerController(imagePickerController: DKImagePickerController,
                                               hidesCancelButtonForVC vc: UIViewController) {
        vc.navigationItem.rightBarButtonItem = nil
    }
    
    override public func imagePickerControllerFooterView(imagePickerController: DKImagePickerController) -> UIView? {
        return self.footer
    }
    
    override public func updateDoneButtonTitle(button: UIButton) {
        if self.imagePickerController.selectedAssets.count > 0 {
            button.setTitle(String(format: "Send(%d)", self.imagePickerController.selectedAssets.count), forState: .Normal)
            button.enabled = true
        } else {
            button.setTitle("Send", forState: .Normal)
            button.enabled = false
        }
        
        button.sizeToFit()
    }
    
    public override func imagePickerControllerCollectionImageCell() -> DKAssetGroupDetailBaseCell.Type {
        return CustomGroupDetailImageCell.self
    }
    
    public override func imagePickerControllerCollectionCameraCell() -> DKAssetGroupDetailBaseCell.Type {
        return CustomGroupDetailCameraCell.self
    }

}
