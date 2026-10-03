

# mpv-windows-builder

## xfdm LGPL fork

This branch builds an **LGPL-2.1-or-later libmpv** (`mpv-2.dll` only, no `mpv.exe`) for dynamic linking from a closed-source app:

- mpv `-Dgpl=false -Dcplayer=false`; cdda / dvdnav / dvda / dvbin / libbluray / libarchive / libcurl / win32-smtc disabled.
- vcpkg: libcdio, libcdio-paranoia, libdvdread, libdvdnav, libbluray, curl, libarchive, openssl removed. ffmpeg uses schannel for TLS and must report `License: LGPL version 2.1 or later` (enforced in the overlay port).
- mpv and libplacebo are pinned in `mpv-builder/clone-mpv.ps1`.
- `package-libmpv.ps1` produces `libmpv-lgpl-<tag>-<arch>.zip` (`bin/`, `include/`, `lib/`, `THIRD_PARTY_NOTICES.md`, `licenses/`, `build-info.json`) and fails if any statically linked component resolves to a GPL license. Ports without license metadata must be reviewed and listed in `mpv-deps-builder/license-overrides.json`.

The notes below describe the upstream GPL configuration.

## Overview
- Deps by vcpkg with clang-cl
- Only d3d11
- Only mpv.exe, windows >= 24H2(26100), see https://github.com/mpv-player/mpv/pull/15039

```
mpv.exe --v
[cplayer] Command line options: '--v'
[cplayer] mpv v0.40.0-UNKNOWN Copyright © 2000-2025 mpv/MPlayer/mplayer2 projects
```



## Requirements
- [vcpkg](https://github.com/microsoft/vcpkg)
- Visual Studio 2022 (with C++ llvm toolset)

## Build 
- see action/build-mpv.yml
- use --genvslite=vs2022 for visual studio ide

## Config

```
libplacebo 

  Optional features
    d3d11       : YES
    dovi        : YES
    gl-proc-addr: NO
    glslang     : NO
    lcms        : YES
    libdovi     : NO
    opengl      : NO
    shaderc     : YES
    vk-proc-addr: NO
    vulkan      : NO
    xxhash      : YES

mpv 

    cocoa                  : NO
    curl                   : YES
    d3d11                  : YES
    drm                    : NO
    javascript             : YES
    libmpv                 : YES
    lua                    : YES
    opengl                 : NO
    vulkan                 : NO
    wayland                : NO
    x11                    : NO

  Subprojects
    libplacebo             : YES 6 warnings

  User defined options
    buildtype              : release
    cplayer                : true
    cplugins               : enabled
    cuda-hwaccel           : disabled
    d3d11                  : enabled
    libplacebo:d3d11       : enabled
    d3d9-hwaccel           : disabled
    libplacebo:demos       : false
    libplacebo:dovi        : enabled
    drm                    : disabled
    force_fallback_for     : libplacebo
    gl                     : disabled
    libplacebo:gl-proc-addr: disabled
    gpl                    : true
    iconv                  : enabled
    javascript             : enabled
    jpeg                   : disabled
    libplacebo:lcms        : enabled
    libarchive             : enabled
    libbluray              : enabled
    libcurl                : enabled
    libmpv                 : true
    lua                    : luajit
    libplacebo:opengl      : disabled
    rubberband             : disabled
    libplacebo:shaderc     : enabled
    tests                  : false
    uchardet               : enabled
    libplacebo:unwind      : disabled
    vaapi                  : disabled
    vulkan                 : disabled
    libplacebo:vulkan      : disabled
    wayland                : disabled
    win32-smtc             : enabled
    win32-subsystem        : console
    wrap_mode              : nodownload
    x11                    : disabled
    zimg                   : disabled
```


## References
- [Custom vcpkg triplets](https://github.com/Neumann-A/my-vcpkg-triplets)
- [mpv official Windows build script](https://github.com/mpv-player/mpv/blob/master/ci/build-win32.ps1)
