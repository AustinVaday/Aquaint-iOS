//
//  SectionHeaderCell.swift
//  
//
//  Created by Austin Vaday on 7/26/16.
//
//

import UIKit


protocol EditSectionDelegate {
  func editSectionButtonClicked(_ sectionTitle: String)
  func cancelSectionButtonClicked(_ sectionTitle: String)
  func saveSectionButtonClicked(_ sectionTitle: String)
}
class SectionHeaderCell: UITableViewCell {

  @IBOutlet weak var sectionTitle: UILabel!
  @IBOutlet weak var editSection: UIButton!
  @IBOutlet weak var saveSection: UIButton!
  @IBOutlet weak var cancelSection: UIButton!
  @IBOutlet weak var editView: UIView!
  
  var editSectionDelegate : EditSectionDelegate?
  
  
  @IBAction func onEditSectionDelegateClicked(_ sender: AnyObject) {
    self.cancelSection.isHidden = false
    self.saveSection.isHidden = false
    self.editSection.isHidden = true
    
    if editSectionDelegate != nil {
      editSectionDelegate?.editSectionButtonClicked(sectionTitle.text!)
    }
  }
  
  
  @IBAction func onSaveSectionClicked(_ sender: AnyObject) {
    self.cancelSection.isHidden = true
    self.saveSection.isHidden = true
    self.editSection.isHidden = false
    
    if editSectionDelegate != nil {
      editSectionDelegate?.saveSectionButtonClicked(sectionTitle.text!)
    }

  }
  
  @IBAction func onCancelSectionClicked(_ sender: AnyObject) {
    self.cancelSection.isHidden = true
    self.saveSection.isHidden = true
    self.editSection.isHidden = false
    
    if editSectionDelegate != nil {
      editSectionDelegate?.cancelSectionButtonClicked(sectionTitle.text!)
    }

  }
  
  
}
