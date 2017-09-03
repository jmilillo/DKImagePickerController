//
//  DKImagePickerController.swift
//  DKImagePickerController
//
//  Created by ZhangAo on 14-10-2.
//  Copyright (c) 2014年 ZhangAo. All rights reserved.
//

import UIKit
import Photos
import AssetsLibrary

@objc
public protocol DKImagePickerControllerCameraProtocol {
    
    func setDKImagePickerControllerCameraDidCancel(block: () -> Void) -> Void
    
    func setDKImagePickerControllerCameraDidFinishCapturingImage(block: (image: UIImage?, data: NSData?) -> Void) -> Void
    
    func setDKImagePickerControllerCameraDidFinishCapturingVideo(block: (videoURL: NSURL) -> Void) -> Void
}

@objc
public protocol DKImagePickerControllerUIDelegate {
    
    /**
     The picker calls -prepareLayout once at its first layout as the first message to the UIDelegate instance.
     */
    func prepareLayout(imagePickerController: DKImagePickerController, vc: UIViewController)
    
    /**
     Returns a custom camera.
     
     **Note**
     
     If you are using a UINavigationController as the custom camera,
     you should also set the picker's modalPresentationStyle to .overCurrentContext, like this:
     
     ```
     pickerController.modalPresentationStyle = .overCurrentContext
     ```
     
     - Parameter imagePickerController: DKImagePickerController
     - Returns: The returned `UIViewControlelr` must conform to the `DKImagePickerControllerCameraProtocol`.
     */
    func imagePickerControllerCreateCamera(imagePickerController: DKImagePickerController) -> UIViewController
        
    /**
     The layout is to provide information about the position and visual state of items in the collection view.
     */
    func layoutForImagePickerController(imagePickerController: DKImagePickerController) -> UICollectionViewLayout.Type
    
    /**
     Called when the user needs to show the cancel button.
     */
    func imagePickerController(imagePickerController: DKImagePickerController, showsCancelButtonForVC vc: UIViewController)
    
    /**
     Called when the user needs to hide the cancel button.
     */
    func imagePickerController(imagePickerController: DKImagePickerController, hidesCancelButtonForVC vc: UIViewController)
    
    /**
     Called after the user changes the selection.
     */
    func imagePickerController(imagePickerController: DKImagePickerController, didSelectAssets: [DKAsset])
    
    /**
     Called after the user changes the selection.
     */
    func imagePickerController(imagePickerController: DKImagePickerController, didDeselectAssets: [DKAsset])
    
    /**
     Called when the count of the selectedAssets did reach `maxSelectableCount`.
     */
    func imagePickerControllerDidReachMaxLimit(imagePickerController: DKImagePickerController)
    
    /**
     Accessory view below content. default is nil.
     */
    func imagePickerControllerFooterView(imagePickerController: DKImagePickerController) -> UIView?
    
    /**
     Set the color of the background of the collection view.
     */
    func imagePickerControllerCollectionViewBackgroundColor() -> UIColor
 
    func imagePickerControllerCollectionImageCell() -> DKAssetGroupDetailBaseCell.Type
    
    func imagePickerControllerCollectionCameraCell() -> DKAssetGroupDetailBaseCell.Type
    
    func imagePickerControllerCollectionVideoCell() -> DKAssetGroupDetailBaseCell.Type
}

/**
 - AllPhotos: Get all photos assets in the assets group.
 - AllVideos: Get all video assets in the assets group.
 - AllAssets: Get all assets in the group.
 */
@objc
public enum DKImagePickerControllerAssetType : Int {
    case allPhotos, allVideos, allAssets
}

@objc
public enum DKImagePickerControllerSourceType : Int {
    case camera, photo, both
}

// MARK: - Public DKImagePickerController

/**
 * The `DKImagePickerController` class offers the all public APIs which will affect the UI.
 */
public class DKImagePickerController : UINavigationController {
    
    lazy public var UIDelegate: DKImagePickerControllerUIDelegate = {
        return DKImagePickerControllerDefaultUIDelegate()
    }()
    
    /// Forces deselect of previous selected image
    public var singleSelect = false
    
    /// Auto close picker on single select
    public var autoCloseOnSingleSelect = true
    
    /// The maximum count of assets which the user will be able to select.
    public var maxSelectableCount = 999
    
    /// Set the defaultAssetGroup to specify which album is the default asset group.
    public var defaultAssetGroup: PHAssetCollectionSubtype?
    
    /// allow swipe to select images.
    public var allowSwipeToSelect: Bool = false
    
    public var inline: Bool = false
    
    /// Limits the maximum number of objects returned in the fetch result, a value of 0 means no limit.
    public var fetchLimit = 0
    
    /// The types of PHAssetCollection to display in the picker.
    public var assetGroupTypes: [PHAssetCollectionSubtype] = [
        .SmartAlbumUserLibrary,
        .SmartAlbumFavorites,
        .AlbumRegular
        ] {
        willSet(newTypes) {
            getImageManager().groupDataManager.assetGroupTypes = newTypes
        }
    }
    
    /// Set the showsEmptyAlbums to specify whether or not the empty albums is shown in the picker.
    public var showsEmptyAlbums = true {
        didSet {
            getImageManager().groupDataManager.showsEmptyAlbums = self.showsEmptyAlbums
        }
    }
    
    public var assetFilter: ((asset: PHAsset) -> Bool)? {
        didSet {
            getImageManager().groupDataManager.assetFilter = self.assetFilter
        }
    }
    
    /// The type of picker interface to be displayed by the controller.
    public var assetType: DKImagePickerControllerAssetType = .allAssets {
        didSet {
            getImageManager().groupDataManager.assetFetchOptions = self.createAssetFetchOptions()
        }
    }
    
    /// The predicate applies to images only.
    public var imageFetchPredicate: NSPredicate? {
        didSet {
            getImageManager().groupDataManager.assetFetchOptions = self.createAssetFetchOptions()
        }
    }
    
    /// The predicate applies to videos only.
    public var videoFetchPredicate: NSPredicate? {
        didSet {
            getImageManager().groupDataManager.assetFetchOptions = self.createAssetFetchOptions()
        }
    }
    
    /// If sourceType is Camera will cause the assetType & maxSelectableCount & allowMultipleTypes & defaultSelectedAssets to be ignored.
    public var sourceType: DKImagePickerControllerSourceType = .both {
        didSet { /// If source type changed in the scenario of sharing instance, view controller should be reinitialized.
            if(oldValue != sourceType) {
                self.hasInitialized = false
            }
        }
    }
    
    /// Whether allows to select photos and videos at the same time.
    public var allowMultipleTypes = true
    
    /// If YES, and the requested image is not stored on the local device, the Picker downloads the image from iCloud.
    public var autoDownloadWhenAssetIsInCloud = true {
        didSet {
            getImageManager().autoDownloadWhenAssetIsInCloud = self.autoDownloadWhenAssetIsInCloud
        }
    }
    
    /// Determines whether or not the rotation is enabled.
    public var allowsLandscape = false
    
    /// The callback block is executed when user pressed the cancel button.
    public var didCancel: (() -> Void)?
    public var showsCancelButton = false {
        didSet {
            if let rootVC = self.viewControllers.first {
                self.updateCancelButtonForVC(rootVC)
            }
        }
    }
    
    /// The callback block is executed when user pressed the select button.
    public var didSelectAssets: ((assets: [DKAsset]) -> Void)?
    
    public var selectedChanged: (() -> Void)?
    
    /// It will have selected the specific assets.
    public var defaultSelectedAssets: [DKAsset]? {
        didSet {
            if let defaultSelectedAssets = self.defaultSelectedAssets {
                if Set(self.selectedAssets) != Set(defaultSelectedAssets) {
                    self.selectedAssets = self.defaultSelectedAssets ?? []
                    
                    if let rootVC = self.viewControllers.first as? DKAssetGroupDetailVC {
                        rootVC.collectionView.reloadData()
                    }
                }
            }
        }
    }
    
    public private(set) var selectedAssets = [DKAsset]()
    
    static private var imagePickerControllerReferenceCount = 0
    public convenience init() {
        let rootVC = UIViewController()
        self.init(rootViewController: rootVC)
        
        self.preferredContentSize = CGSize(width: 680, height: 600)
        
        rootVC.navigationItem.hidesBackButton = true
        
        getImageManager().groupDataManager.assetGroupTypes = self.assetGroupTypes
        getImageManager().groupDataManager.assetFetchOptions = self.createAssetFetchOptions()
        getImageManager().groupDataManager.showsEmptyAlbums = self.showsEmptyAlbums
        getImageManager().autoDownloadWhenAssetIsInCloud = self.autoDownloadWhenAssetIsInCloud
        
        DKImagePickerController.imagePickerControllerReferenceCount += 1
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
        
        DKImagePickerController.imagePickerControllerReferenceCount -= 1
        if DKImagePickerController.imagePickerControllerReferenceCount == 0 {
            getImageManager().invalidate()
        }
    }
    
    private var hasInitialized = false
    override public func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if !hasInitialized {
            hasInitialized = true
            
            if self.inline || self.sourceType == .camera {
                self.navigationBarHidden = true
            } else {
                self.navigationBarHidden = false
            }
            
            if self.sourceType == .camera {
                let camera = self.createCamera()
                if camera is UINavigationController {
                    self.presentCamera(camera)
                    self.setViewControllers([], animated: false)
                } else {
                    self.setViewControllers([camera], animated: false)
                }
            } else {
                let rootVC = self.makeRootVC()
                rootVC.imagePickerController = self
                
                self.UIDelegate.prepareLayout(self, vc: rootVC)
                self.updateCancelButtonForVC(rootVC)
                self.setViewControllers([rootVC], animated: false)
                if let count = self.defaultSelectedAssets?.count where count > 0 {
                    self.UIDelegate.imagePickerController(self, didSelectAssets: [self.defaultSelectedAssets!.last!])
                }
            }
        }
    }
    
    private lazy var assetFetchOptions: PHFetchOptions = {
        let assetFetchOptions = PHFetchOptions()
        return assetFetchOptions
    }()
  
    public func makeRootVC() -> DKAssetGroupDetailVC {
      return DKAssetGroupDetailVC()
    }
    
    private func createAssetFetchOptions() -> PHFetchOptions? {
        let createImagePredicate = { () -> NSPredicate in
            var imagePredicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.Image.rawValue)
            if let imageFetchPredicate = self.imageFetchPredicate {
                imagePredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [imagePredicate, imageFetchPredicate])
            }
            
            return imagePredicate
        }
        
        let createVideoPredicate = { () -> NSPredicate in
            var videoPredicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.Video.rawValue)
            if let videoFetchPredicate = self.videoFetchPredicate {
                videoPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [videoPredicate, videoFetchPredicate])
            }
            
            return videoPredicate
        }
        
        var predicate: NSPredicate?
        switch self.assetType {
        case .allAssets:
            predicate = NSCompoundPredicate(orPredicateWithSubpredicates: [createImagePredicate(), createVideoPredicate()])
        case .allPhotos:
            predicate = createImagePredicate()
        case .allVideos:
            predicate = createVideoPredicate()
        }
        
        self.assetFetchOptions.predicate = predicate
        
        return self.assetFetchOptions
    }
    
    private func updateCancelButtonForVC(vc: UIViewController) {
        if self.showsCancelButton {
            self.UIDelegate.imagePickerController(self, showsCancelButtonForVC: vc)
        } else {
            self.UIDelegate.imagePickerController(self, hidesCancelButtonForVC: vc)
        }
    }
    
    private func createCamera() -> UIViewController {
        let didCancel = { [unowned self] () in
            if self.sourceType == .camera {
                self.dismissCamera()
                self.dismiss()
            } else {
                self.dismissCamera()
            }
        }
        
        let didFinishCapturingImage = { [unowned self] (image: UIImage?, data: NSData?) in
            let completeBlock: ((asset: DKAsset) -> Void) = { asset in
                if self.sourceType != .camera {
                    self.dismissCamera()
                }
                self.selectImage(asset)
            }
            
            if let data = data {
                self.capturingImageData(data, image: image, completeBlock: completeBlock)
            } else if let image = image {
                self.capturingImage(image, completeBlock)
            } else {
                assert(false)
            }
        }
        
        let didFinishCapturingVideo = { [unowned self] (videoURL: NSURL) in
            var newVideoIdentifier: String!
            PHPhotoLibrary.sharedPhotoLibrary().performChanges({
                let assetRequest = PHAssetChangeRequest.creationRequestForAssetFromVideoAtFileURL(videoURL)
                newVideoIdentifier = assetRequest?.placeholderForCreatedAsset?.localIdentifier
            }) { (success, error) in
                dispatch_async(dispatch_get_main_queue(), {
                    if success {
                        if let newAsset = PHAsset.fetchAssetsWithLocalIdentifiers([newVideoIdentifier], options: nil).firstObject {
                            if self.sourceType != .camera || self.viewControllers.count == 0 {
                                self.dismissCamera()
                            }
                            self.selectImage(DKAsset(originalAsset: newAsset as! PHAsset))
                        }
                    } else {
                        self.dismissCamera()
                    }
                })
            }
        }
        
        let camera = self.UIDelegate.imagePickerControllerCreateCamera(self)
        let cameraProtocol = camera as! DKImagePickerControllerCameraProtocol
        
        cameraProtocol.setDKImagePickerControllerCameraDidCancel(didCancel)
        cameraProtocol.setDKImagePickerControllerCameraDidFinishCapturingImage(didFinishCapturingImage)
        cameraProtocol.setDKImagePickerControllerCameraDidFinishCapturingVideo(didFinishCapturingVideo)
        
        return camera
    }
    
    internal func presentCamera() {
        self.presentCamera(self.createCamera())
    }
    
    internal weak var camera: UIViewController?
    internal func presentCamera(camera: UIViewController) {
        self.camera = camera
        
        if self.inline {
            UIApplication.sharedApplication().keyWindow!.rootViewController!.presentViewController(camera, animated: true, completion: nil)
        } else {
            self.presentViewController(camera, animated: true, completion: nil)
        }
    }
    
    internal func dismissCamera() {
        if let _ = self.camera {
            if self.inline {
                UIApplication.sharedApplication().keyWindow!.rootViewController!.dismissViewControllerAnimated(true, completion: nil)
            } else {
                self.dismissViewControllerAnimated(true, completion: nil)
            }
            self.camera = nil
        }
    }
    
    public func dismiss() {
        self.presentingViewController?.dismissViewControllerAnimated(true, completion: {
            self.didCancel?()
        })
    }
    
    public func done() {
        self.presentingViewController?.dismissViewControllerAnimated(true, completion: {
            self.didSelectAssets?(assets: self.selectedAssets)
        })
    }
    
    // MARK:- Capturing Image
    
    internal func capturingImage(image: UIImage, _ completeBlock: ((asset: DKAsset) -> Void)) {
        var newImageIdentifier: String!
        
        PHPhotoLibrary.sharedPhotoLibrary().performChanges({
            let assetRequest = PHAssetChangeRequest.creationRequestForAssetFromImage(image)
            newImageIdentifier = assetRequest.placeholderForCreatedAsset!.localIdentifier
        }) { (success, error) in
            dispatch_async(dispatch_get_main_queue(), {
                if success, let newAsset = PHAsset.fetchAssetsWithLocalIdentifiers([newImageIdentifier], options: nil).firstObject {
                    completeBlock(asset: DKAsset(originalAsset: newAsset as! PHAsset))
                } else {
                    completeBlock(asset: DKAsset(image: image))
                }
            })
            
        }
    }
    
    internal func capturingImageData(data: NSData, image: UIImage?, completeBlock: ((asset: DKAsset) -> Void)) {
        var metadata: Dictionary<NSObject, Any>?
        if let source = CGImageSourceCreateWithData(data as CFData, nil) {
            metadata = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? Dictionary<NSObject, AnyObject>
        }
        
        var imageData = data
        if let image = image {
            imageData = UIImageJPEGRepresentation(image, 1)!
        }
        
        if #available(iOS 9.0, *) {
            if let metadata = metadata {
                if let imageDataWithMetadata = self.writeMetadata(metadata as! Dictionary<NSObject, AnyObject>, Into: imageData) {
                    self.capturingImageDataForiOS9(imageDataWithMetadata, completeBlock: completeBlock)
                } else {
                    self.capturingImageDataForiOS9(imageData, completeBlock: completeBlock)
                }
            } else {
                self.capturingImageDataForiOS9(imageData, completeBlock: completeBlock)
            }
        } else {
            self.capturingImageDataForiOS8(imageData, metadata: metadata, completeBlock: completeBlock)
        }
    }
    
    internal func capturingImageDataForiOS8(data: NSData, metadata: Dictionary<NSObject, Any>?, completeBlock: ((asset: DKAsset) -> Void)) {
        let library = ALAssetsLibrary()
        library.writeImageDataToSavedPhotosAlbum(data, metadata: metadata as? [NSObject : AnyObject], completionBlock: { (newURL, error) in
            if let _ = error {
                completeBlock(asset: DKAsset(image: UIImage(data: data)!))
            } else {
                if let newAsset = PHAsset.fetchAssetsWithALAssetURLs([newURL!], options: nil).firstObject {
                    completeBlock(asset: DKAsset(originalAsset: newAsset as! PHAsset))
                }
            }
        })
    }
    
    internal func capturingImageDataForiOS9(data: NSData, completeBlock: ((asset: DKAsset) -> Void)) {
        var newImageIdentifier: String!
        
        PHPhotoLibrary.sharedPhotoLibrary().performChanges({
            if #available(iOS 9.0, *) {
                let assetRequest = PHAssetCreationRequest.creationRequestForAsset()
                assetRequest.addResourceWithType(.Photo, data: data, options: nil)
                newImageIdentifier = assetRequest.placeholderForCreatedAsset!.localIdentifier
            } else {
                // Fallback on earlier versions
            }
        }) { (success, error) in
            dispatch_async(dispatch_get_main_queue(), {
                if success, let newAsset = PHAsset.fetchAssetsWithLocalIdentifiers([newImageIdentifier], options: nil).firstObject {
                    completeBlock(asset: DKAsset(originalAsset: newAsset as! PHAsset))
                } else {
                    completeBlock(asset: DKAsset(image: UIImage(data: data)!))
                }
            })
            
        }
    }
    
    internal func writeMetadata(metadata: Dictionary<NSObject, AnyObject>, Into imageData: NSData) -> NSData? {
        let source = CGImageSourceCreateWithData(imageData as CFData, nil)!
        let UTI = CGImageSourceGetType(source)!
        
        let newImageData = NSMutableData()
        if let destination = CGImageDestinationCreateWithData(newImageData, UTI, 1, nil) {
            CGImageDestinationAddImageFromSource(destination, source, 0, metadata as NSDictionary)
            if CGImageDestinationFinalize(destination) {
                return newImageData as NSData
            } else {
                return nil
            }
        } else {
            return nil
        }
    }
    
    // MARK: - Selection
    
    public func selectImage(atIndexPath index: NSIndexPath) {
        if let rootVC = self.viewControllers.first as? DKAssetGroupDetailVC {
            rootVC.selectAsset(atIndex: index)
            rootVC.collectionView?.reloadData()
        }
    }
    
    public func deselectAssetAtIndex(index: Int) {
        let asset = self.selectedAssets[index]
        self.deselectAsset(asset)
    }
    
    public func deselectAsset(asset: DKAsset) {
        self.deselectImage(asset)
        if let rootVC = self.viewControllers.first as? DKAssetGroupDetailVC {
            rootVC.collectionView?.reloadData()
        }
    }
    
    public func deselectAllAssets() {
        if self.selectedAssets.count > 0 {
            let assets = self.selectedAssets
            self.selectedAssets.removeAll()
            self.triggerSelectedChanged()
            self.UIDelegate.imagePickerController(self, didDeselectAssets: assets)
            if let rootVC = self.viewControllers.first as? DKAssetGroupDetailVC {
                rootVC.collectionView?.reloadData()
            }
        }
    }
    
    internal func selectImage(asset: DKAsset) {
        if self.singleSelect {
            self.deselectAllAssets()
            self.selectedAssets.append(asset)
            if self.sourceType == .camera || autoCloseOnSingleSelect {
                self.done()
            } else {
                self.UIDelegate.imagePickerController(self, didSelectAssets: [asset])
            }
        } else {
            self.selectedAssets.append(asset)
            if self.sourceType == .camera {
                self.done()
            } else {
                self.UIDelegate.imagePickerController(self, didSelectAssets: [asset])
                self.triggerSelectedChanged()
            }
        }
    }
    
    internal func deselectImage(asset: DKAsset) {
        self.selectedAssets.removeAtIndex(selectedAssets.indexOf(asset)!)
        self.UIDelegate.imagePickerController(self, didDeselectAssets: [asset])
        self.triggerSelectedChanged()
    }
    
    internal func triggerSelectedChanged() {
        if let selectedChanged = self.selectedChanged {
            selectedChanged()
        }
    }
    
    // MARK: - Handles Orientation
    
    public override func shouldAutorotate() -> Bool {
        return self.allowsLandscape && self.sourceType != .camera ? true : false
    }
    
    public override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        if self.allowsLandscape {
            return super.supportedInterfaceOrientations()
        } else {
            return UIInterfaceOrientationMask.Portrait
        }
    }
}
