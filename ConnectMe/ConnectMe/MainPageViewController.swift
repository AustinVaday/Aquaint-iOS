//
//  MainPageViewController.swift
//  Aquaint
//
//  Created by Austin Vaday on 2/25/16.
//  Copyright © 2016 ConnectMe. All rights reserved.
//

import UIKit

protocol MainPageSectionUnderLineViewDelegate
{
    func updateSectionUnderLineView(newViewNum: Int)
}

class MainPageViewController: UIPageViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    
    let HOME = 0
    let SEARCH = 1
    let CONNECTIONS = 2
    let MENU = 3
    
    var arrayOfViewControllers: Array<UIViewController>!
    var currentPageIndex = 0 //UPDATED in changePage and didFinishAnimating methods
    // Delegating properties
//    weak var pageDelegate:MainPageViewControllerDelegate?
    // Protocol properties


    var sectionDelegate : MainPageSectionUnderLineViewDelegate?

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        dataSource = self
        delegate = self
        arrayOfViewControllers = Array<UIViewController>()
        arrayOfViewControllers.append((storyboard?.instantiateViewControllerWithIdentifier("HomeContainerViewController"))!)
        arrayOfViewControllers.append((storyboard?.instantiateViewControllerWithIdentifier("SearchViewController"))!)
        arrayOfViewControllers.append((storyboard?.instantiateViewControllerWithIdentifier("AquaintsContainerViewController"))!)
        arrayOfViewControllers.append((storyboard?.instantiateViewControllerWithIdentifier("MenuViewController"))!)
        
        let firstViewController = arrayOfViewControllers[HOME]
        currentPageIndex = HOME
        
        setViewControllers([firstViewController], direction: .Forward, animated: true, completion: nil)
        
    }
    
    func pageViewController(pageViewController: UIPageViewController, viewControllerAfterViewController viewController: UIViewController) -> UIViewController? {
        
        if viewController.isKindOfClass(HomeContainerViewController)
        {
            return arrayOfViewControllers[SEARCH]
        }
        
        if viewController.isKindOfClass(SearchViewController)
        {
            return arrayOfViewControllers[CONNECTIONS]
        }
        
        if viewController.isKindOfClass(AquaintsContainerViewController)
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
        
        if viewController.isKindOfClass(HomeContainerViewController)
        {
            return nil
        }
        
        if viewController.isKindOfClass(SearchViewController)
        {
            return arrayOfViewControllers[HOME]
        }
        
        if viewController.isKindOfClass(AquaintsContainerViewController)
        {
            return arrayOfViewControllers[SEARCH]
        }
        
        if viewController.isKindOfClass(MenuController)
        {
            return arrayOfViewControllers[CONNECTIONS]
        }
        
                
        return nil
    }
    
    func pageViewController(pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        
        print("TRANSITION COMPLETED?: ", completed)
        
        // Only show the updated section underline if the transition is completed.
        // Previously, we did not check this, so if the user would "fake" a swipe to the left,
        // the section underline would be changed (improper behavior). This is now fixed!
        if completed
        {
            sectionDelegate?.updateSectionUnderLineView(currentPageIndex)
        }
    }
    
    func pageViewController(pageViewController: UIPageViewController, willTransitionToViewControllers pendingViewControllers: [UIViewController]) {
        
        let nextViewController = (pendingViewControllers.first)!
        
        if nextViewController.isKindOfClass(MenuController)
        {
            currentPageIndex = MENU
        }

        else if nextViewController.isKindOfClass(AquaintsContainerViewController)
        {
            currentPageIndex = CONNECTIONS
        }
        
        else if nextViewController.isKindOfClass(HomeContainerViewController)
        {
            currentPageIndex = HOME
        }
        
        else if nextViewController.isKindOfClass(SearchViewController)
        {
            currentPageIndex = SEARCH
        }
        
        print(currentPageIndex)
    
    }

    // Used so that we can use buttons to change the page!
    func changePage (pageIndex: Int)
    {
        
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
            
//            pageDelegate?.didTransitionPage(self)

        }
        else
        {
            
            print ("ERROR in MainPageViewController:changePage. pageIndex out of range.")
        }

    }
}
