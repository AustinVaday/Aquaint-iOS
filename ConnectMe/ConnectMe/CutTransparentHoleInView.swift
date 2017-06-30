//
//  CutTransparentHoleInView.swift
//  Aquaint
//
//  Created by Austin Vaday on 2/25/17.
//  Copyright © 2017 ConnectMe. All rights reserved.
//

import UIKit

class CutTransparentHoleInView: UIView {
  
  @IBOutlet weak var transparentHoleView: UIView!
  
  // MARK: - Drawing
  
  override func draw(_ rect: CGRect) {
    super.draw(rect)
    
    if self.transparentHoleView != nil {
      // Ensures to use the current background color to set the filling color
      self.backgroundColor?.setFill()
      UIRectFill(rect)
      
      let layer = CAShapeLayer()
      let path = CGMutablePath()
      
      // Make hole in view's overlay
      // NOTE: Here, instead of using the transparentHoleView UIView we could use a specific CFRect location instead...
      CGPathAddRect(path, nil, self.transparentHoleView.frame)
      CGPathAddRect(path, nil, bounds)
      
      layer.path = path
      layer.fillRule = kCAFillRuleEvenOdd
      self.layer.mask = layer
    }
  }
  
  override func layoutSubviews () {
    super.layoutSubviews()
  }
  
  // MARK: - Initialization
  
  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }
  
  override init(frame: CGRect) {
    super.init(frame: frame)
  }
}
