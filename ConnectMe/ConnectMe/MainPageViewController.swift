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
    
    let NEWSFEED = 0
    let SEARCH = 1
    let SCANCODE = 2
    let ANALYTICS = 3
    let MENU = 4
    
    var arrayOfViewControllers: Array<UIViewController>!
    var currentPageIndex = 2 //UPDATED in changePage and didFinishAnimating methods
    // Delegating properties
//    weak var pageDelegate:MainPageViewControllerDelegate?
    // Protocol properties


    var sectionDelegate : MainPageSectionUnderLineViewDelegate?

    // Google Analytics tracking
    override func viewDidAppear(animated: Bool) {
//      let name = "MainPageViewController"
//      guard let tracker = GAI.sharedInstance().defaultTracker else { return }
//      tracker.set(kGAIScreenName, value: name)
//      
//      guard let builder = GAIDictionaryBuilder.createScreenView() else { return }
//      tracker.send(builder.build() as [NSObject : AnyObject])
    }
  
    override func viewDidLoad() {
        super.viewDidLoad()
        
        dataSource = self
        delegate = self
      
        let analyticsStoryBoard = UIStoryboard(name: "AnalyticsDisplay", bundle: nil)

        arrayOfViewControllers = Array<UIViewController>()
        arrayOfViewControllers.append((storyboard?.instantiateViewControllerWithIdentifier("HomeContainerViewController"))!)
        arrayOfViewControllers.append((storyboard?.instantiateViewControllerWithIdentifier("SearchViewController"))!)
      arrayOfViewControllers.append((storyboard?.instantiateViewControllerWithIdentifier("ScanCodeDisplayStoryboardViewController"))!)
        //arrayOfViewControllers.append((storyboard?.instantiateViewControllerWithIdentifier("AnalyticsDisplayViewController"))!)
        arrayOfViewControllers.append(analyticsStoryBoard.instantiateViewControllerWithIdentifier("AnalyticsDisplay"))

        arrayOfViewControllers.append((storyboard?.instantiateViewControllerWithIdentifier("MenuViewController"))!)
        
        let firstViewController = arrayOfViewControllers[SCANCODE]
        currentPageIndex = SCANCODE
        
        setViewControllers([firstViewController], direction: .Forward, animated: true, completion: nil)
        
    }
    
    func pageViewController(pageViewController: UIPageViewController, viewControllerAfterViewController viewController: UIViewController) -> UIViewController? {
        
        if viewController.isKindOfClass(HomeContainerViewController)
        {
            return arrayOfViewControllers[SEARCH]
        }
      
        if viewController.isKindOfClass(SearchViewController)
        {
          return arrayOfViewControllers[SCANCODE]
        }
      
        if viewController.isKindOfClass(ScanCodeDisplayStoryboardViewController)
        {
            return arrayOfViewControllers[ANALYTICS]
        }
        
        if viewController.isKindOfClass(AnalyticsDisplay)
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
            return arrayOfViewControllers[NEWSFEED]
        }
      
        if viewController.isKindOfClass(ScanCodeDisplayStoryboardViewController)
        {
          return arrayOfViewControllers[SEARCH]
        }
      
        if viewController.isKindOfClass(AnalyticsDisplay)
        {
            return arrayOfViewControllers[SCANCODE]
        }
        
        if viewController.isKindOfClass(MenuController)
        {
            return arrayOfViewControllers[ANALYTICS]
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

        else if nextViewController.isKindOfClass(AnalyticsDisplay)
        {
            currentPageIndex = ANALYTICS
        }
        
        else if nextViewController.isKindOfClass(HomeContainerViewController)
        {
            currentPageIndex = NEWSFEED
        }
        
        else if nextViewController.isKindOfClass(ScanCodeDisplayStoryboardViewController)
        {
          currentPageIndex = SCANCODE
        }
          
        else if nextViewController.isKindOfClass(SearchViewController)
        {
            currentPageIndex = SEARCH
        }
        
        print(currentPageIndex)
    
    }

    func goToAnalyticsPage()
    {
      changePage(ANALYTICS)
      sectionDelegate?.updateSectionUnderLineView(currentPageIndex)
    }
  
//    func goToFollowersPage()
//    {
//        changePage(ANALYTICS)
//        let aquaintsVC = arrayOfViewControllers[ANALYTICS] as! AnalyticsDisplay
//        let dummyButton = UIButton()
//        aquaintsVC.goToPage0(dummyButton) // Send in random button
//        
//        sectionDelegate?.updateSectionUnderLineView(currentPageIndex)
//
//    }
//    
//    func goToFollowingPage()
//    {
//        changePage(ANALYTICS)
//        let aquaintsVC = arrayOfViewControllers[ANALYTICS] as! AnalyticsDisplay
//        let dummyButton = UIButton()
//        aquaintsVC.goToPage1(dummyButton) // Send in random button
//        
//        sectionDelegate?.updateSectionUnderLineView(currentPageIndex)
//    }
  
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

  // a special case of changePage(pageIndex: 2) used for push notification handling. Displaying Followers or Following section in MenuController
  func changePageToFollows(subpageIndex: Int) {  // 0 for Followers, 1 for Following
    let pageIndex = MENU
    
    let destinationViewController = arrayOfViewControllers[pageIndex]
    
    var direction : UIPageViewControllerNavigationDirection!
    
    if (pageIndex < currentPageIndex) {
      direction = UIPageViewControllerNavigationDirection.Reverse
    }
    else {
      direction = UIPageViewControllerNavigationDirection.Forward
    }
    
    setViewControllers([destinationViewController], direction: direction, animated: true, completion: { (result: Bool) -> Void in
      if let vcFollow = destinationViewController as? MenuController {
        
        let dummyButton = UIButton()
        if (subpageIndex == 0) {
          vcFollow.goToFollowersPage(dummyButton)
        } else if (subpageIndex == 1) {
          vcFollow.goToFollowingPage(dummyButton)
        }
        
      } else {
        print("View Controller on UIView is not MenuController; cannot goToFollowers/FollowingPage. ")
      }
      })
    
    currentPageIndex = pageIndex

  }
  
  // another function for push notification handling
  func changePageToFollowRequests() {
    let pageIndex = 0
    
    let destinationViewController = arrayOfViewControllers[pageIndex]
    
    var direction : UIPageViewControllerNavigationDirection!
    
    if (pageIndex < currentPageIndex) {
      direction = UIPageViewControllerNavigationDirection.Reverse
    }
    else {
      direction = UIPageViewControllerNavigationDirection.Forward
    }

    setViewControllers([destinationViewController], direction: direction, animated: true, completion: {
      (result: Bool) -> Void in
        let vcHome = self.arrayOfViewControllers[0] as! HomeContainerViewController
        vcHome.performSegueWithIdentifier("toFollowRequestsViewController", sender: vcHome)
    })
    
    currentPageIndex = pageIndex
  }
  
}
