import Testing
import Carrier_Primitives_Test_Support

@Suite("Double+Carrier")
struct DoubleCarrierTests {
    @Suite struct Unit {}
    @Suite struct `Edge Case` {}
    @Suite struct Integration {}
    @Suite(.serialized) struct Performance {}
}

extension DoubleCarrierTests.Unit {

    @Test
    func `Double round-trips via underlying`() {
        let v: Double = 3.14
        #expect(v.underlying == 3.14)
    }

    @Test
    func `Double round-trips via init from underlying`() {
        let v: Double = 2.71828
        #expect(Double(v.underlying) == 2.71828)
    }
}

extension DoubleCarrierTests.`Edge Case` {

    @Test
    func `Double handles zero`() {
        let v: Double = 0.0
        #expect(v.underlying == 0.0)
    }

    @Test
    func `Double handles negative zero (preserves sign)`() {
        let v: Double = -0.0
        #expect(v.underlying.bitPattern == Double(-0.0).bitPattern)
    }

    @Test
    func `Double handles infinity`() {
        let v: Double = .infinity
        #expect(v.underlying == .infinity)
    }

    @Test
    func `Double handles negative infinity`() {
        let v: Double = -.infinity
        #expect(v.underlying == -.infinity)
    }

    @Test
    func `Double handles NaN (compared via bitPattern)`() {
        let v: Double = .nan
        #expect(v.underlying.bitPattern == Double.nan.bitPattern)
    }
}

extension DoubleCarrierTests.Integration {

    @Test
    func `Double satisfies some Carrier<Double>`() {
        #expect(Fixture.value(of: 7.5 as Double) == 7.5)
    }
}
