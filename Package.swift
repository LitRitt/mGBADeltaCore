// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "mGBADeltaCore",
    platforms: [
        .iOS(.v14)
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "mGBADeltaCore",
            targets: ["mGBADeltaCore"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/LitRitt/DeltaCore.git", .branch("main"))
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "mGBADeltaCore",
            dependencies: ["DeltaCore", "mGBA", "mGBASwift", "mGBABridge"],
            exclude: [
                "Resources/Controller Skin/info.json"
            ],
            resources: [
                .copy("Resources/Controller Skin/Standard.ignitedskin"),
                .copy("Resources/Controller Skin/Standard-com.litritt.mGBCDeltaCore.ignitedskin"),
                .copy("Resources/Standard.deltamapping"),
                .copy("Resources/Standard-com.litritt.mGBCDeltaCore.deltamapping"),
            ]
        ),
        .target(
            name: "mGBASwift",
            dependencies: ["DeltaCore"]
        ),
        .target(
            name: "mGBABridge",
            dependencies: ["DeltaCore", "mGBA", "mGBASwift"],
            publicHeadersPath: "",
            cSettings: [
                .headerSearchPath("../mGBA/"),
                .headerSearchPath("../mGBA/mGBA"),
                .headerSearchPath("../mGBA/mGBA/src"),
                .headerSearchPath("../mGBA/mGBA/include"),
                
                .define("DM_CORE_GBA"),
                .define("DDISABLE_THREADING"),
                .define("DMINIMAL_CORE", to: "1"),
                .define("DMGBA_STANDALONE"),
                .define("DHAVE_STRDUP"),
                .define("DHAVE_XLOCALE"),
                .define("DHAVE_STRNDUP"),
                .define("DHAVE_STRLCPY"),
                .define("DHAVE_LOCALTIME_R"),
                .define("DHAVE_LOCALE"),
                .define("DHAVE_STRTOF_L"),
                .define("DHAVE_SNPRINTF_L"),
                .define("DHAVE_SETLOCALE"),
                
                .define("M_CORE_GBA"),
                .define("DISABLE_THREADING"),
                .define("MINIMAL_CORE", to: "1"),
                .define("MGBA_STANDALONE"),
                .define("HAVE_STRDUP"),
                .define("HAVE_XLOCALE"),
                .define("HAVE_STRNDUP"),
                .define("HAVE_STRLCPY"),
                .define("HAVE_LOCALTIME_R"),
                .define("HAVE_LOCALE"),
                .define("HAVE_STRTOF_L"),
                .define("HAVE_SNPRINTF_L"),
                .define("HAVE_SETLOCALE"),
            ]
        ),
        .target(
            name: "mGBA",
            exclude: [
                "mGBA/CHANGES",
                "mGBA/cinema",
                "mGBA/CMakeLists.txt",
                "mGBA/CONTRIBUTING.md",
                "mGBA/doc/mgba-qt.6",
                "mGBA/doc/mgba.6",
                "mGBA/include",
                "mGBA/LICENSE",
                "mGBA/opt",
                "mGBA/PORTING.md",
                "mGBA/README_DE.md",
                "mGBA/README_ES.md",
                "mGBA/README_ZH_CN.md",
                "mGBA/README.md",
                "mGBA/res",
                "mGBA/src/arm/CMakeLists.txt",
                "mGBA/src/arm/debugger",
                "mGBA/src/core/CMakeLists.txt",
                "mGBA/src/core/flags.h.in",
                "mGBA/src/core/scripting.c",
                "mGBA/src/core/test",
                "mGBA/src/core/version.c.in",
                "mGBA/src/debugger",
                "mGBA/src/feature",
                "mGBA/src/gb/CMakeLists.txt",
                "mGBA/src/gb/debugger/cli.c",
                "mGBA/src/gb/debugger/debugger.c",
                "mGBA/src/gb/debugger/symbols.c",
                "mGBA/src/gb/extra/proxy.c",
                "mGBA/src/gb/test",
                "mGBA/src/gba/CMakeLists.txt",
                "mGBA/src/gba/debugger/cli.c",
                "mGBA/src/gba/extra/audio-mixer.c",
                "mGBA/src/gba/extra/battlechip.c",
                "mGBA/src/gba/extra/proxy.c",
                "mGBA/src/gba/hle-bios.make",
                "mGBA/src/gba/hle-bios.s",
                "mGBA/src/gba/renderers/gl.c",
                "mGBA/src/gba/sharkport.c",
                "mGBA/src/gba/sio/dolphin.c",
                "mGBA/src/gba/sio/joybus.c",
                "mGBA/src/gba/test",
                "mGBA/src/platform/3ds",
                "mGBA/src/platform/cmake",
                "mGBA/src/platform/example",
                "mGBA/src/platform/libretro",
                "mGBA/src/platform/openemu",
                "mGBA/src/platform/opengl",
                "mGBA/src/platform/psp2",
                "mGBA/src/platform/python",
                "mGBA/src/platform/qt",
                "mGBA/src/platform/sdl",
                "mGBA/src/platform/switch",
                "mGBA/src/platform/test",
                "mGBA/src/platform/wii",
                "mGBA/src/platform/windows",
                "mGBA/src/third-party/blip_buf/license.txt",
                "mGBA/src/third-party/discord-rpc",
                "mGBA/src/third-party/inih/LICENSE.txt",
                "mGBA/src/third-party/inih/README.md",
                "mGBA/src/third-party/libpng",
                "mGBA/src/third-party/lzma",
                "mGBA/src/third-party/sqlite3",
                "mGBA/src/third-party/zlib",
                "mGBA/src/util/CMakeLists.txt",
                "mGBA/src/util/convolve.c",
                "mGBA/src/util/elf-read.c",
                "mGBA/src/util/gui.c",
                "mGBA/src/util/gui/file-select.c",
                "mGBA/src/util/gui/font-metrics.c",
                "mGBA/src/util/gui/font.c",
                "mGBA/src/util/gui/menu.c",
                "mGBA/src/util/memory.c",
                "mGBA/src/util/ring-fifo.c",
                "mGBA/src/util/test",
                "mGBA/src/util/vfs/vfs-devlist.c",
                "mGBA/src/util/vfs/vfs-file.c",
                "mGBA/src/util/vfs/vfs-lzma.c",
                "mGBA/src/util/vfs/vfs-zip.c",
                "mGBA/tools",
                "mGBA/version.cmake",
            ],
            sources: [
                "mGBA/src/arm/arm.c",
                "mGBA/src/arm/decoder-arm.c",
                "mGBA/src/arm/decoder-thumb.c",
                "mGBA/src/arm/decoder.c",
                "mGBA/src/arm/isa-arm.c",
                "mGBA/src/arm/isa-thumb.c",
                "mGBA/src/core/bitmap-cache.c",
                "mGBA/src/core/cache-set.c",
                "mGBA/src/core/cheats.c",
                "mGBA/src/core/core.c",
                "mGBA/src/core/config.c",
                "mGBA/src/core/directories.c",
                "mGBA/src/core/input.c",
                "mGBA/src/core/interface.c",
                "mGBA/src/core/library.c",
                "mGBA/src/core/lockstep.c",
                "mGBA/src/core/log.c",
                "mGBA/src/core/map-cache.c",
                "mGBA/src/core/mem-search.c",
                "mGBA/src/core/rewind.c",
                "mGBA/src/core/serialize.c",
                "mGBA/src/core/sync.c",
                "mGBA/src/core/thread.c",
                "mGBA/src/core/tile-cache.c",
                "mGBA/src/core/timing.c",
                "mGBA/src/gb/cheats.c",
                "mGBA/src/gb/core.c",
                "mGBA/src/gb/gb.c",
                "mGBA/src/gb/input.c",
                "mGBA/src/gb/io.c",
                "mGBA/src/gb/mbc.c",
                "mGBA/src/gb/mbc",
                "mGBA/src/sm83/sm83.c",
                "mGBA/src/sm83/isa-sm83.c",
                "mGBA/src/gb/memory.c",
                "mGBA/src/gb/overrides.c",
                "mGBA/src/gb/renderers/cache-set.c",
                "mGBA/src/gb/renderers/software.c",
                "mGBA/src/gb/serialize.c",
                "mGBA/src/gb/sio.c",
                "mGBA/src/gb/sio/lockstep.c",
                "mGBA/src/gb/sio/printer.c",
                "mGBA/src/gb/timer.c",
                "mGBA/src/gb/video.c",
                "mGBA/src/gb/audio.c",
                "mGBA/src/gba/audio.c",
                "mGBA/src/gba/bios.c",
                "mGBA/src/gba/cart/ereader.c",
                "mGBA/src/gba/cart/gpio.c",
                "mGBA/src/gba/cart/matrix.c",
                "mGBA/src/gba/cart/vfame.c",
                "mGBA/src/gba/cheats.c",
                "mGBA/src/gba/cheats/codebreaker.c",
                "mGBA/src/gba/cheats/gameshark.c",
                "mGBA/src/gba/cheats/parv3.c",
                "mGBA/src/gba/core.c",
                "mGBA/src/gba/dma.c",
                "mGBA/src/gba/gba.c",
                "mGBA/src/gba/hle-bios.c",
                "mGBA/src/gba/input.c",
                "mGBA/src/gba/io.c",
                "mGBA/src/gba/memory.c",
                "mGBA/src/gba/overrides.c",
                "mGBA/src/gba/renderers/cache-set.c",
                "mGBA/src/gba/renderers/common.c",
                "mGBA/src/gba/renderers/software-bg.c",
                "mGBA/src/gba/renderers/software-mode0.c",
                "mGBA/src/gba/renderers/software-obj.c",
                "mGBA/src/gba/renderers/video-software.c",
                "mGBA/src/gba/savedata.c",
                "mGBA/src/gba/serialize.c",
                "mGBA/src/gba/sio.c",
                "mGBA/src/gba/sio/gbp.c",
                "mGBA/src/gba/sio/lockstep.c",
                "mGBA/src/gba/timer.c",
                "mGBA/src/gba/video.c",
                "mGBA/src/platform/posix/memory.c",
                "mGBA/src/third-party/blip_buf/blip_buf.c",
                "mGBA/src/third-party/inih/ini.c",
                "mGBA/src/util/circle-buffer.c",
                "mGBA/src/util/configuration.c",
                "mGBA/src/util/crc32.c",
                "mGBA/src/util/formatting.c",
                "mGBA/src/util/gbk-table.c",
                "mGBA/src/util/hash.c",
                "mGBA/src/util/patch-fast.c",
                "mGBA/src/util/patch-ips.c",
                "mGBA/src/util/patch-ups.c",
                "mGBA/src/util/patch.c",
                "mGBA/src/util/string.c",
                "mGBA/src/util/table.c",
                "mGBA/src/util/text-codec.c",
                "mGBA/src/util/vector.c",
                "mGBA/src/util/vfs.c",
                "mGBA/src/util/vfs/vfs-dirent.c",
                "mGBA/src/util/vfs/vfs-fd.c",
                "mGBA/src/util/vfs/vfs-fifo.c",
                "mGBA/src/util/vfs/vfs-mem.c"
            ],
            cSettings: [
                .headerSearchPath(""),
                .headerSearchPath("mGBA"),
                .headerSearchPath("mGBA/src"),
                .headerSearchPath("mGBA/include"),
                
                .define("DM_CORE_GBA"),
                .define("DDISABLE_THREADING"),
                .define("DMINIMAL_CORE", to: "1"),
                .define("DMGBA_STANDALONE"),
                .define("DHAVE_STRDUP"),
                .define("DHAVE_XLOCALE"),
                .define("DHAVE_STRNDUP"),
                .define("DHAVE_STRLCPY"),
                .define("DHAVE_LOCALTIME_R"),
                .define("DHAVE_LOCALE"),
                .define("DHAVE_STRTOF_L"),
                .define("DHAVE_SNPRINTF_L"),
                .define("DHAVE_SETLOCALE"),
                
                .define("M_CORE_GBA"),
                .define("DISABLE_THREADING"),
                .define("MINIMAL_CORE", to: "1"),
                .define("MGBA_STANDALONE"),
                .define("HAVE_STRDUP"),
                .define("HAVE_XLOCALE"),
                .define("HAVE_STRNDUP"),
                .define("HAVE_STRLCPY"),
                .define("HAVE_LOCALTIME_R"),
                .define("HAVE_LOCALE"),
                .define("HAVE_STRTOF_L"),
                .define("HAVE_SNPRINTF_L"),
                .define("HAVE_SETLOCALE"),
            ]
        )
    ]
)
