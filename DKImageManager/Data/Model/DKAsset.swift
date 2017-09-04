//
//  DKAsset.swift
//  DKImagePickerControllerDemo
//
//  Created by ZhangAo on 15/12/13.
//  Copyright © 2015年 ZhangAo. All rights reserved.
//

import Photos

public extension CGSize {
	
	public func toPixel() -> CGSize {
		let scale = UIScreen.mainScreen().scale
		return CGSize(width: self.width * scale, height: self.height * scale)
	}
}

/**
 An `DKAsset` object represents a photo or a video managed by the `DKImagePickerController`.
 */
public class DKAsset: NSObject {

	/// Returns a UIImage that is appropriate for displaying full screen.
	private var fullScreenImage: (image: UIImage?, info: [NSObject: AnyObject]?)?
	
	/// When the asset was an image, it's false. Otherwise true.
	public private(set) var isVideo: Bool = false
	
    /// Returns location, if its contained in original asser
    public private(set) var location: CLLocation?
    
	/// play time duration(seconds) of a video.
	public private(set) var duration: Double?
	
	public private(set) var originalAsset: PHAsset?
    
    public var localIdentifier: String
		
	public init(originalAsset: PHAsset) {
        self.localIdentifier = originalAsset.localIdentifier
        self.location = originalAsset.location
		super.init()
		
		self.originalAsset = originalAsset
		
		let assetType = originalAsset.mediaType
		if assetType == .Video {
			self.isVideo = true
			self.duration = originalAsset.duration
		}
	}
	
	internal var image: UIImage?
	internal init(image: UIImage) {
        self.localIdentifier = String(image.hash)
		super.init()
        
		self.image = image
		self.fullScreenImage = (image, nil)
	}
	
    public override func isEqual(object: AnyObject?) -> Bool {
        if let another = object as? DKAsset {
            return self.localIdentifier == another.localIdentifier
        }
        return false
    }
	
	public func fetchImageWithSize(size: CGSize, completeBlock: (image: UIImage?, info: [NSObject: AnyObject]?) -> Void) {
		self.fetchImageWithSize(size, options: nil, completeBlock: completeBlock)
	}
	
	public func fetchImageWithSize(size: CGSize, options: PHImageRequestOptions?, completeBlock:(image: UIImage?, info: [NSObject: AnyObject]?) -> Void) {
		self.fetchImageWithSize(size, options: options, contentMode: .AspectFit, completeBlock: completeBlock)
	}
	
	public func fetchImageWithSize(size: CGSize, options: PHImageRequestOptions?, contentMode: PHImageContentMode, completeBlock: (image: UIImage?, info: [NSObject: AnyObject]?) -> Void) {
		if let _ = self.originalAsset {
			getImageManager().fetchImageForAsset(self, size: size, options: options, contentMode: contentMode, completeBlock: completeBlock)
		} else {
			completeBlock(image: self.image, info: nil)
		}
	}
	
	public func fetchFullScreenImageWithCompleteBlock(completeBlock: (image: UIImage?, info: [NSObject: AnyObject]?) -> Void) {
		self.fetchFullScreenImage(false, completeBlock: completeBlock)
	}
	
	/**
     Fetch an image with the current screen size.
     
     - parameter sync:          If true, the method blocks the calling thread until image is ready or an error occurs.
     - parameter completeBlock: The block is executed when the image download is complete.
	*/
	public func fetchFullScreenImage(sync: Bool, completeBlock: (image: UIImage?, info: [NSObject: AnyObject]?) -> Void) {
		if let (image, info) = self.fullScreenImage {
			completeBlock(image: image, info: info)
		} else {
			let screenSize = UIScreen.mainScreen().bounds.size
			
			let options = PHImageRequestOptions()
			options.deliveryMode = .HighQualityFormat
			options.resizeMode = .Exact
			options.synchronous = sync

			getImageManager().fetchImageForAsset(self, size: screenSize.toPixel(), options: options, contentMode: .AspectFit) { [weak self] image, info in
				guard let strongSelf = self else { return }
				
				strongSelf.fullScreenImage = (image, info)
				completeBlock(image: image, info: info)
			}
		}
	}
	
	public func fetchOriginalImageWithCompleteBlock(completeBlock: (image: UIImage?, info: [NSObject: AnyObject]?) -> Void) {
		self.fetchOriginalImage(false, completeBlock: completeBlock)
	}
	
	/**
     Fetch an image with the original size.
     
     - parameter sync:          If true, the method blocks the calling thread until image is ready or an error occurs.
     - parameter completeBlock: The block is executed when the image download is complete.
	*/
	public func fetchOriginalImage(sync: Bool, completeBlock: (image: UIImage?, info: [NSObject: AnyObject]?) -> Void) {
        if let _ = self.originalAsset {
            let options = PHImageRequestOptions()
            options.version = .Current
            options.synchronous = sync
            
            getImageManager().fetchImageDataForAsset(self, options: options, completeBlock: { (data, info) in
                var image: UIImage?
                if let data = data {
                    image = UIImage(data: data)
                }
                completeBlock(image: image, info: info)
            })
        } else {
            completeBlock(image: self.image, info: nil)
        }
	}
    
    /**
     Fetch an image data with the original size.
     
     - parameter sync:          If true, the method blocks the calling thread until image is ready or an error occurs.
     - parameter completeBlock: The block is executed when the image download is complete.
     */
    public func fetchImageDataForAsset(sync: Bool, completeBlock: (imageData: NSData?, info: [NSObject: AnyObject]?) -> Void) {
        let options = PHImageRequestOptions()
        options.version = .Current
        options.synchronous = sync
        
        getImageManager().fetchImageDataForAsset(self, options: options, completeBlock: { (data, info) in
            completeBlock(imageData: data, info: info)
        })
    }
	
    /**
     Fetch an AVAsset with a completeBlock.
	*/
	public func fetchAVAssetWithCompleteBlock(completeBlock: (AVAsset: AVAsset?, info: [NSObject: AnyObject]?) -> Void) {
		self.fetchAVAsset(nil, completeBlock: completeBlock)
	}
	
    /**
     Fetch an AVAsset with a completeBlock and PHVideoRequestOptions.
     */
	public func fetchAVAsset(options: PHVideoRequestOptions?, completeBlock: (AVAsset: AVAsset?, info: [NSObject: AnyObject]?) -> Void) {
		getImageManager().fetchAVAsset(self, options: options, completeBlock: completeBlock)
	}
	
    /**
     Sync fetch an AVAsset with a completeBlock and PHVideoRequestOptions.
     */
	public func fetchAVAsset(sync: Bool, options: PHVideoRequestOptions?, completeBlock: (AVAsset: AVAsset?, info: [NSObject: AnyObject]?) -> Void) {
		if sync {
			let semaphore = dispatch_semaphore_create(0)
			self.fetchAVAsset(options, completeBlock: { (AVAsset, info) -> Void in
				completeBlock(AVAsset: AVAsset, info: info)
                dispatch_semaphore_signal(semaphore)
			})
            dispatch_semaphore_wait(semaphore, dispatch_time_t(DISPATCH_TIME_FOREVER))
		} else {
			self.fetchAVAsset(options, completeBlock: completeBlock)
		}
	}
	
}

public extension DKAsset {
	
	struct DKAssetWriter {
		static let writeQueue: NSOperationQueue = {
			let queue = NSOperationQueue()
			queue.name = "DKAsset_Write_Queue"
			queue.maxConcurrentOperationCount = 5
			return queue
		}()
	}
	
	
    /**
     Writes the image in the receiver to the file specified by a given path.
     */
	public func writeImageToFile(path: String, completeBlock: (success: Bool) -> Void) {
        if let _ = self.originalAsset {
            let options = PHImageRequestOptions()
            options.version = .Current
            
            getImageManager().fetchImageDataForAsset(self, options: options, completeBlock: { (data, _) in
                DKAssetWriter.writeQueue.addOperationWithBlock({
                    if let imageData = data {
                        try! imageData.writeToURL(NSURL(fileURLWithPath: path), options: [.AtomicWrite])
                        completeBlock(success: true)
                    } else {
                        completeBlock(success: false)
                    }
                })
            })
        } else {
            try! UIImageJPEGRepresentation(self.image!, 1)!.writeToURL(NSURL(fileURLWithPath: path), options: [.AtomicWrite])
            completeBlock(success: true)
        }
	}
	
    /**
     Writes the AV in the receiver to the file specified by a given path.
     
     - parameter presetName:        An NSString specifying the name of the preset template for the export. See AVAssetExportPresetXXX.
     - parameter outputFileType:    Type of file to export. Should be a valid media type, otherwise export will fail. See AVFileType.
     */
    public func writeAVToFile(path: String, presetName: String, outputFileType: String = AVFileTypeQuickTimeMovie, completeBlock: (success: Bool) -> Void) {
		self.fetchAVAsset(nil) { (avAsset, _) in
            DKAssetWriter.writeQueue.addOperationWithBlock({
                if let avAsset = avAsset,
                    let exportSession = AVAssetExportSession(asset: avAsset, presetName: presetName) {
                    exportSession.outputFileType = outputFileType
                    exportSession.outputURL = NSURL(fileURLWithPath: path)
                    exportSession.shouldOptimizeForNetworkUse = true
                    exportSession.exportAsynchronouslyWithCompletionHandler({
                        completeBlock(success: exportSession.status == .Completed ? true : false)
                    })
                } else {
                    completeBlock(success: false)
                }
            })
        }
    }
}

public extension AVAsset {
	
	public func calculateFileSize() -> Float {
		if let URLAsset = self as? AVURLAsset {
			var size: AnyObject?
			try! (URLAsset.URL as NSURL).getResourceValue(&size, forKey: NSURLFileSizeKey)
			if let size = size as? NSNumber {
				return size.floatValue
			} else {
				return 0
			}
		} else if let _ = self as? AVComposition {
			var estimatedSize: Float = 0.0
			var duration: Float = 0.0
			for track in self.tracks {
				let rate = track.estimatedDataRate / 8.0
				let seconds = Float(CMTimeGetSeconds(track.timeRange.duration))
				duration += seconds
				estimatedSize += seconds * rate
			}
			return estimatedSize
		} else {
			return 0
		}
	}
    
}
