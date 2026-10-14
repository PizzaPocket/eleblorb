"""Authoring tool for the Sky Kingdom's six courts (docs/architecture/sky_kingdom_layout.md,
_buildings.md and _interiors.md). It holds the frame, the islands, every building with
its podium, ramp and heights, each court's landing forecourt and walking routes, and the
cloud groves; checks them; and writes JSON for the 3D model.

    python3 tools/sky_kingdom_layout.py [--json out.json]

Frame (layout section 1): origin at the Air Gem landing, about 89 m up; u forward, away
from Ohio; v to the right of u; h up from the landing. Proposed: the staircase anchor is
fixed on Ohio's north side with u pointing world north, so v is world east.

Each island has its own local (x, z) in metres from its centre: -z faces its landing
forecourt, toward whatever the visitor arrives from (the staircase for the Dawn Gate
cloud, the gate for Aethra, Aethra for the four courts round Koinon and for Koinon), and
+x is to the right when facing +z.
"""
import json, math, sys
from shapely.geometry import Polygon, Point, LineString, box
from shapely.ops import unary_union
from shapely import affinity

def rad(b): return math.radians(b)

LANDING_WORLD_Y = 89.0
AMBIENT = (87.5, 137.5)           # CloudScatter altitude band
ISLAND_GAP = 60.0                 # least centre-to-centre distance
RAMP_ANGLE = 32.0
LANDING = 1.2
TIER = 1.0                        # podium tier height
ROUTE = 3.0                       # public route width inside a court
EDGE = 1.5                        # a route nearer the cloud's edge than this needs a balustrade
CLEAR = 3.0                       # buildings keep at least this apart
FORECOURT_MIN = 12.0
TEMPESTAR_ROOM = 5.0              # clear height a Tempestar's room needs to the roof's underside
TEMPESTAR_OPENING = 4.0

## ---- islands: key, name, centre (u, v, h), radius, character
ISLANDS = {
    'gate':    dict(name='Dawn Gate cloud', c=(0.0, 0.0, 0.0), r=20.0, faces='stair'),           # was 16: the gate, its ramp and a 12 m forecourt need 20
    'aethra':  dict(name='Aethra', c=(70.0, 0.0, 28.0), r=40.0, faces='gate'),
    'koinon':  dict(name='Koinon', c=(170.0, 0.0, 6.0), r=40.0, faces='aethra', void=7.0),     # was 36: the observatory's spiral needs room clear of the hall
    'pantao':  dict(name='Pantao', c=(150.0, -85.0, 16.0), r=38.0, faces='aethra'),
    'chrysa':  dict(name='Chrysa', c=(230.0, -60.0, 2.0), r=28.0, faces='aethra', crown=18.0),
    'lyria':   dict(name='Lyria', c=(230.0, 65.0, 20.0), r=30.0, faces='aethra'),
    'dromos':  dict(name='Dromos', c=(140.0, 90.0, 8.0), r=46.0, faces='aethra'),
}
def facing(k):
    """Unit (du, dv) of the island's local +z: away from what the visitor arrives from."""
    c = ISLANDS[k]['c']; f = ISLANDS[k]['faces']
    src = (-40.0, 0.0) if f == 'stair' else ISLANDS[f]['c'][:2]
    d = (c[0] - src[0], c[1] - src[1]); L = math.hypot(*d)
    return (d[0] / L, d[1] / L)
def to_frame(k, x, z):
    """Island-local (x, z) to frame (u, v)."""
    fu, fv = facing(k); c = ISLANDS[k]['c']
    # local +z along (fu, fv); local +x to its right: (u, v) rotated so that v is right of u
    ru, rv = (-fv, fu)
    return (c[0] + fu * z + ru * x, c[1] + fv * z + rv * x)
EAST = (0.0, 1.0)                 # world east in the frame: +v (proposed heading, see the docstring)
def local_dir(k, du, dv):
    fu, fv = facing(k); ru, rv = (-fv, fu)
    return (du * ru + dv * rv, du * fu + dv * fv)     # (x, z)

## ---- buildings. shape: ('rect', w, d) along local x and z; ('circle', diameter); ('ring', inner, outer);
## ('semi', diameter) a half disc opening toward -z. podium: tiers of 1 m. cols: column height;
## gap: the height of what the columns carry, a cloud capital (Greek) or a gold bracket set (Chinese), which shows rank; roof: 'xieshan', 'xieshan2', 'gable', 'dome', 'cap', 'none'.
## door: which side the entrance faces ('-z', '+z', '-x', '+x', or a bearing in degrees in local x->z).
B = []
def bld(island, key, name, style, shape, c, podium=0, cols=4.4, gap=0.6, roof='dome', door='-z', who='', program='',
        ramp_w=None, kind='building', **extra):
    B.append(dict(island=island, key=key, name=name, style=style, shape=shape, c=c, podium=podium, cols=cols, gap=gap,
                  roof=roof, door=door, who=who, program=program, ramp_w=ramp_w, kind=kind, **extra))
FORE = {}   # island: (x, z, w, d)

# Dawn Gate cloud
bld('gate', 'dawn_gate', 'Dawn Gate', 'chinese', ('rect', 14.0, 6.0), (0.0, 4.0), podium=1, cols=5.5, gap=1.0, roof='xieshan',
    door='-z', program='threshold; two empty bases in the side bays', ramp_w=6.0, through=True)
FORE['gate'] = (0.0, -11.0, 12.0, 12.0)

# Aethra
bld('aethra', 'hall_of_mist', 'Hall of Mist', 'chinese', ('rect', 22.0, 14.0), (0.0, 8.0), podium=3, cols=6.4, gap=1.6,
    roof='xieshan2', who='Aristeon', program="audience hall; the throne dais; side galleries", ramp_w=4.0, rear_bay=3.2)
bld('aethra', 'propylon', 'Propylon', 'chinese', ('rect', 10.0, 5.0), (0.0, -22.0), podium=0, cols=4.4, gap=0.6, roof='xieshan',   # no podium: its ramp took the forecourt
    program="the court's gate", ramp_w=4.0, through=True)
bld('aethra', 'mnesia', "Chamberlain's tholos", 'greek', ('circle', 7.0), (-20.0, -6.0), who='Mnesia', door='+x',
    program='ledger room, reading table, robe press; sleeping alcove')
bld('aethra', 'herald', "Herald's moored room", 'sky', ('circle', 5.0), (-43.0, -6.0), roof='none', who='Alkis', door='+x',
    program='a set-cloud room in gold rings, its door open to the sky', kind='moored')
bld('aethra', 'nectar_aethra', 'Nectar terrace', 'greek', ('rect', 5.0, 18.0), (32.0, 0.0), roof='cap', who='Drosia', door='-x',
    program='gold dew bowls between the columns; the pouring table', kind='terrace')
bld('aethra', 'aristeon', "Aristeon's tholos", 'greek', ('circle', 9.0), (-10.0, 31.0), podium=1, gap=1.0, who='Aristeon',
    door='+x', program='couch, dew basin, robe press')
bld('aethra', 'drosia', "Drosia's tholos", 'greek', ('circle', 6.0), (11.0, 29.0), who='Drosia', door='-z',
    program='couch; racks of dew bowls')
FORE['aethra'] = (0.0, -32.0, 16.0, 13.0)
VIA = {'aethra': (0.0, -16.5)}     # every way into Aethra passes through the propylon

# Koinon
bld('koinon', 'assembly', 'Hall of Assembly', 'greek', ('ring', 16.0, 30.0), (0.0, 0.0), podium=1, cols=5.5, gap=1.0, roof='cap',
    who='Archeia (tends it)', program='six seats round the void; the sealing decree', ramp_w=3.0, walkthrough=True)
bld('koinon', 'observatory', 'Observatory', 'greek', ('circle', 9.0), (0.0, 29.0), podium=4, gap=1.0, who='Astrion', door='-z',
    program='armillary, star tables', ramp='spiral', ramp_w=2.0)
bld('koinon', 'archive', 'Archive', 'greek', ('rect', 10.0, 7.0), (-27.0, 8.0), podium=1, roof='gable', who='Archeia', door='-z',
    program='gold-leaf records; the only hung leaf', ramp_w=3.0)
bld('koinon', 'philosopher', "Philosopher's residence", 'greek', ('rect', 12.0, 8.0), (25.0, 10.0), roof='gable',
    who='Sophrona, Astrion, Archeia', door='-x', program='three rooms round a sky-lily court')
FORE['koinon'] = (0.0, -28.0, 14.0, 12.0)

# Pantao
bld('pantao', 'banquet', 'Banquet hall', 'chinese', ('rect', 20.0, 12.0), (0.0, 4.0), podium=1.5, cols=5.5, gap=1.0, roof='xieshan',
    who='Xiangyun', program='couches in two arcs; the dais; serving passage behind', ramp_w=4.0, rear_bay=2.4)
bld('pantao', 'peach_garden', 'Peach Garden', 'landscape', ('rect', 26.0, 18.0), (0.0, 26.0), roof='none', who='Chunlu',
    program='cloud peach groves; the first-peach tree on its mound', kind='garden')
bld('pantao', 'kitchen', 'Kitchen pavilion', 'chinese', ('rect', 8.0, 6.0), (-20.0, -4.0), roof='xieshan', who='Tianlu', door='+x',
    program='gold baking plates in full sun; no fire')
bld('pantao', 'open_table', 'Open table', 'greek', ('rect', 12.0, 3.0), (0.0, -20.5), roof='cap', door='-z',
    program='the leftover table on gold tripods', kind='terrace')
bld('pantao', 'pantao_res', 'Residence', 'chinese', ('rect', 14.0, 10.0), (22.0, -6.0), roof='xieshan', who='Xiangyun, Mingyue, Tianlu, Chunlu',
    door='-x', program='three pavilions round a court, entered by a moon gate')
FORE['pantao'] = (0.0, -28.0, 14.0, 12.0)

# Chrysa
bld('chrysa', 'forge', 'Forge hall', 'greek', ('rect', 16.0, 10.0), (0.0, 4.0), podium=1, cols=5.5, gap=1.0, roof='gable',
    who='Aurelia', program='three anvils; cooling basins; the lightning collector', ramp_w=4.0)
bld('chrysa', 'storm_terrace', 'Storm terrace', 'sky', ('rect', 10.0, 8.0), (0.0, 18.0), roof='none', who='Keraunia',
    program='weather instruments under the crown', kind='terrace')
bld('chrysa', 'bench', "Apprentice's bench", 'greek', ('rect', 6.0, 4.0), (15.0, 4.0), roof='cap', who='Kallix', door='-x',
    program='unfinished pieces on every surface')
bld('chrysa', 'chrysa_res', 'Residence', 'greek', ('rect', 10.0, 8.0), (-16.0, -10.0), roof='gable', who='Aurelia, Kallix, Keraunia',
    door='+x', program='three rooms; scorched gold')
FORE['chrysa'] = (0.0, -20.0, 12.0, 12.0)

# Lyria
bld('lyria', 'odeon', 'Odeon', 'greek', ('semi', 24.0), (0.0, 6.0), cols=5.5, gap=1.0, roof='cap', who='Elegon, Aulia',
    program='six tiers of set-cloud seats; the stage with its wind harps', stage=(10.0, 5.0))
bld('lyria', 'poet', "Poet's residence", 'greek', ('rect', 10.0, 8.0), (-14.0, -8.0), roof='gable', who='Elegon, Aulia, Rhapsos',
    door='+x', program='three rooms and a writing room facing the odeon')
bld('lyria', 'song_room', 'Song room', 'greek', ('circle', 7.0), (15.0, -8.0), who='Rhapsos', door='-x',
    program='gold-leaf verse in niches; a practice floor')
FORE['lyria'] = (0.0, -22.0, 12.0, 12.0)

# Dromos
bld('dromos', 'track', 'Racing ring', 'landscape', ('ring', 68.0, 80.0), (0.0, 0.0), roof='none', program='the wind-race track', kind='track')
bld('dromos', 'judges', "Judges' tholos", 'greek', ('circle', 8.0), (0.0, -27.5), podium=2, gap=1.0, who='Nikandra', door='+z',
    program="the judge's seat; the record of victories", ramp_w=2.0)
bld('dromos', 'prize', 'Prize pavilion', 'greek', ('rect', 8.0, 6.0), (14.0, -20.0), roof='gable', who='Stephane', door='-x',
    program='rings and woven-cloud wreaths')
bld('dromos', 'dromos_res', 'Residence', 'greek', ('rect', 12.0, 10.0), (0.0, 18.0), roof='gable', who='Nikandra, Dromeus, Tachys, Stephane',
    door='-z', program='four rooms round a small court')
FORE['dromos'] = (-16.0, -12.0, 12.0, 12.0)

## ---- cloud groves (interiors brief section 3): island, kind, centre (x, z), count, spread
GROVES = [
    ('gate', 'tier_pine', (-11.0, 3.0), 1, 0.0), ('gate', 'tier_pine', (11.0, 3.0), 1, 0.0),
    ('aethra', 'tier_pine', (-4.6, -5.5), 1, 0.0), ('aethra', 'tier_pine', (4.6, -5.5), 1, 0.0),   # flanking the hall's ramp
    ('aethra', 'peach', (26.0, 14.0), 1, 0.0), ('aethra', 'puff', (0.0, -39.0), 6, 7.0),
    ('koinon', 'willow', (-12.0, 31.0), 1, 0.0), ('koinon', 'willow', (12.0, 31.0), 1, 0.0),
    ('pantao', 'peach', (0.0, 26.5), 9, 7.0), ('pantao', 'peach', (0.0, 26.5), 1, 0.0), ('pantao', 'puff', (0.0, -34.5), 5, 6.0),
    ('chrysa', 'puff', (-18.0, -18.0), 3, 2.0),
    ('lyria', 'willow', (-15.5, 12.0), 1, 0.0), ('lyria', 'willow', (15.5, 12.0), 1, 0.0), ('lyria', 'willow', (0.0, 22.5), 1, 0.0), ('lyria', 'puff', (0.0, -28.0), 3, 4.0),
] + [('dromos', 'puff', (27.0 * math.cos(rad(b)), 27.0 * math.sin(rad(b))), 1, 0.0) for b in (20, 60, 120, 160, 200, 240, 320, 340)] + [
    ('dromos', 'tier_pine', (7.0, -31.0), 1, 0.0),
]
TREE_R = {'tier_pine': 3.2, 'peach': 3.6, 'willow': 3.4, 'puff': 1.4}

## ---- the prototype as built today (sky_kingdom.gd): offsets (forward, side, up) and radii
BUILT = [dict(name='Highcloud (Aethra)', c=(45.0, 0.0, 22.0), r=46.0),
         dict(name='Anvil Cloud (Chrysa)', c=(128.0, 72.0, 8.0), r=30.0),
         dict(name='Drift Cloud (Lyria)', c=(93.0, -75.0, -15.0), r=30.0),
         dict(name='Hollow Cloud (Koinon)', c=(195.0, 0.0, 21.0), r=30.0)]

# ---- geometry
TAN = math.tan(rad(RAMP_ANGLE))
def door_vec(b):
    d = b['door']
    if isinstance(d, (int, float)): return (math.cos(rad(d)), math.sin(rad(d)))
    return {'-z': (0, -1), '+z': (0, 1), '-x': (-1, 0), '+x': (1, 0)}[d]
def shape_poly(b, grow=0.0):
    x, z = b['c']; s = b['shape']
    if s[0] == 'rect':
        extra = b.get('rear_bay', 0.0)
        p = box(x - s[1] / 2, z - s[2] / 2, x + s[1] / 2, z + s[2] / 2 + extra)
    elif s[0] == 'circle': p = Point(x, z).buffer(s[1] / 2, 32)
    elif s[0] == 'ring': p = Point(x, z).buffer(s[2] / 2, 64).difference(Point(x, z).buffer(s[1] / 2, 64))
    elif s[0] == 'semi':
        p = Point(x, z).buffer(s[1] / 2, 64).intersection(box(x - s[1], z, x + s[1], z + s[1]))
        if b.get('stage'): p = p.union(box(x - b['stage'][0] / 2, z - b['stage'][1], x + b['stage'][0] / 2, z))
    return p.buffer(grow, 8) if grow else p
def podium_poly(b):
    """The building with its podium: 1 m of podium beyond the footprint per tier, at most 2 m."""
    return shape_poly(b, min(2.0, 0.6 * b['podium'] + 0.4)) if b['podium'] else shape_poly(b)
def ramp_run(b):
    t = b['podium']; n = max(1, math.ceil(t / TIER))
    return t / TAN + (n + 1) * LANDING      # flights plus a landing at the foot, each tier and the head
def ramp_poly(b):
    """The axial ramp in front of the door, from the podium's edge out."""
    if not b['podium'] or b.get('ramp') == 'spiral' or b['shape'][0] == 'ring': return None
    pp = podium_poly(b); dx, dz = door_vec(b); w = b['ramp_w'] or 3.0; run = ramp_run(b)
    minx, minz, maxx, maxz = pp.bounds; x, z = b['c']
    if (dx, dz) == (0, -1): return box(x - w / 2, minz - run, x + w / 2, minz)
    if (dx, dz) == (0, 1): return box(x - w / 2, maxz, x + w / 2, maxz + run)
    if (dx, dz) == (-1, 0): return box(minx - run, z - w / 2, minx, z + w / 2)
    return box(maxx, z - w / 2, maxx + run, z + w / 2)
def spiral_poly(b):
    if b.get('ramp') != 'spiral': return None
    r = shape_poly(b).bounds; rr = (r[2] - r[0]) / 2 + min(2.0, 0.6 * b['podium'] + 0.4)
    return Point(b['c']).buffer(rr + b['ramp_w'] + 0.2, 32)
def door_point(b):
    """Where a route meets the building: the ramp's foot, or the footprint's edge on the door side.
    A moored room is reached by its gangway from a pier 2.5 m inside the cloud's edge."""
    dx, dz = door_vec(b)
    if b['kind'] == 'moored':
        x, z = b['c']; R = ISLANDS[b['island']]['r']; L = math.hypot(x, z)
        return (x / L * (R - 3.0), z / L * (R - 3.0))
    rp = ramp_poly(b) or spiral_poly(b)
    base = rp if rp is not None else podium_poly(b)
    x, z = b['c']; L = 80
    ray = LineString([(x, z), (x + dx * L, z + dz * L)])
    hit = ray.intersection(base.boundary)
    pts = [hit] if hit.geom_type == 'Point' else list(getattr(hit, 'geoms', []))
    far = max(pts, key=lambda p: Point(x, z).distance(p)) if pts else Point(x, z)
    return (far.x + dx * 0.4, far.y + dz * 0.4)
def footprint_all(b):
    parts = [podium_poly(b)]
    for p in (ramp_poly(b), spiral_poly(b)):
        if p is not None: parts.append(p)
    return unary_union(parts)

problems = []; notes = []
# 1. islands: inside the ambient band, apart, and their buildings' heights
for k, isl in ISLANDS.items():
    if k == 'gate': continue          # the landing itself: the top of the course, at the band's floor by design
    wy = LANDING_WORLD_Y + isl['c'][2]
    top = wy + isl.get('crown', 0) + 12
    if not (AMBIENT[0] <= wy - 3 and top <= AMBIENT[1] + 12): problems.append((k, 'outside the ambient cloud band (%.0f m)' % wy))
ks = list(ISLANDS)
for i in range(len(ks)):
    for j in range(i + 1, len(ks)):
        a, b_ = ISLANDS[ks[i]], ISLANDS[ks[j]]
        d = math.dist(a['c'], b_['c'])
        if d < ISLAND_GAP and 'gate' not in (ks[i], ks[j]): problems.append((ks[i], ks[j], 'only %.0f m apart centre to centre' % d))
# 2. buildings: on their island, apart, Tempestar heights
by_island = {}
for b in B: by_island.setdefault(b['island'], []).append(b)
for k, bs in by_island.items():
    R = ISLANDS[k]['r']; disc = Point(0, 0).buffer(R - 0.5, 64)
    for b in bs:
        fp = footprint_all(b)
        if b['kind'] != 'moored' and not disc.contains(fp): problems.append((k, b['key'], 'reaches off the cloud (%.1f m past the edge)' % (fp.exterior.distance(Point(0, 0)) if False else max(math.hypot(*q) for q in (fp.exterior.coords if fp.geom_type == 'Polygon' else fp.convex_hull.exterior.coords)) - R)))
        if b['kind'] == 'building' and b['roof'] not in ('none',) and b['cols'] + b['gap'] < TEMPESTAR_ROOM - 1e-6:
            problems.append((k, b['key'], 'leaves %.1f m to the roof, under the %.1f m a Tempestar needs' % (b['cols'] + b['gap'], TEMPESTAR_ROOM)))
    if ISLANDS[k].get('void'):
        v = Point(0, 0).buffer(ISLANDS[k]['void'] + 1.0)
        for b in bs:
            if b['shape'][0] != 'ring' and footprint_all(b).intersects(v): problems.append((k, b['key'], 'stands at the void'))
    for i in range(len(bs)):
        for j in range(i + 1, len(bs)):
            a, c = bs[i], bs[j]
            if 'track' in (a['kind'], c['kind']):
                inside = [x for x in (a, c) if x['kind'] != 'track'][0]
                tr = [x for x in (a, c) if x['kind'] == 'track'][0]
                if footprint_all(inside).intersects(shape_poly(tr)): problems.append((k, inside['key'], 'stands on the racing track'))
                continue
            g = footprint_all(a).distance(footprint_all(c))
            if g < CLEAR - 1e-6: problems.append((k, a['key'], c['key'], 'only %.1f m apart (podiums and ramps included)' % g))
# 3. landing forecourts: at least 12 x 12, clear of everything, on the cloud, on the approach side
FPOLY = {}
for k, (x, z, w, d) in FORE.items():
    fp = box(x - w / 2, z - d / 2, x + w / 2, z + d / 2); FPOLY[k] = fp
    if min(w, d) < FORECOURT_MIN: problems.append((k, 'forecourt smaller than 12 x 12'))
    if not Point(0, 0).buffer(ISLANDS[k]['r'] - 0.5, 64).contains(fp): problems.append((k, 'forecourt reaches off the cloud'))
    for b in by_island.get(k, []):
        if b['kind'] in ('terrace',) and b['key'] == 'open_table': continue
        if footprint_all(b).intersects(fp) and b['kind'] != 'track': problems.append((k, b['key'], 'stands in the landing forecourt'))
# 4. routes: from the forecourt to every building's door, 3 m wide, clear of every other building,
# and not along the cloud's edge without a balustrade
ROUTES = []
def route_ok(k, pts, own):
    line = LineString(pts); band = line.buffer(ROUTE / 2, 4)
    for b in by_island[k]:
        if b['key'] in own: continue
        obst = footprint_all(b) if b['kind'] != 'track' else shape_poly(b)
        if b['kind'] == 'garden' or b.get('walkthrough') or b.get('through'): continue   # walked through
        if band.intersects(obst.buffer(-0.05)): return False
    if ISLANDS[k].get('void') and band.intersects(Point(0, 0).buffer(ISLANDS[k]['void'] + 0.5)): return False
    if not Point(0, 0).buffer(ISLANDS[k]['r'] - EDGE, 64).contains(band): return False
    return True
for k, bs in by_island.items():
    fx, fz, fw, fd = FORE[k]; start = VIA.get(k, (fx, fz))
    for b in bs:
        if b['kind'] in ('track', 'garden'): continue
        end = door_point(b); own = {b['key']}
        best = None
        if b['key'] == 'propylon': start = (fx, fz)
        else: start = VIA.get(k, (fx, fz))
        if route_ok(k, [start, end], own): best = [start, end]
        else:
            R = ISLANDS[k]['r']
            cands = [(x, z) for x in range(-int(R), int(R) + 1, 2) for z in range(-int(R), int(R) + 1, 2) if math.hypot(x, z) < R - 3]
            for w in sorted(cands, key=lambda w: math.dist(start, w) + math.dist(w, end)):
                if route_ok(k, [start, w, end], own): best = [start, w, end]; break
            if best is None:          # round a building: two bends
                seen_s = [w for w in cands if route_ok(k, [start, w], own)]
                seen_e = [w for w in cands if route_ok(k, [w, end], own)]
                pairs = sorted(((a, c) for a in seen_s for c in seen_e), key=lambda q: math.dist(start, q[0]) + math.dist(*q) + math.dist(q[1], end))
                for a, c in pairs[:4000]:
                    if route_ok(k, [start, a, c, end], own): best = [start, a, c, end]; break
        if best is None: problems.append((k, b['key'], 'no 3 m route from the landing forecourt to its door'))
        else:
            if k in VIA and b['key'] != 'propylon': best = [(fx, fz)] + best
            ROUTES.append(dict(island=k, to=b['key'], pts=[list(map(lambda v: round(v, 2), p)) for p in best]))
# 5. podium ramps: every podium has one, at most 32 deg, landing at each tier
for b in B:
    if b['podium'] and b['shape'][0] != 'ring' and ramp_poly(b) is None and b.get('ramp') != 'spiral':
        problems.append((b['island'], b['key'], 'has a podium and no ramp'))
# 6. nectar terraces face world east; the herald's room looks out to open sky
for b in B:
    if b['key'] == 'nectar_aethra':
        ex, ez = local_dir('aethra', *EAST); x, z = b['c']
        if (x * ex + z * ez) / math.hypot(x, z) < 0.8: problems.append(('aethra', 'the nectar terrace is not on the east rim'))
    if b['key'] == 'herald' and math.hypot(*b['c']) < ISLANDS['aethra']['r'] - 1:
        problems.append(('aethra', 'herald', 'the moored room is %.0f m inside the cloud, not moored at its edge to open sky' % (ISLANDS['aethra']['r'] - math.hypot(*b['c']))))
# 7. groves: trees clear of routes, forecourts, buildings and the void
TREES = []
# Koinon's ring of six tier pines round the Hall of Assembly, one per seat: the six clear bearings
# nearest an even spacing, at 20.5 m
def tree_clear(k, kind, p):
    c = Point(p).buffer(TREE_R[kind] * 0.5)
    if k in FPOLY and c.intersects(FPOLY[k]): return False
    if any(c.intersects(footprint_all(b)) for b in by_island.get(k, []) if b['kind'] not in ('garden', 'track')): return False
    return not any(c.intersects(LineString(r['pts']).buffer(ROUTE / 2)) for r in ROUTES if r['island'] == k)
ok_b = [b for b in range(0, 360, 3) if tree_clear('koinon', 'tier_pine', (20.5 * math.cos(rad(b)), 20.5 * math.sin(rad(b))))]
chosen = []
for i in range(6):
    target = 30 + 60 * i
    if ok_b:
        b = min(ok_b, key=lambda q: min(abs(q - target), 360 - abs(q - target)))
        if all(min(abs(b - c), 360 - abs(b - c)) > 20 for c in chosen): chosen.append(b)
for b in chosen: GROVES.append(('koinon', 'tier_pine', (20.5 * math.cos(rad(b)), 20.5 * math.sin(rad(b))), 1, 0.0))
if len(chosen) < 6: notes.append('Koinon has room for only %d of its six seat pines' % len(chosen))
for k, kind, (x, z), n, spread in GROVES:
    for i in range(n):
        a = 2 * math.pi * i / max(1, n) + (0.3 if n > 1 else 0)
        p = (x + spread * math.cos(a), z + spread * math.sin(a)) if n > 1 else (x, z)
        TREES.append(dict(island=k, kind=kind, c=[round(p[0], 2), round(p[1], 2)]))
for t in TREES:
    k = t['island']; c = Point(t['c']).buffer(TREE_R[t['kind']] * (0.5 if t['kind'] != 'puff' else 0.9))
    if k in FPOLY and c.intersects(FPOLY[k]) and t['kind'] != 'puff': problems.append((k, t['kind'], t['c'], 'stands in the forecourt'))
    for b in by_island.get(k, []):
        if b['kind'] in ('garden', 'track'): continue
        if c.intersects(footprint_all(b)): problems.append((k, t['kind'], t['c'], 'stands in %s' % b['key']))
    for r in ROUTES:
        if r['island'] == k and c.intersects(LineString(r['pts']).buffer(ROUTE / 2)) and t['kind'] != 'puff':
            problems.append((k, t['kind'], t['c'], 'stands on the route to %s' % r['to']))

for p in problems: print('PROBLEM', p)
for n in notes: print('NOTE', n)

def poly_out(p):
    geoms = [p] if p.geom_type == 'Polygon' else list(p.geoms)
    return [dict(ext=[[round(a, 2), round(b_, 2)] for a, b_ in g.exterior.coords], holes=[[[round(a, 2), round(b_, 2)] for a, b_ in h.coords] for h in g.interiors]) for g in geoms]
data = dict(
    islands={k: dict(v, facing=facing(k)) for k, v in ISLANDS.items()},
    buildings=[dict(b, footprint=poly_out(shape_poly(b)), podium_fp=poly_out(podium_poly(b)) if b['podium'] else None,
                    ramp=poly_out(ramp_poly(b)) if ramp_poly(b) is not None else None, ramp_kind=b.get('ramp', 'axial'),
                    ramp_run=round(ramp_run(b), 2) if b['podium'] else 0, door_at=door_point(b)) for b in B],
    forecourts=FORE, routes=ROUTES, trees=TREES, built=BUILT, landing_world_y=LANDING_WORLD_Y, ambient=AMBIENT,
    east=EAST, tan=TAN, problems=[list(map(str, p)) for p in problems])
if '--json' in sys.argv:
    json.dump(data, open(sys.argv[sys.argv.index('--json') + 1], 'w'))
print('%d islands, %d buildings, %d routes, %d trees; %d problems' % (len(ISLANDS), len(B), len(ROUTES), len(TREES), len(problems)))
if problems: sys.exit(1)
