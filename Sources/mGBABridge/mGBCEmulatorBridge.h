//
//  mGBCEmulatorBridge.h
//  mGBCBridge
//
//  Created by Chris Rittenhouse on 3/21/24.
//

#import <Foundation/Foundation.h>

@protocol DLTAEmulatorBridging;

NS_ASSUME_NONNULL_BEGIN

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Weverything" // Silence "Cannot find protocol definition" warning due to forward declaration.
@interface mGBCEmulatorBridge : NSObject <DLTAEmulatorBridging>
#pragma clang diagnostic pop

@property (class, nonatomic, readonly) mGBCEmulatorBridge *sharedBridge;

@property (nonatomic) UInt32 palette0color0;
@property (nonatomic) UInt32 palette0color1;
@property (nonatomic) UInt32 palette0color2;
@property (nonatomic) UInt32 palette0color3;
@property (nonatomic) UInt32 palette1color0;
@property (nonatomic) UInt32 palette1color1;
@property (nonatomic) UInt32 palette1color2;
@property (nonatomic) UInt32 palette1color3;
@property (nonatomic) UInt32 palette2color0;
@property (nonatomic) UInt32 palette2color1;
@property (nonatomic) UInt32 palette2color2;
@property (nonatomic) UInt32 palette2color3;

@property (nonatomic) BOOL sgbBorders;
@property (nonatomic) NSString *gbModel;
@property (nonatomic) NSString *paletteLookup;
@property (nonatomic) int frameskip;
@property (nonatomic) double accelerometerSensitivity;
@property (nonatomic) int orientation;
@property (nonatomic) double rumbleIntensity;

- (void)updateSettings;

@end

NS_ASSUME_NONNULL_END
