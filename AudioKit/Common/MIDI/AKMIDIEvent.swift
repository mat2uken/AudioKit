//
//  AKMIDIEvent.swift
//  AudioKit
//
//  Created by Jeff Cooper, revision history on Github.
//  Copyright © 2018 AudioKit. All rights reserved.
//

import CoreMIDI

/// A container for the values that define a MIDI event
public struct AKMIDIEvent: AKMIDIMessage {

    // MARK: - Properties

    public var timeStamp: MIDITimeStamp = 0

    /// Internal data
    public var data = [MIDIByte]()

    /// Description
    public var description: String {
        if let status = self.status {
            return "\(status.description) - \(data)"
        }
        if let command = self.command {
            return "\(command.description) - \(data)"
        }
        return "Unhandled event \(data)"
    }

    /// Internal MIDIByte-sized packets - in development / not used yet
    public var internalPackets: [[MIDIByte]] {
        var splitData = [[MIDIByte]]()
        let byteLimit = Int(data.count / 256)
        for i in 0...byteLimit {
            let arrayStart = i * 256
            let arrayEnd: Int = min(Int(arrayStart + 256), Int(data.count))
            let tempData = Array(data[arrayStart..<arrayEnd])
            splitData.append(tempData)
        }
        return splitData
    }

    /// The length in bytes for this MIDI message (1 to 3 bytes)
    public var length: Int {
        return data.count
    }

    /// Status
    public var status: AKMIDIStatus? {
        if let statusByte = data.first {
            return AKMIDIStatus(byte: statusByte)
        }
        return nil
    }

    /// System Command
    public var command: AKMIDISystemCommand? {
        if let statusByte = data.first, (statusByte != AKMIDISystemCommand.sysReset.rawValue && data.count > 1) {
            return AKMIDISystemCommand(rawValue: statusByte)
        }
        return nil
    }

    /// MIDI Channel
    public var channel: MIDIChannel? {
        return status?.channel
    }

    /// MIDI Note Number
    public var noteNumber: MIDINoteNumber? {
        if status?.type == .noteOn || status?.type == .noteOff, data.count > 1 {
            return MIDINoteNumber(data[1])
        }
        return nil
    }

    /// Representation of the pitchBend data as a MIDI word 0-16383
    public var pitchbendAmount: MIDIWord? {
        if status?.type == .pitchWheel {
            if data.count > 2 {
                return MIDIWord(byte1: data[1], byte2: data[2])
            }
        }
        return nil
    }

    // MARK: - Initialization

    /// Initialize the MIDI Event from a MIDI Packet
    ///
    /// - parameter packet: MIDIPacket that is potentially a known event type
    ///
    public init(packet: MIDIPacket) {
        timeStamp = packet.timeStamp

        // MARK: we currently assume this is one midi event could be any number of events
        let isSystemCommand = packet.isSystemCommand
        if isSystemCommand {
            let systemCommand = packet.systemCommand
            let length = systemCommand?.length
            if systemCommand == .sysex {
                data = [] //reset internalData

                // voodoo to convert packet 256 element tuple to byte arrays
                if let midiBytes = AKMIDIEvent.decode(packet: packet) {
                    // flag midi system that a sysex packet has started so it can gather bytes until the end
                    AudioKit.midi.startReceivingSysex(with: midiBytes)
                    data += midiBytes
                    if let sysexEndIndex = midiBytes.index(of: AKMIDISystemCommand.sysexEnd.byte) {
                        let length = sysexEndIndex + 1
                        data = Array(data.prefix(length))
                        AudioKit.midi.stopReceivingSysex()
                    } else {
                        data.removeAll()
                    }
                }
            } else if length == 1 {
                let bytes = [packet.data.0]
                data = bytes
            } else if length == 2 {
                let bytes = [packet.data.0, packet.data.2]
                data = bytes
            } else if length == 3 {
                let bytes = [packet.data.0, packet.data.1, packet.data.2]
                data = bytes
            }
        } else {
            let bytes = [packet.data.0, packet.data.1, packet.data.2]
            data = bytes
        }
    }

    init?(fileEvent event: AKMIDIFileChunkEvent) {
        if let typeByte = event.typeByte {
            if typeByte == AKMIDISystemCommand.sysex.rawValue ||
                typeByte == AKMIDISystemCommand.sysexEnd.rawValue {
                let data = [AKMIDISystemCommand.sysex.rawValue] + event.eventData
                self = AKMIDIEvent(data: data)
            } else if let statusType = AKMIDIStatusType.from(byte: typeByte) {
                self = AKMIDIEvent(data: event.computedData)
            } else {
                //unhandled data - fill event anyway with raw data for later decoding
                self.data = event.eventData
            }
        } else {
            AKLog("bad AKMIDIFile chunk - no type for \(event.typeByte!)")
            return nil
        }
    }
    
    /// Initialize the MIDI Event from a raw MIDIByte packet (ie. from Bluetooth)
    ///
    /// - Parameters:
    ///   - data:  [MIDIByte] bluetooth packet
    ///
    public init(data: [MIDIByte], time: MIDITimeStamp = 0) {
        timeStamp = time
        if AudioKit.midi.isReceivingSysex {
            if let sysexEndIndex = data.index(of: AKMIDISystemCommand.sysexEnd.rawValue) {
                self.data = Array(data[0...sysexEndIndex])
            }
        } else if let command = AKMIDISystemCommand(rawValue: data[0]) {
            self.data = []
            // is sys command
            if command == .sysex {
                for byte in data {
                    self.data.append(byte)
                }
            } else {
                fillData(command: command, bytes: Array(data.suffix(from: 1)))
            }
        } else if let status = AKMIDIStatusType.from(byte: data[0]) {
            // is regular MIDI status
            let channel = data[0].lowBit
            fillData(status: status, channel: channel, bytes: Array(data.dropFirst()))
        } else if let metaType = AKMIDIMetaEventType(rawValue: data[0]) {
            print("is meta event \(metaType.description)")
        }
    }

    /// Initialize the MIDI Event from a status message
    ///
    /// - Parameters:
    ///   - status:  MIDI Status
    ///   - channel: Channel on which the event occurs
    ///   - byte1:   First data byte
    ///   - byte2:   Second data byte
    ///
    init(status: AKMIDIStatusType, channel: MIDIChannel, byte1: MIDIByte, byte2: MIDIByte) {
        let data = [byte1, byte2]
        fillData(status: status, channel: channel, bytes: data)
    }

    fileprivate mutating func fillData(status: AKMIDIStatusType,
                                       channel: MIDIChannel,
                                       bytes: [MIDIByte]) {
        data = []
        data.append(AKMIDIStatus.init(type: status, channel: channel).byte)
        for byte in bytes {
            data.append(byte.lower7bits())
        }
    }

    /// Initialize the MIDI Event from a system command message
    ///
    /// - Parameters:
    ///   - command: MIDI System Command
    ///   - byte1:   First data byte
    ///   - byte2:   Second data byte
    ///
    init(command: AKMIDISystemCommand, byte1: MIDIByte, byte2: MIDIByte? = nil) {
        var data = [byte1]
        if byte2 != nil {
            data.append(byte2!)
        }
        fillData(command: command, bytes: data)
    }

    fileprivate mutating func fillData(command: AKMIDISystemCommand,
                                       bytes: [MIDIByte]) {
        data.removeAll()
        data.append(command.byte)

        for byte in bytes {
            data.append(byte)
        }
    }

    // MARK: - Utility constructors for common MIDI events

    /// Create note on event
    ///
    /// - Parameters:
    ///   - noteNumber: MIDI Note number
    ///   - velocity:   MIDI Note velocity (0-127)
    ///   - channel:    Channel on which the note appears
    ///
    public init(noteOn noteNumber: MIDINoteNumber,
                velocity: MIDIVelocity,
                channel: MIDIChannel) {
        self.init(data: [AKMIDIStatus(type: .noteOn, channel: channel).byte, noteNumber, velocity])
    }

    /// Create note off event
    ///
    /// - Parameters:
    ///   - noteNumber: MIDI Note number
    ///   - velocity:   MIDI Note velocity (0-127)
    ///   - channel:    Channel on which the note appears
    ///
    public init(noteOff noteNumber: MIDINoteNumber,
                velocity: MIDIVelocity,
                channel: MIDIChannel) {
        self.init(data: [AKMIDIStatus(type: .noteOff, channel: channel).byte, noteNumber, velocity])
    }

    /// Create program change event
    ///
    /// - Parameters:
    ///   - data: Program change byte
    ///   - channel: Channel on which the program change appears
    ///
    public init(programChange data: MIDIByte,
                channel: MIDIChannel) {
        self.init(data: [AKMIDIStatus(type: .programChange, channel: channel).byte, data])
    }

    /// Create controller event
    ///
    /// - Parameters:
    ///   - controller: Controller number
    ///   - value:      Value of the controller
    ///   - channel:    Channel on which the controller value has changed
    ///
    public init(controllerChange controller: MIDIByte,
                value: MIDIByte,
                channel: MIDIChannel) {
        self.init(data: [AKMIDIStatus(type: .controllerChange, channel: channel).byte, controller, value])
    }

    /// Array of MIDI events from a MIDI packet list poionter
    static public func midiEventsFrom(packetListPointer: UnsafePointer< MIDIPacketList>) -> [AKMIDIEvent] {
        return packetListPointer.pointee.map { AKMIDIEvent(packet: $0) }
    }

    static func appendIncomingSysex(packet: MIDIPacket) -> AKMIDIEvent? {
        if let midiBytes = AKMIDIEvent.decode(packet: packet) {
            AudioKit.midi.incomingSysex += midiBytes
            if midiBytes.contains(AKMIDISystemCommand.sysexEnd.rawValue) {
                let sysexEvent = AKMIDIEvent(data: AudioKit.midi.incomingSysex, time: packet.timeStamp)
                AudioKit.midi.stopReceivingSysex()
                return sysexEvent
            }
        }
        return nil
    }

    /// Generate array of MIDI events from Bluetooth data
    public static func generateFrom(bluetoothData: [MIDIByte]) -> [AKMIDIEvent] {
        //1st byte timestamp coarse will always be > 128
        //2nd byte fine timestamp will always be > 128 - if 2nd message < 128, is continuing sysex
        //3nd < 128 running message - timestamp
        //status byte determines length of message

        var midiEvents: [AKMIDIEvent] = []
        if bluetoothData.count > 1 {
            var rawEvents: [[MIDIByte]] = []
            if bluetoothData[1] < 128 {
                //continuation of sysex from previous packet - handle separately
                //(probably needs a whole bluetooth MIDI class so we can see the previous packets)
            } else {
                var rawEvent: [MIDIByte] = []
                var lastStatus: MIDIByte = 0
                var messageJustFinished = false
                for byte in bluetoothData.dropFirst().dropFirst() { //drops first two bytes as these are timestamp bytes
                    if byte >= 128 {
                        //if we have a new status byte or if rawEvent is a real event

                        if messageJustFinished && byte >= 128 {
                            messageJustFinished = false
                            continue
                        }
                        lastStatus = byte
                    } else {
                        if rawEvent.isEmpty {
                            rawEvent.append(lastStatus)
                        }
                    }
                    rawEvent.append(byte) //set the status byte
                    if (rawEvent.count == 3 && lastStatus != AKMIDISystemCommand.sysex.rawValue)
                        || byte == AKMIDISystemCommand.sysexEnd.rawValue {
                        //end of message
                        messageJustFinished = true
                        if rawEvent.isNotEmpty {
                            rawEvents.append(rawEvent)
                        }
                        rawEvent = [] //init raw Event
                    }
                }
            }
            for event in rawEvents {
                midiEvents.append(AKMIDIEvent(data: event))
            }
        }//end bluetoothData.count > 0
        return midiEvents
    }

    static func decode(packet: MIDIPacket) -> [MIDIByte]? {
        var outBytes = [MIDIByte]()
        var tupleIndex: UInt16 = 0
        let byteCount = packet.length
        let mirrorData = Mirror(reflecting: packet.data)
        for (_, value) in mirrorData.children { // [tupleIndex, outBytes] in
            if tupleIndex < 256 {
                tupleIndex += 1
            }
            if let byte = value as? MIDIByte {
                if tupleIndex <= byteCount {
                    outBytes.append(byte)
                }
            }
        }
        return outBytes
    }
}
