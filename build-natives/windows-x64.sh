#!/bin/sh
# Run from an MSYS2 MINGW64 shell to build and stage windows-x64 natives.
set -eu

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
HEIF_VERSION=1.23.1
DE265_VERSION=1.1.1
DAV1D_VERSION=1.5.4
HEIF_SRC="${1:-$ROOT/build/libheif-$HEIF_VERSION}"
DE265_SRC="$ROOT/build/libde265-$DE265_VERSION"
DE265_PREFIX="$ROOT/build/prefix-libde265-windows-x64"
DAV1D_SRC="$ROOT/build/dav1d-$DAV1D_VERSION"
DAV1D_PREFIX="$ROOT/build/prefix-dav1d-windows-x64"
PREFIX="$ROOT/build/prefix-windows-x64"
DEST="$ROOT/natives/src/main/resources/libheif-natives/windows-x64"

mkdir -p "$ROOT/build"
if [ ! -d "$DE265_SRC" ]; then
  curl -sfL "https://github.com/strukturag/libde265/releases/download/v$DE265_VERSION/libde265-$DE265_VERSION.tar.gz" | tar xz -C "$ROOT/build"
fi
if [ ! -d "$DAV1D_SRC" ]; then
  curl -sfL "https://downloads.videolan.org/pub/videolan/dav1d/$DAV1D_VERSION/dav1d-$DAV1D_VERSION.tar.xz" | tar xJ -C "$ROOT/build"
fi
[ -d "$HEIF_SRC" ] || { echo "missing $HEIF_SRC; fetch libheif $HEIF_VERSION first"; exit 1; }

cmake -S "$DE265_SRC" -B "$DE265_SRC/build-windows-x64" -G Ninja \
  -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$DE265_PREFIX" \
  -DCMAKE_INSTALL_LIBDIR=lib -DBUILD_SHARED_LIBS=OFF \
  -DCMAKE_POSITION_INDEPENDENT_CODE=ON -DENABLE_SDL=OFF -DENABLE_DECODER=OFF \
  -DENABLE_ENCODER=OFF -DENABLE_SHERLOCK265=OFF
cmake --build "$DE265_SRC/build-windows-x64" --target install

if [ ! -f "$DAV1D_PREFIX/lib/pkgconfig/dav1d.pc" ]; then
  meson setup "$DAV1D_SRC/build-windows-x64" "$DAV1D_SRC" \
    --prefix="$DAV1D_PREFIX" --libdir=lib --buildtype=release \
    -Ddefault_library=static -Denable_tools=false -Denable_tests=false
  ninja -C "$DAV1D_SRC/build-windows-x64" install
fi

export PKG_CONFIG_PATH="$DE265_PREFIX/lib/pkgconfig:$DAV1D_PREFIX/lib/pkgconfig"
cmake -S "$HEIF_SRC" -B "$HEIF_SRC/build-windows-x64" -G Ninja \
  -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$PREFIX" -DCMAKE_INSTALL_LIBDIR=lib \
  -DCMAKE_PREFIX_PATH="$DE265_PREFIX;$DAV1D_PREFIX" \
  -DCMAKE_CXX_FLAGS=-DLIBDE265_STATIC_BUILD \
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
cmake --build "$HEIF_SRC/build-windows-x64" --target install

rm -rf "$DEST"
mkdir -p "$DEST"
: > "$DEST/manifest.txt"
for runtime in libwinpthread-1.dll libgcc_s_seh-1.dll libstdc++-6.dll; do
  if [ -f "/mingw64/bin/$runtime" ]; then
    cp "/mingw64/bin/$runtime" "$DEST/$runtime"
    echo "$runtime" >> "$DEST/manifest.txt"
  fi
done
heif_dll="$(find "$PREFIX/bin" -maxdepth 1 -iname '*heif*.dll' | head -1)"
[ -n "$heif_dll" ] || { echo "libheif DLL not found under $PREFIX/bin"; exit 1; }
base="$(basename "$heif_dll")"
cp "$heif_dll" "$DEST/$base"
echo "$base" >> "$DEST/manifest.txt"

allowed='libheif|libwinpthread|libgcc_s_seh|libstdc\+\+|KERNEL32|USER32|ADVAPI32|SHELL32|ole32|OLEAUT32|bcrypt|msvcrt|ntdll|api-ms-'
for dll in "$DEST"/*.dll; do
  if objdump -p "$dll" | awk '/DLL Name:/{print $3}' | grep -viE "^($allowed)"; then
    echo "ERROR: $dll imports unexpected DLLs (above)"; exit 1
  fi
done

cp "$HEIF_SRC/COPYING" "$DEST/COPYING.libheif"
cp "$DE265_SRC/COPYING" "$DEST/COPYING.libde265"
cp "$DAV1D_SRC/COPYING" "$DEST/COPYING.dav1d"
{
  echo "libheif $HEIF_VERSION (windows-x64), built from unmodified source with MSYS2 mingw-w64"
  echo "Source: https://github.com/strukturag/libheif/releases/download/v$HEIF_VERSION/libheif-$HEIF_VERSION.tar.gz"
  echo "License: LGPL v3+ (see COPYING.libheif)"
  echo "Statically linked: libde265 $DE265_VERSION, decoder only (LGPL v3+, see COPYING.libde265)"
  echo "Source: https://github.com/strukturag/libde265/releases/download/v$DE265_VERSION/libde265-$DE265_VERSION.tar.gz"
  echo "Statically linked: dav1d $DAV1D_VERSION, AV1 decoder (BSD-2-Clause, see COPYING.dav1d)"
  echo "Source: https://downloads.videolan.org/pub/videolan/dav1d/$DAV1D_VERSION/dav1d-$DAV1D_VERSION.tar.xz"
  echo "Features: shared libheif; built-in HEVC and AV1 decoders; plugins and all encoders/other codecs disabled"
} > "$DEST/BUILD-INFO.txt"

echo "Staged libheif into $DEST"
