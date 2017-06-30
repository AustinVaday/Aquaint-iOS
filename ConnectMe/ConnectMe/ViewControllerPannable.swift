//
//  ViewControllerPannable.swift
//  Aquaint
//
//  Created by Austin Vaday on 5/20/17.
//  Copyright © 2017 ConnectMe. All rights reserved.
//


// SOURCE: http://stackoverflow.com/questions/29290313/in-ios-how-to-drag-down-to-dismiss-a-modal/29290426
import Foundation

class ViewControllerPannable: UIViewController {
  var panGestureRecognizer: UIPanGestureRecognizer?
  var originalPosition: CGPoint?
  var currentPositionTouched: CGPoint?
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(panGestureAction))
    view.addGestureRecognizer(panGestureRecognizer!)
  }
  
  func panGestureAction(_ panGesture: UIPanGestureRecognizer) {
    let translation = panGesture.translation(in: view)
    
    if panGesture.state == .began {
      originalPosition = view.center
      currentPositionTouched = panGesture.location(in: view)
    } else if panGesture.state == .changed {
      
      // Ignore if user tries to swipe in opposite direction
      if translation.x >= 0 {
        view.frame.origin = CGPoint(
          x: translation.x,
          y: view.frame.origin.y
        )
      }
      
      print("TRANSLATION X IS: ", translation.x)
      print("VIEW SIZE: ", view.frame.size.width)
      print("CURRENT POSITION TOUCHED X: ", view.frame.origin.x)
    } else if panGesture.state == .ended {
      let velocity = panGesture.velocity(in: view)
      
      if velocity.x >= 500 || view.frame.origin.x > view.frame.size.width / 2 {
        UIView.animate(withDuration: 0.2
          , animations: {
            self.view.frame.origin = CGPoint(
              x: self.view.frame.size.width,
              y: self.view.frame.origin.y
            )
          }, completion: { (isCompleted) in
            if isCompleted {
              self.dismiss(animated: false, completion: nil)
            }
        })
      } else {
        UIView.animate(withDuration: 0.2, animations: {
          self.view.center = self.originalPosition!
        })
      }
    }
  }
}
