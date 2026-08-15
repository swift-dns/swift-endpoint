import Endpoint
import NIOCore
import Testing

@Suite
struct DomainNameTests {
    @available(SwiftStdlib 5.1, *)
    @Test(
        arguments: [
            (domainName: "*", isFQDN: false, data: ByteBuffer([1, 42])),
            (domainName: ".", isFQDN: true, data: ByteBuffer([])),
            (domainName: "\u{3002}", isFQDN: true, data: ByteBuffer([])),
            (domainName: "\u{FF0E}", isFQDN: true, data: ByteBuffer([])),
            (domainName: "\u{FF61}", isFQDN: true, data: ByteBuffer([])),
            (domainName: "a", isFQDN: false, data: ByteBuffer([1, 97])),
            (domainName: "ab\u{3002}", isFQDN: true, data: ByteBuffer([2, 97, 98])),
            (domainName: "ab\u{FF0E}", isFQDN: true, data: ByteBuffer([2, 97, 98])),
            (domainName: "ab\u{FF61}", isFQDN: true, data: ByteBuffer([2, 97, 98])),
            (domainName: "*.b", isFQDN: false, data: ByteBuffer([1, 42, 1, 98])),
            (domainName: "a.b", isFQDN: false, data: ByteBuffer([1, 97, 1, 98])),
            (domainName: "*.b.c", isFQDN: false, data: ByteBuffer([1, 42, 1, 98, 1, 99])),
            (domainName: "*.b.c.", isFQDN: true, data: ByteBuffer([1, 42, 1, 98, 1, 99])),
            (domainName: "a.b.c", isFQDN: false, data: ByteBuffer([1, 97, 1, 98, 1, 99])),
            (domainName: "a.b.c.", isFQDN: true, data: ByteBuffer([1, 97, 1, 98, 1, 99])),
            (
                domainName: "Mijia Cloud",
                isFQDN: false,
                data: ByteBuffer([
                    11, 109, 105, 106, 105, 97, 32, 99, 108, 111, 117, 100,
                ])
            ),
            (
                domainName: "_25._tcp.mail.example.com",
                isFQDN: false,
                data: ByteBuffer([
                    3, 95, 50, 53,
                    4, 95, 116, 99, 112,
                    4, 109, 97, 105, 108,
                    7, 101, 120, 97, 109, 112, 108, 101,
                    3, 99, 111, 109,
                ])
            ),
            (
                domainName: "helloß.co.uk.",
                isFQDN: true,
                data: ByteBuffer([
                    13, 120, 110, 45, 45, 104, 101, 108, 108, 111, 45, 112, 113, 97,
                    2, 99, 111, 2, 117, 107,
                ])
            ),
            (
                domainName: "helloß.co.uk",
                isFQDN: false,
                data: ByteBuffer([
                    13, 120, 110, 45, 45, 104, 101, 108, 108, 111, 45, 112, 113, 97,
                    2, 99, 111, 2, 117, 107,
                ])
            ),
        ]
    )
    func initFromString(domainName: String, isFQDN: Bool, data: ByteBuffer) throws {
        do {
            let domainName = try DomainName(domainName)
            #expect(domainName.isFQDN == isFQDN)
            #expect(domainName._data == data)
        }

        do {
            let string = "dasda" + domainName + "sddsd"
            let substring: Substring = string.dropFirst(5).dropLast(5)
            let domainName = try DomainName(substring)
            #expect(domainName.isFQDN == isFQDN)
            #expect(domainName._data == data)
        }

        if #available(SwiftStdlib 6.2, *) {
            let domainName = try DomainName(textualRepresentation: domainName.utf8Span)
            #expect(domainName.isFQDN == isFQDN)
            #expect(domainName._data == data)
        }
    }

    @Test(
        arguments: [
            ".mahdibm.com",
            "",
            "\(Array(repeating: "j", count: 64).joined()).example.com.",
            "s\(Array(repeating: "]", count: 61).joined())s.example.com.",
            "\(Array(repeating: Array(repeating: "j", count: 63).joined(), count: 4).joined(separator: ".")).com",
            "..",
            "...",
            "....",
            ".........",
            "a\u{3002}\u{3002}",
            "a\u{3002}.",
        ]
    )
    func initInvalidFromString(domainName: String) throws {
        #expect(throws: DomainName.ValidationError.self) {
            try DomainName(domainName)
        }
        #expect(throws: DomainName.ValidationError.self) {
            try DomainName(Substring(domainName))
        }
        if #available(SwiftStdlib 6.2, *) {
            #expect(throws: DomainName.ValidationError.self) {
                try DomainName(textualRepresentation: domainName.utf8Span)
            }
        }
    }

    @available(SwiftStdlib 5.1, *)
    @Test(
        arguments: [
            (
                ascii: "royale.mahdibm.com.",
                unicode: "royale.mahdibm.com.",
                asciiNoRootLabel: "royale.mahdibm.com",
                unicodeNoRootLabel: "royale.mahdibm.com",
            ),
            (
                ascii: "xn--1lq90ic7f1rc.cn",
                unicode: "\u{5317}\u{4eac}\u{5927}\u{5b78}.cn",
                asciiNoRootLabel: "xn--1lq90ic7f1rc.cn",
                unicodeNoRootLabel: "\u{5317}\u{4eac}\u{5927}\u{5b78}.cn",
            ),
            (
                ascii: "xn--36c-tfa.com",
                unicode: "36°c.com",
                asciiNoRootLabel: "xn--36c-tfa.com",
                unicodeNoRootLabel: "36°c.com"
            ),
            (
                ascii: "www.xn--hello-pqa.co.uk.",
                unicode: "www.helloß.co.uk.",
                asciiNoRootLabel: "www.xn--hello-pqa.co.uk",
                unicodeNoRootLabel: "www.helloß.co.uk"
            ),
        ]
    )
    func description(
        ascii: String,
        unicode: String,
        asciiNoRootLabel: String,
        unicodeNoRootLabel: String
    ) throws {
        let domainName = try DomainName(unicode)
        let asciiWithBadChars = "112dasda" + ascii + "sdds231d4t"
        let asciiSubstring: Substring = asciiWithBadChars.dropFirst(8).dropLast(10)
        let nameASCII = try DomainName(asciiSubstring)

        /// If the names are the same then we don't need to compare their descriptions
        #expect(domainName == nameASCII)

        #expect(domainName.description == unicodeNoRootLabel)
        #expect(
            domainName.description(format: .unicode)
                == unicodeNoRootLabel
        )

        #expect(domainName.debugDescription == ascii)
        #expect(
            domainName.description(format: .ascii, options: .includeRootLabelIndicator)
                == ascii
        )

        #expect(
            domainName.description(format: .unicode, options: .includeRootLabelIndicator)
                == unicode
        )
        #expect(
            domainName.description(format: .ascii)
                == asciiNoRootLabel
        )
    }

    @available(SwiftStdlib 5.1, *)
    @Test func equalityWhichMustBeCaseInsensitive() throws {
        let domainName = try DomainName("example.com.")
        let duplicate = try DomainName("example.com.")
        let uppercased = try DomainName("EXAMPLE.COM.")
        let partiallyUppercased = try DomainName("exaMple.com.")
        let notFQDN = try DomainName("example.com")
        let letterMismatch = try DomainName("exmmple.com.")
        let bordersMismatch = try DomainName("example.com.com.")
        let different = try DomainName("mahdibm.com.")
        let differentNotFQDN = try DomainName("mahdibm.com")

        #expect(domainName == duplicate)
        #expect(domainName.isExactlyEqual(to: duplicate))
        #expect(domainName == uppercased)
        #expect(domainName == partiallyUppercased)
        #expect(domainName == notFQDN)
        #expect(!domainName.isExactlyEqual(to: notFQDN))
        #expect(domainName != letterMismatch)
        #expect(domainName != bordersMismatch)
        #expect(domainName != different)
        #expect(domainName != differentNotFQDN)

        let weirdUnicodeLowercaseDomain = try DomainName("helloß.co.uk.")
        let weirdUnicodeLowercaseDomainASCII = try DomainName("xn--hello-pqa.co.uk")
        let weirdPartiallyUppercaseDomain = try DomainName("helloSS.co.uk")
        let weirdUppercaseDomain = try DomainName("HELLOSS.CO.UK.")

        /// The DomainName initializers turn non-ascii domain names to IDNA-encoded domain names.
        /// `ß` and `SS` are case-insensitively equal, so with no IDNA these 2 names would be equal.
        #expect(weirdUnicodeLowercaseDomain == weirdUnicodeLowercaseDomainASCII)
        #expect(weirdUnicodeLowercaseDomain != weirdPartiallyUppercaseDomain)
        #expect(weirdUnicodeLowercaseDomain != weirdUppercaseDomain)
        #expect(weirdPartiallyUppercaseDomain == weirdUppercaseDomain)

        /// Hashing must be consistent with `==`, which ignores the FQDN flag.
        #expect(domainName.hashValue == duplicate.hashValue)
        #expect(domainName.hashValue == uppercased.hashValue)
        #expect(domainName.hashValue == notFQDN.hashValue)
        #expect(Set([domainName, duplicate, uppercased, notFQDN]).count == 1)
    }

    @available(SwiftStdlib 5.1, *)
    @Test func isRoot() throws {
        #expect(DomainName.root.isRoot)
        #expect(try DomainName(".").isRoot)
        #expect(try !DomainName("ab.").isRoot)
        #expect(try !DomainName("ab").isRoot)
    }

    @available(SwiftStdlib 5.1, *)
    @Test(
        arguments: [
            (domainName: ".", isFQDN: true),
            (domainName: "www.example.com.", isFQDN: true),
            (domainName: "www.example", isFQDN: false),
            (domainName: "www", isFQDN: false),
            (domainName: "test.", isFQDN: true),
            (domainName: "_25._tcp.mail.example.com", isFQDN: false),
        ]
    )
    func `fqdnParsing`(domainName: String, isFQDN: Bool) throws {
        try #expect(DomainName(domainName).isFQDN == isFQDN)
    }

    @Test(
        arguments: [
            ".",
            "www.example.com.",
            "www.example",
            "www",
            "test.",
            "\(Array(repeating: "j", count: 63).joined()).example.com.",
        ]
    )
    func `parsing then as string works as expected`(domainName: String) throws {
        #expect(
            try DomainName(domainName).description(
                format: .unicode,
                options: .includeRootLabelIndicator
            ) == domainName
        )
    }

    @available(SwiftStdlib 5.1, *)
    @Test func `description falls back to ascii when IDNA to-unicode conversion fails`() {
        let label: [UInt8] = Array("xn--999999999".utf8)
        let domainName = DomainName(
            isFQDN: false,
            _uncheckedAssumingValidWireFormatBytes: ByteBuffer([UInt8(label.count)] + label)
        )
        #expect(domainName.description(format: .unicode) == "xn--999999999")
    }

    @Test(
        arguments: [
            /// _ _should_ only be at the start of a label, but we tolerate it anywhere.
            "_25._tc😅_p.mail.example.com",
            "_25._tc_p.mail.example.com",
            /// * _should_ only be 1 at the start of the first label, but we tolerate it anywhere and in any amounts.
            "*😅*.mahdibm.com",
            "**.mahdibm.com",
            /// * _should usually_ only be at the start of the first label, but we tolerate it anywhere.
            "*.*.😅example.com",
            "*.*.example.com",
        ]
    )
    func `parsing works`(domainName: String) throws {
        #expect(throws: Never.self) {
            try DomainName(domainName)
        }
    }

    @Test(
        arguments: [
            (domainName: "*", expectedLabelsCount: 1),
            (domainName: "a", expectedLabelsCount: 1),
            (domainName: "*.b", expectedLabelsCount: 2),
            (domainName: "a.b", expectedLabelsCount: 2),
            (domainName: "*.b.c", expectedLabelsCount: 3),
            (domainName: "*.*.c", expectedLabelsCount: 3),
            (domainName: "a.b.c", expectedLabelsCount: 3),
        ]
    )
    func `number of labels`(domainName: String, expectedLabelsCount: Int) throws {
        try #expect(DomainName(domainName).labelsCount == expectedLabelsCount)
    }

    @Test(
        arguments: [
            (domainName: ".", isWildcard: false),
            (domainName: "*", isWildcard: true),
            (domainName: "a", isWildcard: false),
            (domainName: "*.b", isWildcard: true),
            (domainName: "a.b", isWildcard: false),
            (domainName: "*.b.c", isWildcard: true),
            (domainName: "*.*.c", isWildcard: true),
            (domainName: "a.b.c", isWildcard: false),
        ]
    )
    func `is wildcard`(domainName: String, isWildcard: Bool) throws {
        try #expect(DomainName(domainName).isWildcard == isWildcard)
    }

    @Test(
        arguments: [
            (domainName: "a", labels: [ByteBuffer([97])]),
            (domainName: "*.b", labels: [ByteBuffer([42]), ByteBuffer([98])]),
            (domainName: "a.b.c", labels: [ByteBuffer([97]), ByteBuffer([98]), ByteBuffer([99])]),
            (
                domainName: "_25._tcp.mail.example.com",
                labels: [
                    ByteBuffer([95, 50, 53]),
                    ByteBuffer([95, 116, 99, 112]),
                    ByteBuffer([109, 97, 105, 108]),
                    ByteBuffer([101, 120, 97, 109, 112, 108, 101]),
                    ByteBuffer([99, 111, 109]),
                ]
            ),
        ]
    )
    func `iterating yields the expected labels`(domainName: String, labels: [ByteBuffer]) throws {
        let domainName = try DomainName(domainName)
        #expect(domainName.map(\._data) == labels)
        #expect(domainName.labelsCount == labels.count)
    }

    @available(SwiftStdlib 5.1, *)
    @Test(
        arguments: [
            (ascii: "mahdibm", unicode: "mahdibm"),
            (ascii: "co", unicode: "co"),
            (ascii: "xn--hello-pqa", unicode: "helloß"),
            (ascii: "xn--1lq90ic7f1rc", unicode: "\u{5317}\u{4eac}\u{5927}\u{5b78}"),
            (ascii: "xn--36c-tfa", unicode: "36°c"),
        ]
    )
    func `label description`(ascii: String, unicode: String) throws {
        let label = try #require(Array(try DomainName(ascii)).first)
        #expect(label.debugDescription == ascii)
        #expect(label.description(format: .ascii) == ascii)
        #expect(label.description == unicode)
        #expect(label.description(format: .unicode) == unicode)
    }

    @Test(
        arguments: [
            (lhs: "a", rhs: "a", areEqual: true),
            (lhs: "mahdibm", rhs: "mahdibm", areEqual: true),
            (lhs: "a", rhs: "b", areEqual: false),
            (lhs: "co", rhs: "uk", areEqual: false),
        ]
    )
    func `label equality`(lhs: String, rhs: String, areEqual: Bool) throws {
        let lhsLabel = try #require(Array(try DomainName(lhs)).first)
        let rhsLabel = try #require(Array(try DomainName(rhs)).first)
        #expect((lhsLabel == rhsLabel) == areEqual)
    }

    @available(SwiftStdlib 5.1, *)
    @Test func ipv4AddressToName() throws {
        let ipAddress = IPv4Address(192, 168, 1, 1)
        let name1 = DomainName(ipv4: ipAddress, format: .arpa)
        let name2 = DomainName(ip: .v4(ipAddress))
        let expectedDescription = "1.1.168.192.in-addr.arpa."
        #expect(name1.debugDescription == expectedDescription)
        #expect(name2.debugDescription == expectedDescription)

        let name1InDottedQuad = DomainName(ipv4: ipAddress, format: .dottedQuad)
        #expect(name1InDottedQuad.debugDescription == "192.168.1.1.")
    }

    /// `255.255.255.255` in particular fills the dotted-quad buffer exactly.
    @available(SwiftStdlib 5.1, *)
    @Test func `ipv4 name is correct for every octet value`() {
        for octet in (UInt8(0)...UInt8(255)) {
            let ipAddress = IPv4Address(octet, octet, octet, octet)
            let dottedQuad = String(repeating: "\(octet).", count: 4)

            #expect(
                DomainName(ipv4: ipAddress, format: .dottedQuad).debugDescription == dottedQuad,
                "octet: \(octet)"
            )
            #expect(
                DomainName(ipv4: ipAddress, format: .arpa).debugDescription
                    == dottedQuad + "in-addr.arpa.",
                "octet: \(octet)"
            )
        }
    }

    @Test func `isAcceptableDomainNameCharacter is correct for every byte`() {
        for byte in (UInt8(0)...UInt8(255)) {
            let expected =
                (byte >= 0x61 && byte <= 0x7A)
                || (byte >= 0x30 && byte <= 0x39)
                || byte == 0x2D
                || byte == 0x5F
                || byte == 0x2A
                || byte == 0x20
            #expect(byte.isAcceptableDomainNameCharacter == expected, "byte: \(byte)")
        }
    }

    @available(SwiftStdlib 6.0, *)
    @Test func `ipv6 arpa name is correct for every address byte`() {
        let hexDigits = Array("0123456789abcdef")
        for byte in (UInt8(0)...UInt8(255)) {
            let ipAddress = IPv6Address(
                byte,
                byte,
                byte,
                byte,
                byte,
                byte,
                byte,
                byte,
                byte,
                byte,
                byte,
                byte,
                byte,
                byte,
                byte,
                byte
            )
            let low = hexDigits[Int(byte & 0x0F)]
            let high = hexDigits[Int(byte >> 4)]
            let expectedDescription =
                String(repeating: "\(low).\(high).", count: 16) + "ip6.arpa."
            #expect(
                DomainName(ipv6: ipAddress).debugDescription == expectedDescription,
                "byte: \(byte)"
            )
        }
    }

    @available(SwiftStdlib 6.0, *)
    @Test func ipv6AddressToName() {
        let ipAddress: IPv6Address = 0x2a01_5cc0_0001_0002_0000_0000_0000_0004
        let name1 = DomainName(ipv6: ipAddress)
        let name2 = DomainName(ip: .v6(ipAddress))
        let expectedDescription =
            "4.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.2.0.0.0.1.0.0.0.0.c.c.5.1.0.a.2.ip6.arpa."
        #expect(name1.debugDescription == expectedDescription)
        #expect(name2.debugDescription == expectedDescription)
    }

    @Test func isSubdomain() throws {
        let name1 = try DomainName("example.com")
        let name2 = try DomainName("www.example.com")
        let name3 = try DomainName("example.com.com")
        let name4 = try DomainName("www.example.com.com")

        #expect(!name1.isSubdomain(of: name2))
        #expect(!name1.isSubdomain(of: name3))
        #expect(!name1.isSubdomain(of: name4))
        #expect(!name2.isSubdomain(of: name4))
        #expect(!name3.isSubdomain(of: name4))

        #expect(name2.isSubdomain(of: name1))
        #expect(!name3.isSubdomain(of: name1))
        #expect(!name4.isSubdomain(of: name1))
        #expect(!name4.isSubdomain(of: name2))
        #expect(name4.isSubdomain(of: name3))

        #expect(!name1.isStrictSubdomain(of: name2))
        #expect(!name1.isStrictSubdomain(of: name3))
        #expect(!name1.isStrictSubdomain(of: name4))
        #expect(!name2.isStrictSubdomain(of: name4))
        #expect(!name3.isStrictSubdomain(of: name4))

        #expect(name2.isStrictSubdomain(of: name1))
        #expect(!name3.isStrictSubdomain(of: name1))
        #expect(!name4.isStrictSubdomain(of: name1))
        #expect(!name4.isStrictSubdomain(of: name2))
        #expect(name4.isStrictSubdomain(of: name3))

        #expect(name1.isSubdomain(of: name1))
        #expect(name2.isSubdomain(of: name2))
        #expect(name3.isSubdomain(of: name3))
        #expect(name4.isSubdomain(of: name4))

        #expect(!name1.isStrictSubdomain(of: name1))
        #expect(!name2.isStrictSubdomain(of: name2))
        #expect(!name3.isStrictSubdomain(of: name3))
        #expect(!name4.isStrictSubdomain(of: name4))

        /// Mark: - name5 (wildcard domain name)
        let name5 = try DomainName("*.example.com")
        let name6 = try DomainName("some.thing.example.com")
        let name7 = try DomainName("*.thing.example.com")

        #expect(!name1.isSubdomain(of: name5))
        #expect(name2.isSubdomain(of: name5))
        #expect(!name3.isSubdomain(of: name5))
        #expect(!name4.isSubdomain(of: name5))
        #expect(name5.isSubdomain(of: name5))
        #expect(!name6.isSubdomain(of: name5))
        #expect(!name7.isSubdomain(of: name5))

        #expect(name5.isSubdomain(of: name1))
        #expect(!name5.isSubdomain(of: name2))
        #expect(!name5.isSubdomain(of: name3))
        #expect(!name5.isSubdomain(of: name4))
        #expect(!name5.isSubdomain(of: name6))
        #expect(!name5.isSubdomain(of: name7))

        #expect(!name1.isStrictSubdomain(of: name5))
        #expect(name2.isStrictSubdomain(of: name5))
        #expect(!name3.isStrictSubdomain(of: name5))
        #expect(!name4.isStrictSubdomain(of: name5))
        #expect(!name5.isStrictSubdomain(of: name5))
        #expect(!name6.isStrictSubdomain(of: name5))
        #expect(!name7.isStrictSubdomain(of: name5))

        #expect(name5.isStrictSubdomain(of: name1))
        #expect(!name5.isStrictSubdomain(of: name2))
        #expect(!name5.isStrictSubdomain(of: name3))
        #expect(!name5.isStrictSubdomain(of: name4))
        #expect(!name5.isStrictSubdomain(of: name6))
        #expect(!name5.isStrictSubdomain(of: name7))

        #expect(name6.isSubdomain(of: name7))
        #expect(!name7.isSubdomain(of: name6))
        #expect(name6.isStrictSubdomain(of: name7))
        #expect(!name7.isStrictSubdomain(of: name6))
    }

    @Test func isSuperdomain() throws {
        let name1 = try DomainName("example.com")
        let name2 = try DomainName("www.example.com")
        let name3 = try DomainName("example.com.com")
        let name4 = try DomainName("www.example.com.com")

        #expect(!name2.isSuperdomain(of: name1))
        #expect(!name3.isSuperdomain(of: name1))
        #expect(!name4.isSuperdomain(of: name1))
        #expect(!name4.isSuperdomain(of: name2))
        #expect(!name4.isSuperdomain(of: name3))

        #expect(name1.isSuperdomain(of: name2))
        #expect(!name1.isSuperdomain(of: name3))
        #expect(!name1.isSuperdomain(of: name4))
        #expect(!name2.isSuperdomain(of: name4))
        #expect(name3.isSuperdomain(of: name4))

        #expect(!name2.isStrictSuperdomain(of: name1))
        #expect(!name3.isStrictSuperdomain(of: name1))
        #expect(!name4.isStrictSuperdomain(of: name1))
        #expect(!name4.isStrictSuperdomain(of: name2))
        #expect(!name4.isStrictSuperdomain(of: name3))

        #expect(name1.isStrictSuperdomain(of: name2))
        #expect(!name1.isStrictSuperdomain(of: name3))
        #expect(!name1.isStrictSuperdomain(of: name4))
        #expect(!name2.isStrictSuperdomain(of: name4))
        #expect(name3.isStrictSuperdomain(of: name4))

        #expect(name1.isSuperdomain(of: name1))
        #expect(name2.isSuperdomain(of: name2))
        #expect(name3.isSuperdomain(of: name3))
        #expect(name4.isSuperdomain(of: name4))

        #expect(!name1.isStrictSuperdomain(of: name1))
        #expect(!name2.isStrictSuperdomain(of: name2))
        #expect(!name3.isStrictSuperdomain(of: name3))
        #expect(!name4.isStrictSuperdomain(of: name4))

        /// Mark: - name5 (wildcard domain name)
        let name5 = try DomainName("*.example.com")
        let name6 = try DomainName("some.thing.example.com")
        let name7 = try DomainName("*.thing.example.com")

        #expect(!name5.isSuperdomain(of: name1))
        #expect(name5.isSuperdomain(of: name2))
        #expect(!name5.isSuperdomain(of: name3))
        #expect(!name5.isSuperdomain(of: name4))
        #expect(name5.isSuperdomain(of: name5))
        #expect(!name5.isSuperdomain(of: name6))
        #expect(!name5.isSuperdomain(of: name7))

        #expect(name1.isSuperdomain(of: name5))
        #expect(!name2.isSuperdomain(of: name5))
        #expect(!name3.isSuperdomain(of: name5))
        #expect(!name4.isSuperdomain(of: name5))
        #expect(!name6.isSuperdomain(of: name5))
        #expect(!name7.isSuperdomain(of: name5))

        #expect(name1.isStrictSuperdomain(of: name5))
        #expect(!name2.isStrictSuperdomain(of: name5))
        #expect(!name3.isStrictSuperdomain(of: name5))
        #expect(!name4.isStrictSuperdomain(of: name5))
        #expect(!name5.isStrictSuperdomain(of: name5))
        #expect(!name6.isStrictSuperdomain(of: name5))
        #expect(!name7.isStrictSuperdomain(of: name5))

        #expect(!name5.isStrictSuperdomain(of: name1))
        #expect(name5.isStrictSuperdomain(of: name2))
        #expect(!name5.isStrictSuperdomain(of: name3))
        #expect(!name5.isStrictSuperdomain(of: name4))
        #expect(!name5.isStrictSuperdomain(of: name6))
        #expect(!name5.isStrictSuperdomain(of: name7))

        #expect(!name6.isSuperdomain(of: name7))
        #expect(name7.isSuperdomain(of: name6))
        #expect(!name6.isStrictSuperdomain(of: name7))
        #expect(name7.isStrictSuperdomain(of: name6))
    }

    /// The file pointing to `Resources.topDomains` contains only 200 top domains, but you can
    /// try bigger files too.
    /// For example you can manually go to cloudflare radar (https://radar.cloudflare.com/domains)
    /// and download the top 1 million domains csv file (or really top any-number, just csv).
    /// Just make sure the download file is only 1 column (so only a new domain on each new line).
    /// Then put it in Tests/Resources/ directory named exactly as `top-domains.csv`.
    /// And untrack the file so it's not committed to git (it's 14+ MiB).
    /// The file is 14+ MiB in size so it's not included in the repo.
    ///
    /// Not using swift-testing arguments because that slows things down significantly if we're
    /// testing against 1 million domains.
    @Test func testAgainstTopCloudflareRadarDomains() throws {
        for (index, domainNameString) in enumeratedTopDomains() {
            let comment: Comment = "index: \(index), domainName: \(domainNameString)"
            #expect(throws: Never.self, comment) {
                let domainName = try DomainName(domainNameString)
                let recreatedDomainName = domainName.description(
                    format: .ascii,
                    options: .includeRootLabelIndicator
                )
                #expect(recreatedDomainName == domainNameString, comment)
            }
        }
    }
}

private func enumeratedTopDomains() -> EnumeratedSequence<[String]> {
    String(
        decoding: Resources.topDomains.data(),
        as: UTF8.self
    ).split(
        whereSeparator: \.isNewline
    )
    .dropFirst()
    .map(String.init)
    .enumerated()
}

#if os(macOS) || os(Linux)
#if DEBUG
extension DomainNameTests {
    @available(SwiftStdlib 5.1, *)
    @Test func `Label unchecked initializer crashes on empty bytes in debug builds`() async {
        await #expect(processExitsWith: .failure) {
            _ = DomainName.Label(_uncheckedAssumingValidBytes: ByteBuffer())
        }
    }

    @available(SwiftStdlib 5.1, *)
    @Test func `Label unchecked initializer crashes on too-long bytes in debug builds`() async {
        await #expect(processExitsWith: .failure) {
            _ = DomainName.Label(
                _uncheckedAssumingValidBytes: ByteBuffer(bytes: [UInt8](repeating: 0x61, count: 64))
            )
        }
    }

    @available(SwiftStdlib 5.1, *)
    @Test func `Label unchecked initializer crashes on invalid bytes in debug builds`() async {
        await #expect(processExitsWith: .failure) {
            _ = DomainName.Label(_uncheckedAssumingValidBytes: ByteBuffer([65]))
        }
    }

    @available(SwiftStdlib 5.1, *)
    @Test func `DomainName unchecked initializer crashes on invalid label bytes in debug builds`()
        async
    {
        await #expect(processExitsWith: .failure) {
            _ = DomainName(_uncheckedAssumingValidWireFormatBytes: ByteBuffer([1, 65]))
        }
    }

    @available(SwiftStdlib 5.1, *)
    @Test func `DomainName unchecked initializer crashes on too-long labels in debug builds`() async
    {
        await #expect(processExitsWith: .failure) {
            _ = DomainName(
                _uncheckedAssumingValidWireFormatBytes: ByteBuffer(
                    bytes: [64] + [UInt8](repeating: 0x61, count: 64)
                )
            )
        }
    }
}
#endif
#endif
