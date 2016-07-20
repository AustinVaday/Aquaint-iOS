//
//  CustomSearchController.swift
//  Aquaint
//
//  Created by Austin Vaday on 7/19/16.
//  Copyright © 2016 ConnectMe. All rights reserved.
//

import UIKit

// Custom protocol required to use this custom search controller!!
protocol CustomSearchControllerDelegate
{
    func didStartSearching()
    
    func didTapOnSearchButton()
    
    func didTapOnCancelButton()
    
    func didChangeSearchText(searchText: String)
}


class CustomSearchController: UISearchController, UISearchBarDelegate {

    var customSearchBar: CustomSearchBar!
    var customDelegate : CustomSearchControllerDelegate!

    // Custom initializer
    init(searchResultsController: UIViewController!, searchBarFrame: CGRect, searchBarFont: UIFont, searchBarTextColor: UIColor, searchBarTintColor: UIColor)
    {
        super.init(searchResultsController: searchResultsController)
        
        configureSearchBar(searchBarFrame, font: searchBarFont, textColor: searchBarTextColor, bgColor: searchBarTintColor)
    }
    
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?)
    {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init(coder someDecoder: NSCoder)
    {
        super.init(coder: someDecoder)!
    }
    
    
    // **** REQUIRED PROTOCOLS FOR SEARCH BAR DELEGATE ****
    func searchBarTextDidBeginEditing(searchBar: UISearchBar)
    {
        customDelegate.didStartSearching()
    }
    
    func searchBarSearchButtonClicked(searchBar: UISearchBar)
    {
        customSearchBar.resignFirstResponder()
        customDelegate.didTapOnSearchButton()
    }
    
    func searchBarCancelButtonClicked(searchBar: UISearchBar)
    {
        customSearchBar.resignFirstResponder()
        customDelegate.didTapOnCancelButton()
    }
    
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String)
    {
        customDelegate.didChangeSearchText(searchText)
    }
    
    // Helper functions
    private func configureSearchBar(frame: CGRect, font: UIFont, textColor: UIColor, bgColor: UIColor)
    {
        // Initializes an instance of our own created custom search bar!
        customSearchBar = CustomSearchBar(frame: frame, font: font , textColor: textColor)
        
        customSearchBar.barTintColor = bgColor
        customSearchBar.tintColor = textColor
        customSearchBar.showsBookmarkButton = false
        customSearchBar.showsCancelButton = true
        customSearchBar.delegate = self
    }
    
    
}
