#!/bin/sh
# Generate the decode-oriented libheif FFM surface from the from-source build
# and redirect jextract's symbol lookup to LibHeifLibs.
set -eu

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
JX="${JEXTRACT:-$ROOT/../ffmpeg-ffm/tools/jextract-22/bin/jextract}"
PREFIX="$ROOT/build/prefix-macos-arm64"
OUT="$ROOT/core/src/main/java"
PKG="io.github.ghosthack.libheifffm.libheif"
SDK="$(xcrun --show-sdk-path)"

[ -x "$JX" ] || { echo "jextract not found at $JX (set JEXTRACT=)"; exit 1; }
[ -d "$PREFIX/include/libheif" ] || { echo "run build-natives/macos-arm64.sh first"; exit 1; }

GEN_DIR="$OUT/$(echo "$PKG" | tr . /)"
rm -rf "$GEN_DIR"

"$JX" --output "$OUT" -t "$PKG" \
  --header-class-name LibHeif \
  -I "$SDK/usr/include" \
  -I "$PREFIX/include" \
  -l ":$PREFIX/lib/libheif.dylib" \
  --include-function heif_get_version \
  --include-function heif_get_version_number \
  --include-function heif_get_version_number_major \
  --include-function heif_get_version_number_minor \
  --include-function heif_get_version_number_maintenance \
  --include-function heif_init \
  --include-function heif_deinit \
  --include-function heif_read_main_brand \
  --include-function heif_has_compatible_brand \
  --include-function heif_get_file_mime_type \
  --include-function heif_check_filetype \
  --include-function heif_has_compatible_filetype \
  --include-function heif_context_alloc \
  --include-function heif_context_free \
  --include-function heif_context_read_from_file \
  --include-function heif_context_read_from_memory_without_copy \
  --include-function heif_context_get_number_of_top_level_images \
  --include-function heif_context_is_top_level_image_ID \
  --include-function heif_context_get_list_of_top_level_image_IDs \
  --include-function heif_context_get_primary_image_ID \
  --include-function heif_context_get_primary_image_handle \
  --include-function heif_context_get_image_handle \
  --include-function heif_context_set_max_decoding_threads \
  --include-function heif_context_get_max_decoding_threads \
  --include-function heif_have_decoder_for_format \
  --include-function heif_image_handle_release \
  --include-function heif_image_handle_is_primary_image \
  --include-function heif_image_handle_get_item_id \
  --include-function heif_image_handle_get_width \
  --include-function heif_image_handle_get_height \
  --include-function heif_image_handle_has_alpha_channel \
  --include-function heif_image_handle_is_premultiplied_alpha \
  --include-function heif_image_handle_get_luma_bits_per_pixel \
  --include-function heif_image_handle_get_chroma_bits_per_pixel \
  --include-function heif_image_handle_get_preferred_decoding_colorspace \
  --include-function heif_image_handle_has_depth_image \
  --include-function heif_image_handle_get_number_of_depth_images \
  --include-function heif_image_handle_get_list_of_depth_image_IDs \
  --include-function heif_image_handle_get_depth_image_handle \
  --include-function heif_image_handle_get_number_of_thumbnails \
  --include-function heif_image_handle_get_list_of_thumbnail_IDs \
  --include-function heif_image_handle_get_thumbnail \
  --include-function heif_image_handle_get_number_of_auxiliary_images \
  --include-function heif_image_handle_get_list_of_auxiliary_image_IDs \
  --include-function heif_image_handle_get_auxiliary_type \
  --include-function heif_image_handle_release_auxiliary_type \
  --include-function heif_image_handle_get_auxiliary_image_handle \
  --include-function heif_decode_image \
  --include-function heif_decoding_options_alloc \
  --include-function heif_decoding_options_copy \
  --include-function heif_decoding_options_free \
  --include-function heif_image_release \
  --include-function heif_image_get_colorspace \
  --include-function heif_image_get_chroma_format \
  --include-function heif_image_get_width \
  --include-function heif_image_get_height \
  --include-function heif_image_get_primary_width \
  --include-function heif_image_get_primary_height \
  --include-function heif_image_get_plane_readonly \
  --include-function heif_image_get_bits_per_pixel \
  --include-function heif_image_get_bits_per_pixel_range \
  --include-function heif_image_scale_image \
  --include-function heif_image_handle_get_number_of_metadata_blocks \
  --include-function heif_image_handle_get_list_of_metadata_block_IDs \
  --include-function heif_image_handle_get_metadata_type \
  --include-function heif_image_handle_get_metadata_content_type \
  --include-function heif_image_handle_get_metadata_size \
  --include-function heif_image_handle_get_metadata \
  --include-function heif_image_handle_get_color_profile_type \
  --include-function heif_image_handle_get_raw_color_profile_size \
  --include-function heif_image_handle_get_raw_color_profile \
  --include-function heif_image_handle_get_nclx_color_profile \
  --include-function heif_nclx_color_profile_alloc \
  --include-function heif_nclx_color_profile_free \
  --include-struct heif_error \
  --include-struct heif_init_params \
  --include-struct heif_decoding_options \
  --include-struct heif_color_conversion_options \
  --include-struct heif_color_conversion_options_ext \
  --include-struct heif_color_profile_nclx \
  --include-typedef heif_error \
  --include-typedef heif_init_params \
  --include-typedef heif_decoding_options \
  --include-typedef heif_color_conversion_options \
  --include-typedef heif_color_conversion_options_ext \
  --include-typedef heif_color_profile_nclx \
  --include-typedef heif_item_id \
  --include-typedef heif_brand2 \
  --include-typedef heif_error_code \
  --include-typedef heif_suberror_code \
  --include-typedef heif_compression_format \
  --include-typedef heif_filetype_result \
  --include-typedef heif_colorspace \
  --include-typedef heif_chroma \
  --include-typedef heif_channel \
  --include-typedef heif_color_profile_type \
  --include-constant LIBHEIF_NUMERIC_VERSION \
  --include-constant heif_error_Ok \
  --include-constant heif_error_Invalid_input \
  --include-constant heif_error_Unsupported_filetype \
  --include-constant heif_error_Unsupported_feature \
  --include-constant heif_error_Usage_error \
  --include-constant heif_error_Memory_allocation_error \
  --include-constant heif_error_Decoder_plugin_error \
  --include-constant heif_error_Color_profile_does_not_exist \
  --include-constant heif_suberror_No_matching_decoder_installed \
  --include-constant heif_compression_undefined \
  --include-constant heif_compression_HEVC \
  --include-constant heif_compression_AV1 \
  --include-constant heif_filetype_no \
  --include-constant heif_filetype_yes_supported \
  --include-constant heif_filetype_yes_unsupported \
  --include-constant heif_filetype_maybe \
  --include-constant heif_brand2_heic \
  --include-constant heif_brand2_heix \
  --include-constant heif_brand2_mif1 \
  --include-constant heif_brand2_avif \
  --include-constant heif_colorspace_undefined \
  --include-constant heif_colorspace_YCbCr \
  --include-constant heif_colorspace_RGB \
  --include-constant heif_colorspace_monochrome \
  --include-constant heif_chroma_undefined \
  --include-constant heif_chroma_planar \
  --include-constant heif_chroma_420 \
  --include-constant heif_chroma_422 \
  --include-constant heif_chroma_444 \
  --include-constant heif_chroma_interleaved_RGB \
  --include-constant heif_chroma_interleaved_RGBA \
  --include-constant heif_chroma_interleaved_RRGGBB_BE \
  --include-constant heif_chroma_interleaved_RRGGBBAA_BE \
  --include-constant heif_chroma_interleaved_RRGGBB_LE \
  --include-constant heif_chroma_interleaved_RRGGBBAA_LE \
  --include-constant heif_channel_Y \
  --include-constant heif_channel_Cb \
  --include-constant heif_channel_Cr \
  --include-constant heif_channel_R \
  --include-constant heif_channel_G \
  --include-constant heif_channel_B \
  --include-constant heif_channel_Alpha \
  --include-constant heif_channel_interleaved \
  --include-constant heif_color_profile_type_not_present \
  --include-constant heif_color_profile_type_nclx \
  --include-constant heif_color_profile_type_rICC \
  --include-constant heif_color_profile_type_prof \
  --include-constant LIBHEIF_AUX_IMAGE_FILTER_OMIT_ALPHA \
  --include-constant LIBHEIF_AUX_IMAGE_FILTER_OMIT_DEPTH \
  "$ROOT/jextract/libheif_api.h"

perl -0777 -pi -e \
  's/static final SymbolLookup SYMBOL_LOOKUP = .*?;/static final SymbolLookup SYMBOL_LOOKUP = io.github.ghosthack.libheifffm.LibHeifLibs.lookup();/s' \
  "$GEN_DIR/LibHeif.java"

# jextract 22 writes an extra blank line after the final closing brace. Keep
# regenerated sources clean and deterministic for Git's whitespace checks.
for java_file in "$GEN_DIR"/*.java; do
  perl -0777 -pi -e 's/\n+\z/\n/' "$java_file"
done

if grep -rn "$PREFIX" "$GEN_DIR" >/dev/null; then
  echo "ERROR: build-prefix paths survived in generated stubs"; exit 1
fi
grep -q "LibHeifLibs.lookup()" "$GEN_DIR/LibHeif.java" || { echo "ERROR: lookup patch did not apply"; exit 1; }

echo "Generated $(find "$GEN_DIR" -type f | wc -l | tr -d ' ') files into $GEN_DIR"
