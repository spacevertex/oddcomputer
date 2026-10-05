# Build a 4D shadows viewer: four 3D isometric views of one oscillator

Build a single self-contained HTML page (inline CSS and JavaScript, no
build step, no external dependencies beyond an optional web font).
This page shows one 4D periodic particle pattern at a time as **four
separate 3D isometric views**, arranged in a 2x2 grid, each one a true
"shadow" that drops one of the four axes entirely. It runs entirely by
itself: no placing, composing, saving, loading, or camera controls —
the only input is a single key to switch which pattern is showing.

Positions and velocities are exact integers at all times in the
underlying simulation. All rotation, projection, scale, and timing is
floating point and purely cosmetic — it never touches the simulation's
own integer state.

## The core rule (4D)

Every particle has a position `(x, y, z, w)` and velocity
`(vx, vy, vz, vw)`, all integers.

Every tick, for every particle `p`, independently:

1. Find its nearest other particle(s) by squared distance across all
   four axes: `(qx-px)^2 + (qy-py)^2 + (qz-pz)^2 + (qw-pw)^2`.
2. **Tie-break rule:** if more than one other particle is tied for the
   minimum squared distance, sum `sign(qx-px)`, `sign(qy-py)`,
   `sign(qz-pz)`, `sign(qw-pw)` separately across every tied neighbor,
   then take the sign of each of those four sums as the actual pull
   this tick. (Exactly the 3D rule, extended to a fourth axis — pulls
   from different tied neighbors can cancel on one axis while adding
   up on another.)
3. Update velocity: `vx += dvx`, `vy += dvy`, `vz += dvz`,
   `vw += dvw`.
4. Update position using the new velocity on every axis.

This update is **simultaneous** across all particles (compute every
delta from one unmutated snapshot first, then apply every update
together) — identical in spirit to a 3D or 2D version of this same
rule, just with a fourth coordinate carried through everywhere.

## Pattern data: hardcoded, not loaded from files

This page is not a general-purpose loader. Pick a small number (two or
three is plenty) of pre-verified 4D oscillators and embed their exact
initial conditions and periods directly in the page's own source, as
a plain array, e.g.:

```js
const OSCILLATORS = [
  { label: 'period 72, extents (4,16,9,2)', period: 72, initial: [
    { x: -1, y: -2, z: 2,  w: 1,  vx: 0, vy: 0, vz: 0, vw: 0 },
    { x: 1,  y: -1, z: -2, w: 0,  vx: 0, vy: 0, vz: 0, vw: 0 },
    { x: 3,  y: -2, z: 2,  w: -1, vx: 0, vy: 0, vz: 0, vw: 0 },
  ]},
  // ...a second and third oscillator, same shape
];
```

(See the closing section for how to find genuinely good ones to embed
here — small particle counts, truly 4D, asymmetric.)

For whichever oscillator is active, precompute its entire period once
(raw exact integers), and compute a pure *display* centering shift —
subtract the bounding-box center (across all four axes, over the whole
period) from every stored point before any rendering math touches it.
This shift is for presentation only and must never feed back into the
physics.

## Four panels, each a true 3D shadow

Lay out four canvases in a 2x2 grid. Each one shows **three of the
four axes**, with the fourth genuinely discarded for that panel — not
re-encoded as depth or color, a true shadow with real information
loss. Assign roles consistently: of the three axes a panel shows, the
*last* one (in `x, y, z, w` order) plays the vertical/"up" role in
that panel's own 3D isometric rendering, and the other two play the
two floor roles, in order. Concretely, the four panels are:

| Panel | Shows | Drops | Floor-A | Floor-B | Up |
|---|---|---|---|---|---|
| 1 | x, y, z | w | x | y | z |
| 2 | x, y, w | z | x | y | w |
| 3 | x, z, w | y | x | z | w |
| 4 | y, z, w | x | y | z | w |

Label each panel on screen with which three axes it shows (or
equivalently, which one it drops), so it's always clear which shadow
is which.

### Rendering each panel: reuse a full 3D isometric viewer, per panel

Each panel's own rendering is a complete, ordinary 3D isometric view —
restated here in full so this document stands on its own:

- Project a panel's three assigned (already-rotated — see below)
  coordinates `(a, b, c)` to screen space as:
  `ix = (a - b) * cos(30deg)`, `iy = (a + b) * sin(30deg) - c`.
- **Depth** for that panel is `a + b + c` (after rotation) — used for
  both the occlusion rule and the size/alpha cue, exactly as below.
- **Occlusion**: for a strictly closer particle `A` and a farther
  particle `B` (by this panel's own depth), `A` hides `B` if their
  on-screen circles overlap (compare squared screen-distance against
  the squared sum of their current radii — no square root needed),
  *unless* `A` and `B` are exactly coincident in the full original 4D
  position (all four coordinates equal) — true coincidence skips the
  check entirely, so genuinely identical points both render rather
  than flickering on an arbitrary tie.
- Each particle's on-screen size and opacity interpolate between a
  minimum and maximum based on that panel's own normalized depth
  (closer = bigger and more opaque).
- **Trails**: draw each particle's complete path across the whole
  known period, every frame (the trajectory is fully known in
  advance, so there's no reason to only reveal the portion played so
  far).
- Pre-render one glow sprite per particle color and reuse it rather
  than recomputing a blur effect every particle, every frame.
- Each panel gets its **own gizmo** (see below) in one corner.

## The shared 4D rotation

Unlike an interactive 3D viewer, there is no user-steered camera here
— the whole page runs on a timer. Represent the current orientation as
a single 4x4 rotation matrix `R`, starting at the identity, shared by
*all four* panels: rotate the raw (display-shifted) 4D point by `R`
first, then each panel independently reads off whichever three of the
four resulting coordinates it's assigned, feeding them into its own
ordinary 3D projection above.

### What "rotate around an axis" means in 4D

In 3D, "rotate around the X axis" unambiguously means mixing Y and Z.
In 4D, the subspace orthogonal to a single axis is three-dimensional
(the other three axes together), not a single plane, so "rotate
around an axis" has no single natural meaning the way it does in 3D.
This needs an explicit, consistent choice, not a derivation:

> Treat the axes as a cycle `x -> y -> z -> w -> x`. A phase named for
> one axis rotates the plane spanned by the **next two** axes in that
> cycle: the `x`-phase rotates the `y`-`z` plane, the `y`-phase
> rotates `z`-`w`, the `z`-phase rotates `w`-`x`, and the `w`-phase
> rotates `x`-`y`.

This touches 4 of the 6 possible coordinate-plane pairs over one full
cycle; the two "diagonal" pairs (`x`-`z` and `y`-`w`) are never
rotated by this scheme. That's an accepted, deliberate simplification
— the goal is something instructive and watchable, not an exhaustive
tour of every possible rotation plane.

A useful, visible consequence of this choice: during, say, the
`x`-phase (rotating `y`-`z`), the two panels that happen to show
*both* `y` and `z` (panels 1 and 4 in the table above) will display
the rotation clearly and fully, while the two panels missing one of
those axes (panels 2 and 3) will show the remaining one of the pair
shift in a way that looks only partially explained from within that
shadow alone — which is the actual point of showing four shadows
instead of one.

## The automatic state machine

Alternate between two modes, repeating forever:

- **Move** (a few seconds, e.g. 4): step the simulation forward at a
  steady tick rate; `R` stays completely fixed.
- **Rotate** (a few seconds, e.g. 5): the simulation is frozen in
  place (no ticking); `R` rotates smoothly through a full 360 degrees
  within the *current* phase's plane (see above), then advances to the
  next phase (`x -> y -> z -> w -> x -> ...`) and returns to Move.

Only redraw when the visible state actually changed: during Move,
that's whenever the tick actually advances (likely well below the
animation-frame rate, so most frames should do nothing); during
Rotate, throttle repainting to a reasonable rate (e.g. ~30fps) rather
than the full animation-frame rate — smooth rotation doesn't need
60fps, and four canvases redrawing at full rate on every single frame
is needlessly demanding for what it buys visually.

## Scale and depth range: one shared value, safe at any rotation

Compute a **single** scale and depth-cue range, shared by all four
panels (not fit independently per panel) — this makes the four shadows
directly, visually comparable at a glance.

Size it for the worst case across *every possible rotation*, exactly
as a 3D isometric viewer would, generalized one dimension further: an
orthogonal projection — including the act of dropping one 4D
coordinate to get a 3D shadow — can only ever shrink a distance, never
grow it. So the pattern's full **4D bounding-sphere radius** (maximum
distance from its own center, in all four dimensions, across the
whole period) bounds the projected extent of *every* possible 3-axis
shadow, at *any* rotation whatsoever. As with the 3D case, the raw
distance alone is not the right bound on its own — multiply by the
same isometric scale constant (`K = sqrt(6)/2`) used in the projection
formula. Verify this numerically (sample many random rotation
sequences across all four panel assignments, confirm the actual
projected screen distance never exceeds `K * radius`) before trusting
the formula; it should also come out *tight* — the worst case actually
reached, not just safely under the bound.

The depth-cue range can be bounded the same way: for any panel, the
depth (sum of its three rotated, shown coordinates) never exceeds
`sqrt(3) * radius` in absolute value, regardless of rotation.

## The orientation gizmo, one per panel — live, not decorative

Each panel's gizmo must genuinely reflect what's on screen, not just
sit there as a static decoration:

- Build it from the **true 4D unit vectors** for whichever three axes
  that panel displays (e.g. for the panel showing x, y, z: the unit
  vectors along x, along y, and along z). Rotate each one by the
  current shared `R`, exactly as every particle is rotated, then
  reduce each to that panel's own three shown components — generally
  no longer unit length or mutually orthogonal once reduced, and
  that's correct, not a bug to fix: part of a true axis can rotate
  into the one dimension that particular shadow cannot show, and the
  gizmo should honestly shrink or skew to reflect that.
- Otherwise built and rendered exactly like a 3D isometric viewer's
  gizmo (restated from that project): one corner at the local origin,
  faces as translucent depth-sorted fills, the three edges meeting at
  that origin corner drawn brighter and extended slightly past the
  cube's own edge length, each labeled with the actual axis letter
  (`x`, `y`, `z`, or `w`) it represents *for this panel*. A panel
  showing x/y/z gets a gizmo labeled x/y/z; the panel showing y/z/w
  gets one labeled y/z/w, and so on.
- Fixed screen position and size, independent of the shared pattern
  scale — the gizmo itself never changes size, only its orientation.

## The per-panel wiggle

Even though each of the four shadows is a genuine 3D object, the
isometric view only ever shows it from one fixed angle — the same
limitation a single frozen 2D view of a real 3D object has. Give each
panel a brief, fully independent "turn it over and look" motion of its
own, on top of (but never interfering with) everything above:

- Confined entirely to that one panel's own three-axis local space —
  never touches the shared `R`, never affects the other panels.
- Only happens during **Move**, never during **Rotate**, so the two
  kinds of motion (the shared hyperplane rotation, and this local
  wiggle) are never visually confused with each other.
- Triggers once per Move phase, starting a short way into it (e.g.
  after 1 second) and lasting a couple of seconds (e.g. 1.5), then the
  panel holds still again for the remainder of that phase.
- **The motion itself is two-axis, not a single back-and-forth nod** —
  it should look like someone actually picking the object up and
  turning it, not a single repeated head-shake. Give each panel its
  own pair of local axes (call them the "Y" and "X" tilt axes for that
  panel; vary the actual pairs across the four panels so they don't
  all turn identically). Trace this path, as a fraction `t` from 0 to
  1 across the whole wiggle duration, using a smooth ease — e.g.
  `ease(u) = (1 - cos(u * pi)) / 2` for `u` from 0 to 1, which starts
  and ends each quarter at zero velocity so nothing changes speed
  abruptly at a hand-off point:
  - `t` in `[0, 0.25]`: tilt angle Y eases from 0 up to its peak (e.g.
    20 degrees); tilt angle X stays at 0.
  - `t` in `[0.25, 0.5]`: Y holds at its peak; X eases from 0 up to
    its own peak.
  - `t` in `[0.5, 0.75]`: Y still holds at its peak; X eases back down
    from its peak to 0.
  - `t` in `[0.75, 1.0]`: Y eases back down from its peak to 0; X
    stays at 0.
  - At `t = 0` and `t = 1`, both angles are exactly zero — the panel
    always returns precisely to its plain, un-wiggled orientation.
  - Apply both rotations to a vector by rotating around the Y axis by
    the current Y angle first, then rotating that result around the X
    axis by the current X angle (axis-angle / Rodrigues' rotation
    formula for each step).
- The gizmo must carry the exact same wiggle as the particles in its
  panel — it should never show an orientation that isn't actually the
  one on screen.
- Outside its brief window, a panel's wiggle contributes nothing
  (identity) — the plain, fixed isometric view stays the primary way
  the pattern is presented almost all of the time; the wiggle is a
  brief supplement, not a redesign of the main view.

## Controls

A single key (e.g. the space bar) switches to the next embedded
oscillator, cycling back to the first after the last. Switching resets
`R` to the identity, resets the tick back to the start, and restarts
the Move/Rotate cycle from the `x`-phase — a clean start on the new
object, never carrying over the previous one's rotation or tick
position. Update any on-screen label showing which oscillator and
tick/phase is currently active.

There is no other interaction. No camera controls, no editing, no
file loading — the whole page is meant to be watched, not operated.

## What makes a 4D oscillator worth embedding here

- Found from a **cold start** and confirmed to have an **exact,
  minimal period** by direct re-simulation (check it doesn't return to
  its starting state any earlier than the claimed period).
- **Genuinely 4D, not secretly 3D**: the rank of the pooled trajectory
  (every particle, every tick of one period, as 4D points relative to
  their own centroid) must be exactly 4 — check with an exact-integer
  rank computation (e.g. integer Gaussian elimination), not a
  floating-point approximation. A pattern whose rank comes out as 3 is
  a 3D pattern that merely happens to be sitting in 4D coordinates.
- **No self-sufficient proper subset** and **every particle
  essential** — same checks as a 3D project: re-simulate every proper
  subset of the pattern's own particles in isolation and confirm none
  of them reproduces the full pattern's trajectory on their own, and
  confirm removing any single particle changes the result.
- Reasonably **asymmetric** extents across all four axes — reject
  anything where all four come out suspiciously close to the same
  size.
- Small particle counts (3 is often enough) tend to be found far
  faster via random cold-start search than larger ones — try the
  smallest counts first rather than assuming more particles makes a
  more interesting pattern.
