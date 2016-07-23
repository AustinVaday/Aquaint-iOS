//
//  NewsfeedTableViewCell.swift
//  Aquaint
//
//  Created by Austin Vaday on 4/30/16.
//  Copyright © 2016 ConnectMe. All rights reserved.
//

import UIKit

class NewsfeedTableViewCell: UITableViewCell {
    
    @IBOutlet weak var cellImage: UIImageView!
    @IBOutlet weak var cellMessage: UILabel!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var cellUserName: UILabel!
    @IBOutlet weak var cellTimeConnected: UILabel!
    @IBOutlet weak var caretImageView: UIImageView!
    @IBOutlet weak var sponsoredProfileImageView: UIImageView!
    
    
//    override init(style: UITableViewCellStyle, reuseIdentifier: String? )
//    {
//        super.init(style: style, reuseIdentifier: reuseIdentifier)
//
//        // Make cell image views circular
//        sponsoredProfileImageView.layer.cornerRadius = sponsoredProfileImageView.frame.width / 2
//        cellImage.layer.cornerRadius = cellImage.frame.width / 2
//
//    }
//    
//    required init?(coder aDecoder: NSCoder) {
//        super.init(coder: aDecoder)!
//    }
    
    func rotateCaret180Degrees()
    {
        
        print("ROTATE")
        
        caretImageView.transform = CGAffineTransformRotate(caretImageView.transform, CGFloat(M_PI))
    }
}
