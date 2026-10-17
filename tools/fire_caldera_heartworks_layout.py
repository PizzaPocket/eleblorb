#!/usr/bin/env python3
"""The Caldera Heartworks: the lava vortex under the Fire Caldera's reservoir.

    python3 tools/fire_caldera_heartworks_layout.py [--json out.json] [--surface surface.json]

Writes scripts/fire_caldera_heartworks_plan.gd (FireCalderaHeartworksPlan). The design is
docs/architecture/fire_caldera_heartworks.md; the model is docs/drawings/fire_caldera_3d.html.

After Jewel Changi's Rain Vortex: one thick, perpetual cascade of lava falls from an oculus in the middle of
the reservoir's floor, through a glass dome, past stepped rim terraces, through an opening in the chamber's
floor, into the collection pool at the bottom. The only way in is through the lava: with the Lava Helm a
swimmer dives to the oculus and goes down with the cascade, and leaves by stepping into the pool and swimming
back up it. Inside, it is a public place: terraces round the rim, two crossings, ramps between every level.

Frame: FireCalderaPlan's local plan frame. Depths are metres below the lava's surface (world 29.2); a level's
datum is its world height. Its walkways use the same system as the surface (tools/walkway_kit.py).
"""
import json, math, os, re, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from shapely.geometry import Polygon, LineString, Point
from walkway_kit import Network, Flight, annulus, band, circle_pts, superellipse
from fire_caldera_frame import LAVA_Y, LOBES, RESERVOIR_MEAN, pol, brg
from gd_plan import write_plan


def wy(d): return round(LAVA_Y - d, 3)

# ---------------------------------------------------------------- the chamber
CHAMBER = dict(
    radius=48.0,                   # the rim wall
    oculus=7.0,                    # the opening in the reservoir's floor, with its refractory lip
    oculus_depth=7.0,              # the lip: the lava is 7 m deep over it
    springing=18.0,                # where the dome meets the rim wall
    floor=48.0,                    # the Floor's depth
    pool_gallery=58.0,             # the level round the pool, under the Floor
    pool_surface=58.8,             # the collection pool
    pool_radius=10.5,
    opening=16.0,                  # the Floor's opening round the cascade
    bottom=62.0,                   # the pool's floor
)
C = CHAMBER
# The dome: a spherical cap of refractory glass in a blackened-steel diagrid, carrying the reservoir's lava on
# its back, from the oculus's lip down to the rim wall. Its sphere passes through both.
_r0, _d0, _r1, _d1 = C['oculus'], C['oculus_depth'], C['radius'], C['springing']
DOME_CENTRE_DEPTH = round((_r1 ** 2 - _r0 ** 2 + _d1 ** 2 - _d0 ** 2) / (2 * (_d1 - _d0)), 3)
DOME_RADIUS = round(math.hypot(_r0, DOME_CENTRE_DEPTH - _d0), 3)
def dome_depth(r): return DOME_CENTRE_DEPTH - math.sqrt(DOME_RADIUS ** 2 - r * r)

# The cascade: a thick column falling from the whole circumference of the lip, narrowing as it accelerates.
CASCADE = dict(top_radius=6.0, bottom_radius=4.2, top_depth=C['oculus_depth'], bottom_depth=C['pool_surface'])

# ---------------------------------------------------------------- the levels: terraces stepping in as they go down
LEVELS = [
    dict(id='R3', name='Upper terrace', depth=24.0, edge=42.0),
    dict(id='R2', name='Middle terrace', depth=32.0, edge=37.0),
    dict(id='R1', name='Lower terrace', depth=40.0, edge=32.0),
    dict(id='F', name='The Floor', depth=C['floor'], edge=C['opening']),
    dict(id='P', name='Pool gallery', depth=C['pool_gallery'], edge=C['pool_radius'], outer=24.0),
]
net = Network('heartworks')
for L in LEVELS:
    outer = L.get('outer', C['radius'])
    net.level(L['id'], wy(L['depth']), 'basalt', L['name'])
    net.add(L['id'], annulus(L['edge'], outer, 720), L['name'])
    net.wall(L['id'], annulus(outer, outer + 12.0, 360))
    L['datum'] = wy(L['depth'])
LV = {L['id']: L for L in LEVELS}
# the pool gallery's inner edge is the pool's: a kerb to step over into the lava
net.open_edge('P', LineString(circle_pts(C['pool_radius'], 0, 360, 720)))


def below(x, y, lv):
    """The nearest surface under a level's edge: a lower level, or the pool."""
    r = math.hypot(x, y); best = wy(C['bottom'])
    for L in LEVELS:
        if L['datum'] < lv['datum'] - 0.01 and L['edge'] - 0.05 <= r <= L.get('outer', C['radius']) + 0.05:
            best = max(best, L['datum'])
    if r <= C['pool_radius'] + 0.05: best = max(best, wy(C['pool_surface']))
    return best
net.below = below

# ---------------------------------------------------------------- crossings
# Two bridges across the void on chords 14 m from the cascade's axis: the Middle Bridge on the far side, the
# Lower Bridge on the gate's side. From each the cascade is seen face-on, 8 m clear of it.
CROSSINGS = [dict(id='B2', level='R2', offset=14.0, toward=90.0, width=4.2, name='Middle Bridge'),
             dict(id='B1', level='R1', offset=14.0, toward=-90.0, width=4.2, name='Lower Bridge')]
for b in CROSSINGS:
    e = LV[b['level']]['edge'] + 1.0; half = math.sqrt(e * e - b['offset'] ** 2)
    ux, uy = pol(1, b['toward']); tx, ty = -uy, ux
    cx, cy = ux * b['offset'], uy * b['offset']
    b['ends'] = [[round(cx - tx * half, 3), round(cy - ty * half, 3)], [round(cx + tx * half, 3), round(cy + ty * half, 3)]]
    net.add(b['level'], band(b['ends'], b['width']), b['name'])

# ---------------------------------------------------------------- ramps
# Between the terraces, double ramps: from a balcony on the upper terrace's edge two ramps sweep apart along
# the void, mirrored, and land on the terrace below (the horseshoe stair of the Renewal deck, made gentle).
RAMP_GRADE = 1 / 6
DOUBLE_RAMPS = [dict(id='K32', upper='R3', lower='R2', bearing=-90.0), dict(id='K21', upper='R2', lower='R1', bearing=90.0),
                dict(id='K1F', upper='R1', lower='F', bearing=90.0)]
RAMP_WIDTH = 3.0


def arc(r, b0, b1, step=0.25):
    n = max(4, int(abs(math.radians(b1 - b0)) * r / step))
    return [pol(r, b0 + (b1 - b0) * i / n) for i in range(n + 1)]


def line(a, b, step=0.25):
    n = max(1, int(math.dist(a, b) / step))
    return [(a[0] + (b[0] - a[0]) * i / n, a[1] + (b[1] - a[1]) * i / n) for i in range(n + 1)]


def join(*parts):
    out = []
    for p in parts: out += p if not out else p[1:]
    return out


for K in DOUBLE_RAMPS:
    up, lo = LV[K['upper']], LV[K['lower']]
    r = (up['edge'] + lo['edge']) / 2                 # the ramp's line, over the lower terrace's open band
    drop = up['datum'] - lo['datum']; run = drop / RAMP_GRADE
    land = 2.0
    sweep = math.degrees((run + 2 * land) / r)
    # the balcony juts from the upper edge to the ramps' line; each ramp leaves its side, tangential
    half_ang = math.degrees(3.2 / r)
    balcony = Polygon(arc(up['edge'] + 1.0, K['bearing'] - half_ang - math.degrees(land / r), K['bearing'] + half_ang + math.degrees(land / r))
                      + arc(r - RAMP_WIDTH / 2, K['bearing'] + half_ang + math.degrees(land / r), K['bearing'] - half_ang - math.degrees(land / r)))
    net.add(K['upper'], balcony, K['id'] + ' balcony')
    K['flights'] = []
    for s in (1, -1):
        b0 = K['bearing'] + s * half_ang
        path = arc(r, b0, b0 + s * sweep)
        f = Flight(K['id'] + ('a' if s > 0 else 'b'), K['upper'], K['lower'], path, RAMP_WIDTH, 'ramp', landing=(land, land),
                   note='%s to %s' % (up['name'], lo['name']))
        net.flight(f); K['flights'].append(f.id)
    K['radius'], K['sweep'] = round(r, 3), round(sweep, 2)

# Floor to pool gallery: a double helix round the cascade, inside the Floor's opening (after Chambord's stair):
# two ramps half a turn apart, each leaving the opening's edge and winding down to the pool gallery.
HELIX = dict(radius=12.8, width=3.0, starts=[0.0, 180.0])
fl, pg = LV['F'], LV['P']
drop = fl['datum'] - pg['datum']; run = drop / RAMP_GRADE
for i, b0 in enumerate(HELIX['starts']):
    # a level gangway from the Floor, tangent to the helix, then the turn about the cascade's axis
    p1 = pol(HELIX['radius'], b0); tx, ty = pol(1, b0 + 90.0)
    reach = math.sqrt((fl['edge'] + 1.0) ** 2 - HELIX['radius'] ** 2)
    p0 = (p1[0] - tx * reach, p1[1] - ty * reach)
    turn = math.degrees(run / HELIX['radius'])
    path = join(line(p0, p1), arc(HELIX['radius'], b0, b0 + turn + math.degrees(2.0 / HELIX['radius'])))
    f = Flight('KF' + 'ab'[i], 'F', 'P', path, HELIX['width'], 'ramp', landing=(reach, 2.0), note='the double helix, ramp %s' % 'ab'[i])
    net.flight(f)
HELIX['turn'] = round(turn, 1)

# ---------------------------------------------------------------- checks
net.solve(); net.check(max_grade=0.18)
F = net.fails
def ok(m): print('ok  ', m)
# the cascade stays clear of every walk, by heat: 5 m at least
def cascade_r(y):
    t = min(1, max(0, (wy(CASCADE['top_depth']) - y) / (CASCADE['bottom_depth'] - CASCADE['top_depth'])))
    return CASCADE['top_radius'] + (CASCADE['bottom_radius'] - CASCADE['top_radius']) * t
for lv in net.levels.values():
    d = lv['surface'].distance(Point(0, 0)) - cascade_r(lv['datum'])
    if d < 5.0: F.append('%s is %.1f m from the cascade' % (lv['id'], d))
for f in net.flights:
    d = f.line.buffer(f.width / 2).distance(Point(0, 0)) - cascade_r(net.levels[f.lower]['datum'])
    if d < 5.0: F.append('%s is %.1f m from the cascade' % (f.id, d))
ok('every walk 5 m or more from the cascade')
# headroom: nothing walkable passes under another walk or a level by less than 2.4 m
items = []
for lv in net.levels.values(): items.append((lv['id'], lv['surface'], lambda s, y=lv['datum']: y))
for f in net.flights:
    items.append((f.id, f.line.buffer(f.width / 2, cap_style=2), None))
def height_at(name, x, y):
    for f in net.flights:
        if f.id == name:
            return f.height(f.line.project(Point(x, y)), net.levels[f.upper]['datum'], net.levels[f.lower]['datum'])
    return net.levels[name]['datum']
for i in range(len(items)):
    for j in range(len(items)):
        if i == j: continue
        a, b = items[i], items[j]
        inter = a[1].intersection(b[1])
        if inter.area < 0.5: continue
        for pt in [inter.representative_point()] + [Point(c) for c in list(getattr(inter, 'exterior', inter.envelope.exterior).coords)[::7]]:
            ya, yb = height_at(a[0], pt.x, pt.y), height_at(b[0], pt.x, pt.y)
            gap = ya - yb - 0.6   # a deck's depth
            if 0 < ya - yb and gap < 2.4:
                own = any(f.id in (a[0], b[0]) and {f.upper, f.lower} & {a[0], b[0]} for f in net.flights)
                if not own: F.append('%s passes %.1f m over %s' % (a[0], gap, b[0])); break
ok('2.4 m or more of headroom under every walk')
for f in net.flights:
    ok('%-5s %5.1f m at %4.1f%%  %s' % (f.id, f.slope.length, f.grade(net.levels[f.upper]['datum'], net.levels[f.lower]['datum']) * 100, f.note))
for lv in net.levels.values():
    ok('level %-2s %-15s Y %6.2f  %d guard runs' % (lv['id'], lv['note'], lv['datum'], len(lv['guards'])))
if F:
    print('\n'.join('FAIL ' + m for m in F)); sys.exit(1)

# ---------------------------------------------------------------- write
data = net.data()
SECTION = dict(lava_y=LAVA_Y, chamber=CHAMBER, dome=dict(centre_depth=DOME_CENTRE_DEPTH, radius=DOME_RADIUS), cascade=CASCADE,
               levels=[{k: v for k, v in L.items()} for L in LEVELS], crossings=CROSSINGS,
               double_ramps=[{k: v for k, v in K.items()} for K in DOUBLE_RAMPS], helix=HELIX, ramp_grade=round(RAMP_GRADE, 4))
HEADER = ['The Caldera Heartworks (docs/architecture/fire_caldera_heartworks.md): one lava cascade from an oculus in',
          'the reservoir\'s floor, a glass dome, stepped rim terraces, two crossings, ramps between every level, the',
          'Floor round the cascade and the pool gallery under it. Its only way in is through the lava.',
          'Frame: FireCalderaPlan\'s local plan frame; depths below FireCalderaGround.LAVA_Y; datums are world Y.',
          'Status: proposed for review. It supersedes FireCalderaPlan\'s HEARTWORKS and lower-city constants.']
write_plan('FireCalderaHeartworksPlan', 'fire_caldera_heartworks_plan.gd', HEADER,
           dict(SECTION=('# the chamber, the dome, the cascade, the levels, crossings and ramps', SECTION),
                LEVELS=('# one surface per level: outline and holes, guard lines', data['levels']),
                FLIGHTS=('# every ramp: centreline profile [x, Y, y] and guard lines', data['flights'])),
           'tools/fire_caldera_heartworks_layout.py')

# The model shows the surface beside the chamber: the Godot export of FireCalderaPlan (--surface), or what the
# page already embeds, and the walkway plan (tools/fire_caldera_walkways_layout.py --json, passed as --walkways).
PAGE = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'docs', 'drawings', 'fire_caldera_3d.html')
RETIRED_ROUTES = {'H5'}
if '--json' in sys.argv:
    if '--surface' in sys.argv:
        surface = json.load(open(sys.argv[sys.argv.index('--surface') + 1]))
    else:
        m = re.search(r'/\*DATA\*/(.*?)/\*END\*/', open(PAGE).read(), re.S)
        old = json.loads(m.group(1)) if m else {}
        surface = old.get('surface', old)
    surface = {k: surface[k] for k in ('frame', 'reservoir', 'terrain', 'plots', 'routes') if k in surface}
    surface['routes'] = [r for r in surface.get('routes', []) if r['id'] not in RETIRED_ROUTES]
    walk = json.load(open(sys.argv[sys.argv.index('--walkways') + 1])) if '--walkways' in sys.argv else {}
    json.dump(dict(surface=surface, walkways=walk.get('walkways'), site=walk.get('site'), heart=dict(section=SECTION, walk=data),
                   lobes=LOBES, reservoir_mean=RESERVOIR_MEAN), open(sys.argv[sys.argv.index('--json') + 1], 'w'), separators=(',', ':'))
print('wrote scripts/fire_caldera_heartworks_plan.gd: %d levels, %d crossings, %d ramps' % (len(LEVELS), len(CROSSINGS), len(net.flights)))
