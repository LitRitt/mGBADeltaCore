//
//  mGBATypes.h
//  mGBADeltaCore
//
//  Created by Ian Clawson on 7/26/21.
//  Copyright © 2021 Riley Testut. All rights reserved.
//

#if SWIFT_PACKAGE
@import CDeltaCore;
#else
@import DeltaCore;
#endif

// Extensible Enums
FOUNDATION_EXPORT GameType const GameTypeGBA NS_SWIFT_NAME(gba);
FOUNDATION_EXPORT GameType const GameTypeGBC NS_SWIFT_NAME(gbc);

FOUNDATION_EXPORT CheatType const CheatTypeActionReplay;
FOUNDATION_EXPORT CheatType const CheatTypeGameShark;
FOUNDATION_EXPORT CheatType const CheatTypeCodeBreaker;
FOUNDATION_EXPORT CheatType const CheatTypeGameGenie;

FOUNDATION_EXPORT NSNotificationName const GBADidActivateGyroNotification NS_REFINED_FOR_SWIFT;
FOUNDATION_EXPORT NSNotificationName const GBADidDeactivateGyroNotification NS_REFINED_FOR_SWIFT;
