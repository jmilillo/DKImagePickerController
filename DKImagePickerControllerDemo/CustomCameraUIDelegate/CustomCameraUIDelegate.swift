//
//  CustomCamera.swift
//  DKImagePickerControllerDemo
//
//  Created by ZhangAo on 16/3/17.
//  Copyright © 2016年 ZhangAo. All rights reserved.
//

import UIKit

public class CustomCameraUIDelegate: DKImagePickerControllerDefaultUIDelegate {
	
    public override func imagePickerControllerCreateCamera(imagePickerController: DKImagePickerController) -> UIViewController {
        let picker = CustomCamera()
        
        return picker
    }
    
}
