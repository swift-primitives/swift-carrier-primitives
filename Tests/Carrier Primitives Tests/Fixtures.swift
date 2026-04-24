import Carrier_Primitives

// MARK: - Conformer fixtures — one per quadrant
//
// These fixtures are declared in a separate file from Carrier Tests.swift
// to keep the @Test-bearing file free of generic file-scope helpers and
// protocol conformances that conflict with the @Test macro's @section
// compile-time-constant metadata generation (Swift 6.3.1 interaction).

// Quadrant 1: Copyable & Escapable Underlying.
// @_lifetime annotations are omitted because Int is Escapable; the
// attribute is rejected on Escapable results.
struct IntCarrier: Carrier {
    typealias Domain = Never
    typealias Underlying = Int

    var _storage: Int

    var underlying: Int {
        borrowing get { _storage }
    }

    init(_ underlying: consuming Int) {
        self._storage = underlying
    }
}

// Quadrant 2: ~Copyable & Escapable Underlying.
// The carrier itself is ~Copyable because Underlying is. Underlying is
// still Escapable — no lifetime annotations needed.
struct MoveOnly: ~Copyable {
    var raw: Int
}

struct MoveOnlyCarrier: ~Copyable, Carrier {
    typealias Domain = Never
    typealias Underlying = MoveOnly

    var _storage: MoveOnly

    // For ~Copyable storage, use _read (borrow-yielding coroutine)
    // to provide access without consuming. The protocol's
    // `borrowing get` requirement is satisfied by _read.
    var underlying: MoveOnly {
        _read { yield _storage }
    }

    init(_ underlying: consuming MoveOnly) {
        self._storage = underlying
    }
}

// MARK: - Generic helpers

/// Form D — a generic function over any Carrier. Demonstrates the
/// super-protocol payoff; types must be suppressed to match Carrier's
/// protocol requirements.
func describe<C: Carrier & ~Copyable & ~Escapable>(
    _ c: borrowing C
) -> String {
    "Carrier<\(C.Underlying.self)> with Domain \(C.Domain.self)"
}

/// SE-0346 primary-associated-type spelling — accepts any Carrier whose
/// Underlying is Int.
func extractInt(_ c: borrowing some Carrier<Int>) -> Int {
    c.underlying
}
