//
//  SignUpController.swift
//  ConnectMe
//
//  Created by Austin Vaday on 12/13/15.
//  Copyright © 2015 ConnectMe. All rights reserved.
//

import UIKit

class SignUpController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    // UI variable data types
    @IBOutlet weak var userName: UITextField!
    @IBOutlet weak var userEmail: UITextField!
    @IBOutlet weak var userPassword: UITextField!
    @IBOutlet weak var userPhoto: UIButton!
    
    // Used for selecting image from user's device
    var imagePicker:UIImagePickerController = UIImagePickerController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // Functionality for adding in a user specific photograph
    @IBAction func addPhotoButtonClicked(sender: UIButton) {
        
        imagePicker.delegate = self
        imagePicker.sourceType = UIImagePickerControllerSourceType.SavedPhotosAlbum
        imagePicker.allowsEditing = false
        self.presentViewController(imagePicker, animated: true, completion: nil)
        
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingImage image: UIImage, editingInfo: [String : AnyObject]?) {
        
        // Close the image picker view when user is finished with it
        self.dismissViewControllerAnimated(true, completion: nil)

        // TODO: Fix the below.
//        userPhoto.setImage(image, forState: UIControlState.Application)
        
    }
    
    
    // EditingDidEnd functionality will be used for error checking user input
    @IBAction func nameEditingDidEnd(sender: UITextField) {
        print(userName.text)
        
    }
    
    @IBAction func emailEditingDidEnd(sender: AnyObject) {
        print(userEmail.text)
    }
    
    @IBAction func passwordEditingDidEnd(sender: AnyObject) {
        print(userPassword.text)
    }
    
    // Actions to perform when "Sign Up" is clicked
    @IBAction func signUpButtonClicked(sender: AnyObject) {
        print("Do something here")
    }
    
}
