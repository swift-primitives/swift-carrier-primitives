public import Carrier_Primitives

extension Fixture {
    /// SE-0346 primary-associated-type spelling — accepts any Carrier
    /// whose Underlying is Int. Demonstrates the `some Carrier<Int>`
    /// constraint spelling at API sites.
    public static func value(of c: borrowing some Carrier<Int>) -> Int {
        c.underlying
    }
}
