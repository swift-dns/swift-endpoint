#ifndef CSWIFT_DNS_ENDPOINT_H
#define CSWIFT_DNS_ENDPOINT_H

#include <stdint.h>
#include <string.h>

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

// Returned by `cswift_endpoint_parse_ipv4_dotted_decimal` when the input is not a valid
// dotted-decimal IPv4 address. Any other return value is the address, packed big-endian-first
// into the low 32 bits.
#define CSWIFT_ENDPOINT_IPV4_PARSE_FAILURE UINT64_C(0xFFFFFFFFFFFFFFFF)

#if defined(__ARM_NEON) || defined(__ARM_NEON__)

#include <arm_neon.h>

// `vld1q_lane_u32` takes a `uint32_t *`, but the input is a byte string with no alignment
// guarantee; ARM's lane loads handle that natively.
typedef uint32_t cswift_endpoint_unaligned_uint32 __attribute__((aligned(1)));

// Branch-free dotted-decimal IPv4 parse, ported from ada-url/ada#1232
// (`parse_ipv4_avx512vl_notab5`).
//
// `vpcompressb` has no NEON form, so the delimiter positions come from a scalar dot bit set
// rather than a compress. The rest is the original kernel: each group's digit window is
// materialised by a table lookup whose index is clamped to the dot that starts the group, so a
// short group pads with zeros instead of reading its predecessor's digits; the "> 255" test is an
// unsigned dword compare on that reversed zero-padded window, running alongside the convert; and
// the four octets are packed by a byte select plus a byte swap.
//
// `len` must be 7...15. Accepts exactly what the portable parser accepts: four groups of one to
// three digits, leading zeros allowed, no trailing dot.
__attribute__((always_inline)) static inline uint64_t
cswift_endpoint_parse_ipv4_dotted_decimal(const uint8_t *data, int len) {
    // The source is only `len` bytes long, so the 16-byte vector cannot be loaded directly.
    // Staging it through a stack buffer costs more than the whole kernel: a 16-byte load on top
    // of narrower overlapping stores cannot forward, and every call reuses the same stack slot,
    // so the stall serialises consecutive parses. Instead, four 32-bit lane loads pull the input
    // straight into one register as four chunks, and the table lookup that the kernel already
    // performs is re-indexed to put each source byte back where it belongs.
    //
    // The chunks cover source [0, 4), [o1, o1 + 4), [o2, o2 + 4) and [len - 4, len). For any
    // length in 7...15 those four ranges cover the whole input, and none of them reads past it.
    const int o1 = (len - 4) < 4 ? (len - 4) : 4;
    const int o2 = (len - 8) > 0 ? (len - 8) : 0;
    uint32x4_t loaded = vld1q_lane_u32((const cswift_endpoint_unaligned_uint32 *)data,
                                       vdupq_n_u32(0), 0);
    loaded = vld1q_lane_u32((const cswift_endpoint_unaligned_uint32 *)(data + o1), loaded, 1);
    loaded = vld1q_lane_u32((const cswift_endpoint_unaligned_uint32 *)(data + o2), loaded, 2);
    loaded = vld1q_lane_u32((const cswift_endpoint_unaligned_uint32 *)(data + len - 4), loaded, 3);
    const uint8x16_t chunks = vreinterpretq_u8_u32(loaded);

    // Source byte i lives at chunk lane i, i + (4 - o1) or i + (16 - len) depending on which
    // chunk holds it. Lanes at or past `len` index out of range and read as zero, which is
    // neither a digit nor a dot, so no padding byte is needed.
    const uint8x16_t iota_base =
        {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15};
    const uint8x16_t middle_chunk = {0, 0, 0, 0, 255, 255, 255, 255, 0, 0, 0, 0, 0, 0, 0, 0};
    const uint8x16_t upper_chunks = {0,   0,   0,   0,   0,   0,   0,   0,
                                     255, 255, 255, 255, 255, 255, 255, 255};
    const uint8x16_t gather = vaddq_u8(
        iota_base,
        vaddq_u8(vandq_u8(middle_chunk, vdupq_n_u8((uint8_t)(4 - o1))),
                 vandq_u8(upper_chunks, vdupq_n_u8((uint8_t)(16 - len)))));
    const uint8x16_t v = vqtbl1q_u8(chunks, gather);

    const uint8x16_t live = vcltq_u8(iota_base, vdupq_n_u8((uint8_t)len));

    const uint8x16_t digits = vsubq_u8(v, vdupq_n_u8('0'));
    const uint8x16_t is_digit = vcleq_u8(digits, vdupq_n_u8(9));
    const uint8x16_t is_dot = vceqq_u8(v, vdupq_n_u8('.'));
    // Also drops lanes at or past `len`, which may alias a chunk that overshoots the input.
    const uint8x16_t digit_values = vandq_u8(vandq_u8(digits, is_digit), live);

    // A byte inside the input that is neither a digit nor a dot.
    const uint8x16_t hole = vandq_u8(vmvnq_u8(vorrq_u8(is_digit, is_dot)), live);

    const uint8x16_t bit_weights = {1, 2, 4, 8, 16, 32, 64, 128, 1, 2, 4, 8, 16, 32, 64, 128};
    const uint8x16_t dot_bits = vandq_u8(vandq_u8(is_dot, live), bit_weights);
    const uint32_t dots = (uint32_t)vaddv_u8(vget_low_u8(dot_bits))
                          | ((uint32_t)vaddv_u8(vget_high_u8(dot_bits)) << 8);

    // Clearing the lowest set bit three times yields the three dot positions, and says whether
    // there were exactly three dots without needing a population count.
    const uint32_t rest1 = dots & (dots - 1);
    const uint32_t rest2 = rest1 & (rest1 - 1);
    const uint32_t rest3 = rest2 & (rest2 - 1);
    const int dot0 = __builtin_ctz(dots | 0x10000u) & 15;
    const int dot1 = __builtin_ctz(rest1 | 0x10000u) & 15;
    const int dot2 = __builtin_ctz(rest2 | 0x10000u) & 15;

    const uint32_t ends = (uint32_t)dot0 | ((uint32_t)dot1 << 8) | ((uint32_t)dot2 << 16)
                          | ((uint32_t)len << 24);
    const uint32_t starts = 0xFFu | ((uint32_t)dot0 << 8) | ((uint32_t)dot1 << 16)
                            | ((uint32_t)dot2 << 24);
    const uint8x16_t group_of_lane = {0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3};
    const int8x16_t back_offsets = {-1, -2, -3, -4, -1, -2, -3, -4,
                                    -1, -2, -3, -4, -1, -2, -3, -4};
    const int8x16_t end_of_lane = vreinterpretq_s8_u8(
        vqtbl1q_u8(vreinterpretq_u8_u32(vdupq_n_u32(ends)), group_of_lane));
    const int8x16_t start_of_lane = vreinterpretq_s8_u8(
        vqtbl1q_u8(vreinterpretq_u8_u32(vdupq_n_u32(starts)), group_of_lane));
    const int8x16_t index = vmaxq_s8(vaddq_s8(end_of_lane, back_offsets), start_of_lane);
    const uint8x16_t window = vqtbl1q_u8(digit_values, vreinterpretq_u8_s8(index));

    // Each dword holds ones | tens << 8 | hundreds << 16, which is monotone in the decimal value,
    // so "> 255" is one unsigned compare against (2, 5, 5).
    const uint32x4_t over =
        vcgtq_u32(vreinterpretq_u32_u8(window), vdupq_n_u32(0x00020505u));

    const uint8x16_t weights = {1, 10, 100, 0, 1, 10, 100, 0, 1, 10, 100, 0, 1, 10, 100, 0};
#if defined(__ARM_FEATURE_DOTPROD)
    const uint32x4_t values = vdotq_u32(vdupq_n_u32(0), window, weights);
#else
    const uint16x8_t low = vmull_u8(vget_low_u8(window), vget_low_u8(weights));
    const uint16x8_t high = vmull_u8(vget_high_u8(window), vget_high_u8(weights));
    const uint32x4_t values = vpaddq_u32(vpaddlq_u16(low), vpaddlq_u16(high));
#endif

    const uint8x16_t low_byte_of_dword = {0, 4, 8, 12, 0, 4, 8, 12, 0, 4, 8, 12, 0, 4, 8, 12};
    const uint32_t packed = vgetq_lane_u32(
        vreinterpretq_u32_u8(vqtbl1q_u8(vreinterpretq_u8_u32(values), low_byte_of_dword)), 0);

    const int length0 = dot0;
    const int length1 = dot1 - dot0 - 1;
    const int length2 = dot2 - dot1 - 1;
    const int length3 = len - dot2 - 1;

    // Both vector rejections fold into one horizontal reduction; each reduction costs a move
    // out of the vector unit, and those moves sit on the critical path.
    const uint8x16_t rejected = vorrq_u8(hole, vreinterpretq_u8_u32(over));
    const int valid = (vmaxvq_u8(rejected) == 0) & (rest2 != 0) & (rest3 == 0)
                      & ((unsigned)(length0 - 1) < 3u) & ((unsigned)(length1 - 1) < 3u)
                      & ((unsigned)(length2 - 1) < 3u) & ((unsigned)(length3 - 1) < 3u);

    return valid ? (uint64_t)__builtin_bswap32(packed) : CSWIFT_ENDPOINT_IPV4_PARSE_FAILURE;
}

#endif  // __ARM_NEON

#ifdef __cplusplus
} // extern "C"
#endif

#endif // CSWIFT_DNS_ENDPOINT_H
