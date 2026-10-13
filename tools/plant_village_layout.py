"""Authoring tool for the Plant Kingdom's primate village
(docs/architecture/plant_kingdom_village_layout.md and _buildings.md). It holds
the three giant trees, the commons deck and everything on it, the inn, the
household rings with their pavilions, the bridges, the public switchbacks, the
grand ramp, the ground camp, and the kingdom's landmarks; checks them; and
writes JSON for the drawings and the 3D model.

    python3 tools/plant_village_layout.py [--json out.json]

Local metres from the village centre (the kingdom origin); x and z follow the
world axes, +z toward the river (south). Heights are metres above the village
floor. Bearings are degrees from +x toward +z.
"""
import json, math, sys
from shapely.geometry import Polygon, Point, LineString, box
from shapely.ops import unary_union   # pip install shapely

def rad(b): return math.radians(b)
def pol(c, r, b): return (c[0] + r * math.cos(rad(b)), c[1] + r * math.sin(rad(b)))
def dist(a, b): return math.hypot(a[0] - b[0], a[1] - b[1])
def bearing(a, b): return math.degrees(math.atan2(b[1] - a[1], b[0] - a[0])) % 360

FLAT_RADIUS = 55.0            # the protected clearing (jungle_kingdom_terrain.gd)
SAFE_RADIUS = 55.0
FOLIAGE_CLEAR = 60.0          # the layout asks the jungle to clear to 60 m
RAMP_ANGLE = 32.0
LANDING = 1.2
STOREY = 3.8                  # the trees' landing spacing (nature_props.gd EMERGENT_BRANCH_RISE)
COMMONS_Y = 11.4
RING_YS = (22.8, 34.2)
CROWN_Y = 45.6
BRIDGE_Y = 22.8
ROUTE = 1.5                   # clear route between things on a deck
HEADROOM = 2.4                # clear height over every route and ramp
RING_WIDTH = 5.0
## The climbing well: every deck stands back 2 m from its trunk, leaving an open
## well round the trunk where the climbers' spiral rises (circulation, section 9).
WELL = 2.0
CLIMB_WIDTH = 1.5             # the climbers' spiral, 46 deg, as the trees' branch ramps are
CLIMB_RUN = 3.6               # nature_props.gd: 3.8 m rise over 3.6 m run
CLIMB_LANDING = 2.3
BAY_WIDTH = 6.5

## ---- the three giant trees (jungle_kingdom_village.gd), tualang
TREES = {
    'east':  dict(name='East Tree',  c=(14.0, 12.0),  h=56.0),
    'elder': dict(name='Elder Tree', c=(-16.0, 9.0),  h=62.0),
    'north': dict(name='North Tree', c=(2.0, -18.0),  h=58.0),
}
def trunk_r(t, y):
    """Trunk radius at height y (nature_props.gd: 0.045 h at the base to 0.02 h at 0.86 h)."""
    h = TREES[t]['h']; top = 0.86 * h
    return 0.045 * h + (0.02 * h - 0.045 * h) * min(1, y / top)

GATE = (0.0, -3.0)
PLAZA_CLEAR = 12.0            # the gate plaza: nothing in it but the gate and the arrival

## ---- the commons (11.4 m): a rounded triangle round the trunks
COMMONS_OFFSET = 3.5          # deck edge beyond the line between trunk centres: wraps each trunk
def commons_outline(offset=COMMONS_OFFSET, n=18):
    cs = [TREES[k]['c'] for k in ('east', 'north', 'elder')]   # counter-clockwise in screen space
    cen = (sum(c[0] for c in cs) / 3, sum(c[1] for c in cs) / 3)
    pts = []
    for i, c in enumerate(cs):
        a, b = cs[i - 1], cs[(i + 1) % 3]
        b0 = bearing(cen, c)
        # sweep the corner arc between the outward normals of the two edges
        def normal(p, q):
            d = (q[0] - p[0], q[1] - p[1]); L = math.hypot(*d); nrm = (d[1] / L, -d[0] / L)
            mid = ((p[0] + q[0]) / 2, (p[1] + q[1]) / 2)
            if (mid[0] - cen[0]) * nrm[0] + (mid[1] - cen[1]) * nrm[1] < 0: nrm = (-nrm[0], -nrm[1])
            return math.degrees(math.atan2(nrm[1], nrm[0]))
        n0, n1 = normal(a, c), normal(c, b)
        sweep = (n1 - n0) % 360
        if sweep > 180: sweep -= 360
        for k in range(n + 1):
            pts.append(pol(c, offset, n0 + sweep * k / n))
    return pts
def area(poly): return abs(sum(poly[i][0] * poly[i - 1][1] - poly[i - 1][0] * poly[i][1] for i in range(len(poly)))) / 2
def inside(p, poly):
    x, y = p; c = False
    for i in range(len(poly)):
        a, b = poly[i], poly[i - 1]
        if (a[1] > y) != (b[1] > y) and x < (b[0] - a[0]) * (y - a[1]) / (b[1] - a[1]) + a[0]: c = not c
    return c
def seg_dist(p, a, b):
    dx, dy = b[0] - a[0], b[1] - a[1]; L = dx * dx + dy * dy
    t = 0 if L == 0 else max(0, min(1, ((p[0] - a[0]) * dx + (p[1] - a[1]) * dy) / L))
    return math.hypot(p[0] - a[0] - t * dx, p[1] - a[1] - t * dy)
def edge_dist(p, poly): return min(seg_dist(p, poly[i - 1], poly[i]) for i in range(len(poly)))
def rect(c, w, d, yaw):
    """Corners of a w (along yaw) by d rectangle centred at c."""
    u = (math.cos(rad(yaw)), math.sin(rad(yaw))); v = (-u[1], u[0])
    return [(c[0] + u[0] * sx * w / 2 + v[0] * sy * d / 2, c[1] + u[1] * sx * w / 2 + v[1] * sy * d / 2) for sx, sy in ((-1, -1), (1, -1), (1, 1), (-1, 1))]
def poly_gap(a, b):
    """Least distance between two convex polygons (0 if they meet)."""
    if any(inside(p, b) for p in a) or any(inside(p, a) for p in b): return 0.0
    return min(min(seg_dist(p, b[i - 1], b[i]) for i in range(len(b))) for p in a + [] ) if a else 0.0
def gap(a, b): return min(poly_gap(a, b), poly_gap(b, a))

COMMONS = commons_outline()
CEN = (sum(TREES[k]['c'][0] for k in TREES) / 3, sum(TREES[k]['c'][1] for k in TREES) / 3)

## amenities on the deck, placed along the deck's edges: key, name, keeper, edge, t (0..1 along it),
## w (along the edge), d (across it), roof. Edges run W->E (south), W->N (north-west), N->E (north-east).
EDGES = {'S': ('elder', 'east'), 'NW': ('elder', 'north'), 'NE': ('north', 'east')}
def on_edge(edge, t, d, inset=0.9):
    a, b = (TREES[k]['c'] for k in EDGES[edge])
    p = (a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t)
    L = dist(a, b); n = ((b[1] - a[1]) / L, -(b[0] - a[0]) / L)
    if (p[0] - CEN[0]) * n[0] + (p[1] - CEN[1]) * n[1] < 0: n = (-n[0], -n[1])
    off = COMMONS_OFFSET - inset - d / 2
    return (p[0] + n[0] * off, p[1] + n[1] * off), bearing(a, b)
AMENITY_SPEC = [
    ('market', 'Market', "Delima's fruit, Rotan's rope", 'S', 0.5, 12.0, 4.0, 'long leaf roof, facing the grand ramp\'s head', 2.0),
    ('kitchen', 'Shared kitchen', 'Wangi', 'NW', 0.34, 8.0, 6.0, 'the one fire in the trees', 0.1),
    ('dining', 'Dining terrace', 'everyone', 'NW', 0.64, 10.0, 6.0, 'open roof', 0.1),
    ('store', 'Food store', 'shared', 'NE', 0.245, 4.0, 4.0, 'raised basket store', 0.1),
    ('cistern', 'Cistern pavilion', 'shared', 'NE', 0.455, 6.0, 6.0, 'the largest leaf roof', 0.1),
    ('workshop', "Jati's workshop", 'Jati', 'NE', 0.69, 6.0, 5.0, 'half-open', 0.1),
]
CIRCLE = (CEN[0] - 0.4, CEN[1] + 0.8)
AMENITIES = [('circle', 'Gathering circle', 'the elders; Purnama presides', CIRCLE, 7.2, 7.2, 0, 'open to the sky')]
for k, n_, w_, e, t, w, d, r, front in AMENITY_SPEC:
    c, y = on_edge(e, t, d, 0.9 + front)
    AMENITIES.append((k, n_, w_, c, w, d, y, r))
## the public privy hangs just outside the rail beside the food store, on its own small bracketed
## platform, so it takes no room from the deck and its vat lowers straight to the ground
PRIVY_C, PRIVY_YAW = on_edge('NE', 0.33, 1.4, -1.6)
PRIVY = ('privy', 'Public privy', 'shared', PRIVY_C, 1.8, 1.4, PRIVY_YAW, 'rattan closet on a bracketed platform')
## the inn: a rounded lobe of deck east of the East Tree, one piece with the commons, the house on
## its east part with its veranda facing the commons, carried by six posts under the house's walls
INN = dict(lobe=(14.0, 3.5, 30.0, 20.5), round=3.0, house_c=(24.1, 12.0), house=(14.0, 8.0), veranda=3.0, keeper='Bima', price=15)
## the grand ramp: a 32 deg spiral wound round a living column (a strangler fig grown on a post)
## just south of the deck's south edge, arriving at the edge beside the market
S_EDGE, _ = on_edge('S', 0.5, 0.0, 0.0)
GRAND = dict(head=S_EDGE, width=2.4, column_r=1.6, landing=LANDING)
GRAND['r'] = GRAND['column_r'] + 0.2 + GRAND['width'] / 2          # the ramp's centreline radius
GRAND['c'] = (S_EDGE[0], S_EDGE[1] + GRAND['column_r'] + 0.2 + GRAND['width'] + 0.2)
## posts to the ground: six under the commons' edges, one under the market's side of the south edge,
## six under the inn house's walls. None stands in the gate plaza.
POSTS = [on_edge(e, t, 2.0, 0.0)[0] for e, t in (('S', 0.25), ('S', 0.75), ('NW', 0.2), ('NE', 0.85))]
POSTS += [(S_EDGE[0] + 0.3, S_EDGE[1] - 1.0)]
POSTS += [(INN['house_c'][0] + sx * (INN['house'][1] / 2 - 0.5), INN['house_c'][1] + sz * (INN['house'][0] / 2 - 0.5)) for sx in (-1, 1) for sz in (-1, 0, 1)]

## ---- household rings and pavilions: tree, ring height, bearing round the trunk, kind, who
PAVILIONS = [
    ('elder', CROWN_Y, 225, 'crown', 'Purnama and Sekar'),
    ('elder', 34.2, 225, 'couple', 'Senja and Rimba'),
    ('elder', 22.8, 40, 'single', 'Abu'),
    ('east', 34.2, 300, 'single', 'Tunas'),
    ('east', 34.2, 50, 'single', 'Bayu'),
    ('east', 22.8, 300, 'couple', 'Jati and Embun'),
    ('east', 22.8, 50, 'single', 'Dahan'),
    ('north', 34.2, 20, 'joined', 'Intan and Murai'),
    ('north', 34.2, 180, 'empty', 'Laras and Gilang (empty)'),
    ('north', 22.8, 165, 'couple', 'Tirta and Bintang'),
]
PAV_SIZE = {'single': (4.0, 4.0), 'couple': (5.0, 4.0), 'joined': (9.0, 4.0), 'empty': (4.0, 4.0), 'crown': (7.0, 5.0)}
## the 32 deg public switchback on each tree: a tower of flights beside the trunk, from the commons up
## The public spiral: a 32 deg ramp 1.5 m wide wound round each trunk just outside its well, under
## the rings, from the commons to every ring (and the Elder Tree's crown). It replaces the
## switchback towers, which took too much of the commons (circulation, section 9).
PUBLIC_W = 1.5
BRIDGES = [('elder', 'east'), ('east', 'north'), ('north', 'elder')]

## ---- the ground camp: key, name, who, centre, w, d, yaw, kind
GROUND = [
    ('ape_lodge', 'Ape lodge', 'Batu, Sari, Teguh', (38.0, -14.0), 14.0, 7.0, 0, 'lodge on short stilts'),
    ('stable', 'Stable and paddock', 'Ossian Redbrow; Manchego', (24.0, -30.0), 12.0, 10.0, 0, 'stall, paddock, lean-to'),
    ('tailed', "Tailed monkeys' house", 'Rotan, Kilat, Akar', (-34.0, -16.0), 10.0, 6.0, 0, 'raised hut'),
    ('garden', 'Garden house and gardens', 'Delima, Melati', (-38.0, 14.0), 9.0, 6.0, 0, 'raised hut and beds'),
    ('floor_hut', 'Floor hut', 'Damar, Wangi', (-24.0, 34.0), 8.0, 6.0, 0, 'raised hut'),
    ('training', 'Training grounds', 'Batu', (-48.0, -48.0), 20.0, 16.0, 45, 'fenced yard, dummies, shed'),
]
LANDMARKS = {  # the wider kingdom
    'kova_kong': dict(name='Kova Kong (Da Hou Zi)', c=(400.0, -280.0), note='the giant gorilla, about 80 m tall'),
    'wood_kingdom': dict(name='The Wood Kingdom', c=(-250.0, -300.0), r=34.0, note='abandoned treehouses; appears after the Ice Kingdom'),
    'clearing_w': dict(name='West clearing', c=(-250.0, 90.0), note=''),
    'falls': dict(name='The falls and the Water Curtain Cave', c=(-640.0, 150.0), note='a 38 m limestone cliff; the river begins here'),
    'mountain': dict(name='Flower Fruit Mountain', c=(-760.0, 150.0), note='the stone egg on its highest knoll'),
    'landing': dict(name="Tirta's fishing landing", c=(0.0, 141.0), note='on the river bank, end of the river trail'),
}

# ---- checks
problems = []
A = area(COMMONS)
if A < 520: problems.append(('the commons is only %.0f m2, under the 520 m2 its program needs' % A,))
amen = {k: rect(c, w, d, y) for k, _, _, c, w, d, y, _ in AMENITIES}
amen['circle'] = [pol(CIRCLE, 3.6, b) for b in range(0, 360, 20)]
privy_poly = rect(PRIVY_C, 1.8, 1.4, PRIVY_YAW)
if dist(PRIVY_C, GATE) < PLAZA_CLEAR: problems.append(('the privy hangs over the gate plaza',))
trunks11 = {k: [pol(t['c'], trunk_r(k, COMMONS_Y) + WELL, b) for b in range(0, 360, 15)] for k, t in TREES.items()}   # the well's rail
for k, poly in amen.items():
    if not all(inside(p, COMMONS) for p in poly): problems.append((k, 'reaches off the commons deck'))
    elif min(edge_dist(p, COMMONS) for p in poly) < 0.9: problems.append((k, 'stands within 0.9 m of the deck edge (rail and net)'))
    for t, tp in trunks11.items():
        if gap(poly, tp) < ROUTE: problems.append((k, 'leaves no route round the %s well (%.1f m)' % (t, gap(poly, tp))))
ks = list(amen)
for i in range(len(ks)):
    for j in range(i + 1, len(ks)):
        g = gap(amen[ks[i]], amen[ks[j]])
        if g < ROUTE and {ks[i], ks[j]} != {'store', 'privy'} and {ks[i], ks[j]} != {'kitchen', 'dining'}:
            problems.append((ks[i], ks[j], 'only %.1f m apart on the deck' % g))
# the gate plaza stays open below; the posts stand outside it and outside the buildings
for i, p in enumerate(POSTS):
    if dist(p, GATE) < PLAZA_CLEAR: problems.append(('post %d stands in the gate plaza' % i,))
# the inn lobe joins the deck and clears the East Tree
INN_LOBE = box(*INN['lobe']).buffer(-INN['round']).buffer(INN['round'], 16)
inn_poly = list(INN_LOBE.exterior.coords)[:-1]
house_poly = rect(INN['house_c'], INN['house'][1], INN['house'][0], 0)
if not INN_LOBE.buffer(-0.9).contains(Polygon(house_poly)): problems.append(('the inn house stands within 0.9 m of its lobe\'s edge',))

if gap(house_poly, trunks11['east']) < ROUTE: problems.append(('the inn house crowds the East Tree\'s well',))
# the grand ramp: one turn and a bit round its column, a landing half way, arriving at the deck's edge
G_RUN = COMMONS_Y / math.tan(rad(RAMP_ANGLE))
G_TURN = math.degrees((G_RUN + LANDING) / GRAND['r'])               # degrees wound from foot to head
GRAND['top_b'] = bearing(GRAND['c'], S_EDGE); GRAND['foot_b'] = GRAND['top_b'] - G_TURN; GRAND['turn'] = G_TURN
GRAND['turn_rise'] = COMMONS_Y * 360 / G_TURN
if GRAND['turn_rise'] < HEADROOM + 0.6: problems.append(('the grand spiral\'s turns leave too little headroom',))
g_poly = [pol(GRAND['c'], GRAND['column_r'] + 0.2 + GRAND['width'] + 0.2, b) for b in range(0, 360, 15)]
if dist(GRAND['c'], GATE) - GRAND['column_r'] - GRAND['width'] < PLAZA_CLEAR: problems.append(('the grand spiral stands in the gate plaza',))
if Polygon(g_poly).intersects(Polygon(COMMONS).buffer(-0.2)): problems.append(('the grand spiral runs under the commons',))
# rings: pavilions on bays fit round each ring with the walkway, the switchback and the bridge landings
def ring_arc(t, y, b0, width):
    r = trunk_r(t, y) + WELL + RING_WIDTH      # pavilions, bridges and switchbacks meet the ring at its outer edge
    return math.degrees(width / r)
for t in TREES:
    for y in RING_YS + ((CROWN_Y,) if t == 'elder' else ()):
        used = []
        for tt, yy, b, kind, who in PAVILIONS:
            if tt == t and yy == y: used.append((b, ring_arc(t, y, b, PAV_SIZE[kind][0] + 1.0), who))
        if y == BRIDGE_Y:
            for a_, b_ in BRIDGES:
                if t in (a_, b_):
                    o = b_ if t == a_ else a_
                    used.append((bearing(TREES[t]['c'], TREES[o]['c']), ring_arc(t, y, 0, 3.0), 'bridge to %s' % o))
        for i in range(len(used)):
            for j in range(i + 1, len(used)):
                d = abs((used[i][0] - used[j][0] + 180) % 360 - 180)
                if d < (used[i][1] + used[j][1]) / 2: problems.append((t, y, '%s and %s overlap on the ring' % (used[i][2], used[j][2])))
# bridges: span between ring edges
BR = []
for a_, b_ in BRIDGES:
    pa, pb = TREES[a_]['c'], TREES[b_]['c']
    span = dist(pa, pb) - trunk_r(a_, BRIDGE_Y) - trunk_r(b_, BRIDGE_Y) - 2 * (WELL + RING_WIDTH)
    BR.append(dict(a=a_, b=b_, span=round(span, 1)))
    if span > 32: problems.append(('the %s-%s bridge spans %.1f m' % (a_, b_, span),))
SBPOLY = {}
LOBES = {}
# ground camp: 3 m apart, 8 m from trunks, out of the plaza, posts, ramp; training grounds outside the safe zone
gpolys = {k: rect(c, w, d, y) for k, _, _, c, w, d, y, _ in GROUND}
gpolys['grand_ramp'] = g_poly
for k, p in gpolys.items():
    for t in TREES.values():
        if min(dist(q, t['c']) for q in p) < 8.0 and k != 'grand_ramp': problems.append((k, 'within 8 m of the %s trunk' % t['name']))
    if any(dist(q, GATE) < PLAZA_CLEAR for q in p): problems.append((k, 'stands in the gate plaza'))
    for i, q in enumerate(POSTS):
        if inside(q, p): problems.append((k, 'post %d stands in it' % i))
ks = list(gpolys)
for i in range(len(ks)):
    for j in range(i + 1, len(ks)):
        if gap(gpolys[ks[i]], gpolys[ks[j]]) < 3.0: problems.append((ks[i], ks[j], 'closer than 3 m'))
tr = gpolys['training']
if min(math.hypot(*q) for q in tr) < SAFE_RADIUS - 0.5: problems.append(('the training grounds reach into the safe zone (%.1f m)' % min(math.hypot(*q) for q in tr),))
for k, p in gpolys.items():
    if k != 'training' and max(math.hypot(*q) for q in p) > FLAT_RADIUS: problems.append((k, 'reaches off the flat clearing'))

# the commons' net area, less the three wells
def net_area(poly, step=0.5):
    xs = [p[0] for p in poly]; zs = [p[1] for p in poly]; n = 0
    x = min(xs)
    while x < max(xs):
        z = min(zs)
        while z < max(zs):
            if inside((x, z), poly) and all(dist((x, z), t['c']) > trunk_r(k, COMMONS_Y) + WELL for k, t in TREES.items()): n += 1
            z += step
        x += step
    return n * step * step
A_NET = net_area(COMMONS)
if A_NET < 520: problems.append(('the commons is only %.0f m2 net of its wells' % A_NET,))

## ---- the climbers' spiral in each tree's well: 46 deg flights of 3.8 m rise and 3.6 m run, a
## 2.3 m landing after each, hugging the trunk; it reaches every deck through a short arm.
DECKS = {'east': (COMMONS_Y,) + RING_YS, 'north': (COMMONS_Y,) + RING_YS, 'elder': (COMMONS_Y,) + RING_YS + (CROWN_Y,)}
def helix(t, a0):
    top = 0.86 * TREES[t]['h'] * 0.95; y = 0.0; a = a0; out = []
    while y + STOREY <= top:
        rh = trunk_r(t, y) + 0.3 + CLIMB_WIDTH / 2
        a1 = a + math.degrees(CLIMB_RUN / rh); a2 = a1 + math.degrees(CLIMB_LANDING / rh)
        out.append(dict(y0=y, y1=y + STOREY, a0=a, a1=a1, a2=a2, r=rh)); y += STOREY; a = a2
    return out
def arm_point(t, a, y):
    return pol(TREES[t]['c'], trunk_r(t, y) + WELL + 0.8, a)
HELIX = {}; ARMS = {}
for t in TREES:
    best = None
    for a0 in range(0, 360, 3):
        h = helix(t, a0); ok = True; arms = []
        for y in DECKS[t]:
            st = next(s_ for s_ in h if abs(s_['y1'] - y) < 0.01)
            b = (st['a1'] + st['a2']) / 2 % 360; ap = arm_point(t, b, y); arms.append((y, b))
            if y == COMMONS_Y:
                if not inside(ap, COMMONS) or any(inside(ap, q) or gap([ap], q) < 1.0 for q in list(amen.values()) + list(SBPOLY.values())): ok = False
            else:
                for tt, yy, bb, kind, who in PAVILIONS:     # the arm lands on the ring's walkway, not in a home
                    pass
        if ok:
            # prefer the start that lands the commons arm nearest the deck's middle
            cm = arm_point(t, arms[0][1], COMMONS_Y); score = dist(cm, CEN)
            if best is None or score < best[0]: best = (score, a0, h, arms)
    if best is None: problems.append((t, 'no start for the climbers\' spiral lands its arm on the commons'))
    else: HELIX[t] = dict(a0=best[1], steps=best[2]); ARMS[t] = best[3]
for t, h in HELIX.items():
    for st in h['steps']:
        if st['y1'] - st['y0'] < HEADROOM if False else False: pass
    # a full turn rises far more than the headroom a climber needs under the turn above
    turn = 360 / ((h['steps'][0]['a2'] - h['steps'][0]['a0'])) * STOREY
    if turn < 2.4 + 0.4: problems.append((t, 'the spiral leaves too little headroom'))
## the deck as built: the commons, a collar wrapping each trunk so its well is a closed hole with a
## walk all round it, and the inn's lobe, filleted into one outline, less the three wells.
## It must be one piece, so everything on it is reachable without crossing a well.
COLLAR = 2.6                  # deck beyond each well: a 1.5 m route and the rail
WELLS = {k: Point(t['c']).buffer(trunk_r(k, COMMONS_Y) + WELL, 48) for k, t in TREES.items()}
COLLARS = [Point(t['c']).buffer(trunk_r(k, COMMONS_Y) + WELL + COLLAR, 48) for k, t in TREES.items()]
DECK = unary_union([Polygon(COMMONS), INN_LOBE] + COLLARS).buffer(1.5, 16).buffer(-1.5, 16).difference(unary_union(list(WELLS.values())))
if DECK.geom_type == 'Polygon' and len(DECK.interiors) != 3: problems.append(('a well breaks through the deck\'s edge',))
for i, p in enumerate(POSTS):
    if not DECK.buffer(-0.3).contains(Point(p)): problems.append(('post %d stands outside the deck it carries' % i,))
if DECK.geom_type != 'Polygon': problems.append(('the commons deck is in %d pieces once the wells are cut' % len(DECK.geoms),))
DECK_POLYS = [DECK] if DECK.geom_type == 'Polygon' else list(DECK.geoms)
if Polygon(house_poly).intersects(unary_union(list(WELLS.values())).buffer(ROUTE)): problems.append(('the inn house crowds a well',))
## the public spiral: from a foot on the commons, 32 deg, a landing at each deck it reaches, coming up
## through an opening in each ring where the ring above would cut its headroom
OPEN_RUN = (HEADROOM + 0.3) / math.tan(rad(RAMP_ANGLE))
def public(t, a0):
    ys = DECKS[t]; a = a0; out = []; opens = []
    for y0, y1 in zip(ys, ys[1:]):
        rp = trunk_r(t, (y0 + y1) / 2) + WELL + PUBLIC_W / 2
        run = (y1 - y0) / math.tan(rad(RAMP_ANGLE))
        a1 = a + math.degrees(run / rp); a2 = a1 + math.degrees(LANDING / rp)
        out.append(dict(y0=y0, y1=y1, a0=a, a1=a1, a2=a2, r=rp))
        opens.append(dict(y=y1, a0=a1 - math.degrees(OPEN_RUN / rp), a1=a2))
        a = a2
    return out, opens
def arc_gap(a, b0, b1, r):
    """Distance along a circle of radius r from bearing a to the arc b0..b1 (0 inside it)."""
    a = (a - b0) % 360; L = (b1 - b0) % 360
    if a <= L: return 0.0
    return math.radians(min(a - L, 360 - a)) * r
PUBLIC = {}
for t in TREES:
    best = None
    for a0 in range(0, 360, 3):
        steps, opens = public(t, a0)
        rp0 = steps[0]['r']; foot = pol(TREES[t]['c'], rp0, a0 - math.degrees(LANDING / rp0) / 2)
        if not DECK.contains(Point(foot)) or any(gap([foot], q) < 0.6 for q in amen.values()): continue
        arm_b = dict(ARMS.get(t, []))
        if arm_b and arc_gap(arm_b[COMMONS_Y], a0 - math.degrees(LANDING / rp0), a0, rp0) < 2.0: continue
        ok = True
        for o in opens:
            if o['y'] in arm_b and arc_gap(arm_b[o['y']], o['a0'], o['a1'], trunk_r(t, o['y']) + WELL) < 1.5: ok = False
        if ok:
            score = dist(foot, CEN)
            if best is None or score < best[0]: best = (score, a0, steps, opens)
    if best is None: problems.append((t, 'no start for the public spiral fits the commons and the arms'))
    else: PUBLIC[t] = dict(a0=best[1], steps=best[2], openings=best[3])
    # one turn above another clears the headroom
    if best:
        st = best[2]; per = sum(x['a2'] - x['a0'] for x in st) / len(st)
        if 11.4 * 360 / per < HEADROOM + 0.4: problems.append((t, 'the public spiral\'s turns are too close'))


## ---- structure: what carries every deck (layout section 10)
## The commons, at 11.4 m, is below the trees' first limbs. It stands on timber bearers bracketed to
## each trunk across its well, and on posts. Its middle is over the gate plaza, where no post may
## stand, so it hangs: each tree grows two limbs at about 20 m toward the commons' middle, and their
## tips carry a hung ring beam round the gathering circle. The rings and the crown deck sit on
## bearers too: a living limb under every pavilion and every bridge landing, timber bearers between.
## No bearer or limb crosses the climbers' spiral or the public spiral within a walker's headroom.
BEARER_TOP, BEARER_BOTTOM = 0.35, 1.3   # a bearer fills y - 1.3 .. y - 0.35 under its deck
BEARER_REACH = 6.0            # with its knee brace a bearer carries the deck this far beyond the well
POST_REACH = 6.0              # beams from a post's head
HANG_REACH = 4.5              # joists between hung beams
MAX_BAY = 7.0                 # bearers no further apart than this at a deck's outer edge
LIMB_MAX = 11.5               # nature_props.gd EMERGENT_BOUGH_LENGTH_MAX
COMMONS_LIMB_SPREAD = 25.0    # each tree's two commons limbs, either side of the line to the middle
def walk_heights(t, b):
    """Heights of the climbers' and the public spiral's walking surfaces at bearing b round tree t."""
    hs = []
    for st in HELIX[t]['steps'] + PUBLIC[t]['steps']:
        d = (b - st['a0']) % 360
        if d <= st['a1'] - st['a0']: hs.append(st['y0'] + (st['y1'] - st['y0']) * d / (st['a1'] - st['a0']))
        elif d <= st['a2'] - st['a0']: hs.append(st['y1'])
    return hs
def clear_of_walks(t, b, y_lo, y_hi):
    return all(y_hi < h - 0.3 or y_lo > h + HEADROOM for h in walk_heights(t, b))
def nearest_clear(t, b, y_lo, y_hi, within):
    for d in sorted(range(-int(within), int(within) + 1), key=abs):
        if clear_of_walks(t, (b + d) % 360, y_lo, y_hi): return (b + d) % 360
    return None
def fill_bearers(t, y, r_out, fixed, hung=None):
    """Timber bearers between the fixed ones, so no bay at the outer edge exceeds MAX_BAY. Where the
    spirals rise under a deck no bearer can cross them, and that bay is hung from above instead
    (listed in `hung`); with no `hung` list, such a bay is left to the coverage check."""
    bs = sorted(b % 360 for b in fixed); out = []; settled = set()
    cands = [b for b in range(0, 360, 2) if clear_of_walks(t, b, y - BEARER_BOTTOM, y - BEARER_TOP)]
    if not bs and cands: out.append(cands[0])
    changed = True
    while changed:
        changed = False
        allb = sorted(set(bs + out))
        for i, b0 in enumerate(allb):
            b1 = allb[(i + 1) % len(allb)] + (360 if i + 1 == len(allb) else 0)
            if math.radians(b1 - b0) * r_out <= MAX_BAY + 1e-6 or (b0, b1 % 360) in settled: continue
            mid = (b0 + b1) / 2
            pick = [c for c in cands if b0 < c < b1 or b0 < c + 360 < b1]
            if not pick:
                settled.add((b0, b1 % 360))
                if hung is not None: hung.append((b0, b1 % 360))
                continue
            out.append(min(pick, key=lambda c: abs(((c - mid + 180) % 360) - 180))); changed = True; break
    return out
SUPPORT = dict(bearers=[], limbs=[], commons_limbs=[], hung=[])
# the commons: timber bearers round each well
for t in TREES:
    r_out = trunk_r(t, COMMONS_Y) + WELL + BEARER_REACH
    for b in fill_bearers(t, COMMONS_Y, r_out, [], []):
        # a bearer runs out across the well to the deck's edge, or its reach, whichever is nearer
        c = TREES[t]['c']; r_in = trunk_r(t, COMMONS_Y) + WELL
        ray = LineString([pol(c, r_in + 0.05, b), pol(c, r_out, b)]).intersection(DECK)
        seg = ray if ray.geom_type == 'LineString' else min(ray.geoms, key=lambda g: Point(c).distance(g))
        end = max(seg.coords, key=lambda q: dist(q, c)) if not seg.is_empty else pol(c, r_in, b)
        SUPPORT['bearers'].append(dict(tree=t, y=COMMONS_Y, b=b, r0=trunk_r(t, COMMONS_Y), r1=round(dist(end, c) - 0.3, 2)))
# the commons limbs and their hung ring
for t, tr in TREES.items():
    for sgn in (-1, 1):
        b = (bearing(tr['c'], CEN) + sgn * COMMONS_LIMB_SPREAD) % 360
        y = next((y for y in [round(18.5 + 0.1 * i, 1) for i in range(31)] if clear_of_walks(t, b, y - 0.6, y + 0.6)), None)
        if y is None: problems.append((t, 'no height for a commons limb at %.0f' % b)); continue
        r0 = trunk_r(t, y); tip = pol(tr['c'], r0 + LIMB_MAX, b)
        SUPPORT['commons_limbs'].append(dict(tree=t, b=b, y=y, r0=r0, length=LIMB_MAX, tip=tip))
tips = sorted((l['tip'] for l in SUPPORT['commons_limbs']), key=lambda q: math.atan2(q[1] - CEN[1], q[0] - CEN[0]))
SUPPORT['hung'] = tips
HUNG = Polygon(tips)
carried = [HUNG.buffer(HANG_REACH)]
carried += [Point(t['c']).buffer(trunk_r(k, COMMONS_Y) + WELL + BEARER_REACH) for k, t in TREES.items()]
carried += [Point(p).buffer(POST_REACH) for p in POSTS]
for l in SUPPORT['commons_limbs']:
    c = TREES[l['tree']]['c']
    carried.append(LineString([pol(c, l['r0'] + WELL + 1.0, l['b']), l['tip']]).buffer(HANG_REACH))
UNCARRIED = DECK.difference(unary_union(carried))
if UNCARRIED.area > 0.5: problems.append(('%.1f m2 of the commons has nothing under or over it' % UNCARRIED.area, [tuple(round(v, 1) for v in g.centroid.coords[0]) for g in getattr(UNCARRIED, 'geoms', [UNCARRIED]) if g.area > 0.2]))
if any(HUNG.buffer(0.1).contains(Point(p)) for p in POSTS): problems.append(('a post stands under the hung ring',))
# rings and the crown: a living limb under every pavilion and bridge landing, timber bearers between
for t in TREES:
    for y in DECKS[t][1:]:
        width = 5.5 if y == CROWN_Y else RING_WIDTH
        r_in = trunk_r(t, y) + WELL; r_out = r_in + width; fixed = []
        loads = [(pb, PAV_SIZE[k][0], PAV_SIZE[k][1], who) for tt, yy, pb, k, who in PAVILIONS if tt == t and yy == y]
        if y == BRIDGE_Y:
            for a_, b_ in BRIDGES:
                if t in (a_, b_): loads.append((bearing(TREES[t]['c'], TREES[b_ if t == a_ else a_]['c']), 3.0, 0.0, 'bridge'))
        for pb, w, d, who in loads:
            half = math.degrees((w / 2 - 0.5) / r_out)
            b = nearest_clear(t, pb, y - BEARER_BOTTOM, y - BEARER_TOP, half)
            if b is None: problems.append((t, y, who, 'no clear bearing for the limb under it')); continue
            reach = r_out + max(0.0, d - 0.6) - 1.0 - trunk_r(t, y)     # to a metre short of the pavilion's outer edge
            if reach > LIMB_MAX: problems.append((t, y, who, 'needs a %.1f m limb' % reach))
            SUPPORT['limbs'].append(dict(tree=t, y=y, b=b, r0=trunk_r(t, y), length=round(min(reach, LIMB_MAX), 2), carries=who)); fixed.append(b)
        hung = []
        for b in fill_bearers(t, y, r_out, fixed, hung):
            SUPPORT['bearers'].append(dict(tree=t, y=y, b=b, r0=trunk_r(t, y), r1=r_out))
        for b0, b1 in hung:
            # a hung bay: hangers at its inner and outer edges, outside the public spiral's 1.5 m, from a
            # hanger limb grown 3.5 to 7 m above the deck over the bay's middle
            mid = (b0 + ((b1 - b0) % 360) / 2) % 360
            yh = next((yy for yy in [round(y + 3.5 + 0.1 * i, 1) for i in range(36)]
                       if clear_of_walks(t, mid, yy - 0.6, yy + 0.6) and all(abs(yy - dy) > 1.6 for dy in DECKS[t])), None)
            if yh is None: problems.append((t, y, 'no hanger limb over the bay %.0f-%.0f' % (b0, b1))); continue
            SUPPORT.setdefault('hangers', []).append(dict(tree=t, y=y, b0=b0, b1=b1, limb_y=yh, b=mid, r0=trunk_r(t, yh),
                                                         length=round(r_out + 0.5 - trunk_r(t, yh), 2), r_in=r_in + PUBLIC_W + 0.1, r_out=r_out))
# the rest of each crown: limbs as nature_props.gd grows them (from 0.4 of the trunk, every 6.2 m, by
# the golden angle), skipped near a deck and wherever they would cross a walk
GOLDEN_B = 360 * 0.6180339887498949
BOUGHS = []
for t, tr in TREES.items():
    top = 0.86 * tr['h']; y = top * 0.40; a = {'east': 40.0, 'elder': 160.0, 'north': 280.0}[t]
    while y < top * 0.97:
        near = any(abs(y - dy) < 3.4 for dy in DECKS[t]) or any(abs(y - l['y']) < 2.0 for l in SUPPORT['commons_limbs'] if l['tree'] == t)
        if not near and clear_of_walks(t, a % 360, y - 0.6, y + 0.6):
            hf = y / top
            BOUGHS.append(dict(tree=t, y=round(y, 2), b=round(a % 360, 1), r0=trunk_r(t, y), length=round(11.5 + (5.0 - 11.5) * hf, 2), pitch=0.26))
        a += GOLDEN_B; y += 6.2

## the commons hoist: a basket on a pulley over the deck's edge beside the food store, so food, water
## and firewood come up from the floor without being carried up the ramps
STORE = next(a for a in AMENITIES if a[0] == 'store')
HOIST = on_edge('NE', 0.245, 0.0, -0.6)[0]
if dist(HOIST, GATE) < PLAZA_CLEAR: problems.append(('the hoist lowers into the gate plaza',))

for p in problems: print('PROBLEM', p)

# ---- the trees' existing branch-ramp chains (nature_props.gd build_emergent_tree), for the model:
# each ramp climbs 3.8 m over 3.6 m from the last landing, turning by the golden angle.
GOLDEN = 360 * 0.6180339887498949
def branch_chain(t, start_angle):
    h = TREES[t]['h']; top = 0.86 * h; y = 0.0; pos = None; a = start_angle; out = []
    while y + STOREY <= top * 0.95:
        tr_ = trunk_r(t, y)
        start = (math.cos(rad(a)) * (tr_ + 0.3), math.sin(rad(a)) * (tr_ + 0.3)) if pos is None else pos
        d = (math.cos(rad(a)), math.sin(rad(a)))
        top_pt = (start[0] + d[0] * 3.6, start[1] + d[1] * 3.6)
        land = (top_pt[0] + d[0] * 2.3 * 0.7, top_pt[1] + d[1] * 2.3 * 0.7)
        out.append(dict(a=start, b=top_pt, y0=y, y1=y + STOREY, land=land))
        pos = land; y += STOREY; a += GOLDEN
    return out

for i, p in enumerate(POSTS):
    for k, ap in list(amen.items()) + list(SBPOLY.items()):
        if inside(p, ap): problems.append(('post %d stands in %s' % (i, k),))
for p in problems[len(problems) - 0:]: pass
data = dict(
    deck=[dict(ext=list(map(list, d_.exterior.coords)), holes=[list(map(list, i.coords)) for i in d_.interiors]) for d_ in DECK_POLYS],
    helix=HELIX, arms=ARMS, well=WELL, climb_width=CLIMB_WIDTH, hoist=HOIST, commons_net=round(A_NET),
    trees={k: dict(v, base_r=0.045 * v['h'], top_r=0.02 * v['h'], trunk_top=0.86 * v['h'], canopy_r=0.34 * v['h'],
                   chain=branch_chain(k, {'east': 30, 'elder': 200, 'north': 290}[k])) for k, v in TREES.items()},
    gate=GATE, plaza=PLAZA_CLEAR, commons=COMMONS, commons_y=COMMONS_Y, commons_area=round(A), centroid=CEN,
    amenities=[dict(key=k, name=n, who=w_, c=c, w=w, d=d, yaw=y, roof=r) for k, n, w_, c, w, d, y, r in AMENITIES + [PRIVY]],
    inn=INN, inn_lobe=inn_poly, grand=dict(GRAND, run=G_RUN, poly=g_poly), posts=POSTS, support=SUPPORT, boughs=BOUGHS, sbpoly=SBPOLY, lobes=LOBES, inn_house=house_poly,
    rings=dict(ys=RING_YS, crown=CROWN_Y, width=RING_WIDTH, bay=BAY_WIDTH),
    pavilions=[dict(tree=t, y=y, b=b, kind=k, who=w_, size=PAV_SIZE[k]) for t, y, b, k, w_ in PAVILIONS],
    public=PUBLIC, public_w=PUBLIC_W, decks=DECKS,
    bridges=BR, bridge_y=BRIDGE_Y,
    ground=[dict(key=k, name=n, who=w_, c=c, w=w, d=d, yaw=y, kind=kd) for k, n, w_, c, w, d, y, kd in GROUND],
    landmarks=LANDMARKS, flat=FLAT_RADIUS, safe=SAFE_RADIUS, foliage_clear=FOLIAGE_CLEAR,
    trunk_r_fn='0.045h at the base to 0.02h at 0.86h', problems=[list(map(str, p)) for p in problems])
if '--json' in sys.argv:
    json.dump(data, open(sys.argv[sys.argv.index('--json') + 1], 'w'))
print('commons %.0f m2 gross, %.0f net of wells, deck %.0f m2 with the inn lobe; grand spiral %.0f deg round its column (%.1f m a turn); %d bearers, %d deck limbs, %d commons limbs, %d posts; bridges %s; %d problems' % (
    A, A_NET, DECK.area, G_TURN, GRAND['turn_rise'], len(SUPPORT['bearers']), len(SUPPORT['limbs']), len(SUPPORT['commons_limbs']), len(POSTS), ', '.join('%s-%s %.1f m' % (b['a'], b['b'], b['span']) for b in BR), len(problems)))
if problems: sys.exit(1)
