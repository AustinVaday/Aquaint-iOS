//
//  WalkthroughPageViewController.swift
//  Aquaint
//
//  Created by Austin Vaday on 1/2/17.
//  Copyright © 2017 ConnectMe. All rights reserved.
//

import UIKit

class WalkthroughPageViewController: UIPageViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
  
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
    arrayOfViewControllers.append((storyboard?.instantiateViewControllerWithIdentifier("Walkthrough0"))!)
    arrayOfViewControllers.append((storyboard?.instantiateViewControllerWithIdentifier("Walkthrough1"))!)
    arrayOfViewControllers.append((storyboard?.instantiateViewControllerWithIdentifier("Walkthrough2"))!)
    arrayOfViewControllers.append((storyboard?.instantiateViewControllerWithIdentifier("Walkthrough3"))!)
    
    let firstViewController = arrayOfViewControllers[0]
    currentPageIndex = 0
    
    setViewControllers([firstViewController], direction: .Forward, animated: true, completion: nil)
    
  }
  
  func pageViewController(pageViewController: UIPageViewController, viewControllerAfterViewController viewController: UIViewController) -> UIViewController? {
    
    if viewController.restorationIdentifier == "Walkthrough0"
    {
      return arrayOfViewControllers[1]
    }
    
    if viewController.restorationIdentifier == "Walkthrough1"
    {
      return arrayOfViewControllers[2]
    }
    
    if viewController.restorationIdentifier == "Walkthrough2"
    {
      return arrayOfViewControllers[3]
    }
    
    if viewController.restorationIdentifier == "Walkthrough3"
    {
      return nil
    }

    
    
    return nil
    
  }
  
  func pageViewController(pageViewController: UIPageViewController, viewControllerBeforeViewController viewController: UIViewController) -> UIViewController? {
    
    if viewController.restorationIdentifier == "Walkthrough0"
    {
      return nil
    }
    
    if viewController.restorationIdentifier == "Walkthrough1"
    {
      return arrayOfViewControllers[0]
    }
    
    if viewController.restorationIdentifier == "Walkthrough2"
    {
      return arrayOfViewControllers[1]
    }
    
    if viewController.restorationIdentifier == "Walkthrough3"
    {
      return arrayOfViewControllers[2]
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
  
  func presentationCountForPageViewController(pageViewController: UIPageViewController) -> Int {
    return 4
  }
  
  func presentationIndexForPageViewController(pageViewController: UIPageViewController) -> Int {
    return currentPageIndex
  }
  
  func pageViewController(pageViewController: UIPageViewController, willTransitionToViewControllers pendingViewControllers: [UIViewController]) {
    
    let nextViewController = (pendingViewControllers.first)!
    
    if nextViewController.restorationIdentifier == "Walkthrough0"
    {
      currentPageIndex = 0
    }
    
    if nextViewController.restorationIdentifier == "Walkthrough1"
    {
      currentPageIndex = 1
    }
    
    if nextViewController.restorationIdentifier == "Walkthrough2"
    {
      currentPageIndex = 2
    }
    
    if nextViewController.restorationIdentifier == "Walkthrough3"
    {
      currentPageIndex = 3
    }
    
    print(currentPageIndex)
    
  }
//  
//  func goToFollowersPage()
//  {
//    changePage(2)
//    let aquaintsVC = arrayOfViewControllers[CONNECTIONS] as! AquaintsContainerViewController
//    let dummyButton = UIButton()
//    aquaintsVC.goToPage0(dummyButton) // Send in random button
//    
//    sectionDelegate?.updateSectionUnderLineView(currentPageIndex)
//    
//  }
//  
//  func goToFollowingPage()
//  {
//    changePage(2)
//    let aquaintsVC = arrayOfViewControllers[CONNECTIONS] as! AquaintsContainerViewController
//    let dummyButton = UIButton()
//    aquaintsVC.goToPage1(dummyButton) // Send in random button
//    
//    sectionDelegate?.updateSectionUnderLineView(currentPageIndex)
//  }
//  
//  // Used so that we can use buttons to change the page!
//  func changePage (pageIndex: Int)
//  {
//    
//    // We have 5 possible page indices (0 -> 5)
//    if (pageIndex >= 0 && pageIndex <= 4)
//    {
//      
//      let destinationViewController = arrayOfViewControllers[pageIndex]
//      
//      var direction : UIPageViewControllerNavigationDirection!
//      
//      // Determine which direction to animate
//      if (pageIndex < currentPageIndex)
//      {
//        direction = UIPageViewControllerNavigationDirection.Reverse
//      }
//      else
//      {
//        direction = UIPageViewControllerNavigationDirection.Forward
//        
//      }
//      
//      setViewControllers([destinationViewController], direction: direction, animated: true, completion: nil)
//      
//      // Update the currentPageIndex
//      currentPageIndex = pageIndex
//      
//      //            pageDelegate?.didTransitionPage(self)
//      
//    }
//    else
//    {
//      
//      print ("ERROR in MainPageViewController:changePage. pageIndex out of range.")
//    }
//    
//  }
}
