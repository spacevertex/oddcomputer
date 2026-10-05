# Build a 3D isometric viewer for integer particle oscillators

Build a single self-contained HTML page (inline CSS and JavaScript, no
build step, no external dependencies beyond an optional web font) that
loads and plays back discovered periodic patterns from a discrete 3D
particle rule, rendered as a rotatable isometric view. Canvas 2D for
rendering — no WebGL needed, the isometric projection is just
arithmetic. This is a **viewer**, not an editor: there is no placing,
composing, or saving particles by hand here, only loading and watching
a pattern that was already found and verified elsewhere.

Positions and velocities are exact integers at all times. No floats in
the physics, ever — only the camera/rendering math uses floating
point.

## The core rule

Every particle has a position `(x, y, z)` and velocity `(vx, vy, vz)`,
all integers. There is only one kind of particle — every particle
moves; there is no second, static "anchor" particle type here.

Every tick, for every particle `p`, independently:

1. Find its nearest other particle(s) by squared distance
   `(qx-px)^2 + (qy-py)^2 + (qz-pz)^2` (never take a square root for
   comparison — squared distance is exact and sufficient).
2. **Tie-break rule:** if more than one other particle is tied for the
   minimum squared distance, do not pick one arbitrarily. For every
   tied neighbor `q`, take `sign(qx-px)`, `sign(qy-py)`, `sign(qz-pz)`
   (each -1, 0, or +1) and **sum** these signs separately across every
   tied neighbor to get `sumX`, `sumY`, `sumZ`. The actual pull this
   tick is `dvx = sign(sumX)`, `dvy = sign(sumY)`, `dvz = sign(sumZ)`
   — the sign of the *combined* pull from every tied neighbor, not
   the pull from any single one of them. Pulls from different tied
   neighbors can cancel on one axis while still adding up on another.
3. Update velocity: `vx += dvx`, `vy += dvy`, `vz += dvz`.
4. Update position using the new velocity: `x += vx`, `y += vy`,
   `z += vz`.

This update is **simultaneous**: compute every particle's delta from
one consistent, unmutated snapshot of every position first, then apply
every update together afterward. A particle must never see another
particle's already-updated-this-tick position.

The patterns this page loads are periodic — their state returns
exactly to the starting state after some fixed number of ticks,
forever — which is only possible because every value involved stays an
exact integer throughout.

## Data and pattern files

A pattern file is a JSON object:

```json
{
  "nearest": [
    { "x": 0, "y": 0, "z": 0, "vx": 0, "vy": 0, "vz": 0 }
  ],
  "period": 36
}
```

`nearest` is the full particle list (position + velocity, all
integers); `period` is the exact minimal period that pattern is known
to have, used to size the complete trail and the tick counter.

Patterns live as individual files in a `3d_patterns/` folder next to
the page, indexed by a `3d_patterns/manifest.json` — a plain JSON
array of filenames in that same folder:

```json
["n3p6.json", "n5p36.json", "n5p86.json"]
```

Fetch the manifest on load, build a button (or similar small control)
per filename, and fetch + display a pattern's own file only once its
button is actually clicked, rather than loading every pattern's data
up front.

## The isometric projection

The camera sits conceptually out along the `(1,1,1)` direction,
looking back at the origin. At the baseline (no rotation applied yet),
a world point projects to screen coordinates as:

```
ix = (x - y) * cos(30deg)
iy = (x + y) * sin(30deg) - z
```

(screen X grows right, screen Y grows down, as usual for a canvas).
One convenient property of this exact split: a one-unit step along X,
Y, or Z moves the projected point by the *same* screen distance in
every case, since `cos(30)^2 + sin(30)^2 = 1`.

### Rotation: an orbit camera, not a fixed matrix

The camera can be freely rotated by the user with `w`/`a`/`s`/`d`, and
it should behave the way a real orbit camera does — rotating *relative
to however you're currently looking*, not around fixed world axes.
Represent the camera's orientation as three orthonormal unit vectors —
`camRight`, `camUp`, `camForward` — rather than a single rotation
matrix tied to world axes. At the baseline (reproducing the plain
formula above exactly):

```
camRight   = normalize(1, -1, 0)
camUp      = normalize(-1, -1, 2)
camForward = normalize(1, 1, 1)
```

Project any world point `P` as:

```
K = sqrt(6) / 2
ix = K * dot(P, camRight)
iy = -K * dot(P, camUp)
```

(Verify this numerically against the plain formula above before
relying on it — it should match to floating-point precision for any
test point at the baseline orientation.)

- `a` / `d` **yaw**: rotate both `camRight` and `camForward` around
  the camera's own *current* `camUp` (which itself stays fixed, since
  you're rotating around it), using an axis-angle rotation (Rodrigues'
  rotation formula) by a fixed small step (e.g. 15 degrees) per press.
- `w` / `s` **tilt**: rotate both `camUp` and `camForward` around the
  camera's own *current* `camRight` (which stays fixed), by the same
  step size.
- A "Reset view" control resets all three vectors back to the
  baseline values above.
- Re-orthonormalize (re-derive `camForward` as the cross product of
  the other two, re-normalize all three) after rotating, to prevent
  tiny floating-point drift from accumulating over many rotations.

**Depth**, used for both the occlusion rule and the size/alpha cue
below, is `dot(P, camForward)` — larger means closer to the camera.
Recompute it against the *current* `camForward` each time; it is not a
fixed property of a point the way position is.

## Rendering a frame

- Each particle draws as a glowing circle. Diameter and opacity both
  interpolate between a minimum and maximum based on normalized depth
  (closer particles are bigger and more opaque, farther ones smaller
  and more translucent). Compute the depth range once, at the
  baseline orientation, when a pattern is first loaded — accept that
  this range is only approximate at other rotations (a minor,
  acceptable cosmetic softening of the cue, not a correctness bug).
- For performance, pre-render one glow sprite per distinct particle
  color on an offscreen canvas (radial gradient), and reuse the cached
  sprite instead of recomputing an expensive blur effect for every
  particle on every frame.
- **Occlusion**: sort nothing globally; instead, for every pair of
  particles `(A, B)`, `A` hides `B` only if *all* of the following
  hold: `B` is strictly closer than `A` is... no — reverse: a
  **strictly closer** particle hides a **farther** one. Precisely: for
  each ordered pair `(A, B)` where `B`'s depth is strictly greater
  than `A`'s depth (B is closer), check whether `A` and `B` are
  coincident (exactly equal `x`, `y`, *and* `z` — the true 3D
  position, not just equal screen position); if they are exactly
  coincident, skip this pair entirely (neither hides the other — two
  particles truly on top of each other both render normally, rather
  than flickering based on an arbitrary depth tie-break). Otherwise,
  compare their on-screen circles: if the squared screen distance
  between their centers is less than the squared sum of their current
  radii (compare squared values — never take a square root here
  either), `A` is hidden behind `B`.
- **Trails**: when enabled, draw each particle's *complete* path for
  the pattern's whole known period, every frame — not accumulated
  tick by tick. Since the pattern is periodic and its full trajectory
  is already known in advance, there's no reason to only reveal the
  portion played so far.
- **Vectors**: when enabled, draw a plain line segment (no arrowhead)
  from each particle's current position to `position + velocity`, in
  that particle's own color.
- Particle colors: assign each particle a distinct, readable color
  from a palette with enough contrast for at least 7-9 particles to
  stay visually distinguishable at once; fall back to generated,
  evenly spread hues for any pattern with more particles than the
  fixed palette covers.

### Scale: fixed by default, sized for the worst case across any rotation

By default, the projection scale is computed **once**, when a pattern
is loaded, and stays constant while the camera rotates — the object
should not appear to grow or shrink as it's turned.

Size it using this fact: an orthogonal projection can only ever
*shrink* a distance, never grow it, regardless of orientation. So the
pattern's own **bounding-sphere radius** — the maximum distance from
its center, across every tick of its full period — bounds how far any
point can ever appear from the screen center, at *any* possible camera
rotation whatsoever. Multiply that radius by the same `K = sqrt(6)/2`
constant used in the projection above (the raw 3D distance alone is
not the right bound — the projection's own scale factor has to be
folded in, or the result under-sizes the object and it can clip the
canvas at some rotations; verify this numerically, e.g. by sampling
many random rotations and confirming the projected distance never
exceeds `K * radius`, before trusting the formula). Leave a small
margin for the canvas edge and for the particle dot's own radius at
its largest rendered size.

Provide a **"Zoom to fit" toggle**, off by default. When switched on,
instead recompute the scale continuously, fit tightly to the *current*
rotation's actual on-screen bounding box (project every point through
the live camera, find the tightest box, solve for the scale and
centering offset that fills the canvas with it) — the object's
apparent size will then change as it's rotated, trading a constant
size for making full use of the canvas at every angle.

### The orientation gizmo

A small cube sits fixed in a corner of the canvas (constant screen
position and size, independent of the pattern's own scale), rotating
in sync with the camera so it always honestly shows which way is
`+x`/`+y`/`+z` from the current viewing angle.

- One corner of the cube sits at the local origin; the cube extends
  into the positive octant from there.
- The 6 faces are drawn as translucent fills (a pale, muted color,
  roughly 20% alpha), sorted back-to-front by the same depth rule as
  the particles so nearer faces correctly paint over farther ones.
- Of the cube's 12 edges, the 3 that meet at the origin corner — one
  running along each of the local `+x`, `+y`, `+z` directions — are
  drawn brighter (roughly 95% alpha) and extended slightly *past* the
  cube's own edge length (about 1.35x), each labeled with a small text
  letter (`x`, `y`, `z`) near its tip. The other 9 ordinary edges are
  drawn dimmer (roughly 50% alpha). None of the edges have arrowheads,
  matching the plain velocity-vector convention above.
- This needs its own fixed projection scale and screen anchor,
  separate from the main pattern's (the gizmo never changes size or
  position, regardless of what the pattern is doing).

## Controls panel

- A pattern picker (built from the manifest, see above).
- **Play** / **Step**, at a steady fixed tick rate while playing
  (redraw only when a tick actually occurred or the camera actually
  moved — don't repaint an unchanged frame).
- **Trails** and **Vectors** toggles.
- **Reset view**.
- **Zoom to fit** toggle (see above; off by default).
- A small legend/table showing each particle's color, and a tick
  counter displayed as 1-indexed (showing "1" through the pattern's
  period, not "0" through period-minus-one).

## What makes a pattern worth including

When searching for or curating patterns to add to `3d_patterns/`, a
genuinely good one should satisfy all of:

- Found from a **cold start** (every particle's velocity begins at
  zero) and settles into an **exact, minimal period** — confirm by
  re-simulating from the stored initial state and checking it returns
  to that exact state only at the claimed period, never earlier.
- **Genuinely 3D**: the full pooled trajectory (every particle, every
  tick of one period) should not lie flat in any 2D plane — check this
  with an exact-integer coplanarity test (e.g. via integer
  cross-products), not a floating-point approximation.
- **No self-sufficient proper subset**: no smaller group of the
  pattern's own particles would behave identically if simulated
  entirely on their own, without the rest of the pattern present.
  Check by directly re-simulating every proper subset in isolation and
  comparing its trajectory, tick by tick, against what that same
  subset does inside the full pattern.
- **No degenerate subgroup**: no subset of 4 or more particles has a
  pooled trajectory that's secretly coplanar, and no subset's distinct
  positions collapse to fewer unique points than particles involved
  (particles swapping places rather than genuinely orbiting).
- **Every particle essential**: removing any single particle and
  re-simulating the rest should fail to reproduce the original
  trajectory (confirms nothing in the pattern is just along for the
  ride).
- Reasonably **asymmetric** extents across its three axes — a pattern
  with a suspiciously similar spread on every axis is less visually
  interesting than one with real variation.

Smaller particle counts (3-5) are often dramatically easier to find
via random cold-start search than larger ones — don't assume more
particles makes a more interesting pattern, and don't over-invest
search time in a larger count before trying a smaller one.
