//
//  CustomGroupDetailImageCell.swift
//  DKImagePickerController
//
//  Created by ZhangAo on 03/01/2017.
//  Copyright © 2017 ZhangAo. All rights reserved.
//

import UIKit

class CustomGroupDetailImageCell: DKAssetGroupDetailBaseCell {
    
    class override func cellReuseIdentifier() -> String {
        return "CustomGroupDetailImageCell"
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.thumbnailImageView.frame = self.bounds
        self.thumbnailImageView.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        self.contentView.addSubview(self.thumbnailImageView)
        
        self.checkView.frame = self.bounds
        self.checkView.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        self.contentView.addSubview(self.checkView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var thumbnailImage: UIImage? {
        didSet {
            self.thumbnailImageView.image = self.thumbnailImage
        }
    }

    lazy var thumbnailImageView: UIImageView = {
        let thumbnailImageView = UIImageView()
        thumbnailImageView.contentMode = .ScaleAspectFill
        thumbnailImageView.clipsToBounds = true
        
        return thumbnailImageView
    }()
    
    lazy var checkView: UIImageView = {
        let checkView = UIImageView(image: DKImageResource.blueTickImage())
        checkView.contentMode = .Center
        
        return checkView
    }()

    override var selected: Bool {
        didSet {
            if super.selected {
                self.thumbnailImageView.alpha = 0.5
                self.checkView.hidden = false
            } else {
                self.thumbnailImageView.alpha = 1
                self.checkView.hidden = true
            }
        }
    }

}
