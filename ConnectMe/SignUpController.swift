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
    
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var userEmailLabel: UILabel!
    @IBOutlet weak var userPasswordLabel: UILabel!
    
    @IBOutlet weak var userNameImage: UIImageView!
    @IBOutlet weak var userEmailImage: UIImageView!
    @IBOutlet weak var userPasswordImage: UIImageView!

    @IBOutlet weak var userNameImageError: UIImageView!
    @IBOutlet weak var userEmailImageError: UIImageView!
    @IBOutlet weak var userPasswordImageError: UIImageView!
    
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
        userObject  = User()
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
    
    // When user finishes picking an image, this function is called and we set the user's image
    func imagePickerController(picker: UIImagePickerController, didFinishPickingImage image: UIImage, editingInfo: [NSObject : AnyObject]?) {
        
        // Close the image picker view when user is finished with it
        self.dismissViewControllerAnimated(true, completion: nil)
    
        // Set the button's new image
        userPhoto.setImage(image, forState: UIControlState.Normal)
        
        // Store the image into the userObject
        userObject.image = image
        
    }
    
    // EditingDidEnd functionality will be used for error checking user input
    @IBAction func nameEditingDidEnd(sender: UITextField) {
        
        // Store the text inside the field. Make sure it's unwrapped by using a '!'.
        let userNameString:String =  userName.text!
        
        print(userNameString)
        
        // Check if text field is empty
        if userNameString.isEmpty
        {
            userNameLabel.textColor = UIColor.redColor()
            userNameImage.hidden = true
            userNameImageError.hidden = false
        }
        else
        {
            userNameLabel.textColor = UIColor.whiteColor()
            userNameImageError.hidden = true
            userNameImage.hidden = false
        }
        //TODO: Escape every single character of the string
        
        // We do not have to ensure each user name is unique, because many people might have the same name.
        
        userObject.name = userNameString

    }
    
    @IBAction func emailEditingDidEnd(sender: AnyObject) {
        
        // Store the text inside the field. Make sure it's unwrapped by using a '!'.
        let userEmailString:String =  userEmail.text!
        
        // Check if text field is empty
        if userEmailString.isEmpty
        {
            print("EMPTY FIELD")
        }
        
        //TODO: Escape every single character of the string
        
        //TODO: Ensure email is not already taken (in database)
        
        userObject.email = userEmailString
        
    }
    
    @IBAction func passwordEditingDidEnd(sender: AnyObject) {
        
        // Store the text inside the field. Make sure it's unwrapped by using a '!'.
        let userPasswordString:String =  userPassword.text!
        
        // Check if text field is empty
        if userPasswordString.isEmpty
        {
            print("EMPTY FIELD")
        }
        
        //TODO: Ensure password is at least 4 characters!
        
        //TODO: Escape every single character of the string
        
        userObject.password = userPasswordString
    }
    
    // Actions to perform when "Sign Up" is clicked
    @IBAction func signUpButtonClicked(sender: AnyObject) {
        print("Do something here")
        
        //TODO: PROCESS THE TEXT
    }
    
}
