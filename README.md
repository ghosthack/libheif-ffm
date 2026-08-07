# libheif-ffm

Panama FFM (jextract) bindings for the **libheif** C API with bundled,
from-source decoding natives. It reads HEIC/HEIF through built-in libde265 and
AVIF through built-in dav1d—no JNI, native plugins, or user-installed codecs.

| Artifact | Contents | License |
|---|---|---|
| `io.github.ghosthack:libheif-ffm` | Generated FFM stubs and native loader (JDK 22+) | MIT |
| `io.github.ghosthack:libheif-ffm-natives` (`macos-arm64`, `windows-x64`, `linux-x64`) | libheif 1.23.1 + static libde265 1.1.1 + static dav1d 1.5.4 | LGPL v3+ / BSD-2-Clause |

The binding surface is decode-oriented: type detection, file and memory input,
top-level image enumeration, primary/thumbnail/auxiliary/depth handles,
metadata and color profiles, RGB/YUV decode, plane access, and scaling. All
encoders and dynamic codec plugins are disabled in the bundled native.

## Use

```xml
<dependency>
  <groupId>io.github.ghosthack</groupId>
  <artifactId>libheif-ffm</artifactId>
  <version>1.23.1-0.1.0-SNAPSHOT</version>
</dependency>
<dependency>
  <groupId>io.github.ghosthack</groupId>
  <artifactId>libheif-ffm-natives</artifactId>
  <version>1.23.1-0.1.0-SNAPSHOT</version>
  <classifier>macos-arm64</classifier> <!-- or windows-x64 / linux-x64 -->
  <scope>runtime</scope>
</dependency>
```

On the module path, declare `requires libheif.ffm;` and run with
`--enable-native-access=libheif.ffm`. On the class path, use
`--enable-native-access=ALL-UNNAMED`.

```java
import io.github.ghosthack.libheifffm.libheif.LibHeif;

int major = LibHeif.heif_get_version_number_major();
boolean heic = LibHeif.heif_have_decoder_for_format(
        LibHeif.heif_compression_HEVC()) != 0;
boolean avif = LibHeif.heif_have_decoder_for_format(
        LibHeif.heif_compression_AV1()) != 0;
```

See `core/src/test/java/.../LibHeifSmokeTest.java` for complete in-memory
HEIC and AVIF decode examples, including `heif_error` handling and RGBA plane
access.

## Library resolution

`LibHeifLibs.lookup()` resolves in this order:

1. `-Dlibheifffm.libdir=<dir>` or `LIBHEIF_FFM_LIBDIR`;
2. the platform classifier jar, extracted once to
   `~/.cache/libheif-ffm/<artifact-version>-<platform>/`;
3. libraries already loaded by the host process.

The override directory should contain a compatible libheif shared library.

## Building

Each native classifier must be built on its target platform. Stub generation
runs once on macOS because this selected public C API uses portable layouts.

```sh
mkdir -p build
curl -sfL https://github.com/strukturag/libheif/releases/download/v1.23.1/libheif-1.23.1.tar.gz | tar xz -C build
build-natives/macos-arm64.sh
jextract/gen-bindings.sh
mvn install
```

The native scripts fetch and statically build libde265 and dav1d. The Windows
script runs from an MSYS2 MINGW64 shell; the Linux script needs CMake, Meson,
Ninja, NASM, pkg-config, patchelf, and a C/C++ toolchain. Staged native files
are build outputs and are not committed.

See [THIRD-PARTY.md](THIRD-PARTY.md) for licensing and replacement details.
