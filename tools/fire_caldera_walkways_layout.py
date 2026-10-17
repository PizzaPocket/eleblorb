#!/usr/bin/env python3
"""The Fire Caldera's public walkways above the lava, as one system, and the funicular up to the gate.

    python3 tools/fire_caldera_walkways_layout.py [--json out.json]

Writes scripts/fire_caldera_walkways_plan.gd (FireCalderaWalkwaysPlan). The design is
docs/architecture/fire_caldera_walkways.md; the model is docs/drawings/fire_caldera_3d.html.

Four tiers, each one level surface at one datum, joined only by flights (tools/walkway_kit.py):

  gate       48.5  the Gate Terrace on the crater lip: the Tempering Gate, the inn's porch, the funicular's top
  highline   42.5  the Highline ring, the docked buildings' porches, the refuge bridges, the stair heads
  promenade  30.0  the lava promenade, the ground buildings' forecourts and the Renewal deck
  and the small private levels flights reach: Oren's roof terrace (38.0), Oren's and Kel's service yards.

Frame: FireCalderaPlan's local plan frame (tools/fire_caldera_frame.py). Heights are world Y.
"""
import json, math, os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from shapely.geometry import Polygon, LineString, Point
from shapely.ops import unary_union
from walkway_kit import Network, Flight, superellipse, annulus, band, circle_pts, polys
from fire_caldera_frame import (PLOT, PLOTS, LAVA_Y, HIGHLINE_RADIUS, HIGHLINE_WIDTH, HIGHLINE_DATUM, REVEAL, bank, bowl_y, flank_y,
                                pol, brg, adiff, facing, shell_to_plan, plan_to_shell, shell_turn)
from gd_plan import write_plan

GATE_DATUM = 48.5          # the crater lip under the Tempering Gate, half a metre up
PROMENADE_DATUM = 30.0     # FireCalderaPlan.FLOOR_Y: the bank's shoulder; every ground door meets it
OREN_ROOF = 38.0           # Oren's roof terrace: its datum + FireCalderaOren.UPPER + roof_top()
OREN_YARD = 31.35          # Oren's workshop floor, its receiving door
KEL_YARD = 31.15           # Kel's loading dock
RAMP_MAX = 0.18            # the steepest public ramp
STAIR_PITCH = 0.68         # 34 degrees: a grand stair's rise over run

HL_IN, HL_OUT = HIGHLINE_RADIUS - HIGHLINE_WIDTH / 2, HIGHLINE_RADIUS + HIGHLINE_WIDTH / 2

net = Network('surface')


def ground_below(x, y, lv=None):
    """What lies under a point: lava inside the bank, the bowl, or the outer flank."""
    r, b = math.hypot(x, y), brg(x, y)
    if r < bank(b): return LAVA_Y
    return bowl_y(r) if r <= 112 else flank_y(r)
net.below = ground_below


def platform(p, key='foundation'):
    """A plot's SocketPlinth platform: the superellipse of its foundation plus the reveal."""
    hx, hy = p[key][0] / 2 + REVEAL, p[key][1] / 2 + REVEAL
    return superellipse(*p['centre'], hx, hy, 10.0, shell_turn(p), 160)


def walls_of(p, grow=0.0):
    return superellipse(*p['centre'], p['footprint'][0] / 2 + grow, p['footprint'][1] / 2 + grow, 10.0, shell_turn(p), 160)


def frame_rect(p, x0, x1, z0, z1):
    return Polygon([shell_to_plan(p, q) for q in [(x0, z0), (x1, z0), (x1, z1), (x0, z1)]])


def frame_line(p, pts):
    return [shell_to_plan(p, q) for q in pts]


def arc_path(start, heading_deg, radius, turn_deg, step=0.25):
    """Points along an arc leaving `start` on `heading`, turning left (+) or right (-) by turn_deg."""
    h = math.radians(heading_deg); sgn = 1 if turn_deg > 0 else -1
    cx, cy = start[0] - math.sin(h) * radius * sgn, start[1] + math.cos(h) * radius * sgn
    a0 = math.atan2(start[1] - cy, start[0] - cx)
    n = max(4, int(abs(math.radians(turn_deg)) * radius / step))
    return [(cx + radius * math.cos(a0 + math.radians(turn_deg) * i / n), cy + radius * math.sin(a0 + math.radians(turn_deg) * i / n)) for i in range(n + 1)]


def line_path(a, b, step=0.25):
    n = max(1, int(math.dist(a, b) / step))
    return [(a[0] + (b[0] - a[0]) * i / n, a[1] + (b[1] - a[1]) * i / n) for i in range(n + 1)]


def join(*parts):
    out = []
    for p in parts:
        out += p if not out else p[1:]
    return out

# ===================================================================== the Gate Terrace (48.5)
net.level('gate', GATE_DATUM, 'basalt', 'the Gate Terrace on the crater lip: the Tempering Gate, the inn porch, the funicular top')
GATE_TERRACE = dict(centre=(4.0, -115.0), half=(14.0, 5.0), exponent=6.0)
terrace = superellipse(*GATE_TERRACE['centre'], *GATE_TERRACE['half'], GATE_TERRACE['exponent'], 0.0, 160)
net.add('gate', terrace, 'terrace')
GUEST = PLOT['GUEST']
net.add('gate', platform(GUEST), 'inn porch')
net.wall('gate', walls_of(GUEST))
INN_BRIDGE = [(15.5, -113.0), (15.5, -106.5)]
net.add('gate', band(INN_BRIDGE, 3.0), 'inn bridge')
TEMPERING_GATE = dict(at=(0.0, -114.6), span=6.8, height=10.0, pylon=0.9)

# ===================================================================== the Highline (42.5)
net.level('highline', HIGHLINE_DATUM, 'glass', 'the Highline ring and everything level with it')
net.add('highline', annulus(HL_IN, HL_OUT, 1440), 'ring')
DOCKS = ['NAHL', 'VARA', 'CIVIC', 'IREN']
for d in DOCKS:
    net.add('highline', platform(PLOT[d]), 'porch ' + d)
    net.wall('highline', walls_of(PLOT[d]))
# Iren's glazed bridge to Civic: an enclosed corridor at the same level (iren.gd), so its sides are glazing, not guards
ip, cp = platform(PLOT['IREN']), platform(PLOT['CIVIC'])
from shapely.ops import nearest_points
a, b = nearest_points(ip, cp)
IREN_BRIDGE = [(a.x + (a.x - b.x) * 0.05, a.y + (a.y - b.y) * 0.05), (b.x + (b.x - a.x) * 0.05, b.y + (b.y - a.y) * 0.05)]
ib = band(IREN_BRIDGE, 2.4)
net.add('highline', ib, 'Iren bridge')
for s in (1, -1):
    tx, ty = b.x - a.x, b.y - a.y; n = math.hypot(tx, ty); nx, ny = -ty / n * 1.2 * s, tx / n * 1.2 * s
    net.open_edge('highline', LineString([(a.x + nx, a.y + ny), (b.x + nx, b.y + ny)]))
# refuge bridges to the emergency shelves (FireCalderaPlan.emergency_spokes E1-E3)
REFUGES = []
for rid, b_ in (('E1', -175.0), ('E2', 65.0), ('E3', 155.0)):
    pad_r = 103.5
    net.add('highline', band([pol(HL_OUT - 1.0, b_), pol(pad_r - 2.0, b_)], 3.5), 'refuge bridge ' + rid)
    cx, cy = pol(pad_r, b_)
    net.add('highline', superellipse(cx, cy, 3.5, 5.0, 6.0, math.radians(b_), 96), 'refuge ' + rid)
    REFUGES.append(dict(id=rid, bearing=b_, pad=[round(cx, 3), round(cy, 3)], ground=round(bowl_y(pad_r), 2)))

# ===================================================================== the promenade tier (30.0)
net.level('promenade', PROMENADE_DATUM, 'basalt', 'the lava promenade, the ground forecourts and the Renewal deck')
GROUND = ['OREN', 'KEL', 'ARO']
PROM_WIDTH, PROM_KERB, FORECOURT_MIN = 4.0, 0.6, 1.5


def facade_radius(p, b):
    """Where a bearing's ray meets a ground building's front plane (or None)."""
    dx, dy = facing(p); ux, uy = pol(1, b); den = -(ux * dx + uy * dy)   # the ray runs outward, against the facing
    if den <= 0.15: return None
    cx, cy = p['centre']; front = -(cx * dx + cy * dy) - p['footprint'][1] / 2
    r = front / den; qx, qy = ux * r, uy * r
    lat = abs((qx - cx) * -dy + (qy - cy) * dx)
    return r if lat <= p['footprint'][0] / 2 + 3.0 else None


raw = []
for i in range(720):
    b = i / 2.0
    c = bank(b) + PROM_KERB + PROM_WIDTH / 2
    for g in GROUND:
        fr = facade_radius(PLOT[g], b)
        if fr is not None: c = min(c, fr - FORECOURT_MIN - PROM_WIDTH / 2)
    raw.append(c)
# a running minimum then a running mean: it eases round a frontage instead of stepping
W = 8
lo = [min(raw[(i + k) % 720] for k in range(-W, W + 1)) for i in range(720)]
cl = [sum(lo[(i + k) % 720] for k in range(-W, W + 1)) / (2 * W + 1) for i in range(720)]
PROM_CENTRE = [round(c, 3) for c in cl]
outer = [pol(c + PROM_WIDTH / 2, i / 2.0) for i, c in enumerate(cl)]
inner = [pol(c - PROM_WIDTH / 2, i / 2.0) for i, c in enumerate(cl)]
promenade = Polygon(outer, [inner]).buffer(0)
lava_side = Polygon(inner).buffer(0)
net.add('promenade', promenade, 'promenade')
LANE_SIDE = {}
FORECOURTS = {}
for g in GROUND:
    p = PLOT[g]; hx, hz = p['footprint'][0] / 2, p['footprint'][1] / 2
    fc = frame_rect(p, -hx - 1.5, hx + 1.5, hz - 0.5, hz + 14.0).difference(lava_side)
    FORECOURTS[g] = fc
    net.add('promenade', fc, 'forecourt ' + g)
    net.wall('promenade', walls_of(p))

# The Renewal deck, enlarged a little so the horseshoe stair's feet land on it, level with the promenade
REN = PLOT['RENEWAL']
RENEWAL_DECK = dict(half=(11.6, 9.2), exponent=7.0)
deck = superellipse(*REN['centre'], *RENEWAL_DECK['half'], RENEWAL_DECK['exponent'], shell_turn(REN), 192)
net.add('promenade', deck, 'Renewal deck')
CANOPY = dict(span=17.0, crown=6.2, spring=3.0, back=-6.6, front=6.2)   # FireCalderaRenewal, in its own frame
IMMERSION_TONGUE = dict(width=8.0, start=(0.0, 8.6), length=14.0, drop=2.4)  # its frame: from the deck's lava edge down into the lava

# ===================================================================== flights
# --- the arrival gallery: the Gate Terrace's north edge down to the Highline's outer edge, on the axis
gallery_top = (0.0, -111.5)
# its top landing reaches 1.5 m out from the terrace's edge; its foot is a mouth cut in the ring's outer edge
gallery = Flight('H0', 'gate', 'highline', line_path(gallery_top, (0.0, -72.4)), 3.8, 'ramp', landing=(3.0, 2.0),
                 note='the arrival gallery, on the gate-to-Civic axis')
net.flight(gallery)


# --- Renewal: a horseshoe stair, two flights from one landing on the Highline round either side of the canopy
def ring_z(x):
    """Where the Highline's inner edge crosses a line x = const in Renewal's frame (its back side)."""
    lo_, hi_ = -30.0, 0.0
    for _ in range(60):
        m = (lo_ + hi_) / 2
        q = shell_to_plan(REN, (x, m))
        if math.hypot(*q) > HL_IN: lo_ = m
        else: hi_ = m
    return (lo_ + hi_) / 2

HS = dict(width=2.2, balcony_half=4.0, radius=6.0, mouth_clear=1.4)
w = HS['width']; Bx = HS['balcony_half']
zb = ring_z(Bx) + HS['mouth_clear'] + w / 2         # the flights' centreline on the balcony
balcony_front = zb + w / 2
balcony = Polygon(frame_line(REN, [(-Bx, ring_z(0) - 1.0), (Bx, ring_z(0) - 1.0), (Bx, balcony_front), (-Bx, balcony_front)]))
net.add('highline', balcony, 'Renewal stair landing')
HORSESHOE = []
for s in (1, -1):
    rise = HIGHLINE_DATUM - PROMENADE_DATUM
    run = rise / STAIR_PITCH
    arc_len = math.pi / 2 * HS['radius']
    straight = run - arc_len
    land = (s * (Bx - 1.5), zb)
    path = join(line_path(land, (s * Bx, zb)),
                arc_path((s * Bx, zb), 0.0 if s > 0 else 180.0, HS['radius'], 90.0 * s),
                line_path((s * (Bx + HS['radius']), zb + HS['radius']), (s * (Bx + HS['radius']), zb + HS['radius'] + straight + 1.2)))
    f = Flight('RS' + ('E' if s > 0 else 'W'), 'highline', 'promenade', frame_line(REN, path), w, 'stair', landing=(1.5, 1.2),
               note='Renewal horseshoe stair, %s flight' % ('east' if s > 0 else 'west'))
    net.flight(f); HORSESHOE.append(f)

# --- Oren: a small spiral stair from the Highline's inner edge down onto the roof terrace
OREN = PLOT['OREN']
sp_b = brg(*shell_to_plan(OREN, (3.0, -6.2)))
SPIRAL = dict(bearing=round(sp_b, 3), walkline=1.55, width=1.2, newel=0.35, top=HL_IN + 1.0, landing_end=66.3)
p0, p1 = pol(SPIRAL['top'], sp_b), pol(SPIRAL['landing_end'], sp_b)
rise = HIGHLINE_DATUM - OREN_ROOF
turn = math.degrees((rise / 0.62) / SPIRAL['walkline']) + math.degrees(1.2 / SPIRAL['walkline'])
spiral_path = join(line_path(p0, p1), arc_path(p1, sp_b + 180.0, SPIRAL['walkline'], turn))
net.level('oren-roof', OREN_ROOF, 'glass', "Oren's roof terrace")
net.add('oren-roof', walls_of(OREN), 'roof')
spiral = Flight('OS', 'highline', 'oren-roof', spiral_path, SPIRAL['width'], 'spiral', landing=(math.dist(p0, p1), 1.2), guards='outer', outer_side=-1,
                note="Oren's spiral stair to the roof terrace")
net.flight(spiral)

# --- the service yards behind Oren and Kel, and a lane along each building's flank down to its forecourt
YARDS = {}
for g, datum, side in (('OREN', OREN_YARD, None), ('KEL', KEL_YARD, None)):
    p = PLOT[g]; hx, hz = p['footprint'][0] / 2, p['footprint'][1] / 2
    if side is None:   # the lane goes on the flank away from the arrival: toward Kel for Oren, toward Vara for Kel
        side = 1 if brg(*shell_to_plan(p, (hx, 0))) > brg(*p['centre']) else -1
    LANE_SIDE[g] = side
    lid = g.lower() + '-yard'
    net.level(lid, datum, 'basalt', "%s's service yard at its receiving door" % g.title())
    yard = frame_rect(p, min(-hx, side * (hx + 3.2)), max(hx, side * (hx + 3.2)), -hz - 3.0, -hz + 0.6)
    net.add(lid, yard, 'yard'); net.wall(lid, walls_of(p))
    YARDS[g] = dict(datum=datum, side=side)
    x = side * (hx + 1.7)
    lane = Flight('L' + g[0], lid, 'promenade', frame_line(p, line_path((x, -hz - 1.0), (x, hz + 1.2))), 2.4, 'ramp', landing=(1.6 + 1.0, 1.4),
                  guards='none', material='basalt', note="%s's service lane" % g.title())
    net.flight(lane)
    # the forecourt reaches the lane's foot
    net.add('promenade', frame_rect(p, min(side * (hx + 0.2), side * (hx + 3.2)), max(side * (hx + 0.2), side * (hx + 3.2)), hz - 0.5, hz + 3.0).difference(lava_side))

# ===================================================================== solve and check
net.solve()
net.check(max_grade=RAMP_MAX)
F = net.fails


def ok(m): print('ok  ', m)

# canopy clearance over Renewal
for f in HORSESHOE:
    L = f.line.length
    for k in range(int(L / 0.25) + 1):
        q = f.line.interpolate(L * k / int(L / 0.25)); x, z = plan_to_shell(REN, (q.x, q.y))
        y = f.height(L * k / int(L / 0.25), HIGHLINE_DATUM, PROMENADE_DATUM)
        if abs(x) - w / 2 <= CANOPY['span'] / 2 + 0.3 and CANOPY['back'] - 0.3 <= z <= CANOPY['front']:
            t = min(1.0, abs(x) / (CANOPY['span'] / 2)); h = CANOPY['spring'] + (CANOPY['crown'] - CANOPY['spring']) * (1 - t * t)
            if y - 0.6 < PROMENADE_DATUM + h + 0.4: F.append('%s passes %.1f m over the canopy' % (f.id, y - 0.6 - PROMENADE_DATUM - h)); break
ok('Renewal horseshoe stair: two %.1f m flights at %.0f degrees, clear over the canopy' % (HORSESHOE[0].slope.length, math.degrees(math.atan(STAIR_PITCH))))

# Highline frames: twelve paired forks, turned to stand clear of everything on the ground and every flight
ground_things = unary_union([net.levels['promenade']['surface'], net.levels['oren-yard']['surface'], net.levels['kel-yard']['surface']]
                            + [band(list(f.line.coords), f.width) for f in net.flights] + [platform(PLOT[d]) for d in DOCKS] + [walls_of(PLOT[g], 0.5) for g in GROUND])
best = None
for off in [o * 0.5 for o in range(60)]:
    gap = min(ground_things.distance(Point(pol(HIGHLINE_RADIUS, off + 30 * k))) for k in range(12))
    if best is None or gap > best[1]: best = (off, gap)
FRAMES = [round(best[0] + 30 * k, 2) for k in range(12)]
if best[1] < 0.6: F.append('a Highline frame stands %.1f m from a walk or building' % best[1])
ok('twelve Highline frames at %.1f + 30k degrees, each %.1f m or more from anything on the ground' % (best[0], best[1]))

# the gallery's grade and the levelness of every joint are in the kit's checks; report the network
for f in net.flights:
    ok('%-4s %-6s %5.1f m  %4.1f%%  %s' % (f.id, f.kind, f.slope.length, f.grade(net.levels[f.upper]['datum'], net.levels[f.lower]['datum']) * 100, f.note))
for lv in net.levels.values():
    ok('level %-10s %5.2f  %3d guard runs, %6.1f m of guard' % (lv['id'], lv['datum'], len(lv['guards']), sum(g.length for g in lv['guards'])))

# ===================================================================== the funicular from the volcano's foot to the Gate Terrace
FUN = dict(lower=(92.0, -181.0), upper=(9.0, -122.0), tracks=3.4, gauge=1.0, car=dict(length=9.6, width=2.5, steps=3, eps=0.28))
lx, ly = FUN['lower']; ux, uy = FUN['upper']
FUN['lower_y'] = round(max(flank_y(math.hypot(lx, ly)), 0.0), 2)
FUN['upper_y'] = GATE_DATUM
run = math.dist(FUN['lower'], FUN['upper'])
FUN['grade'] = round((FUN['upper_y'] - FUN['lower_y']) / run, 3)
FUN['length'] = round(math.hypot(run, FUN['upper_y'] - FUN['lower_y']), 1)
prof = []
worst_cut, worst_fill = 0, 0
for k in range(41):
    t = k / 40; x, y = lx + (ux - lx) * t, ly + (uy - ly) * t
    rail = FUN['lower_y'] + (FUN['upper_y'] - FUN['lower_y']) * t
    g = flank_y(math.hypot(x, y)); prof.append([round(x, 2), round(rail, 2), round(y, 2), round(g, 2)])
    worst_cut, worst_fill = max(worst_cut, g - rail), max(worst_fill, rail - g)
FUN['profile'] = prof
if Point(FUN['upper']).distance(terrace) > 3.5: F.append('the funicular does not reach the Gate Terrace')
ok('funicular: %.0f m long at %.0f%% (%.0f degrees), lower station at %.1f, cutting up to %.1f m, viaduct up to %.1f m' %
   (FUN['length'], FUN['grade'] * 100, math.degrees(math.atan(FUN['grade'])), FUN['lower_y'], worst_cut, worst_fill))
# the gate's plinth: from the terrace down into the rim's lowest ground under it, 1.5 m embedded
lowest = min(ground_below(*q) for q in terrace.exterior.coords)
GATE_PLINTH = dict(top=GATE_DATUM, bottom=round(lowest - 1.5, 2))
ok('Gate Terrace plinth from %.2f down to %.2f: nothing hovers' % (GATE_DATUM, GATE_PLINTH['bottom']))

if F:
    print('\n'.join('FAIL ' + f for f in F)); sys.exit(1)

# ===================================================================== write
data = net.data()
EXTRA = dict(gate_terrace=GATE_TERRACE, tempering_gate=TEMPERING_GATE, gate_plinth=GATE_PLINTH, inn_bridge=INN_BRIDGE, iren_bridge=IREN_BRIDGE,
             refuges=REFUGES, renewal_deck=RENEWAL_DECK, canopy=CANOPY, immersion_tongue=IMMERSION_TONGUE, horseshoe=HS, spiral=SPIRAL,
             yards=YARDS, frames=FRAMES, funicular=FUN, promenade_centre=PROM_CENTRE[::4],
             datums=dict(gate=GATE_DATUM, highline=HIGHLINE_DATUM, promenade=PROMENADE_DATUM, oren_roof=OREN_ROOF, oren_yard=OREN_YARD, kel_yard=KEL_YARD))
HEADER = ['The Fire Caldera\'s walkways above the lava (docs/architecture/fire_caldera_walkways.md): every level',
          'surface with its guards, every flight with its profile and guards, the Gate Terrace, the funicular.',
          'Frame: FireCalderaPlan\'s local plan frame; [x, y] plan points, [x, world Y, y] where a height is given.',
          'A level\'s guards run along its surface\'s outline: build them from these lines, not from a builder\'s',
          'own offsets, so every junction meets end to end. Status: proposed for review.']
write_plan('FireCalderaWalkwaysPlan', 'fire_caldera_walkways_plan.gd', HEADER,
           dict(LEVELS=('# one surface per level: outline and holes, guard lines at datum + 1.09', data['levels']),
                FLIGHTS=('# ramps and stairs: centreline profile [x, Y, y] and guard lines', data['flights']),
                SITE=('# the gate, refuges, Renewal, frames, yards and the funicular', EXTRA)),
           'tools/fire_caldera_walkways_layout.py')
if '--json' in sys.argv:
    json.dump(dict(walkways=data, site=EXTRA), open(sys.argv[sys.argv.index('--json') + 1], 'w'), separators=(',', ':'))
print('wrote scripts/fire_caldera_walkways_plan.gd: %d levels, %d flights' % (len(data['levels']), len(data['flights'])))
