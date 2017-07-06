//
//  WalkthroughContainerViewController.swift
//  Aquaint
//
//  Created by Austin Vaday on 1/2/17.
//  Copyright © 2017 ConnectMe. All rights reserved.
//

import UIKit


class WalkthroughContainerViewController: UIViewController, WalkthroughPageViewDelegate {

  @IBOutlet weak var footerButton: UIButton!
  @IBOutlet weak var animationView: UIView!
  
  // This is our child (container) view controller that holds all our pages
  var walkthroughPageViewController: WalkthroughPageViewController!
  var animatedObjects : Array<UIView>!
  
  let nextModeString = "NEXT"
  let transitionModeString = "LINK PROFILES"
  let segueDestionation = "toMainContainerViewController"
  
  override func viewDidLoad() {
    super.viewDidLoad()

    // Get the walkthroughPageViewController, this holds all our pages!
    walkthroughPageViewController = self.childViewControllers.last as! WalkthroughPageViewController
    walkthroughPageViewController.pageDelegate = self

    animatedObjects = Array<UIView>()
    
  }
  
  override func viewDidAppear(_ animated: Bool) {
    setUpSocialMediaAnimations(self, subView: animationView, animatedObjects: &animatedObjects!, animationLocation: AnimationLocation.top, theme: AnimationAquaintEmblemTheme.whiteTheme)
  }
  
  override func viewDidDisappear(_ animated: Bool) {
    clearUpSocialMediaAnimations(&animatedObjects!)
  }

  override func didReceiveMemoryWarning() {
      super.didReceiveMemoryWarning()
      // Dispose of any resources that can be recreated.
  }
  
  func didHitLastPage() {
    footerButton.setTitle(transitionModeString, for: UIControlState())
  }
  
  func didLeaveLastPage() {
    footerButton.setTitle(nextModeString, for: UIControlState())
  }

  @IBAction func onNextButtonClicked(_ sender: AnyObject) {
    
    if footerButton.titleLabel?.text == nextModeString {
      walkthroughPageViewController.goToNextPage()
    } else {
      performSegue(withIdentifier: segueDestionation, sender: self)
    }
  }
  
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    
    if segue.identifier == segueDestionation {
      let nextVC = segue.destination as! MainContainerViewController
      nextVC.arrivedFromWalkthrough = true
    }
  }
  

}
