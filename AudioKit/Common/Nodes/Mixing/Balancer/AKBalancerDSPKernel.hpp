//
//  AKBalancerDSPKernel.hpp
//  AudioKit
//
//  Created by Aurelius Prochazka, last edited January 13, 2016.
//  Copyright (c) 2015 Aurelius Prochazka. All rights reserved.
//

#ifndef AKBalancerDSPKernel_hpp
#define AKBalancerDSPKernel_hpp

#import "AKDSPKernel.hpp"
#import "AKParameterRamper.hpp"

extern "C" {
#include "soundpipe.h"
}


class AKBalancerDSPKernel : public AKDSPKernel {
public:
    // MARK: Member Functions

    AKBalancerDSPKernel() {}

    void init(int channelCount, double inSampleRate) {
        channels = channelCount;

        sampleRate = float(inSampleRate);

        sp_create(&sp);
        sp_bal_create(&bal);
        sp_bal_init(sp, bal);
    }

    void start() {
        started = true;
    }
    
    void stop() {
        started = false;
    }
    
    void destroy() {
        sp_bal_destroy(&bal);
        sp_destroy(&sp);
    }
    
    void reset() {
    }

    void setParameter(AUParameterAddress address, AUValue value) {
        switch (address) {
        }
    }

    AUValue getParameter(AUParameterAddress address) {
        switch (address) {
            default: return 0.0f;
        }
    }

    void startRamp(AUParameterAddress address, AUValue value, AUAudioFrameCount duration) override {
        switch (address) {
        }
    }

    void setBuffers(AudioBufferList* inBufferList, AudioBufferList *compBufferList, AudioBufferList* outBufferList) {
        
        inBufferListPtr = inBufferList;
        compBufferListPtr = compBufferList;
        outBufferListPtr = outBufferList;
    }

    void process(AUAudioFrameCount frameCount, AUAudioFrameCount bufferOffset) override {
        
        if (!started) {
            outBufferListPtr->mBuffers[0] = inBufferListPtr->mBuffers[0];
            outBufferListPtr->mBuffers[1] = inBufferListPtr->mBuffers[1];
            return;
        }
        
        // For each sample.
        for (int frameIndex = 0; frameIndex < frameCount; ++frameIndex) {

            int frameOffset = int(frameIndex + bufferOffset);


            for (int channel = 0; channel < channels; ++channel) {
                float *in   = (float *)inBufferListPtr->mBuffers[channel].mData  + frameOffset;
                float *comp = (float *)compBufferListPtr->mBuffers[channel].mData + frameOffset;
                float *out  = (float *)outBufferListPtr->mBuffers[channel].mData + frameOffset;
//                *out = *in;
                sp_bal_compute(sp, bal, in, comp, out);
            }
        }
    }

    // MARK: Member Variables

private:

    int channels = 2;
    int inputChannels = 4;
    float sampleRate = 44100.0;

    AudioBufferList* inBufferListPtr = nullptr;
    AudioBufferList* compBufferListPtr = nullptr;
    AudioBufferList* outBufferListPtr = nullptr;

    sp_data *sp;
    sp_bal *bal;

public:
    bool started = true;
};

#endif /* AKBalancerDSPKernel_hpp */
