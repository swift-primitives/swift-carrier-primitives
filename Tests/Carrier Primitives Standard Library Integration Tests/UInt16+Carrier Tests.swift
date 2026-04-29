import Testing
import Carrier_Primitives_Test_Support

@Suite
struct `UInt16+Carrier Tests` {
    @Suite struct Unit {}
    @Suite struct `Edge Case` {}
    @Suite struct Integration {}
    @Suite(.serialized) struct Performance {}
}

extension `UInt16+Carrier Tests`.Unit {

    @Test
    func `UInt16 round-trips via underlying`() {
        let v: UInt16 = 42
        #expect(v.underlying == 42)
    }

    @Test
    func `UInt16 round-trips via init from underlying`() {
        let v: UInt16 = 99
        #expect(UInt16(v.underlying) == 99)
    }
}

extension `UInt16+Carrier Tests`.`Edge Case` {

    @Test
    func `UInt16 handles min (zero)`() {
        let v: UInt16 = .min
        #expect(v.underlying == 0)
    }

    @Test
    func `UInt16 handles max`() {
        let v: UInt16 = .max
        #expect(v.underlying == .max)
    }
}

extension `UInt16+Carrier Tests`.Integration {

    @Test
    func `UInt16 satisfies some Carrier<UInt16>`() {
        #expect(Fixture.value(of: 7 as UInt16) == 7)
    }
}
