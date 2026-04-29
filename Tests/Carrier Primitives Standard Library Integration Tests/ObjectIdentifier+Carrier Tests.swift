import Carrier_Primitives_Test_Support
import Testing

@Suite
struct `ObjectIdentifier+Carrier Tests` {
    @Suite struct Unit {}
    @Suite struct `Edge Case` {}
    @Suite struct Integration {}
    @Suite(.serialized) struct Performance {}
}

// ObjectIdentifier needs a class instance to construct. We use a
// minimal local class for the test fixtures.

private final class Token {}

extension `ObjectIdentifier+Carrier Tests`.Unit {

    @Test
    func `ObjectIdentifier round-trips via underlying`() {
        let token = Token()
        let v = ObjectIdentifier(token)
        #expect(v.underlying == ObjectIdentifier(token))
    }

    @Test
    func `ObjectIdentifier round-trips via init from underlying`() {
        let token = Token()
        let v = ObjectIdentifier(token)
        #expect(ObjectIdentifier(v.underlying) == ObjectIdentifier(token))
    }
}

extension `ObjectIdentifier+Carrier Tests`.`Edge Case` {

    @Test
    func `ObjectIdentifier distinguishes distinct instances`() {
        let a = Token()
        let b = Token()
        let idA = ObjectIdentifier(a)
        let idB = ObjectIdentifier(b)
        #expect(idA.underlying != idB.underlying)
    }
}

extension `ObjectIdentifier+Carrier Tests`.Integration {

    @Test
    func `ObjectIdentifier satisfies some Carrier<ObjectIdentifier>`() {
        let token = Token()
        let v = ObjectIdentifier(token)
        #expect(Fixture.value(of: v) == ObjectIdentifier(token))
    }
}
