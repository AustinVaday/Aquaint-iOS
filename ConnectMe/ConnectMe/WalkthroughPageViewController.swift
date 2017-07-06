//
//  WalkthroughPageViewController.swift
//  Aquaint
//
//  Created by Austin Vaday on 1/2/17.
//  Copyright © 2017 ConnectMe. All rights reserved.
//

import UIKit

protocol WalkthroughPageViewDelegate {
  func didHitLastPage()
  func didLeaveLastPage()
}

class WalkthroughPageViewController: UIPageViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
  
  var arrayOfViewControllers: Array<UIViewController>!
  var currentPageIndex = 0 //UPDATED in changePage and didFinishAnimating methods
  let numPages = 5
  var pageDelegate : WalkthroughPageViewDelegate?
  
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    dataSource = self
    delegate = self
    arrayOfViewControllers = Array<UIViewController>()
    arrayOfViewControllers.append((storyboard?.instantiateViewController(withIdentifier: "Walkthrough0"))!)
    arrayOfViewControllers.append((storyboard?.instantiateViewController(withIdentifier: "Walkthrough1"))!)
    arrayOfViewControllers.append((storyboard?.instantiateViewController(withIdentifier: "Walkthrough2"))!)
    arrayOfViewControllers.append((storyboard?.instantiateViewController(withIdentifier: "Walkthrough3"))!)
    arrayOfViewControllers.append((storyboard?.instantiateViewController(withIdentifier: "Walkthrough4"))!)
    
    let firstViewController = arrayOfViewControllers[0]
    currentPageIndex = 0
    
    setViewControllers([firstViewController], direction: .forward, animated: true, completion: nil)
    
  }
  
  func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
    
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
      return arrayOfViewControllers[4]
    }
    
    if viewController.restorationIdentifier == "Walkthrough4"
    {
      return nil
    }

    
    
    return nil
    
  }
  
  func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
    
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
    
    if viewController.restorationIdentifier == "Walkthrough4"
    {
      pageDelegate?.didLeaveLastPage()
      return arrayOfViewControllers[3]
    }

    
    return nil
  }
  
  func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
    
    print("TRANSITION COMPLETED?: ", completed)
    
    // Only show the updated section underline if the transition is completed.
    // Previously, we did not check this, so if the user would "fake" a swipe to the left,
    // the section underline would be changed (improper behavior). This is now fixed!
    if completed && currentPageIndex == numPages - 1
    {
      pageDelegate?.didHitLastPage()
    }
    
    // If we're at the second-to-last-page, always configure this.
    // Note this is not entirely correct, but suffices for our implementation
    if completed && currentPageIndex == numPages - 2 {
      pageDelegate?.didLeaveLastPage()
    }
  }
  
  func presentationCount(for pageViewController: UIPageViewController) -> Int {
    return numPages
  }
  
  func presentationIndex(for pageViewController: UIPageViewController) -> Int {
    return currentPageIndex
  }
  
  func pageViewController(_ pageViewController: UIPageViewController, willTransitionTo pendingViewControllers: [UIViewController]) {
    
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
    
    if nextViewController.restorationIdentifier == "Walkthrough4"
    {
      currentPageIndex = 4
      pageDelegate?.didHitLastPage()
    }
    
    print(currentPageIndex)
    
  }
  
  func goToNextPage() {
    let direction = UIPageViewControllerNavigationDirection.forward
    
    if currentPageIndex < numPages - 1 {
      currentPageIndex = currentPageIndex + 1
      let destinationVC = arrayOfViewControllers[currentPageIndex]
      setViewControllers([destinationVC], direction: direction, animated: true, completion: nil)
      
      // If last page
      if currentPageIndex == numPages - 1 {
        pageDelegate?.didHitLastPage()
      }

    }
    
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
