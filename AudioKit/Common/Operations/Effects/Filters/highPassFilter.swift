//
//  highPassFilter.swift
//  AudioKit
//
//  Created by Aurelius Prochazka, last edited January 13, 2016.
//  Copyright © 2016 AudioKit. All rights reserved.
//

import Foundation

extension AKComputedParameter {

    /// A complement to the AKLowPassFilter.
    ///
    /// - returns: AKComputedParameter
    /// - parameter input: Input audio signal
    /// - parameter halfPowerPoint: Half-Power Point in Hertz. Half power is defined as peak power / square root of 2. (Default: 1000, Minimum: 12.0, Maximum: 20000.0)
     ///
    public func highPassFilter(
        halfPowerPoint halfPowerPoint: AKParameter = 1000
        ) -> AKOperation {
            return AKOperation("(\(self.toMono()) \(halfPowerPoint) atone)")
    }
}
