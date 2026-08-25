@available(SwiftStdlib 5.1, *)
extension String {
    /// Calls `body` with a `Span` of this String's utf8 bytes.
    @inlinable
    @inline(always)
    func withSpan_Compatibility<T, E: Error>(
        _ body: (Span<UInt8>) throws(E) -> T
    ) throws(E) -> T {
        do {
            /// Fast path: Currently always the case for non-Darwin.
            /// On Darwin, always the case unless for some objc-bridged strings.
            if let fastResult = try self.utf8.withContiguousStorageIfAvailable({
                try body(unsafe $0.span)
            }) {
                return fastResult
            }
        } catch let error as E {
            throw error
        } catch {
            fatalError("Unreachable code path")
        }

        return try self.withSpan_Compatibility_SlowPath(body)
    }

    /// This function can only be reached on Darwin and only for some objc-bridged strings.
    /// Therefore it's not worth inlining. As a matter of fact it's worth not inlining it at all.
    @usableFromInline
    @inline(never)
    func withSpan_Compatibility_SlowPath<T, E: Error>(
        _ body: (Span<UInt8>) throws(E) -> T
    ) throws(E) -> T {
        if #available(SwiftStdlib 6.2, *) {
            return try body(self.utf8Span.span)
        }

        var copy = self
        do {
            return try copy.withUTF8({
                try body(unsafe $0.span)
            })
        } catch let error as E {
            throw error
        } catch {
            fatalError("Unreachable code path")
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
    func withSpan_Compatibility<T, E: Error>(
        _ body: (Span<UInt8>) throws(E) -> T
    ) throws(E) -> T {
        do {
            /// Fast path: Currently always the case for non-Darwin.
            /// On Darwin, always the case unless for some objc-bridged strings.
            if let fastResult = unsafe try self.utf8.withContiguousStorageIfAvailable({
                try body(unsafe $0.span)
            }) {
                return fastResult
            }
        } catch let error as E {
            throw error
        } catch {
            fatalError("Unreachable code path")
        }

        return try self.withSpan_Compatibility_SlowPath(body)
    }

    /// This function can only be reached on Darwin and only for some objc-bridged strings.
    /// Therefore it's not worth inlining. As a matter of fact it's worth not inlining it at all.
    @usableFromInline
    @inline(never)
    func withSpan_Compatibility_SlowPath<T, E: Error>(
        _ body: (Span<UInt8>) throws(E) -> T
    ) throws(E) -> T {
        if #available(SwiftStdlib 6.2, *) {
            return try body(self.utf8Span.span)
        }

        var copy = self
        do {
            return try copy.withUTF8({
                try body(unsafe $0.span)
            })
        } catch let error as E {
            throw error
        } catch {
            fatalError("Unreachable code path")
        }
    }
}
