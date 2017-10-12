//
//  VhistaSpeechManager.swift
//  Vhista
//
//  Created by Juan David Cruz Serrano on 8/2/17.
//  Copyright © 2017 juandavidcruz. All rights reserved.
//

import UIKit
import AVFoundation

var globalRate = 0.65
var global_language: String = NSLocale.preferredLanguages[0]

class VhistaSpeechManager: NSObject {
    
    //Speech Synthesizer
    let speechSynthesizer = AVSpeechSynthesizer()
    
    var voice = AVSpeechSynthesisVoice(language: global_language)
    
    var playingProtectedContent = false;
    
    var blockAllSpeech = false;
    
    // MARK: - Initialization Method
    override init() {
        super.init()
    }
    
    static let shared: VhistaSpeechManager = {
        
        let instance = VhistaSpeechManager()
        
        if global_language.contains("es-") {
            instance.voice = AVSpeechSynthesisVoice(language: "es-MX")
        }
        
        instance.speechSynthesizer.delegate = instance
        
        return instance
    }()
    
    
    func sayGreetingMessage() {
        sayText(stringToSpeak: NSLocalizedString("Greeting_Message", comment: "The first message the user hears everytime he/she opens the app, usually a Short Intro to the app."), isProtected: true, rate: Float(globalRate))
    }
    
    func sayText(stringToSpeak: String, isProtected: Bool, rate: Float) {
        
        if blockAllSpeech {
            return
        }
        
        if playingProtectedContent && !isProtected { return }
        
        if !playingProtectedContent && isProtected {
            playingProtectedContent = true
        }
        
        let speechUtterance = AVSpeechUtterance(string: stringToSpeak)
        
        speechUtterance.voice = voice
        speechUtterance.rate = rate
        
        stopSpeech(sender: stringToSpeak)
        
        speechSynthesizer.speak(speechUtterance)
        
    }
    
    func speakRekognition(stringToSpeak: String) {
        sayText(stringToSpeak: stringToSpeak, isProtected: true, rate: Float(globalRate))
    }
    
}

extension VhistaSpeechManager: AVSpeechSynthesizerDelegate {
    
    func pauseSpeech(sender: Any) {
        speechSynthesizer.pauseSpeaking(at: AVSpeechBoundary.word)
    }
    
    
    func stopSpeech(sender: Any) {
        if speechSynthesizer.isSpeaking == true {
            speechSynthesizer.stopSpeaking(at: AVSpeechBoundary.immediate)
        }
        
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        
    }
    
    
    
}
