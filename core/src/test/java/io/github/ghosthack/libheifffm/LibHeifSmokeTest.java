package io.github.ghosthack.libheifffm;

import io.github.ghosthack.libheifffm.libheif.LibHeif;
import io.github.ghosthack.libheifffm.libheif.heif_error;
import org.junit.jupiter.api.Test;

import java.lang.foreign.Arena;
import java.lang.foreign.MemorySegment;
import java.lang.foreign.ValueLayout;
import java.util.Base64;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

/** End-to-end proof that the bundled libde265 and dav1d backends both decode. */
class LibHeifSmokeTest {
    private static final byte[] HEIC = Base64.getDecoder().decode(
            "AAAAHGZ0eXBoZWljAAAAAG1pZjFoZWljbWlhZgAAAXttZXRhAAAAAAAAACFoZGxyAAAAAAAAAABwaWN0" +
            "AAAAAAAAAAAAAAAAAAAAACJpbG9jAAAAAERAAAEAAQAAAAABnwABAAAAAAAAAGwAAAAjaWluZgAAAAAA" +
            "AQAAABVpbmZlAgAAAAABAABodmMxAAAAAA5waXRtAAAAAAABAAAA+2lwcnAAAADbaXBjbwAAAHZodmND" +
            "AQNwAAAAAAAAAAAAHvAA/P34+AAADwNgAAEAGEABDAH//wNwAAADAJAAAAMAAAMAHroCQGEAAQAqQgEB" +
            "A3AAAAMAkAAAAwAAAwAeoCCBBZbq5Ka5uAhoMCAAAAMDIAAAAwAhYgABAAZEAcFzwIkAAAATY29scm5j" +
            "bHgAAQANAAaAAAAAFGlzcGUAAAAAAAAAQAAAAEAAAAAoY2xhcAAAACAAAAABAAAAIAAAAAH////gAAAAAv" +
            "///+AAAAACAAAADnBpeGkAAAAAAQgAAAAYaXBtYQAAAAAAAAABAAEFgQIDBYQAAAB0bWRhdAAAAGgoAa8T" +
            "gPUrAhGDczL1mz4HCRRzxqbGjnnUrr1cLTO799zRz6nw0QjRMp+4I2Da10D3ghQEMvB53CWoI0S3qXIb" +
            "99YsvLFaQ9ZLHxsJsZ9SxlvNJ5EgD4Y4miuaKu3bxPGXDHirp/9TzA==");

    private static final byte[] AVIF = Base64.getDecoder().decode(
            "AAAAHGZ0eXBhdmlmAAAAAG1pZjFhdmlmbWlhZgAAAOhtZXRhAAAAAAAAACFoZGxyAAAAAAAAAABwaWN0" +
            "AAAAAAAAAAAAAAAAAAAAACJpbG9jAAAAAERAAAEAAQAAAAABDAABAAAAAAAAAEYAAAAjaWluZgAAAAAA" +
            "AQAAABVpbmZlAgAAAAABAABhdjAxAAAAAA5waXRtAAAAAAABAAAAaGlwcnAAAABJaXBjbwAAAAxhdjFD" +
            "gQAMAAAAABNjb2xybmNseAABAA0ABoAAAAAUaXNwZQAAAAAAAAAgAAAAIAAAAA5waXhpAAAAAAEIAAAA" +
            "F2lwbWEAAAAAAAAAAQABBIECAwQAAABObWRhdBIACgkYET/2CAhoNCAyNxgACiiihAAzOuPjZZhvQSuy" +
            "HFo9THbLHhYdqz2Fv/R54HkFZ6ztRPI/rUVEGNN7hhOEXuijGoA=");

    @Test
    void reportsExpectedVersionAndBuiltInDecoders() {
        assertEquals(1, LibHeif.heif_get_version_number_major());
        assertEquals(23, LibHeif.heif_get_version_number_minor());
        assertEquals(1, LibHeif.heif_get_version_number_maintenance());
        assertNotEquals(0, LibHeif.heif_have_decoder_for_format(LibHeif.heif_compression_HEVC()));
        assertNotEquals(0, LibHeif.heif_have_decoder_for_format(LibHeif.heif_compression_AV1()));
    }

    @Test
    void detectsAndDecodesHeicThroughLibde265() {
        decode(HEIC, "image/heic", true);
    }

    @Test
    void detectsAndDecodesAvifThroughDav1d() {
        decode(AVIF, "image/avif", false);
    }

    private static void decode(byte[] encoded, String expectedMime, boolean exerciseScale) {
        try (Arena arena = Arena.ofConfined()) {
            check(LibHeif.heif_init(arena, MemorySegment.NULL));
            try {
                MemorySegment input = arena.allocate(encoded.length);
                MemorySegment.copy(encoded, 0, input, ValueLayout.JAVA_BYTE, 0, encoded.length);
                assertEquals(LibHeif.heif_filetype_yes_supported(),
                        LibHeif.heif_check_filetype(input, encoded.length));
                assertEquals(expectedMime,
                        LibHeif.heif_get_file_mime_type(input, encoded.length).reinterpret(32).getString(0));

                MemorySegment context = LibHeif.heif_context_alloc();
                assertNotEquals(MemorySegment.NULL, context);
                try {
                    check(LibHeif.heif_context_read_from_memory_without_copy(
                            arena, context, input, encoded.length, MemorySegment.NULL));
                    assertEquals(1, LibHeif.heif_context_get_number_of_top_level_images(context));

                    MemorySegment handleOut = arena.allocate(ValueLayout.ADDRESS);
                    check(LibHeif.heif_context_get_primary_image_handle(arena, context, handleOut));
                    MemorySegment handle = handleOut.get(ValueLayout.ADDRESS, 0);
                    try {
                        assertEquals(32, LibHeif.heif_image_handle_get_width(handle));
                        assertEquals(32, LibHeif.heif_image_handle_get_height(handle));
                        assertEquals(1, LibHeif.heif_image_handle_is_primary_image(handle));

                        MemorySegment imageOut = arena.allocate(ValueLayout.ADDRESS);
                        check(LibHeif.heif_decode_image(arena, handle, imageOut,
                                LibHeif.heif_colorspace_RGB(), LibHeif.heif_chroma_interleaved_RGBA(),
                                MemorySegment.NULL));
                        MemorySegment image = imageOut.get(ValueLayout.ADDRESS, 0);
                        try {
                            assertEquals(32, LibHeif.heif_image_get_primary_width(image));
                            assertEquals(32, LibHeif.heif_image_get_primary_height(image));
                            assertEquals(LibHeif.heif_colorspace_RGB(), LibHeif.heif_image_get_colorspace(image));

                            MemorySegment strideOut = arena.allocate(ValueLayout.JAVA_INT);
                            MemorySegment pixels = LibHeif.heif_image_get_plane_readonly(
                                    image, LibHeif.heif_channel_interleaved(), strideOut);
                            int stride = strideOut.get(ValueLayout.JAVA_INT, 0);
                            assertTrue(stride >= 32 * 4, "RGBA stride: " + stride);
                            pixels = pixels.reinterpret((long) stride * 32);
                            boolean hasContent = false;
                            for (long i = 0; i < pixels.byteSize() && !hasContent; i++) {
                                hasContent = pixels.get(ValueLayout.JAVA_BYTE, i) != 0;
                            }
                            assertTrue(hasContent, "decoded pixels contain image data");

                            if (exerciseScale) {
                                MemorySegment scaledOut = arena.allocate(ValueLayout.ADDRESS);
                                check(LibHeif.heif_image_scale_image(
                                        arena, image, scaledOut, 16, 16, MemorySegment.NULL));
                                MemorySegment scaled = scaledOut.get(ValueLayout.ADDRESS, 0);
                                try {
                                    assertEquals(16, LibHeif.heif_image_get_primary_width(scaled));
                                    assertEquals(16, LibHeif.heif_image_get_primary_height(scaled));
                                } finally {
                                    LibHeif.heif_image_release(scaled);
                                }
                            }
                        } finally {
                            LibHeif.heif_image_release(image);
                        }
                    } finally {
                        LibHeif.heif_image_handle_release(handle);
                    }
                } finally {
                    LibHeif.heif_context_free(context);
                }
            } finally {
                LibHeif.heif_deinit();
            }
        }
    }

    private static void check(MemorySegment error) {
        int code = heif_error.code(error);
        if (code != LibHeif.heif_error_Ok()) {
            MemorySegment message = heif_error.message(error);
            String text = message.equals(MemorySegment.NULL) ? "unknown libheif error"
                    : message.reinterpret(1024).getString(0);
            throw new AssertionError(text + " (code=" + code + ", subcode=" + heif_error.subcode(error) + ")");
        }
    }
}
