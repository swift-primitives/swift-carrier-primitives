---
package: swift-carrier-primitives
path: /Users/coen/Developer/swift-primitives/swift-carrier-primitives
simulated_date: 2026-04-24
predicted_category: related-projects
corpus_state: full (602 threads, 25,428 posts, 11,674 substantive — 468 proposal-reviews + 62 pitches + 48 related-projects + 24 community-showcase)
archetypes_used:
  - "post 2  — c2 The ~Copyable / Sendable / protocol-shape reviewer"
  - "post 3  — c3 The closure/expression/syntax technical reviewer (operating on protocol requirements)"
  - "post 4  — c5 The pointed -1 reviewer"
  - "post 5  — c4 The constructive Evolution-process reviewer (with prior-art framing)"
  - "post 6  — c8 The SwiftPM / build-tooling / modularity reviewer"
  - "post 7  — c1 The general-purpose technical reviewer (documentation-flavored)"
  - "post 8  — c6 The Core-Team-aware process voice"
  - "post 9  — c5 The pointed -1 reviewer (scope/motivation framing, withdrawn to neutral)"
  - "post 10 — short community nit (not a dedicated cluster; sampled from short-form substantive posts)"
seed: 7
note: This is an INTERNAL simulation artifact. Handles are anonymized (@reviewer-N). Do NOT post anywhere.
---

# [Simulated] Introducing: Carrier Primitives — a unified super-protocol for phantom-typed value wrappers

<!-- archetype: OP (author voice) — not from cluster; authored as the package maintainer -->

### Post 1 — @op

Hi all,

I've just tagged a release of `swift-carrier-primitives` — a small L1 package in the Swift Institute primitives ecosystem that declares a single protocol, `Carrier<Underlying>`, intended to unify the phantom-typed value wrappers we've accumulated over the last year: `Tagged`, `Cardinal`, `Ordinal`, `Hash.Value`, and friends.

The shape is minimal:

```swift
public protocol Carrier<Underlying>: ~Copyable, ~Escapable {
    associatedtype Domain:     ~Copyable & ~Escapable = Never
    associatedtype Underlying: ~Copyable & ~Escapable

    var underlying: Underlying {
        @_lifetime(borrow self)
        borrowing get
    }

    @_lifetime(copy underlying)
    init(_ underlying: consuming Underlying)
}
```

What it buys:

1. **Coverage across all four `Copyable × Escapable` quadrants in one declaration.** `borrowing get` + `consuming init(_:)` degenerates gracefully on `Copyable & Escapable` Underlyings and carries its weight on `~Copyable & ~Escapable` ones.
2. **Primary associated type on `Underlying`.** SE-0346 spelling — `some Carrier<Int>` at API sites without named-argument verbosity.
3. **Stdlib integration ships as a separate target.** `Int`, `UInt`, `Bool`, `String`, etc. conform as trivial self-carriers (`Underlying == Self`) so bare stdlib values reach `some Carrier<Int>` APIs without wrapping. Consumers opt in by importing the integration module.
4. **Zero dependencies.** Ships the protocol only. Conformances for `Tagged` / `Cardinal` / `Ordinal` live in their respective home packages.

Design analysis is in `Research/capability-lift-pattern.md`; the comparative against `RawRepresentable` is in `Research/carrier-vs-rawrepresentable-comparative-analysis.md`.

What I'm looking for: feedback on whether `Carrier` is the right name, whether the round-trip semantics note (inspect-then-rebuild for `~Copyable` Underlying) is clear enough, and whether the Stdlib Integration target's default trivial self-carriers raise any adoption concerns.

---

### Post 2 — @reviewer-c2

<!-- archetype: The ~Copyable / Sendable / protocol-shape reviewer (canonical c2) — target: ownership-memory, naming, type-system — opener: direct-stance — closer: question-to-author -->

Reading this carefully. The `borrowing get` + `consuming init(_:)` pairing is the right primitive — I expected to see `_read { yield self }` show up somewhere and of course there it is, in `Sources/Carrier Primitives/Carrier where Underlying == Self.swift:15`:

```swift
extension Carrier where Underlying == Self {
    public var underlying: Self {
        _read { yield self }
    }
    ...
}
```

The comment calls out the subtle reason for `_read` over `borrowing get` in the generic trivial-carrier case (Self may be suppressed-`~Copyable`), which is exactly the trap I was looking for. Worth promoting that comment into the DocC article — it's the kind of thing a conformer author needs to know before they reach for the short spelling.

One thing I'd push on: the "round-trip" note says, for `~Copyable` Underlying, round-trip weakens to "inspect-then-rebuild." That's true at the operational level, but the protocol requirement as stated — `init(_ underlying: consuming Underlying)` — obliges the conformer to produce an instance from a *freshly consumed* value, not from the borrow exposed by the getter. So a correct `~Copyable` conformer can't round-trip its own `underlying` without owning a separate instance. Is that the intended reading? The README's Quick Start example only shows a `Copyable` (UInt64-backed) conformer, which dodges the question. A `~Copyable` conformer in the examples would sharpen things considerably.

---

### Post 3 — @reviewer-c3

<!-- archetype: The closure/expression/syntax technical reviewer (canonical c3) — target: type-system, ownership-memory, evolution-process — opener: thanks — closer: recommendation -->

Thanks for pushing this out — the "one protocol, four quadrants" claim holds up for the protocol *declaration*, but I want to check whether it holds up at *conformance sites* and at *use sites*.

At conformance sites: a `~Copyable` Underlying conformer needs `_read` (per @reviewer-c2 above); a `Copyable & ~Escapable` Underlying conformer needs the `@_lifetime(borrow self)` on the getter to carry the right scope bound. Four quadrants → effectively three conformance recipes plus the trivial-self default. Worth a table in the DocC article. Right now the README has a lovely shape diagram but not a "pick your conformance recipe" table.

At use sites: the primary associated type lands on `Underlying`, not `Domain`. That's the right call for consumers who want `some Carrier<Int>` — but it means a consumer constraining on domain (`some Carrier where Domain == User`) is back to the verbose spelling. If a significant fraction of ecosystem use sites constrain on `Domain`, the PAT choice is pointing the wrong way. Do you have call-site telemetry from the existing Tagged/Cardinal/Ordinal consumers that informs this?

The `Domain = Never` default is clever — it makes trivial self-carriers declare just `typealias Underlying = Self` — but `Never` in associated-type position has always been a little load-bearing when it comes to the standard library integration story. If `Int: Carrier` gets `Domain = Never`, and a generic function constrains `where C.Domain: ~Copyable & ~Escapable`, does `Never` satisfy that? (I think yes because `Never` has default conformance to everything, but this is worth a test that exercises the generic domain-constraint path.)

Recommendation: add a DocC article titled "Conformance recipes" with one worked example per quadrant, and add a test in `Tests/Carrier Primitives Tests/` that constrains on `Domain` to confirm the `Never`-default path doesn't silently coerce generic callers.

---

### Post 4 — @reviewer-c5

<!-- archetype: The pointed -1 reviewer (canonical c5, naming framing) — target: naming, precedent-prior-art, scope-motivation — opener: direct-stance — closer: withdraw-hedge -->

-1 on the name. "Carrier" is heavily overloaded in telecom/networking contexts, and anyone who works on anything transport-adjacent will read `import Carrier_Primitives` and expect packet carriers, not value wrappers. If the swift-institute ecosystem ever ships a networking primitives package, the naming collision will be ugly. Prior art in this space — Rust's newtype idiom, Haskell's `newtype`, Scala's opaque types, C#'s value objects — none use the word "carrier." The closest technical term I've seen in the literature is "transparent wrapper" or "envelope."

Also: `carrier.underlying` reads fine, but the protocol name + property name pair reads as tautological. `Carrier.underlying` is "the underlying value of the carrier," which — what else would it be? The ecosystem had `rawValue` for `RawRepresentable`, `value` for `Tagged`, and now `underlying` as a third name for effectively the same concept. I'd want to see the comparative-analysis doc (`Research/carrier-vs-rawrepresentable-comparative-analysis.md`) explicitly argue why this is not a third spelling but a unification — and specifically what stops us from calling the property `raw` or keeping `rawValue`.

Could be I'm wrong; just flagging it up-front.

---

### Post 5 — @reviewer-c4

<!-- archetype: The constructive Evolution-process reviewer (canonical c4, prior-art framing) — target: precedent-prior-art, evolution-process, naming — opener: meta-comment — closer: recommendation -->

First, a meta-comment on what this package *is*. Reading the README, `Carrier<Underlying>` is structurally very close to `RawRepresentable` — same shape, same intent (a lifting of a primitive into a typed wrapper). The differences are (a) four-quadrant support via `~Copyable & ~Escapable`, (b) the `Domain` phantom axis, (c) `consuming` init + `borrowing` get instead of `rawValue: RawValue` getter. These are genuine upgrades, but the pitch should foreground the delta against `RawRepresentable` more aggressively than "see `Research/carrier-vs-rawrepresentable-comparative-analysis.md`." Most readers aren't going to click through.

Prior art worth naming explicitly:

- **`RawRepresentable` (stdlib)**: the thing people already know. A single paragraph in the README explaining why `Carrier` isn't "another `RawRepresentable`" would head off 80% of the scope-motivation objections.
- **Haskell's `Coercible` class + newtype deriving**: the closest formal analogue. Coercible is the compiler-enforced version of "these two types have identical representation"; Carrier is declaring a *protocol* for the same relationship. The trade-off — runtime cost, type-checker cost, generic-algorithm reach — is worth a paragraph.
- **Rust's `#[repr(transparent)]` + `From`/`Into`**: transparent newtype + conversion traits. Analogous in purpose, totally different in mechanism.

Recommendation: lift the `RawRepresentable` comparison out of the Research note and into the README's Motivation section. If the answer to "why not `RawRepresentable`?" is "suppression of `~Copyable` and `~Escapable` on `Self` and `Underlying`," say so in two sentences above the protocol shape block.

---

### Post 6 — @reviewer-c8

<!-- archetype: The SwiftPM / build-tooling / modularity reviewer (canonical c8) — target: layering-modularity, naming, evolution-process — opener: question — closer: question-to-author -->

Question about the Stdlib Integration target.

Looking at `Package.swift`, there are three products: `Carrier Primitives`, `Carrier Primitives Standard Library Integration`, and `Carrier Primitives Test Support`. The Integration product conforms `Int`, `UInt`, `Bool`, `String`, etc. to `Carrier` as trivial self-carriers. That's useful — bare stdlib values reach `some Carrier<Int>` APIs for free — but it has a retroactive-conformance smell. Two concerns:

1. If a downstream consumer imports `Carrier_Primitives_Standard_Library_Integration`, they permanently conform `Int: Carrier` in their module graph. If a *different* downstream does the same at a different version of this package, do the two conformances clash? Swift's retroactive-conformance warning (SE-0364) exists precisely for this class of hazard. I'd expect the Integration target to acknowledge this in its README / DocC.

2. The "home-package ownership" principle for conformances says `Tagged: Carrier` lives in `swift-tagged-primitives`, `Cardinal: Carrier` lives in `swift-cardinal-primitives`, etc. — great, that follows the Institute's layering discipline. But `Int: Carrier` can't live in the stdlib, so by process of elimination it lives in *this* package's Integration target. That's fine as long as `Int: Carrier` conformance is a canonical, stable artifact. Is the intent that every ecosystem package that consumes `some Carrier<Int>` depends on this Integration target, or does each package do its own `Int: Carrier` conformance locally? The answer has layering consequences either way.

---

### Post 7 — @reviewer-c1

<!-- archetype: The general-purpose technical reviewer (canonical c1, documentation-flavored) — target: documentation, api-ergonomics, precedent-prior-art — opener: thanks — closer: recommendation -->

The README is in excellent shape — clear shape block, concrete Quick Start, explicit "Foundation-free" call-out. A few asks from the docs angle.

The DocC catalog at `Sources/Carrier Primitives/Carrier Primitives.docc` is present; I'd like to see three articles land there before a broader announcement:

1. **"Conformance recipes"** — one worked example per quadrant, as @reviewer-c3 asked for (unchanged handle; c3 is canonical).
2. **"When to use `Carrier` vs. `RawRepresentable` vs. `Tagged` directly"** — a decision tree for ecosystem authors who are about to reach for `RawRepresentable` out of habit.
3. **"Lifetime and round-trip semantics for `~Copyable` Underlyings"** — the "inspect-then-rebuild" note from the protocol docstring deserves its own article, with a code example that actually fails to compile in the round-trip-extract sense so the reader sees the linear-type weakening concretely.

The inline DocC comments on the protocol requirements themselves are good — the comment on `Domain` explaining the `User`/`Order` distinction at `Sources/Carrier Primitives/Carrier.swift:62` is doing real work. I'd mirror that shape of comment onto the `underlying` property requirement and the `init(_:)` requirement.

One small API ergonomics note: the init is spelled `init(_ underlying: consuming Underlying)` — positional, no label. That's consistent with Swift convention for wrapper inits, but the ecosystem has occasionally preferred labeled inits when the argument is semantically load-bearing. Given `Carrier` is *exactly* about the lift into a typed wrapper, I think unlabeled is right here — just noting that a future reviewer will ask.

---

### Post 8 — @reviewer-c6

<!-- archetype: The Core-Team-aware process voice (canonical c6) — target: evolution-process, layering-modularity, abi-source-stability — opener: question — closer: recommendation -->

What's the SemVer discipline for this package?

Because `Carrier` is a protocol, every breaking change to the protocol is a breaking change to every conformer's home package in the ecosystem. If the protocol gets a new requirement in 2.0 — say, a `map` or `withUnderlying` — every `Tagged`, `Cardinal`, `Ordinal`, `Hash.Value` conformance breaks and the entire primitives layer needs to bump coordinated-with-this. That's a fine policy if it's the policy. But I don't see it stated in the README.

Concretely: the README currently reads `status: active-development`. For an L1 protocol package that the rest of the ecosystem depends on for conformance shape, the policy I'd expect is "1.0 is committed; post-1.0, new requirements always arrive with default implementations." Otherwise this package becomes a breakage engine for the layer above.

Recommendation: add a `## Stability and compatibility` section to the README with the SemVer policy written down — especially the "default implementation required for new requirements" clause — before tagging anything that downstream packages pin to.

---

### Post 9 — @reviewer-c5b

<!-- archetype: The pointed -1 reviewer (canonical c5, scope/motivation framing, withdrawn to neutral) — target: scope-motivation, precedent-prior-art, api-ergonomics — opener: meta-comment — closer: withdraw-hedge -->

Broadly — and I want to be constructive here — I'd like to see the "what generic code actually consumes `some Carrier<Underlying>`" question answered with a real example from the ecosystem. The README lists what `Carrier` is and what shape it has; it doesn't show me a function signature *anywhere in the rest of the primitives superrepo* that benefits from the abstraction.

The comparative-analysis doc against `RawRepresentable` argues the four-quadrant coverage is the differentiator. Accepted. But coverage is only useful if there's a generic consumer reaching across quadrants. Is there one today? If `Tagged`, `Cardinal`, and `Ordinal` are the three big conformers, and each of their consumers constrains on the concrete type rather than `some Carrier`, then `Carrier` is solving a problem that the ecosystem hasn't yet encountered.

I'd weaken my "-1" to a "neutral" if the README or Research note had an example like: "Here's a serialization witness in `swift-X-foundations` that used to pattern-match on `Tagged | Cardinal | Ordinal` and now dispatches through `some Carrier<Underlying>` — 40 lines deleted, one protocol constraint added."

Could be the example exists and I'm missing it; happy to be pointed at it.

---

### Post 10 — @reviewer-short

<!-- archetype: brief nit (community-voice, short form) — target: documentation — opener: apology-hedge — closer: question-to-author -->

Sorry, small thing — the README says "Zero dependencies" but `Package.swift` declares `Carrier Primitives Test Support` with dependencies. Presumably that's scoped to the test-support target only and the core `Carrier Primitives` product really is zero-dep, but the README reads as if the whole package is zero-dep. Worth a parenthetical?

---

### Post 11 — @op (follow-up)

<!-- archetype: OP follow-up — consolidating responses -->

Thank you all — keeping this short and triaging into concrete actions:

- **@reviewer-c2, @reviewer-c3**: Will add the "Conformance recipes" DocC article with a worked `~Copyable` conformer example, and a test that constrains on `Domain` to exercise the `Never`-default path. Filing as action items.
- **@reviewer-c5 (naming)**: The "networking collision" concern is legitimate. Filing an issue; will do a corpus search of the ecosystem for `Carrier` conflicts and revisit pre-release. On `rawValue` vs `underlying`: the deliberate reason is the `~Escapable` Underlying case, where `rawValue` connotes a copyable plain-old-data read that the protocol actively does *not* promise. Will hoist this into the README.
- **@reviewer-c4**: Lifting the `RawRepresentable` comparison into the README Motivation section. Good call.
- **@reviewer-c8**: Great question on the Integration target. The intended model is "each ecosystem package that wants `some Carrier<Int>` reach depends on the Integration target" — so there is *one* canonical `Int: Carrier` conformance. Will document explicitly.
- **@reviewer-c1**: Three DocC articles added to the roadmap.
- **@reviewer-c6**: SemVer policy with "default implementations for new requirements" added as an action for before any broader announcement.
- **@reviewer-c5b**: Fair pressure. There's a witness-style consumer in one of the standards-layer experiments that motivated this; will surface the diff concretely in the Research note.
- **@reviewer-short**: Yes, zero-dep is scoped to the core product. Will parentheticalize.

Pre-announcement gate is the small items (Research sketches, one test, naming grep); DocC polish follows on the 0.1.x track. Terminal-posture / SemVer framing is handled internally per user directive and is not published in the README.

---

## Changelog

- **2026-04-24 v1.0** — Initial render on partial proposal-reviews corpus (371 threads).
- **2026-04-24 v1.1** — Full-corpus refresh (602 threads). Per-post HTML-comment archetype labels and `@reviewer-cN` handles updated to canonical archetype labels (c1/c2/c3/c4/c5/c6/c8 from the labeled-clusters set). OP follow-up cross-references rewritten to match. Fix for the partial-refresh anti-pattern that previously left body metadata on old k=12 raw cluster IDs while only the front-matter had been updated. See `forums-review-objections-2026-04-24.md` changelog for the corresponding ranking-table corrections and launch-readiness revision.
