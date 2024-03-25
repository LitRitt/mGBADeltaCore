//
//  mGBAEmulatorBridge.h
//  mGBABridge
//
//  Created by Ian Clawson on 7/26/21.
//  Copyright © 2021 Riley Testut. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol DLTAEmulatorBridging;

NS_ASSUME_NONNULL_BEGIN

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Weverything" // Silence "Cannot find protocol definition" warning due to forward declaration.
@interface mGBAEmulatorBridge : NSObject <DLTAEmulatorBridging>
#pragma clang diagnostic pop

@property (class, nonatomic, readonly) mGBAEmulatorBridge *sharedBridge;

@property (nonatomic) BOOL forceGBP;
@property (nonatomic) NSString *idleOptimization;
@property (nonatomic) int frameskip;
@property (nonatomic) double gyroscopeSensitivity;
@property (nonatomic) double accelerometerSensitivity;
@property (nonatomic) int orientation;
@property (nonatomic) double rumbleIntensity;
@property (nonatomic) int luxLevel;
//@property (nonatomic) BOOL luxAllowed;

- (void)updateSettings;

@end

NS_ASSUME_NONNULL_END
