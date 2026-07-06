public import struct NIOCore.ByteBuffer

@available(SwiftStdlib 5.1, *)
extension DomainName {
    /// Returns a Boolean value that indicates whether this domain name is a
    /// subdomain of the given domain name.
    ///
    /// Examples:
    /// ```swift
    /// let domainName = DomainName("example.com")
    /// let otherDomainName = DomainName("www.example.com")
    /// let anotherDomainName = DomainName("www.example.com.thing")
    /// let wildcardDomainName = DomainName("*.example.com")
    ///
    /// domainName.isSubdomain(of: otherDomainName) // true
    /// domainName.isSubdomain(of: domainName) // true
    /// wildcardDomainName.isSubdomain(of: domainName) // true
    /// otherDomainName.isSubdomain(of: domainName) // false
    /// otherDomainName.isSubdomain(of: anotherDomainName) // false
    /// ```
    ///
    /// - Parameter other: A domain name to compare against.
    /// - Returns: `true` if this domain name is a subdomain of `other`;
    ///   otherwise, `false`.
    @inlinable
    public func isSubdomain(of other: DomainName) -> Bool {
        unsafe self._data.withUnsafeReadableBytes { selfPtr -> Bool in
            unsafe selfPtr.withMemoryRebound(to: UInt8.self) { selfBytes -> Bool in
                unsafe other._data.withUnsafeReadableBytes { otherPtr -> Bool in
                    unsafe otherPtr.withMemoryRebound(to: UInt8.self) { otherBytes -> Bool in
                        let selfSpan = unsafe selfBytes.span
                        var selfIterator = self.makePositionIterator()
                        let otherSpan = unsafe otherBytes.span
                        var otherIterator = other.makePositionIterator()

                        guard var otherLabelPosition = otherIterator.next() else {
                            return false
                        }

                        var seenWildcard = false
                        while let selfLabelPosition = selfIterator.next() {
                            let otherLabel = unsafe otherSpan.extracting(
                                unchecked: otherLabelPosition.range
                            )
                            let otherLabelIsWildcard =
                                unsafe otherLabelPosition.length == 1
                                && otherSpan[unchecked: otherLabelPosition.startIndex] == .asciiStar

                            if otherLabelIsWildcard {
                                guard let newOtherLabelPosition = otherIterator.next() else {
                                    return false
                                }
                                otherLabelPosition = newOtherLabelPosition
                                seenWildcard = true
                                continue
                            }

                            let selfLabel = unsafe selfSpan.extracting(
                                unchecked: selfLabelPosition.range
                            )
                            if selfLabel.swift_endpoint_equals(to: otherLabel) {
                                break
                            } else if seenWildcard {
                                return false
                            }
                        }

                        return selfIterator.remainingBytes() == otherIterator.remainingBytes()
                    }
                }
            }
        }
    }

    /// Returns a Boolean value that indicates whether this domain name is a
    /// strict subdomain of the given domain name.
    /// Meaning that `self` is a subdomain of `other` but is not equal to it.
    ///
    /// Examples:
    /// ```swift
    /// let domainName = DomainName("example.com")
    /// let otherDomainName = DomainName("www.example.com")
    /// let anotherDomainName = DomainName("www.example.com.thing")
    /// let wildcardDomainName = DomainName("*.example.com")
    ///
    /// domainName.isStrictSubdomain(of: otherDomainName) // true
    /// domainName.isStrictSubdomain(of: domainName) // false
    /// wildcardDomainName.isStrictSubdomain(of: domainName) // true
    /// otherDomainName.isStrictSubdomain(of: domainName) // false
    /// otherDomainName.isStrictSubdomain(of: anotherDomainName) // false
    /// ```
    ///
    /// - Parameter other: A domain name to compare against.
    /// - Returns: `true` if this domain name is a strict subdomain of `other`;
    ///   otherwise, `false`.
    @inlinable
    public func isStrictSubdomain(of other: DomainName) -> Bool {
        if self == other { return false }
        return self.isSubdomain(of: other)
    }

    /// Returns a Boolean value that indicates whether this domain name is a
    /// superdomain of the given domain name.
    ///
    /// Examples:
    /// ```swift
    /// let domainName = DomainName("example.com")
    /// let otherDomainName = DomainName("www.example.com")
    /// let anotherDomainName = DomainName("www.example.com.thing")
    /// let wildcardDomainName = DomainName("*.example.com")
    ///
    /// otherDomainName.isSuperdomain(of: domainName) // true
    /// otherDomainName.isSuperdomain(of: wildcardDomainName) // false
    /// domainName.isSuperdomain(of: domainName) // true
    /// domainName.isSuperdomain(of: otherDomainName) // false
    /// anotherDomainName.isSuperdomain(of: otherDomainName) // false
    /// ```
    ///
    /// - Parameter other: A domain name to compare against.
    /// - Returns: `true` if this domain name is a superdomain of `other`;
    ///   otherwise, `false`.
    @inlinable
    public func isSuperdomain(of other: DomainName) -> Bool {
        other.isSubdomain(of: self)
    }

    /// Returns a Boolean value that indicates whether this domain name is a
    /// strict superdomain of the given domain name.
    /// Meaning that `self` is a superdomain of `other` but is not equal to it.
    ///
    /// Examples:
    /// ```swift
    /// let domainName = DomainName("example.com")
    /// let otherDomainName = DomainName("www.example.com")
    /// let anotherDomainName = DomainName("www.example.com.thing")
    /// let wildcardDomainName = DomainName("*.example.com")
    ///
    /// otherDomainName.isStrictSuperdomain(of: domainName) // true
    /// otherDomainName.isStrictSuperdomain(of: wildcardDomainName) // false
    /// domainName.isStrictSuperdomain(of: domainName) // false
    /// domainName.isStrictSuperdomain(of: otherDomainName) // false
    /// anotherDomainName.isStrictSuperdomain(of: otherDomainName) // false
    /// ```
    ///
    /// - Parameter other: A domain name to compare against.
    /// - Returns: `true` if this domain name is a strict superdomain of `other`;
    ///   otherwise, `false`.
    @inlinable
    public func isStrictSuperdomain(of other: DomainName) -> Bool {
        other.isStrictSubdomain(of: self)
    }
}
