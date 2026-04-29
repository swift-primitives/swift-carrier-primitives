import Testing
import Carrier_Primitives_Test_Support

@Suite
struct `UInt128+Carrier Tests` {
    @Suite struct Unit {}
    @Suite struct `Edge Case` {}
    @Suite struct Integration {}
    @Suite(.serialized) struct Performance {}
}

extension `UInt128+Carrier Tests`.Unit {

    @Test
    func `UInt128 round-trips via underlying`() {
        let v: UInt128 = 123_456_789
        #expect(v.underlying == 123_456_789)
    }

    @Test
    func `UInt128 round-trips via init from underlying`() {
        let v: UInt128 = 99
        #expect(UInt128(v.underlying) == 99)
    }
}

extension `UInt128+Carrier Tests`.`Edge Case` {

    @Test
    func `UInt128 handles min (zero)`() {
        let v: UInt128 = .min
        #expect(v.underlying == 0)
    }

    @Test
    func `UInt128 handles max`() {
        let v: UInt128 = .max
        #expect(v.underlying == .max)
    }
}

extension `UInt128+Carrier Tests`.Integration {

    @Test
    func `UInt128 satisfies some Carrier<UInt128>`() {
        #expect(Fixture.value(of: 7 as UInt128) == 7)
    }
}
