//
//  MenuButtonTableViewCell.swift
//  Aquaint
//
//  Created by Austin Vaday on 7/27/16.
//  Copyright © 2016 ConnectMe. All rights reserved.
//

import UIKit

class MenuButtonTableViewCell: UITableViewCell {
  enum ToggleType: Int {
    case PRIVATE_PROFILE
  }

  @IBOutlet weak var menuButtonLabel: UITextField!
  @IBOutlet weak var menuToggleSwitch: UISwitch!
  var toggleType : ToggleType!
  
  @IBAction func toggleButtonToggled(sender: AnyObject) {
    if toggleType == ToggleType.PRIVATE_PROFILE {
      print ("toggle for private profile initiated")
    }
  }
}
