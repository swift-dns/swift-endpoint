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
    static func c_memmove(
        _ dest: UnsafeMutableRawPointer,
        _ src: UnsafeRawPointer,
        _ count: Int
    ) {
        _ = unsafe memmove(dest, src, count)
    }
}

@available(*, unavailable)
extension CCalls: Sendable {}
