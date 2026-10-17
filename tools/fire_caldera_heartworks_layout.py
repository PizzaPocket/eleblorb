#!/usr/bin/env python3
"""The Caldera Heartworks plan: the chamber under the Fire Caldera's reservoir.

    python3 tools/fire_caldera_heartworks_layout.py [--json out.json]

Writes scripts/fire_caldera_heartworks_plan.gd (FireCalderaHeartworksPlan) and,
with --json, the data the review model docs/drawings/fire_caldera_3d.html embeds
beside the surface export. The document is docs/architecture/fire_caldera_heartworks.md.

Frame: FireCalderaPlan's local plan frame (origin the reservoir's centre, +y from
the kingdom gate toward Civic, +x a visitor's right at the gate). A bearing is
atan2(y, x) in degrees: Kel about 0, Civic 90, Renewal 180, the gate -90. Depths
are metres below the lava datum (FireCalderaGround.LAVA_Y, world 29.2), positive
down; 3D points are [x, world Y, y].

The surface plan (plots, the Highline and every surface route) stays in
FireCalderaPlan. This file owns everything below the lava, and the four places
it meets the surface: the three immersion shelves, the two crown stairs and the
four service shafts. The checks at the end fail the run when the section stops
fitting together.
"""
import json, math, os, sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from gd_plan import write_plan

LAVA_Y = 29.2
def wy(d): return round(LAVA_Y - d, 3)

# ---------------------------------------------------------------- the surface, as FireCalderaPlan has it
RESERVOIR_MEAN = 52.0
LOBES = [((-39.0, 22.0), -0.5, 0.42), ((-50.0, -5.0), 2.5, 0.42), ((-50.0, -5.0), 2.5, 0.18), ((44.0, -4.0), -0.5, 0.42),
         ((0.0, 43.0), 2.0, 0.42), ((0.0, -46.0), -4.0, 0.42), ((30.0, -34.0), -3.0, 0.42), ((-27.0, -51.0), -3.0, 0.42)]
FLOOR_RADIUS, RIM_RADIUS, FLOOR_Y, LIP_Y = 52.0, 112.0, 30.0, 48.0

def bank(bearing):
    """FireCalderaPlan.reservoir_radius at a bearing in degrees."""
    a = math.radians(bearing); r = RESERVOIR_MEAN
    for (tx, ty), push, width in LOBES:
        diff = (a - math.atan2(ty, tx) + math.pi) % (2 * math.pi) - math.pi
        r += push * math.exp(-(diff / width) ** 2)
    return r

def bowl_y(r):
    """FireCalderaGround.outer_bowl_height: the inhabited bowl's world height."""
    t = min(max((r - FLOOR_RADIUS) / (RIM_RADIUS - FLOOR_RADIUS), 0.0), 1.0)
    return FLOOR_Y + (LIP_Y - FLOOR_Y) * t * t

def pol(r, bearing): a = math.radians(bearing); return (r * math.cos(a), r * math.sin(a))
def brg(x, y): return math.degrees(math.atan2(y, x))
def adiff(a, b): return (a - b + 180) % 360 - 180
def P3(r, bearing, d): x, y = pol(r, bearing); return [round(x, 3), wy(d), round(y, 3)]

# ---------------------------------------------------------------- the section (all depths below the lava datum)
SPHERE = dict(centre_depth=56.0, radius=42.0, shell=2.4)
C_D, R, SH = SPHERE['centre_depth'], SPHERE['radius'], SPHERE['shell']

def sphere_rho(d, radius=R):
    """The sphere's plan radius at a depth (0 above or below it)."""
    q = radius * radius - (d - C_D) ** 2
    return math.sqrt(q) if q > 0 else 0.0

def cap_depth(rho, radius=R):
    """Depth of the sphere's upper surface at a plan radius."""
    return C_D - math.sqrt(max(radius * radius - rho * rho, 0.0))

# The crown: the reservoir stays one lava surface. Its bed shelves from the bank to the settling
# shelf (5 m deep) and the throat drops through it, 17 m in radius, to the sphere's cap.
CROWN = dict(
    shelf_depth=5.0,          # the settling shelf and the throat's lip
    shelf_radius=24.0,        # the bed is level at the shelf depth inside this radius
    throat_radius=17.0,       # the lava-filled throat over the cap
    lens_radius=6.0,          # the oculus: a refractory glass lens in the cap, lit by the throat above it
    baffles=[30.0, 150.0, 270.0],   # refractory settling baffles on the shelf, between the three intakes
)

def bed_depth(rho, bearing):
    """The new reservoir bed: depth below the datum (negative above it, at the bank's dry edge)."""
    b = bank(bearing)
    if rho >= b: return LAVA_Y - bowl_y(rho)
    if rho <= CROWN['throat_radius']: return cap_depth(rho, R + SH)
    if rho <= CROWN['shelf_radius']: return CROWN['shelf_depth']
    t = (b - rho) / (b - CROWN['shelf_radius']); s = t * t * (3 - 2 * t)
    return (LAVA_Y - bowl_y(b)) * (1 - s) + CROWN['shelf_depth'] * s

# The Crown Gallery (C0): the one dry ring, cut into the crown round the throat, its inner wall
# structural glass onto the molten throat, lens wells in its floor looking down into the chamber.
C0 = dict(id='C0', name='Crown Gallery', depth=10.5, inner=CROWN['throat_radius'], outer=CROWN['throat_radius'] + 4.2,
          ceiling=6.5, access='dry')

RING_WIDTH = 4.2
RING_HEADROOM = 4.5     # a ring's slot through the shell
# Rings below C0 follow the shell. `inside` is how much of the 4.2 m floor stands inside the shell's line:
# the upper rings are galleries cut back into the shell (0), the equatorial works ring straddles it (0.5),
# the lower rings are terraces standing out from it (1).
RINGS = [
    dict(id='C1', name='Steward Ring', depth=24.0, inside=0.0, program='the Renewal chamber L0, the manifold L1, the Renewal shelf and daily flow balancing'),
    dict(id='C2', name='Civic Ring', depth=38.0, inside=0.0, program='the deep observatory L2, the fired archive L3 and the Civic Crossing'),
    dict(id='C3', name='Works Ring', depth=52.0, inside=0.5, program='the forge L4, the materials bay L5 and the Forge Arm'),
    dict(id='C4', name='Inspection Ring', depth=68.0, inside=1.0, program='fall inspection, sampling and pressure-isolation stations'),
    dict(id='C5', name='Return Gallery', depth=82.0, inside=1.0, program='the collection gates, the return-riser intakes and the emergency bypass'),
]
for g in RINGS:
    s = sphere_rho(g['depth'])
    g['shell_rho'] = round(s, 3)
    g['inner'] = round(s - RING_WIDTH * g['inside'], 3)
    g['outer'] = round(g['inner'] + RING_WIDTH, 3)
    g['access'] = 'lava_helm'
RING = {g['id']: g for g in RINGS}
RING['C0'] = C0
C0['shell_rho'] = None

# The collection basin: the sphere's floor is refractory works; the receiving pool at its centre.
BASIN = dict(pool_radius=16.0, pool_depth=92.0, lips=[[16.0, 20.0, 90.8], [20.0, 23.0, 89.6]], floor_depth=C_D + R)

# ---------------------------------------------------------------- the falls
# Each fall leaves a gated sluice in the throat's floor and drops from a spout in the cap. A fall is a sheet
# across its bearing, narrowing as it accelerates. Two catch structures split them: the Renewal shelf (F2)
# and the Forge Arm's splitter (F1); what they do not take falls on as a veil to the basin.
def spout_depth(rho): return round(cap_depth(rho), 3)
FALLS = [
    dict(id='F0', name='Heartfall', bearing=90.0, rho=11.0, top=9.0, bottom=5.0, lands='basin', land_depth=BASIN['pool_depth'],
         role='the civic and ceremonial fall, on the gate-to-Civic axis, seen from every ring'),
    dict(id='F1', name='Forge Fall', bearing=-10.0, rho=14.0, top=5.0, bottom=3.5, lands='splitter', land_depth=51.0,
         role='the hot feed: the Forge Arm splitter sends a third along the arm to the forge'),
    dict(id='F1v', name='Forge veil', bearing=-10.0, rho=11.0, top=3.0, bottom=1.8, lands='basin', land_depth=BASIN['pool_depth'], from_depth=51.6,
         role='what the splitter passes on, from its inner lip to the basin'),
    dict(id='F2', name='Renewal Fall', bearing=198.0, rho=14.0, top=5.5, bottom=4.2, lands='renewal_shelf', land_depth=23.6,
         role='the gentlest fall, into the tempering pool of the Renewal shelf'),
    dict(id='F2v', name='Renewal veil', bearing=198.0, rho=9.0, top=3.5, bottom=2.0, lands='basin', land_depth=BASIN['pool_depth'], from_depth=24.0,
         role='the shelf\'s overflow from its inner lip to the basin'),
]
for f in FALLS:
    f['from_depth'] = round(f.get('from_depth', spout_depth(f['rho'])), 3)
    f['sluice'] = f['id'] in ('F0', 'F1', 'F2')
FALL = {f['id']: f for f in FALLS}

# The Renewal shelf: a broad deck held out from the Steward Ring over the void at Renewal's bearing,
# stepping down in warm pools to the tempering pool where F2 lands; its inner lip is a weir.
RENEWAL_SHELF = dict(bearing=198.0, half_angle=15.0, inner=9.0, outer=RING['C1']['inner'], depth=24.0,
                     pool=[11.0, 17.0], pool_surface=23.6, walk_from=17.0)
# The Forge Arm: a steel-and-basalt arm across the void at the Works Ring, carrying a lava channel from the
# splitter bowl under F1 out to the forge, with a stewards' walk beside it.
FORGE_ARM = dict(bearing=-10.0, inner=10.5, outer=RING['C3']['inner'], depth=52.0, width=4.0, channel=2.2,
                 splitter=dict(rho=14.0, radius=3.5, rim_depth=51.0), walk_from=20.0, to_room='L4')
# The Civic Crossing: one bridge across the void at the Civic Ring, on the gate's side, so the Heartfall is
# seen face-on from its middle. A chord at 14 m from the axis keeps it off every fall and impact.
CROSSING = dict(ring='C2', offset=14.0, toward=-90.0, width=4.2)
_phi = math.degrees(math.acos(CROSSING['offset'] / RING['C2']['inner']))
CROSSING['ends'] = [round(CROSSING['toward'] + _phi, 3), round(CROSSING['toward'] - _phi, 3)]

# ---------------------------------------------------------------- rooms behind the rings
# width: along the ring at its outer edge; deep: back into the rock; tall: floor to ceiling.
ROOMS = [
    dict(id='L0', name='Renewal chamber', ring='C1', bearing=198.0, width=22.0, deep=14.0, tall=6.5, kind='civic',
         purpose='communal immersion and the coming-of-age practice, opening onto the Renewal shelf'),
    dict(id='L1', name='Primary manifold', ring='C1', bearing=145.0, width=18.0, deep=14.0, tall=6.0, kind='works',
         purpose='Miru and Tovan\'s thermal distribution, the Aro return\'s valve station and the city\'s spine'),
    dict(id='L2', name='Deep observatory', ring='C2', bearing=90.0, width=18.0, deep=14.0, tall=7.0, kind='science',
         purpose='Selka\'s instruments, facing the Heartfall across the void'),
    dict(id='L3', name='Fired archive', ring='C2', bearing=118.0, width=16.0, deep=14.0, tall=6.0, kind='civic',
         purpose='cast and engraved records in the quiet sector, with the service lift to Civic'),
    dict(id='L4', name='High-temperature forge', ring='C3', bearing=-18.0, width=24.0, deep=14.0, tall=9.0, kind='works',
         purpose='Daro, Vesa and Ruun\'s hot floor, fed along the Forge Arm, with the service lift to Kel'),
    dict(id='L5', name='Experimental materials bay', ring='C3', bearing=24.0, width=18.0, deep=14.0, tall=7.0, kind='science',
         purpose='the shared Kel and Vara testing space, with the service lift to Vara'),
    # Small working bays, still rooms with their own doors onto the ring.
    dict(id='G0', name='Heartfall gate house', ring='C0', bearing=90.0, width=7.0, deep=5.0, tall=4.0, kind='works', purpose='F0\'s sluice gear and its glass-fronted control station'),
    dict(id='G1', name='Forge gate house', ring='C0', bearing=-10.0, width=7.0, deep=5.0, tall=4.0, kind='works', purpose='F1\'s sluice gear'),
    dict(id='G2', name='Renewal gate house', ring='C0', bearing=198.0, width=7.0, deep=5.0, tall=4.0, kind='works', purpose='F2\'s sluice gear'),
    dict(id='I0', name='Heartfall station', ring='C4', bearing=90.0, width=8.0, deep=6.0, tall=4.0, kind='works', purpose='sampling and isolation for F0'),
    dict(id='I1', name='Forge station', ring='C4', bearing=-10.0, width=8.0, deep=6.0, tall=4.0, kind='works', purpose='sampling and isolation for F1'),
    dict(id='I2', name='Renewal station', ring='C4', bearing=198.0, width=8.0, deep=6.0, tall=4.0, kind='works', purpose='sampling and isolation for F2'),
    dict(id='B0', name='Emergency bypass', ring='C5', bearing=235.0, width=8.0, deep=6.0, tall=4.0, kind='works', purpose='the overflow gate to the sacrificial natural tube'),
]
for rm in ROOMS:
    rm['floor_depth'] = RING[rm['ring']]['depth']
    rm['front'] = RING[rm['ring']]['outer']
    rm['back'] = round(rm['front'] + rm['deep'], 3)
    rm['half_angle'] = round(math.degrees(rm['width'] / 2 / rm['front']), 3)
ROOM = {rm['id']: rm for rm in ROOMS}

# ---------------------------------------------------------------- ways between the rings
# Enclosed stairs in the rock behind the shell, each from a door on one ring down to a door on the next.
STAIR_PITCH = 0.62   # rise over run: 32 degrees, an ordinary stair
LINKS = [
    dict(id='K12a', upper='C1', lower='C2', bearing=40.0, turn=-1), dict(id='K12b', upper='C1', lower='C2', bearing=240.0, turn=-1),
    dict(id='K23a', upper='C2', lower='C3', bearing=160.0, turn=1), dict(id='K23b', upper='C2', lower='C3', bearing=300.0, turn=-1),
    dict(id='K34a', upper='C3', lower='C4', bearing=60.0, turn=-1), dict(id='K34b', upper='C3', lower='C4', bearing=250.0, turn=-1),
    dict(id='K45a', upper='C4', lower='C5', bearing=130.0, turn=-1), dict(id='K45b', upper='C4', lower='C5', bearing=320.0, turn=-1),
]

def link_path(k):
    a, b = RING[k['upper']], RING[k['lower']]
    # behind both rings' outer walls, and behind the shell where a terrace stands out from it
    r = max(a['outer'], b['outer'], (a['shell_rho'] or 0) + SH, (b['shell_rho'] or 0) + SH) + 3.0
    drop = b['depth'] - a['depth']; run = drop / STAIR_PITCH
    sweep = math.degrees(run / r) * k['turn']
    pts = [P3(a['outer'], k['bearing'], a['depth']), P3(r, k['bearing'], a['depth'])]
    n = 12
    for i in range(1, n + 1):
        t = i / n; pts.append(P3(r, k['bearing'] + sweep * t, a['depth'] + drop * t))
    end = k['bearing'] + sweep
    pts.append(P3(b['outer'], end, b['depth']))
    return pts, end, run
for k in LINKS:
    k['points'], k['end_bearing'], k['run'] = link_path(k)
    k['end_bearing'] = round(k['end_bearing'], 3); k['run'] = round(k['run'], 2); k['width'] = 2.4

# ---------------------------------------------------------------- the three lava entries
# Each starts at a plot's immersion shelf on the surface: a stepped tongue into the reservoir. The swimmer
# crosses the shelf's lava to a portal in the bed, where a pressure lock (an outer gate, a chamber that
# drains, an inner door) lets them into a dry race: a level tunnel out under the bank to a race well, a
# helical stair with a lava flume beside it (down by the flume, up by the stair), and a level tunnel into
# the room it serves. The lock is why every way into the chamber passes through lava.
RACE_TUNNEL_DEPTH = 9.0
WELL = dict(radius=7.0, axis=68.0, pitch=0.30)
ENTRIES = [
    dict(id='S0', plot='RENEWAL', shelf_bearing=185.0, portal=(36.0, 190.0), well_bearing=202.0, room='L0', entry_offset=0.0,
         note='the gentlest and most social way in, from the Renewal deck\'s immersion tongue'),
    dict(id='S1', plot='CIVIC', shelf_bearing=90.0, portal=(36.0, 84.0), well_bearing=78.0, room='L2', entry_offset=-4.0,
         note='the deep scientific descent, from the observation landing in front of Civic'),
    dict(id='S2', plot='KEL', shelf_bearing=-20.0, portal=(36.0, -8.0), well_bearing=-2.0, room='L4', entry_offset=8.0,
         note='the protected hot-work landing, kept out of the gallery'),
]

def helix(cx, cy, r, a0, d0, d1, pitch, turn):
    drop = d1 - d0; run = drop / pitch; sweep = math.degrees(run / r) * turn; n = max(8, int(abs(sweep) / 12))
    pts = []
    for i in range(n + 1):
        t = i / n; a = math.radians(a0 + sweep * t)
        pts.append([round(cx + r * math.cos(a), 3), wy(d0 + drop * t), round(cy + r * math.sin(a), 3)])
    return pts, a0 + sweep, run

for e in ENTRIES:
    rm = ROOM[e['room']]
    pr, pb = e['portal']
    sx, sy = pol(bank(e['shelf_bearing']) - 2.0, e['shelf_bearing'])
    e['shelf'] = [round(sx, 3), wy(0.0), round(sy, 3)]
    e['portal_point'] = P3(pr, pb, bed_depth(pr, pb))
    e['lock'] = P3(pr, pb, RACE_TUNNEL_DEPTH)
    cx, cy = pol(WELL['axis'], e['well_bearing'])
    # the tunnel reaches the well on its near side, the helix runs round it, the last tunnel leaves on the near side
    near = brg(-cx, -cy)
    top = [round(cx + WELL['radius'] * math.cos(math.radians(near)), 3), wy(RACE_TUNNEL_DEPTH), round(cy + WELL['radius'] * math.sin(math.radians(near)), 3)]
    pts, end_a, run = helix(cx, cy, WELL['radius'], near, RACE_TUNNEL_DEPTH, rm['floor_depth'], WELL['pitch'], 1 if e['well_bearing'] < rm['bearing'] else -1)
    target = P3(rm['back'], rm['bearing'] + math.degrees(e['entry_offset'] / rm['back']), rm['floor_depth'])
    e['points'] = [e['lock']] + pts + [target]
    e['well'] = [round(cx, 3), round(cy, 3)]
    e['helix_run'] = round(run, 1); e['turns'] = round(run / (2 * math.pi * WELL['radius']), 2)
    e['ring'] = rm['ring']; e['width'] = 3.0

# ---------------------------------------------------------------- the dry ways: two crown stairs to C0
# Each is a glass kiosk on the lava promenade over a stair and lift core, then a level tunnel under the
# reservoir's bed to the Crown Gallery. Nothing below C0 is dry: it is a lookout, not a way in.
CROWN_STAIRS = [
    dict(id='CA', name='North crown stair', bearing=112.0, core=60.0, ground=30.2, note='on the promenade between Civic and Aro'),
    dict(id='CB', name='South crown stair', bearing=240.0, core=56.0, ground=30.1, note='on the promenade near the arrival, south of Renewal'),
]
for c in CROWN_STAIRS:
    c['points'] = [[*P3(c['core'], c['bearing'], 0)[:1], round(c['ground'], 3), P3(c['core'], c['bearing'], 0)[2]],
                   P3(c['core'], c['bearing'], C0['depth']), P3(C0['outer'], c['bearing'], C0['depth'])]
    c['rise'] = round(c['ground'] - wy(C0['depth']), 2); c['width'] = 3.2

# ---------------------------------------------------------------- service shafts (residents and goods, not public ways in)
SHAFTS = [
    dict(id='LK', name='Kel lift', plot='KEL', at=(57.6, -21.0), top=29.9, room='L4', entry_offset=-8.0, kind='lift'),
    dict(id='LV', name='Vara lift', plot='VARA', at=(59.0, 58.9), top=42.5, room='L5', entry_offset=0.0, kind='lift'),
    dict(id='LC', name='Civic lift', plot='CIVIC', at=(0.0, 78.0), top=42.5, room='L3', entry_offset=0.0, kind='lift'),
    # Aro's protected descent, already cut through its podium to a sealed bulkhead (FireCalderaPlan ARO pits).
    dict(id='LA', name='Aro descent', plot='ARO', at=(-51.0, 35.7), top=27.6, room='L1', entry_offset=0.0, kind='stair'),
]
for s in SHAFTS:
    rm = ROOM[s['room']]; x, y = s['at']
    foot = [x, wy(rm['floor_depth']), y]
    s['points'] = [[x, s['top'], y], foot, P3(rm['back'], rm['bearing'] + math.degrees(s['entry_offset'] / rm['back']), rm['floor_depth'])]
    s['rise'] = round(s['top'] - wy(rm['floor_depth']), 1)

# ---------------------------------------------------------------- return risers and relief
# Enclosed lava risers in the rock behind the shell, from the Return Gallery's intakes up past their valve
# station at the Steward Ring, then out under the reservoir's bank into the city's buried service spine.
RISER_OFFSET = 6.0
RISERS = [
    dict(id='V0', name='Aro return', bearing=145.0, station='L1', serves=['L0', 'L1'], relief='E1', relief_via=170.0, role='the civic return and the household thermal spine'),
    dict(id='V1', name='Kel return', bearing=-15.0, station='L4', serves=['L4', 'L5'], relief=None, role='the hot industrial return to the east bank'),
    dict(id='V2', name='Civic relief return', bearing=72.0, station=None, serves=['L2', 'L3'], relief='E2', relief_via=64.0, role='the instrumented return with the outward pressure-relief branch'),
]
# Emergency shelves on the surface, from FireCalderaPlan.emergency_spokes (bearing, radius 92).
REFUGES = {'E1': -175.0, 'E2': 65.0}
for v in RISERS:
    rr = R + RISER_OFFSET; pts = []
    for d in range(82, 23, -6):
        pts.append(P3(math.sqrt(max(rr * rr - (d - C_D) ** 2, 0)), v['bearing'], d))
    pts.append(P3(math.sqrt(rr * rr - (24 - C_D) ** 2), v['bearing'], 24))
    pts.append(P3(bank(v['bearing']) + 2.0, v['bearing'], 6.0))
    v['points'] = pts
    if v['relief']:
        b = REFUGES[v['relief']]; ox, oy = pol(92.0, b)
        start = pts[-2]
        v['relief_points'] = [start, P3(74.0, v['relief_via'], 12.0), [round(ox, 3), round(bowl_y(92.0) - 0.5, 3), round(oy, 3)]]

# ---------------------------------------------------------------- checks
FAILS = []
def fail(m): FAILS.append(m)
def ok(m): print('ok  ', m)

def dist3(p, q): return math.dist(p, q)
def seg_dist(p, a, b):
    ab = [b[i] - a[i] for i in range(3)]; ap = [p[i] - a[i] for i in range(3)]
    L = sum(c * c for c in ab); t = 0 if L == 0 else max(0, min(1, sum(ap[i] * ab[i] for i in range(3)) / L))
    return math.dist(p, [a[i] + ab[i] * t for i in range(3)])
def sample(pts, step=1.0):
    out = []
    for i in range(len(pts) - 1):
        a, b = pts[i], pts[i + 1]; n = max(1, int(math.dist(a, b) / step))
        out += [[a[j] + (b[j] - a[j]) * k / n for j in range(3)] for k in range(n)]
    return out + [pts[-1]]
def poly_dist(A, B):
    sa = sample(A, 1.5); return min(min(seg_dist(p, B[i], B[i + 1]) for i in range(len(B) - 1)) for p in sa)
def depth_of(p): return LAVA_Y - p[1]
def rho_b(p): return math.hypot(p[0], p[2]), brg(p[0], p[2])

def in_room(p, rm, margin=0.0):
    r, b = rho_b(p); d = depth_of(p)
    return (rm['front'] - margin <= r <= rm['back'] + margin and abs(adiff(b, rm['bearing'])) <= rm['half_angle'] + math.degrees(margin / max(r, 1))
            and rm['floor_depth'] - rm['tall'] - margin <= d <= rm['floor_depth'] + margin)

def inside_sphere(p, margin=0.0):
    r, _ = rho_b(p); d = depth_of(p)
    return math.hypot(r, d - C_D) < R + SH + margin

def cover_above(p):
    """Rock between a tunnel's crown (3.5 m above its floor) and the lava or ground above it."""
    r, b = rho_b(p); d = depth_of(p)
    return (d - 3.5) - bed_depth(r, b)

# 1. the section
if not (CROWN['shelf_depth'] < C0['ceiling'] - 1.5 + 0.001): fail('the Crown Gallery has under 1.5 m of roof under the settling shelf')
else: ok('Crown Gallery roof %.1f m under the settling shelf' % (C0['ceiling'] - CROWN['shelf_depth']))
under = min(cap_depth(r, R + SH) - C0['depth'] for r in [C0['inner'], C0['outer']])
if under < 3.0: fail('the Crown Gallery stands %.1f m over the shell' % under)
else: ok('Crown Gallery floor %.1f m over the shell\'s crown' % under)
top = cap_depth(0, R + SH)
if top < CROWN['shelf_depth'] + 4: fail('the throat is only %.1f m deep over the cap' % (top - CROWN['shelf_depth']))
else: ok('throat %.0f m across, %.1f to %.1f m deep over the cap' % (2 * CROWN['throat_radius'], top, cap_depth(CROWN['throat_radius'], R + SH)))
if BASIN['pool_depth'] >= C_D + R: fail('the basin pool is below the sphere')

# 2. rings: headroom over the whole floor, below the next ring's floor, and room behind for the rooms
prev = C0['depth']
for g in RINGS:
    for k in range(9):
        rho = g['inner'] + RING_WIDTH * k / 8
        if rho <= g['shell_rho'] + 1e-6 and g['depth'] > C_D:
            head = g['depth'] - C_D + math.sqrt(max(R * R - rho * rho, 0))   # open to the shell above (lower hemisphere)
            head = max(head, RING_HEADROOM)
        elif rho < g['shell_rho']:
            head = g['depth'] - cap_depth(rho)
            head = max(head, 0) if head < RING_HEADROOM else head
            if rho >= sphere_rho(g['depth'] - RING_HEADROOM): head = max(head, RING_HEADROOM)
        else:
            head = RING_HEADROOM
        if head < 3.0: fail('%s has %.1f m of headroom at %.1f m out' % (g['id'], head, rho)); break
    if g['depth'] - prev < 10: fail('%s is %.0f m under the ring above' % (g['id'], g['depth'] - prev))
    prev = g['depth']
ok('rings C1 to C5 at %s m, 4.2 m wide, every floor with 3 m or more of headroom' % ', '.join('%.0f' % g['depth'] for g in RINGS))

# 3. falls: sluiced through the cap, landing in their catch, and off every walk
WALKS = []   # (name, polyline or point set, depth) of open walking surfaces in the void
for g in RINGS:
    WALKS.append((g['id'], [P3(g['inner'], a, g['depth']) for a in range(0, 361, 5)]))
cx = CROSSING
a, b = cx['ends']
WALKS.append(('the Civic Crossing', [P3(RING['C2']['inner'], a, 38.0), P3(RING['C2']['inner'], b, 38.0)]))
WALKS.append(('the Forge Arm walk', [P3(FORGE_ARM['walk_from'], FORGE_ARM['bearing'] + 6, 52.0), P3(FORGE_ARM['outer'], FORGE_ARM['bearing'] + 3, 52.0)]))
sh = RENEWAL_SHELF
WALKS.append(('the Renewal shelf', [P3(sh['walk_from'], sh['bearing'] + t, 24.0) for t in range(-15, 16, 3)]))
for f in FALLS:
    x, y = pol(f['rho'], f['bearing'])
    if f['sluice'] and f['rho'] + f['top'] / 2 > CROWN['throat_radius']: fail('%s\'s sluice is outside the throat' % f['id'])
    if f['sluice'] and f['rho'] - f['top'] / 2 < CROWN['lens_radius']: fail('%s cuts the oculus lens' % f['id'])
    if f['lands'] == 'basin' and f['rho'] + f['bottom'] / 2 > BASIN['pool_radius']: fail('%s misses the basin pool' % f['id'])
    if f['lands'] == 'renewal_shelf' and not (sh['pool'][0] + f['bottom'] / 2 <= f['rho'] <= sh['pool'][1] - f['bottom'] / 2): fail('F2 misses the tempering pool')
    if f['lands'] == 'splitter' and abs(f['rho'] - FORGE_ARM['splitter']['rho']) + f['bottom'] / 2 > FORGE_ARM['splitter']['radius']: fail('F1 misses the splitter bowl')
    for name, pts in WALKS:
        own = (f['id'] in ('F2', 'F2v') and name == 'the Renewal shelf') or (f['id'] in ('F1', 'F1v') and name == 'the Forge Arm walk')
        if own: continue
        for p in sample(pts, 1.0):
            d = depth_of(p)
            if f['from_depth'] - 1 <= d <= f['land_depth'] + 1:
                gap = math.hypot(p[0] - x, p[2] - y) - f['top'] / 2
                if gap < 6.0: fail('%s passes %.1f m from %s' % (f['id'], gap, name)); break
# a fall that reaches the basin crosses no ring floor between (its plan point is inside every ring's inner edge)
ok('%d falls and veils: sluiced inside the throat, each landing in its catch, 6 m or more clear of every walk' % len(FALLS))
# no walk over an impact
for f in FALLS:
    if f['lands'] != 'basin': continue
    x, y = pol(f['rho'], f['bearing'])
    for name, pts in WALKS:
        for p in sample(pts, 1.0):
            if math.hypot(p[0] - x, p[2] - y) < 6.0 and depth_of(p) < f['land_depth']:
                if not ((f['id'] == 'F2v' and name == 'the Renewal shelf') or (f['id'] == 'F1v' and name == 'the Forge Arm walk')):
                    fail('%s crosses over %s\'s impact' % (name, f['id'])); break
ok('no walk crosses over an impact in the basin')

# 4. rooms: apart on their ring, clear of the void, deep enough in rock
by_ring = {}
for rm in ROOMS: by_ring.setdefault(rm['ring'], []).append(rm)
for ring, rs in by_ring.items():
    for i in range(len(rs)):
        for j in range(i + 1, len(rs)):
            gap = abs(adiff(rs[i]['bearing'], rs[j]['bearing'])) - rs[i]['half_angle'] - rs[j]['half_angle']
            if gap * math.pi / 180 * rs[i]['front'] < 3.0: fail('%s and %s are under 3 m apart on %s' % (rs[i]['id'], rs[j]['id'], ring))
ok('%d rooms, none closer than 3 m to its neighbour on the same ring' % len(ROOMS))

# 5. links: stair pitch, doors off rooms, and no stair through a room
for k in LINKS:
    for ring, bearing in ((k['upper'], k['bearing']), (k['lower'], k['end_bearing'])):
        for rm in by_ring.get(ring, []):
            if abs(adiff(bearing, rm['bearing'])) < rm['half_angle'] + math.degrees(4.0 / rm['front']):
                fail('%s\'s door on %s opens into %s' % (k['id'], ring, rm['id']))
    for rm in ROOMS:
        if any(in_room(p, rm, 1.0) for p in sample(k['points'][1:-1], 1.0)): fail('%s runs through %s' % (k['id'], rm['id']))
ok('%d ring stairs at a %.0f-degree pitch, doors clear of the rooms' % (len(LINKS), math.degrees(math.atan(STAIR_PITCH))))

# 6. tunnels and shafts: rock cover, outside the shell, and apart from one another
TUNNELS = [(e['id'], e['points']) for e in ENTRIES] + [(c['id'], c['points'][1:]) for c in CROWN_STAIRS] + [(s['id'], s['points']) for s in SHAFTS] \
    + [(k['id'], k['points'][1:-1]) for k in LINKS] + [(v['id'], v['points']) for v in RISERS] + [(v['id'] + 'r', v['relief_points']) for v in RISERS if v['relief']]
for name, pts in [(e['id'], e['points'][1:-1]) for e in ENTRIES] + [(c['id'], c['points'][1:-1]) for c in CROWN_STAIRS] + [(k['id'], k['points'][1:-1]) for k in LINKS]:
    for p in sample(pts, 1.0):
        if inside_sphere(p, 1.0): fail('%s enters the shell at %s' % (name, [round(v, 1) for v in p])); break
for name, pts in [(e['id'], [e['lock']] + e['points'][1:]) for e in ENTRIES] + [(c['id'], c['points'][1:]) for c in CROWN_STAIRS]:
    worst = min(cover_above(p) for p in sample(pts, 1.0))
    if worst < 1.5: fail('%s has %.1f m of rock over it' % (name, worst))
ok('entries and crown tunnels: 1.5 m or more of rock under the lava and the ground, never through the shell')
# clearances between separate ways (their own meeting points excepted)
MEET = {('S2', 'LK'), ('S1', 'LC')}
for i in range(len(TUNNELS)):
    for j in range(i + 1, len(TUNNELS)):
        (ni, pi), (nj, pj) = TUNNELS[i], TUNNELS[j]
        if (ni, nj) in MEET or (nj, ni) in MEET or nj == ni + 'r' or ni == nj + 'r': continue
        # ways that both end in the same room meet there; compare everything but their last 6 m
        def trim(pts):
            out = list(pts); L = 0
            while len(out) > 2 and L < 6: L += math.dist(out[-1], out[-2]); out.pop()
            return out
        gap = poly_dist(trim(pi), trim(pj))
        if gap < 6.0: fail('%s and %s pass %.1f m apart' % (ni, nj, gap))
ok('every tunnel, well, shaft, stair and riser 6 m or more from the others')
for e in ENTRIES:
    rm = ROOM[e['room']]
    # the well and its tunnels stay outside every room but their own
    for other in ROOMS:
        if other['id'] == rm['id']: continue
        if any(in_room(p, other, 2.0) for p in sample(e['points'], 1.0)): fail('%s passes through %s' % (e['id'], other['id']))
    if e['turns'] > 4.5: fail('%s winds %.1f turns' % (e['id'], e['turns']))
ok('entries: %s' % ', '.join('%s %.1f turns to %s' % (e['id'], e['turns'], e['ring']) for e in ENTRIES))

# 7. every ring reaches the surface two ways, the dry Crown Gallery never reaches the lava rings
EDGES = [('surface', 'C0', c['id'], 'dry') for c in CROWN_STAIRS] + [('surface', e['ring'], e['id'], 'lava') for e in ENTRIES] \
    + [(k['upper'], k['lower'], k['id'], 'ring') for k in LINKS]
def reach(edges, start='surface'):
    seen = {start}; grow = True
    while grow:
        grow = False
        for a, b, _, _ in edges:
            if a in seen and b not in seen: seen.add(b); grow = True
            if b in seen and a not in seen: seen.add(a); grow = True
    return seen
for g in ['C0'] + [r['id'] for r in RINGS]:
    for cut in EDGES:
        if g not in reach([e for e in EDGES if e is not cut]): fail('%s is cut off from the surface without %s' % (g, cut[2]))
if 'C1' in reach([e for e in EDGES if e[3] != 'lava']): fail('the lava rings can be reached without passing through lava')
ok('every ring keeps a way to the surface with any one way closed; nothing below the Crown Gallery is reachable dry')

# 8. relief vents away from the gate, the inn and the big glass fronts
for v in RISERS:
    if v['relief']:
        end = v['relief_points'][-1]; b = brg(end[0], end[2])
        if abs(adiff(b, -90)) < 50: fail('%s vents toward the gate' % v['id'])
ok('relief vents to the west and far shelves only')

if FAILS:
    print('\n'.join('FAIL ' + f for f in FAILS)); sys.exit(1)

# ---------------------------------------------------------------- write
SECTION = dict(lava_y=LAVA_Y, sphere=SPHERE, crown=CROWN, basin=BASIN, ring_width=RING_WIDTH, ring_headroom=RING_HEADROOM,
               stair_pitch=STAIR_PITCH, well=WELL, race_tunnel_depth=RACE_TUNNEL_DEPTH)
HEADER = [
    'The Caldera Heartworks (docs/architecture/fire_caldera_heartworks.md): the spherical chamber under',
    'the Fire Caldera\'s reservoir, its crown, rings, falls, rooms, ways in and return system.',
    'Frame: FireCalderaPlan\'s local plan frame. Bearings in degrees, atan2(y, x): Kel about 0, Civic 90,',
    'Renewal 180, the gate -90. Depths are metres below FireCalderaGround.LAVA_Y, positive down.',
    '3D points are [x, world Y, y] in the local frame.',
    'Status: proposed for review; nothing in the live world reads it yet. It supersedes FireCalderaPlan\'s',
    'HEARTWORKS, HEART_LEVELS, HEART_FALLS, HEART_RISERS and LOWER_ROOMS when it is approved.',
]
CONSTS = dict(
    SECTION=('# the section: the sphere, the crown and throat, the basin, ring and stair sizes', SECTION),
    CROWN_GALLERY=('# C0: the dry ring round the throat', C0),
    RINGS=('# C1 to C5, following the shell: inner and outer are plan radii of the floor', RINGS),
    FALLS=('# the falls and their veils: rho is the plan radius of the sheet, top and bottom its widths', FALLS),
    RENEWAL_SHELF=('# the deck held out from the Steward Ring, with the tempering pool F2 falls into', RENEWAL_SHELF),
    FORGE_ARM=('# the arm across the void at the Works Ring, with the splitter bowl under F1', FORGE_ARM),
    CROSSING=('# the Civic Crossing: a chord across the void at the Civic Ring', CROSSING),
    ROOMS=('# rooms behind the rings: front and back are plan radii, half_angle in degrees', ROOMS),
    LINKS=('# enclosed stairs between the rings', [{k: v for k, v in l.items()} for l in LINKS]),
    ENTRIES=('# the three lava entries: shelf, bed portal and lock, race well, room', ENTRIES),
    CROWN_STAIRS=('# the two dry ways down to the Crown Gallery', CROWN_STAIRS),
    SHAFTS=('# service lifts and Aro\'s descent: residents and goods only', SHAFTS),
    RISERS=('# return risers, and the relief branches to the emergency shelves', RISERS),
)
write_plan('FireCalderaHeartworksPlan', 'fire_caldera_heartworks_plan.gd', HEADER, CONSTS, 'tools/fire_caldera_heartworks_layout.py')
# The model shows the surface beside the chamber. The surface comes from the Godot export of FireCalderaPlan
# (tools/validate_fire_plan.tscn -- --model-json=surface.json), passed with --surface; without it the
# surface already embedded in the page is kept.
PAGE = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'docs', 'drawings', 'fire_caldera_3d.html')
# Routes an older export still carries that FireCalderaPlan no longer builds: Kel's Highline ribbon (H5),
# removed when Kel kept its own circulation (fire_caldera_layout.md, section 10).
RETIRED_ROUTES = {'H5'}
SURFACE_KEYS = ('frame', 'reservoir', 'terrain', 'plots', 'routes')

def surface_data():
    if '--surface' in sys.argv:
        data = json.load(open(sys.argv[sys.argv.index('--surface') + 1]))
    else:
        import re
        m = re.search(r'/\*DATA\*/(.*?)/\*END\*/', open(PAGE).read(), re.S)
        data = json.loads(m.group(1)) if m else {}
        data = data.get('surface', data)
    out = {k: data[k] for k in SURFACE_KEYS if k in data}
    out['routes'] = [r for r in out.get('routes', []) if r['id'] not in RETIRED_ROUTES]
    return out

if '--json' in sys.argv:
    path = sys.argv[sys.argv.index('--json') + 1]
    heart = dict(section=SECTION, crown_gallery=C0, rings=RINGS, falls=FALLS, renewal_shelf=RENEWAL_SHELF, forge_arm=FORGE_ARM,
                 crossing=CROSSING, rooms=ROOMS, links=LINKS, entries=ENTRIES, crown_stairs=CROWN_STAIRS, shafts=SHAFTS,
                 risers=RISERS, refuges=REFUGES, lobes=LOBES, reservoir_mean=RESERVOIR_MEAN)
    json.dump(dict(surface=surface_data(), heart=heart), open(path, 'w'), separators=(',', ':'))
print('wrote scripts/fire_caldera_heartworks_plan.gd: %d rings, %d falls, %d rooms, %d stairs, %d entries, %d service shafts, %d risers'
      % (len(RINGS) + 1, len(FALLS), len(ROOMS), len(LINKS), len(ENTRIES), len(SHAFTS), len(RISERS)))
