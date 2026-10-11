#ifndef CSWIFT_DNS_ENDPOINT_SLOW_STATIC_IP_PARSE_H
#define CSWIFT_DNS_ENDPOINT_SLOW_STATIC_IP_PARSE_H

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
//      fires while `r` is still `{0, 0, false, 0, 0}`.
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
    // Where the embedded IPv4 address starts in the input and how many bytes it has, 0 if none.
    // It is parsed by the caller, so its 32 bits in `lo` are left zero.
    size_t ipv4Start;
    size_t ipv4Count;
} cswift_endpoint_slow_static_ipv6_parse_result;

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
    cswift_endpoint_slow_static_ipv6_parse_result r = {0, 0, false, 0, 0};

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
    size_t ipv4Start = 0;
    size_t ipv4Count = 0;

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
            // Revert the increment we did at the beginning of the loop.
            size_t idxNoIncrement = idx - 1;
            if (segmentDigitIdx == 0) { failed = true; continue; }
            size_t start = idxNoIncrement - segmentDigitIdx;
            // The caller parses the embedded IPv4 address, so only its position is kept here,
            // counted from the start of the input before the brackets were trimmed.
            ipv4Start = (startsWithBracket ? 1 : 0) + start;
            ipv4Count = count - start;

            bool isBeforeCs = segmentsCountBeforeCs == 0;
            __uint128_t forBeforeCs = beforeCs << 32;
            __uint128_t forAfterCs = afterCs << 32;
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
    r.ipv4Start = ipv4Start;
    r.ipv4Count = ipv4Count;
    return r;
}

#ifdef __cplusplus
}  // extern "C"
#endif

#endif  // CSWIFT_DNS_ENDPOINT_SLOW_STATIC_IP_PARSE_H
