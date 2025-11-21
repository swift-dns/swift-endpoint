import IPAddress
import Testing

@Suite
struct UnsignedInt128Tests {
    // @available(swiftEndpointApplePlatforms 15, *)
    // func `test isSigned against UInt128`() {
    //     #expect(UInt128.isSigned == UnsignedInt128.isSigned)
    // }

    // @available(swiftEndpointApplePlatforms 15, *)
    // @Test(arguments: generateRandomUInt128Pairs())
    // func `test bitWidth against UInt128`(lhs: UInt128, _: UInt128) {
    //     let uint128 = lhs.bitWidth
    //     let unsignedInt128 = UnsignedInt128(lhs).bitWidth
    //     #expect(uint128 == unsignedInt128)
    // }

    // @available(swiftEndpointApplePlatforms 15, *)
    // @Test(arguments: generateRandomUInt128Pairs())
    // func `test trailingZeroBitCount against UInt128`(lhs: UInt128, _: UInt128) {
    //     let uint128 = lhs.trailingZeroBitCount
    //     let unsignedInt128 = UnsignedInt128(lhs).trailingZeroBitCount
    //     #expect(uint128 == unsignedInt128)
    // }

    // @available(swiftEndpointApplePlatforms 15, *)
    // @Test(arguments: generateRandomUInt128Pairs())
    // func `test / against UInt128`(lhs: UInt128, rhs: UInt128) {
    //     let uint128 = lhs / rhs
    //     let unsignedInt128 = UnsignedInt128(lhs) / UnsignedInt128(rhs)
    //     #expect(uint128 == unsignedInt128)
    // }

    // @available(swiftEndpointApplePlatforms 15, *)
    // @Test(arguments: generateRandomUInt128Pairs())
    // func `test % against UInt128`(lhs: UInt128, rhs: UInt128) {
    //     let uint128 = lhs % rhs
    //     let unsignedInt128 = UnsignedInt128(lhs) % UnsignedInt128(rhs)
    //     #expect(uint128 == unsignedInt128)
    // }

    // @available(swiftEndpointApplePlatforms 15, *)
    // @Test(arguments: generateRandomUInt128Pairs())
    // func `test %= against UInt128`(lhs: UInt128, rhs: UInt128) {
    //     var uint128 = lhs
    //     uint128 %= rhs
    //     var unsignedInt128 = UnsignedInt128(lhs)
    //     unsignedInt128 %= UnsignedInt128(rhs)
    //     #expect(uint128 == unsignedInt128)
    // }

    // @available(swiftEndpointApplePlatforms 15, *)
    // @Test(arguments: generateRandomUInt128Pairs())
    // func `test * against UInt128`(lhs: UInt128, rhs: UInt128) {
    //     let uint128 = lhs % rhs
    //     let unsignedInt128 = UnsignedInt128(lhs) % UnsignedInt128(rhs)
    //     #expect(uint128 == unsignedInt128)
    // }

    // @available(swiftEndpointApplePlatforms 15, *)
    // @Test(arguments: generateRandomUInt128Pairs())
    // func `test &= against UInt128`(lhs: UInt128, rhs: UInt128) {
    //     let uint128 = lhs % rhs
    //     let unsignedInt128 = UnsignedInt128(lhs) % UnsignedInt128(rhs)
    //     #expect(uint128 == unsignedInt128)
    // }

    // @available(swiftEndpointApplePlatforms 15, *)
    // @Test(arguments: generateRandomUInt128Pairs())
    // func `test |= against UInt128`(lhs: UInt128, rhs: UInt128) {
    //     var uint128 = lhs
    //     uint128 |= rhs
    //     var unsignedInt128 = UnsignedInt128(lhs)
    //     unsignedInt128 |= UnsignedInt128(rhs)
    //     #expect(uint128 == unsignedInt128)
    // }

    // @available(swiftEndpointApplePlatforms 15, *)
    // @Test(arguments: generateRandomUInt128Pairs())
    // func `test ^= against UInt128`(lhs: UInt128, rhs: UInt128) {
    //     var uint128 = lhs
    //     uint128 ^= rhs
    //     var unsignedInt128 = UnsignedInt128(lhs)
    //     unsignedInt128 ^= UnsignedInt128(rhs)
    //     #expect(uint128 == unsignedInt128)
    // }

    // @available(swiftEndpointApplePlatforms 15, *)
    // @Test(arguments: generateRandomUInt128Pairs())
    // func `test magnitude against UInt128`(lhs: UInt128, _: UInt128) {
    //     let uint128 = lhs.magnitude
    //     let unsignedInt128 = UnsignedInt128(lhs).magnitude
    //     #expect(uint128 == unsignedInt128)
    // }

    @available(swiftEndpointApplePlatforms 15, *)
    @Test func `test addition against UInt128`() {
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
    @Test func `test subtraction against UInt128`() {
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
    @Test(arguments: generateRandomUInt128Pairs())
    func `test init(_ description: String) against UInt128`(lhs: UInt128, rhs: UInt128) throws {
        // let utf8 = Array(lhs.description.utf8)
        // guard utf8.count < 20 || utf8[20] < 2 else {
        //     return
        // }
        let uint128 = try #require(UInt128(lhs.description))
        let unsignedInt128 = try #require(UnsignedInt128(lhs.description))
        // let uint128Bits = String(uint128, radix: 2)
        // let unsignedInt128Bits = String(unsignedInt128._high, radix: 2) + String(unsignedInt128._low, radix: 2)
        let uint128Bits = String(uint128._low, radix: 2)
        let unsignedInt128Bits = String(unsignedInt128._low, radix: 2)
        #expect(uint128Bits == unsignedInt128Bits, "\(uint128Bits)\n\(unsignedInt128Bits)")
        #expect(uint128 == lhs)
    }
}

@available(swiftEndpointApplePlatforms 15, *)
private func generateRandomUInt128Pairs() -> [(UInt128, UInt128)] {
    (0..<100_000).map { _ in (UInt128.random(in: .min ... .max), UInt128.random(in: .min ... .max))
    }
}
