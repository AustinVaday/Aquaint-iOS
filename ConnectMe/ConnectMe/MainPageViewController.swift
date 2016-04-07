//
//  MainPageViewController.swift
//  Aquaint
//
//  Created by Austin Vaday on 2/25/16.
//  Copyright © 2016 ConnectMe. All rights reserved.
//

import UIKit

class MainPageViewController: UIPageViewController, UIPageViewControllerDataSource {
    
   
    let MENU = 0
    let PROFILE = 1
    let HOME = 2
    let SEARCH = 3
    let RECENT_CONNECTIONS = 4
    
    var arrayOfViewControllers: Array<UIViewController>!
    var currentVCIndex = 1
    override func viewDidLoad() {
        super.viewDidLoad()

        dataSource = self

        arrayOfViewControllers = Array<UIViewController>()
        arrayOfViewControllers.append((storyboard?.instantiateViewControllerWithIdentifier("MenuViewController"))!)
        arrayOfViewControllers.append((storyboard?.instantiateViewControllerWithIdentifier("ProfileViewController"))!)
        arrayOfViewControllers.append((storyboard?.instantiateViewControllerWithIdentifier("HomeViewController"))!)
        arrayOfViewControllers.append((storyboard?.instantiateViewControllerWithIdentifier("SearchViewController"))!)
        arrayOfViewControllers.append((storyboard?.instantiateViewControllerWithIdentifier("RecentConnectionsViewController"))!)
        
        let firstViewController = arrayOfViewControllers[HOME]
        setViewControllers([firstViewController], direction: .Forward, animated: true, completion: nil)
        
        
        print("DOPE")
    }
    
    func pageViewController(pageViewController: UIPageViewController, viewControllerAfterViewController viewController: UIViewController) -> UIViewController? {
        
        
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

    
    func changePage ()
    {
        
        // Recent Connections
        let recentConnectionsViewController = (storyboard?.instantiateViewControllerWithIdentifier("RecentConnectionsViewController"))!
        setViewControllers([recentConnectionsViewController], direction: .Forward, animated: true, completion: nil)

    }
}
