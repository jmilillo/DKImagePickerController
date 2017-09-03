//
//  CustomFlowLayout.swift
//  DKImagePickerControllerDemo
//
//  Created by ZhangAo on 03/01/2017.
//  Copyright © 2017 ZhangAo. All rights reserved.
//

import UIKit

public class CustomFlowLayout: UICollectionViewFlowLayout {
    
    public override func prepareLayout() {
        super.prepareLayout()
        
        self.scrollDirection = .Horizontal
        
        let contentWidth = self.collectionView!.bounds.width * 0.7
        self.itemSize = CGSize(width: contentWidth, height: contentWidth)
        
        self.minimumInteritemSpacing = 999
    }
    
}
