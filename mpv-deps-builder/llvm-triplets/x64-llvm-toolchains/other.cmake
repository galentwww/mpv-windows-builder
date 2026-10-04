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
