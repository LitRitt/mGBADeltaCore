//
//  mGBCEmulatorBridge.m
//  mGBCBridge
//
//  Created by Chris Rittenhouse on 3/21/24.
//

#import "mGBCEmulatorBridge.h"
#import "mGBATypes.h"

#import <CoreMotion/CoreMotion.h>

#include <mgba-util/common.h>

#include <mgba/core/blip_buf.h>
#include <mgba/core/core.h>
#include <mgba/core/cheats.h>
#include <mgba/core/serialize.h>
#include <mgba/gb/core.h>
#include <mgba/internal/gb/cheats.h>
#include <mgba/internal/gb/input.h>
#include <mgba/internal/gb/overrides.h>
#include <mgba-util/circle-buffer.h>
#include <mgba-util/memory.h>
#include <mgba-util/vfs.h>
#include <mgba/gb/interface.h>

#define SAMPLES 1024

@import Foundation;

@import DeltaCore;
@import mGBASwift;

@interface mGBCEmulatorBridge ()
{
    struct mCore* core;
}

@property (nonatomic, copy, nullable, readwrite) NSURL *gameURL;
@property (nonatomic, copy, nonnull, readonly) NSURL *gameSaveDirectoryURL;
@property (nonatomic, readonly) NSMutableData *videoBuffer;

@property (strong, nonatomic, readonly) CMMotionManager *motionManager;
@property (strong, nonatomic, readonly) UIImpactFeedbackGenerator *impactGenerator;

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
static int8_t orientation;
static int32_t tiltX = 0;
static int32_t tiltY = 0;
static int32_t gyroZ = 0;

static struct mRumble rumble;
static int rumbleUp = 0;
static int rumbleDown = 0;

@implementation mGBCEmulatorBridge
@synthesize audioRenderer = _audioRenderer;
@synthesize videoRenderer = _videoRenderer;
@synthesize saveUpdateHandler = _saveUpdateHandler;

+ (instancetype)sharedBridge
{
    static mGBCEmulatorBridge *_emulatorBridge = nil;
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
        core = GBCoreCreate();
        mCoreInitConfig(core, nil);
        
        mLogSetDefaultLogger(&logger);
        
        struct mCoreOptions options = { .skipBios = true };
        mCoreConfigLoadDefaults(&core->config, &options);
        
        core->init(core);
        
        _motionManager = [[CMMotionManager alloc] init];
        rotation.sample = _sampleRotationGBC;
        rotation.readTiltX = _readTiltXGBC;
        rotation.readTiltY = _readTiltYGBC;
        rotation.readGyroZ = _readGyroZGBC;
        
        _impactGenerator = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleHeavy];
        rumble.setRumble = _setRumbleGBC;
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
    
    core = GBCoreCreate();
    mCoreInitConfig(core, nil);
    
    mLogSetDefaultLogger(&logger);
    
    struct mCoreOptions options = { .skipBios = true };
    mCoreConfigLoadDefaults(&core->config, &options);
    core->init(core);
    
    core->setPeripheral(core, mPERIPH_ROTATION, &rotation);
    core->setPeripheral(core, mPERIPH_RUMBLE, &rumble);
    
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
    [self deactivateAccelerometer];
}

- (void)pause
{
    [self deactivateAccelerometer];
}

- (void)resume
{
}

#pragma mark - Game Loop -

- (void)runFrameAndProcessVideo:(BOOL)processVideo
{
    core->runFrame(core);
    
    unsigned width, height;
    core->currentVideoSize(core, &width, &height);
    
    CGRect viewport = CGRectMake(0, 0, width, height);
    if (!CGRectEqualToRect(viewport, self.videoRenderer.viewport))
    {
        self.videoRenderer.viewport = viewport;
    }

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

- (void)activateAccelerometer
{
    if ([self.motionManager isAccelerometerActive] || ![self.motionManager isAccelerometerAvailable])
    {
        return;
    }
    
    [self.motionManager startAccelerometerUpdates];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:GBADidActivateGyroNotification object:self];
}

- (void)deactivateAccelerometer
{
    if (![self.motionManager isAccelerometerActive])
    {
        return;
    }
    
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
    
    int codeType = GB_CHEAT_AUTODETECT;
    
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
    
    // Device Model
    enum GBModel* model;
    const char* modelName;

    if (strcmp([_gbModel UTF8String], "Game Boy") == 0) {
        model = GB_MODEL_DMG;
    } else if (strcmp([_gbModel UTF8String], "Super Game Boy") == 0) {
        model = GB_MODEL_SGB;
    } else if (strcmp([_gbModel UTF8String], "Game Boy Color") == 0) {
        model = GB_MODEL_CGB;
    } else if (strcmp([_gbModel UTF8String], "Game Boy Advance") == 0) {
        model = GB_MODEL_AGB;
    } else {
        model = GB_MODEL_AUTODETECT;
    }

    modelName = GBModelToName(model);
    mCoreConfigSetValue(&core->config, "gb.model", modelName);
    mCoreConfigSetValue(&core->config, "sgb.model", modelName);
    mCoreConfigSetValue(&core->config, "cgb.model", modelName);
    mCoreConfigSetValue(&core->config, "cgb.hybridModel", modelName);
    mCoreConfigSetValue(&core->config, "cgb.sgbModel", modelName);
    core->reloadConfigOption(core, "gb.model", NULL);
    core->reloadConfigOption(core, "sgb.model", NULL);
    core->reloadConfigOption(core, "cgb.model", NULL);
    core->reloadConfigOption(core, "cgb.hybridModel", NULL);
    core->reloadConfigOption(core, "cgb.sgbModel", NULL);

    // Super Game Boy Borders
    mCoreConfigSetIntValue(&core->config, "sgb.borders", _sgbBorders);
    core->reloadConfigOption(core, "sgb.borders", NULL);
    
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
    
    // Palette Lookup
    int gbColorLookup;
    
    if (strcmp([_paletteLookup UTF8String], "Fallback") == 0) {
        gbColorLookup = GB_COLORS_SGB_CGB_FALLBACK;
    } else if (strcmp([_paletteLookup UTF8String], "Super Game Boy") == 0) {
        gbColorLookup = GB_COLORS_SGB;
    } else if (strcmp([_paletteLookup UTF8String], "Game Boy Color") == 0) {
        gbColorLookup = GB_COLORS_CGB;
    } else if (strcmp([_paletteLookup UTF8String], "None") == 0) {
        gbColorLookup = GB_COLORS_NONE;
    }
    
    mCoreConfigSetUIntValue(&core->config, "gb.colors", gbColorLookup);
    core->reloadConfigOption(core, "gb.colors", NULL);
    
    // Custom Palettes
    mCoreConfigSetUIntValue(&core->config, "gb.pal[0]", _palette0color0);
    mCoreConfigSetUIntValue(&core->config, "gb.pal[1]", _palette0color1);
    mCoreConfigSetUIntValue(&core->config, "gb.pal[2]", _palette0color2);
    mCoreConfigSetUIntValue(&core->config, "gb.pal[3]", _palette0color2);
    mCoreConfigSetUIntValue(&core->config, "gb.pal[4]", _palette1color0);
    mCoreConfigSetUIntValue(&core->config, "gb.pal[5]", _palette1color1);
    mCoreConfigSetUIntValue(&core->config, "gb.pal[6]", _palette1color2);
    mCoreConfigSetUIntValue(&core->config, "gb.pal[7]", _palette1color3);
    mCoreConfigSetUIntValue(&core->config, "gb.pal[8]", _palette2color0);
    mCoreConfigSetUIntValue(&core->config, "gb.pal[9]", _palette2color1);
    mCoreConfigSetUIntValue(&core->config, "gb.pal[10]", _palette2color2);
    mCoreConfigSetUIntValue(&core->config, "gb.pal[11]", _palette2color3);
    core->reloadConfigOption(core, "gb.pal", NULL);
    
    // Frameskip
    opts.frameskip = _frameskip;
    
    mCoreConfigLoadDefaults(&core->config, &opts);
    mCoreLoadConfig(core);
    
    // Accelerometer
    accelerometerSensitivity = _accelerometerSensitivity;
    orientation = _orientation;
}

#pragma mark - mGBA -

void _sampleRotationGBC(struct mRotationSource* source)
{
    UNUSED(source);
    if (![mGBCEmulatorBridge.sharedBridge.motionManager isAccelerometerActive])
    {
        [mGBCEmulatorBridge.sharedBridge activateAccelerometer];
    }
    
    CMAccelerometerData *accelerometerData = mGBCEmulatorBridge.sharedBridge.motionManager.accelerometerData;
    
    switch (orientation)
    {
        case 1:
            tiltX = accelerometerData.acceleration.y * 2e8f * accelerometerSensitivity;
            tiltY = accelerometerData.acceleration.x * 2e8f * accelerometerSensitivity;
            break;
            
        case 2:
            tiltX = accelerometerData.acceleration.y * -2e8f * accelerometerSensitivity;
            tiltY = accelerometerData.acceleration.x * -2e8f * accelerometerSensitivity;
            break;
            
        case 3:
            tiltX = accelerometerData.acceleration.x * -2e8f * accelerometerSensitivity;
            tiltY = accelerometerData.acceleration.y * 2e8f * accelerometerSensitivity;
            break;
            
        default:
            tiltX = accelerometerData.acceleration.x * 2e8f * accelerometerSensitivity;
            tiltY = accelerometerData.acceleration.y * -2e8f * accelerometerSensitivity;
            break;
    }
}

int32_t _readTiltXGBC(struct mRotationSource* source)
{
    UNUSED(source);
    return tiltX;
}

int32_t _readTiltYGBC(struct mRotationSource* source)
{
    UNUSED(source);
    return tiltY;
}

int32_t _readGyroZGBC(struct mRotationSource* source)
{
    UNUSED(source);
    return 0;
}

void _setRumbleGBC(struct mRumble* rumble, int enable)
{
    UNUSED(rumble);
    
    if (enable) {
        ++rumbleUp;
    } else {
        ++rumbleDown;
    }
}

@end
