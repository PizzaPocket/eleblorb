"""Walkway geometry shared by the Fire Caldera's surface network and the Heartworks.

One rule makes every junction clean. Each *level* is a single walkable surface at one datum: the union of
everything that stands at that height (a ring, a dock's porch, a landing, a forecourt). Building walls are
cut out of it. Its guard runs along the union's outline, except where the outline is a wall, a deliberately
open edge (the lava promenade's kerb) or the *mouth* of a flight.

A *flight* (a ramp or a stair) joins two levels. It starts and ends with a short level landing that belongs
to its level's union, so the level's outline turns along the landing's sides and stops at a straight mouth
exactly as wide as the flight. The flight's own guards start at the mouth's corners. Parent and child
therefore share one floor plane at every joint and one continuous guard line, with no seam to fit by hand.

Concave corners of a level are filleted (a closing by FILLET); convex corners stay sharp, so mouths stay
square to their flights. The checks below fail a plan whose guards do not meet end to end, whose flights do
not start and end flush with their levels, or whose slopes are too steep.
"""
import math
from shapely.geometry import Polygon, LineString, Point, MultiLineString, MultiPolygon, GeometryCollection
from shapely.ops import unary_union, linemerge
from shapely.geometry.polygon import orient

FILLET = 1.0          # concave corners of a level's outline
GUARD = 1.09          # top of every handrail above the walking surface
EPS = 0.01            # coincidence tolerance for guard ends, metres (checked at 5x)
KERB_DROP = 1.0       # an edge with less than this drop beside it takes a kerb, not a guard


def superellipse(cx, cy, hx, hy, exponent=10.0, turn=0.0, n=120):
    """A superellipse outline: half sizes along its own axes, its +x axis turned by `turn` radians."""
    pts = []
    c, s = math.cos(turn), math.sin(turn)
    for i in range(n):
        t = 2 * math.pi * i / n
        ct, st = math.cos(t), math.sin(t)
        u = math.copysign(abs(ct) ** (2 / exponent), ct) * hx
        v = math.copysign(abs(st) ** (2 / exponent), st) * hy
        pts.append((cx + u * c - v * s, cy + u * s + v * c))
    return Polygon(pts)


def circle_pts(r, b0, b1, n=None, cx=0.0, cy=0.0):
    n = n or max(4, int(abs(b1 - b0) / 2.0))
    return [(cx + r * math.cos(math.radians(b0 + (b1 - b0) * i / n)), cy + r * math.sin(math.radians(b0 + (b1 - b0) * i / n))) for i in range(n + 1)]


def annulus(r0, r1, n=360):
    return Polygon(circle_pts(r1, 0, 360, n)[:-1], [circle_pts(r0, 0, 360, n)[:-1]])


def dedupe(pts, tol=1e-4):
    out = []
    for q in pts:
        q = tuple(q)
        if not out or math.dist(out[-1], q) > tol: out.append(q)
    return out


def band(pts, width):
    """A flat-ended band of a given width along a centreline."""
    return LineString(dedupe(pts)).buffer(width / 2, cap_style=2, join_style=2, mitre_limit=3.0)


def polys(g):
    if g.is_empty: return []
    if isinstance(g, Polygon): return [g]
    return [p for p in getattr(g, 'geoms', []) if isinstance(p, Polygon)]


def lines(g):
    if g.is_empty: return []
    if isinstance(g, LineString): return [g]
    out = []
    for p in getattr(g, 'geoms', []):
        out += lines(p)
    return out


def cut_line(line, s0, s1):
    """The part of a LineString between arclengths s0 and s1."""
    from shapely.ops import substring
    return substring(line, s0, s1)


class Flight:
    """A ramp or stair between two levels along a plan centreline.

    landing = (top, bottom) lengths of level landing at each end, part of each level's union.
    guards: 'both', 'outer' (only the side to the right of travel... chosen by `outer_side`), or 'none'.
    kind: 'ramp', 'stair' or 'spiral' (a stair round a newel; only its outer side is guarded).
    """
    def __init__(self, id, upper, lower, centre, width, kind='ramp', landing=(1.5, 1.5), guards='both', outer_side=None, material='glass', note=''):
        self.id, self.upper, self.lower, self.width, self.kind = id, upper, lower, width, kind
        self.line = LineString(dedupe(centre))
        self.landing, self.guards, self.outer_side, self.material, self.note = landing, guards, outer_side, material, note
        L = self.line.length
        self.slope = LineString(dedupe(cut_line(self.line, landing[0], L - landing[1]).coords))
        self.top_landing = band(list(cut_line(self.line, 0, landing[0]).coords), width) if landing[0] > 0 else None
        self.bottom_landing = band(list(cut_line(self.line, L - landing[1], L).coords), width) if landing[1] > 0 else None

    def mouth(self, end, sign):
        """A corner of a mouth, square to the landing it ends (end 0 the top, 1 the bottom)."""
        L = self.line.length
        s = self.landing[0] if end == 0 else L - self.landing[1]
        a = self.line.interpolate(max(0.0, s - 0.05) if end == 0 else s)
        b = self.line.interpolate(s if end == 0 else min(L, s + 0.05))
        if a.distance(b) < 1e-6:   # no landing on that side: use the slope's own direction
            a, b = self.line.interpolate(s), self.line.interpolate(s + (0.05 if end == 0 else -0.05))
            if end == 1: a, b = b, a
        tx, ty = b.x - a.x, b.y - a.y; n = math.hypot(tx, ty) or 1
        p = self.line.interpolate(s)
        return (p.x - ty / n * self.width / 2 * sign, p.y + tx / n * self.width / 2 * sign)

    def side(self, sign):
        """The slope's edge on one side (+1 left of travel, -1 right), as a list of plan points."""
        pts = []
        for q in self.slope.coords:
            if not pts or math.dist(pts[-1], q) > 1e-4: pts.append(q)
        out = []
        for i, p in enumerate(pts):
            a, b = pts[max(0, i - 1)], pts[min(len(pts) - 1, i + 1)]
            tx, ty = b[0] - a[0], b[1] - a[1]; n = math.hypot(tx, ty) or 1
            out.append((p[0] - ty / n * self.width / 2 * sign, p[1] + tx / n * self.width / 2 * sign))
        out[0], out[-1] = self.mouth(0, sign), self.mouth(1, sign)
        return out

    def height(self, s, top, bottom):
        """Walking height at arclength s along the whole flight (landings level, slope straight)."""
        L = self.line.length; a, b = self.landing[0], L - self.landing[1]
        if s <= a: return top
        if s >= b: return bottom
        return top + (bottom - top) * (s - a) / (b - a)

    def grade(self, top, bottom):
        return abs(top - bottom) / max(self.slope.length, 1e-6)


class Network:
    def __init__(self, name):
        self.name = name
        self.levels = {}      # id -> dict(datum, material, pieces, walls, open, note)
        self.flights = []
        self.fails = []
        self.notes = []
        self.below = None     # (x, y, level) -> the height of whatever lies under a level's edge

    def level(self, id, datum, material='glass', note=''):
        self.levels[id] = dict(id=id, datum=datum, material=material, pieces=[], walls=[], open=[], note=note, tags=[])
        return self.levels[id]

    def add(self, level, geom, tag=''):
        self.levels[level]['pieces'].append(geom)
        if tag: self.levels[level]['tags'].append((tag, geom))

    def wall(self, level, geom):
        self.levels[level]['walls'].append(geom)

    def open_edge(self, level, geom):
        self.levels[level]['open'].append(geom)

    def flight(self, f):
        self.flights.append(f)
        if f.top_landing is not None: self.add(f.upper, f.top_landing)
        if f.bottom_landing is not None: self.add(f.lower, f.bottom_landing)
        return f

    def fail(self, m): self.fails.append(m)

    # ------------------------------------------------------------ solve
    def solve(self):
        for lv in self.levels.values():
            surf = unary_union(lv['pieces'])
            surf = surf.buffer(FILLET, join_style=1).buffer(-FILLET, join_style=1)
            walls = unary_union(lv['walls']) if lv['walls'] else None
            if walls is not None: surf = surf.difference(walls)
            # only the head of a flight is kept clear of its upper level (a fillet must never roof a slope);
            # a flight that descends onto the middle of a level stands on it, its spandrel closed below 2.1 m
            slopes = [band(list(cut_line(f.slope, 0, min(2.0, f.slope.length)).coords), f.width) for f in self.flights if lv['id'] == f.upper]
            if slopes: surf = surf.difference(unary_union(slopes).buffer(-0.01))
            lv['surface'] = surf
            edge = surf.boundary
            # no guard along a wall, an open edge or a flight's mouth
            if walls is not None: edge = edge.difference(walls.buffer(0.05))
            for o in lv['open']: edge = edge.difference(o.buffer(0.05))
            for f in self.flights:
                L = f.slope.length
                for lid, part in ((f.upper, (0, min(0.3, L))), (f.lower, (max(0, L - 0.3), L))):
                    if lid != lv['id']: continue
                    end = 0 if lid == f.upper and part[0] == 0 else 1
                    cap = LineString([f.mouth(end, 1), f.mouth(end, -1)]).buffer(0.03, cap_style=2)
                    mouth = band(list(cut_line(f.slope, *part).coords), f.width).buffer(0.02, join_style=2).union(cap)
                    edge = edge.difference(mouth)
            # a kerb, not a guard, where the drop beside the edge is under KERB_DROP
            if self.below is not None:
                kept = []
                for g in lines(linemerge(lines(edge)) if lines(edge) else edge):
                    run, runs = [], []
                    n = max(2, int(g.length / 0.25))
                    for k in range(n + 1):
                        p = g.interpolate(g.length * k / n)
                        guarded = lv['datum'] - self.below(p.x, p.y, lv) >= KERB_DROP
                        if guarded: run.append((p.x, p.y))
                        elif run: runs.append(run); run = []
                    if run: runs.append(run)
                    for r in runs:
                        if len(r) >= 2:
                            kept.append(LineString(r))
                            for q in (r[0], r[-1]):
                                if Point(q).distance(g.boundary) > 0.01 or g.is_ring: lv['open'].append(Point(q))
                edge = MultiLineString(kept) if kept else LineString()
            merged = linemerge(lines(edge)) if lines(edge) else edge
            lv['guards'] = [g for g in lines(merged) if g.length > 0.05]
        for f in self.flights:
            sides = []
            if f.guards == 'both': sides = [1, -1]
            elif f.guards == 'outer': sides = [f.outer_side]
            f.guard_lines = [f.side(s) for s in sides]

    # ------------------------------------------------------------ checks
    def check(self, max_grade=None, stair_grade=0.70):
        ends = []   # (point, level datum or flight id, owner)
        for lv in self.levels.values():
            for g in lv['guards']:
                if g.is_ring: continue
                for p in (g.coords[0], g.coords[-1]): ends.append((p, lv['datum'], 'level ' + lv['id']))
        for f in self.flights:
            top, bottom = self.levels[f.upper]['datum'], self.levels[f.lower]['datum']
            if f.guards == 'outer':      # the newel side: its corners are a legitimate end for the level's guard
                inner = f.side(-f.outer_side)
                self.levels[f.upper]['open'].append(Point(inner[0])); self.levels[f.lower]['open'].append(Point(inner[-1]))
            for side in f.guard_lines:
                ends.append((side[0], top, 'flight ' + f.id))
                ends.append((side[-1], bottom, 'flight ' + f.id))
        walls = {lid: unary_union(lv['walls']) for lid, lv in self.levels.items() if lv['walls']}
        opens = {lid: unary_union(lv['open']) for lid, lv in self.levels.items() if lv['open']}
        bad = 0
        for i, (p, y, who) in enumerate(ends):
            mate = any(j != i and abs(q[0] - p[0]) < EPS * 5 and abs(q[1] - p[1]) < EPS * 5 and abs(yy - y) < 0.01 for j, (q, yy, _) in enumerate(ends))
            if mate: continue
            ok = False
            for lid, lv in self.levels.items():
                if abs(lv['datum'] - y) > 0.01: continue
                if lid in walls and walls[lid].distance(Point(p)) < 0.06: ok = True
                if lid in opens and opens[lid].distance(Point(p)) < 0.1: ok = True
                # a flight that lands inside a level (not on its edge) ends its guards in the open floor
                if lv['surface'].buffer(-0.02).contains(Point(p)): ok = True
            if not ok:
                bad += 1
                if bad <= 8: self.fail('%s: a guard ends in mid-air at (%.2f, %.2f), height %.2f' % (self.name, p[0], p[1], y))
        for f in self.flights:
            up, lo = self.levels[f.upper], self.levels[f.lower]
            g = f.grade(up['datum'], lo['datum'])
            limit = stair_grade if f.kind in ('stair', 'spiral') else max_grade
            if limit and g > limit + 1e-6: self.fail('%s: %s %s is %.0f%% steep' % (self.name, f.kind, f.id, g * 100))
            sl = band(list(cut_line(f.slope, 0, min(2.0, f.slope.length)).coords), f.width).buffer(-0.05)
            for lv in (up,):
                if lv['surface'].intersection(sl).area > 0.2: self.fail('%s: %s\'s level surface covers part of %s\'s slope' % (self.name, lv['id'], f.id))
            # flush joints: each landing lies within its level's surface, the mouth on its outline or inside it
            for land, lv in ((f.top_landing, up), (f.bottom_landing, lo)):
                if land is None: continue
                if land.difference(lv['surface'].buffer(0.05)).area > 0.05:
                    self.fail('%s: %s\'s landing is not part of %s' % (self.name, f.id, lv['id']))
        return not self.fails

    # ------------------------------------------------------------ out
    def data(self):
        def ring(c): return [[round(x, 3), round(y, 3)] for x, y in c]
        out = dict(levels=[], flights=[])
        for lv in self.levels.values():
            out['levels'].append(dict(id=lv['id'], datum=lv['datum'], material=lv['material'], note=lv['note'],
                                      surface=[dict(outer=ring(q.exterior.coords), holes=[ring(h.coords) for h in q.interiors]) for q in (orient(p.simplify(0.02)) for p in polys(lv['surface']) if p.area > 0.5) if not q.is_empty],
                                      guards=[ring(g.coords) for g in lv['guards']]))
        for f in self.flights:
            top, bottom = self.levels[f.upper]['datum'], self.levels[f.lower]['datum']
            L = f.line.length; n = max(8, int(L / 0.5))
            prof = []
            for i in range(n + 1):
                s = L * i / n; p = f.line.interpolate(s); prof.append([round(p.x, 3), round(f.height(s, top, bottom), 3), round(p.y, 3)])
            def lift(side):
                sl = LineString(side); m = max(2, int(sl.length / 0.5)); res = []
                for k in range(m + 1):
                    p = sl.interpolate(sl.length * k / m)
                    s = f.line.project(p)
                    res.append([round(p.x, 3), round(f.height(s, top, bottom) + GUARD, 3), round(p.y, 3)])
                return res
            out['flights'].append(dict(id=f.id, kind=f.kind, upper=f.upper, lower=f.lower, width=f.width, material=f.material, note=f.note,
                                       profile=prof, guards=[lift(s) for s in f.guard_lines], grade=round(f.grade(top, bottom), 4), length=round(L, 2)))
        return out
