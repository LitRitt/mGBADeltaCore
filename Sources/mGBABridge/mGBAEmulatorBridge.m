//
//  mGBAEmulatorBridge.h
//  mGBABridge
//
//  Created by Ian Clawson on 7/26/21.
//  Copyright © 2021 Riley Testut. All rights reserved.
//

#import "mGBAEmulatorBridge.h"
#import "mGBATypes.h"

#import <CoreMotion/CoreMotion.h>
//#import <SensorKit/SensorKit.h>

#include <mgba-util/common.h>

#include <mgba/core/blip_buf.h>
#include <mgba/core/core.h>
#include <mgba/core/cheats.h>
#include <mgba/core/serialize.h>
#include <mgba/gba/core.h>
#include <mgba/gba/interface.h>
#include <mgba/internal/gba/cheats.h>
#include <mgba/internal/gba/input.h>
#include <mgba-util/circle-buffer.h>
#include <mgba-util/memory.h>
#include <mgba-util/vfs.h>

#define SAMPLES 1024

@import Foundation;

@import DeltaCore;
@import mGBASwift;

const char* const binaryName = "mGBA";
const char* const projectName = "mGBADeltaCore";
const char* const projectVersion = "0.10.3";

@interface mGBAEmulatorBridge ()
{
    struct mCore* core;
}

@property (nonatomic, copy, nullable, readwrite) NSURL *gameURL;
@property (nonatomic, copy, nonnull, readonly) NSURL *gameSaveDirectoryURL;
@property (nonatomic, readonly) NSMutableData *videoBuffer;

@property (strong, nonatomic, readonly) CMMotionManager *motionManager;
@property (strong, nonatomic, readonly) UIImpactFeedbackGenerator *impactGenerator;
//@property (strong, nonatomic, readonly) SRSensorReader *lightSensor;

@end

static void _log(struct mLogger* log,
                 int category,
                 enum mLogLevel level,
                 const char* format,
                 va_list args)
{}

static struct mLogger logger = { .log = _log };

static struct mRotationSource rotation;
static double_t accelerometerSensitivity = 1.0;
static int32_t tiltX = 0;
static int32_t tiltY = 0;
static int32_t gyroZ = 0;

static struct mRumble rumble;
static int rumbleUp = 0;
static int rumbleDown = 0;

static struct GBALuminanceSource lux;
//static BOOL luxEnabled = false;
static uint8_t luxLevel = 0;

@implementation mGBAEmulatorBridge
@synthesize audioRenderer = _audioRenderer;
@synthesize videoRenderer = _videoRenderer;
@synthesize saveUpdateHandler = _saveUpdateHandler;

+ (instancetype)sharedBridge
{
    static mGBAEmulatorBridge *_emulatorBridge = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _emulatorBridge = [[self alloc] init];
    });
    
    return _emulatorBridge;
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        core = GBACoreCreate();
        mCoreInitConfig(core, nil);
        
        mLogSetDefaultLogger(&logger);
        
        struct mCoreOptions options = { .skipBios = true };
        mCoreConfigLoadDefaults(&core->config, &options);
        core->init(core);
        
        _motionManager = [[CMMotionManager alloc] init];
        rotation.sample = _sampleRotationGBA;
        rotation.readTiltX = _readTiltXGBA;
        rotation.readTiltY = _readTiltYGBA;
        rotation.readGyroZ = _readGyroZGBA;
        
        _impactGenerator = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleHeavy];
        rumble.setRumble = _setRumbleGBA;
        
//        _lightSensor = [[SRSensorReader alloc] initWithSensor:SRSensorAmbientLightSensor];
        lux.sample = _sampleLuminanceGBA;
        lux.readLuminance = _readLuminanceGBA;
    }
    
    return self;
}

#pragma mark - Emulation State -

- (void)startWithGameURL:(NSURL *)URL
{
    if (core) {
        // Fully reinitialize core
        mCoreConfigDeinit(&core->config);
        core->deinit(core);
    }
    
    core = GBACoreCreate();
    mCoreInitConfig(core, nil);
    
    mLogSetDefaultLogger(&logger);
    
    struct mCoreOptions options = { .skipBios = true };
    mCoreConfigLoadDefaults(&core->config, &options);
    core->init(core);
    
    core->setPeripheral(core, mPERIPH_ROTATION, &rotation);
    core->setPeripheral(core, mPERIPH_RUMBLE, &rumble);
    core->setPeripheral(core, mPERIPH_GBA_LUMINANCE, &lux);
    
    [self updateSettings];
    
    self.gameURL = URL;
    
    if (core->dirs.save) {
        core->dirs.save->close(core->dirs.save);
    }
    core->dirs.save = VDirOpen(URL.URLByDeletingPathExtension.URLByDeletingLastPathComponent.fileSystemRepresentation);
    strcpy(core->dirs.baseName, [URL.URLByDeletingPathExtension.lastPathComponent UTF8String]);
    
    struct VFile* rom = VFileOpen(URL.fileSystemRepresentation, O_RDONLY);
    core->loadROM(core, rom);
    
    unsigned width, height;
    core->baseVideoSize(core, &width, &height);
    _videoBuffer = [[NSMutableData alloc] initWithLength:(width * height * BYTES_PER_PIXEL)];
    core->setVideoBuffer(core, _videoBuffer.mutableBytes, width);
    core->setAudioBufferSize(core, SAMPLES);

    blip_set_rates_(core->getAudioChannel(core, 0), core->frequency(core), 32768);
    blip_set_rates_(core->getAudioChannel(core, 1), core->frequency(core), 32768);
    
    mCoreAutoloadSave(core); // handles saving/loading battery saves automatically

    core->reset(core);
    
    return YES;
}

- (void)stop
{
    [self deactivateGyroscopeAndAccelerometer];
}

- (void)pause
{
    [self deactivateGyroscopeAndAccelerometer];
}

- (void)resume
{
}

#pragma mark - Game Loop -

- (void)runFrameAndProcessVideo:(BOOL)processVideo
{
    core->runFrame(core);

    int16_t samples[SAMPLES * 2];
    size_t available = 0;
    available = blip_samples_avail_(core->getAudioChannel(core, 0));
    blip_read_samples_(core->getAudioChannel(core, 0), samples, (int)available, true);
    blip_read_samples_(core->getAudioChannel(core, 1), samples + 1, (int)available, true);
    
    [self.audioRenderer.audioBuffer writeBuffer:samples size:available * 4];
    
    if (processVideo)
    {
        memcpy(self.videoRenderer.videoBuffer, self.videoBuffer.mutableBytes, self.videoBuffer.length);
        [self.videoRenderer processFrame];
    }
    
    if (rumbleUp)
    {
        [_impactGenerator impactOccurredWithIntensity:_rumbleIntensity];
    }
    rumbleUp = 0;
    rumbleDown = 0;
}

#pragma mark - Inputs -

- (void)activateInput:(NSInteger)inputValue value:(double)value at:(NSInteger)playerIndex
{
    core->addKeys(core, 1 << inputValue);
}

- (void)deactivateInput:(NSInteger)inputValue at:(NSInteger)playerIndex
{
    core->clearKeys(core, 1 << inputValue);
}

- (void)resetInputs
{
    core->clearKeys(core, 1 << mGBAGameInputUp);
    core->clearKeys(core, 1 << mGBAGameInputDown);
    core->clearKeys(core, 1 << mGBAGameInputLeft);
    core->clearKeys(core, 1 << mGBAGameInputRight);
    core->clearKeys(core, 1 << mGBAGameInputA);
    core->clearKeys(core, 1 << mGBAGameInputB);
    core->clearKeys(core, 1 << mGBAGameInputL);
    core->clearKeys(core, 1 << mGBAGameInputR);
    core->clearKeys(core, 1 << mGBAGameInputStart);
    core->clearKeys(core, 1 << mGBAGameInputSelect);
}

#pragma mark - Game Saves -

- (void)saveGameSaveToURL:(NSURL *)URL
{
}

- (void)loadGameSaveFromURL:(NSURL *)URL
{
}

#pragma mark - Save States -

- (void)saveSaveStateToURL:(NSURL *)URL
{
    struct VFile* vf = VFileOpen([URL fileSystemRepresentation], O_CREAT | O_TRUNC | O_RDWR);
    mCoreSaveStateNamed(core, vf, 0);
    vf->close(vf);
}

- (void)loadSaveStateFromURL:(NSURL *)URL
{
    struct VFile* vf = VFileOpen([URL fileSystemRepresentation], O_RDONLY);
    mCoreLoadStateNamed(core, vf, 0);
    vf->close(vf);
}

#pragma mark - Sensors -

- (void)activateGyroscopeAndAccelerometer
{
    if (([self.motionManager isGyroActive] && [self.motionManager isAccelerometerActive]) || ![self.motionManager isGyroAvailable] || ![self.motionManager isAccelerometerAvailable])
    {
        return;
    }
    
    [self.motionManager startGyroUpdates];
    [self.motionManager startAccelerometerUpdates];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:GBADidActivateGyroNotification object:self];
}

- (void)deactivateGyroscopeAndAccelerometer
{
    if (!([self.motionManager isGyroActive] || [self.motionManager isAccelerometerActive]))
    {
        return;
    }
    
    [self.motionManager stopGyroUpdates];
    [self.motionManager stopAccelerometerUpdates];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:GBADidDeactivateGyroNotification object:self];
}

#pragma mark - Cheats -

- (BOOL)addCheatCode:(NSString *)cheatCode type:(NSString *)type
{
    cheatCode = [cheatCode stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSString *codeId = [cheatCode stringByAppendingFormat:@"/%@", type];
    
    struct mCheatDevice* cheats = core->cheatDevice(core);
    struct mCheatSet* cheatSet = cheats->createSet(cheats, [codeId UTF8String]);
    
    size_t size = mCheatSetsSize(&cheats->cheats);
    if (size) {
        cheatSet->copyProperties(cheatSet, *mCheatSetsGetPointer(&cheats->cheats, size - 1));
    }
    
    int codeType = GBA_CHEAT_AUTODETECT;
    
    NSArray *codeSet = [cheatCode componentsSeparatedByString:@"\n"];
    for (id codeLine in codeSet) {
        mCheatAddLine(cheatSet, [codeLine UTF8String], codeType);
    }
    
    cheatSet->enabled = YES;
    mCheatAddSet(cheats, cheatSet);
    
    return YES;
}

- (void)resetCheats
{
    struct mCheatDevice* cheats = core->cheatDevice(core);
    mCheatDeviceClear(cheats);
}

- (void)updateCheats
{
}

#pragma mark - Getters/Setters -

- (NSTimeInterval)frameDuration
{
    return (1.0 / 59.7275);
}

#pragma mark - Settings -

- (void)updateSettings
{
    struct mCoreOptions opts = {
        .skipBios = true,
        .volume = 0x100,
    };
    
    // Force Game Boy Player
    mCoreConfigSetIntValue(&core->config, "gba.forceGbp", _forceGBP);
    core->reloadConfigOption(core, "gba.forceGbp", NULL);
    
    // Idle Optimization
    const char* idleOptimization;
    
    if (strcmp([_idleOptimization UTF8String], "Don't Remove") == 0) {
        idleOptimization = "ignore";
    } else if (strcmp([_idleOptimization UTF8String], "Remove Known") == 0) {
        idleOptimization = "remove";
    } else if (strcmp([_idleOptimization UTF8String], "Detect and Remove") == 0) {
        idleOptimization = "detect";
    }
    
    mCoreConfigSetValue(&core->config, "idleOptimization", idleOptimization);
    core->reloadConfigOption(core, "idleOptimization", NULL);
    
    // Frameskip
    opts.frameskip = _frameskip;
    
    mCoreConfigLoadDefaults(&core->config, &opts);
    mCoreLoadConfig(core);
    
    // Accelerometer
    accelerometerSensitivity = _accelerometerSensitivity;
    
    // Light Sensor
    luxLevel = _luxLevel;
}

#pragma mark - mGBA Sensors -

void _sampleRotationGBA(struct mRotationSource* source)
{
    UNUSED(source);
    if (!([mGBAEmulatorBridge.sharedBridge.motionManager isGyroActive] && [mGBAEmulatorBridge.sharedBridge.motionManager isAccelerometerActive]))
    {
        [mGBAEmulatorBridge.sharedBridge activateGyroscopeAndAccelerometer];
    }
    
    CMGyroData *gyroData = mGBAEmulatorBridge.sharedBridge.motionManager.gyroData;
    CMAccelerometerData *accelerometerData = mGBAEmulatorBridge.sharedBridge.motionManager.accelerometerData;
    
    gyroZ = gyroData.rotationRate.z * -1e8f;
    tiltX = accelerometerData.acceleration.x * 2e8f * accelerometerSensitivity;
    tiltY = accelerometerData.acceleration.y * -2e8f * accelerometerSensitivity;
}

int32_t _readTiltXGBA(struct mRotationSource* source)
{
    UNUSED(source);
    return tiltX;
}

int32_t _readTiltYGBA(struct mRotationSource* source)
{
    UNUSED(source);
    return tiltY;
}

int32_t _readGyroZGBA(struct mRotationSource* source)
{
    UNUSED(source);
    return gyroZ;
}

void _setRumbleGBA(struct mRumble* rumble, int enable)
{
    UNUSED(rumble);
    
    if (enable) {
        ++rumbleUp;
    } else {
        ++rumbleDown;
    }
}

void _sampleLuminanceGBA(struct GBALuminanceSource* source)
{
    UNUSED(source);
}

uint8_t _readLuminanceGBA(struct GBALuminanceSource* source)
{
    UNUSED(source);
    int value = 0x16;
    
    if (luxLevel > 0 && luxLevel <= 10)
    {
        value += GBA_LUX_LEVELS[luxLevel - 1];
    }
    
    return 0xFF - value;
}

@end
