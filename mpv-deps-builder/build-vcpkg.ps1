Write-Host "Building Deps using vcpkg..."
$env:VCPKG_OVERLAY_TRIPLETS="$PSScriptRoot\llvm-triplets"
Write-Host "Using VCPKG_OVERLAY_TRIPLETS: $env:VCPKG_OVERLAY_TRIPLETS" 

$VcpkgExe = "$env:VCPKG_ROOT\vcpkg.exe"
Write-Host "Using vcpkg: $VcpkgExe"

Write-Host "Building Deps using vcpkg..."
& $VcpkgExe install --triplet x64-llvm-windows-static-mt --allow-unsupported
if ($LASTEXITCODE -ne 0) { throw "vcpkg install failed ($LASTEXITCODE)" }

& xcopy /y /c /h /r /s "libs\*.*" "vcpkg_installed\x64-llvm-windows-static-mt\"