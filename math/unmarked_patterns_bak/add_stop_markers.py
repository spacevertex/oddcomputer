#!/usr/bin/env python3
"""
add_stop_markers.py — mark an oscillator's connection points.

Runs a bobo.html pattern file with exactly the page's physics (tied-nearest
sign rule, simultaneous update, markers ignored), watches one full period,
and adds an X marker where a nearest particle comes to a dead stop
(velocity 0,0) at the outer extent of the figure: only stops that touch the
figure's bounding box (leftmost, rightmost, lowest or highest point reached
by any particle over the period) are kept. Those are the connection points
on the fringe of the shape; stops inside the figure are left out.

Usage:
  python3 add_stop_markers.py pattern.json              writes pattern_markers.json
  python3 add_stop_markers.py pattern.json -o out.json  choose the output name
  python3 add_stop_markers.py pattern.json -i           overwrite the file
  python3 add_stop_markers.py pattern.json --all        keep inner stops too
  python3 add_stop_markers.py pattern.json --turns      also count points where
                                                        just one direction (x or y)
                                                        reverses
  python3 add_stop_markers.py *.json                    several files at once

Galleries of separate oscillators may never line up into one exact repeat
in a reasonable time; if the pattern stays in place, the stops seen over a
long run are used instead. Ships and runaways are skipped.

Markers already in the file are kept; duplicates are dropped. Everything
else in the file (nearest, bobo, period, name, ...) is left exactly as it was.
"""
import argparse
import json
import os
import sys

MAX_TICKS = 20000  # longest the script will wait for the pattern to repeat


def sign(n):
    return (n > 0) - (n < 0)


def step(nearest, bobo):
    """One tick, same rule as bobo.html: every nearest particle finds all
    neighbours tied for closest (other nearest particles and bobos; markers
    never count), sums their sign(dx), sign(dy), takes the sign of each sum
    as its acceleration. All deltas come from the old positions, then all
    are applied together."""
    others = [(p[0], p[1]) for p in nearest] + bobo
    n = len(nearest)
    acc = []
    for i, (x, y, _, _) in enumerate(nearest):
        best, sx, sy = None, 0, 0
        for j, (qx, qy) in enumerate(others):
            if j == i:
                continue
            dx, dy = qx - x, qy - y
            d2 = dx * dx + dy * dy
            if best is None or d2 < best:
                best, sx, sy = d2, sign(dx), sign(dy)
            elif d2 == best:
                sx += sign(dx)
                sy += sign(dy)
        acc.append((sign(sx), sign(sy)) if best is not None else (0, 0))
    out = []
    for (x, y, vx, vy), (ax, ay) in zip(nearest, acc):
        vx += ax
        vy += ay
        out.append((x + vx, y + vy, vx, vy))
    return out


def find_points(data, turns=False, keep_inner=False):
    nearest = [(p['x'], p['y'], p.get('vx', 0), p.get('vy', 0)) for p in data.get('nearest', [])]
    bobo = [(p['x'], p['y']) for p in data.get('bobo', [])]
    if not nearest:
        return None, 'no nearest particles in the file'

    # run until the whole state repeats: that's one exact period
    seen = {}
    history = []
    state = nearest
    for t in range(MAX_TICKS + 1):
        key = tuple(state)
        if key in seen:
            start = seen[key]
            break
        seen[key] = t
        history.append(state)
        state = step(state, bobo)
    else:
        # no exact repeat. A gallery of separate oscillators can take a very
        # long time to line up all at once; if everything stayed in place,
        # use every stop seen during the run. Anything that wandered off
        # (a ship or a runaway) is skipped instead.
        xs = [p[0] for p in nearest] + [b[0] for b in bobo]
        ys = [p[1] for p in nearest] + [b[1] for b in bobo]
        span = max(max(xs) - min(xs), max(ys) - min(ys), 10)
        lo_x, hi_x = min(xs) - 2 * span, max(xs) + 2 * span
        lo_y, hi_y = min(ys) - 2 * span, max(ys) + 2 * span
        if any(not (lo_x <= x <= hi_x and lo_y <= y <= hi_y) for st in history for (x, y, _, _) in st):
            return None, f'did not repeat within {MAX_TICKS} ticks and moves away (a ship, or not an oscillator)'
        start, period = None, None

    cycle = history[start:] if start is not None else history
    if start is not None:
        period = len(cycle)           # one full period, each state exactly once
    points = set()
    for t, st in enumerate(cycle):
        if t == 0 and period is None:
            prev = st                 # open run: nothing before the first tick
        else:
            prev = cycle[t - 1]       # a closed cycle wraps around
        for (x, y, vx, vy), (_, _, pvx, pvy) in zip(st, prev):
            if vx == 0 and vy == 0:
                points.add((x, y))
            elif turns:
                # a single axis reversing: its velocity changes sign, or
                # reaches zero after moving (the stop tick of that axis)
                if (vx == 0 and pvx != 0) or sign(vx) * sign(pvx) < 0:
                    points.add((x, y))
                if (vy == 0 and pvy != 0) or sign(vy) * sign(pvy) < 0:
                    points.add((x, y))
    # the figure's extent: every position any nearest particle reaches
    xs = [x for st in cycle for (x, _, _, _) in st]
    ys = [y for st in cycle for (_, y, _, _) in st]
    box = (min(xs), max(xs), min(ys), max(ys))
    inner = 0
    if not keep_inner:
        edge = {p for p in points if p[0] in (box[0], box[1]) or p[1] in (box[2], box[3])}
        inner = len(points) - len(edge)
        points = edge
    return {'period': period, 'start': start, 'points': sorted(points), 'inner': inner, 'box': box}, None


def main():
    ap = argparse.ArgumentParser(description='Add X markers at an oscillator\'s stopping points.')
    ap.add_argument('files', nargs='+', help='pattern .json file(s)')
    ap.add_argument('-o', '--output', help='output file (only with a single input file)')
    ap.add_argument('-i', dest='in_place', action='store_true', help='overwrite the input file(s)')
    ap.add_argument('--all', action='store_true', help='keep stops inside the figure, not just at its extent')
    ap.add_argument('--turns', action='store_true', help='also mark single-direction reversals')
    args = ap.parse_args()
    if args.output and len(args.files) > 1:
        ap.error('-o works with one input file; use -i or the default names for several')

    failed = 0
    for path in args.files:
        try:
            with open(path) as f:
                data = json.load(f)
        except (OSError, json.JSONDecodeError) as e:
            print(f'{path}: could not read ({e})', file=sys.stderr)
            failed += 1
            continue
        res, err = find_points(data, args.turns, args.all)
        if err:
            print(f'{path}: skipped, {err}', file=sys.stderr)
            failed += 1
            continue

        existing = data.get('marker') if isinstance(data.get('marker'), list) else []
        have = {(m['x'], m['y']) for m in existing}
        added = [p for p in res['points'] if p not in have]
        data['marker'] = existing + [{'x': x, 'y': y} for x, y in added]

        if args.in_place:
            out = path
        elif args.output:
            out = args.output
        else:
            root, ext = os.path.splitext(path)
            out = root + '_markers' + (ext or '.json')
        with open(out, 'w') as f:
            json.dump(data, f, indent=2)
            f.write('\n')

        if res['period'] is None:
            head = f'no exact repeat within {MAX_TICKS} ticks but it stays in place, so using every stop seen'
        else:
            head = f'period {res["period"]}' + (f', settles into its cycle after {res["start"]} ticks' if res['start'] else '')
        kind = ('stop/turn points' if args.turns else 'stop points') + ('' if args.all else ' at the extent')
        x0, x1, y0, y1 = res['box']
        head += f'; extent x {x0}..{x1}, y {y0}..{y1}'
        if res['inner']:
            head += f'; {res["inner"]} inner one(s) left out'
        if not res['points']:
            hint = '' if args.turns else ' (try --turns to mark single-direction reversals)'
            print(f'{path}: {head}; no {kind} found{hint}; wrote {out} unchanged')
        else:
            print(f'{path}: {head}; {len(res["points"])} {kind}, '
                  f'{len(added)} new marker(s) -> {out}')
    sys.exit(1 if failed else 0)


if __name__ == '__main__':
    main()
