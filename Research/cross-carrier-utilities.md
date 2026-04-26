# Cross-Carrier Utilities — Prior Art Survey and Ship-List Recommendation

<!--
---
version: 1.0.0
last_updated: 2026-04-26
status: RECOMMENDATION
tier: 2
scope: package-specific
---
-->

## Context

`swift-carrier-primitives` shipped `Carrier<Underlying>` in 2026-04-24 and
the carrier-ecosystem migration (Phases 1–3 + 5) closed in 2026-04-26.
Six packages — `swift-tagged-primitives`, `swift-cardinal-primitives`,
`swift-ordinal-primitives`, `swift-affine-primitives`,
`swift-clock-primitives`, `swift-property-primitives` — now ship Carrier
conformances. The cascading `extension Tagged: Carrier where RawValue:
Carrier` means ~80 ecosystem typealias sites are first-class Carriers
without per-site work.

The `Carrier` protocol surface itself is small (`Sources/Carrier
Primitives/Carrier.swift`):

```swift
public protocol Carrier<Underlying>: ~Copyable, ~Escapable {
    associatedtype Domain: ~Copyable & ~Escapable = Never
    associatedtype Underlying: ~Copyable & ~Escapable
    var underlying: Underlying {
        @_lifetime(borrow self)
        borrowing get
    }
    @_lifetime(copy underlying)
    init(_ underlying: consuming Underlying)
}
```

Four files alongside provide trivial-self-Carrier defaults across the
four `Copyable × Escapable` quadrants — they are NOT cross-Carrier
utilities; they are per-quadrant defaults for `Underlying == Self`
conformers.

The standing **structural** decision (this session, no commit; locked
in by the HANDOFF):

- Cross-Carrier utilities go INSIDE the existing `Carrier Primitives`
  target — NOT a new variant target.
- Convention: methods on the `Carrier` protocol via constraint-slice
  extensions, not free functions.
- File-naming: extends the existing `Carrier where {clause}.swift`
  pattern, parameterized by the *Underlying* constraint that gates the
  utility (e.g., `Carrier where Underlying: Equatable.swift`).

The structural decision is locked. This document resolves the
**content** decision: which utilities (if any) ship.

**Trigger**: [RES-001] Investigation. The location decision was made
without a corresponding content decision because the four-quadrant
shape, the second-consumer rule, and the round-trip asymmetry for
`~Copyable` Underlyings each constrain the candidate space in
non-obvious ways that warrant systematic analysis before any utility
ships.

**Tier**: 2 (Standard). Cross-Carrier utility *shape* sets long-lived
semantic contracts — every future Carrier conformer's API surface
inherits whatever ships here. Per HANDOFF, applies prior-art-survey
and theoretical-grounding rigor per [RES-021] and [RES-022]. Not
Tier 3 because the recommendation does not establish a NEW normative
contract; it characterizes options against an established structural
decision.

**Scope**: package-specific. The output lives in
`swift-carrier-primitives/Research/` per [RES-002a]. The analysis is
specific to `Carrier`'s protocol design and does not generalize to
ecosystem-wide patterns (capability-lift, sibling protocols, witness
protocols are addressed in their own ecosystem-wide research).

**Stakeholders**: ecosystem maintainers; future Carrier consumers
(diagnostics, serialization, witness scaffolding) per anticipated
demand documented in `generic-consumer-across-quadrants.md`.

## Prior research (cited, not relitigated)

This document **extends** the following — every recommendation here
must be consistent with these:

| Source | Locks in |
|--------|----------|
| `capability-lift-pattern.md` v1.3.0 RECOMMENDATION (this package, 2026-04-26) | Recs #4 (don't extend Carrier to ~Copyable Underlying naively — round-trip breaks); #5 (Carrier addition driven by Form-D demand, not factored-for-its-own-sake); #6 (witness protocols stay distinct from Carrier as siblings); #7 (operator-ergonomics protocols stay distinct as siblings); #8 (domain-specific value types stay distinct) |
| `carrier-vs-rawrepresentable-comparative-analysis.md` DECISION (this package, 2026-04-24) | Carrier and RawRepresentable are non-substitutable. Dimension 5: "Carrier conformance gives ZERO stdlib-level benefit." Dimension 8: cross-type morphisms are Carrier's design payoff but RawRepresentable categorically cannot host them. |
| `generic-consumer-across-quadrants.md` REFERENCE (this package, 2026-04-24) | The canonical witness-style consumer signature `project<C: Carrier & ~Copyable & ~Escapable, R: ~Copyable>(_ carrier: borrowing C, through sink: (borrowing C.Underlying) -> R) -> R` is the operational proof of the four-quadrant claim. First real consumers anticipated in serialization, diagnostics, hash-projection. |
| `round-trip-semantics-noncopyable-underlyings.md` DECISION (this package, 2026-04-24) | For `~Copyable` Underlying, the round-trip property is broken — `borrow → consume → reconstruct` is the canonical pattern; `let x = c.underlying; Carrier(x)` cannot compile. Critical constraint on `reroot`-shaped utilities. |
| `mutability-design-space.md` v1.1.0 DECISION (this package, 2026-04-25) | Direct precedent: `Carrier.Mutable` deferred indefinitely; an entire `swift-mutator-primitives` package investigation completed DEFERRED on [RES-018] grounds despite a genuine academic gap (handlers for linear/borrowed state). The pattern of "well-shaped abstraction, no second consumer, defer" applies symmetrically here. |
| `swift-institute/Research/carrier-ecosystem-application-inventory.md` v1.2.0 RECOMMENDATION (2026-04-26) | "**The Carrier capability is unused so far** in production cross-Carrier algorithms" — Form-D demand is unrealized as of 2026-04-26. Recommendation #5 (capability-lift-pattern.md) was prescient: migration was factored ahead of demand. Suggestion #7 of the carrier-integration retrospective explicitly flags this as the unresolved validation question. |
| `swift-institute/Research/operator-ergonomics-and-carrier-migration.md` RECOMMENDATION (2026-04-26) | Demonstrates the "sibling-not-Carrier" pattern for operator-ergonomics protocols (Ordinal.\`Protocol\`); the same diagnostic logic — "what specific shape does this need that Carrier cannot replicate?" — applies to evaluating utility candidates. |
| `swift-institute/Research/decimal-carrier-integration.md` RECOMMENDATION (2026-04-26) | Phase 4 (Decimal Tagged refactor) CANCELLED on four-way convergence: naming obstacle, literal-conformance gating, [IMPL-001] domain-erasure, [RES-018] second-consumer hurdle. Direct precedent for "the inventory's CAN-yes verdict was ungrounded; defer." |
| `swift-institute/Research/phantom-typed-value-wrappers-literature-study.md` v1.0.0 RECOMMENDATION (2026-02-26, Tier 3) | Tier-3 SLR + 5-language comparative analysis (36 papers, Reynolds–Wadler–Breitner et al.). The academic literature foundation for this document; cited rather than re-surveyed per [RES-019]. The literature study covers wrappers; this document covers what UTILITIES ship across them. |
| `sli-*.md` (24 DECISIONs, this package, 2026-04-24) | Recurring rationale across stdlib-integration decisions: trivial-form is zero-payoff; parametric-form pre-commits semantics consumers should own; multi-axis generics don't fit Carrier; "no demonstrated use case" → SKIP. The hurdle rate for adding ANY Carrier-touching API surface is high and well-precedented. |

User-stated constraints (this session, locked in by HANDOFF):

- Utilities live INSIDE `Carrier Primitives`, not in a new variant target.
- Methods on the `Carrier` protocol via constraint extensions, not free
  functions.
- File-naming inherits `Carrier where {clause}.swift`.
- Defer shipping any speculative utility until research lands.

## Question

Given the locked structural decision, four sub-questions:

1. **Which cross-Carrier utilities have prior-art justification** (vs.
   ecosystem-novel speculation)? Survey what ships across phantom-typed
   wrappers in Haskell, Rust, Scala, OCaml, F#, Idris/Agda, and the
   academic literature.

2. **For each utility with prior-art support, what is the minimum
   constraint surface** that makes it total / sound across the four
   `Copyable × Escapable` quadrants? Which require new operations on
   the `Carrier` protocol itself (e.g., consume-extraction blocks
   `reroot` from being expressible without an additional protocol
   requirement)?

3. **Which utilities pass the [RES-018] second-consumer hurdle** as of
   2026-04-26? The Mutator-package precedent and the Decimal-Phase-4
   cancellation set a high bar for "ship without consumer evidence."

4. **What's the right scope for v1**: ship a small set of prior-art-
   supported utilities, or codify the location decision and ship none
   until a real consumer surfaces?

## Analysis

### Methodology

Per [RES-004]: enumerate the candidate utilities, identify the
classification axes, analyse each candidate against the constraints,
recommend.

Per [RES-019]: Step-0 internal grep run — `swift-institute/Research/`
and `swift-carrier-primitives/Research/` searched for `cross-carrier`,
`newtype`, `coerce`, `wrapper`, `RawRepresentable`, `phantom`,
`tagged`, `optic`, `lens`, `reroot`, `equate`. Surfaced ~30 internal
docs; the load-bearing ten are listed in the *Prior research* table
above. The Tier-3 phantom-typed-value-wrappers-literature-study covers
the wrappers themselves (parametricity, GADTs, Coercible, the four
ecosystem-variants); this document focuses specifically on what
*operations* ship across phantom-typed wrappers — a complementary
question the literature study touches but does not cover end-to-end.

Per [RES-021] (Tier 2+): prior-art survey of Haskell `tagged` /
`lens` / `Coercible`; Rust `derive_more` / `newtype_derive` and the
PhantomData pattern; Scala 3 opaque types; F# units of measure;
OCaml private types; Idris/Agda dependently-typed phantom encoding;
academic citations from the Tier-3 literature study. The
contextualization step (per [RES-021]'s rule about universal-adoption
not implying universal-necessity) is applied per candidate.

Per [RES-022] (Tier 2+): theoretical grounding — parametricity
(Reynolds 1983), free theorems (Wadler 1989), Coercible/roles
(Breitner et al. 2014), affine/linear types (Wadler 1990, Tov-Pucella
2011) — cited from the literature study.

Per [RES-018]: candidate utilities are evaluated against the
second-consumer hurdle. This document **does** propose new APIs (utility
methods on Carrier) rather than a new primitive type, but the same
hurdle rate applies because every method ships an API contract that
all future Carrier conformers carry. The Mutator and Decimal precedents
are direct.

### The Carrier protocol surface (recap)

Carrier exposes exactly two abstract members:

```swift
var underlying: Underlying { @_lifetime(borrow self) borrowing get }
init(_ underlying: consuming Underlying)
```

Plus two associated types (`Domain`, `Underlying`). That is all.

Three structural facts dominate the candidate analysis:

1. **`underlying` is borrow-only.** No protocol-level consume-extraction
   path. Operations that need to take ownership of the carried value
   must either (a) consume the entire Carrier (`consume self` at the
   call site, exposing the value as a borrow first then dropping
   `self`), (b) require `Underlying: Copyable` (so the borrow can be
   copied), or (c) require a *new* Carrier protocol method like
   `consuming func unwrap() -> Underlying`.

2. **`init(_:)` is consuming.** Construction takes ownership of an
   owned `Underlying`. For ~Copyable Underlying, the caller must own a
   *separate* Underlying value — they cannot route `c.underlying`
   (a borrow) into `Carrier(...)` (a consume). This is documented in
   `round-trip-semantics-noncopyable-underlyings.md`.

3. **Stdlib-protocol constraints are Q1-only.** `Equatable`, `Hashable`,
   `Comparable`, `CustomStringConvertible`, `Codable`, `Sendable`
   (with caveats) all require `Self: Copyable & Escapable` because
   they were defined pre-ownership. Any conditional conformance from
   `Carrier` to a stdlib protocol must restrict to Q1 — the
   four-quadrant matrix is non-uniform under stdlib-protocol lifting.
   This is the same constraint that drives `dynamic-member-lookup-
   decision.md` to its asymmetric-ergonomic skip rule.

### Cross-language prior-art survey

#### Haskell — `Data.Tagged` (the `tagged` package)

Authoritative source: `Data.Tagged` (verified against
hackage.haskell.org/package/tagged-0.8.10/docs/Data-Tagged.html,
2026-04-26).

Tagged-specific functions shipped:

| Function | Type | Cross-Carrier analog |
|----------|------|---------------------|
| `Tagged { unTagged :: b }` | constructor + accessor | `init(_:)` + `var underlying` (already shipped) |
| `retag :: Tagged s b -> Tagged t b` | change phantom tag | candidate `reroot` |
| `untag :: Tagged s b -> b` | extract value | `c.underlying` (Q1 case) |
| `tagSelf :: a -> Tagged a a` | tag with own type | trivial-self-Carrier (already shipped) |
| `untagSelf :: Tagged a a -> a` | restricted extraction | trivial-self-Carrier `.underlying` |
| `asTaggedTypeOf :: s -> tagged s b -> s` | type-alignment witness | type witness pattern |
| `witness :: Tagged a b -> a -> b` | combine tag + value | not applicable to Carrier (Carrier has no Proxy story) |
| `proxy`, `unproxy`, `tagWith`, `reproxy` | Proxy interop | not applicable (Swift has no Proxy idiom) |

Typeclass instances (= "automatic protocol forwarding"):

- `Functor`, `Applicative`, `Monad` on the value position
- `Bifunctor`, `Bitraversable` — both tag and value mappable
- `Foldable`, `Traversable` — over wrapped value
- `Eq`, `Ord`, `Show`, `Read` — delegate to wrapped value
- `Num`, `Fractional`, `Floating`, `Bounded`, `Enum`, `Integral`,
  `Real`, `RealFrac`, `RealFloat` — full numeric forwarding
- `Monoid`, `Semigroup` — combined via wrapped
- `Generic`, `Data` — reflective programming
- `Storable`, `Bits`, `FiniteBits` — low-level

The Haskell `tagged` library treats `retag` as a first-class
operation. It is shipped because Coercible/representational roles
(Breitner et al. 2014) make it provably zero-cost: `Tagged s b` and
`Tagged t b` have the same representation; `retag = coerce`. The
typeclass instances are *automatic* via `deriving newtype`
machinery — same Coercible mechanism.

**Contextualization step (per [RES-021])**: in Swift, no Coercible /
roles system exists. `phantom-typed-value-wrappers-literature-study.md`
§S2 ("The Coercibility Gap") records this as the single largest
language-level absence. A Swift `reroot` would be a typed function
call, not a zero-cost coercion. Operator forwarding (the `Functor` /
`Num` instances) requires manual implementation — exactly the problem
the protocol-abstraction-for-phantom-typed-wrappers research was
chartered to address for *operators on Tagged*, not for cross-Carrier
generic dispatch.

#### Haskell — `Control.Lens.Wrapped` (Edward Kmett's `lens`)

Verified against
hackage.haskell.org/package/lens-4.17/docs/Control-Lens-Wrapped.html,
2026-04-26.

```haskell
class Wrapped s where
    type Unwrapped s
    _Wrapped' :: Iso' s (Unwrapped s)
```

`_Wrapped` provides a canonical isomorphism between a newtype and its
unwrapped form. Composes with the rest of the lens algebra:

- `over _Wrapped :: (Unwrapped s -> Unwrapped s) -> s -> s` — same-Self
  map (transform underlying, rebuild)
- `view _Wrapped :: s -> Unwrapped s` — extract underlying
- `_Unwrapped :: Iso' (Unwrapped s) s` — the inverse

Generic support via `_GWrapped'` and `makeWrapped`.

**Contextualization step**: lens is built on the Iso/Prism/Lens
algebra, which the swift-primitives ecosystem partially has via
`swift-optic-primitives` (Lens/Prism/Iso/Affine/Traversal — per
mutability-design-space.md §"Investigation outcome"). The lens
`_Wrapped` is structurally `Optic.Iso<Self, Underlying>`. A
Carrier-aware `Wrapped` adapter would be a *third-party utility* in
the Optic ecosystem, not a Carrier-internal API. The right home is
`swift-optic-primitives`, not `swift-carrier-primitives`. Recorded as
a future-work direction; out of scope for this document.

#### Rust — newtype + `derive_more` / `newtype_derive`

Verified against docs.rs/derive_more, 2026-04-26.

The Rust newtype idiom is `struct Newtype(Inner);` with explicit trait
implementations. `derive_more` generates the boilerplate for:

- **Conversion**: `From`, `Into`, `AsRef`, `AsMut`, `FromStr`,
  `TryFrom`, `TryInto`, `IntoIterator`
- **Formatting**: `Display`, `Debug`
- **Operators**: `Add` (+ `Sub`, `BitAnd`, `BitOr`, `BitXor`),
  `Mul` (+ `Div`, `Rem`, `Shr`, `Shl`), `Deref`/`DerefMut`,
  `Not`/`Neg`, `Index`/`IndexMut`
- **Utility**: `Constructor` (`new()`), `IsVariant`, `Unwrap`/`TryUnwrap`

Crucially, **none of these are cross-newtype operations**. They are
*forwarding* derives — they implement traits on `Newtype` by
delegating to the trait impl on `Inner`. A function generic over
`<T: Add>` already accepts both `Newtype` and `Inner` because both
implement `Add` — but you cannot generically convert one newtype to
another with the same `Inner` without an explicit `From` impl per
pair. The Rust ecosystem does not idiomatically ship cross-newtype
morphisms.

The PhantomData approach (`struct Tagged<Tag, Value> { value: Value,
_tag: PhantomData<Tag> }`) is the closest analog to Carrier; the
literature study §"Rust" covers this. Variance is explicit
(covariant via `PhantomData<T>`, contravariant via `PhantomData<fn(T)>`,
invariant via `PhantomData<*mut T>`); cross-tag operations are NOT
part of the standard pattern. The community position (Rust API
Guidelines C-DEREF) is "only smart pointers should implement Deref"
— even forwarding via Deref is discouraged.

**Contextualization step**: Rust's "no cross-newtype morphisms" stance
*matches* the [RES-018]-grounded skepticism. Newtypes in Rust are
treated as nominal walls; operations are per-type. The Swift
ecosystem's instinct toward cross-Carrier generic algorithms
(Form-D) is *not* mirrored in Rust's newtype practice — Rust would
expect each conversion to be explicit.

#### Scala 3 — opaque types

Verified against docs.scala-lang.org/scala3/reference/other-new-features/opaques.html,
2026-04-26.

Opaque types in Scala 3 require **explicit extension methods** for
all operations on the underlying type:

> "Extension methods define opaque types' public APIs. ... There is
> no automatic forwarding."

The example from the documentation: `Logarithm` opaque type backed
by `Double` requires explicit `+`, `*`, `toDouble` extensions. `l / l2`
fails: "`/` is not a member of Logarithm".

For cross-opaque-type operations: the documentation **does not
demonstrate** equality comparison or conversion between distinct
opaque types with identical implementations. Bounds (`<:`) can
establish subtype relationships. Otherwise, developers implement
case-by-case.

**Contextualization step**: Scala 3 opaque types are the closest
ecosystem analog to a "deliberately wall the type off" stance.
Cross-opaque morphisms are explicitly NOT a standard pattern. The
Swift ecosystem's Carrier design — which anticipates Form-D
cross-Carrier generic algorithms — is *more ambitious* than Scala 3's
opaque-types convention. The "more ambitious" direction needs
correspondingly stronger evidence (per [RES-018] second-consumer
hurdle) to ship utilities that operationalize the ambition.

#### F# — units of measure

Verified against learn.microsoft.com/dotnet/fsharp/language-reference/units-of-measure,
2026-04-26.

F# units of measure are compile-time-only (erased at runtime). The
operations available are:

- **Add unit**: multiply by `1.0<unit>`
- **Strip unit**: divide by `1.0<unit>` or multiply by `1.0<1/unit>`
- **Convert between units**: explicit conversion factor
  (`tenMeters * 3.281<foot/meter>`)

Cross-unit operations (e.g., `meter + foot`) are compile errors. The
unit system is designed to *prevent* dimension mixing. There is no
"describe units" operation, no "rebrand to a different unit while
preserving magnitude" operation. Units are intentionally distinct.

**Contextualization step**: F# units of measure are the cleanest
example of a phantom-typed system that ships *zero* cross-phantom
utilities. The design is "discriminate, don't mix." Translating to
Carrier: this *strengthens* the case that cross-Carrier utilities
are not universal-prior-art; they are an artifact of Haskell's
Coercible-driven design.

#### OCaml — private types and module-level abstraction

The Tier-3 literature study §"OCaml" covers the mechanism. Cross-
abstract-type operations are NOT part of the standard pattern; the
module signature controls access on a per-functor basis. Each
functor instantiation produces a fresh abstract type with no generic
relationship to other instantiations.

#### Idris/Agda — dependently-typed phantom encoding

The literature study §"Foundational Theory" covers Cheney-Hinze 2003
"First-Class Phantom Types" (type equality witnesses) and
McBride 2002 "Faking it: Simulating dependent types in Haskell"
(verified via dblp.org/rec/journals/jfp/McBride02.html, 2026-04-26).
The technique uses type equality witnesses (`TypeEq a b`) and
phantom indexing to simulate dependent types. The relevant operations
are *equality witnesses*, not utilities on the wrappers themselves.

**Contextualization step**: dependent-type encodings give you *more*
power than phantom types but at the cost of inference (Peyton Jones
et al. 2004, 2006 "Wobbly Types"). The literature study §S4
classifies Carrier as occupying the "phantom type" position on the
type-discrimination spectrum — the sweet spot of maximum
discrimination with full inference and zero runtime cost. Stretching
toward dependent-type-style cross-wrapper proofs would push Carrier
out of its sweet spot.

#### Academic — what utilities does parametricity actually permit?

Wadler's free theorems for `Tagged<Tag, V>` (literature study §S1):
any function `f : ∀ Tag. Tagged<Tag, V> → Tagged<Tag, V>` polymorphic
in `Tag` must preserve the tag. This is the *formal* guarantee that
phantom tags are tamper-proof — and it directly bounds the candidate
utility set:

| Operation | Permitted by parametricity? | Reason |
|-----------|------------------------------|--------|
| `f<C: Carrier>(_ c: C) -> C.Underlying` (extract) | YES | the result is the underlying value; tag is forgotten |
| `f<C: Carrier>(_ c: C) -> String` (describe) | YES (with reflection) | the result type doesn't depend on `C.Domain` |
| `f<C: Carrier>(_ c: C) -> C` (preserving) | YES | tag is preserved structurally |
| `f<C1, C2: Carrier>(_ a: C1, _ b: C2) -> Bool where C1.Underlying == C2.Underlying` | YES | result type doesn't depend on either Domain |
| `f<C1, C2: Carrier>(_ c: C1) -> C2 where C1.Underlying == C2.Underlying` (`reroot`) | YES (parametricity), NO (Swift's protocol) | parametrically sound: but Swift's Carrier needs a way to construct C2; the `init(_:)` exists but consumes ownership of the underlying, and the borrow returned by `c.underlying` cannot be consumed without a copy |
| `f<C1, C2: Carrier>(_ c: C1, _ f: (Underlying) -> Other.Underlying) -> C2` (`map`) | YES (parametricity), NO (Swift's protocol) | Carrier protocol provides no way to express "build a C2" generically — `init(_:)` is per-Self, not per-protocol |

This is the formal foundation: parametricity permits a richer set of
operations than Swift's `Carrier` protocol can express today. The
gap is *language-level* (no Coercible, no per-protocol per-Self
constructor) — not a research gap.

### Summary of cross-language ship-list

| Ecosystem | Ships `retag` / cross-tag morphism? | Ships auto-trait-forwarding? | Mechanism |
|-----------|------------------------------------|------------------------------|-----------|
| Haskell `tagged` | YES (`retag`) | YES (`deriving newtype`) | Coercible + roles (Breitner 2014) |
| Haskell `lens` | YES (via `_Wrapped` Iso) | partial (lens algebra) | Iso composition |
| Rust `derive_more` | NO | YES (forward Inner → Newtype) | Procedural macros |
| Scala 3 opaque types | NO | NO (must extension-method) | Compile-time discrimination |
| F# units of measure | NO (intentionally) | partial (numeric ops) | Dimension algebra |
| OCaml private/abstract | NO | NO | Module abstraction |
| Idris/Agda | YES (via type-equality witness) | YES (via dependency) | Dependent types |

**Universal observation**: the only ecosystems that ship `retag`-style
cross-tag morphisms are those with *language-level support* for
zero-cost coercion (Haskell Coercible) or dependent-type witnesses
(Idris/Agda). Ecosystems that lack such language support (Rust,
Scala, F#, OCaml) do NOT ship cross-tag morphisms — they require
explicit per-pair conversions instead.

Swift is in the "lacks language-level support" group. Per the
contextualization step (per [RES-021]), this is signal that adding
cross-Carrier utilities at the language-untyped layer is going
*against* the cross-language consensus. The Form-D enablement that
`capability-lift-pattern.md` §"What's missing" anticipates is real
but is the more-ambitious direction — the burden of proof for shipping
APIs that operationalize it sits with the demand-evidence side.

### Candidate utility enumeration

Distilled from prior research and the cross-language survey:

1. **`describe`** — `func describe<C: Carrier>(_ c: C) -> String`.
   Print the Underlying type and Domain. Cited in
   `capability-lift-pattern.md` line 219 as the diagnostic anchor.
   Universal across ecosystems (Haskell `Show`, Rust `Display`, Scala
   `toString`).

2. **`reroot`** — `func reroot<C1: Carrier, C2: Carrier>(_ c: C1) -> C2
   where C1.Underlying == C2.Underlying`. Change phantom Domain
   preserving Underlying value. Cited in `capability-lift-pattern.md`
   line 218; Haskell `retag :: Tagged s b -> Tagged t b`; lens
   `_Wrapped` Iso.

3. **`equate`** — `func equate<C1: Carrier, C2: Carrier>(_ a: C1, _ b: C2)
   -> Bool where C1.Underlying == C2.Underlying, C1.Underlying:
   Equatable`. Cross-Domain underlying-value equality. Implicit in
   Haskell `Eq` instance on `Tagged`; not standard in Rust/Scala.

4. **`project`** (witness sink) — `func project<C: Carrier & ~Copyable
   & ~Escapable, R: ~Copyable>(_ carrier: borrowing C, through sink:
   (borrowing C.Underlying) -> R) -> R`. Pass underlying through a
   caller-supplied sink. Already documented as a sketch in
   `generic-consumer-across-quadrants.md`. The lens-style `over` in
   spirit.

5. **`untag`** — degenerate. Already shipped as `c.underlying`
   returning a borrow; for Q1 callers, `let x = c.underlying` produces
   an owned copy. No new API needed.

6. **`map`** — functor lift. Same-Self map (`Self(transform(c.underlying))`)
   works trivially because `init(_:)` exists per-conformer. Cross-
   Carrier map (build a different Carrier of a different Underlying)
   is NOT EXPRESSIBLE in the current Carrier protocol — there is no
   per-protocol way to construct an arbitrary `Other: Carrier`.
   Excluded from further analysis.

7. **Conditional `Equatable`/`Hashable`/`CustomStringConvertible`
   conformance** — `extension Carrier: Equatable where Underlying:
   Equatable, Self: Copyable & Escapable`, etc. Q1-only, conditional.
   Haskell `deriving newtype Eq` is the analog.

### Classification matrix

Per HANDOFF Step 3 axes:

| # | Utility | Prior art ≥2 ecosystems | Carrier-protocol-feasible | Quadrants | Underlying constraint |
|---|---------|------------------------|---------------------------|-----------|----------------------|
| 1 | `describe` | YES (universal) | YES (uses `String(reflecting:)` / `String(describing:)`) | All four (type reflection only) | None for type names; `CustomStringConvertible` if rendering value |
| 2 | `reroot` | YES (Haskell `retag`, lens `_Wrapped`) | NO without protocol extension; Q1-only via copy | Q1 only (requires `Underlying: Copyable`) | None |
| 3 | `equate` | YES (Haskell `Eq` on Tagged) | YES via `==` on `.underlying` (Q1) | Q1 only (Equatable requires Copyable & Escapable on Self) | Equatable |
| 4 | `project` | YES (lens-style witness) | YES — already validated all four quadrants | All four | None |
| 7a | `Carrier: CustomStringConvertible` | YES (Haskell `Show`) | Q1-only conditional | Q1 only | CustomStringConvertible |
| 7b | `Carrier: Equatable` | YES (Haskell `Eq`) | Q1-only conditional | Q1 only | Equatable |
| 7c | `Carrier: Hashable` | YES (Haskell `Hashable`) | Q1-only conditional | Q1 only | Hashable |

### Per-utility analysis

#### Utility 1: `describe`

Shape:

```swift
extension Carrier {
    public static var describedType: String {
        "Carrier of \(String(reflecting: Underlying.self)) " +
        "with Domain \(String(reflecting: Domain.self))"
    }
}
```

Or as an instance method that includes the value:

```swift
extension Carrier where Underlying: CustomStringConvertible {
    public var described: String {
        "\(String(reflecting: Self.self))(\(underlying))"
    }
}
```

**Prior art**: universal — every typed phantom-wrapper ecosystem ships
some form of `Show`/`Display`/`toString`/`Debug`. Haskell `Show` for
`Tagged` (delegates to wrapped); Rust `Display` via `derive_more`;
Scala explicit extension; F# `printfn "%A"` automatic.

**Carrier feasibility**: works in all four quadrants when the value
isn't rendered (just type reflection). When rendering the value, the
constraint `where Underlying: CustomStringConvertible, Self: Copyable
& Escapable` makes this Q1-only.

**Second-consumer check ([RES-018])**:
- Originating consumer: anticipated for diagnostics (panics, log
  messages, error-path output).
- Second consumer: NONE in the ecosystem as of 2026-04-26. No package
  imports `Carrier_Primitives` to format Carriers in error messages.
- Carrier-integration retrospective Suggestion #7 explicitly notes
  Form-D demand is unrealized.

**Verdict**: structurally feasible, prior-art-supported, but no
second consumer. Same shape as the Mutator package's deferral —
"well-shaped, no consumer, defer."

#### Utility 2: `reroot`

Shape (Q1-only):

```swift
extension Carrier where Underlying: Copyable {
    public func reroot<Other: Carrier>(_: Other.Type) -> Other
    where Other.Underlying == Underlying, Other.Underlying: Copyable {
        Other(underlying)
    }
}
```

Or as a free function (rejected by HANDOFF; included for completeness):

```swift
public func reroot<C1: Carrier, C2: Carrier>(_ c: C1) -> C2
where C1.Underlying == C2.Underlying, C1.Underlying: Copyable {
    C2(c.underlying)
}
```

**Prior art**: Haskell `retag :: Tagged s b -> Tagged t b` is one of
the canonical operations the `tagged` package ships. lens
`_Wrapped` provides the same via Iso composition.

**Carrier feasibility**: BLOCKED in the four-quadrant matrix.
- Q1 (`Underlying: Copyable`): works via copy.
- Q2 (`Underlying: ~Copyable`): borrow cannot be consumed; a new
  Carrier protocol method like `consuming func unwrap() -> Underlying`
  would be required. Adding it widens the protocol surface and
  breaks the symmetry of the trivial-self-Carrier defaults.
- Q3 (`Underlying: ~Escapable`): borrow has lifetime tied to source;
  consuming into a new Carrier requires lifetime annotation
  cooperation that the protocol hasn't been designed for.
- Q4 (`~Copyable & ~Escapable`): both blockers compound.

The HANDOFF identified this exact blocker: *"`reroot` is structurally
blocked by Carrier's `borrowing get` on `underlying` (no consume-
extraction)."* This document confirms.

**Second-consumer check**:
- Originating consumer: anticipated for cross-domain serialization
  (e.g., "treat this `User.ID` as an `Order.ID` during a
  schema migration"), debugging tools, runtime introspection.
- Second consumer: NONE.

**Universal-adoption contextualization**: Haskell ships `retag` because
Coercible makes it provably zero-cost AND because `Tagged s b` is
the only Tagged-like wrapper in standard use, so the cross-tag
shape is canonical. In Swift, no Coercible exists; `reroot` would
be a typed function call (one extension method dispatch). The cost
is small but non-zero. AND: per `dynamic-member-lookup-decision.md`
the asymmetric-quadrant trigger is the canonical "don't apply"
signal — Q1-only utilities surface as "works in some places, breaks
in others" surprises.

**Verdict**: prior-art-supported, but BLOCKED for Q2/Q3/Q4 absent a
new Carrier protocol method. The cross-language survey shows that
Rust/Scala/F#/OCaml *deliberately* don't ship `reroot`-style
morphisms. Defer per [RES-018]; revisit only when (a) a real consumer
surfaces with a Q1-acceptable use case, or (b) the ecosystem decides
to widen Carrier's protocol surface with consume-extraction (separate
investigation, not within this document's scope).

#### Utility 3: `equate`

Shape:

```swift
extension Carrier where Underlying: Equatable, Self: Copyable & Escapable {
    public static func equateUnderlying<Other: Carrier>(_ lhs: Self, _ rhs: Other) -> Bool
    where Other.Underlying == Underlying, Other: Copyable & Escapable {
        lhs.underlying == rhs.underlying
    }
}
```

Or as a free function:

```swift
public func equateUnderlying<C1: Carrier, C2: Carrier>(_ a: C1, _ b: C2) -> Bool
where C1.Underlying == C2.Underlying,
      C1.Underlying: Equatable,
      C1: Copyable & Escapable,
      C2: Copyable & Escapable {
    a.underlying == b.underlying
}
```

**Prior art**: Haskell's `Eq` instance on `Tagged s b` provides
in-tag equality; cross-tag equality requires explicit `==` on the
unwrapped values. Rust requires explicit per-pair `PartialEq` impls.
F# units of measure intentionally reject cross-unit equality at
compile time.

**Carrier feasibility**: Q1-only. The `Self: Copyable & Escapable`
constraint is forced by Equatable's stdlib definition.

**Second-consumer check**:
- Originating consumer: anticipated for migration tools, debugging,
  cross-domain coalescing.
- Second consumer: NONE.

**Concern beyond [RES-018]**: cross-domain equality is *semantically
suspect*. The whole point of phantom-typed wrappers is that `User.ID`
and `Order.ID` are intentionally distinct even when they wrap the same
`UInt64`. A function that says "are these underlying values equal"
elides the type-system distinction the wrapper exists to enforce.
Legitimate use cases exist (migration, debugging) but they are
specialized — not part of the day-to-day Carrier API surface.

**Verdict**: prior-art-supported but with a semantic-suspicion overlay
that further raises the second-consumer hurdle. Defer.

#### Utility 4: `project`

Shape (already in `generic-consumer-across-quadrants.md`):

```swift
public func project<C: Carrier & ~Copyable & ~Escapable, R: ~Copyable>(
    _ carrier: borrowing C,
    through sink: (borrowing C.Underlying) -> R
) -> R {
    sink(carrier.underlying)
}
```

**Prior art**: lens-style — `view`, `over`, `withWrapped`. Not as
canonical in Haskell as `retag` because the underlying is directly
accessible via `unTagged`; lens treats it as one operation in a
larger algebra.

**Carrier feasibility**: VALIDATED in all four quadrants by
`generic-consumer-across-quadrants.md`. The signature is the
operational proof of the four-quadrant claim.

**Second-consumer check**:
- Originating consumer: the document itself (single sketch).
- Anticipated consumers: serialization (`swift-serialization-primitives`
  variant), diagnostics emission, hash-projection witnesses. None
  shipped.
- Current production consumer: NONE.

**Special status**: this utility is documented as a SKETCH (Tier 1
REFERENCE), not as a shipped API. The document says: *"When those
land, this sketch becomes the spec they satisfy; until then, it
stands as the operational proof that the abstraction pays rent."*

**Verdict**: the existing sketch is the right level of commitment
today. Promote to a shipped utility (`Carrier where Underlying: Any.swift`?
or just bare-Carrier-extension-with-no-where-clause?) when the FIRST
real consumer surfaces. Do not ship pre-emptively.

Note on file naming: `project` does not have an `Underlying`
constraint, so a `Carrier where {clause}.swift` filename would be
degenerate — it would be `Carrier.swift` or similar. The existing
`Carrier.swift` is the protocol declaration; a shipping `project`
would need a different filename convention (e.g., `Carrier+Project.swift`
or a suite-of-utilities file). This naming question is deferred until
shipment is justified.

#### Utility 7a/b/c: Conditional stdlib protocol conformances

Shape (Equatable example):

```swift
extension Carrier: Equatable
where Underlying: Equatable, Self: Copyable & Escapable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.underlying == rhs.underlying
    }
}
```

**Prior art**: Haskell `deriving newtype Eq`, `deriving newtype Show`,
`deriving newtype Hashable` all ship in stdlib via the Coercible
mechanism. Rust forwards via `derive_more`.

**Carrier feasibility**: Q1-only. The constraint `Self: Copyable &
Escapable` propagates from stdlib's Equatable/Hashable/CustomString-
Convertible requirements (each requires Copyable & Escapable on Self).

**Concerns specific to this category**:

1. **Asymmetric ergonomic trigger** (per `dynamic-member-lookup-
   decision.md`): a Carrier that's Q1 gets `==` for free; a Q2/Q3/Q4
   Carrier doesn't. Consumers writing `func f<C: Carrier>(_ a: C, _ b: C)`
   that uses `a == b` get a constraint error visible only at the use
   site. The `dynamic-member-lookup-decision.md` SKIP rule is
   triggered by exactly this asymmetry.

2. **Conformance shadowing**: ecosystem types that already conform to
   Equatable directly (Cardinal, Ordinal, etc.) have their own
   `==` implementations. Adding `Carrier: Equatable where Underlying:
   Equatable` creates a *more general* path that might or might not
   be selected by overload resolution. Prior research did not
   investigate this; the experiment exists at
   `Experiments/dynamic-member-lookup-quadrants/` but covers KeyPath
   mechanics, not protocol-conformance ambiguity.

3. **Carrier's design intent** per `carrier-vs-rawrepresentable-
   comparative-analysis.md` Dimension 5: *"Carrier conformance gives
   ZERO stdlib-level benefit. The abstraction is ecosystem-internal."*
   Adding stdlib-protocol lifting via Carrier reverses this design
   stance. Doing so warrants explicit justification — not a quiet
   convenience extension.

4. **Conformance proliferation**: a single `Carrier: Equatable`
   extension cascades through every type that conforms to Carrier —
   bare Cardinal, bare Ordinal, every `Tagged<Tag, X>` for Equatable
   X. The blast radius is the entire Carrier-conforming ecosystem.
   The hurdle for ecosystem-wide conformance addition is materially
   higher than for a single utility method.

**Second-consumer check**:
- Originating consumer: NONE specified. Pure design speculation.
- Second consumer: NONE.

**Verdict**: each of 7a/7b/7c carries the standard [RES-018] hurdle
PLUS an asymmetric-quadrant-ergonomic concern PLUS a design-intent
reversal concern PLUS an ecosystem-wide blast-radius concern. The
second-consumer hurdle is effectively higher here than for individual
utility methods. Defer until a concrete generic consumer surfaces
and the four concerns above can each be answered with evidence.

### Why composition over new Carrier surface

Per [RES-018]'s "Why not compose existing primitives?" question:
each candidate utility is, by construction, expressible as a
*composition* of existing operations on Carrier (`underlying` borrow
+ `init(_:)` consume) plus stdlib operations on Underlying. None
require new Carrier protocol members. The structural answer to
"why not compose" is: every consumer that needs one of these utilities
*can write it inline as a one-liner* against the current Carrier
protocol, parameterized by the utility's specific constraint set.

What shipping a utility ON Carrier buys:

- Discoverability via autocomplete / `extension Carrier where ...`
  visibility.
- One canonical spelling instead of N inline re-derivations.
- A documented contract that downstream consumers rely on.

What it costs:

- Ecosystem-wide commitment — the API ships in every Carrier-aware
  consumer.
- Maintenance surface for every future Carrier conformer review
  ("does this conform sensibly to all the utilities?").
- A precedent: once one utility ships, the next becomes easier to
  argue for, and the per-utility hurdle slowly erodes.

Per [RES-018]: the cost of premature shipping compounds; the cost of
deferred shipping is one extension method per consumer per use case
until evidence accumulates. The asymmetry favors deferral.

### Second-consumer hurdle — synthesis

Of the seven candidate utilities surveyed:

| # | Utility | Prior-art ✓ | Feasible ✓ | Second consumer? | [RES-018] |
|---|---------|-------------|------------|------------------|-----------|
| 1 | `describe` | YES | YES (Q1+) | NONE | DEFER |
| 2 | `reroot` | YES | NO (Q1-only via copy; Q2/Q3/Q4 blocked) | NONE | DEFER |
| 3 | `equate` | partial | YES (Q1) | NONE | DEFER (semantically suspect) |
| 4 | `project` | YES | YES (all four) | NONE (sketch only) | DEFER (sketch is the spec) |
| 7a | `CustomStringConvertible` | YES | Q1-only conditional | NONE | DEFER (4 concerns) |
| 7b | `Equatable` | YES | Q1-only conditional | NONE | DEFER (4 concerns) |
| 7c | `Hashable` | YES | Q1-only conditional | NONE | DEFER (4 concerns) |

Zero of seven candidates have a credible second consumer in the
ecosystem as of 2026-04-26. The carrier-integration retrospective
explicitly flags this as the unresolved validation question for the
entire Carrier capability — Form-D demand has not yet materialized
two days post-shipping.

The mutability-design-space.md DECISION (2026-04-25) and the
swift-mutator-primitives investigation (DEFERRED, 2026-04-25) set the
direct precedent: an ENTIRE PACKAGE was investigated, surveyed
academically (Tier-2 prior-art with 31 citations and 26 verified),
and DEFERRED on [RES-018] grounds despite a genuine academic gap.
The Decimal-Phase-4 cancellation (2026-04-26) is the second
recent precedent — Tier-2 inventory verdicts were retracted on
[RES-018] re-examination.

The pattern is consistent: well-shaped Carrier-adjacent abstractions
without second consumers DEFER. Cross-Carrier utilities are not an
exception.

## Outcome

**Status**: RECOMMENDATION — codify the location decision; ship NO
speculative utilities; promote each candidate from candidate-list to
ship-list only when a real downstream consumer surfaces. Principal
stamp pending.

### Decisions

1. **No utility ships at v0.1.x.** None of the seven candidates passes
   the [RES-018] second-consumer hurdle as of 2026-04-26. The
   structural decision (utilities live inside Carrier Primitives;
   methods on Carrier protocol via constraint extensions; file
   naming `Carrier where {clause}.swift`) is locked in by HANDOFF
   and remains in force; the *content* slate is empty until
   evidence accumulates.

2. **The candidate list is recorded** as anticipated future
   ship-list per `[RES-006a]`, with prior-art citation per item:
   - `describe` — Haskell `Show`, Rust `Display`, Scala `toString`.
     Anticipated consumer: diagnostics (`swift-diagnostic-primitives`
     or downstream).
   - `reroot` — Haskell `retag`. **BLOCKED** for Q2/Q3/Q4 absent
     a Carrier protocol extension (consume-extraction). Q1-only via
     copy. Asymmetric-quadrant trigger; defer pending separate
     investigation.
   - `equate` — Haskell `Eq` on Tagged. Q1-only. Semantically suspect
     across phantom domains; defer pending specialized consumer.
   - `project` — already documented as REFERENCE sketch in
     `generic-consumer-across-quadrants.md`. Promote to shipped
     utility when first concrete consumer (serialization, diagnostics,
     hash-projection witness) surfaces.
   - Conditional stdlib conformances (`CustomStringConvertible`,
     `Equatable`, `Hashable`) — Q1-only. Four compounding concerns
     (asymmetric-ergonomic, conformance shadowing, design-intent
     reversal, ecosystem-wide blast radius) raise the hurdle further.
     Defer until a Carrier-aware generic consumer needs them AND each
     concern is addressed with evidence.

3. **The `reroot` blocker is documented as a structural protocol
   gap**, NOT as a future utility decision. Adding consume-extraction
   to the Carrier protocol is a separate Tier-2 investigation if and
   when demand surfaces. The investigation MUST address: (a) does the
   trivial-self default still work for Q3 ~Escapable Self under a
   new consume requirement? (b) what's the ABI commitment of widening
   the protocol surface mid-cycle? (c) does the addition trigger the
   capability-lift-pattern.md Recommendation #4 concern (~Copyable
   round-trip)? Out of scope for THIS document.

4. **The semantic-suspicion overlay on `equate` is preserved as a
   warning** in this document's anticipated future ship-list. Cross-
   Domain equality elides the phantom-type distinction the wrapper
   exists to enforce; legitimate uses (migration, debugging) are
   specialized. If `equate` ships, it should ship with documentation
   that names the use cases and the suspicion pattern explicitly.

5. **`project` is the strongest near-term ship candidate** when the
   first concrete consumer surfaces — it has a Tier-1 REFERENCE
   sketch already, validates all four quadrants (the Carrier design
   payoff), and has anticipated consumers documented in
   `generic-consumer-across-quadrants.md`. The sketch's status as
   "the spec when consumers land" is the right framing.

6. **No `Carrier where {clause}.swift` file ships in this session.**
   The HANDOFF's structural decision (utilities live inside the
   existing target, file-naming pattern locked) remains uncommitted
   to source code. Source code change deferred to a subsequent cycle
   once Decision #1 produces a concrete first consumer.

### Acceptance gate (when shipping any utility)

For ANY future utility to graduate from candidate-list to shipped:

1. **Concrete second consumer named**, with the consumer's signature
   demonstrating that it materially benefits from the utility being
   on Carrier (vs. inline at the use site).
2. **Quadrant story explicit**: which of Q1/Q2/Q3/Q4 the utility
   supports, with rationale for any quadrant that's excluded
   (asymmetric-ergonomic risk per `dynamic-member-lookup-decision.md`).
3. **Conformance-shadowing analysis**: does the utility introduce
   ambiguity with conformer-side per-type implementations? Empirical
   verification (build the experiment) before shipping.
4. **Verification spike per [EXP-006b]** if the utility involves
   conditional protocol conformance — Q1-only conditional conformances
   on Carrier interact with stdlib protocols in ways that have not
   been empirically verified in this package.

### Constraints honored

- ✓ HANDOFF: structural decision (utilities inside Carrier Primitives;
  methods on protocol; `Carrier where {clause}.swift` naming) preserved
  uncommitted; this document does not contradict it.
- ✓ HANDOFF: defers shipping speculative utilities until research
  lands; this document IS that research, recommending defer.
- ✓ [RES-018]: second-consumer hurdle binding; no utility passes.
- ✓ [API-NAME-*]: no `*Tag` suffixes proposed.
- ✓ [PRIM-FOUND-001]: no Foundation imports.
- ✓ [RES-002a]: package-specific scope; output in
  `swift-carrier-primitives/Research/`.
- ✓ [RES-019]: Step-0 internal grep documented; literature-study and
  ten load-bearing internal docs cited rather than re-surveyed.
- ✓ [RES-021]: Tier-2 prior-art survey across the requested
  ecosystems (Haskell, Rust, Scala, OCaml, F#, Idris/Agda, academic);
  contextualization step applied per universal-adoption pattern.
- ✓ [RES-022]: theoretical grounding cited (parametricity, free
  theorems, Coercible/roles, affine/linear types) — primarily by
  reference to the Tier-3 phantom-typed-value-wrappers-literature-
  study where the formalism already lives.
- ✓ Cross-linked to capability-lift-pattern.md (v1.3.0),
  round-trip-semantics-noncopyable-underlyings.md,
  generic-consumer-across-quadrants.md, carrier-vs-rawrepresentable-
  comparative-analysis.md per HANDOFF Step 5.

### What this document does NOT do

- Ship any source code (no `Carrier where {clause}.swift` file
  authored).
- Modify the Carrier protocol (no consume-extraction added; no new
  protocol members).
- Modify any of the four trivial-self default extensions (Q1/Q2/Q3/Q4
  defaults remain unchanged).
- Propose adding consume-extraction to the Carrier protocol — that
  is a separate Tier-2 investigation gated on `reroot` demand.
- Propose conditional conformances of Carrier to stdlib protocols
  — those are deferred behind FOUR concerns, not just [RES-018].
- Re-litigate the location decision (HANDOFF locks: inside Carrier
  Primitives, methods-on-protocol, `Carrier where {clause}.swift`
  naming).
- Survey utility candidates beyond the seven enumerated — the
  enumeration is grounded in the cross-language survey + the
  capability-lift-pattern.md Form-D candidates + the speculative
  trio from HANDOFF. Additional candidates may surface in future
  consumer-driven research.
- Modify capability-lift-pattern.md or carrier-vs-rawrepresentable-
  comparative-analysis.md or any other prior research. This
  document EXTENDS them; it does not amend.

### Queued escalations

None. The recommendation is "defer all" with the location decision
locked. No principal input required beyond stamp on the recommendation
itself.

### Promotion to authoritative documentation per [RES-006a]

Findings worth promoting:

1. **The candidate-list with prior-art citations** could land as a
   DocC article in `Carrier Primitives.docc/` titled
   *"Future cross-Carrier utilities (anticipated)"* — non-normative,
   serves as a guide for downstream consumers wondering whether to
   write a utility inline or open an issue requesting it on Carrier.
   Optional; deferred to a future DocC cycle.
2. **The "compose inline at the use site, open an issue when N≥2
   consumers exist" guidance** could land as a one-paragraph
   addendum to `carrier-vs-rawrepresentable-comparative-analysis.md`
   §"What this document does NOT do" — explicit ecosystem guidance
   for new Carrier-aware code. Optional.

Neither promotion is required for this document's status to advance to
DECISION; both can be picked up when Decision #6 produces a concrete
first consumer or when a downstream consumer asks.

## References

### Primary sources (cited extensively above)

- `swift-carrier-primitives/Sources/Carrier Primitives/Carrier.swift`
  — protocol declaration; minimal surface (Domain, Underlying,
  borrowing-get underlying, consuming init).
- `swift-carrier-primitives/Sources/Carrier Primitives/Carrier where Underlying == Self*.swift`
  — four trivial-self-Carrier defaults across Q1/Q2/Q3/Q4 quadrants.
- `swift-carrier-primitives/Research/capability-lift-pattern.md`
  v1.3.0 RECOMMENDATION (2026-04-26) — Form-D enumeration; Recs #4,
  #5, #6, #7, #8.
- `swift-carrier-primitives/Research/carrier-vs-rawrepresentable-comparative-analysis.md`
  DECISION (2026-04-24) — non-substitutable; Dimension 5 (zero stdlib
  benefit); Dimension 8 (cross-type morphisms as Carrier's design
  payoff).
- `swift-carrier-primitives/Research/generic-consumer-across-quadrants.md`
  REFERENCE (2026-04-24) — `project` sketch as the operational
  proof of four-quadrant coverage; anticipated first consumers.
- `swift-carrier-primitives/Research/round-trip-semantics-noncopyable-underlyings.md`
  DECISION (2026-04-24) — borrow-vs-consume asymmetry; structurally
  blocks `reroot` for Q2/Q3/Q4 absent new protocol surface.
- `swift-carrier-primitives/Research/mutability-design-space.md`
  v1.1.0 DECISION (2026-04-25) — direct precedent for "well-shaped
  Carrier-adjacent abstraction, no second consumer, defer."
- `swift-carrier-primitives/Research/dynamic-member-lookup-decision.md`
  DECISION — asymmetric-ergonomic trigger; canonical "don't apply"
  signal for Q1-only features.
- `swift-carrier-primitives/Research/sli-*.md` (24 DECISIONs,
  2026-04-24) — recurring SKIP rationale across stdlib-integration
  candidates.

### Cited cross-package research

- `swift-institute/Research/carrier-ecosystem-application-inventory.md`
  v1.2.0 RECOMMENDATION (2026-04-26) — Phase 4 cancellation;
  "Carrier capability is unused so far in production cross-Carrier
  algorithms" finding.
- `swift-institute/Research/operator-ergonomics-and-carrier-migration.md`
  RECOMMENDATION (2026-04-26) — sibling-not-Carrier pattern (Rec
  #7); diagnostic logic for Carrier-vs-not-Carrier classification.
- `swift-institute/Research/decimal-carrier-integration.md`
  RECOMMENDATION (2026-04-26) — second-consumer hurdle bit Phase 4.
- `swift-institute/Research/phantom-typed-value-wrappers-literature-study.md`
  v1.0.0 RECOMMENDATION (2026-02-26, Tier 3) — academic foundation
  (Reynolds 1983, Wadler 1989, Breitner et al. 2014, etc.); cross-
  language wrapper comparison.
- `swift-institute/Research/Reflections/2026-04-26-carrier-integration-retrospective.md`
  — Suggestion #7 explicitly flags Form-D demand validation as
  unresolved.
- `swift-institute/Research/mutator-academic-prior-art-survey.md`
  REFERENCE — Tier-2 prior-art survey for the deferred Mutator
  package; same precedent shape as this document.

### Convention sources

- **[RES-001]** — Investigation triggers.
- **[RES-002a]** — Package-specific research lives in `<pkg>/Research/`.
- **[RES-003]** — Research document structure.
- **[RES-006a]** — Documentation promotion when research establishes
  conventions.
- **[RES-018]** — Premature primitive anti-pattern; second-consumer
  hurdle.
- **[RES-019]** — Step-0 internal research grep before external
  survey.
- **[RES-020]** — Research tiers.
- **[RES-021]** — Prior-art survey requirements; universal-adoption
  contextualization step.
- **[RES-022]** — Theoretical grounding requirements.
- **[API-NAME-*]** — naming conventions (no `*Tag` suffixes).
- **[PRIM-FOUND-001]** — Foundation-free primitives layer.
- **[EXP-006b]** — Confirmation evidence requirements (referenced for
  the acceptance gate).

### Language references

- **SE-0346** — Lightweight same-type requirements for primary
  associated types (enables `some Carrier<Underlying>`).
- **SE-0427** — Noncopyable generics (enables Q2/Q4 Carrier
  conformance).
- **SE-0506** — Noncopyable associated types (enables Carrier's
  `~Copyable & ~Escapable` associated types).
- **SE-0390** — Noncopyable structs and enums.

### Cross-language prior art (verified 2026-04-26)

- [Hackage `tagged-0.8.10` `Data.Tagged`](https://hackage.haskell.org/package/tagged-0.8.10/docs/Data-Tagged.html)
  — `retag`, `untag`, `tagSelf`, `asTaggedTypeOf`, `witness`,
  `tagWith`; typeclass instances forwarding via `deriving newtype`.
- [Hackage `lens-4.17` `Control.Lens.Wrapped`](https://hackage.haskell.org/package/lens-4.17/docs/Control-Lens-Wrapped.html)
  — `_Wrapped`, `_Unwrapped`, `_Wrapping`, `_Unwrapping` Iso forms;
  composable with the lens algebra.
- [Breitner, Eisenberg, Peyton Jones, Weirich, "Safe Zero-cost
  Coercions for Haskell" (ICFP 2014)](https://www.cis.upenn.edu/~sweirich/papers/coercible.pdf)
  — Coercible / role system; the language-level mechanism that
  makes `retag` zero-cost. Cited for "what Swift lacks" analysis.
- [`derive_more` crate documentation](https://docs.rs/derive_more/)
  — Rust newtype trait-forwarding derives; no cross-newtype
  morphisms shipped.
- [Scala 3 opaque types reference](https://docs.scala-lang.org/scala3/reference/other-new-features/opaques.html)
  — explicit extension methods required; no automatic forwarding;
  no documented cross-opaque-type morphism pattern.
- [F# units of measure (Microsoft Learn)](https://learn.microsoft.com/en-us/dotnet/fsharp/language-reference/units-of-measure)
  — compile-time discrimination; explicit conversion factors;
  no cross-unit "rebrand" operation by design.
- [McBride, "Faking it: Simulating dependent types in Haskell"
  (JFP 2002)](https://www.cambridge.org/core/journals/journal-of-functional-programming/article/faking-it-simulating-dependent-types-in-haskell/A904B84CA962F2D75578445B703F199A)
  — type-equality witnesses; phantom indexing; foundational
  technique cited from the literature study.

### Provenance

This document was authored as the resolution of the
`HANDOFF.md`-described investigation
("Cross-Carrier Utilities Research"). The HANDOFF locked in the
structural decision (utilities inside Carrier Primitives; methods on
the Carrier protocol via constraint extensions; `Carrier where
{clause}.swift` naming); this document resolves the content decision.
Per HANDOFF, the second-consumer hurdle ([RES-018]) was identified as
binding; this document confirms with seven-candidate analysis. The
recommendation is "defer all" — consistent with the Mutator-package
deferral (2026-04-25) and the Decimal-Phase-4 cancellation
(2026-04-26).
