#ifndef CSWIFT_DNS_ENDPOINT_DECIMAL_DIGITS_TABLE_H
#define CSWIFT_DNS_ENDPOINT_DECIMAL_DIGITS_TABLE_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

// The decimal-digits table is indexed by a byte and describes how to print it
// in base 10:
//
//   - Bytes 0, 1, 2: the ASCII digits, most significant first, zero-padded on
//   the right.
//   - Byte 3: how many of the above digits are significant, plus one, so 2 to 4.
//
// So 7 is `{'7', 0, 0, 2}` and 255 is `{'2', '5', '5', 4}`.
// This enables speculative writes, where you write all 3 bytes and only advance an index
// by the number of significant bytes, to leave the insignificant bytes to be overwritten.
// The stored count is one too high because a dotted-quad writer also writes a separator
// per segment; it shifts the entry up by a byte to make room for one, and then byte 3 is
// exactly how far to advance. Writers that don't add a separator subtract the one back.

extern const uint32_t cswift_endpoint_decimal_digits_table[256];

// Returns the packed decimal-digits entry for the given byte.
static inline uint32_t cswift_endpoint_decimal_digits(uint8_t byte) {
    return cswift_endpoint_decimal_digits_table[byte];
}

#ifdef __cplusplus
} // extern "C"
#endif

#endif // CSWIFT_DNS_ENDPOINT_DECIMAL_DIGITS_TABLE_H
