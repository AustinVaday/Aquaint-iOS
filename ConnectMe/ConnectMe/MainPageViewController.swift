//
//  MainPageViewController.swift
//  Aquaint
//
//  Created by Austin Vaday on 2/25/16.
//  Copyright © 2016 ConnectMe. All rights reserved.
//

import UIKit


// CREATE PROTOCOL TO Communicate easily with MainPageViewController
protocol MainPageViewControllerDelegate : class {
    func didTransitionPage(sender: MainPageViewController)
    
}

class MainPageViewController: UIPageViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    
   
    let MENU = 0
    let PROFILE = 1
    let HOME = 2
    let SEARCH = 3
    let RECENT_CONNECTIONS = 4
    
    var arrayOfViewControllers: Array<UIViewController>!
    var currentPageIndex = 2 //UPDATED in changePage and didFinishAnimating methods
    // Delegating properties
    weak var pageDelegate:MainPageViewControllerDelegate?


    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        

        dataSource = self
//        delegate = self
        
        print("YOLO2", self.delegate)


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
            return arrayOfViewControllers[PROFILE]
        }
        
        if viewController.isKindOfClass(ProfileViewController)
        {
            return arrayOfViewControllers[HOME]
        }
        
        if viewController.isKindOfClass(HomeController)
        {
            return arrayOfViewControllers[SEARCH]
        }
        
        if viewController.isKindOfClass(SearchViewController)
        {
            return arrayOfViewControllers[RECENT_CONNECTIONS]
        }
        
        if viewController.isKindOfClass(RecentConnections)
        {
            return nil
        }
        
        
        return nil
        
    }
    
    func pageViewController(pageViewController: UIPageViewController, viewControllerBeforeViewController viewController: UIViewController) -> UIViewController? {
        
        if viewController.isKindOfClass(MenuController)
        {
            return nil
        }
        
        if viewController.isKindOfClass(ProfileViewController)
        {
            return arrayOfViewControllers[MENU]
        }
        
        if viewController.isKindOfClass(HomeController)
        {
            return arrayOfViewControllers[PROFILE]
        }
        
        if viewController.isKindOfClass(SearchViewController)
        {
            return arrayOfViewControllers[HOME]
        }
        
        if viewController.isKindOfClass(RecentConnections)
        {
            return arrayOfViewControllers[SEARCH]
        }
                
        return nil
    }
    
    func pageViewController(pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        
        
        // Get current page index
        let currentViewController = (pageViewController.viewControllers?.last)!
        
//        showAlert(String("DID FINISH ANIMATING"), message: "", buttonTitle: "", sender: self)
        
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
        
        print("YOLO3", self.delegate)

        // We have 5 possible page indices (0 -> 5)
        if (pageIndex >= 0 && pageIndex <= 4)
        {
        
            let destinationViewController = arrayOfViewControllers[pageIndex]
        
            var direction : UIPageViewControllerNavigationDirection!

            // Determine which direction to animate
            if (pageIndex < currentPageIndex)
            {
                direction = UIPageViewControllerNavigationDirection.Reverse
            }
            else
            {
                direction = UIPageViewControllerNavigationDirection.Forward

            }
        
            setViewControllers([destinationViewController], direction: direction, animated: true, completion: nil)
            
            // Update the currentPageIndex
            currentPageIndex = pageIndex
            
            pageDelegate?.didTransitionPage(self)

        }
        else
        {
            
            print ("ERROR in MainPageViewController:changePage. pageIndex out of range.")
        }

    }
}
