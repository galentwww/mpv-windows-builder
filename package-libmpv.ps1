#Requires -Version 7
<#
.SYNOPSIS
  Package the LGPL libmpv build as libmpv-lgpl-<Tag>-<arch>.zip and fail on any GPL leak.

.DESCRIPTION
  Layout (consumed by xfdm tools/fetch-mpv-libs.ps1):
    bin/mpv-2.dll, include/mpv/*.h, lib/mpv.lib, THIRD_PARTY_NOTICES.md, licenses/, build-info.json
  Gates: meson gpl=false and cplayer=false; ffmpeg "LGPL version 2.1 or later" without
  --enable-gpl/nonfree/version3; every statically linked vcpkg port resolves to a non-GPL license
  (dual licenses are elected to the non-GPL alternative, unknowns must be listed in
  mpv-deps-builder/license-overrides.json after review).
#>
[CmdletBinding(PositionalBinding = $false)]
param(
    [Parameter(Mandatory)][string]$Tag,
    [ValidateSet('x64')][string]$Arch = 'x64',
    [string]$Triplet = "$Arch-llvm-windows-static-mt",
    [string]$OutDir = (Join-Path $PSScriptRoot 'dist')
)

$ErrorActionPreference = 'Stop'
$gplPattern = '(?<!L)GPL'

$mpvSrc = Join-Path $PSScriptRoot 'mpv-builder/mpv-windows'
$installDir = Join-Path $mpvSrc 'build/mpv-windows-x64'
$vcpkgDir = Join-Path $PSScriptRoot "mpv-deps-builder/vcpkg_installed/$Triplet"
$overrides = Get-Content (Join-Path $PSScriptRoot 'mpv-deps-builder/license-overrides.json') -Raw | ConvertFrom-Json -AsHashtable

# meson options
$options = meson introspect (Join-Path $mpvSrc 'build') --buildoptions | ConvertFrom-Json
function Get-MesonOption([string]$name) { ($options | Where-Object name -eq $name).value }
if ((Get-MesonOption 'gpl') -ne $false) { throw "meson gpl is not false: $(Get-MesonOption 'gpl')" }
if ((Get-MesonOption 'cplayer') -ne $false) { throw 'meson cplayer is not false' }

# ffmpeg, recorded by the overlay port
$ffInfo = @{}
Get-Content (Join-Path $vcpkgDir 'share/ffmpeg/xfdm-build-info.txt') | ForEach-Object {
    if ($_ -match '^(?<k>[^=:]+)[=:]\s*(?<v>.*)$') { $ffInfo[$Matches.k.Trim()] = $Matches.v }
}
if ($ffInfo.License -ne 'LGPL version 2.1 or later') { throw "ffmpeg license: $($ffInfo.License)" }
if (-not $ffInfo.configuration -or $ffInfo.configuration -match '--enable-(gpl|nonfree|version3)\b') {
    throw "ffmpeg configuration rejected: $($ffInfo.configuration)"
}

function Resolve-License([string]$port, [string]$expr) {
    if ($overrides.ContainsKey($port)) { return $overrides[$port] }
    if (-not $expr -or $expr -eq 'NOASSERTION') { return $null }
    $alternatives = $expr -split '\s+OR\s+' | ForEach-Object { $_.Trim('() ') }
    $elected = $alternatives | Where-Object { $_ -notmatch $gplPattern } | Select-Object -First 1
    if ($elected) { return $elected } else { return $expr }
}

$git = { param($dir) (git -C $dir rev-parse HEAD).Trim() }
$mpvCommit = & $git $mpvSrc
$placeboCommit = & $git (Join-Path $mpvSrc 'subprojects/libplacebo')
$mpvVersion = "v$((Get-Content (Join-Path $mpvSrc 'VERSION') -Raw).Trim())-g$($mpvCommit.Substring(0, 9))"

$rows = [System.Collections.Generic.List[object]]::new()
$rows.Add([pscustomobject]@{ Name = 'mpv'; Version = $mpvVersion; License = 'LGPL-2.1-or-later'; Source = "https://github.com/mpv-player/mpv/tree/$mpvCommit" })
$rows.Add([pscustomobject]@{ Name = 'libplacebo'; Version = $placeboCommit.Substring(0, 12); License = 'LGPL-2.1-or-later'; Source = "https://github.com/haasn/libplacebo/tree/$placeboCommit" })

$errors = [System.Collections.Generic.List[string]]::new()
foreach ($spdxFile in Get-ChildItem (Join-Path $vcpkgDir 'share') -Filter vcpkg.spdx.json -Recurse -Depth 1) {
    $port = $spdxFile.Directory.Name
    $pkg = (Get-Content $spdxFile -Raw | ConvertFrom-Json).packages | Where-Object SPDXID -eq 'SPDXRef-port' | Select-Object -First 1
    $declared = if ($pkg.licenseConcluded -and $pkg.licenseConcluded -ne 'NOASSERTION') { $pkg.licenseConcluded } else { $pkg.licenseDeclared }
    $license = Resolve-License $port $declared
    if (-not $license) { $errors.Add("$port`: no license metadata (add to license-overrides.json after review)"); continue }
    if ($license -match $gplPattern) { $errors.Add("$port`: $license"); continue }
    $source = if ($pkg.homepage -and $pkg.homepage -ne 'NOASSERTION') { $pkg.homepage } else { $pkg.downloadLocation }
    $rows.Add([pscustomobject]@{ Name = $port; Version = $pkg.versionInfo; License = $license; Source = $source })
}
if ($errors.Count) { throw "license gate failed:`n$($errors -join "`n")" }

# stage
$stage = Join-Path $OutDir "stage-$Arch"
if (Test-Path $stage) { Remove-Item $stage -Recurse -Force }
New-Item -ItemType Directory -Path "$stage/bin", "$stage/lib", "$stage/licenses" | Out-Null
Copy-Item (Join-Path $installDir 'bin/mpv-2.dll') "$stage/bin/"
Copy-Item (Join-Path $installDir 'include') $stage -Recurse
Copy-Item (Join-Path $installDir 'lib/mpv.lib') "$stage/lib/"

Copy-Item (Join-Path $mpvSrc 'LICENSE.LGPL') "$stage/licenses/mpv-LICENSE.LGPL.txt"
Copy-Item (Join-Path $mpvSrc 'Copyright') "$stage/licenses/mpv-Copyright.txt"
Copy-Item (Join-Path $mpvSrc 'subprojects/libplacebo/LICENSE') "$stage/licenses/libplacebo-LICENSE.txt"
foreach ($row in $rows | Where-Object Name -notin 'mpv', 'libplacebo') {
    $copyright = Join-Path $vcpkgDir "share/$($row.Name)/copyright"
    if (Test-Path $copyright) { Copy-Item $copyright "$stage/licenses/$($row.Name).txt" }
}

$builder = if ($env:GITHUB_REPOSITORY) { "$env:GITHUB_SERVER_URL/$env:GITHUB_REPOSITORY/tree/$env:GITHUB_SHA" } else { "local build $((git -C $PSScriptRoot rev-parse HEAD).Trim())" }
$notices = @(
    '# Third-Party Notices: libmpv (LGPL build)'
    ''
    "``mpv-2.dll`` is built from mpv with ``-Dgpl=false`` and is licensed under the GNU Lesser General Public License, version 2.1 or later. Every component below is statically linked into ``mpv-2.dll``. Full license texts are in ``licenses/``."
    ''
    "Build scripts and modifications: $builder"
    ''
    '| Component | Version | License | Source |'
    '|-----------|---------|---------|--------|'
    $rows | Sort-Object { $_.Name -notin 'mpv', 'libplacebo' }, Name | ForEach-Object { "| $($_.Name) | $($_.Version) | $($_.License) | $($_.Source) |" }
)
$notices | Set-Content "$stage/THIRD_PARTY_NOTICES.md" -Encoding utf8NoBOM
if (Select-String -Path "$stage/THIRD_PARTY_NOTICES.md" -Pattern $gplPattern -CaseSensitive) { throw 'THIRD_PARTY_NOTICES.md contains a GPL entry' }

[ordered]@{
    gpl              = $false
    platform         = $Arch
    tag              = $Tag
    mpvVersion       = $mpvVersion
    mpvCommit        = $mpvCommit
    libplaceboCommit = $placeboCommit
    ffmpegVersion    = $ffInfo.version
    ffmpegLicense    = $ffInfo.License
    ffmpegConfigure  = $ffInfo.configuration
    vcpkgTriplet     = $Triplet
    builder          = $builder
} | ConvertTo-Json | Set-Content "$stage/build-info.json" -Encoding utf8NoBOM

$zip = Join-Path $OutDir "libmpv-lgpl-$Tag-$($Arch.ToLowerInvariant()).zip"
Compress-Archive -Path "$stage/*" -DestinationPath $zip -Force
$pdb = Join-Path $installDir 'bin/mpv-2.pdb'
if (Test-Path $pdb) { Compress-Archive -Path $pdb -DestinationPath (Join-Path $OutDir "libmpv-lgpl-$Tag-$($Arch.ToLowerInvariant())-pdb.zip") -Force }
Get-ChildItem $OutDir -Filter "libmpv-lgpl-$Tag-*.zip" | ForEach-Object {
    "$((Get-FileHash -Algorithm SHA256 $_).Hash.ToLowerInvariant())  $($_.Name)"
} | Set-Content (Join-Path $OutDir "libmpv-lgpl-$Tag-$($Arch.ToLowerInvariant()).sha256") -Encoding utf8NoBOM
Write-Host "packaged $zip"
