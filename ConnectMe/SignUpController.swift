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
    
    var userObject : User!
    
    
    // Used for selecting image from user's device
    var imagePicker:UIImagePickerController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from 
        
        // Make the button round!
        userPhoto.clipsToBounds = true
        userPhoto.layer.cornerRadius = userPhoto.bounds.size.width / 2
    
    }
    
    override func viewDidAppear(animated: Bool) {
        //TODO: INVESTIGATE UIImagePickerController class
        // The following initialization, for some reason, takes longer than usual. Doing this AFTER the view appears so that there's no obvious delay in any transitions.
        imagePicker = UIImagePickerController()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // Functionality for adding in a user specific photograph
    @IBAction func addPhotoButtonClicked(sender: UIButton) {
        
        
        // Present the Saved Photo Album to user only if it is available
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.SavedPhotosAlbum)
        {
            imagePicker.delegate = self
            imagePicker.sourceType = UIImagePickerControllerSourceType.SavedPhotosAlbum
            imagePicker.allowsEditing = false
            self.presentViewController(imagePicker, animated: true, completion: nil)
        }
        
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingImage image: UIImage, editingInfo: [NSObject : AnyObject]?) {
        
        // Close the image picker view when user is finished with it
        self.dismissViewControllerAnimated(true, completion: nil)
    
        // TODO: Fix the below.
        userPhoto.setImage(image, forState: UIControlState.Normal)
        
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
        
        //TODO: PROCESS THE TEXT
    }
    
}
