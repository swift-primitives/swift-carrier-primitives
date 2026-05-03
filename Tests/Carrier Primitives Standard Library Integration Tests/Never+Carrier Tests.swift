import Carrier_Primitives_Test_Support
import Testing

@Suite
struct `Never+Carrier Tests` {
    @Suite struct Unit {}
    @Suite struct `Edge Case` {}
    @Suite struct Integration {}
    @Suite(.serialized) struct Performance {}
}

// Never is uninhabited; no value can exist. The conformance is
// verifiable at type level only — the protocol is satisfied by the
// default `where Underlying == Self` extension with Self == Never.

extension `Never+Carrier Tests`.`Edge Case` {

    @Test
    func `Never conforms to Carrier at the type level`() {
        // This test confirms the conformance is present in the
        // module's conformance table.
        func _requireCarrier<T: Carrier.`Protocol` & ~Copyable & ~Escapable>(_: T.Type) {}
        _requireCarrier(Never.self)
        #expect(Bool(true))
    }

    @Test
    func `Never's Underlying is Never at the type level`() {
        #expect(Never.Underlying.self == Never.self)
    }

    @Test
    func `Never's Domain defaults to Never`() {
        #expect(Never.Domain.self == Never.self)
    }
}
