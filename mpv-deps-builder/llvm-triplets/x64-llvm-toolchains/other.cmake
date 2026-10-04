# Per-port flags. Appended (not set) so that triplet-level flags such as the ARM64 --target survive;
# the SSE/AVX flags only apply to x86 targets.
if(PORT MATCHES "^(spirv-tools)$")
    string(APPEND VCPKG_CXX_FLAGS " -Wno-error=unused-command-line-argument")
    string(APPEND VCPKG_C_FLAGS " -Wno-error=unused-command-line-argument")
endif()

if(VCPKG_TARGET_ARCHITECTURE MATCHES "^(x86|x64)$")
    if(PORT MATCHES "^(opus)$")
        string(APPEND VCPKG_CXX_FLAGS " -mssse3 -msse4.1")
        string(APPEND VCPKG_C_FLAGS " -mssse3 -msse4.1")
    endif()

    if(PORT MATCHES "^(libvpx)$")
        string(APPEND VCPKG_CXX_FLAGS " -msse3 -mssse3 -msse4.1 -msse4.2 -mavx -mavx2")
        string(APPEND VCPKG_C_FLAGS " -msse3 -mssse3 -msse4.1 -msse4.2 -mavx -mavx2")
    endif()
endif()

if(VCPKG_TARGET_ARCHITECTURE STREQUAL "arm64")
    # libwebp's SIMD flag probing emits an empty -mfpu= that clang-cl rejects for aarch64.
    # NEON is still selected from the _M_ARM64 predefine; WebP only matters for images, not video.
    if(PORT MATCHES "^(libwebp)$")
        list(APPEND VCPKG_CMAKE_CONFIGURE_OPTIONS "-DWEBP_ENABLE_SIMD=OFF")
    endif()
    # opus' ARM runtime CPU detection (celt/arm/armcpu.c) takes the _MSC_VER branch under clang-cl and calls
    # the MSVC-only __emit intrinsic; its CMake cannot presume NEON without also compiling that file, and its
    # headers assume PRESUME implies MAY_HAVE. Same choice as vcpkg's own arm64 MinGW path: plain C opus.
    # Only affects Opus audio decoding cost, not video.
    if(PORT MATCHES "^(opus)$")
        list(APPEND VCPKG_CMAKE_CONFIGURE_OPTIONS "-DOPUS_DISABLE_INTRINSICS=ON")
    endif()
endif()
