# busybox_android

Builds `busybox` using `docker` and `musl` cross-compilation. 

Then copies the `busybox` binary to an Android device and installs symbolic links in the `$PATH`.

Useful for Android devices that don't ship with standard GNU Utils (i.e., only include [coreutils](https://wiki.debian.org/coreutils))

## Setup
* [adb](https://www.xda-developers.com/install-adb-windows-macos-linux/)
* [docker](https://www.docker.com/products/docker-desktop/)
* [task](https://taskfile.dev/installation/)

## Quickstart
```bash
# cross-compile busybox for arm
cd static-cross-bins/
./docker_build.sh TARGET=arm-linux-musleabi busybox

# copy bin to android device
cd ..
./android-install.sh

# open a shell to an attached android device
λ adb shell
/ # ls -l /system/bin
total 1864
lrwxrwxrwx    1 0        0               19 Oct 23 18:16 add-shell -> /system/bin/busybox
lrwxrwxrwx    1 0        0               19 Oct 23 18:16 addgroup -> /system/bin/busybox
lrwxrwxrwx    1 0        0               19 Oct 23 18:16 adduser -> /system/bin/busybox
lrwxrwxrwx    1 0        0               19 Oct 23 18:16 arch -> /system/bin/busybox
lrwxrwxrwx    1 0        0               19 Oct 23 18:16 arp -> /system/bin/busybox
lrwxrwxrwx    1 0        0               19 Oct 23 18:16 ash -> /system/bin/busybox
lrwxrwxrwx    1 0        0               19 Oct 23 18:16 awk -> /system/bin/busybox
...
```

## Further Reading
[Gnurou/busybox-android: A Busybox binary that is ready to be integrated into your Android project](https://github.com/Gnurou/busybox-android)

[Cross Compile Busybox For ARM - YouTube](https://www.youtube.com/watch?v=KfktWz4Ko3A)

[llamasoft/static-cross-bins: Static Cross-compiler Automation Toolkit](https://github.com/llamasoft/static-cross-bins)

[richfelker/musl-cross-make: Simple makefile-based build for musl cross compiler](https://github.com/richfelker/musl-cross-make)
