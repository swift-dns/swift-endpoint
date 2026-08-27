#ifndef CSWIFT_DNS_ENDPOINT_SLOW_STATIC_IPV6_PARSE_H
#define CSWIFT_DNS_ENDPOINT_SLOW_STATIC_IPV6_PARSE_H

#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#include "cswift_endpoint_hexadecimal_digit_table.h"

#ifdef __cplusplus
extern "C" {
#endif

// A second, slower IPv6 parser, used only by `IPv6Address(_ description: StaticString)`.
// It is written out rather than looped so a literal address folds to a constant, which
// `parseIPv6` cannot do: its byte loop is never peeled or unrolled.
// It is in C because Swift honours `@inline(always)` at `-Onone` too, which costs 74512 bytes
// of stack per call site; clang's `always_inline` costs 4672.

typedef struct {
    uint64_t hi;
    uint64_t lo;
    bool ok;
} cswift_endpoint_slow_static_ipv6_parse_result;

// Parses an embedded IPv4 address, most significant byte first.
__attribute__((always_inline))
static inline bool cswift_endpoint_slow_static_parse_embedded_ipv4(
    const uint8_t *s,
    size_t count,
    uint32_t *out
) {
    if (count < 7 || count > 15) {
        return false;
    }

    uint32_t address = 0;
    size_t i = 0;

#define CSWIFT_ENDPOINT_SLOW_STATIC_IPV4_SEGMENT(needs_dot)             \
    {                                                                   \
        if (i >= count) return false;                                   \
        uint32_t value = 0;                                             \
        int digits = 0;                                                 \
        while (i < count && s[i] >= '0' && s[i] <= '9' && digits < 3) { \
            value = value * 10 + (uint32_t)(s[i] - '0');                \
            i++;                                                        \
            digits++;                                                   \
        }                                                               \
        if (digits == 0 || value > 255) return false;                   \
        address = (address << 8) | value;                               \
        if (needs_dot) {                                                \
            if (i >= count || s[i] != '.') return false;                \
            i++;                                                        \
        }                                                               \
    }

    CSWIFT_ENDPOINT_SLOW_STATIC_IPV4_SEGMENT(1)
    CSWIFT_ENDPOINT_SLOW_STATIC_IPV4_SEGMENT(1)
    CSWIFT_ENDPOINT_SLOW_STATIC_IPV4_SEGMENT(1)
    CSWIFT_ENDPOINT_SLOW_STATIC_IPV4_SEGMENT(0)

#undef CSWIFT_ENDPOINT_SLOW_STATIC_IPV4_SEGMENT

    if (i != count) {
        return false;
    }

    *out = address;
    return true;
}

__attribute__((always_inline))
static inline cswift_endpoint_slow_static_ipv6_parse_result cswift_endpoint_slow_static_parse_ipv6(
    const uint8_t *s,
    size_t n
) {
    cswift_endpoint_slow_static_ipv6_parse_result r = {0, 0, false};

    // 2 == "::".count
    if (n < 2) {
        return r;
    }

    bool starts_with_bracket = s[0] == '[';
    bool ends_with_bracket = s[n - 1] == ']';
    if (starts_with_bracket != ends_with_bracket) {
        return r;
    }

    size_t i = starts_with_bracket ? 1 : 0;
    size_t end = starts_with_bracket ? n - 1 : n;
    if (end - i < 2) {
        return r;
    }

    unsigned __int128 before = 0;
    unsigned __int128 after = 0;
    int segments = 0;
    int segments_before_cs = 0;
    int cs_count = 0;
    int digits = 0;
    uint16_t current = 0;
    bool has_ipv4 = false;
    uint32_t ipv4 = 0;

    // For when there is a lone colon at the start
    if (s[i] == ':' && s[i + 1] != ':') {
        return r;
    }
    // And for when there is a compression sign at the end
    if (s[end - 1] == ':' && s[end - 2] != ':') {
        return r;
    }

    // This `1` is technically not correct.
    // We use 1 because we use 0 to indicate no before-cs segments.
    if (s[i] == ':') {
        segments_before_cs = 1;
        cs_count = 1;
        i += 2;
    }

    // One byte of the address. 45 is the longest a valid address can be, so the state is
    // final by the last step.
#define CSWIFT_ENDPOINT_SLOW_STATIC_IPV6_STEP()                                 \
    if (i < end && !has_ipv4) {                                                 \
        uint8_t byte = s[i++];                                                  \
        uint8_t digit = cswift_endpoint_hexadecimal_digit_table[byte];          \
        if (digit != 0xFF) {                                                    \
            if (digits == 4) goto fail;                                         \
            current = (uint16_t)((current << 4) | digit);                       \
            digits++;                                                           \
        } else if (byte == '.') {                                               \
            /* The embedded IPv4 starts where this segment's digits started. */ \
            if (digits == 0) goto fail;                                         \
            if (!cswift_endpoint_slow_static_parse_embedded_ipv4(               \
                    s + (i - 1 - (size_t)digits),                               \
                    end - (i - 1 - (size_t)digits),                             \
                    &ipv4)) {                                                   \
                goto fail;                                                      \
            }                                                                   \
            if (segments_before_cs == 0) {                                      \
                before = (before << 32) | ipv4;                                 \
            } else {                                                            \
                after = (after << 32) | ipv4;                                   \
            }                                                                   \
            segments += 2;                                                      \
            digits = 0;                                                         \
            has_ipv4 = true;                                                    \
        } else if (byte == ':') {                                               \
            if (digits == 0) goto fail;                                         \
            if (segments_before_cs == 0) {                                      \
                before = (before << 16) | current;                              \
            } else {                                                            \
                after = (after << 16) | current;                                \
            }                                                                   \
            segments++;                                                         \
            current = 0;                                                        \
            digits = 0;                                                         \
            if (i < end && s[i] == ':') {                                       \
                segments_before_cs = segments;                                  \
                cs_count++;                                                     \
                i++;                                                            \
            }                                                                   \
        } else {                                                                \
            goto fail;                                                          \
        }                                                                       \
    }

    CSWIFT_ENDPOINT_SLOW_STATIC_IPV6_STEP()
    CSWIFT_ENDPOINT_SLOW_STATIC_IPV6_STEP()
    CSWIFT_ENDPOINT_SLOW_STATIC_IPV6_STEP()
    CSWIFT_ENDPOINT_SLOW_STATIC_IPV6_STEP()
    CSWIFT_ENDPOINT_SLOW_STATIC_IPV6_STEP()
    CSWIFT_ENDPOINT_SLOW_STATIC_IPV6_STEP()
    CSWIFT_ENDPOINT_SLOW_STATIC_IPV6_STEP()
    CSWIFT_ENDPOINT_SLOW_STATIC_IPV6_STEP()
    CSWIFT_ENDPOINT_SLOW_STATIC_IPV6_STEP()
    CSWIFT_ENDPOINT_SLOW_STATIC_IPV6_STEP()
    CSWIFT_ENDPOINT_SLOW_STATIC_IPV6_STEP()
    CSWIFT_ENDPOINT_SLOW_STATIC_IPV6_STEP()
    CSWIFT_ENDPOINT_SLOW_STATIC_IPV6_STEP()
    CSWIFT_ENDPOINT_SLOW_STATIC_IPV6_STEP()
    CSWIFT_ENDPOINT_SLOW_STATIC_IPV6_STEP()
    CSWIFT_ENDPOINT_SLOW_STATIC_IPV6_STEP()
    CSWIFT_ENDPOINT_SLOW_STATIC_IPV6_STEP()
    CSWIFT_ENDPOINT_SLOW_STATIC_IPV6_STEP()
    CSWIFT_ENDPOINT_SLOW_STATIC_IPV6_STEP()
    CSWIFT_ENDPOINT_SLOW_STATIC_IPV6_STEP()
    CSWIFT_ENDPOINT_SLOW_STATIC_IPV6_STEP()
    CSWIFT_ENDPOINT_SLOW_STATIC_IPV6_STEP()
    CSWIFT_ENDPOINT_SLOW_STATIC_IPV6_STEP()
    CSWIFT_ENDPOINT_SLOW_STATIC_IPV6_STEP()
    CSWIFT_ENDPOINT_SLOW_STATIC_IPV6_STEP()
    CSWIFT_ENDPOINT_SLOW_STATIC_IPV6_STEP()
    CSWIFT_ENDPOINT_SLOW_STATIC_IPV6_STEP()
    CSWIFT_ENDPOINT_SLOW_STATIC_IPV6_STEP()
    CSWIFT_ENDPOINT_SLOW_STATIC_IPV6_STEP()
    CSWIFT_ENDPOINT_SLOW_STATIC_IPV6_STEP()
    CSWIFT_ENDPOINT_SLOW_STATIC_IPV6_STEP()
    CSWIFT_ENDPOINT_SLOW_STATIC_IPV6_STEP()
    CSWIFT_ENDPOINT_SLOW_STATIC_IPV6_STEP()
    CSWIFT_ENDPOINT_SLOW_STATIC_IPV6_STEP()
    CSWIFT_ENDPOINT_SLOW_STATIC_IPV6_STEP()
    CSWIFT_ENDPOINT_SLOW_STATIC_IPV6_STEP()
    CSWIFT_ENDPOINT_SLOW_STATIC_IPV6_STEP()
    CSWIFT_ENDPOINT_SLOW_STATIC_IPV6_STEP()
    CSWIFT_ENDPOINT_SLOW_STATIC_IPV6_STEP()
    CSWIFT_ENDPOINT_SLOW_STATIC_IPV6_STEP()
    CSWIFT_ENDPOINT_SLOW_STATIC_IPV6_STEP()
    CSWIFT_ENDPOINT_SLOW_STATIC_IPV6_STEP()
    CSWIFT_ENDPOINT_SLOW_STATIC_IPV6_STEP()
    CSWIFT_ENDPOINT_SLOW_STATIC_IPV6_STEP()
    CSWIFT_ENDPOINT_SLOW_STATIC_IPV6_STEP()

#undef CSWIFT_ENDPOINT_SLOW_STATIC_IPV6_STEP

    // Any bytes left mean the address is longer than one can validly be.
    if (i < end && !has_ipv4) {
        return r;
    }

    if (digits > 0) {
        if (segments_before_cs == 0) {
            before = (before << 16) | current;
        } else {
            after = (after << 16) | current;
        }
        segments++;
    }

    if (digits >= 5) {
        return r;
    }

    unsigned __int128 address;
    if (segments_before_cs == 0) {
        if (segments != 8) {
            return r;
        }
        address = before;
    } else {
        // There must be exactly 1 compression sign that stands for at least 1 segment.
        if (cs_count != 1 || segments > 7) {
            return r;
        }
        address = after | (before << (16 * (8 - segments_before_cs)));
    }

    r.hi = (uint64_t)(address >> 64);
    r.lo = (uint64_t)address;
    r.ok = true;
    return r;

fail:
    r.ok = false;
    return r;
}

#ifdef __cplusplus
}  // extern "C"
#endif

#endif  // CSWIFT_DNS_ENDPOINT_SLOW_STATIC_IPV6_PARSE_H
