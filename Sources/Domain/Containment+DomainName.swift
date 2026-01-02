public import struct NIOCore.ByteBuffer

extension DomainName {
    /// Returns a Boolean value that indicates whether this domain name is a
    /// subdomain of the given domain name.
    ///
    /// Examples:
    /// ```swift
    /// let domainName = DomainName("example.com")
    /// let otherDomainName = DomainName("www.example.com")
    /// let anotherDomainName = DomainName("www.example.com.thing")
    ///
    /// domainName.isSubdomain(of: otherDomainName) // true
    /// domainName.isSubdomain(of: domainName) // true
    /// otherDomainName.isSubdomain(of: domainName) // false
    /// otherDomainName.isSubdomain(of: anotherDomainName) // false
    /// ```
    ///
    /// - Parameter other: A domain name to compare against.
    /// - Returns: `true` if this domain name is a subdomain of `other`;
    ///   otherwise, `false`.
    @inlinable
    public func isSubdomain(of other: DomainName) -> Bool {
        var otherIterator = other.makeIterator()
        var selfIterator = self.makeIterator()

        guard let firstLabel = selfIterator.next() else {
            return true
        }

        while let otherLabel = otherIterator.next() {
            if otherLabel == firstLabel {
                break
            }
        }

        return selfIterator.remainingBytes() == otherIterator.remainingBytes()
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
    ///
    /// domainName.isStrictSubdomain(of: otherDomainName) // true
    /// domainName.isStrictSubdomain(of: domainName) // false
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
    ///
    /// otherDomainName.isSuperdomain(of: domainName) // true
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
    ///
    /// otherDomainName.isStrictSuperdomain(of: domainName) // true
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
