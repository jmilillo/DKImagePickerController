//
//  CustomLayoutUIDelegate.swift
//  DKImagePickerControllerDemo
//
//  Created by ZhangAo on 03/01/2017.
//  Copyright © 2017 ZhangAo. All rights reserved.
//

import UIKit

public class CustomLayoutUIDelegate: DKImagePickerControllerDefaultUIDelegate {
    
    override public func layoutForImagePickerController(imagePickerController: DKImagePickerController) -> UICollectionViewLayout.Type {
        return CustomFlowLayout.self
    }
    
}
