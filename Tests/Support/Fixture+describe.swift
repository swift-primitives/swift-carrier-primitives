public import Carrier_Primitives

extension Fixture {
    /// Form D — a generic function over any Carrier. Demonstrates the
    /// super-protocol's payoff: cross-Carrier reflection over `Domain`
    /// and `Underlying` metatypes without per-type plumbing.
    public static func describe<C: Carrier & ~Copyable & ~Escapable>(
        _ c: borrowing C
    ) -> String {
        "Carrier<\(C.Underlying.self)> with Domain \(C.Domain.self)"
    }

    /// Generic helper that projects only `C.Domain` (not `C.Underlying`).
    /// Exercises the Never-default generic substitution path — the
    /// protocol declares `associatedtype Domain: ~Copyable & ~Escapable
    /// = Never`, and this helper confirms that `Never` resolves cleanly
    /// at call sites that use the default without the caller restating
    /// the suppression.
    ///
    /// Restating `C.Domain: ~Copyable & ~Escapable` in the where clause
    /// is a compile error on Swift 6.3 ("cannot suppress '~Copyable' on
    /// generic parameter ... defined in outer scope") — the protocol's
    /// own associated-type declaration already carries the suppression;
    /// consumers inherit it and cannot re-apply it.
    ///
    /// Added per the 2026-04-24 forums-review simulation (post 3, c3
    /// archetype) asking for an explicit test of the Never-default
    /// generic-dispatch path.
    public static func describe<C: Carrier & ~Copyable & ~Escapable>(
        domain _: C.Type
    ) -> String {
        "\(C.Domain.self)"
    }
}
