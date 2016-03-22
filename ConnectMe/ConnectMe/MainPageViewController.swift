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
    let HOME = 1
    let RECENT_CONNECTIONS = 2
    
    var arrayOfViewControllers: Array<UIViewController>!
    var currentVCIndex = 1
    override func viewDidLoad() {
        super.viewDidLoad()

        dataSource = self

        arrayOfViewControllers = Array<UIViewController>()
        arrayOfViewControllers.append((storyboard?.instantiateViewControllerWithIdentifier("MenuViewController"))!)
        arrayOfViewControllers.append((storyboard?.instantiateViewControllerWithIdentifier("HomeViewController"))!)
        arrayOfViewControllers.append((storyboard?.instantiateViewControllerWithIdentifier("RecentConnectionsViewController"))!)
        
        let firstViewController = arrayOfViewControllers[HOME]
        setViewControllers([firstViewController], direction: .Forward, animated: true, completion: nil)
    }
    
    func pageViewController(pageViewController: UIPageViewController, viewControllerAfterViewController viewController: UIViewController) -> UIViewController? {
                
        if viewController.isKindOfClass(HomeController)
        {
            return arrayOfViewControllers[RECENT_CONNECTIONS]
        }
        
        if viewController.isKindOfClass(MenuController)
        {
            return arrayOfViewControllers[HOME]
        }
        
        if viewController.isKindOfClass(RecentConnections)
        {
            return nil
        }
        
        return nil
        
    }
    
    func pageViewController(pageViewController: UIPageViewController, viewControllerBeforeViewController viewController: UIViewController) -> UIViewController? {
        
        if viewController.isKindOfClass(HomeController)
        {
            return arrayOfViewControllers[MENU]
        }
        
        if viewController.isKindOfClass(MenuController)
        {
            return nil
        }
        
        if viewController.isKindOfClass(RecentConnections)
        {
            return arrayOfViewControllers[HOME]
        }
        
        return nil
    }

}
