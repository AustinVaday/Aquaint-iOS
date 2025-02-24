//
//  HomePageViewController.swift
//  Aquaint
//
//  Created by Austin Vaday on 4/30/16.
//  Copyright © 2016 ConnectMe. All rights reserved.
//

import UIKit

protocol HomePageSectionUnderLineViewDelegate
{
    func updateSectionUnderLineView(_ newViewNum: Int)
}

class HomePageViewController: UIPageViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    
    let AQUAINTS_NOTIFICATIONS = 0
    let WORLD_NOTIFICATIONS = 1
    
    var arrayOfViewControllers: Array<UIViewController>!
    
    var currentPageIndex = 0 //UPDATED in changePage and didFinishAnimating methods
    
    // Delegating properties
    var sectionDelegate:HomePageSectionUnderLineViewDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        
        dataSource = self
        delegate = self
        
        arrayOfViewControllers = Array<UIViewController>()
        arrayOfViewControllers.append((storyboard?.instantiateViewController(withIdentifier: "NewsfeedViewController"))!)
        arrayOfViewControllers.append((storyboard?.instantiateViewController(withIdentifier: "YouNotificationsViewController"))!)

        let firstViewController = arrayOfViewControllers[AQUAINTS_NOTIFICATIONS]
        currentPageIndex = AQUAINTS_NOTIFICATIONS
        
        setViewControllers([firstViewController], direction: .forward, animated: true, completion: nil)
        
    }
    
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        
        
//        if viewController.isKindOfClass(NewsfeedViewController)
//        {
//            return arrayOfViewControllers[WORLD_NOTIFICATIONS]
//        }
//        
//        if viewController.isKindOfClass(WorldNotificationsViewController)
//        {
//            return nil
//        }
//        
        return nil
        
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
//        
//        if viewController.isKindOfClass(NewsfeedViewController)
//        {
//            return nil
//        }
//        
//        if viewController.isKindOfClass(WorldNotificationsViewController)
//        {
//            return arrayOfViewControllers[AQUAINTS_NOTIFICATIONS]
//        }

        return nil
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
//        let currentViewController = previousViewControllers.last!
//        
//        if currentViewController.isKindOfClass(NewsfeedViewController)
//        {
//            currentPageIndex = AQUAINTS_NOTIFICATIONS
//        }
//        
//        if currentViewController.isKindOfClass(WorldNotificationsViewController)
//        {
//            currentPageIndex = WORLD_NOTIFICATIONS
//        }
//        
//        sectionDelegate?.updateSectionUnderLineView(currentPageIndex)
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, willTransitionTo pendingViewControllers: [UIViewController]) {
//        // Get current page index
//        let currentViewController = (pendingViewControllers.first)!
//        
//        if currentViewController.isKindOfClass(NewsfeedViewController)
//        {
//            currentPageIndex = AQUAINTS_NOTIFICATIONS
//        }
//        
//        if currentViewController.isKindOfClass(WorldNotificationsViewController)
//        {
//            currentPageIndex = WORLD_NOTIFICATIONS
//        }
//        
//        sectionDelegate?.updateSectionUnderLineView(currentPageIndex)

    }

    // Used so that we can use buttons to change the page!
    func changePage (_ pageIndex: Int)
    {

//        TEMP ... UNCOMMENT IF WANT TO CHANGE PAGES
//        // We have 2 possible page indices (0 -> 1)
//        if (pageIndex >= 0 && pageIndex <= 2)
//        {
//            
//            let destinationViewController = arrayOfViewControllers[pageIndex]
//            
//            var direction : UIPageViewControllerNavigationDirection!
//            
//            // Determine which direction to animate
//            if (pageIndex < currentPageIndex)
//            {
//                direction = UIPageViewControllerNavigationDirection.Reverse
//            }
//            else
//            {
//                direction = UIPageViewControllerNavigationDirection.Forward
//                
//            }
//            
//            setViewControllers([destinationViewController], direction: direction, animated: true, completion: nil)
//            
//            // Update the currentPageIndex
//            currentPageIndex = pageIndex
//        
//            
//        }
//        else
//        {
//            
//            print ("ERROR in MainPageViewController:changePage. pageIndex out of range.")
//        }
        
    }

}
