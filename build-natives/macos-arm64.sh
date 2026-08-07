#!/bin/sh
# Build libheif with statically absorbed libde265 and dav1d decoders and stage
# the one resulting shared library for the macos-arm64 classifier jar.
set -eu

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
HEIF_VERSION=1.23.1
DE265_VERSION=1.1.1
DAV1D_VERSION=1.5.4
HEIF_SRC="${1:-$ROOT/build/libheif-$HEIF_VERSION}"
DE265_SRC="$ROOT/build/libde265-$DE265_VERSION"
DE265_PREFIX="$ROOT/build/prefix-libde265-macos-arm64"
DAV1D_SRC="$ROOT/build/dav1d-$DAV1D_VERSION"
DAV1D_PREFIX="$ROOT/build/prefix-dav1d-macos-arm64"
PREFIX="$ROOT/build/prefix-macos-arm64"
DEST="$ROOT/natives/src/main/resources/libheif-natives/macos-arm64"

mkdir -p "$ROOT/build"
if [ ! -d "$DE265_SRC" ]; then
  curl -sfL "https://github.com/strukturag/libde265/releases/download/v$DE265_VERSION/libde265-$DE265_VERSION.tar.gz" | tar xz -C "$ROOT/build"
fi
if [ ! -d "$DAV1D_SRC" ]; then
  curl -sfL "https://downloads.videolan.org/pub/videolan/dav1d/$DAV1D_VERSION/dav1d-$DAV1D_VERSION.tar.xz" | tar xJ -C "$ROOT/build"
fi
[ -d "$HEIF_SRC" ] || { echo "missing $HEIF_SRC; fetch libheif $HEIF_VERSION first"; exit 1; }

cmake -S "$DE265_SRC" -B "$DE265_SRC/build-macos-arm64" -G Ninja \
  -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$DE265_PREFIX" \
  -DCMAKE_INSTALL_LIBDIR=lib -DBUILD_SHARED_LIBS=OFF \
  -DCMAKE_POSITION_INDEPENDENT_CODE=ON -DENABLE_SDL=OFF -DENABLE_DECODER=OFF \
  -DENABLE_ENCODER=OFF -DENABLE_SHERLOCK265=OFF
cmake --build "$DE265_SRC/build-macos-arm64" --target install

if [ ! -f "$DAV1D_PREFIX/lib/pkgconfig/dav1d.pc" ]; then
  meson setup "$DAV1D_SRC/build-macos-arm64" "$DAV1D_SRC" \
    --prefix="$DAV1D_PREFIX" --libdir=lib --buildtype=release \
    -Ddefault_library=static -Denable_tools=false -Denable_tests=false
  ninja -C "$DAV1D_SRC/build-macos-arm64" install
fi

export PKG_CONFIG_PATH="$DE265_PREFIX/lib/pkgconfig:$DAV1D_PREFIX/lib/pkgconfig"
cmake -S "$HEIF_SRC" -B "$HEIF_SRC/build-macos-arm64" -G Ninja \
  -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$PREFIX" -DCMAKE_INSTALL_LIBDIR=lib \
  -DCMAKE_PREFIX_PATH="$DE265_PREFIX;$DAV1D_PREFIX" -DCMAKE_INSTALL_NAME_DIR='@loader_path' \
  -DBUILD_SHARED_LIBS=ON -DENABLE_PLUGIN_LOADING=OFF \
  -DWITH_LIBDE265=ON -DWITH_LIBDE265_PLUGIN=OFF \
  -DWITH_X265=OFF -DWITH_KVAZAAR=OFF -DWITH_UVG266=OFF \
  -DWITH_VVDEC=OFF -DWITH_VVENC=OFF -DWITH_X264=OFF -DWITH_OpenH264_DECODER=OFF \
  -DWITH_DAV1D=ON -DWITH_DAV1D_PLUGIN=OFF -DWITH_AOM_DECODER=OFF -DWITH_AOM_ENCODER=OFF \
  -DWITH_SvtEnc=OFF -DWITH_RAV1E=OFF -DWITH_JPEG_DECODER=OFF -DWITH_JPEG_ENCODER=OFF \
  -DWITH_OpenJPEG_DECODER=OFF -DWITH_OpenJPEG_ENCODER=OFF \
  -DWITH_FFMPEG_DECODER=OFF -DWITH_OPENJPH_ENCODER=OFF \
  -DWITH_UNCOMPRESSED_CODEC=OFF -DWITH_LIBSHARPYUV=OFF \
  -DWITH_EXAMPLES=OFF -DWITH_GDK_PIXBUF=OFF -DBUILD_DOCUMENTATION=OFF -DBUILD_TESTING=OFF
cmake --build "$HEIF_SRC/build-macos-arm64" --target install

rm -rf "$DEST"
mkdir -p "$DEST"
real_lib="$(cd "$PREFIX/lib" && readlink -f libheif.dylib)"
base="$(basename "$(otool -D "$real_lib" | tail -1)")"
cp "$real_lib" "$DEST/$base"
chmod 644 "$DEST/$base"
printf '%s\n' "$base" > "$DEST/manifest.txt"

if otool -L "$DEST/$base" | tail -n +2 | awk '{print $1}' \
    | grep -vE '^(@loader_path/)?libheif|^/usr/lib/|^/System/Library/'; then
  echo "ERROR: staged libheif has non-system dynamic dependencies (above)"; exit 1
fi

cp "$HEIF_SRC/COPYING" "$DEST/COPYING.libheif"
cp "$DE265_SRC/COPYING" "$DEST/COPYING.libde265"
cp "$DAV1D_SRC/COPYING" "$DEST/COPYING.dav1d"
{
  echo "libheif $HEIF_VERSION (macos-arm64), built from unmodified source"
  echo "Source: https://github.com/strukturag/libheif/releases/download/v$HEIF_VERSION/libheif-$HEIF_VERSION.tar.gz"
  echo "License: LGPL v3+ (see COPYING.libheif)"
  echo "Statically linked: libde265 $DE265_VERSION, decoder only (LGPL v3+, see COPYING.libde265)"
  echo "Source: https://github.com/strukturag/libde265/releases/download/v$DE265_VERSION/libde265-$DE265_VERSION.tar.gz"
  echo "Statically linked: dav1d $DAV1D_VERSION, AV1 decoder (BSD-2-Clause, see COPYING.dav1d)"
  echo "Source: https://downloads.videolan.org/pub/videolan/dav1d/$DAV1D_VERSION/dav1d-$DAV1D_VERSION.tar.xz"
  echo "Features: shared libheif; built-in HEVC and AV1 decoders; plugins and all encoders/other codecs disabled"
} > "$DEST/BUILD-INFO.txt"

echo "Staged libheif into $DEST"
