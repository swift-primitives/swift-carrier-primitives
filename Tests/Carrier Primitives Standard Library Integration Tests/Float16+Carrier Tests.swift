import Testing
import Carrier_Primitives_Test_Support

@Suite("Float16+Carrier")
struct Float16CarrierTests {
    @Suite struct Unit {}
    @Suite struct `Edge Case` {}
    @Suite struct Integration {}
    @Suite(.serialized) struct Performance {}
}

extension Float16CarrierTests.Unit {

    @Test
    func `Float16 round-trips via underlying`() {
        let v: Float16 = 1.5
        #expect(v.underlying == 1.5)
    }

    @Test
    func `Float16 round-trips via init from underlying`() {
        let v: Float16 = 2.5
        #expect(Float16(v.underlying) == 2.5)
    }
}

extension Float16CarrierTests.`Edge Case` {

    @Test
    func `Float16 handles zero`() {
        let v: Float16 = 0.0
        #expect(v.underlying == 0.0)
    }

    @Test
    func `Float16 handles infinity`() {
        let v: Float16 = .infinity
        #expect(v.underlying == .infinity)
    }

    @Test
    func `Float16 handles NaN (compared via bitPattern)`() {
        let v: Float16 = .nan
        #expect(v.underlying.bitPattern == Float16.nan.bitPattern)
    }
}

extension Float16CarrierTests.Integration {

    @Test
    func `Float16 satisfies some Carrier<Float16>`() {
        #expect(Fixture.value(of: 1.5 as Float16) == 1.5)
    }
}
