public import Carrier_Primitives

extension Fixture {
    /// SE-0346 primary-associated-type spelling — accepts any Carrier
    /// whose Underlying is `U`. Demonstrates the `some Carrier<U>`
    /// constraint spelling at API sites and lets test files exercise
    /// the parameterized super-protocol surface for any Copyable
    /// Underlying.
    public static func value<U: Copyable>(of c: borrowing some Carrier<U>) -> U {
        c.underlying
    }
}
