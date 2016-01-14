//
//  AKConvolutionAudioUnit.h
//  AudioKit
//
//  Created by Aurelius Prochazka, last edited January 13, 2016.
//  Copyright (c) 2016 Aurelius Prochazka. All rights reserved.
//

#ifndef AKConvolutionAudioUnit_h
#define AKConvolutionAudioUnit_h

#import <AudioToolbox/AudioToolbox.h>

@interface AKConvolutionAudioUnit : AUAudioUnit

- (void)setupAudioFileTable:(float *)data size:(UInt32)size;
- (void)setPartitionLength:(int)partitionLength;

- (void)start;
- (void)stop;
- (BOOL)isPlaying;
@end

#endif /* AKConvolutionAudioUnit_h */
