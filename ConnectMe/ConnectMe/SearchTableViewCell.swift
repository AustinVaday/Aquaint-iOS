//
//  TableViewCell.swift
//  ConnectMe
//
//  Created by Austin Vaday on 12/31/15.
//  Copyright © 2015 ConnectMe. All rights reserved.
//
//  Code is owned by: Austin Vaday and Navid Sarvian

import UIKit

class SearchTableViewCell: UITableViewCell {
    
    @IBOutlet weak var cellImage: UIImageView!
    @IBOutlet weak var cellName: UILabel!
    @IBOutlet weak var cellAddButton: UIButton!
    @IBOutlet weak var cellUserName: UILabel!
    
    @IBAction func onAddConnectionButtonClicked(sender: UIButton) {
        
        print("You clicked on", cellName.text)
    }
    
    
}
