//
//  CameraController.swift
//  ConnectMe
//
//  Created by Austin Vaday on 12/20/15.
//  Copyright © 2015 ConnectMe. All rights reserved.
//

import UIKit
import AVFoundation

class CameraController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {

    var captureSession:AVCaptureSession!
    var videoPreviewLayer:AVCaptureVideoPreviewLayer!
    var scanCodeFrameView:UIView!
    
    override func viewDidLoad() {
        
        // Create capture device object with the appropriate AVCaptureDevice we need for video processing
        let captureDevice = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
        
        let input: AVCaptureInput = try! AVCaptureDeviceInput.init(device: captureDevice)
        
        captureSession = AVCaptureSession()
        captureSession.addInput(input)
        
    }
    

}
