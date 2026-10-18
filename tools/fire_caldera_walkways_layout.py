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
from walkway_kit import Network, Flight, superellipse, annulus, band, circle_pts, polys, lines
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

# ===================================================================== the Gate Terrace (48.5) and the funicular
# Revised 2026-10-18, at the user's direction, after the first build: the funicular's track clipped into the flank,
# its top station was a slab half-sunk in the terrace, the terrace's ends stood open onto nothing, there was no way
# up for a walker, and the gate had lost its SuperEgg arch and glass veil. Designed together now:
# - the terrace is guarded all round; its only openings are designed: the arrival gallery's mouth (H0), the inn's
#   bridge, the funicular's platform gates and the head of the track-side stair;
# - the funicular's top station is part of the terrace: a wing of the terrace along the track with a notch the two
#   cars dock in, floor level with the terrace, boarded through platform gates on each car's outer side;
# - the track rides a graded corridor (the flank's noise is faded out along it, FireKingdomTerrain) on a basalt
#   viaduct that follows the ground at a constant clearance, so it never clips the flank;
# - the cabins hang level in their frames as the grade changes (after the Stoosbahn), one SuperEgg cabin per car,
#   two cars, counterbalanced on two tracks (after Lisbon's Gloria);
# - a stair climbs beside the track for walkers, as Lisbon's Bica has stairs beside its track.
import fire_kingdom_terrain_bounds as TB
net.level('gate', GATE_DATUM, 'basalt', 'the Gate Terrace on the crater lip: the Tempering Gate, the inn porch, the funicular top', kerbs=False)
GATE_TERRACE = dict(centre=(4.0, -115.0), half=(14.0, 5.0), exponent=6.0)
terrace = superellipse(*GATE_TERRACE['centre'], *GATE_TERRACE['half'], GATE_TERRACE['exponent'], 0.0, 160)
GUEST = PLOT['GUEST']
INN_BRIDGE = [(15.5, -113.0), (15.5, -106.5)]
# the gate: the earlier arrival threshold's language (a squarish superellipse arch of three refractory tubes on
# SuperEgg feet, a veil of stained-glass SuperEgg fins hung under its crown) at the new size
TEMPERING_GATE = dict(at=(0.0, -114.6), span=6.8, height=10.0, pylon=0.9,
    arch=dict(exponent=6.0, tube=0.42, layers=[-0.48, 0.0, 0.48], material='refractory ceramic, ember-glazed'),
    feet=dict(semi=[0.9, 0.7, 1.1], eps=7.5, material='basalt'),
    veil=dict(clear=3.4, fins=[dict(x=-2.25, len=3.6, colour='teal'), dict(x=-0.75, len=4.6, colour='magenta'),
                               dict(x=0.75, len=4.2, colour='lime'), dict(x=2.25, len=3.4, colour='cobalt')],
              semi_width=0.55, semi_depth=0.12, eps=3.0, material='stained glass, lit from within at night'))
_g = TEMPERING_GATE
if _g['height'] - max(f['len'] for f in _g['veil']['fins']) < _g['veil']['clear']: raise SystemExit('FAIL the gate\'s veil hangs into the walk')

FUN_DIR = (83.0, -59.0); _n = math.hypot(*FUN_DIR); FU = (FUN_DIR[0] / _n, FUN_DIR[1] / _n); FN = (-FU[1], FU[0])
FUN = dict(top=(7.0, -118.0), tracks=3.4, gauge=1.0, dock=8.4, frame=0.9, bed=dict(width=10.6, depth=0.7, clearance=0.6),
           corridor=dict(clear=25.0, blend=50.0),
           car=dict(semi=[3.5, 1.45, 1.25], eps=[2.6, 3.4], floor=0.9, door=1.6, length=7.0, width=2.5, steps=1,   # length/width/steps: the first builder's keys, kept until it is replaced
                     pivot='the cabin hangs level in a ring frame as the grade changes (after the Stoosbahn)',
                    names=['the ember car', 'the ash car'], colours=['ember red', 'ash white']),
           stair=dict(offset=-4.35, width=1.8, tread=0.3),
           pier=dict(every=7.5, semi=[0.9, 1.1], eps=3.0, socket=1.0))
def along(s, across=0.0): return (FUN['top'][0] + FU[0] * s + FN[0] * across, FUN['top'][1] + FU[1] * s + FN[1] * across)
S_END = 108.0
TB.set_corridor(FUN['top'], along(S_END + 6), FUN['corridor']['clear'], FUN['corridor']['blend'])
def ground_at(q): return TB.bounds_local(q)[1]
# the profile: docks level at both ends (the cars' floors meet the platforms), between them the track follows the
# ground at a constant clearance, a taut line over it eased into vertical curves
ds = 0.5; NS = int(S_END / ds) + 1; SS = [k * ds for k in range(NS)]
G_ = [max(ground_at(along(s, a)) for a in (-5.3, 0.0, 5.3)) for s in SS]   # the bed's whole width
top_rail = GATE_DATUM - FUN['frame']
need = [g + FUN['bed']['depth'] + FUN['bed']['clearance'] + 0.15 for g in G_]
# under the station wing and in the lower station the bed rests on the stations' socketed plinths: no clearance
# there. The cabins hang level, so a dock needs no level track: only its centre is pinned, where the car's floor
# meets the platform.
WING_END = FUN['dock'] + 5.6
LOW_START = S_END - FUN['dock'] - 1.0
def _ss(a, b, x): t = min(max((x - a) / (b - a), 0.0), 1.0); return t * t * (3 - 2 * t)
FULL = FUN['bed']['depth'] + FUN['bed']['clearance'] + 0.15
need = [g + 0.3 + (FULL - 0.3) * _ss(WING_END, WING_END + 10, s) * (1 - _ss(LOW_START - 10, LOW_START, s)) for g, s in zip(G_, SS)]
top_k = int(round(FUN['dock'] / 2 / ds)); low_k = int(round((S_END - FUN['dock'] / 2) / ds))
# a smooth envelope over the clearance line: a running maximum, then three running means no wider than it, so the
# track is never under the line and its vertical curves are wide (it never copies the coarse ground's kinks)
def _run(v, h, f):
    return [f(v[max(0, k - h):min(len(v), k + h + 1)]) for k in range(len(v))]
rail = _run(need, 10, max)
for _ in range(3): rail = _run(rail, 3, lambda w: sum(w) / len(w))
# the top dock's car floor is the terrace: lift the track there by a smooth bump (it may only rise to meet it)
lift_ = top_rail - rail[top_k]
if lift_ < -0.01: F.append('the funicular cannot come down to the terrace: its clearance holds it %.2f m above' % -lift_)
rail = [r + max(lift_, 0.0) * math.exp(-((k - top_k) * ds / 6.0) ** 2) for k, r in enumerate(rail)]
low_rail = round(rail[low_k], 2); low_datum = round(low_rail + FUN['frame'], 2)
FUN['profile'] = [[round(along(s)[0], 3), round(rail[k], 3), round(along(s)[1], 3), round(G_[k], 3)] for k, s in enumerate(SS)][::2]
FUN['lower_datum'] = low_datum; FUN['upper_datum'] = GATE_DATUM; FUN['length'] = round(sum(math.hypot(ds, rail[k + 1] - rail[k]) for k in range(NS - 1)), 1)
grades = [(rail[k] - rail[k + 1]) / ds for k in range(NS - 1)]
FUN['max_grade'] = round(max(grades), 3)
FUN['piers'] = []
s_ = FUN['dock'] + 3.0
while s_ < S_END - FUN['dock'] - 1.0:
    k = int(round(s_ / ds)); q = along(s_)
    if rail[k] - FUN['bed']['depth'] - G_[k] > 0.4:
        FUN['piers'].append(dict(at=[round(q[0], 3), round(q[1], 3)], top=round(rail[k] - 0.15 - FUN['bed']['depth'], 3), foot=round(G_[k] - FUN['pier']['socket'], 3)))
    s_ += FUN['pier']['every']
# the top station: a wing of the terrace along the track, a notch the cars dock in, platforms on their outer sides
wing_c = along(FUN['dock'] / 2 + 0.6)
FUN['wing'] = dict(centre=[round(wing_c[0], 3), round(wing_c[1], 3)], half=[FUN['dock'] / 2 + 1.6, 6.6], exponent=6.0, turn=round(math.degrees(math.atan2(FU[1], FU[0])), 3))
wing = superellipse(*wing_c, FUN['wing']['half'][0], FUN['wing']['half'][1], 6.0, math.atan2(FU[1], FU[0]), 160)
car_half = FUN['tracks'] / 2 + FUN['car']['semi'][2] + 0.08
notch = Polygon([along(0, -car_half), along(0, car_half), along(S_END, car_half), along(S_END, -car_half)])
net.add('gate', terrace.difference(notch), 'terrace')
net.add('gate', wing.difference(notch), 'funicular station')
FUN['notch_half'] = round(car_half, 3)
# platform gates: the car's door, on its outer side, at the middle of the docked car
dock_mid = FUN['dock'] / 2
FUN['gates'] = []
for sgn in (1, -1):
    a_, b_ = along(dock_mid - FUN['car']['door'] / 2, sgn * car_half), along(dock_mid + FUN['car']['door'] / 2, sgn * car_half)
    net.open_edge('gate', LineString([a_, b_])); FUN['gates'].append([[round(a_[0], 3), round(a_[1], 3)], [round(b_[0], 3), round(b_[1], 3)]])
# the track-side stair: a cantilevered walk on the viaduct's south-west side, at the cars' floor line, from the
# station's platform down to the lower station
st = FUN['stair']; stair_s0 = FUN['wing']['half'][0] * 2 - 1.6 + 0.6 - 0.05     # the wing's downhill edge
stair_prof = []
for k, s in enumerate(SS):
    if s < stair_s0: continue
    q = along(s, st['offset']); stair_prof.append([round(q[0], 3), round(min(GATE_DATUM, rail[k] + FUN['frame']), 3), round(q[1], 3)])
FUN['stair']['profile'] = stair_prof[::2]
mouth_a, mouth_b = along(stair_s0 - 0.2, st['offset'] - st['width'] / 2), along(stair_s0 - 0.2, st['offset'] + st['width'] / 2)
net.add('gate', band([along(stair_s0 - 1.2, st['offset']), along(stair_s0 + 0.02, st['offset'])], st['width']), 'stair head')
net.open_edge('gate', LineString([along(stair_s0, st['offset'] - st['width'] / 2 - 0.05), along(stair_s0, st['offset'] + st['width'] / 2 + 0.05)]))
FUN['stair']['guards'] = [[[round(q[0], 3), round(h + 1.09, 3), round(q[2], 3)] for q, h in ((along(s, st['offset'] + sgn * st['width'] / 2) + (None,), r) for s, r in [])] for sgn in (1, -1)]
gl = []
for sgn in (1, -1):
    run_ = []
    for k, s in enumerate(SS):
        if s < stair_s0: continue
        q = along(s, st['offset'] + sgn * st['width'] / 2); run_.append([round(q[0], 3), round(min(GATE_DATUM, rail[k] + FUN['frame']) + 1.09, 3), round(q[1], 3)])
    gl.append(run_[::2])
FUN['stair']['guards'] = gl
# the lower station: a plaza on the graded ground round the lower dock, its floor the cars' floor
net.level('funicular-foot', low_datum, 'basalt', "the funicular's lower station at the volcano's foot")
low_c = along(S_END - FUN['dock'] / 2 + 1.0)
FUN['foot'] = dict(centre=[round(low_c[0], 3), round(low_c[1], 3)], half=[FUN['dock'] / 2 + 3.0, 7.4], exponent=6.0, turn=FUN['wing']['turn'])
foot = superellipse(*low_c, FUN['foot']['half'][0], FUN['foot']['half'][1], 6.0, math.atan2(FU[1], FU[0]), 160)
net.add('funicular-foot', foot.difference(notch), 'lower station')
for sgn in (1, -1):
    a_, b_ = along(S_END - dock_mid - FUN['car']['door'] / 2, sgn * car_half), along(S_END - dock_mid + FUN['car']['door'] / 2, sgn * car_half)
    net.open_edge('funicular-foot', LineString([a_, b_]))
net.open_edge('funicular-foot', LineString([along(S_END - FUN['dock'] - 0.4, st['offset'] - 1.0), along(S_END - FUN['dock'] - 0.4, st['offset'] + 1.0)]))
# down to the ground: a straight ramp off the plaza's far end, on the line, to a landing on the graded ground
foot_end = along(S_END - FUN['dock'] / 2 + 1.0 + FUN['foot']['half'][0] - 0.5)
ground_end = ground_at(foot_end)
FOOT_GROUND = round(max(ground_at(along(S_END + 8 + t, 0)) for t in range(0, 28)) + 0.1, 2)
net.level('foot-ground', FOOT_GROUND, 'basalt', 'the landing on the ground at the foot of the lower station\'s ramp')
ramp_len = (low_datum - FOOT_GROUND) / 0.16 + 3.0
foot_ramp = Flight('FR', 'funicular-foot', 'foot-ground', line_path(along(S_END - FUN['dock'] / 2 + 1.0 + FUN['foot']['half'][0] - 1.5), along(S_END - FUN['dock'] / 2 + 1.0 + FUN['foot']['half'][0] - 1.5 + ramp_len)),
                   3.0, 'ramp', landing=(1.5, 1.5), note="the lower station's ramp down to the ground")
net.flight(foot_ramp)
net.add('foot-ground', superellipse(*along(S_END - FUN['dock'] / 2 + 1.0 + FUN['foot']['half'][0] - 1.5 + ramp_len + 2.0), 3.5, 3.0, 6.0, math.atan2(FU[1], FU[0]), 96), 'landing')

net.add('gate', platform(GUEST), 'inn porch')
net.wall('gate', walls_of(GUEST))
net.add('gate', band(INN_BRIDGE, 3.0), 'inn bridge')

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
IMMERSION_TONGUE = dict(width=8.0, start=(0.0, RENEWAL_DECK['half'][1]), length=14.0, drop=2.4)  # its frame: from the deck's lava edge (not over the deck: no two surfaces at one height) down into the lava

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

# Revised 2026-10-18, at the user's direction: the flights were 34-degree stairs built as slopes, and near the
# bottom they straightened and aimed at the deck's front corners. Now two grand ramps: each leaves the balcony
# outward along the back of the canopy, sweeps round a wide half-turn toward the lava, and straightens only for
# the last few metres, entering the deck at the middle of its side, square to it.
HS = dict(width=2.2, balcony_half=4.0, mouth_clear=1.4, turn_x=13.2, radius=4.6, entry_z=None, kind='ramp')
w = HS['width']; Bx = HS['balcony_half']
zb = ring_z(Bx) + HS['mouth_clear'] + w / 2         # the ramps' centreline along the balcony
balcony_front = zb + w / 2
balcony = Polygon(frame_line(REN, [(-Bx, ring_z(0) - 1.0), (Bx, ring_z(0) - 1.0), (Bx, balcony_front), (-Bx, balcony_front)]))
net.add('highline', balcony, 'Renewal ramp landing')
HS['entry_z'] = round(zb + 2 * HS['radius'], 3)
deck_side = RENEWAL_DECK['half'][0]
HORSESHOE = []
for s in (1, -1):
    xc = HS['turn_x']                                 # where the half-turn begins and ends: outside the deck's side
    path = join(line_path((s * (Bx - 1.5), zb), (s * xc, zb)),
                arc_path((s * xc, zb), 0.0 if s > 0 else 180.0, HS['radius'], 180.0 * s),
                line_path((s * xc, HS['entry_z']), (s * (deck_side - 1.2), HS['entry_z'])))
    f = Flight('RS' + ('E' if s > 0 else 'W'), 'highline', 'promenade', frame_line(REN, path), w, 'ramp', landing=(1.5, 1.2),
               note='Renewal grand ramp, %s' % ('east' if s > 0 else 'west'))
    net.flight(f); HORSESHOE.append(f)

# --- Oren: a small spiral stair from the Highline's inner edge down onto the roof terrace
OREN = PLOT['OREN']
sp_b = brg(*shell_to_plan(OREN, (3.0, -6.2)))
SPIRAL = dict(bearing=round(sp_b, 3), walkline=1.55, width=1.2, newel=0.35, top=HL_IN + 1.0, landing_end=66.3)
p0, p1 = pol(SPIRAL['top'], sp_b), pol(SPIRAL['landing_end'], sp_b)
rise = HIGHLINE_DATUM - OREN_ROOF
turn = math.degrees((rise / 0.62) / SPIRAL['walkline']) + math.degrees(1.2 / SPIRAL['walkline'])
spiral_path = join(line_path(p0, p1), arc_path(p1, sp_b + 180.0, SPIRAL['walkline'], turn))
# Oren's own roof terrace (FireCalderaOren._parapet): the house builds it, paving, parapet and all. The walkway
# builder added a glass deck and a guard over it, which sealed the house's parapet gap and the lift's top stop
# (user, 2026-10-18): the level is the house's, here only so the spiral can land on it.
net.level('oren-roof', OREN_ROOF, 'glass', "Oren's roof terrace (the house's own)", owner='FireCalderaOren')
net.add('oren-roof', walls_of(OREN), 'roof')
spiral = Flight('OS', 'highline', 'oren-roof', spiral_path, SPIRAL['width'], 'spiral', landing=(math.dist(p0, p1), 1.2), guards='outer', outer_side=-1,
                note="Oren's spiral stair to the roof terrace")
net.flight(spiral)
# where the spiral arrives on the house's terrace, in Oren's own frame: the house's parapet opens there, and the
# lift's top stop (FireCalderaOren.LIFT_AT) keeps its own clear landing
_end = list(spiral.line.coords)[-1]; _sp = plan_to_shell(OREN, _end)
SPIRAL['arrival_local'] = [round(_sp[0], 3), round(_sp[1], 3)]
OREN_LIFT_AT = (7.62, 3.7)

# the house's own landings outside its walls, from FireCalderaPlan.PLOTS[...].levels (its frame: x, z, w, d)
OWN_LANDINGS = {'OREN': [(-7.0, -6.8, 2.0, 0.8), (6.5, -6.8, 2.0, 2.2), (6.5, -4.6, 2.0, 4.24)]}
if math.dist(SPIRAL['arrival_local'], OREN_LIFT_AT) < 2.6: F.append("Oren's spiral lands on the lift's landing")
# --- the service yards behind Oren and Kel, and a lane along each building's flank down to its forecourt
YARDS = {}
for g, datum, side in (('OREN', OREN_YARD, None), ('KEL', KEL_YARD, None)):
    p = PLOT[g]; hx, hz = p['footprint'][0] / 2, p['footprint'][1] / 2
    if side is None:   # the lane goes on the flank away from the arrival: toward Kel for Oren, toward Vara for Kel
        side = 1 if brg(*shell_to_plan(p, (hx, 0))) > brg(*p['centre']) else -1
    LANE_SIDE[g] = side
    lid = g.lower() + '-yard'
    net.level(lid, datum, 'basalt', "%s's service yard at its receiving door" % g.title())
    # the house's own floors that reach out of its walls (its ramp's foot landings) are the house's: the yard stops
    # at their edges instead of lying over them at the same height (user, 2026-10-18)
    for lv_ in OWN_LANDINGS.get(g, []):
        net.wall(lid, frame_rect(p, lv_[0], lv_[0] + lv_[2], lv_[1], lv_[1] + lv_[3]))
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
net.check(max_grade=RAMP_MAX, exempt={'RSE': 0.55, 'RSW': 0.55})
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
for f in HORSESHOE:   # each enters the deck's side, square to it, in its middle half (not at a front corner)
    c_ = list(f.line.coords); e0, e1 = plan_to_shell(REN, c_[-6]), plan_to_shell(REN, c_[-1])
    head_ = math.degrees(math.atan2(e1[1] - e0[1], abs(e1[0] - e0[0])))
    if abs(head_) > 15 or abs(e1[1]) > RENEWAL_DECK['half'][1] / 2 or abs(e1[0]) > RENEWAL_DECK['half'][0]: F.append('%s does not enter the deck square to the middle of its side' % f.id)
g_ = HORSESHOE[0].grade(HIGHLINE_DATUM, PROMENADE_DATUM)
if g_ > 0.55: F.append('the Renewal ramps are %.0f%% steep' % (g_ * 100))
ok('Renewal grand ramps: two %.1f m ramps at %.0f%% (%.0f degrees), each entering the deck square to its side, clear over the canopy' % (HORSESHOE[0].slope.length, g_ * 100, math.degrees(math.atan(g_))))

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

# ===================================================================== the funicular's checks
for k, s in enumerate(SS):
    if WING_END + 10 < s < LOW_START - 10 and rail[k] - 0.15 - FUN['bed']['depth'] < G_[k] + FUN['bed']['clearance'] - 0.01:
        F.append('the funicular\'s bed is %.2f m over the ground at %.0f m' % (rail[k] - 0.15 - FUN['bed']['depth'] - G_[k], s)); break
if FUN['max_grade'] > 0.68: F.append('the funicular is %.0f%% steep' % (FUN['max_grade'] * 100))
curv = max(abs(grades[k + 1] - grades[k]) / ds for k in range(top_k, low_k))   # between the docks' centres
if curv > 1 / 12.0: F.append('a vertical curve on the funicular is tighter than 12 m (%.1f m)' % (1 / curv))
if Point(along(0)).distance(terrace) > 0.01 and not terrace.contains(Point(along(0))): F.append('the funicular does not reach into the Gate Terrace')
for TB_ in (net.levels['gate'], net.levels['funicular-foot']):
    pass
ok('funicular: %.0f m, the cabins level from the terrace (48.5) to the foot (%.2f), steepest %.0f%% (%.0f degrees), vertical curves 12 m or wider, the bed %.1f m or more clear of the graded flank on %d piers' %
   (FUN['length'], low_datum, FUN['max_grade'] * 100, math.degrees(math.atan(FUN['max_grade'])), FUN['bed']['clearance'], len(FUN['piers'])))
# the gate's plinth: from the terrace and its station wing down into the lowest live ground under them, 1.5 m embedded
lowest = min(ground_at(q) for q in list(terrace.exterior.coords) + list(wing.exterior.coords))
GATE_PLINTH = dict(top=GATE_DATUM, bottom=round(lowest - 1.5, 2))
ok('Gate Terrace plinth from %.2f down to %.2f: nothing hovers' % (GATE_DATUM, GATE_PLINTH['bottom']))

if F:
    print('\n'.join('FAIL ' + f for f in F)); sys.exit(1)

# ===================================================================== the ground under the walks (2026-10-18)
# In the game the promenade lay in the ground: its datum (30.0) is the bowl's lowest point and the bowl rises
# outward, up to 1.4 m above the walk, and nothing cut it. Every walk that sits on the ground now says so: the
# ground under it is cut down to its underside, and where the ground beyond its edge stands higher than the walk a
# low basalt retaining edge holds it back. Raised walks say what holds them up. Checked here against the live
# ground (the analytic bowl inside the rim; the coarse mesh, bounded, outside it).
DECK_DEPTH = 0.22
def live_ground(x, y):
    r = math.hypot(x, y)
    if r < bank(brg(x, y)): return None
    return TB.bounds_local((x, y))[1]
ON_GROUND = ['promenade', 'oren-yard', 'kel-yard', 'foot-ground']
BEDS = {}
for lid, lv in net.levels.items():
    if lv['owner']: continue
    if lid in ON_GROUND:
        geom = lv['surface']; runs = []; worst = 0.0
        for edge in lines(geom.boundary) if hasattr(geom, 'boundary') else []:
            n_ = max(2, int(edge.length / 0.5)); run = []
            for k in range(n_ + 1):
                q = edge.interpolate(edge.length * k / n_)
                # the ground just outside the edge
                g_ = None
                for dd in (0.4, -0.4):
                    t_ = edge.interpolate(min(edge.length, edge.length * k / n_ + 0.05)); tx, ty = t_.x - q.x, t_.y - q.y; nn = math.hypot(tx, ty) or 1
                    pq = (q.x - ty / nn * dd, q.y + tx / nn * dd)
                    if not geom.buffer(0.01).contains(Point(pq)): g_ = live_ground(*pq)
                if g_ is not None and g_ > lv['datum'] + 0.05:
                    run.append([round(q.x, 3), round(g_, 3), round(q.y, 3)]); worst = max(worst, g_ - lv['datum'])
                elif len(run) > 1: runs.append(run); run = []
                else: run = []
            if len(run) > 1: runs.append(run)
        BEDS[lid] = dict(kind='ground', cut_to=round(lv['datum'] - DECK_DEPTH - 0.05, 3), retaining=runs, max_above=round(worst, 2),
                         note='cut the ground under the whole surface to cut_to; build a basalt retaining edge along each run, its top at the ground')
    else:
        BEDS[lid] = dict(kind='raised', note='a deck on its own supports (the Highline frames, a plinth or a building); the ground stays below it')
# raised walks clear the ground; flights that come down to the ground cut it where they run within 0.6 m of it
REFUGE_PADS = unary_union([superellipse(*r_['pad'], 3.5, 5.0, 6.0, math.radians(r_['bearing']), 96).buffer(2.0) for r_ in REFUGES])
BEDS['highline']['refuges'] = 'each refuge pad meets the rising bowl at its outer end: cut the ground under the pad to its underside, with a basalt retaining edge round that end'
for lid in ('highline', 'gate'):
    lv = net.levels[lid]
    for poly in polys(lv['surface']):
        for c in list(poly.exterior.coords)[::6]:
            if REFUGE_PADS.contains(Point(c)): continue
            g_ = live_ground(*c)
            if g_ is not None and lid == 'highline' and g_ > lv['datum'] - DECK_DEPTH - 0.3: F.append('the Highline at (%.1f, %.1f) is in the ground' % c); break
FLIGHT_CUTS = {}
for f in net.flights:
    top, bot = net.levels[f.upper]['datum'], net.levels[f.lower]['datum']; L_ = f.line.length; cuts = []; run = None
    for k in range(int(L_ / 0.5) + 1):
        s_ = min(L_, k * 0.5); q = f.line.interpolate(s_); g_ = live_ground(q.x, q.y); h = f.height(s_, top, bot)
        near = g_ is not None and h - DECK_DEPTH - g_ < 0.6
        if near and run is None: run = [round(s_, 2), round(s_, 2)]
        elif near: run[1] = round(s_, 2)
        elif run: cuts.append(run); run = None
    if run: cuts.append(run)
    if cuts: FLIGHT_CUTS[f.id] = cuts
ok('ground under the walks: %s cut to their undersides; retaining edges where the ground stands up to %.2f m above them' %
   (', '.join(ON_GROUND), max(b.get('max_above', 0) for b in BEDS.values())))
# the materials every walk shares: the guards' posts and handrail in Renewal's blued steel (user, 2026-10-18), and one
# clear sheet of glass for a glass deck: a top face seen from above, a bottom face seen from below, each culled
# from behind, so no view looks through two layers
MATERIALS = dict(
    guard_steel=dict(colour=[0.15, 0.24, 0.42], metallic=0.9, roughness=0.2, source='CalderaShell.STEEL_BLUED, as on Renewal\'s canopy'),
    guard_glass=dict(colour=[0.62, 0.82, 0.88], alpha=0.16, roughness=0.05, cull='back, one pane each side'),
    deck_glass=dict(colour=[0.62, 0.82, 0.88], alpha=0.2, roughness=0.05, metallic=0.0, cull='back', faces='a top face facing up and a bottom face facing down; edges opaque steel'),
    basalt=dict(colour=[0.17, 0.16, 0.16], roughness=0.9),
    winding='Godot front faces are clockwise seen from outside: every face of every deck, guard, post and rail faces out',
)
if F:
    print('\n'.join('FAIL ' + f for f in F)); sys.exit(1)

# ===================================================================== write
data = net.data()
EXTRA = dict(gate_terrace=GATE_TERRACE, tempering_gate=TEMPERING_GATE, gate_plinth=GATE_PLINTH, inn_bridge=INN_BRIDGE, iren_bridge=IREN_BRIDGE,
             refuges=REFUGES, renewal_deck=RENEWAL_DECK, canopy=CANOPY, immersion_tongue=IMMERSION_TONGUE, horseshoe=HS, spiral=SPIRAL,
             yards=YARDS, frames=FRAMES, funicular=FUN, promenade_centre=PROM_CENTRE[::4], beds=BEDS, flight_cuts=FLIGHT_CUTS, materials=MATERIALS,
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
