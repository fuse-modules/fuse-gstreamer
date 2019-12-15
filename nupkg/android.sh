#!/bin/bash
set -e
ndkRoot="C:\\android-ndk-r18b"
gstRoot="C:\\gstreamer\\android"
"$ndkRoot\\ndk-build.cmd" \
    APP_PLATFORM=android-16 \
    NDK_APPLICATION_MK=jni/Application.mk \
    GSTREAMER_JAVA_SRC_DIR=src \
    GSTREAMER_ROOT_ANDROID=$gstRoot \
    GSTREAMER_ASSETS_DIR=src/assets

function copy {
    local abi1=$1
    local abi2=$2
    cp -fv "libs/$abi1/libc++_shared.so" "$gstRoot/$abi2/lib"
    cp -fv "libs/$abi1/libgstreamer_android.so" "$gstRoot/$abi2/lib"
}

copy armeabi-v7a armv7
copy arm64-v8a arm64
copy x86_64 x86_64
copy x86 x86

# Build NUPKG.
cp -fv gstreamer-android-shared.nuspec "$gstRoot"
cd "$gstRoot"
nuget pack
