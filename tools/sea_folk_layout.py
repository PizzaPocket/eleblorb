"""Authoring tool for the sea folk city's plan (docs/architecture/ocean_sea_folk_city_layout.md
and ocean_sea_folk_city_buildings.md). It holds the rings, the avenues, the
air halls and glass tunnels, every building and home, and the guest hall's
rooms, checks them, and writes scripts/sea_folk_plan.gd, the one plan the city
builder and tools/validate_sea_folk_plan.tscn read.

    python3 tools/sea_folk_layout.py [--json out.json]

Edit here, never in sea_folk_plan.gd. Local metres from the city centre at
world (0, -540); x and z follow the world axes, so +z faces the islands and the
arrival dock. Bearings are degrees from +x toward +z (as ocean_kingdom_city.gd
measures them), so the main avenue runs at 90. Heights are metres above the
city floor, 72 m down.
"""
import json, math, os, sys

CENTER = (0.0, -540.0)
FLOOR_Y = -72.0
FLAT_RADIUS = 105.0

## The rings (layout 3): Plato's concentric city. They are circles by design:
## Atlantis's civic geometry. The gardens and the edge beyond are not.
RINGS = {
    'mound': (0.0, 24.0),      # the castle, raised 2 m
    'civic': (24.0, 46.0),     # air halls, the Lamp House, the school court, light pipes
    'current': (46.0, 52.0),   # the Ring Current, 2 m below the civic ring, running clockwise
    'homes': (52.0, 90.0),     # two rows of homes and the ring path between them
    'gardens': (90.0, 105.0),  # kelp, sea flowers, the Reef House workshop
}
HOME_ROWS = (60.0, 82.0)
RING_PATH = 71.0               # the swimming path between the two rows of homes
AVENUES = [b * 45.0 for b in range(8)]   # eight sunken avenues, the main one at 90
AVENUE_WIDTH = 4.0
MAIN_AVENUE = 90.0
CLEAR = 3.0                    # swimmers' clearance between buildings

def at(r, bearing):
    t = math.radians(bearing)
    return (round(r * math.cos(t), 3), round(r * math.sin(t), 3))
def bearing_of(p): return math.degrees(math.atan2(p[1], p[0])) % 360
def circle(c, r, n=32): return [(round(c[0] + r * math.cos(2 * math.pi * k / n), 3), round(c[1] + r * math.sin(2 * math.pi * k / n), 3)) for k in range(n)]
def orect(c, along, across, facing):
    """A rectangle `along` m wide (tangential) and `across` m deep, centred at c,
    its front facing bearing `facing` (degrees)."""
    t = math.radians(facing); f = (math.cos(t), math.sin(t)); s = (-f[1], f[0])
    out = []
    for a, d in [(-along / 2, -across / 2), (along / 2, -across / 2), (along / 2, across / 2), (-along / 2, across / 2)]:
        out.append((round(c[0] + s[0] * a + f[0] * d, 3), round(c[1] + s[1] * a + f[1] * d, 3)))
    return out

## Civic buildings (layout 5 and 6, second pass). The Exchange stands beside the
## main avenue, not on it, so the castle's door looks straight down the avenue
## to the arrivals; the guest hall is 20 m across so its rooms fit at world scale.
DOMES = [  # key, name, keeper, bearing, radius from centre, dome diameter, dome height
    ('exchange', 'The Exchange', 'Maresa', 69.0, 34.0, 18.0, 9.0),
    ('guest_hall', 'The guest hall', 'Isaro', 22.5, 35.0, 20.0, 8.5),
    ('glassworks', 'The Glassworks', 'Kunei and Damaku', 90.0, 118.0, 16.0, 8.0),
]
WET = [  # key, name, who, centre, along, across, facing bearing, ring
    ('lamp_house', 'Lamp House', ['Lunira', 'Korasi', 'Mira'], at(34.0, 112.5), 12.0, 10.0, 112.5 + 180, 'civic'),
    ('school_court', 'School court', ['Munaja (teaches)'], at(34.0, 157.5), 16.0, 12.0, 157.5 + 180, 'civic'),
    ('reef_house', 'Reef House workshop', ['Talisa', 'Arimu', 'Kaluja'], at(97.0, 202.5), 12.0, 9.0, 202.5 + 180, 'gardens'),
]
CASTLE = dict(key='tidehall', name='Tidehall', who=['Tidekeeper Asaru', 'Ikara', 'Tudaro'], size=(34.0, 30.0), facing=90.0, mound=24.0)
LOOKOUT = dict(key='lookout', name='Kraken lookout', who=['Ikara (watches)'], at=at(104.0, 112.0), size=5.0, height=14.0)
## Light pipes stand on the civic ring between avenues, clear of every building.
LIGHT_PIPES = [at(40.0, b) for b in (202.5, 247.5, 292.5, 337.5)]
LIGHT_PIPE_DIAMETER = 1.6
## The warm vent that heats the Glassworks, at the head of the main avenue.
VENT = at(124.0, 90.0)

## Homes (layout 6): household, type, row, bearing. Types (buildings 2):
## single 8 x 7, double 11 x 7, workshop 10 x 8 (along x across). Each faces the
## ring path between the rows: the inner row outward, the outer row inward.
HOME_TYPES = {'single': (8.0, 7.0), 'double': (11.0, 7.0), 'workshop': (10.0, 8.0)}
HOMES = [
    ('Garden House', 'double', 0, 12.0, ['Nesaja']),
    ('Garden House', 'double', 0, 33.0, ['Rodasu']),
    ('Garden House', 'double', 0, 327.0, ['Kasuno', 'Tami']),
    ('Exchange', 'single', 0, 146.0, ['Maresa']),
    ('Exchange', 'single', 0, 157.5, ['Pelaju']),
    ('Exchange', 'single', 0, 169.0, ['Sujira']),
    ('Lamp House', 'workshop', 0, 112.5, ['Lunira', 'Korasi', 'Mira']),
    ('Current House', 'double', 1, 193.0, ['Oruko']),
    ('Current House', 'double', 1, 213.0, ['Dakuro']),
    ('Current House', 'double', 1, 237.0, ['Sekira']),
    ('Current House', 'double', 1, 257.0, ['Munaja']),
    ('Reef House', 'single', 1, 280.0, ['Talisa']),
    ('Reef House', 'single', 1, 292.0, ['Arimu']),
    ('Reef House', 'single', 1, 304.0, ['Kaluja']),
    ('Glassworks', 'workshop', 1, 66.0, ['Kunei']),
    ('Glassworks', 'workshop', 1, 76.0, ['Damaku']),
]

## Glass tunnels (layout 5): centre lines; the network is one pressurised volume.
TUNNEL_WIDTH = 4.5
TUNNEL_FLOOR = 3.0  # metres above the city floor, so swimmers pass beneath
def arc(r, b0, b1, n=10): return [at(r, b0 + (b1 - b0) * k / n) for k in range(n + 1)]
TUNNELS = [
    ('civic tunnel', arc(34.5, 60.5, 32.0)),
    ('avenue tunnel', [at(42.0, 75.5), (8.6, 48.0), (7.4, 60.0), (7.0, 71.0), (6.6, 84.0), (5.8, 98.0), (4.0, 110.0)]),
]
TUNNEL_JUNCTIONS = [(7.0, 71.0)]  # a moon pool between the rows of homes

## The guest hall's rooms (buildings 2, second pass): a ring of rooms under the
## dome round a common room and the moon pool, sized at world scale. Each room:
## name, kind, radial depth, arc width at its inner face.
GUEST_ROOMS = [('party room', 'bed2', 3.4, 6.0), ('guest room', 'bed2', 3.4, 3.6), ('guest room', 'bed2', 3.4, 3.6),
               ('guest room', 'bed2', 3.4, 3.6), ('washroom', 'bath', 3.4, 2.4), ('Isaro\'s room', 'bed1', 3.4, 3.2)]
MOON_POOL = 4.0
RAMP_RUN = 2.4       # from the pool's surface up to the floor
DOME_EXPONENT = 3.0  # the shell's profile: h = H (1 - (r/R)^n)^(1/n)
HEADROOM = 2.4

RESIDENTS = ['Tidekeeper Asaru', 'Ikara', 'Tudaro', 'Kunei', 'Damaku', 'Lunira', 'Korasi', 'Mira', 'Nesaja', 'Rodasu',
             'Kasuno', 'Tami', 'Maresa', 'Pelaju', 'Isaro', 'Sujira', 'Talisa', 'Arimu', 'Kaluja', 'Oruko', 'Dakuro',
             'Sekira', 'Munaja']

## Gardens beyond the homes: kelp groves and sea-flower beds as organic patches.
def blob(c, r, seed, n=9):
    pts = []
    for k in range(n):
        t = 2 * math.pi * k / n
        rr = r * (0.78 + 0.22 * math.sin(seed * 1.7 + k * 2.3) + 0.08 * math.cos(seed + k * 4.1))
        pts.append((round(c[0] + rr * math.cos(t), 2), round(c[1] + rr * math.sin(t), 2)))
    return pts
KELP = [blob(at(97.5, b), 6.5, i, 14) for i, b in enumerate((20, 58, 122, 150, 172, 232, 262, 312, 345))]
SEA_FLOWERS = [blob(at(96.0, b), 4.5, 10 + i, 12) for i, b in enumerate((5, 35, 330))]  # the warm east side
## The city's edge: the levelled shelf gives way to the natural floor and the
## reef, an irregular line, not a circle.
def edge_r(t): return FLAT_RADIUS + 7 + 5 * math.sin(3 * t + 0.6) + 3 * math.cos(5 * t + 1.9) + 2 * math.sin(8 * t)
EDGE = [(round(edge_r(2 * math.pi * k / 120) * math.cos(2 * math.pi * k / 120), 2), round(edge_r(2 * math.pi * k / 120) * math.sin(2 * math.pi * k / 120), 2)) for k in range(120)]

# ---- assemble every footprint
items = []  # key, name, kind, ring, polygon, who, extra
for key, name, keeper, b, r, d, h in DOMES:
    c = at(r, b)
    items.append(dict(key=key, name=name, kind='air hall', ring='edge' if r > FLAT_RADIUS else 'civic', centre=c, poly=circle(c, d / 2),
                      who=[keeper], extra=dict(diameter=d, height=h, plinth=3.0, moon_pool=MOON_POOL)))
for key, name, who, c, along, across, facing, ring in WET:
    items.append(dict(key=key, name=name, kind='wet', ring=ring, centre=c, poly=orect(c, along, across, facing), who=who,
                      extra=dict(along=along, across=across, facing=facing)))
items.append(dict(key='tidehall', name='Tidehall', kind='castle', ring='mound', centre=(0.0, 0.0),
                  poly=orect((0.0, 0.0), CASTLE['size'][0], CASTLE['size'][1], CASTLE['facing']), who=CASTLE['who'],
                  extra=dict(facing=CASTLE['facing'], mound=CASTLE['mound'])))
items.append(dict(key='lookout', name='Kraken lookout', kind='wet', ring='edge', centre=LOOKOUT['at'],
                  poly=circle(LOOKOUT['at'], LOOKOUT['size'] / 2, 12), who=LOOKOUT['who'], extra=dict(height=LOOKOUT['height'])))
for i, (house, typ, row, b, who) in enumerate(HOMES):
    r = HOME_ROWS[row]; c = at(r, b); along, across = HOME_TYPES[typ]
    facing = b if row == 0 else b + 180.0
    items.append(dict(key='home_%02d' % (i + 1), name='%s home' % house, kind='home', ring='homes', centre=c,
                      poly=orect(c, along, across, facing), who=who, extra=dict(type=typ, row=row, bearing=b, facing=facing % 360, household=house)))
for i, p in enumerate(LIGHT_PIPES):
    items.append(dict(key='light_pipe_%d' % (i + 1), name='Light pipe', kind='light pipe', ring='civic', centre=p,
                      poly=circle(p, LIGHT_PIPE_DIAMETER / 2, 10), who=['Kaluja (keeps)'], extra={}))

# ---- geometry
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
def edges(poly, closed=True): return list(zip(poly, poly[1:] + poly[:1])) if closed else list(zip(poly, poly[1:]))
def dist(P, Q, qclosed=True):
    for e in edges(P):
        for f in edges(Q, qclosed):
            if segs_cross(e[0], e[1], f[0], f[1]): return 0.0
    if any(inside(p, P) for p in Q) or (qclosed and any(inside(p, Q) for p in P)): return 0.0
    return min(min(seg_dist(p, *f) for f in edges(Q, qclosed)) for p in P + ([] if not qclosed else [])) if qclosed else \
        min(min(seg_dist(p, *f) for f in edges(Q, False)) for p in P)
def dist2(P, Q, qclosed=True): return min(dist(P, Q, qclosed), min(seg_dist(q, *e) for q in Q for e in edges(P)))
def radii(poly): return min(math.hypot(*p) for p in poly), max(math.hypot(*p) for p in poly)
def avenue_line(b): return [at(RINGS['mound'][1], b), at(FLAT_RADIUS, b)]

problems = []
by_key = {it['key']: it for it in items}
for it in items:
    lo, hi = radii(it['poly'])
    ring = it['ring']
    if ring == 'edge':
        if hi > FLAT_RADIUS + 25: problems.append((it['key'], 'stands too far beyond the city'))
    elif ring != 'mound':
        r0, r1 = RINGS[ring]
        if lo < r0 - 0.01 or hi > r1 + 0.01: problems.append((it['key'], 'reaches out of the %s ring (%.1f to %.1f m)' % (ring, lo, hi)))
    if ring != 'mound':
        # the Ring Current stays open water; nothing but tunnels crosses it
        if lo < RINGS['current'][1] and hi > RINGS['current'][0]: problems.append((it['key'], 'stands in the Ring Current'))
        for b in AVENUES:
            if dist2(it['poly'], avenue_line(b), False) < AVENUE_WIDTH / 2 + 1.0:
                problems.append((it['key'], 'stands in the avenue at %g' % b))
# the castle's door looks straight down the main avenue
if CASTLE['facing'] != MAIN_AVENUE: problems.append(('tidehall', 'does not face the main avenue'))
for i in range(len(items)):
    for j in range(i + 1, len(items)):
        g = dist2(items[i]['poly'], items[j]['poly'])
        if g < CLEAR - 0.01: problems.append((items[i]['key'], items[j]['key'], 'only %.1f m apart' % g))
# tunnels: clear of everything but the air halls they join
for name, line in TUNNELS:
    for it in items:
        if it['kind'] == 'air hall': continue
        if dist2(it['poly'], line, False) < TUNNEL_WIDTH / 2 + 1.0: problems.append((name, 'runs into', it['key']))
    ends = [k for k, *_ in DOMES if dist2(by_key[k]['poly'], [line[0], line[-1]], False) < 1.5]
    if len(ends) < 2: problems.append((name, 'does not join two air halls', ends))
# the guest hall's rooms fit under its dome at world scale
gh = by_key['guest_hall']; R = gh['extra']['diameter'] / 2; H = gh['extra']['height']
def clear_height(r): return H * max(0.0, 1 - (r / R) ** DOME_EXPONENT) ** (1 / DOME_EXPONENT)
outer = R - 0.3
depth = GUEST_ROOMS[0][2]
inner = outer - depth
if clear_height(outer) < HEADROOM: problems.append(('guest_hall', 'rooms have under %g m headroom at the wall' % HEADROOM))
if sum(w for *_, w in GUEST_ROOMS) + 0.2 * len(GUEST_ROOMS) > 2 * math.pi * inner - 4.0:
    problems.append(('guest_hall', 'rooms do not fit round the dome'))
# the ramp rises out of the pool onto the common room floor: between the
# pool's edge and the rooms there must be room for the ramp and a 1.4 m landing
common = inner - 0.2 - MOON_POOL / 2
if common < RAMP_RUN + 1.4: problems.append(('guest_hall', 'only %.1f m between the moon pool and the rooms' % common))
MIN_ROOM = {'bed2': (3.2, 3.4), 'bed1': (3.0, 3.2), 'bath': (1.4, 1.8)}
for name, kind, d, w in GUEST_ROOMS:
    lo_, hi_ = MIN_ROOM[kind]
    if min(d, w) < lo_ or max(d, w) < hi_: problems.append(('guest_hall', name, 'too small'))
for r in RESIDENTS:
    if not any(w.startswith(r) for it in items for w in it['who']): problems.append(('no building for', r))
if len([it for it in items if it['kind'] == 'home']) != 16: problems.append(('there should be sixteen homes',))
if problems:
    for p in problems: print('PROBLEM', p)
    sys.exit(1)

# ---- write the plan
def q(t): return json.dumps(t, ensure_ascii=False)
def v2(p): return 'Vector2(%g, %g)' % tuple(p)
def pts(poly): return 'PackedVector2Array([%s])' % ', '.join(v2(p) for p in poly)
out = []; w_ = out.append
w_('class_name SeaFolkPlan')
w_('extends RefCounted')
w_('')
w_('## The sea folk city\'s single plan (docs/architecture/ocean_sea_folk_city_layout.md and')
w_('## ocean_sea_folk_city_buildings.md). GENERATED by tools/sea_folk_layout.py: edit there')
w_('## and rerun, never here. The city builder and tools/validate_sea_folk_plan.tscn')
w_('## read only this.')
w_('##')
w_('## Local metres from the city centre (x, z as the world\'s); +z faces the islands.')
w_('## Bearings are degrees from +x toward +z; the main avenue runs at 90.')
w_('')
w_('const CENTER := %s' % v2(CENTER))
w_('const FLOOR_Y := %g' % FLOOR_Y)
w_('const FLAT_RADIUS := %g' % FLAT_RADIUS)
w_('const RINGS := {%s}' % ', '.join('%s: %s' % (q(k), v2(v)) for k, v in RINGS.items()))
w_('const HOME_ROWS := %s' % v2(HOME_ROWS))
w_('const RING_PATH := %g' % RING_PATH)
w_('const AVENUES: Array[float] = [%s]' % ', '.join('%g' % b for b in AVENUES))
w_('const AVENUE_WIDTH := %g' % AVENUE_WIDTH)
w_('const MAIN_AVENUE := %g' % MAIN_AVENUE)
w_('const CLEAR := %g' % CLEAR)
w_('const VENT := %s' % v2(VENT))
w_('')
w_('## Every structure: key, name, kind (air hall, wet, castle, home, light pipe),')
w_('## ring, centre, footprint polygon, who, and kind-specific details.')
w_('const STRUCTURES := [')
for it in items:
    w_('\t{"key": %s, "name": %s, "kind": %s, "ring": %s, "centre": %s, "footprint": %s, "who": %s, "extra": %s},' % (
        q(it['key']), q(it['name']), q(it['kind']), q(it['ring']), v2(it['centre']), pts(it['poly']), q(it['who']), q(it['extra'])))
w_(']')
w_('')
w_('## Glass tunnels: name and centre line; one pressurised network with the air halls.')
w_('const TUNNEL_WIDTH := %g' % TUNNEL_WIDTH)
w_('const TUNNEL_FLOOR := %g' % TUNNEL_FLOOR)
w_('const TUNNELS := [')
for name, line in TUNNELS: w_('\t[%s, %s],' % (q(name), pts(line)))
w_(']')
w_('const TUNNEL_JUNCTIONS := %s' % pts(TUNNEL_JUNCTIONS))
w_('')
w_('## The guest hall\'s rooms round its dome: name, kind, radial depth, arc width.')
w_('const GUEST_ROOMS := [%s]' % ', '.join('[%s, %s, %g, %g]' % (q(n), q(k), d, w) for n, k, d, w in GUEST_ROOMS))
w_('const MOON_POOL := %g' % MOON_POOL)
w_('const RAMP_RUN := %g' % RAMP_RUN)
w_('const DOME_EXPONENT := %g' % DOME_EXPONENT)
w_('const HEADROOM := %g' % HEADROOM)
w_('')
w_('const KELP := [%s]' % ', '.join(pts(k) for k in KELP))
w_('const SEA_FLOWERS := [%s]' % ', '.join(pts(k) for k in SEA_FLOWERS))
w_('const EDGE := %s' % pts(EDGE))
w_('')
w_('const RESIDENTS: Array[String] = [%s]' % ', '.join(q(r) for r in RESIDENTS))
w_('')
w_('')
w_('static func to_world(local: Vector2) -> Vector2:')
w_('\treturn CENTER + local')
root = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..')
open(os.path.join(root, 'scripts', 'sea_folk_plan.gd'), 'w').write('\n'.join(out) + '\n')
if '--json' in sys.argv:
    path = sys.argv[sys.argv.index('--json') + 1]
    json.dump(dict(structures=items, tunnels=TUNNELS, junctions=TUNNEL_JUNCTIONS, rings=RINGS, avenues=AVENUES, home_rows=HOME_ROWS,
                   ring_path=RING_PATH, kelp=KELP, flowers=SEA_FLOWERS, edge=EDGE, vent=VENT, guest_rooms=GUEST_ROOMS),
              open(path, 'w'), ensure_ascii=False)
print('wrote scripts/sea_folk_plan.gd: %d structures, %d tunnels, %d residents' % (len(items), len(TUNNELS), len(RESIDENTS)))
