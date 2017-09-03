//
//  DKGroupDataManager.swift
//  DKImagePickerControllerDemo
//
//  Created by ZhangAo on 15/12/16.
//  Copyright © 2015年 ZhangAo. All rights reserved.
//

import Photos

@objc
protocol DKGroupDataManagerObserver {
	
	@objc optional func groupDidUpdate(groupId: String)
	@objc optional func groupDidRemove(groupId: String)
	@objc optional func group(groupId: String, didRemoveAssets assets: [DKAsset])
	@objc optional func group(groupId: String, didInsertAssets assets: [DKAsset])
    @objc optional func groupDidUpdateComplete(groupId: String)
    @objc optional func groupsDidInsert(groupIds: [String])
}

public class DKGroupDataManager: DKBaseManager, PHPhotoLibraryChangeObserver {

    public var groupIds: [String]?
	private var groups: [String : DKAssetGroup]?
    private var assets = [String: DKAsset]()
	
	public var assetGroupTypes: [PHAssetCollectionSubtype]?
	public var assetFetchOptions: PHFetchOptions?
	public var showsEmptyAlbums: Bool = true

    public var assetFilter: ((asset: PHAsset) -> Bool)?
	
	deinit {
        PHPhotoLibrary.sharedPhotoLibrary().unregisterChangeObserver(self)
	}
	
	public func invalidate() {
		self.groupIds?.removeAll()
        self.groups?.removeAll()
        self.assets.removeAll()
		
		PHPhotoLibrary.sharedPhotoLibrary().unregisterChangeObserver(self)
	}

	public func fetchGroups(completeBlock: (groups: [String]?, error: NSError?) -> Void) {
		if let assetGroupTypes = self.assetGroupTypes {
            dispatch_async(dispatch_get_global_queue(0, 0), {
                [weak self] in
                guard let strongSelf = self else {
                    return
                }
                
                guard strongSelf.groups == nil else {
                    dispatch_async(dispatch_get_main_queue(), {
                        completeBlock(groups: strongSelf.groupIds, error: nil)
                    })
                    return
                }
                
                var groups: [String : DKAssetGroup] = [:]
                var groupIds: [String] = []
                
                strongSelf.fetchGroups(assetGroupTypes, block: { (collection) in
                    let assetGroup = strongSelf.makeDKAssetGroup(with: collection)
                    if strongSelf.showsEmptyAlbums || assetGroup.totalCount > 0 {
                        groups[assetGroup.groupId] = assetGroup
                        groupIds.append(assetGroup.groupId)
                    }
                    if !groupIds.isEmpty {
                        strongSelf.updatePartial(groups, groupIds: groupIds, completeBlock: completeBlock)
                    }
                })
                PHPhotoLibrary.sharedPhotoLibrary().registerChangeObserver(strongSelf)
                if !groupIds.isEmpty {
                    strongSelf.updatePartial(groups, groupIds: groupIds, completeBlock: completeBlock)
                }
            })
		}
	}
	
	public func fetchGroupWithGroupId(groupId: String) -> DKAssetGroup {
		return self.groups![groupId]!
	}
	
	public func fetchGroupThumbnailForGroup(groupId: String, size: CGSize, options: PHImageRequestOptions, completeBlock: (image: UIImage?, info: [NSObject: Any]?) -> Void) {
		let group = self.fetchGroupWithGroupId(groupId)
		if group.totalCount == 0 {
			completeBlock(image: nil, info: nil)
			return
		}
		
		let latestAsset = DKAsset(originalAsset:group.fetchResult.lastObject! as! PHAsset)
		latestAsset.fetchImageWithSize(size, options: options, completeBlock: completeBlock)
	}
	
	public func fetchAsset(group: DKAssetGroup, index: Int) -> DKAsset {
        let originalAsset = self.fetchOriginalAsset(group, index: index)
        var asset = self.assets[originalAsset.localIdentifier]
        if asset == nil {
            asset = DKAsset(originalAsset:originalAsset)
            self.assets[originalAsset.localIdentifier] = asset
        }
		return asset!
	}
    
    public func fetchOriginalAsset(group: DKAssetGroup, index: Int) -> PHAsset {
        return group.fetchResult[group.totalCount - index - 1] as! PHAsset
    }
	
	// MARK: - Private methods
    
    private func makeDKAssetGroup(with collection: PHAssetCollection) -> DKAssetGroup {
        let assetGroup = DKAssetGroup()
        assetGroup.groupId = collection.localIdentifier
        self.updateGroup(assetGroup, collection: collection)
        self.updateGroup(assetGroup, fetchResult: PHAsset.fetchAssetsInAssetCollection(collection, options: self.assetFetchOptions))
        
        return assetGroup
    }
    
    private func collectionTypeForSubtype(subtype: PHAssetCollectionSubtype) -> PHAssetCollectionType {
        return subtype.rawValue < PHAssetCollectionSubtype.SmartAlbumGeneric.rawValue ? .Album : .SmartAlbum
    }
    
    private func fetchGroups(assetGroupTypes: [PHAssetCollectionSubtype], block: (PHAssetCollection) -> Void) {
        for (_, groupType) in assetGroupTypes.enumerate() {
            let fetchResult = PHAssetCollection.fetchAssetCollectionsWithType(self.collectionTypeForSubtype(groupType),
                                                                              subtype: groupType,
                                                                              options: nil)
            fetchResult.enumerateObjectsUsingBlock({ (collection, index, stop) in
                block(collection as! PHAssetCollection)
            })
        }
    }
    
    private func updatePartial(groups: [String : DKAssetGroup], groupIds: [String], completeBlock: (groups: [String]?, error: NSError?) -> Void) {
        self.groups = groups
        self.groupIds = groupIds
        dispatch_async(dispatch_get_main_queue()) {
            completeBlock(groups: groupIds, error: nil)
        }
    }
	
	private func updateGroup(group: DKAssetGroup, collection: PHAssetCollection) {
		group.groupName = collection.localizedTitle
		group.originalCollection = collection
	}
	
	private func updateGroup(group: DKAssetGroup, fetchResult: PHFetchResult) {
        group.fetchResult = filterResults(fetchResult)
		group.totalCount = group.fetchResult.count
	}
	
    private func filterResults(fetchResult: PHFetchResult) -> PHFetchResult {
        guard let filter = assetFilter else { return fetchResult }
        
        var filtered = [PHAsset]()
        for i in 0..<fetchResult.count {
            if filter(asset: fetchResult[i] as! PHAsset) {
                filtered.append(fetchResult[i] as! PHAsset)
            }
        }

        let collection = PHAssetCollection.transientAssetCollectionWithAssets(filtered, title: nil)
        return PHAsset.fetchAssetsInAssetCollection(collection, options: nil)
    }
    
	// MARK: - PHPhotoLibraryChangeObserver methods
	
	public func photoLibraryDidChange(changeInstance: PHChange) {
        for group in self.groups!.values {
			if let changeDetails = changeInstance.changeDetailsForObject(group.originalCollection) {
				if changeDetails.objectWasDeleted {
					self.groups![group.groupId] = nil
					self.notifyObserversWithSelector(#selector(DKGroupDataManagerObserver.groupDidRemove(_:)), object: group.groupId as AnyObject?)
					continue
				}
				
				if let objectAfterChanges = changeDetails.objectAfterChanges as? PHAssetCollection {
					self.updateGroup(self.groups![group.groupId]!, collection: objectAfterChanges)
					self.notifyObserversWithSelector(#selector(DKGroupDataManagerObserver.groupDidUpdate(_:)), object: group.groupId as AnyObject?)
				}
			}
			
			if let changeDetails = changeInstance.changeDetailsForFetchResult(group.fetchResult) {
                let removedAssets = changeDetails.removedObjects.map{ DKAsset(originalAsset: $0 as! PHAsset) }
				if removedAssets.count > 0 {
					self.notifyObserversWithSelector(#selector(DKGroupDataManagerObserver.group(_:didRemoveAssets:)), object: group.groupId as AnyObject?, objectTwo: removedAssets as AnyObject?)
				}
				self.updateGroup(group, fetchResult: changeDetails.fetchResultAfterChanges)
				
                let insertedAssets = changeDetails.insertedObjects.map{ DKAsset(originalAsset: $0 as! PHAsset) }
				if insertedAssets.count > 0  {
					self.notifyObserversWithSelector(#selector(DKGroupDataManagerObserver.group(_:didInsertAssets:)), object: group.groupId as AnyObject?, objectTwo: insertedAssets as AnyObject?)
				}
                
                self.notifyObserversWithSelector(#selector(DKGroupDataManagerObserver.groupDidUpdateComplete(_:)), object: group.groupId as AnyObject?)
			}
		}
        
        if let assetGroupTypes = self.assetGroupTypes {
            var insertedGroupIds: [String] = []
            
            self.fetchGroups(assetGroupTypes, block: { (collection) in
                if (self.groups![collection.localIdentifier] == nil) {
                    let assetGroup = self.makeDKAssetGroup(with: collection)
                    self.groups![assetGroup.groupId] = assetGroup
                    self.groupIds!.append(assetGroup.groupId)
                    
                    insertedGroupIds.append(assetGroup.groupId)
                }
            })
            
            if (insertedGroupIds.count > 0) {
                self.notifyObserversWithSelector(#selector(DKGroupDataManagerObserver.groupsDidInsert(_:)), object: insertedGroupIds as AnyObject)
            }
        }
	}

}
