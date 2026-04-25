import Testing
import Carrier_Primitives_Test_Support

@Suite("UInt32+Carrier")
struct UInt32CarrierTests {
    @Suite struct Unit {}
    @Suite struct `Edge Case` {}
    @Suite struct Integration {}
    @Suite(.serialized) struct Performance {}
}

extension UInt32CarrierTests.Unit {

    @Test
    func `UInt32 round-trips via underlying`() {
        let v: UInt32 = 42
        #expect(v.underlying == 42)
    }

    @Test
    func `UInt32 round-trips via init from underlying`() {
        let v: UInt32 = 99
        #expect(UInt32(v.underlying) == 99)
    }
}

extension UInt32CarrierTests.`Edge Case` {

    @Test
    func `UInt32 handles min (zero)`() {
        let v: UInt32 = .min
        #expect(v.underlying == 0)
    }

    @Test
    func `UInt32 handles max`() {
        let v: UInt32 = .max
        #expect(v.underlying == .max)
    }
}

extension UInt32CarrierTests.Integration {

    @Test
    func `UInt32 satisfies some Carrier<UInt32>`() {
        #expect(Fixture.value(of: 7 as UInt32) == 7)
    }
}
