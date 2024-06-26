//
//  mGBATypes.m
//  mGBADeltaCore
//
//  Created by Ian Clawson on 7/26/21.
//  Copyright © 2021 Riley Testut. All rights reserved.
//

#import "mGBATypes.h"

GameType const GameTypeGBA = @"com.litritt.ignited.game.gba";
GameType const GameTypeGBC = @"com.litritt.ignited.game.gbc";

CheatType const CheatTypeActionReplay = @"ActionReplay";
CheatType const CheatTypeGameShark = @"GameShark";
CheatType const CheatTypeCodeBreaker = @"CodeBreaker";
CheatType const CheatTypeGameGenie = @"GameGenie";

NSNotificationName const GBADidActivateGyroNotification = @"GBADidActivateGyroNotification";
NSNotificationName const GBADidDeactivateGyroNotification = @"GBADidDeactivateGyroNotification";
