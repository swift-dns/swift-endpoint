@available(SwiftStdlib 5.1, *)
extension String {
    #if canImport(Darwin)
    @usableFromInline
    mutating func withSpan_Compatibility<T, E: Error>(
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
            return try self.withUTF8 {
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
    mutating func withSpan_Compatibility<T, E: Error>(
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
        ) throws -> Int
    ) rethrows {
        if #available(SwiftStdlib 5.3, *) {
            try self.init(unsafeUninitializedCapacity: capacity) { buffer in
                unsafe try initializer(buffer)
            }
        } else {
            let array = unsafe try [UInt8].init(
                unsafeUninitializedCapacity: capacity
            ) { buffer, initializedCount in
                initializedCount = unsafe try initializer(buffer)
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
        ) throws -> Int
    ) rethrows {
        try self.init(unsafeUninitializedCapacity: capacity) { buffer in
            try initializer(buffer)
        }
    }
    #endif
}

@available(SwiftStdlib 5.1, *)
extension Substring {
    #if canImport(Darwin)
    @usableFromInline
    mutating func withSpan_Compatibility<T, E: Error>(
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
            return try self.withUTF8 {
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
    mutating func withSpan_Compatibility<T, E: Error>(
        _ body: (Span<UInt8>) throws(E) -> T
    ) throws(E) -> T {
        try body(self.utf8Span.span)
    }
    #endif
}
