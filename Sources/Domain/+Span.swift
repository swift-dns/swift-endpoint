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
#error("The Domain+Span module was unable to identify your C library.")
#endif

@available(SwiftStdlib 5.1, *)
extension Span<UInt8> {
    @inlinable
    var isASCII: Bool {
        var result: UInt8 = 0
        for idx in self.indices {
            result |= self[unchecked: idx]
        }
        return result <= 127
    }

    @usableFromInline
    func swift_endpoint_equals(to other: Self) -> Bool {
        guard self.count == other.count else {
            return false
        }
        if self.count == 0 {
            return true
        }

        return self.withUnsafeBytes { selfBytes -> Bool in
            other.withUnsafeBytes { otherBytes -> Bool in
                memcmp(
                    /// If the count is non-zero then the `UnsafeRawBufferPointer` guarantees there is a non-nil pointer.
                    selfBytes.baseAddress.unsafelyUnwrapped,
                    otherBytes.baseAddress.unsafelyUnwrapped,
                    self.count
                ) == 0
            }
        }
    }
}
