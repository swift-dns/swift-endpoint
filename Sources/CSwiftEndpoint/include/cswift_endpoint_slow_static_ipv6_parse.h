#ifndef CSWIFT_DNS_ENDPOINT_SLOW_STATIC_IPV6_PARSE_H
#define CSWIFT_DNS_ENDPOINT_SLOW_STATIC_IPV6_PARSE_H

#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#include "cswift_endpoint_hexadecimal_digit_table.h"

#ifdef __cplusplus
extern "C" {
#endif

// A second, slower IPv6 parser, used only by `IPv6Address(stringLiteral:)`, so a
// literal address folds to a constant. The Swift `parseIPv6` cannot do that: its byte loop is
// never unrolled.
//
// It is the same algorithm as `parseIPv6`, reshaped so LLVM will fully unroll it. Two properties
// are required and neither is sufficient alone:
//
//   1. The loop must be single-exit. Errors set `failed` and `continue` rather than returning, so
//      the loop condition is the only way out. This is sound because every in-loop error path
//      fires while `r` is still `{0, 0, false}`.
//   2. The trip count must be a constant. Hence `k < 45` plus the `n > 45` rejection above the
//      loop, without which an over-long input would stop early and fall into the post-loop logic
//      instead of being rejected.
//
// With both in place `#pragma clang loop unroll(full)` clears the unroller's cost model, and no
// compiler flags are needed. Writing the loop out by hand instead folds identically at `-O2` but
// costs 26430 instructions and a 4592-byte frame per call site at `-O0`, against 1320 and 864.
//
// It is in C because Swift honours `@inline(always)` at `-Onone` too, which costs 74512 bytes of
// stack per call site; clang's `always_inline` costs far less.

typedef struct {
    uint64_t hi;
    uint64_t lo;
    bool ok;
} cswift_endpoint_slow_static_ipv6_parse_result;

// A duplicate of the Swift `IPv4Address._parseSegment`.
__attribute__((always_inline))
static inline bool cswift_endpoint_slow_static_parse_ipv4_segment(
    const uint8_t *s,
    size_t count,
    size_t *idx,
    uint32_t *out
) {
    size_t i = *idx;

    if (i >= count) return false;
    uint8_t d1 = (uint8_t)(s[i] - (uint8_t)'0');
    if (d1 > 9) return false;
    uint32_t segment = d1;
    i += 1;

    uint8_t d2 = i < count ? (uint8_t)(s[i] - (uint8_t)'0') : 0xFF;
    if (d2 <= 9) {
        segment = segment * 10 + d2;
        i += 1;

        uint8_t d3 = i < count ? (uint8_t)(s[i] - (uint8_t)'0') : 0xFF;
        if (d3 <= 9) {
            segment = segment * 10 + d3;
            i += 1;

            if (segment > 255) return false;
        }
    }

    *idx = i;
    *out = segment;
    return true;
}

// A duplicate of the Swift `IPv4Address.parseIPv4`.
__attribute__((always_inline))
static inline bool cswift_endpoint_slow_static_parse_embedded_ipv4(
    const uint8_t *s,
    size_t count,
    uint32_t *out
) {
    // The shortest possible IPv4 address is "0.0.0.0" with 7 bytes, and the longest possible
    // one is "255.255.255.255" with 15 bytes.
    if (count < 7 || count > 15) return false;

    size_t idx = 0;
    uint32_t s1, s2, s3, s4;

    if (!cswift_endpoint_slow_static_parse_ipv4_segment(s, count, &idx, &s1)) return false;
    if (idx >= count || s[idx] != (uint8_t)'.') return false;
    idx += 1;

    if (!cswift_endpoint_slow_static_parse_ipv4_segment(s, count, &idx, &s2)) return false;
    if (idx >= count || s[idx] != (uint8_t)'.') return false;
    idx += 1;

    if (!cswift_endpoint_slow_static_parse_ipv4_segment(s, count, &idx, &s3)) return false;
    if (idx >= count || s[idx] != (uint8_t)'.') return false;
    idx += 1;

    if (!cswift_endpoint_slow_static_parse_ipv4_segment(s, count, &idx, &s4)) return false;
    if (idx != count) return false;

    *out = (s1 << 24) | (s2 << 16) | (s3 << 8) | s4;
    return true;
}

// | byte == ':' | adjacent == ':' | returns |                meaning               |
// +-------------+-----------------+---------+--------------------------------------+
// |    false    |      false      |  false  | not a colon; e.g. "2001:db8::1"      |
// |    false    |      true       |  false  | not a colon; e.g. "a::b"             |
// |    true     |      false      |  true   | lone colon; e.g. ":a::b", or "a::b:" |
// |    true     |      true       |  false  | a "::" compression sign; e.g. "::1"  |
// +-------------+-----------------+---------+--------------------------------------+
__attribute__((always_inline))
static inline bool cswift_endpoint_slow_static_is_lone_colon(uint8_t byte, uint8_t adjacent) {
    return byte == (uint8_t)':' && adjacent != (uint8_t)':';
}

__attribute__((always_inline))
static inline cswift_endpoint_slow_static_ipv6_parse_result cswift_endpoint_slow_static_parse_ipv6(
    const uint8_t *s,
    size_t n
) {
    cswift_endpoint_slow_static_ipv6_parse_result r = {0, 0, false};

    // 2 == "::".count
    if (n < 2) return r;

    // Trim the left and right square brackets if they both exist
    bool startsWithBracket = s[0] == (uint8_t)'[';
    bool endsWithBracket = s[n - 1] == (uint8_t)']';
    if (startsWithBracket != endsWithBracket) return r;
    if (startsWithBracket) {
        s += 1;
        n -= 2;
    }

    // 2 == "::".count
    if (n < 2) return r;

    // The longest valid trimmed form is 45 bytes:
    // "0000:0000:0000:0000:0000:ffff:255.255.255.255".
    if (n > 45) return r;

    size_t count = n;
    // cs == compression sign
    __uint128_t beforeCs = 0;
    __uint128_t afterCs = 0;
    size_t segmentsCount = 0;
    size_t segmentsCountBeforeCs = 0;
    uint16_t currentSegmentValue = 0;
    size_t segmentDigitIdx = 0;
    size_t idx = 0;

    bool startsWithColon = s[0] == (uint8_t)':';
    // For when there is a lone colon at the start
    if (cswift_endpoint_slow_static_is_lone_colon(s[0], s[1])) return r;
    // And for when there is a compression sign at the end
    if (cswift_endpoint_slow_static_is_lone_colon(s[count - 1], s[count - 2])) return r;

    // This `1` is technically not correct.
    // We use 1 because we use 0 to indicate no before-cs segments.
    segmentsCountBeforeCs = startsWithColon ? 1 : segmentsCountBeforeCs;
    idx = startsWithColon ? 2 : idx;
    size_t csCount = startsWithColon ? 1 : 0;

    bool failed = false;
    bool done = false;
    #pragma clang loop unroll(full)
    for (size_t k = 0; k < 45; k++) {
        if (failed || done || idx >= count) continue;

        uint8_t byte = s[idx];
        idx += 1;

        uint8_t digit = cswift_endpoint_hexadecimal_digit_table[byte];
        if (digit != 0xFF) {
            if (segmentDigitIdx == 4) { failed = true; continue; }

            currentSegmentValue = (uint16_t)((currentSegmentValue << 4) | digit);
            segmentDigitIdx += 1;

            continue;
        }

        if (byte == (uint8_t)'.') {
            // The embedded IPv4 address starts where the digits of this segment started.
            uint32_t ipv4Address = 0;
            // Revert the increment we did at the beginning of the loop.
            size_t idxNoIncrement = idx - 1;
            if (segmentDigitIdx == 0) { failed = true; continue; }
            size_t start = idxNoIncrement - segmentDigitIdx;
            if (!cswift_endpoint_slow_static_parse_embedded_ipv4(
                    s + start,
                    count - start,
                    &ipv4Address)) {
                failed = true;
                continue;
            }

            bool isBeforeCs = segmentsCountBeforeCs == 0;
            __uint128_t forBeforeCs = (beforeCs << 32) | (__uint128_t)ipv4Address;
            __uint128_t forAfterCs = (afterCs << 32) | (__uint128_t)ipv4Address;
            beforeCs = isBeforeCs ? forBeforeCs : beforeCs;
            afterCs = isBeforeCs ? afterCs : forAfterCs;

            segmentsCount += 2;
            segmentDigitIdx = 0;

            done = true;
            continue;
        }

        if (segmentDigitIdx == 0) { failed = true; continue; }
        if (byte != (uint8_t)':') { failed = true; continue; }

        bool isBeforeCs = segmentsCountBeforeCs == 0;
        __uint128_t forBeforeCs = (beforeCs << 16) | (__uint128_t)currentSegmentValue;
        __uint128_t forAfterCs = (afterCs << 16) | (__uint128_t)currentSegmentValue;
        beforeCs = isBeforeCs ? forBeforeCs : beforeCs;
        afterCs = isBeforeCs ? afterCs : forAfterCs;

        segmentsCount += 1;
        currentSegmentValue = 0;
        segmentDigitIdx = 0;

        // The pre-loop trailing-colon check guarantees `idx < count`.
        bool isColon = s[idx] == (uint8_t)':';
        segmentsCountBeforeCs = isColon ? segmentsCount : segmentsCountBeforeCs;
        csCount += isColon ? 1 : 0;
        idx += isColon ? 1 : 0;
        }
    if (failed) return r;

    bool isBeforeCs = segmentsCountBeforeCs == 0;
    bool wasParsingSegments = segmentDigitIdx > 0;

    __uint128_t _forBeforeCs = (beforeCs << 16) | (__uint128_t)currentSegmentValue;
    __uint128_t forBeforeCs = wasParsingSegments ? _forBeforeCs : beforeCs;
    __uint128_t _forAfterCs = (afterCs << 16) | (__uint128_t)currentSegmentValue;
    __uint128_t forAfterCs = wasParsingSegments ? _forAfterCs : afterCs;
    beforeCs = isBeforeCs ? forBeforeCs : beforeCs;
    afterCs = isBeforeCs ? afterCs : forAfterCs;

    segmentsCount += wasParsingSegments ? 1 : 0;

    if (segmentDigitIdx >= 5) return r;

    __uint128_t address;
    if (isBeforeCs) {
        address = beforeCs;
        if (segmentsCount != 8) {
            r.hi = (uint64_t)(address >> 64);
            r.lo = (uint64_t)address;
            return r;
        }
    } else {
        // There must be exactly 1 compression sign that stands for at least 1 segment.
        if (csCount != 1 || segmentsCount > 7) return r;

        address = afterCs | (beforeCs << (16 * (8 - segmentsCountBeforeCs)));
    }

    r.hi = (uint64_t)(address >> 64);
    r.lo = (uint64_t)address;
    r.ok = true;
    return r;
}

#ifdef __cplusplus
}  // extern "C"
#endif

#endif  // CSWIFT_DNS_ENDPOINT_SLOW_STATIC_IPV6_PARSE_H
