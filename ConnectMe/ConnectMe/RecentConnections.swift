//
//  RecentConnections.swift
//  ConnectMe
//
//  Created by Austin Vaday on 12/31/15.
//  Copyright © 2015 ConnectMe. All rights reserved.
//
//  Code is owned by: Austin Vaday and Navid Sarvian

import UIKit
import Parse

class RecentConnections: UIViewController, UITableViewDelegate, UITableViewDataSource, UICollectionViewDelegate, UICollectionViewDataSource {

    let NO_ROW = -1
    @IBOutlet weak var recentConnTableView: UITableView!
    var selectedRowIndex:Int = -1
    var expandedRow:Int = -1
    var isARowExpanded:Bool = false
    let defaultRowHeight:CGFloat = 100
    let expandedRowHeight:CGFloat = 60
    let emblemImageRange = Array<UIImage>(arrayLiteral: UIImage(named: "facebook")!, UIImage(named:"youtube")!, UIImage(named:"twitter")!, UIImage(named:"skype")!, UIImage(named:"linkedin")!)
    
    
    // TABLE VIEW
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        // TODO: If more than one user,
        // Display up to 30 users immediately
        // Display 20 more if user keeps sliding down
        
        print("TABLEVIEW 1")
        return 50
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        print("TABLEVIEW 2")

        let cell = tableView.dequeueReusableCellWithIdentifier("recentConnCell", forIndexPath: indexPath) as! TableViewCell
        
        // Ensure that internal cellImage is circular
        cell.cellImage.layer.cornerRadius = cell.cellImage.frame.size.width / 2

        // Set the user name
        cell.cellName.text = "User " + String(indexPath.row)
        
        
        return cell
        
    }
    
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        print("TABLEVIEW 3")

        // Set the new selectedRowIndex
        selectedRowIndex = indexPath.row
        
        // Update UI with animation
        tableView.beginUpdates()
        tableView.endUpdates()
        

//        let cell = tableView.dequeueReusableCellWithIdentifier("recentConnCell", forIndexPath: indexPath) as! TableViewCell
//
//        cell.collectionView.reloadData()
    
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        print("TABLEVIEW 4")

        let currentRow = indexPath.row
        
        // If a row is selected, we want to expand the cells
        if (currentRow == selectedRowIndex)
        {
            // Collapse if it is already expanded
            if (isARowExpanded && expandedRow == currentRow)
            {
                isARowExpanded = false
                expandedRow = NO_ROW
                return defaultRowHeight
            }
            else
            {
                isARowExpanded = true
                expandedRow = currentRow
                return expandedRowHeight
            }
        }
        else
        {
            return defaultRowHeight
        }
        
    }
    
    // COLLECTION VIEW
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        print("COLLECTIONVIEW 1")
        

        return 20
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        print("COLLECTIONVIEW 2")
        

        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("collectionViewCell", forIndexPath: indexPath) as! SocialMediaCollectionViewCell

        // We will delay the image assignment to prevent buggy race conditions
        // (Check to see what happens when the delay is not set... then you'll understand)
        // Probable cause: tableView.beginUpdates() and tableView.endUpdates() in tableView(didSelectIndexPath) method
        delay(0) { () -> () in
            
            // Set social media emblem
            cell.emblemButton.imageView?.image = self.emblemImageRange[indexPath.item % 4]

        }

        // Make cell circular
        cell.layer.cornerRadius = cell.frame.width / 2
        
        // Make cell movements cleaner (increased FPM)
        cell.layer.shouldRasterize = true
        
        return cell
    }



    


}



