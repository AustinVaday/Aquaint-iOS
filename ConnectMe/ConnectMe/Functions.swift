//
//  Functions.swift
//  ConnectMe
//
//  Created by Austin Vaday on 1/16/16.
//  Copyright © 2016 ConnectMe. All rights reserved.
//

import Foundation
import UIKit

// Implements a delay. 
// Usage: delay([num_sec]){ [Code after delay] }
func delay(delay:Double, closure:()->()) {
    dispatch_after(
        dispatch_time(
            DISPATCH_TIME_NOW,
            Int64(delay * Double(NSEC_PER_SEC))
        ),
        dispatch_get_main_queue(), closure)
}

// Flips any image horizontally
func flipImageHorizontally(imageView:UIImageView)
{
    imageView.transform = CGAffineTransformMakeScale(-1.0, 1.0)
}

// Flips any image vertically
func flipImageVertically(imageView:UIImageView)
{
    imageView.transform = CGAffineTransformMakeScale(1.0, -1.0)
}

