//
//  ScanCodeDisplay.swift
//  Aquaint
//
//  Created by Austin Vaday on 2/19/17.
//  Copyright © 2017 ConnectMe. All rights reserved.
//

import UIKit
import AVFoundation
import CoreGraphics

class ScanCodeDisplay: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
  

  @IBOutlet weak var scanCountLabel: UILabel!
  @IBOutlet weak var scanCountNumber: UILabel!
  @IBOutlet weak var cameraView: CutTransparentHoleInView!
  @IBOutlet weak var userNameLabel: UILabel!
  @IBOutlet weak var scanCodeImageView: UIImageView!
  @IBOutlet weak var lineSeparator: UIImageView!
  @IBOutlet weak var cameraButton: UIButton!
  @IBOutlet weak var exitButton: UIButton!
  @IBOutlet weak var exportButton: UIButton!
  
  var animatedObjects = Array<UIView>()
  var captureSession:AVCaptureSession?
  var videoPreviewLayer:AVCaptureVideoPreviewLayer?
  var qrCodeFrameView:UIView?
  
  let aquaBlue = UIColor(red:0.06, green:0.48, blue:0.62, alpha:1.0)
  let blackSeparator = UIImage(named: "Line Separator Black")
  let whiteSeparator = UIImage(named: "Line Separator")
  
  let supportedCodeTypes = [AVMetadataObjectTypeUPCECode,
                            AVMetadataObjectTypeCode39Code,
                            AVMetadataObjectTypeCode39Mod43Code,
                            AVMetadataObjectTypeCode93Code,
                            AVMetadataObjectTypeCode128Code,
                            AVMetadataObjectTypeEAN8Code,
                            AVMetadataObjectTypeEAN13Code,
                            AVMetadataObjectTypeAztecCode,
                            AVMetadataObjectTypePDF417Code,
                            AVMetadataObjectTypeQRCode]

  override func viewDidLoad() {
    super.viewDidLoad()
    
    cameraView.transparentHoleView = self.scanCodeImageView
    cameraView.drawRect(cameraView.frame)
    
    let currentUser = getCurrentCachedUser()
    
    if currentUser != nil {
      userNameLabel.text = currentUser
    }
    
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
  
  @IBAction func onCameraButtonClicked(sender: AnyObject) {
    // Perform update on UI on main thread
    dispatch_async(dispatch_get_main_queue(), { () -> Void in
      UIView.transitionWithView(self.scanCodeImageView, duration: 1, options: UIViewAnimationOptions.TransitionCrossDissolve, animations: { () -> Void in
          self.scanCodeImageView.hidden = true
          self.cameraView.hidden = false
          self.exportButton.hidden = true
          self.scanCountNumber.textColor = UIColor.whiteColor()
          self.scanCountLabel.textColor = UIColor.whiteColor()
          self.lineSeparator.image = self.whiteSeparator
          self.cameraButton.hidden = true
          self.exitButton.hidden = false
        
        }, completion: { (status) in
          // Show camera view
          dispatch_async(dispatch_get_main_queue(), {
              self.setUpCameraDisplay()
          })
        })

    })

  }
  
  @IBAction func onExitButtonClicked(sender: AnyObject) {
    self.scanCodeImageView.hidden = false
    self.cameraView.hidden = true
    self.exportButton.hidden = false
    self.scanCountNumber.textColor = self.aquaBlue
    self.scanCountLabel.textColor = self.aquaBlue
    self.lineSeparator.image = self.blackSeparator
    self.cameraButton.hidden = false
    self.exitButton.hidden = true
    
    // Clear the camera display?
  }
  

  func setUpCameraDisplay() {
    // Get an instance of the AVCaptureDevice class to initialize a device object and provide the video as the media type parameter.
    let captureDevice = AVCaptureDevice.defaultDeviceWithMediaType("AVMediaTypeVideo")
    do {
      // Get an instance of the AVCaptureDeviceInput class using the previous device object.
      let input = try AVCaptureDeviceInput(device: captureDevice)
      
      // Initialize the captureSession object.
      captureSession = AVCaptureSession()
      
      // Set the input device on the capture session.
      captureSession?.addInput(input)
      
      // Initialize a AVCaptureMetadataOutput object and set it as the output device to the capture session.
      let captureMetadataOutput = AVCaptureMetadataOutput()
      captureSession?.addOutput(captureMetadataOutput)
      
      // Set delegate and use the default dispatch queue to execute the call back
      captureMetadataOutput.setMetadataObjectsDelegate(self, queue: dispatch_get_main_queue())
      captureMetadataOutput.metadataObjectTypes = supportedCodeTypes
      
      // Initialize the video preview layer and add it as a sublayer to the viewPreview view's layer.
      videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
      videoPreviewLayer?.videoGravity = AVLayerVideoGravityResizeAspectFill
      videoPreviewLayer?.frame = view.layer.bounds

      view.layer.addSublayer(videoPreviewLayer!)
      
      // Start video capture.
      captureSession?.startRunning()
      
      // Initialize QR Code Frame to highlight the QR code
      qrCodeFrameView = UIView()
      
      if let qrCodeFrameView = qrCodeFrameView {
        qrCodeFrameView.layer.borderColor = UIColor.blueColor().CGColor
        qrCodeFrameView.layer.borderWidth = 3
        view.addSubview(qrCodeFrameView)
        view.bringSubviewToFront(qrCodeFrameView)
      }
      
    } catch {
      // If any error occurs, simply print it out and don't continue any more.
      print(error)
      
      return
    }

  }
  
  func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [Any]!, from connection: AVCaptureConnection!) {
    
    // Check if the metadataObjects array is not nil and it contains at least one object.
    if metadataObjects == nil || metadataObjects.count == 0 {
      qrCodeFrameView?.frame = CGRect.zero
      //      messageLabel.text = "No QR/barcode is detected"
      return
    }
    
    // Get the metadata object.
    let metadataObj = metadataObjects[0] as! AVMetadataMachineReadableCodeObject
    
    if supportedCodeTypes.contains(metadataObj.type) {
      // If the found metadata is equal to the QR code metadata then update the status label's text and set the bounds
      let barCodeObject = videoPreviewLayer?.transformedMetadataObjectForMetadataObject(metadataObj)
      qrCodeFrameView?.frame = barCodeObject!.bounds
      
      //      if metadataObj.stringValue != nil {
      //        messageLabel.text = metadataObj.stringValue
      //      }
    }
  }

}
