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

class RecentConnections: UIViewController, UITableViewDelegate, UITableViewDataSource {

    let NO_ROW = -1
    @IBOutlet weak var recentConnTableView: UITableView!
    var selectedRowIndex:Int = -1
    var expandedRow:Int = -1
    var isARowExpanded:Bool = false
    let defaultRowHeight:CGFloat = 60
    let expandedRowHeight:CGFloat = 120
    
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        // TODO: If more than one user,
        // Display up to 30 users immediately
        // Display 20 more if user keeps sliding down
        
        return 50
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier("recentConnCell", forIndexPath: indexPath) as! TableViewCell
        
        // Ensure that internal cellImage is circular
        cell.cellImage.layer.cornerRadius = cell.cellImage.frame.size.width / 2

        // Set the user name
        cell.cellName.text = "User " + String(indexPath.row)
        
        
        return cell
        
    }
    
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        // Set the new selectedRowIndex
        selectedRowIndex = indexPath.row
        
        // Update UI with animation
        tableView.beginUpdates()
        tableView.endUpdates()
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        
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
    


}



