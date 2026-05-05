import Carrier_Primitives_Test_Support
import Testing

// Tests focused on the `Carrier where Underlying == Self` default
// extension shipped in `Sources/Carrier Primitives/Carrier where Underlying == Self.swift`.
//
// Two design properties are unit-asserted here, distinct from the
// transitive coverage every SLI conformance gives the default:
//
//   1. The default's `_read { yield self }` accessor satisfies the
//      protocol's `@_lifetime(borrow self) borrowing get` requirement
//      for Copyable & Escapable Self without a per-conformer body.
//   2. The default's `init(_ underlying: consuming Self)` round-trips
//      a value through assignment.
//
// Coverage shape:
//   • Unit — round-trip via the default extension on a synthetic local
//     trivial conformer (Underlying == Self, no explicit witness).
//   • Edge Case — extension's exclusion of ~Escapable Self (refer to
//     Span+Carrier Tests.swift for the empirical demonstration).
//   • Integration — synthetic conformer reaches `some Carrier<U>` APIs.

@Suite
struct `Carrier.Protocol where Underlying == Self Tests` {
    @Suite struct Unit {}
    @Suite struct `Edge Case` {}
    @Suite struct Integration {}
    @Suite(.serialized) struct Performance {}
}

// MARK: Synthetic trivial conformer
//
// A local struct whose only declaration is the conformance — the
// witness bodies come from the default extension. This is the minimum
// shape that exercises the default extension as a unit.

private struct Cardinal: Carrier.`Protocol` {
    typealias Underlying = Self
    var raw: Int
}

extension `Carrier.Protocol where Underlying == Self Tests`.Unit {

    @Test
    func `default extension provides underlying for trivial self-carrier`() {
        let c = Cardinal(raw: 21)
        #expect(c.underlying.raw == 21)
    }

    @Test
    func `default extension provides init for trivial self-carrier`() {
        let original = Cardinal(raw: 42)
        let rebuilt = Cardinal(original)
        #expect(rebuilt.raw == 42)
    }

    @Test
    func `default extension round-trips through underlying and init`() {
        let original = Cardinal(raw: 99)
        let rebuilt = Cardinal(original.underlying)
        #expect(rebuilt.raw == 99)
    }
}

extension `Carrier.Protocol where Underlying == Self Tests`.Integration {

    @Test
    func `synthetic trivial conformer reaches some Carrier<U> API`() {
        // The default extension is what makes the parametric API site
        // accept the synthetic conformer without further boilerplate.
        let c = Cardinal(raw: 7)
        #expect(Fixture.value(of: c).raw == 7)
    }
}
