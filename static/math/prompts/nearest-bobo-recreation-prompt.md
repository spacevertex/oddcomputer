# Build "Nearest + Bobo": an integer particle simulator

Build a single self-contained HTML page (inline CSS and JavaScript, no
build step, no external dependencies beyond an optional web font) that
simulates and visualizes a simple discrete particle rule on an integer
2D grid, with tools for composing, saving, loading, and exploring
patterns by hand. Canvas 2D for rendering. No frameworks needed.

Everything below — positions, velocities, accelerations — is an exact
integer at all times. No floats, no rounding, anywhere in the physics.
This is the single most important property of the whole project: the
rule must be exactly reversible and exactly periodic when it does
cycle, and that only holds if every value involved is an exact integer.

## The core rule

Two kinds of particle share one 2D integer grid:

- **nearest** particles: have a position `(x, y)` and velocity
  `(vx, vy)`, all integers. They move every tick.
- **bobo** particles: have only a position `(x, y)`. They never move,
  but they are valid candidates when any nearest particle searches for
  its nearest neighbor.

Every tick, for every **nearest** particle `p`, independently:

1. Find its nearest other particle(s) — considering every other
   particle on the board regardless of type — by squared Euclidean
   distance `(qx-px)^2 + (qy-py)^2` (never take a square root; integer
   squared distance is exact and sufficient for comparison).
2. **Tie-break rule, stated precisely:** if more than one other particle
   is tied for the minimum squared distance, do not arbitrarily pick
   one. Instead, for every tied neighbor `q`, take `sign(qx-px)` and
   `sign(qy-py)` (where `sign` is -1, 0, or +1) and **sum** these
   signs separately across all tied neighbors to get `sumX` and
   `sumY`. The actual pull for this tick is then
   `dvx = sign(sumX)`, `dvy = sign(sumY)` — the sign of the *combined*
   pull from every tied neighbor, not the pull from any single one of
   them. With only one nearest neighbor this reduces to the obvious
   case. With several tied neighbors pulling in different directions,
   their pulls can partially or fully cancel on one axis while still
   adding up on the other.
3. Update velocity: `vx += dvx`, `vy += dvy` (each component changes
   by at most 1 per tick, and can also stay the same if the sign came
   out to 0).
4. Update position using the **new** velocity: `x += vx`, `y += vy`.

**This update must be simultaneous**, not sequential: compute every
particle's delta from one consistent, unmutated snapshot of every
particle's position first, then apply every position/velocity update
together afterward. A particle must never see another particle's
already-updated-this-tick position when computing its own nearest
neighbor.

`bobo` particles never move and are not subject to any of the above —
they are source data for other particles' searches only.

This rule, run from a cold start (every particle's velocity at 0), is
occasionally genuinely periodic — the state returns exactly to its
starting state after some number of ticks, forever. Most starts are
not periodic; they wander indefinitely. There is no concept of energy
conservation and no forced boundary — particles can travel arbitrarily
far from the origin.

## Data model

Keep one flat array of particle objects, each with at least `type`
(`'nearest'` or `'bobo'`), `x`, `y`, `vx`, `vy` (bobo's `vx`/`vy` are
always 0 and simply unused), and `color` (a CSS color string). Keep a
parallel array of "trail" entries, one per particle, index-aligned: for
a bobo particle this is `null`; for a nearest particle it's an array of
`{x, y}` points recording its path, capped at a reasonable maximum
length (e.g. 500 points — drop the oldest point as new ones are
pushed past the cap, so memory and draw cost stay bounded even for a
simulation left running a long time).

## The simulation loop

- **Play / Pause**: toggles continuous ticking at a steady fixed rate
  (pick a reasonable default, e.g. somewhere around 15-20 ticks per
  second — exact value isn't critical, just keep it steady and
  readable).
- **Step**: advance exactly one tick while paused.
- Redraw only when the visible state actually changed (a tick
  occurred, or the user did something that changes what's on screen) —
  don't burn CPU repainting an identical frame.

## Camera and rendering

- World-to-screen transform supporting panning (click-and-drag the
  background) and at least two zoom levels — a normal working view and
  a tighter zoomed-in view (e.g. showing roughly 30 world units across
  the screen) toggled by a button, for inspecting small clusters
  closely.
- A background grid of faint lines at integer-ish intervals, with the
  x=0 and y=0 axis lines drawn more prominently than the rest of the
  grid so orientation is always clear.
- **Nearest particles**: drawn as soft glowing circles. For
  performance, pre-render one glow sprite per distinct color (on an
  offscreen canvas, using a radial gradient) and cache it, rather than
  recomputing an expensive shadow-blur effect for every particle on
  every frame — this matters once there are dozens of particles on
  screen at once.
- **Bobo particles**: drawn as small static squares in a single muted
  color (pull this from a CSS custom property so it's easy to
  reskin). Brighten a bobo's square slightly whenever it is currently
  serving as the (or a tied) nearest neighbor for some nearest
  particle this tick — a cheap, useful visual cue for which anchors
  are actually "in play" right now.
- Each new nearest particle gets a distinct, readable color assigned
  from a cycling palette with enough contrast to tell particles apart
  at a glance even with many on screen; fall back to generated,
  evenly-spread hues if the palette runs out.
- **Trails toggle**: when on, draw each nearest particle's trail as a
  translucent line in its own color.
- **Vectors toggle**: when on, draw each nearest particle's current
  velocity as a single plain line segment from its position to
  `position + velocity` — no arrowhead. (It's expected and fine for
  this segment to jump to a different direction the very next tick,
  since velocity itself changes every tick.)

## Controls panel

Buttons: **Play**, **Step**, **Roll**, **Recall**, **Save**, **Load**,
**Presets**, **Clear**, **Add Nearest**, **Add Bobo**.

Sliders, each with a live numeric readout next to it:

| Slider | Range | Default | Effect |
|---|---|---|---|
| Nearest count | 1–100 | 20 | how many nearest particles Roll spawns |
| Nearest bounds (±) | 1–100 | ±10 | symmetric spawn box for nearest particles |
| Bobo count | 0–100 | 20 | how many bobo particles Roll spawns |
| Bobo bounds (±) | 10–100 | ±80 | symmetric spawn box for bobo particles |
| Initial speed (±) | 0–5 | ±4 | symmetric range each spawned nearest particle's vx/vy is randomly drawn from |

**Roll**: respawns the whole board — random integer positions within
each type's current bounds slider, random integer initial velocities
within the initial-speed slider's range for nearest particles (bobo
velocity is always 0) — clearing trails and the tick counter. Also
takes and stores a snapshot of this exact freshly-rolled state.

**Recall**: restores the particle field to exactly the snapshot taken
at the last Roll. Useful for getting back to a known-good starting
point after accidentally deleting a particle or otherwise disturbing
an interesting run, without having to re-roll randomly and lose it.

**Clear**: empties the board to zero particles.

## Adding a single particle by hand

**Add Nearest**: click-driven two-step placement. The first click sets
where the particle will spawn. The second click's offset *from* the
first point becomes its initial velocity (`vx, vy = secondClick -
firstClick`) — so dragging out a vector visually sets both position
and speed/direction in one gesture. Support nudging the candidate
point with keys (e.g. `i`/`j`/`k`/`l` for up/left/down/right, a larger
step when Shift is held) before confirming with Enter or a click;
Escape cancels.

**Add Bobo**: single click-to-place (no velocity to set).

## Loading and placing a saved pattern (the "ghost" system)

**Load** opens a file picker, reads a JSON pattern file (format
below), and enters placement mode rather than immediately dropping the
particles onto the board.

In placement mode, the loaded pattern is shown as a translucent
"ghost" overlay, positioned at a candidate center point that follows
the mouse by default, or can be moved precisely with the same
`i`/`j`/`k`/`l` nudge keys used for hand-adding a particle.

- `o` rotates the pending pattern 90°: transform every relative
  position `(x,y) -> (-y,x)` and every velocity `(vx,vy) -> (-vy,vx)`
  the same way, so velocity stays consistent with the new orientation.
- `u` mirrors the pending pattern left-right: `(x,y) -> (-x,y)`,
  `(vx,vy) -> (-vx,vy)`.
- Enter, or a click on the canvas, confirms placement at the current
  candidate position. Escape cancels placement entirely, discarding
  the pending pattern.
- **Loading is additive**: confirming placement *adds* the pattern's
  particles to whatever is already on the board — it never clears or
  replaces the existing field. This is what allows multiple separate
  patterns to be composed together in the same simulation.

**Centering rule, exact:** when a pattern is loaded, compute its own
bounding box and express every particle's position relative to that
box's center, so rotation/mirroring happen around a sensible point and
so the ghost can be repositioned by moving just one reference point.
If a bounding-box axis has an *odd* span, pad that axis by 1 before
computing the center, so the center is always an exact integer on both
axes. This guarantees every relative coordinate is an exact integer
and the pattern always lands on exact integer world coordinates when
placed — never a fractional or rounded position.

## Preview while placing

Before committing a pending pattern, let the user watch what would
actually happen if they dropped it in right there, against the live
field, without having to commit and manually undo if it doesn't work:

- Pressing `p` while placing starts a **preview**: snapshot the
  current live particles and the ghost (at its current candidate
  position and orientation) into one combined, temporary copy, then
  run the *real* simulation rule on that copy, live, redrawing it each
  tick. The ghost stays rendered in one fixed "ghost color" throughout
  the preview, regardless of what color it would eventually get once
  placed; the live particles keep their own individual colors. Trails
  accumulate during the preview, for both the live particles and the
  ghost, and are discarded completely once the preview ends.
- Critically, **the real/live particle array is never touched by a
  preview** — it runs entirely on a separate, temporary copy. This
  makes "stop the preview" trivial and risk-free: there is nothing to
  restore, because nothing real ever changed.
- Starting a preview always pauses the main simulation if it was
  running.
- Any action that represents the user changing their mind about the
  setup — moving the mouse, nudging with `i`/`j`/`k`/`l`, rotating
  (`o`), mirroring (`u`) — first reverts an active preview back to the
  live field's real, untouched state, then performs its own action
  normally. Pressing `p` again while already previewing also reverts
  first, then immediately restarts the preview from the same
  snapshot — a deterministic replay of the identical scenario, since
  nothing about the setup changed.
- Confirming placement (Enter or a click) while a preview is active
  reverts the preview first, then places the pattern at its
  **pre-preview** candidate position and orientation — never wherever
  a hypothetical preview run happened to leave it. The point of the
  preview is to inform the decision, not to relocate the ghost as a
  side effect.
- Include a safety net so a non-periodic or divergent pending pattern
  can't run away unbounded: stop stepping the preview (freeze it in
  place, don't revert it) once it exceeds a generous tick count (for
  example 5000 ticks) or once any particle's coordinate exceeds a
  generous distance from the origin (for example 100,000). Either way
  the preview simply holds still and waits for the user's next move,
  rather than crashing, hanging, or silently reverting on its own.

## Pre-roll: advancing the pending pattern's own clock

Timing often matters for how a pattern will interact with an existing
field, so before ever starting a preview, let the user advance the
*pending* pattern forward on its own:

- `;` steps the pending pattern forward by exactly one tick, using the
  real simulation rule, but treating the pending pattern as entirely
  self-contained — its own particles only, exactly as if it were
  loaded and played completely on its own with no live field present
  at all. This lets the user dial in a specific phase of an oscillator
  before introducing it to a hand-off, rather than always introducing
  it at tick zero.
- Each `;` press advances one more tick from wherever the pattern
  currently sits. This persists across ordinary repositioning (mouse
  movement, nudging) and across rotate/mirror — those are independent
  adjustments and must not reset or interfere with the pre-roll.
- If an *active preview* is aborted (by any of the actions listed in
  the previous section), the pending pattern's pre-roll resets back to
  its un-advanced state — whatever rotation/mirror is currently
  applied, but with zero pre-roll ticks — so the next preview attempt
  starts its timing fresh rather than silently compounding on top of
  the last attempt. Pressing `p` again to **replay** an existing
  preview is explicitly *not* treated as an abort for this purpose —
  it preserves the current pre-roll exactly, since a replay is meant
  to show the identical scenario again, not a new one.

## Saving

**Save** serializes the current live particle field to a JSON file and
prompts for a filename before downloading it.

## Pattern file format

A single JSON **object** (not an array — arrays are reserved for
manifest files, see below):

```json
{
  "nearest": [
    { "x": 0, "y": 0, "vx": 1, "vy": 0 }
  ],
  "bobo": [
    { "x": 5, "y": 5 }
  ]
}
```

- `nearest`: array of moving particles, each with integer `x`, `y`,
  `vx`, `vy`.
- `bobo`: array of static particles, each with integer `x`, `y` only.

This is both what **Save** produces and what **Load** (and presets,
below) expect to read.

## Presets gallery and manifest format

**Presets** opens a gallery dialog listing a curated set of saved
patterns, without the user having to manually download and re-upload
files. The gallery's contents come from a `manifest.json` file that
lives in a `patterns/` folder alongside the page itself, fetched with
a relative path (so the whole thing keeps working regardless of what
URL path the site is actually served from).

Manifest format: a JSON **array**, each entry shaped as:

```json
[
  { "file": "some-pattern.json", "name": "Display Name" },
  { "file": "another-pattern.json", "name": "Another Pattern" }
]
```

`file` is a filename relative to the same `patterns/` folder (not a
full path); `name` is what's shown in the gallery UI. Fetch each
pattern file on demand only when its entry is clicked, and route it
through the exact same placement flow as a manually loaded file —
ghost preview, rotate, mirror, nudge, preview, pre-roll, and
append-not-replace on confirm should all behave identically whether
the pattern came from a preset or a manual file load.

It's fine (and a nice touch) to remember lightweight gallery state —
e.g. scroll position or last opened — across sessions using
`localStorage`, as long as it's wrapped in a `try`/`catch` so the
picker still works correctly on a browser or context where
`localStorage` happens to be unavailable.

## Oscillator watch

Clicking a nearest particle opens a small context menu offering at
least **Watch** and **Delete**.

**Watch** tracks that particle, and transitively, any other particle
that ever becomes one of its tied-nearest-neighbors at any point while
watching — growing a dependency cluster over time as new particles
become relevant. Every tick, hash the exact combined `(x, y, vx, vy)`
state of every particle currently in the cluster. If that exact hash
ever repeats, a genuine cycle has been found live — report the period
(the gap between the two matching ticks) and which particles make up
the oscillating cluster. This is how a true oscillator can be
discovered by watching an otherwise-chaotic live field, rather than
only by deliberately searching cold starts offline.

**Delete** removes the clicked particle (and its trail entry) from the
board; works for either particle type.

## What "done" looks like

A single HTML file that opens in a browser with no build step, spawns
a reasonable default field on first load, and supports: Play/Step/Roll
/Recall/Clear, hand-adding single particles of either type, loading a
pattern file or a preset into a movable/rotatable/mirrorable/
pre-rollable ghost with a live interactive preview before committing,
appending (never replacing) on confirm, saving the current field back
out to a file, toggleable trails and velocity vectors, and the
click-to-watch oscillator-discovery tool — all built on the exact
simultaneous-update, sign-of-summed-ties integer rule described at the
top, with every value involved staying an exact integer from spawn to
however many ticks it's run.
