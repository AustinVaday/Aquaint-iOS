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
    
    var audioPlayer : AVAudioPlayer!
    var audioEngine : AVAudioEngine = AVAudioEngine()
    var audioFile : AVAudioFile!
    
    var receivedAudio: RecordedAudio!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        let filePath = NSBundle.mainBundle().pathForResource("movie_quote", ofType: "mp3")
//
//        if (filePath == nil)
//        {
//            print("Bad file path, please re-check it!")
//        }
//        else
//        {
//            let filePathNSURL = NSURL.fileURLWithPath(filePath!)
//            audioPlayer = try! AVAudioPlayer(contentsOfURL: filePathNSURL)
//            
//            // Enable rate-changing features
//            audioPlayer.enableRate = true
//        }
        audioPlayer = try! AVAudioPlayer(contentsOfURL: receivedAudio.filePath)
        
        audioFile = try! AVAudioFile(forReading: receivedAudio.filePath)
        
        // Enable rate-changing features
        audioPlayer.enableRate = true
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func playAudio(rate: Float) {
        audioPlayer.stop()
        audioPlayer.rate = rate
        audioPlayer.currentTime = 0.0
        audioPlayer.play()
    }
    
    func playAudioWithVariablePitch(pitch: Float)
    {
        // Perform cleanups
        audioPlayer.stop()
        audioEngine.stop()
        audioEngine.reset()
        
        // Prepare audio engine
        let audioPlayerNode: AVAudioPlayerNode = AVAudioPlayerNode()
        let audioPitch: AVAudioUnitTimePitch = AVAudioUnitTimePitch()
        audioPitch.pitch = pitch
        
        // Perform operations on node, prepare nodes for pitch alteration
        audioEngine.attachNode(audioPlayerNode)
        audioEngine.attachNode(audioPitch)
        audioEngine.connect(audioPlayerNode, to: audioPitch, format: nil)
        audioEngine.connect(audioPitch, to: audioEngine.outputNode, format: nil)
        
        // Play the node using audioFile, at a specific pitch
        audioPlayerNode.scheduleFile(audioFile, atTime: nil, completionHandler: nil)
    
        try! audioEngine.start()
        audioPlayerNode.play()
        
    }
    
    @IBAction func playSlowRecord(sender: UIButton) {
        playAudio(0.5)
    }

    @IBAction func playFastRecord(sender: AnyObject) {
        playAudio(1.5)
    }
    
    
    @IBAction func stopAudioRecord(sender: UIButton) {
        audioPlayer.stop()
    }
    
    @IBAction func playChipmunkRecord(sender: UIButton) {
        playAudioWithVariablePitch(1000)
    }
    
    @IBAction func playVaderRecord(sender: UIButton) {
        playAudioWithVariablePitch(-1000)
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
