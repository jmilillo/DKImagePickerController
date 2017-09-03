//
//  DKImagePickerControllerDefaultUIDelegate.swift
//  DKImagePickerControllerDemo
//
//  Created by ZhangAo on 16/3/7.
//  Copyright © 2016年 ZhangAo. All rights reserved.
//

import UIKit

@objc
public class DKImagePickerControllerDefaultUIDelegate: NSObject, DKImagePickerControllerUIDelegate {
	
	public weak var imagePickerController: DKImagePickerController!
	
	public var doneButton: UIButton?
	
	public func createDoneButtonIfNeeded() -> UIButton {
        if self.doneButton == nil {
            let button = UIButton(type: UIButtonType.Custom)
            button.setTitleColor(UINavigationBar.appearance().tintColor ?? self.imagePickerController.navigationBar.tintColor, forState: .Normal)
            button.addTarget(self.imagePickerController, action: #selector(DKImagePickerController.done), forControlEvents: UIControlEvents.TouchUpInside)
            self.doneButton = button
            self.updateDoneButtonTitle(button)
        }
		
		return self.doneButton!
	}
    
    public func updateDoneButtonTitle(button: UIButton) {
        if self.imagePickerController.selectedAssets.count > 0 {
            
            let nF = NSNumberFormatter()
            nF.numberStyle = .DecimalStyle
            nF.locale = NSLocale(localeIdentifier: NSLocale.currentLocale().localeIdentifier)
            
            let formattedSelectableCount = nF.stringFromNumber(self.imagePickerController.selectedAssets.count)
            
            button.setTitle(String(format: DKImageLocalizedStringWithKey("select"), formattedSelectableCount ?? self.imagePickerController.selectedAssets.count), forState: .Normal)
        } else {
            button.setTitle(DKImageLocalizedStringWithKey("done"), forState: .Normal)
        }
        
        button.sizeToFit()
    }
	
	// Delegate methods...
	
	public func prepareLayout(imagePickerController: DKImagePickerController, vc: UIViewController) {
		self.imagePickerController = imagePickerController
		vc.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: self.createDoneButtonIfNeeded())
	}
        
    public func imagePickerControllerCreateCamera(imagePickerController: DKImagePickerController) -> UIViewController {
        let camera = DKImagePickerControllerCamera()
        
        self.checkCameraPermission(camera)
        
        return camera
    }
	
	public func layoutForImagePickerController(imagePickerController: DKImagePickerController) -> UICollectionViewLayout.Type {
		return DKAssetGroupGridLayout.self
	}
	
	public func imagePickerController(imagePickerController: DKImagePickerController,
	                                  showsCancelButtonForVC vc: UIViewController) {
		vc.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Cancel,
		                                                      target: imagePickerController,
		                                                      action: #selector(imagePickerController.dismiss as (Void) -> Void))
	}
	
	public func imagePickerController(imagePickerController: DKImagePickerController,
	                                  hidesCancelButtonForVC vc: UIViewController) {
		vc.navigationItem.leftBarButtonItem = nil
	}
    
    public func imagePickerController(imagePickerController: DKImagePickerController, didSelectAssets: [DKAsset]) {
        self.updateDoneButtonTitle(self.createDoneButtonIfNeeded())
    }
	    
    public func imagePickerController(imagePickerController: DKImagePickerController, didDeselectAssets: [DKAsset]) {
        self.updateDoneButtonTitle(self.createDoneButtonIfNeeded())
    }
	
	public func imagePickerControllerDidReachMaxLimit(imagePickerController: DKImagePickerController) {
        
        let nF = NSNumberFormatter()
        nF.numberStyle = .DecimalStyle
        nF.locale = NSLocale(localeIdentifier: NSLocale.currentLocale().localeIdentifier)
        
        let formattedMaxSelectableCount = nF.stringFromNumber(imagePickerController.maxSelectableCount)
        
        let alert = UIAlertController(title: DKImageLocalizedStringWithKey("maxLimitReached"), message: nil, preferredStyle: .Alert)
        
        alert.message = String(format: DKImageLocalizedStringWithKey("maxLimitReachedMessage"), formattedMaxSelectableCount ?? imagePickerController.maxSelectableCount)
        
        alert.addAction(UIAlertAction(title: DKImageLocalizedStringWithKey("ok"), style: .Cancel) { _ in })
        
        imagePickerController.presentViewController(alert, animated: true, completion: nil)
	}
	
	public func imagePickerControllerFooterView(imagePickerController: DKImagePickerController) -> UIView? {
		return nil
	}
    
    public func imagePickerControllerCollectionViewBackgroundColor() -> UIColor {
        return UIColor.whiteColor()
    }
    
    public func imagePickerControllerCollectionImageCell() -> DKAssetGroupDetailBaseCell.Type {
        return DKAssetGroupDetailImageCell.self
    }
    
    public func imagePickerControllerCollectionCameraCell() -> DKAssetGroupDetailBaseCell.Type {
        return DKAssetGroupDetailCameraCell.self
    }
    
    public func imagePickerControllerCollectionVideoCell() -> DKAssetGroupDetailBaseCell.Type {
        return DKAssetGroupDetailVideoCell.self
    }
	
	// Internal
	
	public func checkCameraPermission(camera: DKCamera) {
		func cameraDenied() {
            dispatch_async(dispatch_get_main_queue()) {
				let permissionView = DKPermissionView.permissionView(.camera)
				camera.cameraOverlayView = permissionView
			}
		}
		
		func setup() {
			camera.cameraOverlayView = nil
		}
		
		DKCamera.checkCameraPermission { granted in
			granted ? setup() : cameraDenied()
		}
	}
		
}

@objc
public class DKImagePickerControllerCamera: DKCamera, DKImagePickerControllerCameraProtocol {
    
    public func setDKImagePickerControllerCameraDidFinishCapturingVideo(block: (videoURL: NSURL) -> Void) {
        
    }

    public func setDKImagePickerControllerCameraDidFinishCapturingImage(block: (image: UIImage?, data: NSData?) -> Void) {
        super.didFinishCapturingImage = block
    }

    public func setDKImagePickerControllerCameraDidCancel(block: () -> Void) {
        super.didCancel = block
    }
    
}
