#ifndef CBENCH_SUPPORT_H
#define CBENCH_SUPPORT_H

#include <stdint.h>
#include <stdio.h>

#ifdef __cplusplus
extern "C" {
#endif

// `snprintf` is a C variadic, so it is not importable into Swift. Reaching it through
// `vsnprintf` and `withVaList` costs 2-3 mallocs per call for the argument boxing, which a C
// user never pays. This wrapper is what a C user actually writes.

static inline int cbench_snprintf_u32(char *buffer, size_t size, uint32_t value) {
    return snprintf(buffer, size, "%u", value);
}

#ifdef __cplusplus
}
#endif

#endif
