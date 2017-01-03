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
  var socialMediaImages : Array<UIImage>!
  override func viewDidLoad() {
    super.viewDidLoad()

    // Get the walkthroughPageViewController, this holds all our pages!
    walkthroughPageViewController = self.childViewControllers.last as! WalkthroughPageViewController
    walkthroughPageViewController.pageDelegate = self

    animatedObjects = Array<UIView>()
    
    socialMediaImages = Array(getAllPossibleSocialMediaImages().values)
    
    // Add Aquaint emblem to list too ;)
    let aquaintEmblem = UIImage(named: "Emblem White")
    socialMediaImages.append(aquaintEmblem!)
    
  }
  
  override func viewDidAppear(animated: Bool) {
    setUpAnimations(self, subView: animationView)
  }
  
  override func viewDidDisappear(animated: Bool) {
    clearUpAnimations()
  }

  override func didReceiveMemoryWarning() {
      super.didReceiveMemoryWarning()
      // Dispose of any resources that can be recreated.
  }
  
  func didHitLastPage() {
    footerButton.setTitle("LINK PROFILES", forState: UIControlState.Normal)
  }
  
  func didLeaveLastPage() {
    footerButton.setTitle("NEXT", forState: UIControlState.Normal)

  }

  @IBAction func onNextButtonClicked(sender: AnyObject) {
    walkthroughPageViewController.goToNextPage()
  }
  
  private func setUpAnimations(viewController: UIViewController, subView: UIView)
  {
    // Only add more animations if none exist already. Prevents user abuse
    if !animatedObjects.isEmpty
    {
      return
    }
    
    for i in 0...10
    {
      
      // Set up object to animate
      let object = UIView()
      
      // Generate random size offset from 0.0 to 20.0
      let randomSizeOffset = CGFloat(arc4random_uniform(20))
      
      // Fetch arbritrary social media emblem
      let image = socialMediaImages[ i % socialMediaImages.count]
      let imageView = UIImageView(image: image)
      imageView.frame = CGRect(x:0, y:0, width:20 + randomSizeOffset, height:20 + randomSizeOffset)
//      imageView.backgroundColor = generateRandomColor()
      imageView.layer.cornerRadius = imageView.frame.size.width / 2
      object.addSubview(imageView)
      
      object.frame = CGRect(x:0, y:0, width:20 + randomSizeOffset, height:20 + randomSizeOffset)
//      object.backgroundColor = generateRandomColor()
//      object.layer.cornerRadius = object.frame.size.width / 2
      
      
      // Generate random number from 0.0 and 200.0
      let randomYOffset = CGFloat( arc4random_uniform(140))
      
      // Add object to subview
      subView.addSubview(object)
      
      // Create a cool path that defines animation curve
      let path = UIBezierPath()
      path.moveToPoint(CGPoint(x:-20, y:169 - randomYOffset))
      path.addCurveToPoint(CGPoint(x:viewController.view.frame.width + 50 , y: 169 - randomYOffset), controlPoint1: CGPoint(x: 136, y: 273 - randomYOffset), controlPoint2: CGPoint(x: 178, y: 110 - randomYOffset))
      
      // Set up animation with path
      let animation = CAKeyframeAnimation(keyPath: "position")
      animation.path = path.CGPath
      
      // Set up rotational animations
      animation.rotationMode = kCAAnimationRotateAuto
      animation.repeatCount = Float.infinity
      animation.duration = 10.0
      // Each object will take between 12.0 and 16.0 seconds
      // to complete one animation loop
      animation.duration = Double(arc4random_uniform(120)+30) / 10
      
      // stagger each animation by a random value
      // `290` was chosen simply by experimentation
      animation.timeOffset = Double(arc4random_uniform(290))
      
      object.layer.addAnimation(animation, forKey: "animate position along path")
      animatedObjects.append(object)
    }
  }
  
  
  private func clearUpAnimations()
  {
    // Only remove animations if there are some that exist already. O(1) if empty
    if animatedObjects.isEmpty
    {
      return
    }
    
    for object in animatedObjects
    {
      object.layer.removeAllAnimations()
      object.removeFromSuperview()
    }
    
    animatedObjects.removeAll()
  }
  

}
