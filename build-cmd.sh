#!/bin/bash

# turn on verbose debugging output for parabuild logs.
set -x
eval "$("$AUTOBUILD" source_environment)"
# make errors fatal
set -e

OPENAL_VERSION="1.17.2"
OPENAL_SOURCE_DIR="openal-soft"

FREEALUT_VERSION="1.1.0"
FREEALUT_SOURCE_DIR="freealut"

if [ -z "$AUTOBUILD" ] ; then 
    fail
fi

if [ "$OSTYPE" = "cygwin" ] ; then
    export AUTOBUILD="$(cygpath -u $AUTOBUILD)"
fi

# load autbuild provided shell functions and variables
set +x
eval "$("$AUTOBUILD" source_environment)"
set -x

stage="$(pwd)"

echo "${OPENAL_VERSION}-${FREEALUT_VERSION}" > "${stage}/VERSION.txt"

case "$AUTOBUILD_PLATFORM" in
    "windows")
        cmake "../$OPENAL_SOURCE_DIR" -G"Visual Studio 12" -DCMAKE_INSTALL_PREFIX=$stage \
            -DALSOFT_NO_CONFIG_UTIL:BOOL=ON -DALSOFT_UTILS:BOOL=OFF
        build_sln "OpenAL.sln" "Debug|Win32" "OpenAL32"
        mkdir -p "$stage/lib"
        mv Debug "$stage/lib/debug"

        build_sln "OpenAL.sln" "Release|Win32" "OpenAL32"
        mv Release "$stage/lib/release"
        
        pushd "$stage/../$FREEALUT_SOURCE_DIR/admin/VisualStudioDotNET"
            build_sln "alut.sln" "Debug|Win32" "alut"
            build_sln "alut.sln" "Release|Win32" "alut"
            
            cp -a "alut/Debug/Win32/alut.dll" "$stage/lib/debug"
            cp -a "alut/Debug/Win32/alut.lib" "$stage/lib/debug"
            cp -a "alut/Debug/Win32/alut.pdb" "$stage/lib/debug"
            cp -a "alut/Release/Win32/alut.dll" "$stage/lib/release"
            cp -a "alut/Release/Win32/alut.lib" "$stage/lib/release"
            cp -a "alut/Release/Win32/alut.pdb" "$stage/lib/release"
        popd
    ;;
    "windows64")
        cmake "../$OPENAL_SOURCE_DIR" -G"Visual Studio 12 Win64" -DCMAKE_INSTALL_PREFIX=$stage \
            -DALSOFT_NO_CONFIG_UTIL:BOOL=ON -DALSOFT_UTILS:BOOL=OFF
        build_sln "OpenAL.sln" "Debug|x64" "OpenAL32"
        mkdir -p "$stage/lib"
        mv Debug "$stage/lib/debug"

        build_sln "OpenAL.sln" "Release|x64" "OpenAL32"
        mv Release "$stage/lib/release"
        
        pushd "$stage/../$FREEALUT_SOURCE_DIR/admin/VisualStudioDotNET"
            build_sln "alut.sln" "Debug|x64" "alut"
            build_sln "alut.sln" "Release|x64" "alut"
            
            cp -a "alut/Debug/x64/alut.dll" "$stage/lib/debug"
            cp -a "alut/Debug/x64/alut.lib" "$stage/lib/debug"
            cp -a "alut/Debug/x64/alut.pdb" "$stage/lib/debug"
            cp -a "alut/Release/x64/alut.dll" "$stage/lib/release"
            cp -a "alut/Release/x64/alut.lib" "$stage/lib/release"
            cp -a "alut/Release/x64/alut.pdb" "$stage/lib/release"
        popd
    ;;
    "linux")
        JOBS=`cat /proc/cpuinfo | grep processor | wc -l`
        HARDENED="-fstack-protector -D_FORTIFY_SOURCE=2"

        mkdir -p openal
        pushd openal
            cmake ../../$OPENAL_SOURCE_DIR -DCMAKE_C_FLAGS="-m32 $HARDENED" -DCMAKE_CXX_FLAGS="-m32 $HARDENED" \
                -DALSOFT_NO_CONFIG_UTIL:BOOL=ON -DALSOFT_UTILS:BOOL=OFF
            make -j$JOBS
        popd

        mkdir -p "$stage/lib/release"
        cp -a $stage/openal/libopenal.so* "$stage/lib/release"

        mkdir -p freealut
        pushd freealut
            cmake ../../$FREEALUT_SOURCE_DIR -DCMAKE_C_FLAGS="-m32 $HARDENED" -DCMAKE_CXX_FLAGS="-m32 $HARDENED" \
                -DOPENAL_LIB_DIR="$stage/openal" -DOPENAL_INCLUDE_DIR="$stage/../$OPENAL_SOURCE_DIR/include"
            make -j$JOBS
            cp -P libalut.so "$stage/lib/release"
            cp -P libalut.so.0 "$stage/lib/release"
            cp -P libalut.so.0.0.0 "$stage/lib/release"
        popd
    ;;
    "linux64")
        JOBS=`cat /proc/cpuinfo | grep processor | wc -l`
        HARDENED="-fstack-protector -D_FORTIFY_SOURCE=2"

        mkdir -p openal
        pushd openal
            cmake ../../$OPENAL_SOURCE_DIR -DCMAKE_C_FLAGS="-m64 $HARDENED" -DCMAKE_CXX_FLAGS="-m64 $HARDENED" \
                -DALSOFT_NO_CONFIG_UTIL:BOOL=ON -DALSOFT_UTILS:BOOL=OFF
            make -j$JOBS
        popd

        mkdir -p "$stage/lib/release"
        cp -a $stage/openal/libopenal.so* "$stage/lib/release"

        mkdir -p freealut
        pushd freealut
            cmake ../../$FREEALUT_SOURCE_DIR -DCMAKE_C_FLAGS="-m64 $HARDENED" -DCMAKE_CXX_FLAGS="-m64 $HARDENED" \
                -DOPENAL_LIB_DIR="$stage/openal" -DOPENAL_INCLUDE_DIR="$stage/../$OPENAL_SOURCE_DIR/include"
            make -j$JOBS
            cp -P libalut.so "$stage/lib/release"
            cp -P libalut.so.0 "$stage/lib/release"
            cp -P libalut.so.0.0.0 "$stage/lib/release"
        popd
    ;;
    "darwin")
        mkdir -p openal
        pushd openal
            cmake ../../$OPENAL_SOURCE_DIR -DCMAKE_OSX_ARCHITECTURES='i386;x86_64' \
                  -DCMAKE_C_COMPILER=clang -DCMAKE_C_FLAGS='-Wno-self-assign' \
                  -DALSOFT_NO_CONFIG_UTIL:BOOL=ON -DALSOFT_UTILS:BOOL=OFF
        make
        popd

        mkdir -p "$stage/lib/release"
        cp -P "$stage/openal/libopenal.dylib" "$stage/lib/release"
        cp -P "$stage/openal/libopenal.1.dylib" "$stage/lib/release"
        cp "$stage/openal/libopenal.${OPENAL_VERSION}.dylib" "$stage/lib/release"

        mkdir -p freealut
        pushd freealut
            cmake ../../$FREEALUT_SOURCE_DIR -DCMAKE_OSX_ARCHITECTURES='i386;x86_64' \
                -DCMAKE_C_COMPILER=clang \
                -DOPENAL_LIB_DIR="$stage/openal" -DOPENAL_INCLUDE_DIR="$stage/../$OPENAL_SOURCE_DIR/include"
        make
        cp -P "$stage/freealut/libalut.a" "$stage/lib/release"
        cp -P "$stage/freealut/libalut_static.a" "$stage/lib/release"
        cp -P "$stage/freealut/libalut.dylib" "$stage/lib/release"
        cp -P "$stage/freealut/libalut.0.dylib" "$stage/lib/release"
        cp -P "$stage/freealut/libalut.0.0.0.dylib" "$stage/lib/release"
        popd
        pushd "$stage/lib/release/"
            fix_dylib_id libalut.0.dylib
            fix_dylib_id libalut.dylib
            fix_dylib_id libopenal.${OPENAL_VERSION}.dylib
            fix_dylib_id libopenal.1.dylib
            fix_dylib_id libopenal.dylib
        popd
    ;;
esac

cp -r "$stage/../$OPENAL_SOURCE_DIR/include" "$stage"
cp -r "$stage/../$FREEALUT_SOURCE_DIR/include" "$stage"

mkdir -p "$stage/LICENSES"
cp "$stage/../$OPENAL_SOURCE_DIR/COPYING" "$stage/LICENSES/openal.txt"

pass

