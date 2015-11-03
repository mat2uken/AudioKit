//
//  AKAUHighShelfFilter.swift
//  AudioKit
//
//  Autogenerated by scripts by Aurelius Prochazka. Do not edit directly.
//  Copyright (c) 2015 Aurelius Prochazka. All rights reserved.
//

import AVFoundation

/** AudioKit version of Apple's HighShelfFilter Audio Unit */
public class AKAUHighShelfFilter: AKOperation {
    
    private let cd = AudioComponentDescription(
        componentType: OSType(kAudioUnitType_Effect),
        componentSubType: OSType(kAudioUnitSubType_HighShelfFilter),
        componentManufacturer: OSType(kAudioUnitManufacturer_Apple),
        componentFlags: 0,
        componentFlagsMask: 0)
    
    private var internalEffect = AVAudioUnitEffect()
    public var internalAU = AudioUnit()
    
    /** Cut Off Frequency (Hz) ranges from 10000 to 22050 (Default: 10000) */
    public var cutOffFrequency: Float = 10000 {
        didSet {
            if cutOffFrequency < 10000 {
                cutOffFrequency = 10000
            }
            if cutOffFrequency > 22050 {
                cutOffFrequency = 22050
            }
            AudioUnitSetParameter(internalAU, kHighShelfParam_CutOffFrequency, kAudioUnitScope_Global, 0, cutOffFrequency, 0)
        }
    }
    
    /** Gain (dB) ranges from -40 to 40 (Default: 0) */
    public var gain: Float = 0 {
        didSet {
            if gain < -40 {
                gain = -40
            }
            if gain > 40 {
                gain = 40
            }
            AudioUnitSetParameter(internalAU, kHighShelfParam_Gain, kAudioUnitScope_Global, 0, gain, 0)
        }
    }
    
    /** Initialize the reverb operation */
    public init(_ input: AKOperation) {
        super.init()
        internalEffect = AVAudioUnitEffect(audioComponentDescription: cd)
        output = internalEffect
        AKManager.sharedInstance.engine.attachNode(internalEffect)
        AKManager.sharedInstance.engine.connect(input.output!, to: internalEffect, format: nil)
        internalAU = internalEffect.audioUnit
    }
}