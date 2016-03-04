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
    let defaultRowHeight:CGFloat = 60
    let expandedRowHeight:CGFloat = 100
    let socialMediaNameList = Array<String>(arrayLiteral: "phone", "facebook", "youtube", "twitter", "skype", "linkedin")
    var socialMediaImageList : Array<UIImage>! // An array of social media emblem images
//    let socialMediaImageList = Array<UIImage>(arrayLiteral: UIImage(named: "phone")!, UIImage(named: "facebook")!, UIImage(named:"youtube")!, UIImage(named:"twitter")!, UIImage(named:"skype")!, UIImage(named:"linkedin")!)
    
    
    override func viewDidLoad() {
    
        var imageName:String!
        var newUIImage:UIImage!
        let size = socialMediaNameList.count
        
        socialMediaImageList = Array<UIImage>()
        
        // Generate all necessary images for the emblems
        for (var i = 0; i < size; i++)
        {
            print("OK!")

            // Fetch emblem name
            imageName = socialMediaNameList[i]
            
            // Generate image
            newUIImage = UIImage(named: imageName)!
            
            // Store image
            socialMediaImageList.append(newUIImage)
        }
        
    }
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
        

        return socialMediaNameList.count
        
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        print("COLLECTIONVIEW 2")
        

        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("collectionViewCell", forIndexPath: indexPath) as! SocialMediaCollectionViewCell

        let socialMediaName = socialMediaNameList[indexPath.item % self.socialMediaNameList.count]
        
        // We will delay the image assignment to prevent buggy race conditions
        // (Check to see what happens when the delay is not set... then you'll understand)
        // Probable cause: tableView.beginUpdates() and tableView.endUpdates() in tableView(didSelectIndexPath) method
        delay(0) { () -> () in
            
            // Set social media emblem

            
            // Generate a UI image for the respective social media type
            cell.emblemImage.image = self.socialMediaImageList[indexPath.item % self.socialMediaImageList.count]
            cell.socialMediaName = socialMediaName
            
            
            /* Don't use the below, will cause images to reset when button is clicked. */
            //cell.emblemButton.imageView?.image = self.emblemImageRange[indexPath.item % 4]
        }

        // Make cell image circular
        cell.layer.cornerRadius = cell.frame.width / 2
        
        // Make cell movements cleaner (increased FPM)
        cell.layer.shouldRasterize = true
        
        return cell
    }


//    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
//        print("SELECTED ITEM AT ", indexPath.item)
//
//    }
    
    func collectionView(collectionView: UICollectionView, didHighlightItemAtIndexPath indexPath: NSIndexPath) {
        print("SELECTED ITEM AT ", indexPath.item)
        
        let cell = collectionView.cellForItemAtIndexPath(indexPath) as! SocialMediaCollectionViewCell

        let socialMediaName = cell.socialMediaName
        
        
        
        print(socialMediaName)
        print ("CELL SIZE IS: ", cell.frame.size.width)
        print ("IMAGE SIZE IS: ",cell.emblemImage.frame.size.width)
    }

    


}



