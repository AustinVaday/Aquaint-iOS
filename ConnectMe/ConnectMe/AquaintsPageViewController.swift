//
//  AquaintsPageViewController.swift
//  Aquaint
//
//  Created by Austin Vaday on 9/21/16.
//  Copyright © 2016 ConnectMe. All rights reserved.
//

import UIKit

protocol AquaintsPageSectionUnderLineViewDelegate
{
    func updateSectionUnderLineView(newViewNum: Int)
}

class AquaintsPageViewController: UIPageViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    
    let FOLLOWERS = 0
    let FOLLOWING = 1

    var arrayOfViewControllers: Array<UIViewController>!
    var currentPageIndex = 0 //UPDATED in changePage and didFinishAnimating methods
    var sectionDelegate : AquaintsPageSectionUnderLineViewDelegate?
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        dataSource = self
        delegate = self
        arrayOfViewControllers = Array<UIViewController>()
        arrayOfViewControllers.append((storyboard?.instantiateViewControllerWithIdentifier("FollowersViewController"))!)
        arrayOfViewControllers.append((storyboard?.instantiateViewControllerWithIdentifier("FollowingViewController"))!)

        
        let firstViewController = arrayOfViewControllers[FOLLOWERS]
        currentPageIndex = FOLLOWERS
        
        setViewControllers([firstViewController], direction: .Forward, animated: true, completion: nil)
        
    }
    
    func pageViewController(pageViewController: UIPageViewController, viewControllerAfterViewController viewController: UIViewController) -> UIViewController? {
        
        if viewController.isKindOfClass(FollowersViewController)
        {
            return arrayOfViewControllers[FOLLOWING]
        }
        
        return nil
    }
    
    func pageViewController(pageViewController: UIPageViewController, viewControllerBeforeViewController viewController: UIViewController) -> UIViewController? {
        
        if viewController.isKindOfClass(FollowingViewController)
        {
            return arrayOfViewControllers[FOLLOWERS]
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
        
        if nextViewController.isKindOfClass(FollowersViewController)
        {
            currentPageIndex = FOLLOWING
        }
            
        else if nextViewController.isKindOfClass(FollowingViewController)
        {
            currentPageIndex = FOLLOWERS
        }
        
    }
    
    // Used so that we can use buttons to change the page!
    func changePage (pageIndex: Int)
    {
        
        // We have 2 possible page indices (0 -> 1)
        if (pageIndex >= 0 && pageIndex <= 1)
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
            
        }
        else
        {
            
            print ("ERROR in AquaintsViewController:changePage. pageIndex out of range.")
        }
        
    }
}
