//
//  CameraButtonCell.swift
//  BSImagePicker
//
//  Created by Sam Ritchie on 29/09/2015.
//  Copyright © 2015 codesplice pty ltd. All rights reserved.
//

import UIKit

class CameraButtonCell: UICollectionViewCell {
    @IBOutlet var cameraButton: UIButton!
    
    override func hitTest(point: CGPoint, withEvent event: UIEvent?) -> UIView? {
        for subView in subviews {
            let view = subView.hitTest(subView.convertPoint(point, fromView: self), withEvent: event)
            if view != nil{
                return view
            }
        }
        return super.hitTest(point, withEvent: event)
    }
}
