//
//  MenuController.swift
//  ConnectMe
//
//  Created by Austin Vaday on 12/20/15.
//  Copyright © 2015 ConnectMe. All rights reserved.
//
//  Code is owned by: Austin Vaday and Navid Sarvian


import UIKit
import AWSCognitoIdentityProvider

class MenuController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    enum MenuData: Int {
        case YOUR_ACCOUNT
        case LINKED_ACCOUNTS
        case NOTIFICATIONS
        case INVITE_FRIENDS
        case HELP
        case TERMS
        case CLEAR_HISTORY
        case LOG_OUT
    }
    
    override func viewDidLoad() {
        

    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 8
    }

    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier("menuCell") as! MenuTableViewCell!
        
        let menuOption = MenuData(rawValue: indexPath.row)!
        
        switch (menuOption)
        {
        case .YOUR_ACCOUNT:
            cell.cellName.text = "Your Account"
            break;
        case .LINKED_ACCOUNTS:
            cell.cellName.text = "Linked Social Media Accounts"
            break;
        case .NOTIFICATIONS:
            cell.cellName.text = "Notification Settings"
            break;
        case .INVITE_FRIENDS:
            cell.cellName.text = "Invite Friends"
            break;
        case .HELP:
            cell.cellName.text = "Help & About Us"
            break;
        case .TERMS:
            cell.cellName.text = "Terms of Service"
            break;
        case .CLEAR_HISTORY:
            cell.cellName.text = "Clear Search History"
            break;
        case .LOG_OUT:
            cell.cellName.text = "Log Out"
            break;
    
//        default:
//            cell.cellName.text = "Error"
//            break;
        }
        

        
        return cell
        
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        let menuOption = MenuData(rawValue: indexPath.row)!
        
        switch (menuOption)
        {
        case .YOUR_ACCOUNT:
            
            self.performSegueWithIdentifier("yourAccountSegue", sender: nil)
            break;
        case .LINKED_ACCOUNTS:
            self.performSegueWithIdentifier("linkedAccountsSegue", sender: nil)
            break;
        case .NOTIFICATIONS:
            self.performSegueWithIdentifier("notificationSegue", sender: nil)
            break;
        case .INVITE_FRIENDS:
            self.performSegueWithIdentifier("inviteFriendsSegue", sender: nil)
            break;
        case .HELP:
            self.performSegueWithIdentifier("helpSegue", sender: nil)
            break;
        case .TERMS:
            self.performSegueWithIdentifier("termsSegue", sender: nil)
            break;
        case .CLEAR_HISTORY:
            self.performSegueWithIdentifier("clearHistorySegue", sender: nil)
            break;
        case .LOG_OUT:
            logUserOut()
            break;
//        default:
//            break;
        }
    }
    
    
    func logUserOut()
    {
        
        // Ask user if they really want to log out...
        let alert = UIAlertController(title: nil, message: "Are you really sure you want to log out?", preferredStyle: UIAlertControllerStyle.Alert)
        
        let logOutAction = UIAlertAction(title: "Log out", style: UIAlertActionStyle.Default) { (UIAlertAction) -> Void in
            
            // present the log in home page
            
            //TODO: Add spinner functionality
            self.performSegueWithIdentifier("logOut", sender: nil)
            
            // Log out AWS
            
            
            
            
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Default, handler: nil)
        
        alert.addAction(logOutAction)
        alert.addAction(cancelAction)
        
        self.showViewController(alert, sender: nil)
    }
}
