//
//  CameraController.swift
//  ConnectMe
//
//  Created by Austin Vaday on 12/20/15.
//  Copyright © 2015 ConnectMe. All rights reserved.
//
//
//  Code is owned by: Austin Vaday and Navid Sarvian


import UIKit
import AVFoundation

class CameraController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {


    @IBOutlet weak var previewView: UIView!
    var captureSession:AVCaptureSession!
    var videoPreviewLayer:AVCaptureVideoPreviewLayer!
    var scanCodeFrameView:UIView!
    
    override func viewWillAppear(animated: Bool) {
        
//        //Create a capture session
//        captureSession = AVCaptureSession()
//        
//        print ("TESTING0")
//
//        // Configure session - We need a capture session that captures a still image
//        captureSession.sessionPreset = AVCaptureSessionPresetPhoto
//        
//        
//        let rearCamera = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
//        let input = try! AVCaptureDeviceInput(device: rearCamera)
//        
//        
//        print ("TESTING")
//        captureSession.addInput(input)
//        videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
//        previewView.layer.addSublayer(videoPreviewLayer)
//
//        print("TESTING 2")
//        videoPreviewLayer.frame = previewView.bounds

    }
    
    override func viewDidLoad() {
        
//        // Create capture device object with the appropriate AVCaptureDevice we need for video processing
//        let captureDevice = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
//        
//        let input: AVCaptureInput = try! AVCaptureDeviceInput.init(device: captureDevice)

        
        
    }
    

}
