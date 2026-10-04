
if (-not $env:VS_ROOT) {
    $env:VS_ROOT="C:\Program Files\Microsoft Visual Studio\2022\Community"
}

# ARCH=x64 builds on an x64 host; ARCH=arm64 builds natively on an ARM64 host (windows-11-arm runner).
$devArch = if ($env:ARCH -eq 'arm64') { 'arm64' } else { 'amd64' }
& "$env:VS_ROOT\Common7\Tools\Launch-VsDevShell.ps1" -Arch $devArch -HostArch $devArch -SkipAutomaticLocation | Out-Null
