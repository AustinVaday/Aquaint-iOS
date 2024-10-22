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
        searchBarStyle = UISearchBarStyle.prominent
        
        // Take out translucent bg
        isTranslucent = false
        
        
    }

    // Required initializer...
    required init(coder someDecoder: NSCoder)
    {
        super.init(coder: someDecoder)!
    }
    
    
    // Set up the UI for the custom search bar
    override func draw(_ rect: CGRect)
    {
        // Find the index of the search field in the search bar subviews
        if let index = indexOfSearchFieldInSubviews()
        {
            // Access the search field
            let searchField: UITextField = (subviews[0]).subviews[index] as! UITextField
            
            // Set its frame.
            searchField.frame = CGRect(x: 5.0, y: 5.0, width: frame.size.width - 10.0, height: frame.size.height - 10.0)

            // Set the font and text color of the search field.
            searchField.font = preferredFont
            searchField.textColor = preferredTextColor
            
            // Change placeholder color. Warning: This may violate Swift public APIs and the app may be
            // rejected from submition into the app store
            let placeHolderLabel = searchField.value(forKey: "placeholderLabel") as! UILabel
            placeHolderLabel.textColor = UIColor(red:0.95, green:0.95, blue:0.95, alpha:1.0)
            
            setImage(UIImage(named: "Mini Search Icon"), for: .search, state: UIControlState())
            
            // Set the background color of the search field.
            searchField.backgroundColor = barTintColor
        }
        
//        // Add line to bottom of search field
//        let startPoint = CGPointMake(0.0, frame.size.height)
//        let endPoint = CGPointMake(frame.size.width, frame.size.height)
//        let path = UIBezierPath()
//        path.moveToPoint(startPoint)
//        path.addLineToPoint(endPoint)
        
//        let shapeLayer = CAShapeLayer()
//        shapeLayer.path = path.CGPath
//        shapeLayer.strokeColor = UIColor(red:0.06, green:0.48, blue:0.62, alpha:1.0).CGColor
//        shapeLayer.lineWidth = 2.5
//
//        layer.addSublayer(shapeLayer)
        
        super.draw(rect)
    }
    
    // Helper functions
    fileprivate func indexOfSearchFieldInSubviews() -> Int!
    {
        var index = 0
        
        // A UISearchBar consists of multiple subviews 
        // Fetch the first view
        let searchBarView = subviews[0] as UIView
        
        // In the view that was fetched, find the index of the search field
        for view in searchBarView.subviews
        {
            if view.isKind(of: UITextField.self)
            {
                return index
            }
            
            index = index + 1
        }
        
        return nil
    }
}
