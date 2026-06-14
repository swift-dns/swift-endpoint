public import struct NIOCore.ByteBuffer

extension DomainName {
    /// A single label of a domain name.
    ///
    /// [RFC 9499, DNS Terminology, March 2024](https://tools.ietf.org/html/rfc9499)
    ///
    /// ```text
    /// 2.1.12 Label
    ///
    /// An ordered list of zero or more octets that makes up a portion of a domain name.
    /// Using graph theory, a label identifies one node in a portion of the graph of all possible domain names.
    /// ```
    ///
    /// Use a for-loop over a ``DomainName`` to obtain its labels.
    public struct Label: Sendable, Hashable {
        /// Using this property directly is highly discouraged, as denoted by the underscored name.
        /// If you want a description of the label, use the `label.description` instead.
        ///
        /// The raw bytes of the label, as in the wire format, excluding the leading length byte.
        /// Lowercased ASCII bytes only.
        ///
        /// Only lowercased letter, digits, hyphen-minus, underscores, stars, and whitespaces will ever make it to this property.
        ///
        /// Underscores are allowed for "underbar" service names like "_sip._tcp.example.com" according
        /// to [RFC 8552](https://tools.ietf.org/html/rfc8552) and [RFC 8553](https://tools.ietf.org/html/rfc8553).
        /// Stars are allowed for wildcards like "*.example.com" according to [RFC 4592](https://tools.ietf.org/html/rfc4592).
        /// Whitespaces are allowed for labels like "Mijia Cloud" which some Xiaomi devices use.
        /// Non-ASCII names are converted to ASCII based on the IDNA spec, in the ``DomainName`` initializers.
        /// Non-lowercased ASCII names are converted to lowercased ASCII in the ``DomainName`` initializers.
        public var _data: ByteBuffer

        /// Using this initializer is not safe and is highly discouraged.
        /// To obtain a label, for-loop over a ``DomainName`` instead.
        ///
        /// - Parameter _uncheckedAssumingValidBytes: The bytes of the label, excluding the leading
        ///   length byte.
        ///   Must be valid ASCII.
        ///   Must not contain uppercased A-Z. Use lowercased bytes instead.
        ///   Must not be empty.
        ///   Must not be longer than 63 bytes.
        @inlinable
        public init(_uncheckedAssumingValidBytes data: ByteBuffer) {
            self._data = data

            debugOnly {
                let labelLength = self._data.readableBytes
                precondition(
                    labelLength > 0 && labelLength <= DomainName.maxLabelLength,
                    "Label was longer than \(DomainName.maxLabelLength) bytes:\n\(self._data.hexDump(format: .detailed))"
                )

                for byte in self._data.readableBytesView {
                    precondition(
                        byte.isAcceptableDomainNameCharacter,
                        "Label contained invalid byte: \(byte)\nLabel:\n\(self._data.hexDump(format: .detailed))"
                    )
                }
            }
        }
    }
}
