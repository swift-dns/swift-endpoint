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
//   - Bits 0-23: 8 segment indices, 3 bits each.
//   - Bits 24-31: segments count.
//   - Bits 32-39: min raw layout bytes.
//   - Bits 40-47: index at which to write the compression sign.
//   - Bit 48: whether to write the compression sign at the beginning.
//   - Bit 49: whether to write the compression sign at the end.
//
// The entries are unpacked by `IPv6Address.SegmentWriteTableEntry` in `String+IPv6Address.swift`.

extern const uint64_t cswift_endpoint_ipv6_segment_write_table[256];

// Returns the packed segment-write entry for the given all-zero-segments mask.
static inline uint64_t cswift_endpoint_ipv6_segment_write_entry(uint8_t mask) {
    return cswift_endpoint_ipv6_segment_write_table[mask];
}

// The hexadecimal-digit table is indexed by an ASCII byte and maps `0-9`, `a-f` and `A-F` to
// their 0-15 numeric value. Every other byte maps to 0xFF.

extern const uint8_t cswift_endpoint_hexadecimal_digit_table[256];

// Returns the 0-15 value of the given hexadecimal ASCII digit, or 0xFF if it isn't one.
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
