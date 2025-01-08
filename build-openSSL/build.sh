#!/bin/bash

if [ -z "$ANDROID_NDK" ]; then
  echo "Please set Android NDK folder to the ANDROID_NDK environment variable"
  echo "Usage to set a temporary environment variable -"
  echo "export ANDROID_NDK=<NDK_PATH>"
  exit 1
fi

if ! command -v cmake &> /dev/null
then
    echo "cmake could not be found"
    exit 1
fi

# Define NDK version
export ANDROID_NDK_ROOT=$ANDROID_NDK

# Define the version and download URL
OPENSSL_VERSION="3.0.5"
OPENSSL_URL="https://www.openssl.org/source/openssl-$OPENSSL_VERSION.tar.gz"

# Define directories
WORKING_DIR=$(pwd)
SRC_DIR="$WORKING_DIR/openssl"
BUILD_DIR="$WORKING_DIR/build"

# Clean up any previous builds
rm -rf $BUILD_DIR $SRC_DIR
mkdir -p $BUILD_DIR

# Download and extract openssl
curl -L $OPENSSL_URL -o "$WORKING_DIR/openssl-$OPENSSL_VERSION.tar.gz"
tar -xzf "$WORKING_DIR/openssl-$OPENSSL_VERSION.tar.gz" -C $WORKING_DIR
mv "$WORKING_DIR/openssl-$OPENSSL_VERSION" "$WORKING_DIR/openssl"

function build_library {
    # Check if the ouput folder exists
    if [ -d $1 ]; then
      # If it exists, delete the folder
      rm -rf "$1"
      echo "Existing folder '$1' deleted."
    fi

    # Creating output directory
    mkdir -p $1

    # https://github.com/openssl/openssl/blob/master/INSTALL.md#makefile-targets
    # Clean:
    make -f Makefile clean

    #install_sw Only install the OpenSSL software components.
    make -j8
    make install_sw

    # Deleting OPENSSL_TMP_FOLDER
    rm -rf $2

    # Cleaning output folder
    rm -rf $1/lib/engines-3 $1/lib/ossl-modules $1/lib/pkgconfig $1/bin

    # Rename lib folder to libs
    mv $1/lib $1/libs

    echo "Build completed! Check output libraries in $1"
}

function build_arch() {
    echo ""
	echo "----- Build libcrypto & libssl.so for "$1" -----"
	echo ""

    sleep 2

    ANDROID_ABI=$1
	TARGET_API_LEVEL=$2
    # https://openssl-library.org/policies/platforms/index.html
	OPENSSL_CONFIGURATION_ARCHITECTURE=$3
    # https://developer.android.com/ndk/guides/other_build_systems#overview
    # Andoid ABI Triple
    ANDROID_ABI_TRIPLE=$4

    # Creating output directory
    OUTPUT_ABI_DIR="${WORKING_DIR}/build/$ANDROID_ABI"

    # Creating tmp folder to perform all openssl operations; do not touch original source code
    OPENSSL_TMP_FOLDER=$BUILD_DIR/tmp/openssl_${ANDROID_ABI}
    mkdir -p ${OPENSSL_TMP_FOLDER}
    cp -r ${SRC_DIR}/* ${OPENSSL_TMP_FOLDER}

    # Setting up toolchain
    # https://developer.android.com/ndk/guides/other_build_systems
    export TOOLCHAIN=$ANDROID_NDK_ROOT/toolchains/llvm/prebuilt/darwin-x86_64
    export AR=$TOOLCHAIN/bin/llvm-ar
    # In these cases, you can typically include the -target argument as part of the compiler definition (e.g. CC="clang -target aarch64-linux-android21).
    export CC="$TOOLCHAIN/bin/clang --target=$ANDROID_ABI_TRIPLE$TARGET_API_LEVEL"
    export AS=$CC
    export CXX="$TOOLCHAIN/bin/clang++ --target=$ANDROID_ABI_TRIPLE$TARGET_API_LEVEL"
    export LD=$TOOLCHAIN/bin/ld
    export RANLIB=$TOOLCHAIN/bin/llvm-ranlib
    export STRIP=$TOOLCHAIN/bin/llvm-strip
	export CXXFLAGS="-std=c++11 -fPIC"
	export CPPFLAGS="-DANDROID -fPIC"

    cd $OPENSSL_TMP_FOLDER

	# Build openssl libraries
	export PATH=$ANDROID_NDK_ROOT/toolchains/llvm/prebuilt/darwin-x86_64/bin:$PATH
    # https://wiki.openssl.org/index.php/Compilation_and_Installation#Configure_Options
    # adding shared flag to below command creates .so files
    # Removing __ANDROID_API__ macro,
    # Directly setting __ANDROID_API__ is now discouraged and instead, behind the scenes, that macro is automatically set to the value of __ANDROID_MIN_SDK_VERSION__.
    # If -D__ANDROID_API__=23 is set directly nonetheless, the warning that it is redefined is emitted.
    # Thus, to prevent that warning it is necessary to set __ANDROID_MIN_SDK_VERSION__ instead of __ANDROID_API__.
    # https://developer.android.com/ndk/guides/other_build_systems#overview
    # https://github.com/llvm/llvm-project/commit/0849047860a343d8bcf1f828a82d585e89079943
	./configure $OPENSSL_CONFIGURATION_ARCHITECTURE --openssldir=${OUTPUT_ABI_DIR} --prefix=${OUTPUT_ABI_DIR} no-shared threads no-asm no-sse2 no-ssl3 no-comp no-engine no-dso no-err

    build_library $OUTPUT_ABI_DIR $OPENSSL_TMP_FOLDER
}

function cleanup(){
    rm -rf $BUILD_DIR/tmp $SRC_DIR
    rm $WORKING_DIR/openssl-$OPENSSL_VERSION.tar.gz
}

build_arch "armeabi-v7a" "23" "android-arm" "armv7a-linux-androideabi"
build_arch "arm64-v8a" "23" "android-arm64" "aarch64-linux-android"
build_arch "x86" "23" "android-x86" "i686-linux-android"
build_arch "x86_64" "23" "android-x86_64" "x86_64-linux-android"

cleanup

exit 0
