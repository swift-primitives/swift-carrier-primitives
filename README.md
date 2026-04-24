# Carrier Primitives

![Development Status](https://img.shields.io/badge/status-experimental-red.svg)

Research-stage super-abstraction over phantom-typed value wrappers — the `Carrier<Underlying>` protocol family that Tagged, Cardinal, Ordinal, Hash.Value, and similar value-carrying primitives are candidates to conform to.

---

## Status

This package is **research-stage**, not production-ready. The `Carrier<Underlying>` protocol's final shape is still converging through experiments in `Experiments/` and design analysis in `Research/`. Consumers SHOULD NOT depend on this package yet.

The design question: given recurring patterns across `Cardinal.\`Protocol\``, `Ordinal.\`Protocol\``, `Hash.\`Protocol\``, and `Tagged<Tag, V>` — can a super-protocol factor out the shared structure (Domain associatedtype + value accessor + round-trip init + Tagged forwarding) without breaking per-type ergonomics?

The current state of the investigation:

- **Recipe characterized** — `Research/capability-lift-pattern.md` documents the shared structure and ecosystem instances.
- **Options analysed** — Option A (refinement), Option B (parameterized `Carrier<Underlying>` via SE-0346), Option C (both). Option B is the current recommendation.
- **Experiments CONFIRMED** — `Experiments/capability-lift-pattern/` has six variants (V0–V5) probing the recipe, super-protocol unification options, API broadening, and limits (generic Underlying, `~Copyable` Underlying, existentials).
- **Adoption DEFERRED** — Cardinal/Ordinal don't need to change to participate; Carrier can be added later as a one-extension migration per conforming type. The decision gate is a concrete Form-D use case (cross-Carrier generic algorithms).

---

## Architecture (intended)

Once `Carrier<Underlying>` converges, the package is expected to ship:

- `Carrier<Underlying>` — the super-protocol (Option B form, parameterized).
- Possibly `NoncopyCarrier<Underlying>` — the `~Copyable` Underlying variant (the research's V5b shows round-trip breaks on a unified protocol).
- Extension points for ecosystem types to conform (`Tagged: Carrier`, `Cardinal: Carrier`, `Ordinal: Carrier`, etc.) — placed in each conforming type's home package.
- Test support for verifying conformance.

---

## Relationship to other primitives

| Package | Relationship |
|---------|--------------|
| [swift-tagged-primitives](https://github.com/swift-primitives/swift-tagged-primitives) | **Canonical Carrier.** `Tagged<Tag, V>` is the free generic implementation — any `(Tag, V)` combination becomes a Carrier of V with `Domain = Tag`. The `Tagged: Carrier` conformance file will live in this package once the protocol lands. |
| [swift-cardinal-primitives](https://github.com/swift-primitives/swift-cardinal-primitives) | Candidate adopter. `Cardinal` is a trivial Carrier (`Domain = Never`); `Tagged<T, Cardinal>` is a tagged Carrier. Both shapes conform. |
| [swift-ordinal-primitives](https://github.com/swift-primitives/swift-ordinal-primitives) | Candidate adopter. Same shape as Cardinal. |
| [swift-hash-primitives](https://github.com/swift-primitives/swift-hash-primitives) | Candidate adopter. `Hash.Value` is the Underlying; `Hash.\`Protocol\`` follows the recipe. |
| [swift-property-primitives](https://github.com/swift-primitives/swift-property-primitives) | **Categorically blocked** from Carrier. Property's Tag is a verb-namespace (Group B per `property-tagged-semantic-roles.md`), not a domain-identity. Cross-fiber morphisms don't exist in verb-namespaces, so Carrier's round-trip can't be made coherent. See `Research/capability-lift-pattern.md` §"Pattern taxonomy". |

---

## License

Apache 2.0. See [LICENSE.md](LICENSE.md).
