#ifndef CSWIFT_DNS_ENDPOINT_IPV6_SEGMENT_WRITE_TABLE_H
#define CSWIFT_DNS_ENDPOINT_IPV6_SEGMENT_WRITE_TABLE_H

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

extern const uint8_t cswift_endpoint_ipv6_segment_write_index[256];
extern const uint64_t cswift_endpoint_ipv6_segment_write_values[29];

// Returns the packed segment-write entry for the given all-zero-segments mask.
static inline uint64_t cswift_endpoint_ipv6_segment_write_entry(uint8_t mask) {
    return cswift_endpoint_ipv6_segment_write_values[cswift_endpoint_ipv6_segment_write_index[mask]];
}

#ifdef __cplusplus
} // extern "C"
#endif

#endif // CSWIFT_DNS_ENDPOINT_IPV6_SEGMENT_WRITE_TABLE_H
