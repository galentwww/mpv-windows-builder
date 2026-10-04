set(VCPKG_TARGET_ARCHITECTURE arm64)
set(VCPKG_CRT_LINKAGE static)
set(VCPKG_LIBRARY_LINKAGE static)

set(VCPKG_BUILD_TYPE "release")

# Same clang-cl toolchain as x64 (the directory name is historical); the target is pinned
# explicitly so an emulated x64 clang-cl on an ARM64 host cannot silently produce x64 objects.
set(VCPKG_C_FLAGS "--target=aarch64-pc-windows-msvc")
set(VCPKG_CXX_FLAGS "--target=aarch64-pc-windows-msvc")

set(VCPKG_CHAINLOAD_TOOLCHAIN_FILE "${CMAKE_CURRENT_LIST_DIR}/x64-llvm-toolchains/clangcl-windows.cmake")
set(VCPKG_LOAD_VCVARS_ENV ON)

if(DEFINED VCPKG_PLATFORM_TOOLSET)
    set(VCPKG_PLATFORM_TOOLSET ClangCL)
endif()
set(VCPKG_ENV_PASSTHROUGH_UNTRACKED "LLVMInstallDir;LLVMToolsVersion")


set(VCPKG_POLICY_SKIP_ARCHITECTURE_CHECK enabled)
set(VCPKG_POLICY_SKIP_DUMPBIN_CHECKS enabled)


include("${CMAKE_CURRENT_LIST_DIR}/x64-llvm-toolchains/other.cmake")
