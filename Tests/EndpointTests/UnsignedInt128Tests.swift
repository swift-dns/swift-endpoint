import IPAddress
import Synchronization
import Testing

@Suite
struct UnsignedInt128Tests {
    @available(swiftEndpointApplePlatforms 15, *)
    @Test func `verify static properties against UInt128`() {
        #expect(UnsignedInt128.bitWidth == UInt128.bitWidth)
        #expect(UnsignedInt128.max == UInt128.max)
        #expect(UnsignedInt128.min == UInt128.min)
        #expect(UnsignedInt128.zero == UInt128.zero)
        #expect(UnsignedInt128.isSigned == UInt128.isSigned)
    }

    @available(swiftEndpointApplePlatforms 15, *)
    @Test func `verify integer literal init against UInt128`() {
        for lhs in generateRandomUInt128s() {
            let uint128 = UInt128(integerLiteral: lhs)
            let unsignedInt128 = UnsignedInt128(integerLiteral: lhs)
            #expect(uint128 == unsignedInt128)
        }
    }

    @available(swiftEndpointApplePlatforms 15, *)
    @Test func `verify instance properties against UInt128`() {
        for lhs in generateRandomUInt128s() {
            let uint128 = UInt128(lhs)
            let unsignedInt128 = UnsignedInt128(lhs)
            #expect(uint128.leadingZeroBitCount == unsignedInt128.leadingZeroBitCount)
            #expect(uint128.trailingZeroBitCount == unsignedInt128.trailingZeroBitCount)
            #expect(uint128.nonzeroBitCount == unsignedInt128.nonzeroBitCount)
            #expect(uint128.byteSwapped == unsignedInt128.byteSwapped)
            #expect(uint128.littleEndian == unsignedInt128.littleEndian)
            #expect(uint128.bigEndian == unsignedInt128.bigEndian)
            #expect(uint128.magnitude == unsignedInt128.magnitude)
            #expect(
                uint128.customMirror.children.count
                    == unsignedInt128.customMirror.children.count
            )
            #expect(
                uint128.customMirror.children.map(\.label)
                    == unsignedInt128.customMirror.children.map(\.label)
            )
        }
    }

    @available(swiftEndpointApplePlatforms 15, *)
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
            let unsignedInt128 = UnsignedInt128(lhs)
            #expect(uint128.description == unsignedInt128.description)
        }
    }

    @available(swiftEndpointApplePlatforms 15, *)
    @Test func `verify words against UInt128`() {
        for lhs in generateRandomUInt128s() {
            let uint128 = UInt128(lhs)
            let unsignedInt128 = UnsignedInt128(lhs)
            #expect(uint128.words.count == unsignedInt128.words.count)
            #expect(uint128.words.startIndex == unsignedInt128.words.startIndex)
            #expect(uint128.words.endIndex == unsignedInt128.words.endIndex)
            #expect(uint128.words.underestimatedCount == unsignedInt128.words.underestimatedCount)
            #expect(uint128.words.indices == unsignedInt128.words.indices)
            #expect(uint128.words.first == unsignedInt128.words.first)
            #expect(Array(uint128.words) == Array(unsignedInt128.words))

            let uint128WordIndexBefore = uint128.words.indices.dropFirst().map {
                uint128.words.index(before: $0)
            }
            let unsignedInt128WordIndexBefore = unsignedInt128.words.indices.dropFirst().map {
                unsignedInt128.words.index(before: $0)
            }
            #expect(uint128WordIndexBefore == unsignedInt128WordIndexBefore)

            let uint128WordIndexAfter = uint128.words.indices.dropLast().map {
                uint128.words.index(after: $0)
            }
            let unsignedInt128WordIndexAfter = unsignedInt128.words.indices.dropLast().map {
                unsignedInt128.words.index(after: $0)
            }
            #expect(uint128WordIndexAfter == unsignedInt128WordIndexAfter)
        }
    }

    @available(swiftEndpointApplePlatforms 15, *)
    @Test func `verify init(_ description: String) against UInt128`() throws {
        for lhs in generateRandomUInt128s() {
            let desc = lhs.description
            let uint128 = try #require(UInt128(desc))
            let unsignedInt128 = try #require(UnsignedInt128(desc))
            #expect(uint128 == unsignedInt128)
            #expect(uint128 == lhs)
        }
    }

    @available(swiftEndpointApplePlatforms 15, *)
    @Test func `verify init(big/littleEndian:) against UInt128`() throws {
        for lhs in generateRandomUInt128s() {
            do {
                let uint128 = UInt128(bigEndian: lhs)
                let unsignedInt128 = UnsignedInt128(bigEndian: UnsignedInt128(lhs))
                #expect(uint128 == unsignedInt128)
            }

            do {
                let uint128 = UInt128(littleEndian: lhs)
                let unsignedInt128 = UnsignedInt128(littleEndian: UnsignedInt128(lhs))
                #expect(uint128 == unsignedInt128)
            }
        }
    }

    @available(swiftEndpointApplePlatforms 15, *)
    @Test func `verify integer initializers against UInt128`() {
        for lhs in generateRandomUInt128s() {
            do {
                let uint128 = UInt128(lhs)
                let unsignedInt128 = UnsignedInt128(lhs)
                #expect(uint128._low == unsignedInt128._low)
                #expect(uint128._high == unsignedInt128._high)
            }

            do {
                let uint128 = UInt128(truncatingIfNeeded: lhs)
                let unsignedInt128 = UnsignedInt128(truncatingIfNeeded: lhs)
                #expect(uint128._low == unsignedInt128._low)
                #expect(uint128._high == unsignedInt128._high)
            }

            do {
                let uint128 = UInt128(_truncatingBits: UInt(clamping: lhs))
                let unsignedInt128 = UnsignedInt128(_truncatingBits: UInt(clamping: lhs))
                #expect(uint128._low == unsignedInt128._low)
                #expect(uint128._high == unsignedInt128._high)
            }

            do {
                let uint128 = UInt128(clamping: lhs)
                let unsignedInt128 = UnsignedInt128(clamping: lhs)
                #expect(uint128._low == unsignedInt128._low)
                #expect(uint128._high == unsignedInt128._high)
            }
        }
    }

    @available(swiftEndpointApplePlatforms 15, *)
    @Test func `verify float initializers against UInt128`() {
        for lhs in generateRandomDoubles() {
            do {
                let uint128 = UInt128(lhs)
                let unsignedInt128 = UnsignedInt128(lhs)
                #expect(uint128._low == unsignedInt128._low)
                #expect(uint128._high == unsignedInt128._high)
            }

            do {
                let uint128 = UInt128(exactly: lhs)
                let unsignedInt128 = UnsignedInt128(exactly: lhs)
                #expect(uint128?._low == unsignedInt128?._low)
                #expect(uint128?._high == unsignedInt128?._high)
            }
        }
    }

    @available(swiftEndpointApplePlatforms 15, *)
    @Test func `verify equality-operator against UInt128`() {
        #expect(UnsignedInt128(_low: 0, _high: 0) == UnsignedInt128(_low: 0, _high: 0))
        #expect(UnsignedInt128(_low: .max, _high: .max) == UnsignedInt128(_low: .max, _high: .max))
        #expect(UnsignedInt128(_low: 19, _high: 7) == UnsignedInt128(_low: 19, _high: 7))

        for (lhs, rhs) in generateRandomUInt128Pairs() {
            if lhs == rhs { continue }

            #expect(lhs == lhs)
            #expect(!(lhs != lhs))
            #expect(rhs == rhs)
            #expect(!(rhs != rhs))
            #expect(lhs != rhs)
            #expect(!(lhs == rhs))

            let unsignedLhs = UnsignedInt128(lhs)
            let unsignedRhs = UnsignedInt128(rhs)

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

    @available(swiftEndpointApplePlatforms 15, *)
    @Test func `verify strideable conformance against UInt128`() {
        for (lhs, rhs) in generateRandomUInt128Pairs(range: 0...UInt128(Int32.max)) {
            do {
                let uint128 = lhs.distance(to: rhs)
                let unsignedInt128 = UnsignedInt128(lhs).distance(to: UnsignedInt128(rhs))
                #expect(uint128 == unsignedInt128)
            }

            do {
                let uint128 = lhs.advanced(by: Int(rhs))
                let unsignedInt128 = UnsignedInt128(lhs).advanced(by: Int(rhs))
                #expect(uint128 == unsignedInt128)
            }
        }
    }

    @available(swiftEndpointApplePlatforms 15, *)
    @Test func `verify comparison-operators against UInt128`() {
        for (lhs, rhs) in generateRandomUInt128Pairs() {
            #expect(lhs <= lhs)
            #expect(!(lhs < lhs))
            #expect(rhs <= rhs)
            #expect(!(rhs < rhs))

            let unsignedLhs = UnsignedInt128(lhs)
            let unsignedRhs = UnsignedInt128(rhs)

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

    @available(swiftEndpointApplePlatforms 15, *)
    @Test func `verify addition against UInt128`() {
        for (lhs, rhs) in generateRandomUInt128Pairs() {
            let uint128 = lhs.addingReportingOverflow(rhs)
            let unsignedInt128 = UnsignedInt128(lhs).addingReportingOverflow(UnsignedInt128(rhs))
            #expect(uint128.partialValue == unsignedInt128.partialValue)
            #expect(uint128.overflow == unsignedInt128.overflow)

            do {
                let uint128 = lhs &+ rhs
                let unsignedInt128 = UnsignedInt128(lhs) &+ UnsignedInt128(rhs)
                #expect(uint128 == unsignedInt128)
            }

            do {
                var uint128 = lhs
                uint128 &+= rhs
                var unsignedInt128 = UnsignedInt128(lhs)
                unsignedInt128 &+= UnsignedInt128(rhs)
                #expect(uint128 == unsignedInt128)
            }

            if !uint128.overflow, !unsignedInt128.overflow {
                do {
                    let uint128 = lhs + rhs
                    let unsignedInt128 = UnsignedInt128(lhs) + UnsignedInt128(rhs)
                    #expect(uint128 == unsignedInt128)
                }

                do {
                    var uint128 = lhs
                    uint128 += rhs
                    var unsignedInt128 = UnsignedInt128(lhs)
                    unsignedInt128 += UnsignedInt128(rhs)
                    #expect(uint128 == unsignedInt128)
                }
            }
        }
    }

    @available(swiftEndpointApplePlatforms 15, *)
    @Test func `verify subtraction against UInt128`() {
        for (lhs, rhs) in generateRandomUInt128Pairs() {
            let uint128 = lhs.subtractingReportingOverflow(rhs)
            let unsignedInt128 = UnsignedInt128(lhs).subtractingReportingOverflow(
                UnsignedInt128(rhs)
            )
            #expect(uint128.partialValue == unsignedInt128.partialValue)
            #expect(uint128.overflow == unsignedInt128.overflow)

            do {
                let uint128 = lhs &- rhs
                let unsignedInt128 = UnsignedInt128(lhs) &- UnsignedInt128(rhs)
                #expect(uint128 == unsignedInt128)
            }

            do {
                var uint128 = lhs
                uint128 &-= rhs
                var unsignedInt128 = UnsignedInt128(lhs)
                unsignedInt128 &-= UnsignedInt128(rhs)
                #expect(uint128 == unsignedInt128)
            }

            if !uint128.overflow, !unsignedInt128.overflow {
                do {
                    let uint128 = lhs - rhs
                    let unsignedInt128 = UnsignedInt128(lhs) - UnsignedInt128(rhs)
                    #expect(uint128 == unsignedInt128)
                }

                do {
                    var uint128 = lhs
                    uint128 -= rhs
                    var unsignedInt128 = UnsignedInt128(lhs)
                    unsignedInt128 -= UnsignedInt128(rhs)
                    #expect(uint128 == unsignedInt128)
                }
            }
        }
    }

    @available(swiftEndpointApplePlatforms 15, *)
    @Test func `verify multiplication against UInt128`() {
        for (lhs, rhs) in generateRandomUInt128Pairs() {
            let uint128 = lhs.multipliedReportingOverflow(by: rhs)
            let unsignedInt128 = UnsignedInt128(lhs).multipliedReportingOverflow(
                by: UnsignedInt128(rhs)
            )
            #expect(uint128.partialValue == unsignedInt128.partialValue)
            #expect(uint128.overflow == unsignedInt128.overflow)

            do {
                let uint128 = lhs.multipliedFullWidth(by: rhs)
                let unsignedInt128 = UnsignedInt128(lhs).multipliedFullWidth(
                    by: UnsignedInt128(rhs)
                )
                #expect(uint128.high == unsignedInt128.high)
                #expect(uint128.low == unsignedInt128.low)
            }

            do {
                let uint128 = lhs &* rhs
                let unsignedInt128 = UnsignedInt128(lhs) &* UnsignedInt128(rhs)
                #expect(uint128 == unsignedInt128)
            }

            do {
                var uint128 = lhs
                uint128 &*= rhs
                var unsignedInt128 = UnsignedInt128(lhs)
                unsignedInt128 &*= UnsignedInt128(rhs)
                #expect(uint128 == unsignedInt128)
            }

            if !uint128.overflow, !unsignedInt128.overflow {
                do {
                    let uint128 = lhs * rhs
                    let unsignedInt128 = UnsignedInt128(lhs) * UnsignedInt128(rhs)
                    #expect(uint128 == unsignedInt128)
                }

                do {
                    var uint128 = lhs
                    uint128 *= rhs
                    var unsignedInt128 = UnsignedInt128(lhs)
                    unsignedInt128 *= UnsignedInt128(rhs)
                    #expect(uint128 == unsignedInt128)
                }
            }
        }
    }

    @available(swiftEndpointApplePlatforms 15, *)
    @Test func `verify division against UInt128`() {
        for (lhs, rhs) in generateRandomUInt128Pairs() {
            let uint128 = lhs.dividedReportingOverflow(by: rhs)
            let unsignedInt128 = UnsignedInt128(lhs).dividedReportingOverflow(
                by: UnsignedInt128(rhs)
            )
            #expect(uint128.partialValue == unsignedInt128.partialValue)
            #expect(uint128.overflow == unsignedInt128.overflow)

            if !uint128.overflow, !unsignedInt128.overflow {
                do {
                    let uint128 = lhs / rhs
                    let unsignedInt128 = UnsignedInt128(lhs) / UnsignedInt128(rhs)
                    #expect(uint128 == unsignedInt128)
                }

                do {
                    var uint128 = lhs
                    uint128 /= rhs
                    var unsignedInt128 = UnsignedInt128(lhs)
                    unsignedInt128 /= UnsignedInt128(rhs)
                    #expect(uint128 == unsignedInt128)
                }
            }
        }
    }

    @available(swiftEndpointApplePlatforms 15, *)
    @Test func `verify modulo against UInt128`() {
        for (lhs, rhs) in generateRandomUInt128Pairs() {
            let uint128 = lhs.remainderReportingOverflow(dividingBy: rhs)
            let unsignedInt128 = UnsignedInt128(lhs).remainderReportingOverflow(
                dividingBy: UnsignedInt128(rhs)
            )
            #expect(uint128.partialValue == unsignedInt128.partialValue)
            #expect(uint128.overflow == unsignedInt128.overflow)

            if !uint128.overflow, !unsignedInt128.overflow {
                do {
                    let uint128 = lhs % rhs
                    let unsignedInt128 = UnsignedInt128(lhs) % UnsignedInt128(rhs)
                    #expect(uint128 == unsignedInt128)
                }

                do {
                    var uint128 = lhs
                    uint128 %= rhs
                    var unsignedInt128 = UnsignedInt128(lhs)
                    unsignedInt128 %= UnsignedInt128(rhs)
                    #expect(uint128 == unsignedInt128)
                }
            }
        }
    }

    @available(swiftEndpointApplePlatforms 15, *)
    @Test func `verify not-operator against UInt128`() {
        for lhs in generateRandomUInt128s() {
            let uint128 = ~lhs
            let unsignedInt128 = ~UnsignedInt128(lhs)
            #expect(uint128 == unsignedInt128)
        }
    }

    @available(swiftEndpointApplePlatforms 15, *)
    @Test func `verify or-operator against UInt128`() {
        for (lhs, rhs) in generateRandomUInt128Pairs() {
            do {
                let uint128 = lhs | rhs
                let unsignedInt128 = UnsignedInt128(lhs) | UnsignedInt128(rhs)
                #expect(uint128 == unsignedInt128)
            }

            do {
                var uint128 = lhs
                uint128 |= rhs
                var unsignedInt128 = UnsignedInt128(lhs)
                unsignedInt128 |= UnsignedInt128(rhs)
                #expect(uint128 == unsignedInt128)
            }
        }
    }

    @available(swiftEndpointApplePlatforms 15, *)
    @Test func `verify and-operator against UInt128`() {
        for (lhs, rhs) in generateRandomUInt128Pairs() {
            do {
                let uint128 = lhs & rhs
                let unsignedInt128 = UnsignedInt128(lhs) & UnsignedInt128(rhs)
                #expect(uint128 == unsignedInt128)
            }

            do {
                var uint128 = lhs
                uint128 &= rhs
                var unsignedInt128 = UnsignedInt128(lhs)
                unsignedInt128 &= UnsignedInt128(rhs)
                #expect(uint128 == unsignedInt128)
            }
        }
    }

    @available(swiftEndpointApplePlatforms 15, *)
    @Test func `verify xor-operator against UInt128`() {
        for (lhs, rhs) in generateRandomUInt128Pairs() {
            do {
                let uint128 = lhs ^ rhs
                let unsignedInt128 = UnsignedInt128(lhs) ^ UnsignedInt128(rhs)
                #expect(uint128 == unsignedInt128)
            }

            do {
                var uint128 = lhs
                uint128 ^= rhs
                var unsignedInt128 = UnsignedInt128(lhs)
                unsignedInt128 ^= UnsignedInt128(rhs)
                #expect(uint128 == unsignedInt128)
            }
        }
    }

    @available(swiftEndpointApplePlatforms 15, *)
    @Test func `verify left bit-shift against UInt128`() {
        for (lhs, rhs) in generateRandomUInt128Pairs() {
            do {
                let uint128 = lhs << rhs
                let unsignedInt128 = UnsignedInt128(lhs) << UnsignedInt128(rhs)
                let unsignedInt128_2 = UnsignedInt128(lhs) << rhs
                #expect(uint128 == unsignedInt128)
                #expect(uint128 == unsignedInt128_2)
            }

            do {
                let uint128 = lhs &<< rhs
                let unsignedInt128 = UnsignedInt128(lhs) &<< UnsignedInt128(rhs)
                let unsignedInt128_2 = UnsignedInt128(lhs) &<< rhs
                #expect(uint128 == unsignedInt128)
                #expect(uint128 == unsignedInt128_2)
            }

            do {
                var uint128 = lhs
                uint128 <<= rhs
                var unsignedInt128 = UnsignedInt128(lhs)
                unsignedInt128 <<= UnsignedInt128(rhs)
                var unsignedInt128_2 = UnsignedInt128(lhs)
                unsignedInt128_2 <<= rhs
                #expect(uint128 == unsignedInt128)
                #expect(uint128 == unsignedInt128_2)
            }

            do {
                var uint128 = lhs
                uint128 &<<= rhs
                var unsignedInt128 = UnsignedInt128(lhs)
                unsignedInt128 &<<= UnsignedInt128(rhs)
                var unsignedInt128_2 = UnsignedInt128(lhs)
                unsignedInt128_2 &<<= rhs
                #expect(uint128 == unsignedInt128)
                #expect(uint128 == unsignedInt128_2)
            }
        }
    }

    @available(swiftEndpointApplePlatforms 15, *)
    @Test func `verify right bit-shift against UInt128`() {
        for (lhs, rhs) in generateRandomUInt128Pairs() {
            do {
                let uint128 = lhs >> rhs
                let unsignedInt128 = UnsignedInt128(lhs) >> UnsignedInt128(rhs)
                let unsignedInt128_2 = UnsignedInt128(lhs) >> rhs
                #expect(uint128 == unsignedInt128)
                #expect(uint128 == unsignedInt128_2)
            }

            do {
                let uint128 = lhs &>> rhs
                let unsignedInt128 = UnsignedInt128(lhs) &>> UnsignedInt128(rhs)
                let unsignedInt128_2 = UnsignedInt128(lhs) &>> rhs
                #expect(uint128 == unsignedInt128)
                #expect(uint128 == unsignedInt128_2)
            }

            do {
                var uint128 = lhs
                uint128 >>= rhs
                var unsignedInt128 = UnsignedInt128(lhs)
                unsignedInt128 >>= UnsignedInt128(rhs)
                var unsignedInt128_2 = UnsignedInt128(lhs)
                unsignedInt128_2 >>= rhs
                #expect(uint128 == unsignedInt128)
                #expect(uint128 == unsignedInt128_2)
            }

            do {
                var uint128 = lhs
                uint128 &>>= rhs
                var unsignedInt128 = UnsignedInt128(lhs)
                unsignedInt128 &>>= UnsignedInt128(rhs)
                var unsignedInt128_2 = UnsignedInt128(lhs)
                unsignedInt128_2 &>>= rhs
                #expect(uint128 == unsignedInt128)
                #expect(uint128 == unsignedInt128_2)
            }
        }
    }

    @available(swiftEndpointApplePlatforms 15, *)
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

    @available(swiftEndpointApplePlatforms 15, *)
    private func generateRandomUInt128s() -> some Sequence<UInt128> {
        let randomPairs: [UInt128] = (0..<10_000).map { _ in
            UInt128.random(in: .min ... .max)
        }
        let edgeCases: [UInt128] = [0, 1, .max - 1, .max]
        let result = randomPairs + edgeCases
        return result
    }

    @available(swiftEndpointApplePlatforms 15, *)
    private func generateRandomDoubles(
        randomCount: Int = 10_000
    ) -> some Sequence<Double> {
        let randomPairs: [Double] = (0..<randomCount).map { _ in
            Double.random(in: 0...20.1)
        }
        return randomPairs
    }
}
