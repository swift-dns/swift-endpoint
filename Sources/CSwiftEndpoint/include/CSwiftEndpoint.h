#ifndef CSWIFT_DNS_ENDPOINT_H
#define CSWIFT_DNS_ENDPOINT_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

// The IPv6 segment-write table is indexed by a mask, and describes how the
// address is laid out when serialized.
// The mask is 8-bits, each bit representing whether the corresponding IPv6
// segment is all-zero (1) or not (0).
//
//   - Bits 0-39: 8 segment-infos, 5 bits each. Bits 0-2 of a segment-info are
//   the segment index, bits 3-4 are how many colons precede that segment.
//   - Bits 40-43: segments count.
//   - Bits 44-49: min reserve bytes.
//   - Bit 50: whether to write the compression sign at the end.
//
// The entries are unpacked by `IPv6Address.SegmentWriteTableEntry` in `String+IPv6Address.swift`.

extern const uint64_t cswift_endpoint_ipv6_segment_write_table[256];

// Returns the packed segment-write entry for the given all-zero-segments mask.
static inline uint64_t cswift_endpoint_ipv6_segment_write_entry(uint8_t mask) {
    return cswift_endpoint_ipv6_segment_write_table[mask];
}

// The hexadecimal-digit table is indexed by an ASCII byte and maps `0-9`, `a-f` and `A-F` to
// their 0-15 numeric value. Every other byte maps to 0xF0.

extern const uint8_t cswift_endpoint_hexadecimal_digit_table[256];

// Returns the 0-15 value of the given hexadecimal ASCII digit, or 0xF0 if it isn't one.
static inline uint8_t cswift_endpoint_hexadecimal_digit(uint8_t ascii_byte) {
    return cswift_endpoint_hexadecimal_digit_table[ascii_byte];
}

// The decimal-digits table is indexed by a byte and describes how to print it
// in base 10:
//
//   - Bytes 0, 1, 2: the ASCII digits, most significant first, zero-padded on
//   the right.
//   - Byte 3: how many of the above digits are significant, 1 to 3.
//
// So 7 is `{'7', 0, 0, 1}` and 255 is `{'2', '5', '5', 3}`.
// This enables speculative writes, where you write all 3 bytes and only advance an index
// by the number of significant bytes, to leave the insignificant bytes to be overwritten.

extern const uint32_t cswift_endpoint_decimal_digits_table[256];

// Returns the packed decimal-digits entry for the given byte.
static inline uint32_t cswift_endpoint_decimal_digits(uint8_t byte) {
    return cswift_endpoint_decimal_digits_table[byte];
}

#ifdef __cplusplus
} // extern "C"
#endif

#endif // CSWIFT_DNS_ENDPOINT_H
