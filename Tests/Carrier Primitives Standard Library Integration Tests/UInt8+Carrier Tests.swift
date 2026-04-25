import Testing
import Carrier_Primitives_Test_Support

@Suite("UInt8+Carrier")
struct UInt8CarrierTests {
    @Suite struct Unit {}
    @Suite struct `Edge Case` {}
    @Suite struct Integration {}
    @Suite(.serialized) struct Performance {}
}

extension UInt8CarrierTests.Unit {

    @Test
    func `UInt8 round-trips via underlying`() {
        let v: UInt8 = 42
        #expect(v.underlying == 42)
    }

    @Test
    func `UInt8 round-trips via init from underlying`() {
        let v: UInt8 = 99
        #expect(UInt8(v.underlying) == 99)
    }
}

extension UInt8CarrierTests.`Edge Case` {

    @Test
    func `UInt8 handles min (zero)`() {
        let v: UInt8 = .min
        #expect(v.underlying == 0)
    }

    @Test
    func `UInt8 handles max`() {
        let v: UInt8 = .max
        #expect(v.underlying == .max)
    }
}

extension UInt8CarrierTests.Integration {

    @Test
    func `UInt8 satisfies some Carrier<UInt8>`() {
        #expect(Fixture.value(of: 7 as UInt8) == 7)
    }
}
