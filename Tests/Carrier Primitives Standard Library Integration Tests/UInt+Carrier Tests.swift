import Testing
import Carrier_Primitives_Test_Support

@Suite("UInt+Carrier")
struct UIntCarrierTests {
    @Suite struct Unit {}
    @Suite struct `Edge Case` {}
    @Suite struct Integration {}
    @Suite(.serialized) struct Performance {}
}

extension UIntCarrierTests.Unit {

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

extension UIntCarrierTests.`Edge Case` {

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

extension UIntCarrierTests.Integration {

    @Test
    func `UInt satisfies some Carrier<UInt>`() {
        #expect(Fixture.value(of: 7 as UInt) == 7)
    }
}
