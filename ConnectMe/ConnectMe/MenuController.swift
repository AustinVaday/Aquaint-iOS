//
//  MenuController.swift
//  ConnectMe
//
//  Created by Austin Vaday on 12/20/15.
//  Copyright © 2015 ConnectMe. All rights reserved.
//
//  Code is owned by: Austin Vaday and Navid Sarvian


import UIKit

class MenuController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    @IBOutlet weak var testLabel: UILabel!

    
    override func viewDidLoad() {
        
        
        
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 6
    }

    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier("menuCell") as! MenuTableViewCell!
        
        switch (indexPath.row)
        {
        case 0:
            cell.cellName.text = "Your Account"
            break;
        case 1:
            cell.cellName.text = "Linked Social Media Accounts"
            break;
        case 2:
            cell.cellName.text = "Notification Settings"
            break;
        case 3:
            cell.cellName.text = "Invite Friends"
            break;
        case 4:
            cell.cellName.text = "Help & About Us"
            break;
        case 5:
            cell.cellName.text = "Log Out"
            break;
    
        default:
            cell.cellName.text = "Error"
        
        }
        

        
        return cell
        
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
    }
}
