//
//  ScanCodeDisplay.swift
//  Aquaint
//
//  Created by Austin Vaday on 2/19/17.
//  Copyright © 2017 ConnectMe. All rights reserved.
//

import UIKit

class ScanCodeDisplay: UIViewController {
  
  @IBOutlet weak var scanCodeImageView: UIImageView!
  var animatedObjects = Array<UIView>()

  override func viewDidLoad() {
    super.viewDidLoad()
    
    fetchUserScanCode()
  }
  
  override func viewDidAppear(animated: Bool) {
    setUpSocialMediaAnimations(self, subView: self.view, animatedObjects: &animatedObjects, animationLocation: AnimationLocation.Bottom, theme: AnimationAquaintEmblemTheme.DarkTheme)
  }
  
  override func viewDidDisappear(animated: Bool) {
    clearUpSocialMediaAnimations(&animatedObjects)
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
  
  /*
   // MARK: - Navigation
   
   // In a storyboard-based application, you will often want to do a little preparation before navigation
   override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
   // Get the new view controller using segue.destinationViewController.
   // Pass the selected object to the new view controller.
   }
   */
  @IBAction func onExportButtonClicked(sender: AnyObject) {
    let actionSheet = UIAlertController(title: "Export options", message: nil, preferredStyle: UIAlertControllerStyle.ActionSheet)
    
    let shareItems = [self.scanCodeImageView.image!]
    let activityVC = UIActivityViewController(activityItems: shareItems, applicationActivities: nil)
    
//    let saveAction = UIAlertAction(title: "Save to phone", style: UIAlertActionStyle.Default) { (action) in
//      dispatch_async(dispatch_get_main_queue(), { 
//        UIImageWriteToSavedPhotosAlbum(self.scanCodeImageView.image!, nil, nil, nil)
//      })
//    }
//    let shareAction = UIAlertAction(title: "Share with friends", style: UIAlertActionStyle.Default) { (action) in
//      //
//    }
//    let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel) { (action) in
//      //
//    }
//
//    actionSheet.addAction(saveAction)
//    actionSheet.addAction(shareAction)
//    actionSheet.addAction(cancelAction)
    
    dispatch_async(dispatch_get_main_queue()) { 
      self.presentViewController(activityVC, animated: true, completion: nil)
    }
    
    
  
  }
  
  func fetchUserScanCode()
  {
    let user = getCurrentCachedUser()
    var scanCode = getCurrentCachedUserScanCode()
    
    if scanCode == nil {
      getUserS3Image(user, extraPath: "scancodes/", completion: { (result, error) in
        if result != nil && error == nil
        {
          scanCode = result as UIImage!
          setCurrentCachedUserScanCode(scanCode)
          
          dispatch_async(dispatch_get_main_queue(), {
            self.scanCodeImageView.image = scanCode
          })
        }
        
      })
   
    } else {
      
      dispatch_async(dispatch_get_main_queue(), {
        self.scanCodeImageView.image = scanCode
      })
    }
    
  }

}
