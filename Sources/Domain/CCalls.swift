#if os(Windows)
import ucrt
#elseif canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
@preconcurrency import Glibc
#elseif canImport(Musl)
@preconcurrency import Musl
#elseif canImport(Bionic)
@preconcurrency import Bionic
#elseif canImport(WASILibc)
@preconcurrency import WASILibc
#else
#error("The Domain CCalls module was unable to identify your C library.")
#endif

@usableFromInline
enum CCalls {
    @usableFromInline
    static func c_memcmp(
        _ a: UnsafeRawPointer,
        _ b: UnsafeRawPointer,
        _ count: Int
    ) -> Int32 {
        memcmp(a, b, count)
    }
}

@available(*, unavailable)
extension CCalls: Sendable {}
