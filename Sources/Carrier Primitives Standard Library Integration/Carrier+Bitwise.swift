// ===----------------------------------------------------------------------===//
//
// This source file is part of the swift-carrier-primitives open source project
//
// Copyright (c) 2024-2026 Coen ten Thije Boonkkamp and the swift-carrier-primitives project authors
// Licensed under Apache License v2.0
//
// See LICENSE for license information
//
// ===----------------------------------------------------------------------===//

// MARK: - Bitwise Operations on Carrier<FixedWidthInteger>
//
// Type-safe bitwise operations on any `Carrier.\`Protocol\``-conforming type
// whose `Underlying` is `FixedWidthInteger`. Any institute typed-wrapper
// type over a fixed-width integer (Tagged-backed brand newtypes,
// Memory.Address, Memory.Alignment, Binary.Mask, etc.) receives the
// bitwise surface uniformly.
//
// Cardinal-typed shifts (`<<` / `>>` with `Carrier<Cardinal>` amount) live
// in `swift-bit-primitives` next to the bare-FixedWidthInteger Cardinal
// shifts they parallel — `bit-primitives` is downstream of both Carrier
// and Cardinal, where the cross-typed shift overloads naturally compose.
//
// All operators carry `@_disfavoredOverload` so when both this overload
// and stdlib's FixedWidthInteger operator apply (self-carriers — stdlib
// FWI types conforming to Carrier via SLI), stdlib wins. Typed wrappers
// like `Tagged<Tag, UInt32>` aren't FixedWidthInteger themselves so they
// only match this overload — they get the typed-wrapper bitwise surface
// that stdlib can't provide.
//
// **Literal-side overloads omitted intentionally.** Earlier drafts
// included `(C, C.Underlying)` / `(C.Underlying, C)` convenience overloads
// for mixing typed-wrapper and raw-value operands. They produced a
// resolution ambiguity at call sites like `byte & 0x3F`: the integer
// literal can bind either as `C` (via ExpressibleByIntegerLiteral, when
// the wrapper conforms) or as `C.Underlying`, and both
// `@_disfavoredOverload`-marked candidates tie. With only the `(C, C)`
// form, the literal coerces to `C` uniquely. Mixing with a non-literal
// raw value gets explicit: `byte & Byte(rawUInt8)`.
//
// Used for CPU register manipulation, flag checking, typed-mask arithmetic.

// MARK: - Bitwise AND

/// Bitwise AND of two carrier values.
@_disfavoredOverload
@inlinable
public func & <C: Carrier.`Protocol`>(lhs: C, rhs: C) -> C
where C.Underlying: FixedWidthInteger {
    C(lhs.underlying & rhs.underlying)
}

// MARK: - Bitwise OR

/// Bitwise OR of two carrier values.
@_disfavoredOverload
@inlinable
public func | <C: Carrier.`Protocol`>(lhs: C, rhs: C) -> C
where C.Underlying: FixedWidthInteger {
    C(lhs.underlying | rhs.underlying)
}

// MARK: - Bitwise XOR

/// Bitwise XOR of two carrier values.
@_disfavoredOverload
@inlinable
public func ^ <C: Carrier.`Protocol`>(lhs: C, rhs: C) -> C
where C.Underlying: FixedWidthInteger {
    C(lhs.underlying ^ rhs.underlying)
}

// MARK: - Bitwise NOT

/// Bitwise NOT of a carrier value.
@_disfavoredOverload
@inlinable
public prefix func ~ <C: Carrier.`Protocol`>(value: C) -> C
where C.Underlying: FixedWidthInteger {
    C(~value.underlying)
}

// MARK: - Left Shift (by Int)

/// Left shift a carrier value by an integer amount.
@_disfavoredOverload
@inlinable
public func << <C: Carrier.`Protocol`>(lhs: C, rhs: Int) -> C
where C.Underlying: FixedWidthInteger {
    C(lhs.underlying << rhs)
}

// MARK: - Right Shift (by Int)

/// Right shift a carrier value by an integer amount.
@_disfavoredOverload
@inlinable
public func >> <C: Carrier.`Protocol`>(lhs: C, rhs: Int) -> C
where C.Underlying: FixedWidthInteger {
    C(lhs.underlying >> rhs)
}

// MARK: - Compound Assignment

/// Bitwise AND assignment.
@_disfavoredOverload
@inlinable
public func &= <C: Carrier.`Protocol`>(lhs: inout C, rhs: C)
where C.Underlying: FixedWidthInteger {
    lhs = lhs & rhs
}

/// Bitwise OR assignment.
@_disfavoredOverload
@inlinable
public func |= <C: Carrier.`Protocol`>(lhs: inout C, rhs: C)
where C.Underlying: FixedWidthInteger {
    lhs = lhs | rhs
}

/// Bitwise XOR assignment.
@_disfavoredOverload
@inlinable
public func ^= <C: Carrier.`Protocol`>(lhs: inout C, rhs: C)
where C.Underlying: FixedWidthInteger {
    lhs = lhs ^ rhs
}

/// Left shift assignment by Int.
@_disfavoredOverload
@inlinable
public func <<= <C: Carrier.`Protocol`>(lhs: inout C, rhs: Int)
where C.Underlying: FixedWidthInteger {
    lhs = lhs << rhs
}

/// Right shift assignment by Int.
@_disfavoredOverload
@inlinable
public func >>= <C: Carrier.`Protocol`>(lhs: inout C, rhs: Int)
where C.Underlying: FixedWidthInteger {
    lhs = lhs >> rhs
}

// MARK: - Comparison with Zero (for flag checking)

extension Carrier.`Protocol` where Underlying: FixedWidthInteger {
    /// Returns `true` if the value is non-zero.
    @inlinable
    public var isNonZero: Bool {
        underlying != 0
    }

    /// Returns `true` if the value is zero.
    @inlinable
    public var isZero: Bool {
        underlying == 0
    }
}
