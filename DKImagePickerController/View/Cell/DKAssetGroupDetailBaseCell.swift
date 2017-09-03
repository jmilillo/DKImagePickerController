//
//  DKAssetGroupDetailBaseCell.swift
//  DKImagePickerControllerDemo
//
//  Created by ZhangAo on 03/01/2017.
//  Copyright © 2017 ZhangAo. All rights reserved.
//

import UIKit

@objc
public class DKAssetGroupDetailBaseCell: UICollectionViewCell, DKAssetGroupCellItemProtocol {
    
    // This method must be overridden
    public class func cellReuseIdentifier() -> String { preconditionFailure("This method must be overridden") }
    
    public weak var asset: DKAsset?
    public var index: Int = 0
    public var thumbnailImage: UIImage!
}
