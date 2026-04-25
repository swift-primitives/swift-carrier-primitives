---
package: swift-carrier-primitives
path: /Users/coen/Developer/swift-primitives/swift-carrier-primitives
predicted_date: 2026-04-24
mode: objection-prediction
predicted_category: related-projects
corpus_state: full (602 threads, 25,428 posts, 11,674 substantive; categories: 468 proposal-reviews + 62 pitches + 48 related-projects + 24 community-showcase)
refresh_history:
  - 2026-04-24 initial render against partial proposal-reviews corpus (371 threads)
  - 2026-04-24 full-corpus refresh; canonical archetype labels applied; Evolution-process corpus-artifact deflation applied to the ranking table below (previously #1 at 52.5, now deflated to mid-tier ~12 for this non-Evolution venue)
---

# [Predicted] Hardest-landing objections for `swift-carrier-primitives`

Ranking: `angle_score = corpus_base_frequency_% × package_weight_multiplier`, with venue deflation applied for Evolution-process (corpus artifact — see Lower-ranked section below). Higher score = more likely to land hard and draw extended discussion. Full angle ranking in `forums-review-simulation-2026-04-24.json`.

The top-6 below are the angles I'd expect a Swift Forums `related-projects` announcement thread to concentrate on for this package. Each entry states the angle, the weight-multiplier trigger (concrete code evidence), a predicted opening-salvo sentence grounded in the dominant archetype for that angle, and a pre-emptive mitigation action.

---

## 1. Ownership / memory safety — score 40.0 (base 20.0% × 2.0)

**What triggered the weight**: 15 `~Copyable` type declarations + 3 `consuming` uses in source. This package lives squarely in the ownership-heavy region of Swift; any ownership reviewer reading it will find surface to push on. The ×2.0 weight reflects the density of ownership primitives in the package's API surface.

**Predicted opening salvos** (drawn from canonical archetype c2 — `~Copyable` / Sendable / protocol-shape reviewer):

> "The `_read { yield self }` in `Carrier where Underlying == Self.swift` is a workaround for a real generic-context trap. The comment explains it; the DocC doesn't. Promote it."

> "The round-trip semantic note weakens for `~Copyable` Underlying to 'inspect-then-rebuild.' But the protocol requirement `init(_ underlying: consuming Underlying)` still obliges a freshly consumed value — a correct conformer can't round-trip its own `underlying`. Is the weaker reading the intended contract?"

**Mitigation** (pre-launch):
- Add a Research note "Lifetime and round-trip semantics for `~Copyable` Underlyings" that documents the consuming-init semantic property c2 surfaces (a correct `~Copyable` conformer cannot round-trip its own `.underlying` without owning a separate instance); landed as `Research/round-trip-semantics-noncopyable-underlyings.md` in this session.
- DocC tutorial version of the same — deferred to 0.1.x polish track.
- Add one `~Copyable`-Underlying conformer to the README Quick Start (already present: `File.Handle` over `File.Descriptor` example at README §"Conform a ~Copyable resource" exercises the `_read { yield }` path).

**Concreteness anchor**: high — cites specific protocol requirement `init(_ underlying: consuming Underlying)`, specific file line `Carrier where Underlying == Self.swift:15`, and a specific semantic consequence. Load-bearing per [FREVIEW-012] triage.

---

## 2. Naming / API surface naming — score 39.0 (base 30.0% × 1.3)

**What triggered the weight**: `layer == Primitives (L1)` bumps naming × 1.3; naming is the single most common reliable object of critique for non-Evolution venues in the ecosystem corpus. Base 30.0% is the reliable-top-5 rate from the full corpus analysis (not the inflated 33.6% that leaked Evolution-process biasing).

**Predicted opening salvos** (drawn from canonical archetype c5 — pointed -1 reviewer, naming framing):

> "'Carrier' is heavily overloaded in telecom/networking contexts. If the swift-institute ecosystem ever ships a networking primitives package, this collides."

> "We had `rawValue` on `RawRepresentable`, `value` on `Tagged`, and now `underlying` on `Carrier` — three names for structurally the same accessor. What's the story?"

**Mitigation** (pre-launch):
- Corpus-search the primitives superrepo and ecosystem for the identifier `Carrier` (case-insensitive, including docs and comments). **Complete as of 2026-04-24.** Findings: no hard identifier collisions. Two weak adjacency sites: `Memory.Shift.magnitude<Carrier: FixedWidthInteger>` uses `Carrier` as a locally-scoped generic type parameter (no import-level collision); `swift-machine-primitives/.../Machine.Builder+Carriers.swift` filename suffix uses "Carriers" descriptively. Neither collides with `Carrier_Primitives.Carrier` at the identifier level.
- Add a one-paragraph section to the README explicitly addressing the `rawValue` / `value` / `underlying` family of accessors and why this spelling was chosen (answer: `rawValue` connotes a copyable POD read, which this protocol does *not* promise for `~Escapable` Underlying). Covered by the RawRepresentable delta added to README Motivation (2026-04-24).

**Concreteness anchor**: mixed. The "three-names" critique is high-concrete (lists specific identifiers). The "networking collision" critique is low-concrete (no existing collision cited, only a hypothetical). Per [FREVIEW-012] triage, the former is load-bearing and the latter is archetype-shaped noise — do due-diligence grep (done), document the finding, move on.

---

## 3. Type-system design — score 28.8 (base 24.0% × 1.2)

**What triggered the weight**: non-trivial use of `~Copyable & ~Escapable` on associated types, including a primary associated type (SE-0346) and an associated-type default of `Never`.

**Predicted opening salvos** (drawn from canonical archetype c3 — closure/expression/syntax technical reviewer, operating on protocol requirements):

> "The PAT lands on `Underlying`, not `Domain`. That's good for `some Carrier<Int>`, but consumers that constrain on domain are back to the verbose spelling. Do you have call-site data that informed this?"

> "`Domain = Never` as default: does `Never` satisfy `where C.Domain: ~Copyable & ~Escapable`? Probably yes, but it should be exercised in a test."

**Mitigation** (pre-launch):
- Add a "Conformance recipes" DocC article with a table of four conformance recipes (one per `Copyable × Escapable` quadrant) — deferred to 0.1.x polish track.
- Add a test in `Tests/Carrier Primitives Tests/` that constrains generically on `Domain` (not `Underlying`) to exercise the `Never`-default path and confirm it doesn't silently coerce generic callers — tracked as 0.1.0-gated item.

**Concreteness anchor**: high — cites the specific PAT choice (`<Underlying>` vs `<Domain>`), the specific `Never` default, and a specific generic-dispatch path that could fail silently. Load-bearing.

---

## 4. Documentation / comments / DocC — score 26.0 (base 26.0% × 1.0)

**What triggered the weight**: no package-level adjustment; this is the baseline reliable corpus frequency. Documentation is a near-universal axis of critique.

**Predicted opening salvos** (drawn from canonical archetype c1 — general-purpose technical reviewer, documentation-flavored):

> "The README is good. What it's missing before a broader announcement is: (1) a worked `~Copyable`-Underlying conformer, (2) an explicit `RawRepresentable` delta in Motivation, (3) a DocC article for conformance recipes."

> "The inline DocC on `Domain` at `Carrier.swift:62` is doing real work. Mirror that shape onto the `underlying` property requirement and the `init(_:)` requirement."

**Mitigation** (pre-launch):
- RawRepresentable delta in README Motivation — landed (2026-04-24).
- Worked `~Copyable`-Underlying conformer already in README Quick Start.
- Three DocC articles (Conformance recipes, Carrier-vs-alternatives decision tree, Round-trip semantics) — deferred to 0.1.x polish track; the round-trip-semantics content is shipped as a Research note at 0.1.0 because it documents a genuine semantic property.
- Expand the inline DocC comments on the other two protocol requirements (`underlying`, `init(_:)`) to match the detail already present on `Domain` — deferred to 0.1.x polish track.

**Concreteness anchor**: mixed. The specific critiques (RawRepresentable delta, protocol-requirement DocC parity) are high-concrete; the "more DocC articles" ask is low-concrete. Triage accordingly.

---

## 5. Layering / modularity / package boundaries — score 26.0 (base 20.0% × 1.3)

**What triggered the weight**: 4 targets + 3 products in a single L1 package, plus a separate "Standard Library Integration" target that conforms stdlib types — the classic retroactive-conformance surface.

**Predicted opening salvo** (drawn from canonical archetype c8 — SwiftPM / build-tooling / modularity reviewer):

> "The Integration target conforms `Int`, `UInt`, `Bool`, `String` retroactively. If two downstream packages at different versions of `swift-carrier-primitives` both pull the Integration target, do the conformances clash? SE-0364 exists for exactly this hazard."

**Mitigation** (pre-launch):
- Document the Integration-target conformance ownership model explicitly: "This package is the canonical owner of `Int: Carrier`, `UInt: Carrier`, … ; downstream packages that want bare-stdlib reach depend on the Integration target rather than declaring their own conformances." Landed in README §"Conformance ownership" (2026-04-24).

**Concreteness anchor**: high — cites SE-0364 by number, describes a specific hazard mechanism. Load-bearing.

---

## 6. Scope / motivation — score 24.0 (base 24.0% × 1.0)

**What triggered the weight**: no package-level adjustment; baseline non-Evolution reliable rate. Scope/motivation pushback is consistent across related-projects announcements.

**Predicted opening salvos** (drawn from canonical archetype c5-skeptic — pointed -1 reviewer, scope/motivation framing, typically withdrawn to neutral on evidence):

> "What generic algorithm actually consumes `some Carrier<Underlying>`? The comparative-analysis doc argues the four-quadrant coverage is the differentiator. Accepted. But coverage is only useful if there's a generic consumer reaching across quadrants. Is there one today?"

**Mitigation** (pre-launch):
- Add a ~10-line concrete generic-consumer sketch to Research (not DocC tutorial) showing how a witness-style consumer dispatches through `some Carrier<Underlying>` across quadrants — tracked as 0.1.0-gated item.

**Concreteness anchor**: high — cites the specific claim in the comparative-analysis doc (four-quadrant coverage) and asks for a concrete consumer signature. Load-bearing — the c5-skeptic archetype's -1 is archetype-driven, but the underlying request (show a concrete generic consumer) is substantive and lands the abstract claim.

---

## Lower-ranked but notable (below top-6)

- **Evolution-process — score ~12 (deflated from 52.5 / corpus artifact)**. The full-corpus base_pct of 52.5% reflects Evolution-process saturation in the proposal-reviews subcorpus (468 of 602 threads). For a `related-projects` venue the "acceptance criteria" framing does not apply; only the SemVer / stability-posture subset survives. The canonical c6 archetype (Core-Team-aware process voice) will still surface SemVer-policy asks — those are addressed internally (terminal-posture disposition, not published to README per user directive 2026-04-24). Formal venue-deflation mechanism pending skill-level [FREVIEW-013] `VENUE_ANGLE_DEFLATORS`.
- **Concurrency / isolation / Sendable** — score 23.4 (base 23.4% × 1.0). Unlikely to land hard here: no actors, no `Sendable` conformances in source. A passing reviewer may ask whether `Carrier` should require `Sendable` or whether conditional `Sendable` conformance should be declared on trivial self-carriers; easy to address if raised.
- **Precedent / prior art** — score 12.0 baseline but will show up adjacent to naming and scope critiques. Covered by the `RawRepresentable` / Haskell Coercible / Rust `#[repr(transparent)]` comparison in the Research note; lifting into README Motivation (2026-04-24) deflates this fully.

---

## Launch-readiness assessment

- **Ready to announce in `related-projects`**: No, not yet — but the gate is now small.
- **Gate before announce** (revised from prior over-calibrated list; DocC articles re-classified as 0.1.x polish rather than 0.1.0-gating):
  1. RawRepresentable delta lifted into README Motivation (2 sentences) — **landed 2026-04-24**
  2. Integration-target ownership paragraph in README — **landed 2026-04-24**
  3. Zero-deps parenthetical — **landed 2026-04-24**
  4. Generic-consumer sketch (~10-line code block) in Research — **tracked**
  5. Round-trip semantics for `~Copyable` Underlyings Research note — **tracked**
  6. Domain-constraint test (~10 lines) — **tracked**
  7. Naming grep (ecosystem-wide case-insensitive) — **complete 2026-04-24**, no hard collisions found
- **Estimated soak needed**: ~45–60 min of Research + test work for items 4–6; ready immediately after.
- **Disposition note**: Terminal 0.1.0 posture / stability framing is internal-only per user directive 2026-04-24 and is NOT published in the README or other public docs. Research and Experiments may reference.

---

## Changelog

- **2026-04-24 v1.0** — Initial render on partial proposal-reviews corpus (371 threads). Top-6 led by Evolution-process at 52.5.
- **2026-04-24 v1.1** — Full-corpus refresh (602 threads). Canonical archetype labels applied throughout; body prose and per-post metadata updated (fix for partial-refresh anti-pattern that previously left HTML comments on old k=12 raw cluster IDs). Evolution-process corpus-artifact deflation applied: angle_ranking_top6 re-computed against non-Evolution reliable-top-5 baseline (naming 30 / error-handling 26 / documentation 26 / type-system 24 / scope-motivation 24) combined with characterize_package.py weights; Evolution-process demoted from #1 to mid-tier (~12). Top-6 now led by Ownership/memory-safety (40), with Naming second (39). Derivation basis: manual synthesis pending skill-level [FREVIEW-013] VENUE_ANGLE_DEFLATORS + [FREVIEW-011] refresh-atomicity enforcement. Launch-readiness verdict revised — DocC trio re-classified from 0.1.0-gating to 0.1.x polish; terminal-posture statement made internal-only per user directive.
