//
//  AnalyticsContentTableViewCell.swift
//  Aquaint
//
//  Created by Austin Vaday on 3/28/17.
//  Copyright © 2017 ConnectMe. All rights reserved.
//

import UIKit

class AnalyticsContentTableViewCell: UITableViewCell {

  @IBOutlet weak var socialProviderLabel: UILabel!
  @IBOutlet weak var numericalValueLabel: UILabel!
  @IBOutlet weak var numericalTypeLabel: UILabel!
  
  override func awakeFromNib() {
    super.awakeFromNib()
    // Initialization code
  }
  
  override func setSelected(selected: Bool, animated: Bool) {
    super.setSelected(selected, animated: animated)
    
    // Configure the view for the selected state
  }

}
