import Testing
import Carrier_Primitives_Test_Support

// SLI conformances of Copyable & Escapable stdlib types. Each conformer
// is a trivial self-carrier (Underlying == Self, Domain == Never)
// satisfied by the `Carrier where Underlying == Self` default
// extension. The Span family is exercised separately in
// `Span Tests.swift` because its ~Escapable nature requires explicit
// witnesses.

@Suite("Carrier (Standard Library Integration)")
struct CarrierSLITests {
    @Suite struct Unit {}
    @Suite struct `Edge Case` {}
    @Suite struct Integration {}
    @Suite(.serialized) struct Performance {}
}

// MARK: - Unit
//
// One assertion per stdlib conformer that a value-bearing trivial
// self-carrier round-trips its underlying through the protocol's
// witness shape.

extension CarrierSLITests.Unit {

    @Test
    func `Int conforms via stdlib integration`() {
        let i: Int = 42
        #expect(i.underlying == 42)
        #expect(Int(99).underlying == 99)
    }

    @Test
    func `String conforms via stdlib integration`() {
        let s: String = "hello"
        #expect(s.underlying == "hello")
    }

    @Test
    func `Double conforms via stdlib integration`() {
        let d: Double = 3.14
        #expect(d.underlying == 3.14)
    }

    @Test
    func `Bool conforms via stdlib integration`() {
        let b: Bool = true
        #expect(b.underlying == true)
    }

    @Test
    func `Character conforms via stdlib integration`() {
        let c: Character = "A"
        #expect(c.underlying == "A")
    }

    @Test
    func `Substring conforms via stdlib integration`() {
        let full = "hello world"
        let s: Substring = full.prefix(5)
        #expect(s.underlying == "hello")
    }

    @Test
    func `Int128 conforms via stdlib integration`() {
        let big: Int128 = 123_456_789
        #expect(big.underlying == 123_456_789)
    }

    @Test
    func `Duration conforms via stdlib integration`() {
        let d: Duration = .milliseconds(500)
        #expect(d.underlying == .milliseconds(500))
    }
}

// MARK: - Edge Case
//
// Conformances that cannot be exercised by value — Never is uninhabited;
// Span family lives in the ~Escapable quadrant with bespoke witnesses
// (covered in `Span Tests.swift`).

extension CarrierSLITests.`Edge Case` {

    @Test
    func `Never conforms to Carrier at the type level`() {
        // Never is uninhabited; no value can exist. The conformance
        // is verifiable at type level only — the protocol is
        // satisfied by the default `where Underlying == Self`
        // extension with Self == Never. This test confirms the
        // conformance is present in the module's conformance table.
        func _requireCarrier<T: Carrier & ~Copyable & ~Escapable>(_: T.Type) {}
        _requireCarrier(Never.self)
        #expect(Bool(true))
    }
}

// MARK: - Integration
//
// SLI conformers reaching parameterized Carrier APIs without wrapping —
// confirms a bare stdlib value satisfies `some Carrier<Int>` at API
// sites without consumer plumbing.

extension CarrierSLITests.Integration {

    @Test
    func `Int satisfies some Carrier<Int> at API sites`() {
        // A bare Int reaches a `some Carrier<Int>` API without any
        // wrapping, via the SLI conformance.
        #expect(Fixture.value(of: 77) == 77)
    }
}
