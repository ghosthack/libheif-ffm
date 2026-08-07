# Third-party notices

## libheif

The `libheif-ffm-natives` classifier jars contain a shared library built from
unmodified [libheif](https://github.com/strukturag/libheif) 1.23.1 source,
licensed under the GNU Lesser General Public License v3 or later.

- The exact build and source URL are recorded in each jar's `BUILD-INFO.txt`.
- `COPYING.libheif` is included in every native classifier jar.
- The build has no encoder, plugin-loading, or dynamically loaded codec modules.
- Users may replace the bundled library with a compatible build through
  `LIBHEIF_FFM_LIBDIR` or `-Dlibheifffm.libdir`, preserving the LGPL relinking path.

## libde265

libheif statically links unmodified
[libde265](https://github.com/strukturag/libde265) 1.1.1 for HEVC/HEIC
decoding. libde265 is licensed under the GNU Lesser General Public License v3
or later; `COPYING.libde265` ships in each native jar.

## dav1d

libheif statically links unmodified
[dav1d](https://code.videolan.org/videolan/dav1d) 1.5.4 for AV1/AVIF
decoding. dav1d is BSD-2-Clause; `COPYING.dav1d` ships in each native jar.

The Java binding and loader code is MIT licensed; it contains no source from
libheif, libde265, or dav1d.
