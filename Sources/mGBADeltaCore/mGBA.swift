//
//  mGBA.swift
//  mGBADeltaCore
//
//  Created by Ian Clawson on 7/26/21.
//  Copyright © 2021 Riley Testut. All rights reserved.
//

import Foundation
import AVFoundation

import DeltaCore
@_exported import mGBABridge
@_exported import mGBASwift

extension mGBAGameInput: Input
{
    public var type: InputType {
        return .game(.gba)
    }
}

extension mGBCGameInput: Input
{
    public var type: InputType {
        return .game(.gbc)
    }
}

public struct mGBA: DeltaCoreProtocol
{
    public static let core = mGBA()
    
    public var name: String { "mGBA" }
    public var identifier: String { "com.rileytestut.mGBADeltaCore" }
    
    public var gameType: GameType { .gba }
    public var gameInputType: Input.Type { mGBAGameInput.self }
    public var gameSaveFileExtension: String { "sav" }
    
    public let audioFormat = AVAudioFormat(commonFormat: .pcmFormatInt16, sampleRate: 32768, channels: 2, interleaved: true)!
    public let videoFormat = VideoFormat(format: .bitmap(.rgba8), dimensions: CGSize(width: 240, height: 160))

    public var supportedCheatFormats: Set<CheatFormat> {
        let actionReplayFormat = CheatFormat(name: NSLocalizedString("Action Replay", comment: ""), format: "XXXXXXXX YYYYYYYY", type: .actionReplay)
        let gameSharkFormat = CheatFormat(name: NSLocalizedString("GameShark", comment: ""), format: "XXXXXXXX YYYYYYYY", type: .gameShark)
        let codeBreakerFormat = CheatFormat(name: NSLocalizedString("Code Breaker", comment: ""), format: "XXXXXXXX YYYY", type: .codeBreaker)
        return [actionReplayFormat, gameSharkFormat, codeBreakerFormat]
    }

    public var emulatorBridge: EmulatorBridging { mGBAEmulatorBridge.shared as! EmulatorBridging }
    
    public var resourceBundle: Bundle { Bundle.module }
    
    private init()
    {
    }
}

public struct mGBC: DeltaCoreProtocol
{
    public static let core = mGBC()
    
    public var name: String { "mGBC" }
    public var identifier: String { "com.rileytestut.mGBCDeltaCore" }
    
    public var gameType: GameType { .gbc }
    public var gameInputType: Input.Type { mGBCGameInput.self }
    public var gameSaveFileExtension: String { "sav" }
    
    public let audioFormat = AVAudioFormat(commonFormat: .pcmFormatInt16, sampleRate: 32768, channels: 2, interleaved: true)!
    public let videoFormat = VideoFormat(format: .bitmap(.rgba8), dimensions: CGSize(width: 256, height: 224))

    public var supportedCheatFormats: Set<CheatFormat> {
        return []
    }

    public var emulatorBridge: EmulatorBridging { mGBCEmulatorBridge.shared as! EmulatorBridging }
    
    public var resourceBundle: Bundle { Bundle.module }
    
    private init()
    {
    }
}
