//
//  DropDownTableViewFunctions.swift
//  Aquaint
//
//  Created by Austin Vaday on 7/22/16.
//  Copyright © 2016 ConnectMe. All rights reserved.
//

import UIKit
import Foundation

// Struct used to encapsulate cell necessary expansion/collapse variables
struct CellExpansion {
    
    var selectedRowIndex:Int = -1
    var expandedRow:Int = -1
    var isARowExpanded:Bool = false
    
    let NO_ROW = -1
    let defaultRowHeight:CGFloat = 60
    let expandedRowHeight:CGFloat = 120
}

// Pass expansionObject by reference: so we can maintain the corresponding updated values
func getTableRowHeightForDropdownCell(inout expansionObject: CellExpansion!, currentRow: Int) -> CGFloat
{
    // If a row is selected, we want to expand the cells
    if (currentRow == expansionObject.selectedRowIndex)
    {
        // Collapse if it is already expanded
        if (expansionObject.isARowExpanded && expansionObject.expandedRow == currentRow)
        {
            expansionObject.isARowExpanded = false
            expansionObject.expandedRow = expansionObject.NO_ROW
            return expansionObject.defaultRowHeight
        }
        else
        {
            expansionObject.isARowExpanded = true
            expansionObject.expandedRow = currentRow
            return expansionObject.expandedRowHeight
        }
    }
    else
    {
        return expansionObject.defaultRowHeight
    }
    
}

func updateCurrentlyExpandedRow(inout expansionObject: CellExpansion!, currentRow: Int)
{
    // Set the new selectedRowIndex
    expansionObject.selectedRowIndex = currentRow
}
