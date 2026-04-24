---
source_simulation: forums-review-simulation-2026-04-24.md
triage_date: 2026-04-24
rule: FREVIEW-012
pre_classification_automated: true
final_classification_requires_human_review: true
---

# Concreteness-anchor triage — forums-review-simulation-2026-04-24

Pre-classifications are produced by `scripts/triage_simulation.py` using the
concreteness-anchor regex catalogue. **Final classifications require a human
review pass** to apply the manual escape hatch per [FREVIEW-012] — a post with
low anchor count MAY still be load-bearing if it surfaces a novel semantic
property of the target package. Such escapes MUST be justified in the
`final_classification_notes` column.

Quoted blocks (Discourse-style `> text` lines) and fenced code blocks are
excluded from the count — they don't count as the post author's own anchoring.

| # | handle | archetype (from comment) | anchor total | pre-classification | final classification | disposition |
|---|---|---|---:|---|---|---|
| 1 | @op | — | 3 | op-follow-up | _pending review_ | _pending_ |
| 2 | @reviewer-c2 | The ~Copyable / Sendable / protocol-shape reviewer (canonica… | 2 | partially-load-bearing-candidate | _pending review_ | _pending_ |
| 3 | @reviewer-c3 | The closure/expression/syntax technical reviewer (canonical … | 1 | archetype-shaped-candidate | _pending review_ | _pending_ |
| 4 | @reviewer-c5 | The pointed -1 reviewer (canonical c5, naming framing) | 3 | load-bearing-candidate | _pending review_ | _pending_ |
| 5 | @reviewer-c4 | The constructive Evolution-process reviewer (canonical c4, p… | 9 | load-bearing-candidate | _pending review_ | _pending_ |
| 6 | @reviewer-c8 | The SwiftPM / build-tooling / modularity reviewer (canonical… | 3 | load-bearing-candidate | _pending review_ | _pending_ |
| 7 | @reviewer-c1 | The general-purpose technical reviewer (canonical c1, docume… | 7 | load-bearing-candidate | _pending review_ | _pending_ |
| 8 | @reviewer-c6 | The Core-Team-aware process voice (canonical c6) | 5 | load-bearing-candidate | _pending review_ | _pending_ |
| 9 | @reviewer-c5b | The pointed -1 reviewer (canonical c5, scope/motivation fram… | 3 | load-bearing-candidate | _pending review_ | _pending_ |
| 10 | @reviewer-short | brief nit (community-voice, short form) | 3 | load-bearing-candidate | _pending review_ | _pending_ |
| 11 | @op | OP follow-up | 6 | op-follow-up | _pending review_ | _pending_ |

## Anchor breakdown per post

- Post 1 (@op): backticked_type=1, backticked_qualified=1, se_crossref=1 (total 3).
- Post 2 (@reviewer-c2): file_line=1, readme_ref=1 (total 2).
- Post 3 (@reviewer-c3): readme_ref=1 (total 1).
- Post 4 (@reviewer-c5): backticked_type=1, backticked_fn=2 (total 3).
- Post 5 (@reviewer-c4): backticked_type=6, readme_ref=3 (total 9).
- Post 6 (@reviewer-c8): se_crossref=1, package_swift=1, readme_ref=1 (total 3).
- Post 7 (@reviewer-c1): docc_catalog=1, file_line=1, backticked_type=4, readme_ref=1 (total 7).
- Post 8 (@reviewer-c6): backticked_fn=1, backticked_qualified=1, readme_ref=3 (total 5).
- Post 9 (@reviewer-c5b): backticked_type=1, readme_ref=2 (total 3).
- Post 10 (@reviewer-short): package_swift=1, readme_ref=2 (total 3).
- Post 11 (@op): backticked_type=1, backticked_fn=2, readme_ref=3 (total 6).

## Human-review instructions

For each row:

1. Confirm or override the pre-classification. Overrides MUST be justified in prose.
2. Write a one-sentence `disposition`: act-on / answer-cheaply / discount / escape-to-load-bearing-because-X.
3. Archetype-shaped posts that are NOT escape-hatched should drive zero post-launch action.
4. If more than 50% of substantive posts are archetype-shaped, consider re-running the simulation with a different seed or a narrower archetype mix — the current thread may not be exercising the package's real surface.
