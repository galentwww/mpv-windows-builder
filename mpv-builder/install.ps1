$arch = if ($env:ARCH) { $env:ARCH } else { 'x64' }
meson install -C build --destdir=mpv-windows-$arch
