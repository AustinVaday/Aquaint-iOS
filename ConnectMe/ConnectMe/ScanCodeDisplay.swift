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
import AWSLambda

class ScanCodeDisplay: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
  
  @IBOutlet weak var profileViewsCountNumber: UILabel!
  @IBOutlet weak var profileViewsCountLabel: UILabel!
  
  @IBOutlet weak var engagementCountNumber: UILabel!
  @IBOutlet weak var engagementCountLabel: UILabel!
  
  @IBOutlet weak var codeScansCountNumber: UILabel!
  @IBOutlet weak var codeScansCountLabel: UILabel!
  
  @IBOutlet weak var maskView: CutTransparentHoleInView!
  @IBOutlet weak var cameraView: UIView!
//  @IBOutlet weak var userNameLabel: UILabel!
  @IBOutlet weak var scanCodeImageView: UIImageView!
  
  @IBOutlet weak var firstLineSeparator: UIImageView!
  @IBOutlet weak var secondLineSeparator: UIImageView!
  @IBOutlet weak var thirdLineSeparator: UIImageView!
  
  @IBOutlet weak var cameraButton: UIButton!
  @IBOutlet weak var exitButton: UIButton!
  @IBOutlet weak var exportButton: UIButton!
  @IBOutlet weak var animationView: UIView!
  @IBOutlet weak var usernameLabel: UILabel!
  
  var defaultCameraView: UIView!
  var currentUser: String!
  var animatedObjects = Array<UIView>()
  var captureSession:AVCaptureSession?
  var videoPreviewLayer:AVCaptureVideoPreviewLayer?
  var qrCodeFrameView:UIView?
  
  let aquaBlue = UIColor(red:0.06, green:0.48, blue:0.62, alpha:1.0)
  let blackSeparator = UIImage(named: "Line Separator Black")
  let whiteSeparator = UIImage(named: "Line Separator")
  let reusableWebViewStoryboard = UIStoryboard(name: "ReusableWebView", bundle: nil)

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
  
  var lastScanCodeProcessedTime: Date?
  let SCAN_CODE_PROCESSING_INTERVAL = 3.0  // this should be the maximum time taken to fully show the KLCPopup, so that we guarantee its completion handler is called
  var isShowingUserProfilePopup = false

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    
    // Generate data right when object is generated
    updateAnalyticsDisplayValues()

    
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    defaultCameraView = cameraView
    
//    updateAnalyticsDisplayValues()

    maskView.transparentHoleView = self.scanCodeImageView
    maskView.draw(maskView.frame)
    
    currentUser = getCurrentCachedUser()
    
    if currentUser != nil {
      usernameLabel.text = currentUser
    }
    
    fetchUserScanCode()
    
    // TEMP FIX: When user initially logs in (and doesn't have a scan code), some race conditions may occur where the code is not ready to fetch before we display. Add a delay to fix this if it does happen
    delay(2.0) {
      self.fetchUserScanCode()
    }
    
  }
  
  override func viewDidAppear(_ animated: Bool) {
    setUpSocialMediaAnimations(self, subView: self.animationView, animatedObjects: &animatedObjects, animationLocation: AnimationLocation.bottom, theme: AnimationAquaintEmblemTheme.darkTheme)
    updateAnalyticsDisplayValues()
    
    fetchUserScanCode()
    
    updateAnalyticsDisplayValues()

    awsMobileAnalyticsRecordPageVisitEventTrigger("ScanCodeDisplay", forKey: "page_name")
    
  }
  
  override func viewDidDisappear(_ animated: Bool) {
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
  @IBAction func onExportButtonClicked(_ sender: AnyObject) {
    
    
    let textToShare = "Take a look at all my social profiles on Aquaint by scanning this code or going to: www.aquaint.us/user/" + currentUser
    let shareItems = [self.scanCodeImageView.image!, textToShare] as [Any]
    let activityVC = UIActivityViewController(activityItems: shareItems, applicationActivities: nil)
    
    DispatchQueue.main.async { 
      self.present(activityVC, animated: true, completion: nil)
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
          
          DispatchQueue.main.async(execute: {
            self.scanCodeImageView.image = scanCode
          })
        }
        
      })
   
    } else {
      
      DispatchQueue.main.async(execute: {
        self.scanCodeImageView.image = scanCode
      })
    }
    
  }
  
  @IBAction func onCameraButtonClicked(_ sender: AnyObject) {
    // Perform update on UI on main thread
    DispatchQueue.main.async(execute: { () -> Void in
      UIView.transition(with: self.scanCodeImageView, duration: 1, options: UIViewAnimationOptions.transitionCrossDissolve, animations: { () -> Void in
          self.scanCodeImageView.isHidden = true
          self.maskView.isHidden = false
          self.exportButton.isHidden = true
          self.profileViewsCountLabel.textColor = UIColor.white
          self.profileViewsCountNumber.textColor = UIColor.white
          self.engagementCountLabel.textColor = UIColor.white
          self.engagementCountNumber.textColor = UIColor.white
          self.codeScansCountLabel.textColor = UIColor.white
          self.codeScansCountNumber.textColor = UIColor.white
          self.firstLineSeparator.image = self.whiteSeparator
          self.secondLineSeparator.image = self.whiteSeparator
          self.thirdLineSeparator.image = self.whiteSeparator
          self.cameraButton.isHidden = true
          self.exitButton.isHidden = false
          self.usernameLabel.isHidden = true
        
        }, completion: { (status) in
          // Show camera view
          DispatchQueue.main.async(execute: {
              self.cameraView.isHidden = false
              self.setUpCameraDisplay()
          })
        })

    })

  }
  
  @IBAction func onExitButtonClicked(_ sender: AnyObject) {
    self.scanCodeImageView.isHidden = false
    self.maskView.isHidden = true
    self.exportButton.isHidden = false
    self.profileViewsCountNumber.textColor = self.aquaBlue
    self.profileViewsCountLabel.textColor = self.aquaBlue
    self.codeScansCountNumber.textColor = self.aquaBlue
    self.codeScansCountLabel.textColor = self.aquaBlue
    self.engagementCountNumber.textColor = self.aquaBlue
    self.engagementCountLabel.textColor = self.aquaBlue
    self.firstLineSeparator.image = self.blackSeparator
    self.secondLineSeparator.image = self.blackSeparator
    self.thirdLineSeparator.image = self.blackSeparator
    self.cameraButton.isHidden = false
    self.exitButton.isHidden = true
    self.usernameLabel.isHidden = false
    
    // Clear the camera display?
    captureSession?.stopRunning()
    //self.view.backgroundColor = UIColor.whiteColor()
    //self.cameraView.backgroundColor = UIColor.clearColor()
    
    //cameraView = defaultCameraView
    cameraView.isHidden = true
    
  }
  @IBAction func onShowHelpCodeScans(_ sender: AnyObject) {
    showHelpPopup("Code Scans", description: "This feature allows you to see how many people viewed your Aquaint profile directly from your Aquaint scan code. We track data on both the Aquaint mobile app and Aquaint website (hint: If you didn't know already, you can view your Aquaint profile on the web at www.aquaint.us/user/" + currentUser + ")!")
  }
  
  @IBAction func onShowHelpProfileViews(_ sender: AnyObject) {
    showHelpPopup("Profile Views", description: "This feature allows you to see how many people viewed your Aquaint profile in the app and on your web profile. We track data on both the Aquaint mobile app and Aquaint website (hint: If you didn't know already, you can view your Aquaint profile on the web at www.aquaint.us/user/" + currentUser + ")!")
  }
  
  @IBAction func onShowHelpEngagements(_ sender: AnyObject) {
    showHelpPopup("Engagements", description: "This feature allows you to see how many people actually clicked on the social media profiles you provided. If you want to see more data such as the number of engagements per social media platform, please check out our advanced analytics features!")
  }
  
//  @IBAction func onMoreFeaturesButtonClicked(sender: AnyObject) {
//    // Takes advantage of the fact that we know our grandparent is MainPageViewController
//    let parentViewController = self.parentViewController?.parentViewController as! MainPageViewController
//    parentViewController.goToAnalyticsPage()
//  }
  @IBAction func coolTipsAndTricksButtonClicked(_ sender: AnyObject) {
    let webDisplayVC = reusableWebViewStoryboard.instantiateViewController(withIdentifier: "reusableWebViewController") as! ReusableWebViewController
    
    webDisplayVC.webTitle = "Cool Tricks"
    webDisplayVC.webURL = "http://www.aquaint.us/static/cool-tricks"
    webDisplayVC.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
    self.present(webDisplayVC, animated: true, completion: nil)
  }

  @IBAction func onYourWebProfileClicked(_ sender: AnyObject) {
    let webDisplayVC = reusableWebViewStoryboard.instantiateViewController(withIdentifier: "reusableWebViewController") as! ReusableWebViewController
    
//    webDisplayVC.copyLinkButton.hidden = false
    webDisplayVC.webTitle = "aquaint.us/user/" + currentUser
    webDisplayVC.webURL = "http://www.aquaint.us/user/" + currentUser
    webDisplayVC.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
    self.present(webDisplayVC, animated: true, completion: nil)
  }
  
  @IBAction func onScanCodeImageClicked(_ sender: AnyObject) {
    let webDisplayVC = reusableWebViewStoryboard.instantiateViewController(withIdentifier: "reusableWebViewController") as! ReusableWebViewController
    
//    webDisplayVC.copyLinkButton.hidden = false
    webDisplayVC.webTitle = "aquaint.us/user/" + currentUser
    webDisplayVC.webURL = "http://www.aquaint.us/user/" + currentUser
    webDisplayVC.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
    self.present(webDisplayVC, animated: true, completion: nil)
  }
  
  func setUpCameraDisplay() {
    // Get an instance of the AVCaptureDevice class to initialize a device object and provide the video as the media type parameter.
    //let captureDevice = AVCaptureDevice.defaultDeviceWithMediaType("AVMediaTypeVideo")
    let captureDevice = AVCaptureDevice.devices().filter({ ($0 as AnyObject).position == .back }).first as? AVCaptureDevice
    
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
      captureMetadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
      captureMetadataOutput.metadataObjectTypes = supportedCodeTypes
      
      // Initialize the video preview layer and add it as a sublayer to the viewPreview view's layer.
      videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
      videoPreviewLayer?.videoGravity = AVLayerVideoGravityResizeAspectFill
      videoPreviewLayer?.frame = cameraView.layer.bounds

      cameraView.layer.addSublayer(videoPreviewLayer!)
      
      // Start video capture.
      captureSession?.startRunning()
      
      // Initialize QR Code Frame to highlight the QR code
      qrCodeFrameView = UIView()
      
//      if let qrCodeFrameView = qrCodeFrameView {
//        qrCodeFrameView.layer.borderColor = UIColor.blueColor().CGColor
//        qrCodeFrameView.layer.borderWidth = 3
//        view.addSubview(qrCodeFrameView)
//        view.bringSubviewToFront(qrCodeFrameView)
//      }
      
    } catch {
      // If any error occurs, simply print it out and don't continue any more.
      print(error)
      
      return
    }

  }
  
  func updateAnalyticsDisplayValues()
  {
    var username: String!
    username = getCurrentCachedUser()

    if (username == nil)
    {
      return
    }
    
    let lambdaInvoker = AWSLambdaInvoker.default()
    var parameters = ["action":"getUserPageViews", "target": username]
    
    lambdaInvoker.invokeFunction("mock_api", jsonObject: parameters).continue { (resultTask) -> AnyObject? in
      if resultTask.error == nil && resultTask.result != nil
      {
        print("Result task for getUserPageViews is: ", resultTask.result!)
        DispatchQueue.main.async(execute: {
          let number = resultTask.result as? Int
          self.profileViewsCountNumber.text  = String(number!)
        })
      }
      
      return nil
    }
    
    parameters = ["action":"getUserCodeScans", "target": username]
    
    lambdaInvoker.invokeFunction("mock_api", jsonObject: parameters).continue { (resultTask) -> AnyObject? in
      if resultTask.error == nil && resultTask.result != nil
      {
        print("Result task for getUserCodeScans is: ", resultTask.result!)
        DispatchQueue.main.async(execute: {
          let number = resultTask.result as? Int
          self.codeScansCountNumber.text  = String(number!)
        })
      }
      
      return nil
    }
    
    parameters = ["action":"getUserTotalEngagements", "target": username]
    lambdaInvoker.invokeFunction("mock_api", jsonObject: parameters).continue { (resultTask) -> AnyObject? in
      if resultTask.error == nil && resultTask.result != nil
      {
        print("Result task for getUserTotalEngagements is: ", resultTask.result!)
        DispatchQueue.main.async(execute: {
          let number = resultTask.result as? Int
          self.engagementCountNumber.text = String(number!)
        })

      }
      
      return nil
    }
    
  }
  
  
  func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [Any]!, from connection: AVCaptureConnection!) {
    
    // Check if the metadataObjects array is not nil and it contains at least one object.
    if metadataObjects == nil || metadataObjects.count == 0 {
      qrCodeFrameView?.frame = CGRect.zero
      print("Nothing detected yet")
      return
    }
    
    // Get the metadata object.
    let metadataObj = metadataObjects[0] as! AVMetadataMachineReadableCodeObject
    
    if supportedCodeTypes.contains(metadataObj.type) {
      // If the found metadata is equal to the QR code metadata then update the status label's text and set the bounds
      let barCodeObject = videoPreviewLayer?.transformedMetadataObject(for: metadataObj)
      qrCodeFrameView?.frame = barCodeObject!.bounds
    
      if metadataObj.stringValue != nil {
        
        //GOAL: PARSE www.aquaint.us/user/[DATA]
        //NOTE: This has been tested and should work.
        let scancodeString = metadataObj.stringValue
        let url = URL(string: scancodeString!)
        var userName: String!
        
        print("URL HOST: ", url?.host)
        print("URL PATH: ", url?.path)
        print("URL PATH COMPONENTS: ", url?.pathComponents)
        print("URL LAST PATH COMP:", url?.lastPathComponent)
        
        // Check if host of QR code is ours, else we do not process
        if url?.host == "www.aquaint.us" {
          
          // Check if scan code should be processed now #1: keep the PROCESSING_INTERVAL check to give the first user profile popup enough time to be fully shown
          // Moving to check #2 after the isShowingUserProfilePopup flag is set
          if let scanCodeProcessedTime = lastScanCodeProcessedTime {
            let currentDate = Date.init()
            if (currentDate.timeIntervalSince(scanCodeProcessedTime) <= SCAN_CODE_PROCESSING_INTERVAL) {
                print("scanCodeDisplay(): PROCESSING_INTERVAL: scan code is already processed; ignore current request.")
                return;
              } else {
                lastScanCodeProcessedTime = Date.init()
              }
          } else {
            lastScanCodeProcessedTime = Date.init()
          }
          
          // Check if scan code should be processed now #2
          if isShowingUserProfilePopup == true {
            print ("scanCodeDisplay(): isShowingUserProfilePopup: scan code is already processed; ignore current request.")
            return
          } else {
            print ("scanCodeDisplay(): processing current code scan...")
          }
          
          userName = url?.lastPathComponent
          
          // Check if extracted username is a valid aquaint username
          if verifyUserNameFormat(userName) && verifyUserNameLength(userName) {
            DispatchQueue.main.async(execute: { 
              showPopupForUserFromScanCode(userName, me: getCurrentCachedUser(), sender: self)
              
              // Send view trigger (Code Scans) to Google Analytics
              let tracker = GAI.sharedInstance().defaultTracker
              let GApageName = "/user/" + userName + "/iOS/scan"
              tracker?.set(kGAIPage, value: GApageName)
              
              let builder = GAIDictionaryBuilder.createScreenView()
              tracker?.send(builder?.build() as! [AnyHashable: Any])
              
              print("scanCodeDisplay(): trigger Google Analytics for Code Scan: \(GApageName)")
            })
          } else {
            print ("Error, could not verify proper username format")
          }
          
        }
        else {
          
          // Show URL in browser
          let reusableWebViewStoryboard = UIStoryboard(name: "ReusableWebView", bundle: nil)
          let webDisplayVC = reusableWebViewStoryboard.instantiateViewController(withIdentifier: "reusableWebViewController") as! ReusableWebViewController
          webDisplayVC.webTitle = url?.host
          webDisplayVC.webURL = url?.absoluteString
          webDisplayVC.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
          
          // Present only if not presented
          if self.presentingViewController?.presentedViewController == nil {
            self.present(webDisplayVC, animated: true, completion: nil)
          }
        }
        
      }
    }
  }

}
