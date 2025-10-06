public import SwiftIDNA

public import struct NIOCore.ByteBuffer

@available(endpointApplePlatforms 13, *)
extension DomainName: CustomStringConvertible {
    /// Unicode-friendly description of the domain name, excluding the possible root label separator.
    @inlinable
    public var description: String {
        self.description(format: .unicode)
    }
}

@available(endpointApplePlatforms 13, *)
extension DomainName: CustomDebugStringConvertible {
    /// Source-accurate description of the domain name.
    @inlinable
    public var debugDescription: String {
        self.description(format: .ascii, options: .includeRootLabelIndicator)
    }
}

@available(endpointApplePlatforms 13, *)
extension DomainName {
    /// FIXME: public nonfrozen enum
    public enum DescriptionFormat: Sendable {
        /// ASCII-only description of the domain name, as in the wire format and IDNA.
        case ascii
        /// Unicode representation of the domain name, converting IDNA names to Unicode.
        case unicode
    }

    public struct DescriptionOptions: Sendable, OptionSet {
        public var rawValue: Int

        @inlinable
        public static var includeRootLabelIndicator: Self {
            Self(rawValue: 1 << 0)
        }

        public init(rawValue: Int) {
            self.rawValue = rawValue
        }
    }

    @inlinable
    public func description(
        format: DescriptionFormat,
        options: DescriptionOptions = []
    ) -> String {
        /// The needed capacity without the root label indicator
        let neededCapacity = self.encodedLength - 1
        var domainName = String(unsafeUninitializedCapacity: neededCapacity) { stringBuffer in
            var bufferIdx = 0

            self._data.withUnsafeReadableBytes { domainNamePtr in
                var iterator = self.makePositionIterator()
                if let (range, _) = iterator.nextRange() {
                    /// These are all ASCII bytes so safe to map directly
                    for idx in range {
                        stringBuffer[bufferIdx] = domainNamePtr[idx]
                        /// Can't possibly overflow since it can't be greater than the buffer size
                        bufferIdx &+= 1
                    }
                }

                while let (range, _) = iterator.nextRange() {
                    stringBuffer[bufferIdx] = .asciiDot
                    /// Can't possibly overflow since it can't be greater than the buffer size
                    bufferIdx &+= 1
                    /// These are all ASCII bytes so safe to map directly
                    for idx in range {
                        stringBuffer[bufferIdx] = domainNamePtr[idx]
                        /// Can't possibly overflow since it can't be greater than the buffer size
                        bufferIdx &+= 1
                    }
                }
            }

            return bufferIdx
        }

        if format == .unicode {
            let copy = domainName

            do {
                try IDNA(configuration: .mostLax)
                    .toUnicode(domainName: &domainName)
            } catch {
                domainName = copy
            }
        }

        if self.isFQDN,
            options.contains(.includeRootLabelIndicator)
        {
            domainName.append(".")
        }

        return domainName
    }
}

/// MARK: - Initializers from String

extension DomainName {
    /// FIXME: public non frozen enum?
    public enum ValidationError: Error {
        case domainNameMustBeASCII(ByteBuffer)
        case domainNameLengthLimitExceeded(actual: Int, max: Int, in: ByteBuffer)
        case labelLengthLimitExceeded(actual: Int, max: Int, in: ByteBuffer)
        case labelMustNotBeEmpty(in: ByteBuffer)
        case emptyDomainName
    }
}

@available(endpointApplePlatforms 13, *)
extension DomainName {
    /// Parses and case-folds the domainName from the string, and ensures the domainName is valid.
    /// Example: try DomainName("mahdibm.com")
    /// Converts the domain name to ASCII if it's not already, according to the IDNA spec.
    public init(_ description: String, idnaConfiguration: IDNA.Configuration = .default) throws {
        if #available(endpointApplePlatforms 26, *) {
            try self.init(
                macOS26_description: description,
                idnaConfiguration: idnaConfiguration
            )
        } else {
            try self.init(
                macOSLowerThan26_description: description,
                idnaConfiguration: idnaConfiguration
            )
        }
    }

    /// Parses and case-folds the domainName from the string, and ensures the domainName is valid.
    /// Example: try DomainName("mahdibm.com")
    /// Converts the domain name to ASCII if it's not already, according to the IDNA spec.
    public init(_ description: Substring, idnaConfiguration: IDNA.Configuration = .default) throws {
        if #available(endpointApplePlatforms 26, *) {
            try self.init(
                macOS26_description: description,
                idnaConfiguration: idnaConfiguration
            )
        } else {
            try self.init(
                macOSLowerThan26_description: String(description),
                idnaConfiguration: idnaConfiguration
            )
        }
    }

    /// Parses and case-folds the domainName from the string, and ensures the domainName is valid.
    /// Example: try DomainName("mahdibm.com")
    /// Converts the domain name to ASCII if it's not already, according to the IDNA spec.
    @inlinable
    init(
        macOSLowerThan26_description description: String,
        idnaConfiguration: IDNA.Configuration = .default
    ) throws {
        self.init()

        // short-circuit root parse
        if description.unicodeScalars.count == 1,
            description.unicodeScalars.first?.isIDNALabelSeparator == true
        {
            self.isFQDN = true
            return
        }

        var description = description

        /// Remove the trailing dot if it exists, and set the FQDN flag
        /// The IDNA spec doesn't like the root label separator.
        if description.unicodeScalars.last?.isIDNALabelSeparator == true {
            self.isFQDN = true
            description = String(description.unicodeScalars.dropLast())
        }

        /// TODO: make sure all initializations of DomainName go through a single initializer that
        /// asserts lowercased ASCII?

        /// short-circuits most domain names which won't change with IDNA anyway.
        try IDNA(
            configuration: idnaConfiguration
        ).toASCII(
            domainName: &description
        )

        self = try description.withUTF8 { utf8Ptr in
            try Self.init(
                __uncheckedValidatedDomainNameSpan: utf8Ptr.span,
                isFQDN: isFQDN
            )
        }
    }
}

@available(endpointApplePlatforms 26, *)
extension DomainName {
    @inlinable
    init(
        macOS26_description description: String,
        idnaConfiguration: IDNA.Configuration = .default
    ) throws {
        try self.init(
            textualRepresentation: description.utf8Span.span,
            idnaConfiguration: idnaConfiguration
        )
    }

    @inlinable
    init(
        macOS26_description description: Substring,
        idnaConfiguration: IDNA.Configuration = .default
    ) throws {
        try self.init(
            textualRepresentation: description.utf8Span.span,
            idnaConfiguration: idnaConfiguration
        )
    }

    /// Parses and case-folds the domainName from the string, and ensures the domainName is valid.
    /// Example: try DomainName(textualRepresentation: "mahdibm.com".utf8Span)
    /// Converts the domain name to ASCII if it's not already, according to the IDNA spec.
    @inlinable
    public init(
        textualRepresentation span: UTF8Span,
        idnaConfiguration: IDNA.Configuration = .default
    ) throws {
        try self.init(
            textualRepresentation: span.span,
            idnaConfiguration: idnaConfiguration
        )
    }

    /// Parses and case-folds the domainName from the string, and ensures the domainName is valid.
    /// Example: try DomainName(textualRepresentation: "mahdibm.com".utf8Span.span)
    /// Converts the domain name to ASCII if it's not already, according to the IDNA spec.
    @inlinable
    public init(
        textualRepresentation span: Span<UInt8>,
        idnaConfiguration: IDNA.Configuration = .default
    ) throws {
        var span = span
        var bytesCount = span.count
        var isFQDN = false

        guard bytesCount != 0 else {
            throw ValidationError.emptyDomainName
        }

        // short-circuit root parse
        switch bytesCount {
        case 1:
            if span[unchecked: 0].isIDNALabelSeparator {
                self = .root
                return
            }
        case 3:
            let first = span[unchecked: 0]
            let second = span[unchecked: 1]
            let third = span[unchecked: 2]
            /// U+FF0E ( ． ) FULLWIDTH FULL STOP
            /// U+3002 ( 。 ) IDEOGRAPHIC FULL STOP
            /// U+FF61 ( ｡ ) HALFWIDTH IDEOGRAPHIC FULL STOP
            if DomainName.isIDNALabelSeparator(first, second, third) {
                self = .root
                return
            }
            if first.isIDNALabelSeparator {
                /// There are 2 bytes and the first one is a label separator
                /// Starting with an empty label like that is invalid
                throw ValidationError.labelMustNotBeEmpty(
                    in: ByteBuffer(bytes: [first, second, third])
                )
            }
        default:
            break
        }

        /// Remove the trailing dot if it exists, and set the FQDN flag
        /// The IDNA spec doesn't like the root label separator.
        DomainName.__removingRootLabelIndicator(
            from: &span,
            bytesCount: &bytesCount,
            isFQDN: &isFQDN
        )

        /// FIXME: skip this step whenever swift-idna supports spans
        var domainName = String(
            unsafeUninitializedCapacity: bytesCount
        ) { stringBuffer in
            span.withUnsafeBytes { bytesBuffer in
                let rawStringBuffer = UnsafeMutableRawBufferPointer(stringBuffer)
                rawStringBuffer.copyMemory(from: bytesBuffer)
            }
            return bytesCount
        }

        /// TODO: make sure all initializations of DomainName go through a single initializer that
        /// asserts lowercased ASCII?

        /// short-circuits most domain names which won't change with IDNA anyway.
        try IDNA(
            configuration: idnaConfiguration
        ).toASCII(
            domainName: &domainName
        )

        try self.init(
            __uncheckedValidatedDomainNameSpan: domainName.utf8Span.span,
            isFQDN: isFQDN
        )
    }

    /// Only intended to be used in the initializer above
    @inlinable
    static func __removingRootLabelIndicator(
        from bytesSpan: inout Span<UInt8>,
        bytesCount: inout Int,
        isFQDN: inout Bool
    ) {
        /// In the initializer above, we already checked if the domain name is 1-2 bytes and those
        /// 2 bytes are the IDNA label separator. Here we don't need to check for that.
        guard bytesCount > 1 else {
            return
        }

        let endIndex = bytesCount &- 1
        switch bytesCount {
        case 2:
            let rhs = bytesSpan[unchecked: endIndex]
            if rhs.isIDNALabelSeparator {
                let range = Range(uncheckedBounds: (0, endIndex))
                bytesSpan = bytesSpan.extracting(unchecked: range)
                isFQDN = true
                bytesCount &-= 1
                return
            }
        case 3...:
            let first = bytesSpan[unchecked: endIndex &- 2]
            let second = bytesSpan[unchecked: endIndex &- 1]
            let third = bytesSpan[unchecked: endIndex]
            if third.isIDNALabelSeparator {
                let range = Range(uncheckedBounds: (0, endIndex))
                bytesSpan = bytesSpan.extracting(unchecked: range)
                isFQDN = true
                bytesCount &-= 1
                return
            }
            if DomainName.isIDNALabelSeparator(first, second, third) {
                let range = Range(uncheckedBounds: (0, endIndex &- 2))
                bytesSpan = bytesSpan.extracting(unchecked: range)
                isFQDN = true
                bytesCount &-= 3
                return
            }
        default:
            break
        }
    }
}

@available(endpointApplePlatforms 13, *)
extension DomainName {
    /// `span` must be an already-validated domain name span.
    /// ASCII characters only.
    /// No uppercased latin characters.
    /// No root label indicator.
    ///
    /// Labels that are empty will throw an error.
    /// Labels that are longer than 63 bytes will throw an error.
    /// Total length greater than 255 bytes will throw an error.
    @inlinable
    init(
        __uncheckedValidatedDomainNameSpan span: Span<UInt8>,
        isFQDN: Bool
    ) throws {
        debugOnly {
            DomainName.__debugAssertValidDomainNameSpan(span)
        }

        let totalLength = span.count &+ 1

        guard totalLength <= DomainName.maxLength else {
            throw ValidationError.domainNameLengthLimitExceeded(
                actual: totalLength,
                max: Int(DomainName.maxLength),
                in: ByteBuffer(swiftEndpointReadingFromSpan: span)
            )
        }

        self.isFQDN = isFQDN
        self._data = ByteBuffer()

        try self._data.writeWithUnsafeMutableBytes(
            minimumWritableBytes: totalLength
        ) { dataPtr in
            var dataPtr = dataPtr.baseAddress.unsafelyUnwrapped
            var startIndex = 0
            for idx in span.indices {
                let byte = span[unchecked: idx]
                switch byte {
                case .asciiDot:
                    try Self._writeLabel(
                        from: span,
                        to: &dataPtr,
                        startIndex: startIndex,
                        idx: idx
                    )
                    startIndex = idx &+ 1
                default:
                    break
                }
            }

            try Self._writeLabel(
                from: span,
                to: &dataPtr,
                startIndex: startIndex,
                idx: span.count
            )

            return totalLength
        }
    }

    @inlinable
    static func _writeLabel(
        from span: Span<UInt8>,
        to dataPtr: inout UnsafeMutableRawPointer,
        startIndex: Int,
        idx: Int
    ) throws {
        let range = Range(uncheckedBounds: (startIndex, idx))
        let chunk = span.extracting(range)
        let labelLength = range.count
        if labelLength == 0 {
            throw ValidationError.labelMustNotBeEmpty(
                in: ByteBuffer(swiftEndpointReadingFromSpan: span)
            )
        }
        if labelLength > DomainName.maxLabelLength {
            throw ValidationError.labelLengthLimitExceeded(
                actual: Int(labelLength),
                max: Int(DomainName.maxLabelLength),
                in: ByteBuffer(swiftEndpointReadingFromSpan: span)
            )
        }

        var copyableLabelLength = UInt8(truncatingIfNeeded: labelLength)
        withUnsafeBytes(of: &copyableLabelLength) {
            dataPtr.copyMemory(
                from: UnsafeRawPointer($0.baseAddress.unsafelyUnwrapped),
                byteCount: 1
            )
            dataPtr = dataPtr.advanced(by: 1)
        }

        chunk.withUnsafeBytes { chunkPtr in
            dataPtr.copyMemory(
                from: UnsafeRawPointer(chunkPtr.baseAddress.unsafelyUnwrapped),
                byteCount: chunk.count
            )
            dataPtr = dataPtr.advanced(by: chunk.count)
        }
    }

    @inlinable
    static func isIDNALabelSeparator(_ first: UInt8, _ second: UInt8, _ third: UInt8) -> Bool {
        /// U+3002 ( 。 ) IDEOGRAPHIC FULL STOP
        if first == 227, second == 128, third == 130 {
            return true
        }
        /// U+FF0E ( ． ) FULLWIDTH FULL STOP
        if first == 239, second == 188, third == 142 {
            return true
        }
        /// U+FF61 ( ｡ ) HALFWIDTH IDEOGRAPHIC FULL STOP
        if first == 239, second == 189, third == 161 {
            return true
        }
        return false
    }

    @inlinable
    static func __debugAssertValidDomainNameSpan(_ span: Span<UInt8>) {
        for idx in span.indices {
            /// Unchecked because `idx` comes right from `span.indices`
            if !span[unchecked: idx].isASCII {
                fatalError(
                    "DomainName initializer should not be used with non-ASCII character: \(span[unchecked: idx])"
                )
            }
            if span[unchecked: idx].isUppercasedASCIILetter {
                fatalError(
                    "DomainName initializer should not be used with uppercased ASCII characters: \(span[unchecked: idx])"
                )
            }
        }

        guard span.count > 1 else {
            return
        }

        let endIndex = span.count &- 1
        switch span.count {
        case 2:
            let rhs = span[unchecked: endIndex]
            if rhs.isIDNALabelSeparator {
                fatalError(
                    "DomainName initializer should not be used with root label indicator: \(span[unchecked: endIndex])"
                )
            }
        case 3...:
            let first = span[unchecked: endIndex &- 2]
            let second = span[unchecked: endIndex &- 1]
            let third = span[unchecked: endIndex]
            if third.isIDNALabelSeparator {
                fatalError(
                    "DomainName initializer should not be used with root label indicator: \(span[unchecked: endIndex])"
                )
            }
            if DomainName.isIDNALabelSeparator(first, second, third) {
                fatalError(
                    "DomainName initializer should not be used with root label indicator: \(span[unchecked: endIndex])"
                )
            }
        default:
            break
        }
    }
}
