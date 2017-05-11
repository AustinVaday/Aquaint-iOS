//
//  Animations.swift
//  Aquaint
//
//  Created by Austin Vaday on 2/19/17.
//  Copyright © 2017 ConnectMe. All rights reserved.
//

import UIKit

enum AnimationLocation {
  case Top
  case Bottom
  case Middle
}

enum AnimationAquaintEmblemTheme {
  case DarkTheme
  case WhiteTheme
}

func setUpSocialMediaAnimations(viewController: UIViewController, subView: UIView, inout animatedObjects: Array<UIView>, animationLocation: AnimationLocation, theme: AnimationAquaintEmblemTheme)
{

  
  // Only add more animations if none exist already. Prevents user abuse
  if !animatedObjects.isEmpty
  {
    return
  }

  var yLocationDisplacement = CGFloat(0)
  if animationLocation == AnimationLocation.Bottom {
    yLocationDisplacement = CGFloat(viewController.view.frame.size.height) / 1.5
  } else if animationLocation == AnimationLocation.Middle {
    yLocationDisplacement = CGFloat(viewController.view.frame.size.height) / 2
  }
  
  var emblem = "Emblem White"
  if theme == AnimationAquaintEmblemTheme.DarkTheme {
    emblem = "Emblem"
  }
  
  
  var socialMediaImages = Array(getAllPossibleSocialMediaImages().values)
  
  // Add Aquaint emblem to list too ;)
  let aquaintEmblem = UIImage(named: emblem)
  socialMediaImages.append(aquaintEmblem!)
  
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
    path.moveToPoint(CGPoint(x:-20, y:169 - randomYOffset + yLocationDisplacement))
    path.addCurveToPoint(CGPoint(x:viewController.view.frame.width + 50 , y: 169 - randomYOffset + yLocationDisplacement), controlPoint1: CGPoint(x: 136, y: 273 - randomYOffset + yLocationDisplacement), controlPoint2: CGPoint(x: 178, y: 110 - randomYOffset + yLocationDisplacement))
    
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


func clearUpSocialMediaAnimations(inout animatedObjects: Array<UIView>)
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