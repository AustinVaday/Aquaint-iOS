//
//  CustomSearchBar.swift
//  Pods
//
//  Created by Austin Vaday on 7/19/16.
//
//

import UIKit

class CustomSearchBar: UISearchBar {
    
    var preferredFont: UIFont!
    var preferredTextColor: UIColor!
    
    // Custom initialize for our class
    init(frame: CGRect, font: UIFont, textColor: UIColor)
    {
        super.init(frame: frame)
        self.frame = frame
        
        preferredFont = font
        preferredTextColor = textColor
        
        // Configure search bar -- results in translucent bg and opaque search field
        searchBarStyle = UISearchBarStyle.Prominent
        
        // Take out translucent bg
        translucent = false
        
        
    }

    // Required initializer...
    required init(coder someDecoder: NSCoder)
    {
        super.init(coder: someDecoder)!
    }
    
    
    // Set up the UI for the custom search bar
    override func drawRect(rect: CGRect)
    {
        // Find the index of the search field in the search bar subviews
        if let index = indexOfSearchFieldInSubviews()
        {
            // Access the search field
            let searchField: UITextField = (subviews[0]).subviews[index] as! UITextField
            
            // Set its frame.
            searchField.frame = CGRectMake(5.0, 5.0, frame.size.width - 10.0, frame.size.height - 10.0)

            // Set the font and text color of the search field.
            searchField.font = preferredFont
            searchField.textColor = preferredTextColor
            
            // Set the background color of the search field.
            searchField.backgroundColor = barTintColor
        }
        
        // Add line to bottom of search field
        let startPoint = CGPointMake(0.0, frame.size.height)
        let endPoint = CGPointMake(frame.size.width, frame.size.height)
        let path = UIBezierPath()
        path.moveToPoint(startPoint)
        path.addLineToPoint(endPoint)
        
        let shapeLayer = CAShapeLayer()
        shapeLayer.path = path.CGPath
        shapeLayer.strokeColor = preferredTextColor.CGColor
        shapeLayer.lineWidth = 2.5

        layer.addSublayer(shapeLayer)
        
        super.drawRect(rect)
    }
    
    // Helper functions
    private func indexOfSearchFieldInSubviews() -> Int!
    {
        var index = 0
        
        // A UISearchBar consists of multiple subviews 
        // Fetch the first view
        let searchBarView = subviews[0] as UIView
        
        // In the view that was fetched, find the index of the search field
        for view in searchBarView.subviews
        {
            if view.isKindOfClass(UITextField)
            {
                return index
            }
            
            index = index + 1
        }
        
        return nil
    }
}
