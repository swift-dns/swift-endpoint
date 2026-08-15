#ifndef CSWIFT_DNS_ENDPOINT_H
#define CSWIFT_DNS_ENDPOINT_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

// The IPv6 segment-write table is indexed by the 8-bit mask of which of the 8 segments of an
// IPv6 address are all-zero, and describes how the address is laid out when serialized.
//
// The top 14 bits of an entry are unused. The rest is the packed layout description:
//
//   - Bits 0-23: 8 segment indices, 3 bits each.
//   - Bits 24-31: segments count.
//   - Bits 32-39: min raw layout bytes.
//   - Bits 40-47: index at which to write the compression sign.
//   - Bit 48: whether to write the compression sign at the beginning.
//   - Bit 49: whether to write the compression sign at the end.
//
// The entries are unpacked by `IPv6Address.SegmentWriteTableEntry` in
// Sources/IPAddress/IPv6Address/String+IPv6Address.swift, and are exhaustively verified
// against an independently derived layout by the IPv6 address tests.

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

#ifdef __cplusplus
} // extern "C"
#endif

#endif // CSWIFT_DNS_ENDPOINT_H
