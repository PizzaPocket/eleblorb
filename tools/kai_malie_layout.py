"""Authoring tool for Kai Mālie's plan (docs/architecture/ocean_island_village_layout.md
and ocean_island_village_buildings.md). It holds the island's zones, the green,
the paths and every building with its walls, lānai, eaves and room program,
checks them, and writes scripts/kai_malie_plan.gd, the one plan the village
builder and tools/validate_kai_malie_plan.tscn read.

    python3 tools/kai_malie_layout.py [--json out.json]

Edit here, never in kai_malie_plan.gd. Local metres on the main island:
u points from the island's centre toward the arrival dock, v to its right;
(0, 0) is the island centre at world (-118, 72). Heights are metres above sea
level. Sizes are world scale (about 1.1 x real, docs/world_bible.md).
"""
import json, math, os, sys

CENTER = (-118.0, 72.0)
U = (0.854, -0.521)
V = (0.521, 0.854)
def world(u, v): return (round(CENTER[0] + u * U[0] + v * V[0], 2), round(CENTER[1] + u * U[1] + v * V[1], 2))

## Zones (layout 3 and 4), as control points in local (u, v) metres, smoothed
## into curves: the shore is a bay between two lava headlands, never a box.
def catmull(pts, closed, n=6):
    out = []; m = len(pts)
    rng = range(m) if closed else range(m - 1)
    for i in rng:
        p0 = pts[(i - 1) % m] if closed or i > 0 else pts[0]
        p1 = pts[i]; p2 = pts[(i + 1) % m]
        p3 = pts[(i + 2) % m] if closed or i + 2 < m else pts[-1]
        for k in range(n):
            t = k / n; t2 = t * t; t3 = t2 * t
            out.append(tuple(round(0.5 * ((2 * p1[j]) + (-p0[j] + p2[j]) * t + (2 * p0[j] - 5 * p1[j] + 4 * p2[j] - p3[j]) * t2 + (-p0[j] + 3 * p1[j] - 3 * p2[j] + p3[j]) * t3), 2) for j in (0, 1)))
    if not closed: out.append(tuple(pts[-1]))
    return out
## the top of the beach (the plain's seaward edge), from the east headland to the west
BEACH_TOP = [(77, 58), (72, 48), (69.5, 36), (68.6, 22), (68.2, 8), (68.2, -8), (68.8, -22), (70.4, -36), (74, -48), (80, -58)]
## the waterline at mean tide
WATERLINE = [(84, 60), (79.5, 48), (76.5, 36), (75.4, 22), (74.8, 8), (74.8, -8), (75.4, -22), (77.4, -36), (81, -48), (88, -60)]
## the foot of the valley walls and ridges round the plain, west to east
PLAIN_FOOT = [(52, -60), (42, -52), (37.5, -40), (35.5, -24), (34.8, -8), (35.2, 8), (36.6, 22), (40, 36), (47, 50), (56, 58)]
PLAIN = catmull(PLAIN_FOOT + BEACH_TOP, True)
BEACH = catmull(BEACH_TOP + list(reversed(WATERLINE)), True)
SHORE = catmull(PLAIN_FOOT + WATERLINE[::-1][::-1] if False else PLAIN_FOOT + list(WATERLINE), True)
REEF_EDGE = [(88, -60), (100, -65), (116, -61), (127, -53), (134, -38), (131, -20), (137, -6), (135, 10), (130, 26), (121, 40), (107, 47), (92, 51), (84, 60)]
REEF_FLAT = catmull(list(WATERLINE) + REEF_EDGE[1:-1], True)
HEADLANDS = [catmull([(68, -58), (80, -57), (92, -61), (97, -67), (86, -72), (70, -66)], True),
             catmull([(72, 57), (83, 56), (94, 61), (97, 68), (84, 72), (70, 64)], True)]
## the loʻi kalo on the valley floor, nothing built on them; bund lines follow
## the contours, bowed upslope where the valley floor dips toward the stream
TERRACES = catmull([(37.0, -36), (30, -34.5), (22, -31), (15, -25), (12, -16), (14, -6), (20, 1.5), (28, 4.5), (35, 5), (37.2, -1), (37.4, -18)], True)
BUNDS = [catmull([(u + 0.6, -33), (u - 1.2, -24), (u, -14), (u + 1.0, -4), (u + 0.2, 4)], False, 4) for u in (18, 22, 26, 30, 34)]
## the stream: from the waterfall down the valley's south side, along the
## plain's western edge and into the fishpond's inland side
STREAM = catmull([(8, -18), (14, -30), (24, -38), (34, -44.5), (42, -52.5), (52, -56), (62, -56.5), (71, -53), (77, -48)], False)
STREAM_CLEAR = 3.0
GREEN = catmull([(48.6, -2), (49.4, -7.6), (53.6, -10.2), (58.6, -8.4), (60.4, -1.6), (59.8, 6.4), (55, 9.8), (50, 8.2)], True)
PIER_HEAD = catmull([(63, -4.6), (68.6, -5.4), (70.6, 0), (68.6, 5.4), (63, 4.6), (61.6, 0)], True)
PIER = (68.0, -1.8, 134.0, 1.8)         # 3.6 m wide, across the reef flat to the dock
FISHPOND_WALL = catmull([(75.6, -57), (88, -61), (101, -57), (106, -44), (104, -30), (93, -23), (76, -23.5)], False)
MEETING_ROCKS = (128.0, -42.0)
WATERFALL = (8.0, -18.0)
DOCK_U = 138.0
KAHALA_GARDEN = catmull([(31, 10), (36.5, 9), (37.6, 15), (34, 19.5), (30.4, 16)], True)
PIRATES_BEACH = (46.0, 58.0)            # the stretch of beach (v) beyond the canoe house
def plain_height(u): return round(3.0 + (1.2 - 3.0) * min(1.0, max(0.0, (u - 36.0) / 32.0)), 2)

## Each building turns a few degrees off the island's frame to face the green
## or the curve of its lane (positive from +u toward +v), as houses do on a
## real bay; within about 12 degrees, never a random scatter.
TURN = {'halau': 0, 'kahananui': -4, 'kealoha': 6, 'akana': 5, 'guest_house': 6, 'medeiros': 4, 'kahale': -6, 'nakamura': -5, 'varga': -7, 'canoe_house': -12}

## Room minimums at world scale (architecture skill 5): (short, long) side.
MIN_ROOM = {
    'bed2': (3.2, 3.4),    # a double: 1.7 x 2.45 frame, 0.6 m both sides, 0.9 m at the foot
    'bed1': (3.0, 3.2),    # a single: 1.0 x 2.45 frame
    'living': (3.2, 3.6),
    'kitchen': (2.8, 3.0),
    'bath': (1.4, 1.8),    # toilet, basin, shower
    'store': (1.6, 1.6),
    'work': (3.0, 3.0),
    'hall': (1.4, 1.4),
}

## Buildings. walls = (u0, v0, u1, v1); lanai = {side: depth}, side one of
## 'u+' (toward the sea), 'u-' (upslope), 'v+', 'v-'; front = the side the
## main lānai and door face. floors = list of rows per floor: each row is
## (depth along u, [(room, kind, width along v), ...]) from the upslope side.
B = []
def b(key, name, kind, walls, front, lanai, eaves, floors, who, extra=None):
    d = dict(key=key, name=name, kind=kind, walls=walls, front=front, lanai=lanai, eaves=eaves,
             floors=floors, who=who, turn=TURN[key])
    if extra: d.update(extra)
    B.append(d)

b('halau', 'Hālau', 'hale', (39.0, -8.0, 47.0, 8.0), 'u+', {}, 0.6,
  [[(8.0, [('hula floor', 'open', 16.0)])]],
  ['Puanani Akana (teaches)', 'the kūpuna (meet)'], {'paepae': 0.8, 'open_side': 'u+'})
b('kahananui', 'Kahananui home', 'home', (41.8, -26.4, 49.8, -16.8), 'v+', {'v+': 2.4, 'u-': 2.4}, 1.2,
  [[(4.0, [('kitchen', 'kitchen', 3.2), ('bath', 'bath', 2.0), ('Kawika and Malia', 'bed2', 4.4)]),
    (4.0, [('Keoni', 'bed1', 3.2), ('living room', 'living', 6.4)])]],
  ['Kawika Kahananui', 'Malia Kahananui', 'Keoni Kahananui'], {'work_lanai': 'u-'})
b('kealoha', 'Kealoha home', 'home', (41.0, -43.6, 49.0, -34.0), 'u+', {'u+': 2.4}, 1.2,
  [[(4.0, [('bath', 'bath', 2.4), ('Noelani', 'bed1', 3.2), ('Leilani and Makoa', 'bed2', 4.0)]),
    (4.0, [('kitchen', 'kitchen', 4.8), ('living room', 'living', 4.8)])]],
  ['Leilani Kealoha', 'Makoa Kealoha', 'Noelani Kealoha'], {'back_door': 'u-', 'net_store': 'u-'})
b('akana', 'Akana home', 'home', (57.3, -42.6, 63.7, -36.2), 'u+', {'u+': 2.4}, 1.2,
  [[(3.2, [('bedroom', 'bed2', 3.6), ('kitchen', 'kitchen', 2.8)]),
    (3.2, [('living room', 'living', 4.8), ('bath', 'bath', 1.6)])]],
  ['Puanani Akana'])
b('guest_house', 'Okafor guest house', 'rest', (56.7, -26.0, 64.7, -13.2), 'u+', {'u+': 2.4}, 1.2,
  [[(3.1, [('kitchen', 'kitchen', 5.2), ('ramp', 'ramp', 7.6)]),
    (4.9, [('Sam', 'bed1', 3.6), ('day toilet', 'bath', 1.6), ('common room', 'living', 7.6)])],
   [(1.4, [('bathroom', 'bath', 2.6), ('linen cupboard', 'cupboard', 2.6), ('ramp opening', 'ramp', 7.6)]),
    (1.7, [('landing corridor', 'hall', 12.8)]),
    (4.9, [('guest room', 'bed2', 3.6), ('guest room', 'bed2', 3.6), ('party room', 'bed2', 5.6)])]],
  ['Sam Okafor'], {'rest_point': True, 'price': 25, 'toilet': 'flush toilet and shower upstairs; toilet and basin by the common room',
                   'waste': 'septic tank behind the house, away from the stream and the reef'})
b('medeiros', 'Medeiros home and ukulele workshop', 'home', (39.2, 13.8, 45.6, 26.6), 'u+', {'u+': 2.4}, 1.2,
  [[(3.2, [('workshop', 'work', 4.8), ('bedroom', 'bed2', 4.0), ('bath', 'bath', 1.6), ('drying room', 'store', 2.4)]),
    (3.2, [('workshop', 'work', 4.8), ('living room', 'living', 4.8), ('kitchen', 'kitchen', 3.2)])]],
  ['Manny Medeiros', 'Kahala Medeiros'], {'plan': 'L: the workshop wing on the green side'})
b('kahale', 'Kahale home', 'home', (43.0, 33.0, 49.4, 41.0), 'u+', {'u+': 2.4}, 1.2,
  [[(3.2, [('Kahiau', 'bed1', 3.2), ('Iolana', 'bed1', 3.2), ('bath', 'bath', 1.6)]),
    (3.2, [('living room', 'living', 4.8), ('kitchen', 'kitchen', 3.2)])]],
  ['Kahiau Kahale', 'Iolana Kahale'])
b('nakamura', 'Nakamura store and home', 'shop', (55.4, 13.2, 63.4, 22.8), 'v-', {'v-': 2.4}, 1.2,
  [[(4.0, [('storeroom', 'store', 3.2), ('store', 'work', 6.4)]),
    (4.0, [('shave ice counter', 'work', 3.2), ('store', 'work', 6.4)])],
   [(4.0, [('bedroom', 'bed2', 4.0), ('bath', 'bath', 2.4), ('kitchen', 'kitchen', 3.2)]),
    (4.0, [('living room', 'living', 9.6)])]],
  ['Hiro Nakamura', 'Grace Nakamura'], {'shop_counter': 'v-', 'outside_ramp': 'u-'})
b('varga', 'Varga cottage', 'home', (57.5, 29.2, 62.3, 34.0), 'u+', {'u+': 2.0}, 1.2,
  [[(3.4, [('room', 'bed1', 4.8)]), (1.4, [('bath and wet bench', 'bath', 4.8)])]],
  ['Elena Varga'])
b('canoe_house', 'Canoe house', 'hale', (60.2, 39.4, 74.0, 45.8), 'u+', {}, 0.6,
  [[(13.8, [('canoes', 'open', 6.4)])]],
  ['Kahiau Kahale (keeps it)'], {'paepae': 0.3, 'open_side': 'u+'})

## Paths: (name, width, control points), smoothed into curves along desire lines.
PATHS = [(nm, wd, catmull(pts, False, 4)) for nm, wd, pts in [
    ('main path', 3.0, [(69.0, 0.0), (63.0, 0.6), (56.5, -0.4), (51.6, 0.3), (49.2, 0.0)]),
    ('green to the loʻi', 2.0, [(49.6, -6.5), (46.6, -10.6), (42.0, -11.6), (37.6, -10.8), (33.0, -9.6)]),
    ('beach path', 2.5, [(71.4, 35.4), (71.0, 30.0), (70.4, 16.0), (70.2, 0.0), (70.6, -16.0), (71.6, -30.0), (74.0, -42.0), (76.4, -50.0)]),
    ('west lane', 2.0, [(53.6, -10.0), (53.2, -18.0), (53.4, -28.0), (54.6, -36.0), (54.2, -44.5)]),
    ('east lane', 2.0, [(53.0, 10.0), (52.6, 18.0), (53.6, 28.0), (54.4, 36.0), (53.8, 43.0)]),
]]
RESIDENTS = ['Kawika Kahananui', 'Malia Kahananui', 'Keoni Kahananui', 'Leilani Kealoha', 'Makoa Kealoha',
             'Noelani Kealoha', 'Kahiau Kahale', 'Iolana Kahale', 'Puanani Akana', 'Hiro Nakamura',
             'Grace Nakamura', 'Manny Medeiros', 'Kahala Medeiros', 'Sam Okafor', 'Elena Varga']

# ---- geometry
import math
def rot(c, th, p):
    t = math.radians(th); du, dv = p[0] - c[0], p[1] - c[1]
    return (round(c[0] + du * math.cos(t) - dv * math.sin(t), 3), round(c[1] + du * math.sin(t) + dv * math.cos(t), 3))
SIDES = {'u+': (2, 1), 'u-': (0, -1), 'v+': (3, 1), 'v-': (1, -1)}
def rect_of(bd, lanai=True, eaves=True):
    r = list(bd['walls'])
    if lanai:
        for side, dep in bd['lanai'].items():
            i, s_ = SIDES[side]; r[i] += s_ * dep
    if eaves:
        e = bd['eaves']; r = [r[0] - e, r[1] - e, r[2] + e, r[3] + e]
    return r
def turned(bd, r):
    w = bd['walls']; c = ((w[0] + w[2]) / 2, (w[1] + w[3]) / 2)
    return [rot(c, bd['turn'], p) for p in [(r[0], r[1]), (r[2], r[1]), (r[2], r[3]), (r[0], r[3])]]
def footprint(bd): return turned(bd, rect_of(bd))
def body(bd): return turned(bd, rect_of(bd, eaves=False))
def inside(pt, poly):
    x, y = pt; c = False
    for i in range(len(poly)):
        a, b_ = poly[i], poly[i - 1]
        if (a[1] > y) != (b_[1] > y) and x < (b_[0] - a[0]) * (y - a[1]) / (b_[1] - a[1]) + a[0]: c = not c
    return c
def seg_dist(p, a, b_):
    du, dv = b_[0] - a[0], b_[1] - a[1]; L = du * du + dv * dv
    t = max(0, min(1, ((p[0] - a[0]) * du + (p[1] - a[1]) * dv) / L)) if L else 0
    return math.hypot(p[0] - a[0] - t * du, p[1] - a[1] - t * dv)
def segs_cross(a, b_, c, d):
    def o(p, q, r_): return (q[0] - p[0]) * (r_[1] - p[1]) - (q[1] - p[1]) * (r_[0] - p[0])
    return (o(a, b_, c) * o(a, b_, d) < 0) and (o(c, d, a) * o(c, d, b_) < 0)
def edges(poly, closed=True):
    return list(zip(poly, poly[1:] + poly[:1])) if closed else list(zip(poly, poly[1:]))
def dist(P, Q, qclosed=True):
    """Least distance between polygon P and polygon or polyline Q (0 if they meet)."""
    for e in edges(P):
        for f in edges(Q, qclosed):
            if segs_cross(e[0], e[1], f[0], f[1]): return 0.0
    if any(inside(p, P) for p in Q) or (qclosed and any(inside(p, Q) for p in P)): return 0.0
    return min(min(seg_dist(p, *f) for f in edges(Q, qclosed)) for p in P) if True else 0
def dist2(P, Q, qclosed=True):
    return min(dist(P, Q, qclosed), min(seg_dist(q, *e) for q in Q for e in edges(P)))

problems = []
for bd in B:
    w = bd['walls']; W_v = w[3] - w[1]; D_u = w[2] - w[0]
    for fi, rows in enumerate(bd['floors']):
        if abs(sum(d for d, _ in rows) - D_u) > 0.05:
            problems.append((bd['key'], 'floor %d rows add to %.2f, not the depth %.2f' % (fi, sum(d for d, _ in rows), D_u)))
        for d, rooms in rows:
            if abs(sum(x[2] for x in rooms) - W_v) > 0.05:
                problems.append((bd['key'], 'floor %d row adds to %.2f, not the width %.2f' % (fi, sum(x[2] for x in rooms), W_v)))
            for name, kind, wd in rooms:
                if kind in MIN_ROOM:
                    lo, hi = MIN_ROOM[kind]
                    if min(wd, d) < lo - 0.01 or max(wd, d) < hi - 0.01:
                        problems.append((bd['key'], '%s is %.1f x %.1f, under %.1f x %.1f' % (name, wd, d, lo, hi)))
    fp = footprint(bd); bo = body(bd)
    zone = PLAIN if bd['key'] != 'canoe_house' else SHORE
    if bd['key'] == 'canoe_house':
        if not all(inside(p, SHORE) or inside(p, BEACH) for p in bo[:1] + bo[3:]): problems.append((bd['key'], 'stands off the beach'))
    elif not all(inside(p, PLAIN) for p in bo): problems.append((bd['key'], 'stands outside the coastal plain'))
    if dist(fp, TERRACES) == 0: problems.append((bd['key'], 'stands on the taro terraces'))
    if dist2(fp, STREAM, False) < STREAM_CLEAR: problems.append((bd['key'], 'stands within %g m of the stream' % STREAM_CLEAR))
    if dist(fp, GREEN) == 0: problems.append((bd['key'], 'stands on the green'))
    if dist(fp, PIER_HEAD) == 0: problems.append((bd['key'], 'stands on the pier head'))
    if abs(bd['turn']) > 12: problems.append((bd['key'], 'turns more than 12 degrees'))
for i in range(len(B)):
    for j in range(i + 1, len(B)):
        g = dist2(footprint(B[i]), footprint(B[j]))
        if g < 2.99: problems.append((B[i]['key'], B[j]['key'], 'only %.1f m apart at the eaves' % g))
for r in RESIDENTS:
    if not any(w.startswith(r) for bd in B for w in bd['who']): problems.append(('resident without a building', r))
for bd in B:
    if bd.get('rest_point') and not bd.get('toilet'): problems.append((bd['key'], 'rest point without a toilet'))
# no path runs through walls or a lānai (eaves may overhang)
for nm, wd, pts in PATHS:
    for bd in B:
        if dist2(body(bd), pts, False) < wd / 2: problems.append((nm, 'runs through', bd['key']))
# every front faces a path or the green within 8 m
for bd in B:
    r = rect_of(bd, eaves=False); i, s_ = SIDES[bd['front']]
    mid = [(r[0] + r[2]) / 2, (r[1] + r[3]) / 2]
    if i in (0, 2): mid[0] = r[i]
    else: mid[1] = r[i]
    w = bd['walls']; m = rot(((w[0] + w[2]) / 2, (w[1] + w[3]) / 2), bd['turn'], mid)
    near = any(min(seg_dist(m, *e) for e in edges(pts, False)) <= 8 + wd / 2 for _, wd, pts in PATHS) or min(seg_dist(m, *e) for e in edges(GREEN)) <= 8
    if not near: problems.append((bd['key'], 'its front faces no path or the green'))
if problems:
    for p_ in problems: print('PROBLEM', p_)
    sys.exit(1)

# ---- write the plan
def q(t): return json.dumps(t, ensure_ascii=False)
def v2(p): return 'Vector2(%g, %g)' % tuple(p)
def pts(poly): return 'PackedVector2Array([%s])' % ', '.join(v2(p) for p in poly)
def rect(r): return 'Rect2(%g, %g, %g, %g)' % (r[0], r[1], r[2] - r[0], r[3] - r[1])
out = []; w_ = out.append
w_('class_name KaiMaliePlan')
w_('extends RefCounted')
w_('')
w_('## Kai Mālie\'s single plan (docs/architecture/ocean_island_village_layout.md and')
w_('## ocean_island_village_buildings.md). GENERATED by tools/kai_malie_layout.py:')
w_('## edit there and rerun, never here. The village builder and')
w_('## tools/validate_kai_malie_plan.tscn read only this.')
w_('##')
w_('## Local metres on the main island: u (x) points from the island centre toward')
w_('## the arrival dock, v (y) to its right. to_world() converts. The shore and')
w_('## every zone are smoothed curves (polygons of many points), not boxes.')
w_('')
w_('const CENTER := %s' % v2(CENTER))
w_('const U_AXIS := %s' % v2(U))
w_('const V_AXIS := %s' % v2(V))
for nm, poly in [('PLAIN', PLAIN), ('BEACH', BEACH), ('REEF_FLAT', REEF_FLAT), ('TERRACES', TERRACES), ('GREEN', GREEN),
                 ('PIER_HEAD', PIER_HEAD), ('KAHALA_GARDEN', KAHALA_GARDEN)]:
    w_('static var %s := %s' % (nm, pts(poly)))
w_('## Lines: the stream from the waterfall to the fishpond, the fishpond wall.')
w_('static var STREAM := %s' % pts(STREAM))
w_('const STREAM_CLEAR := %g' % STREAM_CLEAR)
w_('static var FISHPOND_WALL := %s' % pts(FISHPOND_WALL))
w_('static var HEADLANDS := [%s]' % ', '.join(pts(h) for h in HEADLANDS))
w_('static var BUNDS := [%s]' % ', '.join(pts(h) for h in BUNDS))
w_('const PIER := %s' % rect(PIER))
w_('const MEETING_ROCKS := %s' % v2(MEETING_ROCKS))
w_('const WATERFALL := %s' % v2(WATERFALL))
w_('const PIRATES_BEACH_V := %s' % v2(PIRATES_BEACH))
w_('const DOCK_U := %g' % DOCK_U)
w_('')
w_('## Every building: walls as a local Rect2 before its turn, the turn in degrees')
w_('## (from +u toward +v, about the walls\' centre), the body (walls and lānai) and')
w_('## footprint (with eaves) as turned polygons, the side its front faces (u+')
w_('## seaward, u- upslope, v+, v-), and its floors as rows of rooms (depth along')
w_('## u, then rooms with their width along v), in the building\'s own frame.')
w_('static var BUILDINGS := [')
for bd in B:
    floors = '[' + ', '.join('[' + ', '.join('[%g, [%s]]' % (d, ', '.join('[%s, %s, %g]' % (q(n), q(k), wd) for n, k, wd in rooms)) for d, rooms in rows) + ']' for rows in bd['floors']) + ']'
    extra = {k: v for k, v in bd.items() if k not in ('key', 'name', 'kind', 'walls', 'front', 'lanai', 'eaves', 'floors', 'who', 'turn')}
    w_('\t{"key": %s, "name": %s, "kind": %s, "walls": %s, "turn": %g, "body": %s, "footprint": %s, "front": %s, "lanai": %s, "eaves": %g, "floor_height": %g, "floors": %s, "who": %s, "extra": %s},' % (
        q(bd['key']), q(bd['name']), q(bd['kind']), rect(bd['walls']), bd['turn'], pts(body(bd)), pts(footprint(bd)), q(bd['front']),
        q(bd['lanai']), bd['eaves'], plain_height((bd['walls'][0] + bd['walls'][2]) / 2) + (bd.get('paepae', 0.8)),
        floors, q(bd['who']), q(extra)))
w_(']')
w_('')
w_('## Paths: name, width, the smoothed centre line.')
w_('static var PATHS := [')
for nm, wd, p_ in PATHS: w_('\t[%s, %g, %s],' % (q(nm), wd, pts(p_)))
w_(']')
w_('')
w_('const RESIDENTS: Array[String] = [%s]' % ', '.join(q(r) for r in RESIDENTS))
w_('')
w_('')
w_('static func to_world(local: Vector2) -> Vector2:')
w_('\treturn CENTER + U_AXIS * local.x + V_AXIS * local.y')
root = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..')
open(os.path.join(root, 'scripts', 'kai_malie_plan.gd'), 'w').write('\n'.join(out) + '\n')
if '--json' in sys.argv:
    path = sys.argv[sys.argv.index('--json') + 1]
    json.dump(dict(buildings=[dict(bd, footprint=footprint(bd), body=body(bd)) for bd in B], paths=PATHS, plain=PLAIN, beach=BEACH,
                   reef=REEF_FLAT, headlands=HEADLANDS, terraces=TERRACES, bunds=BUNDS, stream=STREAM, green=GREEN, pier=PIER,
                   pier_head=PIER_HEAD, fishpond=FISHPOND_WALL, rocks=MEETING_ROCKS, waterfall=WATERFALL, garden=KAHALA_GARDEN,
                   pirates=PIRATES_BEACH, center=CENTER, u=U, v=V), open(path, 'w'), ensure_ascii=False)
print('wrote scripts/kai_malie_plan.gd: %d buildings, %d paths, %d residents' % (len(B), len(PATHS), len(RESIDENTS)))
