import Carrier_Primitives

extension Fixture {
    /// Form D — a generic function over any Carrier. Demonstrates the
    /// super-protocol's payoff: cross-Carrier reflection over `Domain`
    /// and `Underlying` metatypes without per-type plumbing.
    static func describe<C: Carrier & ~Copyable & ~Escapable>(
        _ c: borrowing C
    ) -> String {
        "Carrier<\(C.Underlying.self)> with Domain \(C.Domain.self)"
    }
}
