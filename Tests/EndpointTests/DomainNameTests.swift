import Endpoint
import NIOCore
import Testing

@Suite
struct DomainNameTests {
    @available(swiftEndpointApplePlatforms 10.15, *)
    @Test(
        arguments: [
            (domainName: "*", isFQDN: false, data: ByteBuffer([1, 42])),
            (domainName: ".", isFQDN: true, data: ByteBuffer([])),
            (domainName: "\u{3002}", isFQDN: true, data: ByteBuffer([])),
            (domainName: "a", isFQDN: false, data: ByteBuffer([1, 97])),
            (domainName: "*.b", isFQDN: false, data: ByteBuffer([1, 42, 1, 98])),
            (domainName: "a.b", isFQDN: false, data: ByteBuffer([1, 97, 1, 98])),
            (domainName: "*.b.c", isFQDN: false, data: ByteBuffer([1, 42, 1, 98, 1, 99])),
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
    }

    @Test(
        arguments: [
            ".mahdibm.com",
            "",
            "\(Array(repeating: "j", count: 64).joined()).example.com.",
            "s\(Array(repeating: "]", count: 61).joined())s.example.com.",
        ]
    )
    func initInvalidFromString(domainName: String) throws {
        #expect(throws: (any Error).self) {
            try DomainName(domainName)
        }
    }

    @available(swiftEndpointApplePlatforms 10.15, *)
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

    @available(swiftEndpointApplePlatforms 10.15, *)
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
    }

    @available(swiftEndpointApplePlatforms 10.15, *)
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
            (domainName: "*", expectedLabelsCount: 0),
            (domainName: "a", expectedLabelsCount: 1),
            (domainName: "*.b", expectedLabelsCount: 1),
            (domainName: "a.b", expectedLabelsCount: 2),
            (domainName: "*.b.c", expectedLabelsCount: 2),
            (domainName: "a.b.c", expectedLabelsCount: 3),
        ]
    )
    func `number of labels`(domainName: String, expectedLabelsCount: Int) throws {
        try #expect(DomainName(domainName).labelsCount == expectedLabelsCount)
    }

    @available(swiftEndpointApplePlatforms 10.15, *)
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

    @available(swiftEndpointApplePlatforms 15, *)
    @Test func ipv6AddressToName() {
        let ipAddress: IPv6Address = 0x2a01_5cc0_0001_0002_0000_0000_0000_0004
        let name1 = DomainName(ipv6: ipAddress)
        let name2 = DomainName(ip: .v6(ipAddress))
        let expectedDescription =
            "4.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.2.0.0.0.1.0.0.0.0.c.c.5.1.0.a.2.ip6.arpa."
        #expect(name1.debugDescription == expectedDescription)
        #expect(name2.debugDescription == expectedDescription)
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
