import Carrier_Primitives_Test_Support
import Testing

@Suite
struct `UInt64+Carrier Tests` {
    @Suite struct Unit {}
    @Suite struct `Edge Case` {}
    @Suite struct Integration {}
    @Suite(.serialized) struct Performance {}
}

extension `UInt64+Carrier Tests`.Unit {

    @Test
    func `UInt64 round-trips via underlying`() {
        let v: UInt64 = 42
        #expect(v.underlying == 42)
    }

    @Test
    func `UInt64 round-trips via init from underlying`() {
        let v: UInt64 = 99
        #expect(UInt64(v.underlying) == 99)
    }
}

extension `UInt64+Carrier Tests`.`Edge Case` {

    @Test
    func `UInt64 handles min (zero)`() {
        let v: UInt64 = .min
        #expect(v.underlying == 0)
    }

    @Test
    func `UInt64 handles max`() {
        let v: UInt64 = .max
        #expect(v.underlying == .max)
    }
}

extension `UInt64+Carrier Tests`.Integration {

    @Test
    func `UInt64 satisfies some Carrier<UInt64>`() {
        #expect(Fixture.value(of: 7 as UInt64) == 7)
    }
}
