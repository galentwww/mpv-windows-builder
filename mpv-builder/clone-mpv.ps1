# Pinned to the upstream commits used by the 20260831 ikas-mc build (mpv v0.41.0-dev-ge8673660a),
# so that LGPL vs GPL A/B comparisons only differ in build configuration.
$mpvCommit = 'e8673660ab7ee5d4ea8f93e4bf3a6e170ab2a19a'
$libplaceboCommit = '41ac2980e1a898f41d7c2e07999f9862ee89d99f'

function Get-PinnedSource([string]$url, [string]$commit, [string]$dir) {
    git init -q $dir
    git -C $dir fetch -q --depth 1 $url $commit
    if ($LASTEXITCODE -ne 0) { throw "fetch $url@$commit failed" }
    git -C $dir checkout -q FETCH_HEAD
}

if (-not (Test-Path -Path 'mpv-windows')) {
    Get-PinnedSource 'https://github.com/mpv-player/mpv.git' $mpvCommit 'mpv-windows'

    if (Test-Path -Path 'mpv') {
        Copy-Item -Path 'mpv\*' -Destination 'mpv-windows\' -Recurse -Force
    }

    New-Item -Path 'mpv-windows\subprojects' -ItemType Directory -Force | Out-Null
    Get-PinnedSource 'https://github.com/haasn/libplacebo.git' $libplaceboCommit 'mpv-windows/subprojects/libplacebo'
}
