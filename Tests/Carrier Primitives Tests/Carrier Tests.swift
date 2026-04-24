import Testing
import Carrier_Primitives
import Carrier_Primitives_Test_Support

@Suite("Carrier")
struct CarrierTests {
    @Suite struct Unit {}
}

extension CarrierTests.Unit {
    @Test
    func `Carrier namespace exists`() {
        // Smoke test — confirms the package builds + test target links.
        // Substantive tests will accompany Carrier protocol landings as
        // research converges. See Research/capability-lift-pattern.md.
        #expect(Bool(true))
    }
}
