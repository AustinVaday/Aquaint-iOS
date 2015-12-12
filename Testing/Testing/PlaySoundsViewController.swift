//
//  PlaySoundsViewController.swift
//  Testing
//
//  Created by Austin Vaday on 12/11/15.
//  Copyright © 2015 None. All rights reserved.
//

import UIKit
import AVFoundation

class PlaySoundsViewController: UIViewController {
    var audio : AVAudioPlayer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let filePath = NSBundle.mainBundle().pathForResource("movie_quote", ofType: "mp3")

        if (filePath == nil)
        {
            print("Bad file path, please re-check it!")
        }
        else
        {
            let filePathNSURL = NSURL.fileURLWithPath(filePath!)
            audio = try! AVAudioPlayer(contentsOfURL: filePathNSURL)
            
            // Enable rate-changing features
            audio.enableRate = true
        }
        
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func playAudio(rate: Float) {
        audio.stop()
        audio.rate = rate
        audio.currentTime = 0.0
        audio.play()
    }
    
    @IBAction func playSlowRecord(sender: UIButton) {
        playAudio(0.5)
    }

    @IBAction func playFastRecord(sender: AnyObject) {
        playAudio(1.5)
    }
    
    
    @IBAction func stopAudioRecord(sender: UIButton) {
        audio.stop()
    }
    
    
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
