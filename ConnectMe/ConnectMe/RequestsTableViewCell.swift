//
//  RequestsTableViewCell.swift
//  Aquaint
//
//  Created by Austin Vaday on 4/10/16.
//  Copyright © 2016 ConnectMe. All rights reserved.
//

import UIKit

class RequestsTableViewCell: UITableViewCell {
    
    @IBOutlet weak var cellImage: UIImageView!
    @IBOutlet weak var cellName: UILabel!
    @IBOutlet weak var cellAddButton: UIButton!
    @IBOutlet weak var cellAddPendingButton: UIButton!
    @IBOutlet weak var cellDeleteButton: UIButton!
    @IBOutlet weak var cellUserName: UILabel!
    let firebaseRootRefString = "https://torrid-fire-8382.firebaseio.com/"

}
