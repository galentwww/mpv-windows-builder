ninja -C build mpv-2.dll
if ($LASTEXITCODE -ne 0) { throw "ninja failed ($LASTEXITCODE)" }
