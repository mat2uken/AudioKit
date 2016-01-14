//
//  AKFMOscillatorAudioUnit.h
//  AudioKit
//
//  Created by Aurelius Prochazka, last edited January 13, 2016.
//  Copyright (c) 2016 Aurelius Prochazka. All rights reserved.
//

#ifndef AKFMOscillatorAudioUnit_h
#define AKFMOscillatorAudioUnit_h

#import <AudioToolbox/AudioToolbox.h>

@interface AKFMOscillatorAudioUnit : AUAudioUnit
@property (nonatomic) float baseFrequency;
@property (nonatomic) float carrierMultiplier;
@property (nonatomic) float modulatingMultiplier;
@property (nonatomic) float modulationIndex;
@property (nonatomic) float amplitude;

- (void)setupWaveform:(int)size;
- (void)setWaveformValue:(float)value atIndex:(UInt32)index;
- (void)start;
- (void)stop;
- (BOOL)isPlaying;
@end

#endif /* AKFMOscillatorAudioUnit_h */
