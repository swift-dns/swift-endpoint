@available(SwiftStdlib 5.1, *)
extension String {
    /// Calls `body` with a `Span` of this String's utf8 bytes.
    @inlinable
    @inline(always)
    func withSpan_Compatibility<T>(
        _ body: (Span<UInt8>) -> T
    ) -> T {
        /// Fast path: Currently always the case for non-Darwin.
        /// On Darwin, always the case unless for some objc-bridged strings.
        if let fastResult = self.utf8.withContiguousStorageIfAvailable({ buffer in
            body(unsafe buffer.span)
        }) {
            return fastResult
        }

        return self.withSpan_Compatibility_SlowPath(body)
    }

    /// This function can only be reached on Darwin and only for some objc-bridged strings.
    /// Therefore it's not worth inlining. As a matter of fact it's worth not inlining it at all.
    @usableFromInline
    @inline(never)
    func withSpan_Compatibility_SlowPath<T>(
        _ body: (Span<UInt8>) -> T
    ) -> T {
        /// Same availability guard as `utf8Span` has in swift repo.
        /// The symbol is available there but will just abort.
        #if !(os(watchOS) && _pointerBitWidth(_32))
        if #available(SwiftStdlib 6.2, *) {
            return body(self.utf8Span.span)
        }
        #endif

        var copy = self
        return copy.withUTF8 { buffer in
            body(unsafe buffer.span)
        }
    }

    #if canImport(Darwin)
    @usableFromInline
    init(
        unsafeUninitializedCapacity_Compatibility capacity: Int,
        initializingUTF8With initializer: (
            _ buffer: UnsafeMutableBufferPointer<UInt8>
        ) -> Int
    ) {
        if #available(SwiftStdlib 5.3, *) {
            self.init(unsafeUninitializedCapacity: capacity) { buffer in
                unsafe initializer(buffer)
            }
        } else {
            let array = unsafe [UInt8].init(
                unsafeUninitializedCapacity: capacity
            ) { buffer, initializedCount in
                initializedCount = unsafe initializer(buffer)
            }
            self.init(decoding: array, as: UTF8.self)
        }
    }
    #else
    /// @_transparent helps mitigate some performance regressions on Linux that happened when
    /// moving from directly using the underlying initializer, to this compatibility initializer.
    @_transparent
    @inlinable
    init(
        unsafeUninitializedCapacity_Compatibility capacity: Int,
        initializingWith initializer: (
            _ buffer: UnsafeMutableBufferPointer<UInt8>
        ) -> Int
    ) {
        self.init(unsafeUninitializedCapacity: capacity) { buffer in
            unsafe initializer(buffer)
        }
    }
    #endif
}

@available(SwiftStdlib 5.1, *)
extension Substring {
    /// Calls `body` with a `Span` of this Substring's utf8 bytes.
    @inlinable
    @inline(always)
    func withSpan_Compatibility<T>(
        _ body: (Span<UInt8>) -> T
    ) -> T {
        /// Fast path: Currently always the case for non-Darwin.
        /// On Darwin, always the case unless for some objc-bridged strings.
        if let fastResult = unsafe self.utf8.withContiguousStorageIfAvailable({ buffer in
            body(unsafe buffer.span)
        }) {
            return fastResult
        }

        return self.withSpan_Compatibility_SlowPath(body)
    }

    /// This function can only be reached on Darwin and only for some objc-bridged strings.
    /// Therefore it's not worth inlining. As a matter of fact it's worth not inlining it at all.
    @usableFromInline
    @inline(never)
    func withSpan_Compatibility_SlowPath<T>(
        _ body: (Span<UInt8>) -> T
    ) -> T {
        /// Same availability guard as `utf8Span` has in swift repo.
        /// The symbol is available there but will just abort.
        #if !(os(watchOS) && _pointerBitWidth(_32))
        if #available(SwiftStdlib 6.2, *) {
            return body(self.utf8Span.span)
        }
        #endif

        var copy = self
        return copy.withUTF8 { buffer in
            body(unsafe buffer.span)
        }
    }
}
