#if os(Linux) || os(FreeBSD) || os(Android)

#if canImport(Glibc)
@preconcurrency import Glibc
#elseif canImport(Musl)
@preconcurrency import Musl
#elseif canImport(Android)
@preconcurrency import Android
#endif

#elseif os(Windows)
import ucrt
import WinSDK
#elseif canImport(Darwin)
import Darwin
#elseif canImport(WASILibc)
@preconcurrency import WASILibc
#else
#error("The CCalls test module was unable to identify your C library.")
#endif

/// Calls the platform's `inet_ntop`.
/// FreeBSD only declares the `__inet_ntop` that its `<arpa/inet.h>` macro expands to, and Windows
/// takes the output buffer's size as a `size_t` where the POSIX platforms take a `socklen_t`.
func c_inet_ntop(
    _ family: CInt,
    _ address: UnsafeRawPointer,
    _ buffer: UnsafeMutablePointer<CChar>,
    _ bufferSize: CInt
) -> UnsafePointer<CChar>? {
    #if os(FreeBSD)
    return unsafe __inet_ntop(family, address, buffer, socklen_t(bufferSize))
    #elseif os(Windows)
    return unsafe inet_ntop(family, address, buffer, Int(bufferSize))
    #else
    return unsafe inet_ntop(family, address, buffer, socklen_t(bufferSize))
    #endif
}
