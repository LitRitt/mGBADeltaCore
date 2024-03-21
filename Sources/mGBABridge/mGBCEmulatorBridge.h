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

@end

NS_ASSUME_NONNULL_END
