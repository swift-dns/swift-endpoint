@available(SwiftStdlib 5.1, *)
extension String {
    #if canImport(Darwin)
    @usableFromInline
    func withSpan_Compatibility<T, E: Error>(
        _ body: (Span<UInt8>) throws(E) -> T
    ) throws(E) -> T {
        do {
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

        if #available(SwiftStdlib 6.2, *) {
            return try body(self.utf8Span.span)
        }

        do {
            var copy = self
            return try copy.withUTF8 {
                try body(unsafe $0.span)
            }
        } catch let error as E {
            throw error
        } catch {
            fatalError("Unreachable code path")
        }
    }
    #else
    @_transparent
    @inlinable
    func withSpan_Compatibility<T, E: Error>(
        _ body: (Span<UInt8>) throws(E) -> T
    ) throws(E) -> T {
        try body(self.utf8Span.span)
    }
    #endif

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
    #if canImport(Darwin)
    @usableFromInline
    func withSpan_Compatibility<T, E: Error>(
        _ body: (Span<UInt8>) throws(E) -> T
    ) throws(E) -> T {
        do {
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

        if #available(SwiftStdlib 6.2, *) {
            return try body(self.utf8Span.span)
        }

        do {
            var copy = self
            return try copy.withUTF8 {
                try body(unsafe $0.span)
            }
        } catch let error as E {
            throw error
        } catch {
            fatalError("Unreachable code path")
        }
    }
    #else
    @_transparent
    @inlinable
    func withSpan_Compatibility<T, E: Error>(
        _ body: (Span<UInt8>) throws(E) -> T
    ) throws(E) -> T {
        try body(self.utf8Span.span)
    }
    #endif
}
