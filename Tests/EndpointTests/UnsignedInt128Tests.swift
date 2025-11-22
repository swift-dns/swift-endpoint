import IPAddress
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
    @Test func `verify init(_:) against UInt128`() {
        for (lhs, _) in generateRandomUInt128Pairs() {
            let uint128 = UInt128(lhs)
            let unsignedInt128 = UnsignedInt128(lhs)
            #expect(uint128._low == unsignedInt128._low)
            #expect(uint128._high == unsignedInt128._high)
        }
    }

    @available(swiftEndpointApplePlatforms 15, *)
    @Test func `verify equality-operator against UInt128`() {
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
        for (lhs, _) in generateRandomUInt128Pairs() {
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
                #expect(uint128 == unsignedInt128)
            }

            do {
                let uint128 = lhs << rhs
                let unsignedInt128 = UnsignedInt128(lhs) << UnsignedInt128(rhs)
                #expect(uint128 == unsignedInt128)
            }

            do {
                var uint128 = lhs
                uint128 <<= rhs
                var unsignedInt128 = UnsignedInt128(lhs)
                unsignedInt128 <<= UnsignedInt128(rhs)
                #expect(uint128 == unsignedInt128)
            }

            do {
                var uint128 = lhs
                uint128 &<<= rhs
                var unsignedInt128 = UnsignedInt128(lhs)
                unsignedInt128 &<<= UnsignedInt128(rhs)
                #expect(uint128 == unsignedInt128)
            }
        }
    }

    @available(swiftEndpointApplePlatforms 15, *)
    @Test func `verify right bit-shift against UInt128`() {
        for (lhs, rhs) in generateRandomUInt128Pairs() {
            do {
                let uint128 = lhs >> rhs
                let unsignedInt128 = UnsignedInt128(lhs) >> UnsignedInt128(rhs)
                #expect(uint128 == unsignedInt128)
            }

            do {
                let uint128 = lhs >> rhs
                let unsignedInt128 = UnsignedInt128(lhs) >> UnsignedInt128(rhs)
                #expect(uint128 == unsignedInt128)
            }

            do {
                var uint128 = lhs
                uint128 >>= rhs
                var unsignedInt128 = UnsignedInt128(lhs)
                unsignedInt128 >>= UnsignedInt128(rhs)
                #expect(uint128 == unsignedInt128)
            }

            do {
                var uint128 = lhs
                uint128 &>>= rhs
                var unsignedInt128 = UnsignedInt128(lhs)
                unsignedInt128 &>>= UnsignedInt128(rhs)
                #expect(uint128 == unsignedInt128)
            }
        }
    }

    @available(swiftEndpointApplePlatforms 15, *)
    @Test func `verify init(big/littleEndian:) against UInt128`() throws {
        for (lhs, _) in generateRandomUInt128Pairs() {
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
    @Test func `verify init(_ description: String) against UInt128`() throws {
        for (lhs, _) in generateRandomUInt128Pairs() {
            let uint128 = try #require(UInt128(lhs.description))
            let unsignedInt128 = try #require(UnsignedInt128(lhs.description))
            #expect(uint128 == unsignedInt128)
            #expect(uint128 == lhs)
        }
    }

    @available(swiftEndpointApplePlatforms 15, *)
    private func generateRandomUInt128Pairs(
        randomCount: Int = 1000
    ) -> some Sequence<(UInt128, UInt128)> {
        typealias UInt128Pair = (UInt128, UInt128)
        let randomPairs: [UInt128Pair] = (0..<randomCount).map { _ in
            (UInt128.random(in: .min ... .max), UInt128.random(in: .min ... .max))
        }
        let zeros1: [UInt128Pair] = (0..<100).map { _ in
            (0, UInt128.random(in: .min ... .max))
        }
        let zeros2: [UInt128Pair] = (0..<100).map { _ in
            (UInt128.random(in: .min ... .max), 0)
        }
        let zeros3: [UInt128Pair] = [(0, 0)]
        let edgeCases: [UInt128Pair] = [
            (0, .max), (.max, 0),
            (.max, .max),
            (.max, .max - 1), (.max - 1, .max),
            (1, .max), (.max, 1),
        ]
        let result = randomPairs + zeros1 + zeros2 + zeros3 + edgeCases
        return result
    }
}
