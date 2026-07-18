import DomainIPAddressCompat
import Testing

@Suite
struct SpanTests {
    @available(SwiftStdlib 6.2, *)
    @Test func `equals returns true for empty spans`() {
        let empty: [UInt8] = []
        let result = empty.span.swift_endpoint_equals(to: [])
        #expect(result)
    }

    @available(SwiftStdlib 6.2, *)
    @Test(arguments: 0...40, 0...40)
    func `equals returns false for mismatched counts`(lhsCount: Int, rhsCount: Int) {
        guard lhsCount != rhsCount else {
            return
        }
        let lhs = [UInt8](repeating: 0, count: lhsCount)
        let rhs = [UInt8](repeating: 0, count: rhsCount)
        let result = lhs.span.swift_endpoint_equals(to: rhs)
        #expect(!result)
    }

    @available(SwiftStdlib 6.2, *)
    @Test(arguments: 0...40)
    func `equals returns true for identical bytes of every length`(count: Int) {
        let bytes = (0..<count).map { UInt8(truncatingIfNeeded: $0 &* 7 &+ 3) }
        let result = bytes.span.swift_endpoint_equals(to: bytes)
        #expect(result)
    }

    @available(SwiftStdlib 6.2, *)
    @Test(arguments: 1...40)
    func `equals detects a difference at every byte position of every length`(count: Int) {
        let bytes = (0..<count).map { UInt8(truncatingIfNeeded: $0 &* 7 &+ 3) }
        for position in 0..<count {
            for mask: UInt8 in [0x01, 0x80, 0xFF] {
                var other = bytes
                other[position] ^= mask
                let result = bytes.span.swift_endpoint_equals(to: other)
                #expect(!result)
            }
        }
    }
}
