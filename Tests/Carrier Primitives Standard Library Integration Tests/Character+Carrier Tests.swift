import Carrier_Primitives_Test_Support
import Testing

@Suite
struct `Character+Carrier Tests` {
    @Suite struct Unit {}
    @Suite struct `Edge Case` {}
    @Suite struct Integration {}
    @Suite(.serialized) struct Performance {}
}

extension `Character+Carrier Tests`.Unit {

    @Test
    func `Character round-trips via underlying`() {
        let v: Character = "A"
        #expect(v.underlying == "A")
    }

    @Test
    func `Character round-trips via init from underlying`() {
        let v: Character = "Z"
        #expect(Character(v.underlying) == "Z")
    }
}

extension `Character+Carrier Tests`.`Edge Case` {

    @Test
    func `Character handles emoji grapheme cluster`() {
        let v: Character = "🌍"
        #expect(v.underlying == "🌍")
    }

    @Test
    func `Character handles combining scalars (single grapheme)`() {
        let v: Character = "é"
        #expect(v.underlying == "é")
    }

    @Test
    func `Character handles ZWJ family sequence`() {
        let v: Character = "👨‍👩‍👧"
        #expect(v.underlying == "👨‍👩‍👧")
    }
}

extension `Character+Carrier Tests`.Integration {

    @Test
    func `Character satisfies some Carrier<Character>`() {
        #expect(Fixture.value(of: "Q" as Character) == "Q")
    }
}
