import Testing
import Carrier_Primitives
import Carrier_Primitives_Standard_Library_Integration
import Carrier_Primitives_Test_Support

// Carrier<Underlying> is a generic protocol — per [SWIFT-TEST-003] the
// test suite uses the parallel namespace pattern (a non-generic
// top-level struct).

@Suite("Carrier")
struct CarrierTests {
    @Suite struct Unit {}
}

extension CarrierTests.Unit {

    @Test
    func `Plain stores and reads Int underlying`() {
        let c = Fixture.Plain(42)
        #expect(c.underlying == 42)
    }

    @Test
    func `Plain round-trips via init from underlying`() {
        let a = Fixture.Plain(100)
        let b = Fixture.Plain(a.underlying)
        #expect(a.underlying == b.underlying)
    }

    @Test
    func `Unique reads underlying via borrow`() {
        let c = Fixture.Unique(Fixture.Unique.Resource(raw: 99))
        let raw = c.underlying.raw
        #expect(raw == 99)
    }

    @Test
    func `describe reflects Underlying and Domain at type level`() {
        let c = Fixture.Plain(7)
        let desc = Fixture.describe(c)
        #expect(desc == "Carrier<Int> with Domain Never")
    }

    @Test
    func `value accepts Plain via parameterized constraint`() {
        let c = Fixture.Plain(55)
        #expect(Fixture.value(of: c) == 55)
    }

    @Test
    func `Scoped conforms with noncopyable nonescapable underlying`() {
        let c = Fixture.Scoped(Fixture.Scoped.Resource(raw: 77))
        let raw = c.underlying.raw
        #expect(raw == 77)
    }

    // MARK: Standard Library Integration — stdlib types as trivial self-carriers

    @Test
    func `Int conforms to Carrier via stdlib integration`() {
        // Int: Carrier lives in Carrier Primitives Standard Library
        // Integration. The default `where Underlying == Self` extension
        // provides underlying + init(_:).
        let i: Int = 42
        #expect(i.underlying == 42)
        #expect(Int(99).underlying == 99)
    }

    @Test
    func `Int satisfies some Carrier<Int> at API sites`() {
        // Form: a bare Int reaches a `some Carrier<Int>` API without
        // any wrapping.
        #expect(Fixture.value(of: 77) == 77)
    }

    @Test
    func `String conforms to Carrier via stdlib integration`() {
        let s: String = "hello"
        #expect(s.underlying == "hello")
    }

    @Test
    func `Double conforms to Carrier via stdlib integration`() {
        let d: Double = 3.14
        #expect(d.underlying == 3.14)
    }

    @Test
    func `Bool conforms to Carrier via stdlib integration`() {
        let b: Bool = true
        #expect(b.underlying == true)
    }

    @Test
    func `Character conforms to Carrier via stdlib integration`() {
        let c: Character = "A"
        #expect(c.underlying == "A")
    }

    @Test
    func `Substring conforms to Carrier via stdlib integration`() {
        let full = "hello world"
        let s: Substring = full.prefix(5)
        #expect(s.underlying == "hello")
    }

    @Test
    func `Int128 conforms to Carrier via stdlib integration`() {
        let big: Int128 = 123_456_789
        #expect(big.underlying == 123_456_789)
    }

    @Test
    func `Duration conforms to Carrier via stdlib integration`() {
        let d: Duration = .milliseconds(500)
        #expect(d.underlying == .milliseconds(500))
    }

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

    @Test
    func `Domain-constrained generic resolves Never for default-Domain conformer`() {
        // Exercises `where C.Domain: ~Copyable & ~Escapable` against a
        // conformer that uses the `Domain = Never` default. The generic
        // substitution machinery must (a) bind C.Domain to Never without
        // the caller spelling it out, and (b) confirm Never satisfies the
        // ~Copyable & ~Escapable constraint on the associated type.
        let c = Fixture.Plain(42)
        let d = Fixture.domainDescription(c)
        #expect(d == "Never")
    }
}
