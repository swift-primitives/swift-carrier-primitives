import Testing
import Carrier_Primitives_Test_Support

@Suite
struct `UInt+Carrier Tests` {
    @Suite struct Unit {}
    @Suite struct `Edge Case` {}
    @Suite struct Integration {}
    @Suite(.serialized) struct Performance {}
}

extension `UInt+Carrier Tests`.Unit {

    @Test
    func `UInt round-trips via underlying`() {
        let v: UInt = 42
        #expect(v.underlying == 42)
    }

    @Test
    func `UInt round-trips via init from underlying`() {
        let v: UInt = 99
        #expect(UInt(v.underlying) == 99)
    }
}

extension `UInt+Carrier Tests`.`Edge Case` {

    @Test
    func `UInt handles min (zero)`() {
        let v: UInt = .min
        #expect(v.underlying == 0)
    }

    @Test
    func `UInt handles max`() {
        let v: UInt = .max
        #expect(v.underlying == .max)
    }
}

extension `UInt+Carrier Tests`.Integration {

    @Test
    func `UInt satisfies some Carrier<UInt>`() {
        #expect(Fixture.value(of: 7 as UInt) == 7)
    }
}
