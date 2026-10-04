$arch = if ($env:ARCH) { $env:ARCH } else { 'x64' }
$triplet = "$arch-llvm-windows-static-mt"

Write-Host "Building Deps using vcpkg..."
$env:VCPKG_OVERLAY_TRIPLETS="$PSScriptRoot\llvm-triplets"
Write-Host "Using VCPKG_OVERLAY_TRIPLETS: $env:VCPKG_OVERLAY_TRIPLETS"

$VcpkgExe = "$env:VCPKG_ROOT\vcpkg.exe"
Write-Host "Using vcpkg: $VcpkgExe"

Write-Host "Building Deps using vcpkg ($triplet)..."
& $VcpkgExe install --triplet $triplet --allow-unsupported
if ($LASTEXITCODE -ne 0) { throw "vcpkg install failed ($LASTEXITCODE)" }

& xcopy /y /c /h /r /s "libs\*.*" "vcpkg_installed\$triplet\"
