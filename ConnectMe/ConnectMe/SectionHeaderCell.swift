//
//  SectionHeaderCell.swift
//  
//
//  Created by Austin Vaday on 7/26/16.
//
//

import UIKit


protocol EditSectionDelegate {
  func editSectionButtonClicked(sectionTitle: String)
  func cancelSectionButtonClicked(sectionTitle: String)
  func saveSectionButtonClicked(sectionTitle: String)
}
class SectionHeaderCell: UITableViewCell {

  @IBOutlet weak var sectionTitle: UILabel!
  @IBOutlet weak var editSection: UIButton!
  @IBOutlet weak var saveSection: UIButton!
  @IBOutlet weak var cancelSection: UIButton!
  @IBOutlet weak var editView: UIView!
  
  var editSectionDelegate : EditSectionDelegate?
  
  
  @IBAction func onEditSectionDelegateClicked(sender: AnyObject) {
    self.cancelSection.hidden = false
    self.saveSection.hidden = false
    self.editSection.hidden = true
    
    if editSectionDelegate != nil {
      editSectionDelegate?.editSectionButtonClicked(sectionTitle.text!)
    }
  }
  
  
  @IBAction func onSaveSectionClicked(sender: AnyObject) {
    self.cancelSection.hidden = true
    self.saveSection.hidden = true
    self.editSection.hidden = false
    
    if editSectionDelegate != nil {
      editSectionDelegate?.saveSectionButtonClicked(sectionTitle.text!)
    }

  }
  
  @IBAction func onCancelSectionClicked(sender: AnyObject) {
    self.cancelSection.hidden = true
    self.saveSection.hidden = true
    self.editSection.hidden = false
    
    if editSectionDelegate != nil {
      editSectionDelegate?.cancelSectionButtonClicked(sectionTitle.text!)
    }

  }
  
  
}
