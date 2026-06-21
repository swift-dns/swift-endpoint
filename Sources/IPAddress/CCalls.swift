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
#elseif canImport(Darwin)
import Darwin
#elseif canImport(WASILibc)
@preconcurrency import WASILibc
#else
#error("The CCalls module was unable to identify your C library.")
#endif

@usableFromInline
enum CCalls {
    @usableFromInline
    static func c_strlen(_ s: UnsafePointer<CChar>) -> Int {
        strlen(s)
    }

    @usableFromInline
    static func c_memmove(
        _ dest: UnsafeMutableRawPointer,
        _ src: UnsafeRawPointer,
        _ count: Int
    ) {
        _ = memmove(dest, src, count)
    }

    @usableFromInline
    static func c_memset(
        _ dest: UnsafeMutableRawPointer,
        _ value: Int32,
        _ count: Int
    ) {
        _ = memset(dest, value, count)
    }
}

@available(*, unavailable)
extension CCalls: Sendable {}
