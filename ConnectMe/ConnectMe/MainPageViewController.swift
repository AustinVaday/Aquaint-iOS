//
//  MainPageViewController.swift
//  Aquaint
//
//  Created by Austin Vaday on 2/25/16.
//  Copyright © 2016 ConnectMe. All rights reserved.
//

import UIKit

class MainPageViewController: UIPageViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    
   
    let MENU = 0
    let PROFILE = 1
    let HOME = 2
    let SEARCH = 3
    let RECENT_CONNECTIONS = 4
    
    var arrayOfViewControllers: Array<UIViewController>!
    var currentPageIndex = 2
    override func viewDidLoad() {
        super.viewDidLoad()

        dataSource = self
        delegate = self

        arrayOfViewControllers = Array<UIViewController>()
        arrayOfViewControllers.append((storyboard?.instantiateViewControllerWithIdentifier("MenuViewController"))!)
        arrayOfViewControllers.append((storyboard?.instantiateViewControllerWithIdentifier("ProfileViewController"))!)
        arrayOfViewControllers.append((storyboard?.instantiateViewControllerWithIdentifier("HomeViewController"))!)
        arrayOfViewControllers.append((storyboard?.instantiateViewControllerWithIdentifier("SearchViewController"))!)
        arrayOfViewControllers.append((storyboard?.instantiateViewControllerWithIdentifier("RecentConnectionsViewController"))!)
        
        let firstViewController = arrayOfViewControllers[HOME]
        currentPageIndex = HOME
        
        setViewControllers([firstViewController], direction: .Forward, animated: true, completion: nil)
        
    }

    
    func pageViewController(pageViewController: UIPageViewController, viewControllerAfterViewController viewController: UIViewController) -> UIViewController? {
        
        
        print ("HEY")
        if viewController.isKindOfClass(MenuController)
        {
            currentPageIndex = PROFILE
            return arrayOfViewControllers[PROFILE]
        }
        
        if viewController.isKindOfClass(ProfileViewController)
        {
            currentPageIndex = HOME
            return arrayOfViewControllers[HOME]
        }
        
        if viewController.isKindOfClass(HomeController)
        {
            currentPageIndex = SEARCH
            return arrayOfViewControllers[SEARCH]
        }
        
        if viewController.isKindOfClass(SearchViewController)
        {
            currentPageIndex = RECENT_CONNECTIONS
            return arrayOfViewControllers[RECENT_CONNECTIONS]
        }
        
        if viewController.isKindOfClass(RecentConnections)
        {
            return nil
        }
        
        
        return nil
        
    }
    
    func pageViewController(pageViewController: UIPageViewController, viewControllerBeforeViewController viewController: UIViewController) -> UIViewController? {
        
        print("HEY")
        if viewController.isKindOfClass(MenuController)
        {
            return nil
        }
        
        if viewController.isKindOfClass(ProfileViewController)
        {
            currentPageIndex = MENU
            return arrayOfViewControllers[MENU]
        }
        
        if viewController.isKindOfClass(HomeController)
        {
            currentPageIndex = PROFILE
            return arrayOfViewControllers[PROFILE]
        }
        
        if viewController.isKindOfClass(SearchViewController)
        {
            currentPageIndex = HOME
            return arrayOfViewControllers[HOME]
        }
        
        if viewController.isKindOfClass(RecentConnections)
        {
            currentPageIndex = SEARCH
            return arrayOfViewControllers[SEARCH]
        }
                
        return nil
    }
    
    
    func pageViewController(pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        
        
        // Get current page index
        let currentViewController = (pageViewController.viewControllers?.last)!
        
//        showAlert(String(currentPageIndex), message: "", buttonTitle: "", sender: self)
        
        if currentViewController.isKindOfClass(MenuController)
        {
            currentPageIndex = MENU
        }
        
        if currentViewController.isKindOfClass(ProfileViewController)
        {
            currentPageIndex = PROFILE
        }
        
        if currentViewController.isKindOfClass(HomeController)
        {
            currentPageIndex = HOME
        }
        
        if currentViewController.isKindOfClass(SearchViewController)
        {
            currentPageIndex = SEARCH
        }
        
        if currentViewController.isKindOfClass(RecentConnections)
        {
            currentPageIndex = RECENT_CONNECTIONS
        }
        
    }
    

    // Used so that we can use buttons to change the page!
    func changePage (pageIndex: Int)
    {
        
        // We have 5 possible page indices (0 -> 5)
        if (pageIndex >= 0 && pageIndex <= 4)
        {
        
            let destinationViewController = arrayOfViewControllers[pageIndex]
        
            var direction : UIPageViewControllerNavigationDirection!
        
//            print ("CURRENT PAGE INDEX: ", currentPageIndex)
//            print ("SELECTED PAGE INDEX:", pageIndex)
            // Determine which direction to animate
            
//            showAlert(String(currentPageIndex), message: String(pageIndex), buttonTitle: "button", sender: self)
            
            if (pageIndex < currentPageIndex)
            {
                direction = UIPageViewControllerNavigationDirection.Reverse
            }
            else
            {
                direction = UIPageViewControllerNavigationDirection.Forward

            }
            
        
            setViewControllers([destinationViewController], direction: direction, animated: true, completion: nil)
        }
        else
        {
            
            print ("ERROR in MainPageViewController:changePage. pageIndex out of range.")
        }

    }
}
