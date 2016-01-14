//
//  modalResonanceFilter.swift
//  AudioKit
//
//  Created by Aurelius Prochazka, last edited January 13, 2016.
//  Copyright © 2016 AudioKit. All rights reserved.
//

import Foundation

extension AKComputedParameter {

    /// A modal resonance filter used for modal synthesis. Plucked and bell sounds
    /// can be created using  passing an impulse through a combination of modal
    /// filters.
    ///
    /// - returns: AKComputedParameter
    /// - parameter input: Input audio signal
    /// - parameter frequency: Resonant frequency of the filter. (Default: 500.0, Minimum: 12.0, Maximum: 20000.0)
    /// - parameter qualityFactor: Quality factor of the filter. Roughly equal to Q/frequency. (Default: 50.0, Minimum: 0.0, Maximum: 100.0)
     ///
    public func modalResonanceFilter(
        frequency frequency: AKParameter = 500.0,
        qualityFactor: AKParameter = 50.0
        ) -> AKOperation {
            return AKOperation("(\(self.toMono()) \(frequency) \(qualityFactor) mode)")
    }
}
