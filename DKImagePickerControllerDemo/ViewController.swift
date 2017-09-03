//
//  ViewController.swift
//  DKImagePickerControllerDemo
//
//  Created by ZhangAo on 14-10-1.
//  Copyright (c) 2014年 ZhangAo. All rights reserved.
//

import UIKit
import Photos
import AVKit

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate {

    var pickerController: DKImagePickerController!
    
    @IBOutlet var previewView: UICollectionView?
    var assets: [DKAsset]?
    
	func showImagePicker() {
		pickerController.defaultSelectedAssets = self.assets
        
        pickerController.didCancel = { ()
            print("didCancel")
        }
        
		pickerController.didSelectAssets = { [unowned self] (assets: [DKAsset]) in
            self.updateAssets(assets)
		}
		
		if UI_USER_INTERFACE_IDIOM() == .Pad {
			pickerController.modalPresentationStyle = .FormSheet
		}
		
        // turn on the swipe selection feature
        // self.pickerController.allowSwipeToSelect = true
		
        if pickerController.inline {
            self.showInlinePicker()
        } else {
            self.presentViewController(pickerController, animated: true, completion: nil)
        }
	}
    
    func updateAssets(assets: [DKAsset]) {
        print("didSelectAssets")
        
        self.assets = assets
        self.previewView?.reloadData()
    }
	
    func playVideo(asset: AVAsset) {
		let avPlayerItem = AVPlayerItem(asset: asset)
		
		let avPlayer = AVPlayer(playerItem: avPlayerItem)
		let player = AVPlayerViewController()
		player.player = avPlayer
		
        avPlayer.play()
		
		self.presentViewController(player, animated: true, completion: nil)
    }
    
    // MARK: - UITableViewDataSource, UITableViewDelegate methods
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath)
        
        cell.textLabel?.text = "Start"
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
		
		showImagePicker()
	}
	
    // MARK: - UICollectionViewDataSource, UICollectionViewDelegate methods
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.assets?.count ?? 0
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let asset = self.assets![indexPath.row]
		var cell: UICollectionViewCell?
		var imageView: UIImageView?
		
        if asset.isVideo {
            cell = collectionView.dequeueReusableCellWithReuseIdentifier("CellVideo", forIndexPath: indexPath)
			imageView = cell?.contentView.viewWithTag(1) as? UIImageView
        } else {
            cell = collectionView.dequeueReusableCellWithReuseIdentifier("CellImage", forIndexPath: indexPath)
            imageView = cell?.contentView.viewWithTag(1) as? UIImageView
        }
		
		if let cell = cell, let imageView = imageView {
			let layout = collectionView.collectionViewLayout as! UICollectionViewFlowLayout
			let tag = indexPath.row + 1
			cell.tag = tag
			asset.fetchImageWithSize(layout.itemSize.toPixel(), completeBlock: { image, info in
				if cell.tag == tag {
					imageView.image = image
				}
			})
		}
		
		return cell!
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let asset = self.assets![indexPath.row]
		asset.fetchAVAssetWithCompleteBlock { (avAsset, info) in
            dispatch_async(dispatch_get_global_queue(0, 0), {
				self.playVideo(avAsset!)
			})
		}
    }
    
    // Inline Mode
    
    func showInlinePicker() {
        let pickerView = self.pickerController.view!
        pickerView.frame = CGRect(x: 0, y: 170, width: self.view.bounds.width, height: 200)
        self.view.addSubview(pickerView)
        
        let doneButton = UIButton(type: .Custom)
        doneButton.setTitleColor(UIColor.blueColor(), forState: .Normal)
        doneButton.addTarget(self, action: #selector(done), forControlEvents: .TouchUpInside)
        doneButton.frame = CGRect(x: 0, y: pickerView.frame.maxY, width: pickerView.bounds.width / 2, height: 50)
        self.view.addSubview(doneButton)
        self.pickerController.selectedChanged = { [unowned self] in
            self.updateDoneButtonTitle(doneButton)
        }
        self.updateDoneButtonTitle(doneButton)
        
        let albumButton = UIButton(type: .Custom)
        albumButton.setTitleColor(UIColor.blueColor(), forState: .Normal)
        albumButton.setTitle("Album", forState: .Normal)
        albumButton.addTarget(self, action: #selector(showAlbum), forControlEvents: .TouchUpInside)
        albumButton.frame = CGRect(x: doneButton.frame.maxX, y: doneButton.frame.minY, width: doneButton.bounds.width, height: doneButton.bounds.height)
        self.view.addSubview(albumButton)
    }
    
    func updateDoneButtonTitle(doneButton: UIButton) {
        doneButton.setTitle("Done(\(self.pickerController.selectedAssets.count))", forState: .Normal)
    }
    
    func done() {
        self.updateAssets(self.pickerController.selectedAssets)
    }
    
    func showAlbum() {
        let pickerController = DKImagePickerController()
        pickerController.defaultSelectedAssets = self.pickerController.selectedAssets
        pickerController.didSelectAssets = { [unowned self] (assets: [DKAsset]) in
            self.updateAssets(assets)
            self.pickerController.defaultSelectedAssets = assets
        }
        
        self.presentViewController(pickerController, animated: true, completion: nil)
    }

}

