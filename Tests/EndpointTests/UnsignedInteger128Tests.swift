import IPAddress
import Synchronization
import Testing

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
/// We're in tests so should be fine
import Foundation
#endif

@Suite
struct UnsignedInteger128Tests {
    @available(SwiftStdlib 6.0, *)
    @Test func `verify static properties against UInt128`() {
        #expect(UnsignedInteger128.bitWidth == UInt128.bitWidth)
        #expect(UnsignedInteger128.max == UInt128.max)
        #expect(UnsignedInteger128.min == UInt128.min)
        #expect(UnsignedInteger128.zero == UInt128.zero)
        #expect(UnsignedInteger128.isSigned == UInt128.isSigned)
    }

    @available(SwiftStdlib 6.0, *)
    @Test func `verify integer literal init against UInt128`() {
        for lhs in generateRandomUInt128s() {
            let uint128 = UInt128(integerLiteral: lhs)
            let unsignedInteger128 = UnsignedInteger128(integerLiteral: lhs)
            #expect(uint128 == unsignedInteger128)
        }
    }

    @available(SwiftStdlib 6.0, *)
    @Test func `verify instance properties against UInt128`() {
        for lhs in generateRandomUInt128s() {
            let uint128 = UInt128(lhs)
            let unsignedInteger128 = UnsignedInteger128(lhs)
            #expect(uint128.leadingZeroBitCount == unsignedInteger128.leadingZeroBitCount)
            #expect(uint128.trailingZeroBitCount == unsignedInteger128.trailingZeroBitCount)
            #expect(uint128.nonzeroBitCount == unsignedInteger128.nonzeroBitCount)
            #expect(uint128.byteSwapped == unsignedInteger128.byteSwapped)
            #expect(uint128.littleEndian == unsignedInteger128.littleEndian)
            #expect(uint128.bigEndian == unsignedInteger128.bigEndian)
            #expect(uint128.magnitude == unsignedInteger128.magnitude)
            #expect(
                uint128.customMirror.children.count
                    == unsignedInteger128.customMirror.children.count
            )
            #expect(
                uint128.customMirror.children.map(\.label)
                    == unsignedInteger128.customMirror.children.map(\.label)
            )
        }
    }

    @available(SwiftStdlib 6.0, *)
    @Test func `verify description against UInt128`() {
        let randomUInt128s: [UInt128] = (4..<512).map {
            let bitCount = $0 / 4
            let randomBits = (0..<bitCount)
                .map { _ in Bool.random() ? "0" : "1" }
                .joined()
            let random = UInt128(randomBits, radix: 2)!
            return random
        }
        for lhs in randomUInt128s {
            let uint128 = UInt128(lhs)
            let unsignedInteger128 = UnsignedInteger128(lhs)
            #expect(uint128.description == unsignedInteger128.description)
        }
    }

    @available(SwiftStdlib 6.0, *)
    @Test func `verify words against UInt128`() {
        for lhs in generateRandomUInt128s() {
            let uint128 = UInt128(lhs)
            let unsignedInteger128 = UnsignedInteger128(lhs)
            #expect(uint128.words.count == unsignedInteger128.words.count)
            #expect(uint128.words.startIndex == unsignedInteger128.words.startIndex)
            #expect(uint128.words.endIndex == unsignedInteger128.words.endIndex)
            #expect(
                uint128.words.underestimatedCount == unsignedInteger128.words.underestimatedCount
            )
            #expect(uint128.words.indices == unsignedInteger128.words.indices)
            #expect(uint128.words.first == unsignedInteger128.words.first)
            #expect(Array(uint128.words) == Array(unsignedInteger128.words))

            let uint128WordIndexBefore = uint128.words.indices.dropFirst().map {
                uint128.words.index(before: $0)
            }
            let unsignedInteger128WordIndexBefore = unsignedInteger128.words.indices.dropFirst().map
            {
                unsignedInteger128.words.index(before: $0)
            }
            #expect(uint128WordIndexBefore == unsignedInteger128WordIndexBefore)

            let uint128WordIndexAfter = uint128.words.indices.dropLast().map {
                uint128.words.index(after: $0)
            }
            let unsignedInteger128WordIndexAfter = unsignedInteger128.words.indices.dropLast().map {
                unsignedInteger128.words.index(after: $0)
            }
            #expect(uint128WordIndexAfter == unsignedInteger128WordIndexAfter)
        }
    }

    @available(SwiftStdlib 6.0, *)
    @Test func `verify init(_ description: String) against UInt128`() throws {
        for lhs in generateRandomUInt128s() {
            let desc = lhs.description
            let uint128 = try #require(UInt128(desc))
            let unsignedInteger128 = try #require(UnsignedInteger128(desc))
            #expect(uint128 == unsignedInteger128)
            #expect(uint128 == lhs)
        }
    }

    @available(SwiftStdlib 6.0, *)
    @Test func `verify init(big/littleEndian:) against UInt128`() throws {
        for lhs in generateRandomUInt128s() {
            do {
                let uint128 = UInt128(bigEndian: lhs)
                let unsignedInteger128 = UnsignedInteger128(bigEndian: UnsignedInteger128(lhs))
                #expect(uint128 == unsignedInteger128)
            }

            do {
                let uint128 = UInt128(littleEndian: lhs)
                let unsignedInteger128 = UnsignedInteger128(littleEndian: UnsignedInteger128(lhs))
                #expect(uint128 == unsignedInteger128)
            }
        }
    }

    @available(SwiftStdlib 6.0, *)
    @Test func `verify integer initializers against UInt128`() {
        for lhs in generateRandomUInt128s() {
            do {
                let uint128 = UInt128(lhs)
                let unsignedInteger128 = UnsignedInteger128(lhs)
                #expect(uint128._low == unsignedInteger128._low)
                #expect(uint128._high == unsignedInteger128._high)
            }

            do {
                let uint128 = UInt128(truncatingIfNeeded: lhs)
                let unsignedInteger128 = UnsignedInteger128(truncatingIfNeeded: lhs)
                #expect(uint128._low == unsignedInteger128._low)
                #expect(uint128._high == unsignedInteger128._high)
            }

            do {
                let uint128 = UInt128(_truncatingBits: UInt(clamping: lhs))
                let unsignedInteger128 = UnsignedInteger128(_truncatingBits: UInt(clamping: lhs))
                #expect(uint128._low == unsignedInteger128._low)
                #expect(uint128._high == unsignedInteger128._high)
            }

            do {
                let uint128 = UInt128(clamping: lhs)
                let unsignedInteger128 = UnsignedInteger128(clamping: lhs)
                #expect(uint128._low == unsignedInteger128._low)
                #expect(uint128._high == unsignedInteger128._high)
            }
        }
    }

    @available(SwiftStdlib 6.0, *)
    @Test func `verify float initializers against UInt128`() {
        for lhs in generateRandomDoubles() {
            do {
                let uint128 = UInt128(lhs)
                let unsignedInteger128 = UnsignedInteger128(lhs)
                #expect(uint128._low == unsignedInteger128._low)
                #expect(uint128._high == unsignedInteger128._high)
            }

            do {
                let uint128 = UInt128(exactly: lhs)
                let unsignedInteger128 = UnsignedInteger128(exactly: lhs)
                #expect(uint128?._low == unsignedInteger128?._low)
                #expect(uint128?._high == unsignedInteger128?._high)
            }
        }
    }

    @available(SwiftStdlib 6.0, *)
    @Test func `verify equality-operator against UInt128`() {
        #expect(UnsignedInteger128(_low: 0, _high: 0) == UnsignedInteger128(_low: 0, _high: 0))
        #expect(
            UnsignedInteger128(_low: .max, _high: .max)
                == UnsignedInteger128(_low: .max, _high: .max)
        )
        #expect(UnsignedInteger128(_low: 19, _high: 7) == UnsignedInteger128(_low: 19, _high: 7))

        for (lhs, rhs) in generateRandomUInt128Pairs() {
            if lhs == rhs { continue }

            #expect(lhs == lhs)
            #expect(!(lhs != lhs))
            #expect(rhs == rhs)
            #expect(!(rhs != rhs))
            #expect(lhs != rhs)
            #expect(!(lhs == rhs))

            let unsignedLhs = UnsignedInteger128(lhs)
            let unsignedRhs = UnsignedInteger128(rhs)

            #expect(unsignedLhs == unsignedLhs)
            #expect(!(unsignedLhs != unsignedLhs))
            #expect(unsignedRhs == unsignedRhs)
            #expect(!(unsignedRhs != unsignedRhs))
            #expect(unsignedLhs != unsignedRhs)
            #expect(!(unsignedLhs == unsignedRhs))

            #expect(unsignedLhs == lhs)
            #expect(unsignedRhs == rhs)
            #expect(unsignedLhs != rhs)
            #expect(unsignedRhs != lhs)

            #expect(lhs == unsignedLhs)
            #expect(rhs == unsignedRhs)
            #expect(lhs != unsignedRhs)
            #expect(rhs != unsignedLhs)
        }
    }

    @available(SwiftStdlib 6.0, *)
    @Test func `verify strideable conformance against UInt128`() {
        for (lhs, rhs) in generateRandomUInt128Pairs(range: 0...UInt128(Int32.max)) {
            do {
                let uint128 = lhs.distance(to: rhs)
                let unsignedInteger128 = UnsignedInteger128(lhs).distance(
                    to: UnsignedInteger128(rhs)
                )
                #expect(uint128 == unsignedInteger128)
            }

            do {
                let uint128 = lhs.advanced(by: Int(rhs))
                let unsignedInteger128 = UnsignedInteger128(lhs).advanced(by: Int(rhs))
                #expect(uint128 == unsignedInteger128)
            }
        }
    }

    @available(SwiftStdlib 6.0, *)
    @Test func `verify comparison-operators against UInt128`() {
        for (lhs, rhs) in generateRandomUInt128Pairs() {
            #expect(lhs <= lhs)
            #expect(!(lhs < lhs))
            #expect(rhs <= rhs)
            #expect(!(rhs < rhs))

            let unsignedLhs = UnsignedInteger128(lhs)
            let unsignedRhs = UnsignedInteger128(rhs)

            #expect(unsignedLhs <= unsignedLhs)
            #expect(!(unsignedLhs < unsignedLhs))
            #expect(unsignedRhs <= unsignedRhs)
            #expect(!(unsignedRhs < unsignedRhs))

            #expect((unsignedLhs < unsignedRhs) == (lhs < rhs))
            #expect((unsignedLhs <= unsignedRhs) == (lhs <= rhs))
            #expect((unsignedLhs > unsignedRhs) == (lhs > rhs))
            #expect((unsignedLhs >= unsignedRhs) == (lhs >= rhs))
        }
    }

    @available(SwiftStdlib 6.0, *)
    @Test func `verify addition against UInt128`() {
        for (lhs, rhs) in generateRandomUInt128Pairs() {
            let uint128 = lhs.addingReportingOverflow(rhs)
            let unsignedInteger128 = UnsignedInteger128(lhs).addingReportingOverflow(
                UnsignedInteger128(rhs)
            )
            #expect(uint128.partialValue == unsignedInteger128.partialValue)
            #expect(uint128.overflow == unsignedInteger128.overflow)

            do {
                let uint128 = lhs &+ rhs
                let unsignedInteger128 = UnsignedInteger128(lhs) &+ UnsignedInteger128(rhs)
                #expect(uint128 == unsignedInteger128)
            }

            do {
                var uint128 = lhs
                uint128 &+= rhs
                var unsignedInteger128 = UnsignedInteger128(lhs)
                unsignedInteger128 &+= UnsignedInteger128(rhs)
                #expect(uint128 == unsignedInteger128)
            }

            if !uint128.overflow, !unsignedInteger128.overflow {
                do {
                    let uint128 = lhs + rhs
                    let unsignedInteger128 = UnsignedInteger128(lhs) + UnsignedInteger128(rhs)
                    #expect(uint128 == unsignedInteger128)
                }

                do {
                    var uint128 = lhs
                    uint128 += rhs
                    var unsignedInteger128 = UnsignedInteger128(lhs)
                    unsignedInteger128 += UnsignedInteger128(rhs)
                    #expect(uint128 == unsignedInteger128)
                }
            }
        }
    }

    @available(SwiftStdlib 6.0, *)
    @Test func `verify subtraction against UInt128`() {
        for (lhs, rhs) in generateRandomUInt128Pairs() {
            let uint128 = lhs.subtractingReportingOverflow(rhs)
            let unsignedInteger128 = UnsignedInteger128(lhs).subtractingReportingOverflow(
                UnsignedInteger128(rhs)
            )
            #expect(uint128.partialValue == unsignedInteger128.partialValue)
            #expect(uint128.overflow == unsignedInteger128.overflow)

            do {
                let uint128 = lhs &- rhs
                let unsignedInteger128 = UnsignedInteger128(lhs) &- UnsignedInteger128(rhs)
                #expect(uint128 == unsignedInteger128)
            }

            do {
                var uint128 = lhs
                uint128 &-= rhs
                var unsignedInteger128 = UnsignedInteger128(lhs)
                unsignedInteger128 &-= UnsignedInteger128(rhs)
                #expect(uint128 == unsignedInteger128)
            }

            if !uint128.overflow, !unsignedInteger128.overflow {
                do {
                    let uint128 = lhs - rhs
                    let unsignedInteger128 = UnsignedInteger128(lhs) - UnsignedInteger128(rhs)
                    #expect(uint128 == unsignedInteger128)
                }

                do {
                    var uint128 = lhs
                    uint128 -= rhs
                    var unsignedInteger128 = UnsignedInteger128(lhs)
                    unsignedInteger128 -= UnsignedInteger128(rhs)
                    #expect(uint128 == unsignedInteger128)
                }
            }
        }
    }

    @available(SwiftStdlib 6.0, *)
    @Test func `verify multiplication against UInt128`() {
        for (lhs, rhs) in generateRandomUInt128Pairs() {
            let uint128 = lhs.multipliedReportingOverflow(by: rhs)
            let unsignedInteger128 = UnsignedInteger128(lhs).multipliedReportingOverflow(
                by: UnsignedInteger128(rhs)
            )
            #expect(uint128.partialValue == unsignedInteger128.partialValue)
            #expect(uint128.overflow == unsignedInteger128.overflow)

            do {
                let uint128 = lhs.multipliedFullWidth(by: rhs)
                let unsignedInteger128 = UnsignedInteger128(lhs).multipliedFullWidth(
                    by: UnsignedInteger128(rhs)
                )
                #expect(uint128.high == unsignedInteger128.high)
                #expect(uint128.low == unsignedInteger128.low)
            }

            do {
                let uint128 = lhs &* rhs
                let unsignedInteger128 = UnsignedInteger128(lhs) &* UnsignedInteger128(rhs)
                #expect(uint128 == unsignedInteger128)
            }

            do {
                var uint128 = lhs
                uint128 &*= rhs
                var unsignedInteger128 = UnsignedInteger128(lhs)
                unsignedInteger128 &*= UnsignedInteger128(rhs)
                #expect(uint128 == unsignedInteger128)
            }

            if !uint128.overflow, !unsignedInteger128.overflow {
                do {
                    let uint128 = lhs * rhs
                    let unsignedInteger128 = UnsignedInteger128(lhs) * UnsignedInteger128(rhs)
                    #expect(uint128 == unsignedInteger128)
                }

                do {
                    var uint128 = lhs
                    uint128 *= rhs
                    var unsignedInteger128 = UnsignedInteger128(lhs)
                    unsignedInteger128 *= UnsignedInteger128(rhs)
                    #expect(uint128 == unsignedInteger128)
                }
            }
        }
    }

    @available(SwiftStdlib 6.0, *)
    @Test func `verify division against UInt128`() {
        for (lhs, rhs) in generateRandomUInt128Pairs() {
            let uint128 = lhs.dividedReportingOverflow(by: rhs)
            let unsignedInteger128 = UnsignedInteger128(lhs).dividedReportingOverflow(
                by: UnsignedInteger128(rhs)
            )
            #expect(uint128.partialValue == unsignedInteger128.partialValue)
            #expect(uint128.overflow == unsignedInteger128.overflow)

            if !uint128.overflow, !unsignedInteger128.overflow {
                do {
                    let uint128 = lhs / rhs
                    let unsignedInteger128 = UnsignedInteger128(lhs) / UnsignedInteger128(rhs)
                    #expect(uint128 == unsignedInteger128)
                }

                do {
                    var uint128 = lhs
                    uint128 /= rhs
                    var unsignedInteger128 = UnsignedInteger128(lhs)
                    unsignedInteger128 /= UnsignedInteger128(rhs)
                    #expect(uint128 == unsignedInteger128)
                }
            }
        }
    }

    @available(SwiftStdlib 6.0, *)
    @Test func `verify modulo against UInt128`() {
        for (lhs, rhs) in generateRandomUInt128Pairs() {
            let uint128 = lhs.remainderReportingOverflow(dividingBy: rhs)
            let unsignedInteger128 = UnsignedInteger128(lhs).remainderReportingOverflow(
                dividingBy: UnsignedInteger128(rhs)
            )
            #expect(uint128.partialValue == unsignedInteger128.partialValue)
            #expect(uint128.overflow == unsignedInteger128.overflow)

            if !uint128.overflow, !unsignedInteger128.overflow {
                do {
                    let uint128 = lhs % rhs
                    let unsignedInteger128 = UnsignedInteger128(lhs) % UnsignedInteger128(rhs)
                    #expect(uint128 == unsignedInteger128)
                }

                do {
                    var uint128 = lhs
                    uint128 %= rhs
                    var unsignedInteger128 = UnsignedInteger128(lhs)
                    unsignedInteger128 %= UnsignedInteger128(rhs)
                    #expect(uint128 == unsignedInteger128)
                }
            }
        }
    }

    @available(SwiftStdlib 6.0, *)
    @Test func `verify not-operator against UInt128`() {
        for lhs in generateRandomUInt128s() {
            let uint128 = ~lhs
            let unsignedInteger128 = ~UnsignedInteger128(lhs)
            #expect(uint128 == unsignedInteger128)
        }
    }

    @available(SwiftStdlib 6.0, *)
    @Test func `verify or-operator against UInt128`() {
        for (lhs, rhs) in generateRandomUInt128Pairs() {
            do {
                let uint128 = lhs | rhs
                let unsignedInteger128 = UnsignedInteger128(lhs) | UnsignedInteger128(rhs)
                #expect(uint128 == unsignedInteger128)
            }

            do {
                var uint128 = lhs
                uint128 |= rhs
                var unsignedInteger128 = UnsignedInteger128(lhs)
                unsignedInteger128 |= UnsignedInteger128(rhs)
                #expect(uint128 == unsignedInteger128)
            }
        }
    }

    @available(SwiftStdlib 6.0, *)
    @Test func `verify and-operator against UInt128`() {
        for (lhs, rhs) in generateRandomUInt128Pairs() {
            do {
                let uint128 = lhs & rhs
                let unsignedInteger128 = UnsignedInteger128(lhs) & UnsignedInteger128(rhs)
                #expect(uint128 == unsignedInteger128)
            }

            do {
                var uint128 = lhs
                uint128 &= rhs
                var unsignedInteger128 = UnsignedInteger128(lhs)
                unsignedInteger128 &= UnsignedInteger128(rhs)
                #expect(uint128 == unsignedInteger128)
            }
        }
    }

    @available(SwiftStdlib 6.0, *)
    @Test func `verify xor-operator against UInt128`() {
        for (lhs, rhs) in generateRandomUInt128Pairs() {
            do {
                let uint128 = lhs ^ rhs
                let unsignedInteger128 = UnsignedInteger128(lhs) ^ UnsignedInteger128(rhs)
                #expect(uint128 == unsignedInteger128)
            }

            do {
                var uint128 = lhs
                uint128 ^= rhs
                var unsignedInteger128 = UnsignedInteger128(lhs)
                unsignedInteger128 ^= UnsignedInteger128(rhs)
                #expect(uint128 == unsignedInteger128)
            }
        }
    }

    @available(SwiftStdlib 6.0, *)
    @Test func `verify left bit-shift against UInt128`() {
        for (lhs, rhs) in generateRandomUInt128Pairs() {
            do {
                let uint128 = lhs << rhs
                let unsignedInteger128 = UnsignedInteger128(lhs) << UnsignedInteger128(rhs)
                let unsignedInteger128_2 = UnsignedInteger128(lhs) << rhs
                #expect(uint128 == unsignedInteger128)
                #expect(uint128 == unsignedInteger128_2)
            }

            do {
                let uint128 = lhs &<< rhs
                let unsignedInteger128 = UnsignedInteger128(lhs) &<< UnsignedInteger128(rhs)
                let unsignedInteger128_2 = UnsignedInteger128(lhs) &<< rhs
                #expect(uint128 == unsignedInteger128)
                #expect(uint128 == unsignedInteger128_2)
            }

            do {
                var uint128 = lhs
                uint128 <<= rhs
                var unsignedInteger128 = UnsignedInteger128(lhs)
                unsignedInteger128 <<= UnsignedInteger128(rhs)
                var unsignedInteger128_2 = UnsignedInteger128(lhs)
                unsignedInteger128_2 <<= rhs
                #expect(uint128 == unsignedInteger128)
                #expect(uint128 == unsignedInteger128_2)
            }

            do {
                var uint128 = lhs
                uint128 &<<= rhs
                var unsignedInteger128 = UnsignedInteger128(lhs)
                unsignedInteger128 &<<= UnsignedInteger128(rhs)
                var unsignedInteger128_2 = UnsignedInteger128(lhs)
                unsignedInteger128_2 &<<= rhs
                #expect(uint128 == unsignedInteger128)
                #expect(uint128 == unsignedInteger128_2)
            }
        }
    }

    @available(SwiftStdlib 6.0, *)
    @Test func `verify right bit-shift against UInt128`() {
        for (lhs, rhs) in generateRandomUInt128Pairs() {
            do {
                let uint128 = lhs >> rhs
                let unsignedInteger128 = UnsignedInteger128(lhs) >> UnsignedInteger128(rhs)
                let unsignedInteger128_2 = UnsignedInteger128(lhs) >> rhs
                #expect(uint128 == unsignedInteger128)
                #expect(uint128 == unsignedInteger128_2)
            }

            do {
                let uint128 = lhs &>> rhs
                let unsignedInteger128 = UnsignedInteger128(lhs) &>> UnsignedInteger128(rhs)
                let unsignedInteger128_2 = UnsignedInteger128(lhs) &>> rhs
                #expect(uint128 == unsignedInteger128)
                #expect(uint128 == unsignedInteger128_2)
            }

            do {
                var uint128 = lhs
                uint128 >>= rhs
                var unsignedInteger128 = UnsignedInteger128(lhs)
                unsignedInteger128 >>= UnsignedInteger128(rhs)
                var unsignedInteger128_2 = UnsignedInteger128(lhs)
                unsignedInteger128_2 >>= rhs
                #expect(uint128 == unsignedInteger128)
                #expect(uint128 == unsignedInteger128_2)
            }

            do {
                var uint128 = lhs
                uint128 &>>= rhs
                var unsignedInteger128 = UnsignedInteger128(lhs)
                unsignedInteger128 &>>= UnsignedInteger128(rhs)
                var unsignedInteger128_2 = UnsignedInteger128(lhs)
                unsignedInteger128_2 &>>= rhs
                #expect(uint128 == unsignedInteger128)
                #expect(uint128 == unsignedInteger128_2)
            }
        }
    }

    @available(SwiftStdlib 6.0, *)
    @Test(
        arguments: [
            "abc",
            "12a",
            "-1",
            "+1",
            " 1",
            "1 ",
        ]
    )
    func `init from invalid description is nil`(description: String) {
        #expect(UnsignedInteger128(description) == nil)
    }

    @available(SwiftStdlib 6.0, *)
    @Test func `Codable round-trip works as expected`() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        for lhs in generateRandomUInt128s() {
            let unsignedInteger128 = UnsignedInteger128(lhs)
            let encoded = try encoder.encode(unsignedInteger128)
            #expect(String(decoding: encoded, as: UTF8.self) == "\"\(lhs.description)\"")
            let decoded = try decoder.decode(UnsignedInteger128.self, from: encoded)
            #expect(decoded == unsignedInteger128)
        }
    }

    @available(SwiftStdlib 6.0, *)
    @Test func `decoding an invalid description throws`() {
        let decoder = JSONDecoder()
        #expect(throws: DecodingError.self) {
            try decoder.decode(
                UnsignedInteger128.self,
                from: Data("\"not-a-number\"".utf8)
            )
        }
    }

    @available(SwiftStdlib 6.0, *)
    private func generateRandomUInt128Pairs(
        range: ClosedRange<UInt128> = .min ... .max
    ) -> some Sequence<(UInt128, UInt128)> {
        typealias UInt128Pair = (UInt128, UInt128)
        let randomPairs: [UInt128Pair] = (0..<10_000).map { _ in
            (UInt128.random(in: range), UInt128.random(in: range))
        }
        let zeros1: [UInt128Pair] = (0..<100).map { _ in
            (0, UInt128.random(in: range))
        }
        let zeros2: [UInt128Pair] = (0..<100).map { _ in
            (UInt128.random(in: range), 0)
        }
        let zeros3: [UInt128Pair] = [(0, 0)]
        let edgeCases: [UInt128Pair] = [
            (0, .max), (.max, 0),
            (.max, .max),
            (.max, .max - 1), (.max - 1, .max),
            (1, .max), (.max, 1),
        ]
        let result: [UInt128Pair] =
            if range.contains(.max), range.contains(.min) {
                randomPairs + zeros1 + zeros2 + zeros3 + edgeCases
            } else {
                randomPairs + zeros1 + zeros2 + zeros3
            }
        return result
    }

    @available(SwiftStdlib 6.0, *)
    private func generateRandomUInt128s() -> some Sequence<UInt128> {
        let randomPairs: [UInt128] = (0..<10_000).map { _ in
            UInt128.random(in: .min ... .max)
        }
        let edgeCases: [UInt128] = [0, 1, .max - 1, .max]
        let result = randomPairs + edgeCases
        return result
    }

    @available(SwiftStdlib 6.0, *)
    private func generateRandomDoubles(
        randomCount: Int = 10_000
    ) -> some Sequence<Double> {
        let randomPairs: [Double] = (0..<randomCount).map { _ in
            Double.random(in: 0...20.1)
        }
        return randomPairs
    }
}
