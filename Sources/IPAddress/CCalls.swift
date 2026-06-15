#if os(Linux) || os(FreeBSD) || os(Android)

#if canImport(Glibc)
@preconcurrency public import Glibc
#elseif canImport(Musl)
@preconcurrency public import Musl
#elseif canImport(Android)
@preconcurrency public import Android
#endif

#elseif os(Windows)
public import ucrt
#elseif canImport(Darwin)
public import Darwin
#elseif canImport(WASILibc)
@preconcurrency public import WASILibc
#else
#error("The CCalls module was unable to identify your C library.")
#endif

@usableFromInline
enum CCalls {
    @usableFromInline
    static func c_strlen(_ s: UnsafePointer<CChar>) -> Int {
        strlen(s)
    }
}

@available(*, unavailable)
extension CCalls: Sendable {}
