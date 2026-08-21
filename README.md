# mekuri (めくり)

**The page-turn decision: is a frame owed, and the permission to draw it.**

Zero dependencies. `no_std`. One `AtomicU64`.

```rust
use mekuri::{Cause, Gate, Verdict};

let mut gate: Gate<Why> = Gate::new();
let ledger = gate.ledger();          // Clone + Send + Sync — hand one to every producer

ledger.mark(Why::Commit);            // one atomic OR, from any thread

match gate.open() {
    Verdict::Draw(pass) => pass.spend(|causes| { compose()?; flip() })?,
    Verdict::Skip => { /* nothing to draw, and no way to draw it */ }
}
```

## Why it exists

Two renderers grew this decision independently and both got it wrong — in
opposite directions, from the same root: **the decision was one statement and
the action was another, with nothing tying them together.**

| | the decision | what it did | idle cost |
|---|---|---|---|
| a GPU terminal | "this frame is unnecessary" | rendered it anyway | **50.7%** of a core |
| a compositor | "the damage was empty" | had already composed the frame | **38.2%** of a core |

Both figures measured on a **static screen presenting zero frames**. The
terminal's own counter read `9_934_969` of `10_726_562` frames "skipped" — none
of which were skipped, because the branch that recorded the verdict fell
through to a full repaint. Its source comment estimated the cost at "≈0.2% of
one core … free correctness with no measurable cost": reasoned, never measured,
wrong by ~250×.

## The invariant

**The decision produces the permission.** `Gate::open` returns a `Verdict`, and
only its `Draw` arm carries a `Pass`. Drawing and presenting take a `Pass`, and
nothing else constructs one.

| illegal state | mechanism |
|---|---|
| drawing work obtained from a `Skip` | `Skip` carries no `Pass` |
| a `Pass` conjured without deciding | only `Gate::open` constructs one |
| two renderers draining one ledger | `Gate` is `!Clone` |
| a frame's causes lost to an error path | `Pass` re-marks on drop |

That last row is worth stating plainly, because neither original had noticed
it. When a render fails partway, the reasons the frame was owed have already
been drained; without putting them back the screen stays stale until something
unrelated happens to dirty it. `Pass` restores its causes on `abandoned()` **and
on an un-surrendered drop** — fail toward a wasted frame, never a frozen
display. `Pass::spend` ties this to a `Result` so there is no separate statement
to forget.

## The honest ceiling

mekuri cannot see a consumer's other functions, so a `present()` that takes no
`Pass` still compiles and can still be called from the `Skip` arm. That is
`only-mitigated`, not unrepresentable, and it is why `spend` exists: to make
the correct shape the shortest one to write. **Consumers should have exactly
one present path, and it should take a `&Pass`.**

## What this crate deliberately does not own

**Region damage.** The two founding consumers track 1-D row spans and 2-D
rectangles respectively — same goal, genuinely different shapes. Forcing them
into one type would be a bad abstraction that looks well-motivated. mekuri
answers only *whether* a frame is owed and *why*; each consumer keeps its own
description of *what changed*.

## Causes are enumerable

`Cause::all()` makes the set closed and introspectable, so a drained bitmask
renders back into names — an operator asking "why did it redraw?" gets
`"pointer+chrome"`, not a number. `bits_are_distinct::<C>()` is a one-line unit
test that catches two variants sharing a bit, which would otherwise merge two
reasons silently.

## License

MIT.
