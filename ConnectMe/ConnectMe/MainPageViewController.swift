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
    
    let FRIEND_REQUESTS = 0
    let SEARCH = 1
    let HOME = 2
    let PROFILE = 3
    let MENU = 4
    
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
        arrayOfViewControllers.append((storyboard?.instantiateViewControllerWithIdentifier("FriendRequestsViewController"))!)
        arrayOfViewControllers.append((storyboard?.instantiateViewControllerWithIdentifier("SearchViewController"))!)
        arrayOfViewControllers.append((storyboard?.instantiateViewControllerWithIdentifier("HomeViewController"))!)
        arrayOfViewControllers.append((storyboard?.instantiateViewControllerWithIdentifier("ProfileViewController"))!)
        arrayOfViewControllers.append((storyboard?.instantiateViewControllerWithIdentifier("MenuViewController"))!)
        
        let firstViewController = arrayOfViewControllers[HOME]
        currentPageIndex = HOME
        
        setViewControllers([firstViewController], direction: .Forward, animated: true, completion: nil)
        
    }

    
    func pageViewController(pageViewController: UIPageViewController, viewControllerAfterViewController viewController: UIViewController) -> UIViewController? {
        
        
        print ("HEY")
        if viewController.isKindOfClass(FriendRequestsController)
        {
            return arrayOfViewControllers[SEARCH]
        }
        
        if viewController.isKindOfClass(SearchViewController)
        {
            return arrayOfViewControllers[HOME]
        }
        
        if viewController.isKindOfClass(HomeViewController)
        {
            return arrayOfViewControllers[PROFILE]
        }
        
        if viewController.isKindOfClass(ProfileViewController)
        {
            return arrayOfViewControllers[MENU]
        }
        
        if viewController.isKindOfClass(MenuController)
        {
            return nil
        }
        
        
        return nil
        
    }
    
    func pageViewController(pageViewController: UIPageViewController, viewControllerBeforeViewController viewController: UIViewController) -> UIViewController? {
        
        if viewController.isKindOfClass(FriendRequestsController)
        {
            return nil
        }
        
        if viewController.isKindOfClass(SearchViewController)
        {
            return arrayOfViewControllers[FRIEND_REQUESTS]
        }
        
        if viewController.isKindOfClass(HomeViewController)
        {
            return arrayOfViewControllers[SEARCH]
        }
        
        if viewController.isKindOfClass(ProfileViewController)
        {
            return arrayOfViewControllers[HOME]
        }
        
        if viewController.isKindOfClass(MenuController)
        {
            return arrayOfViewControllers[PROFILE]
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
        
        if currentViewController.isKindOfClass(HomeViewController)
        {
            currentPageIndex = HOME
        }
        
        if currentViewController.isKindOfClass(SearchViewController)
        {
            currentPageIndex = SEARCH
        }
        
        if currentViewController.isKindOfClass(FriendRequestsController)
        {
            currentPageIndex = FRIEND_REQUESTS
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
