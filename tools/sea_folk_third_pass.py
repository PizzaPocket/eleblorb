"""The sea folk city's third pass (proposed): the floor plans of the two eras and
the glass network that joins them (docs/architecture/ocean_sea_folk_city_layout.md
section 10). It holds every volume as a SuperEgg, every glass tunnel, the
heritage each glass building wraps, joins or grows from, the rooms and ramps,
and the households' homes; checks them; and writes JSON for the drawings.

    python3 tools/sea_folk_third_pass.py [--json out.json]

When the user approves the pass, this data replaces the second pass in
tools/sea_folk_layout.py and SeaFolkPlan. Until then SeaFolkPlan is unchanged.

Local metres from the city centre (world (0, -540)); x and z follow the world
axes, +z toward the islands; y is height above the city floor (72 m down).
Bearings are degrees from +x toward +z; the main avenue runs at 90.

A SuperEgg here is |u/a|^e + |v/b|^e + |w/c|^e <= 1 in its own frame: u along
the ring (tangential), v up, w across the ring (radial outward). That is the
implicit form of scripts/superegg.gd's surface with one epsilon.
"""
import json, math, sys
import numpy as np

AVENUES = [b * 45.0 for b in range(8)]
AVENUE_HALF = 2.0
MAIN_AVENUE = 90.0
MOUND = 24.0                 # the open column: nothing modern over the mound but the civic hall and the way down
MOUND_OK = ('civic_hall', 'trunk_c', 'civic_link')
CURRENT = (46.0, 52.0)       # the Ring Current's channel
SWIM_CLEAR = 3.6             # clear height a swimmer needs under a tunnel at the floor
CLEAR = 3.0                  # between volumes that are not joined
TUBE_R = 2.25                # glass tunnels: 4.5 m superellipse tube
TUBE_FLOOR_OFFSET = 1.6      # tube axis above its walking floor (3 m flat floor, 3.2 m headroom)
NET_FLOOR = 4.4              # walking floor of the floor-level tunnels, on the old arcades
CROWN = 30.0                 # walking floor of the crown ring
RAMP_ANGLE = 32.0
RAMP_W = 1.4
LANDING = 1.2
HEADROOM = 2.4
MAX_TUNNEL_GRADE = 1 / 6.0
MIN_ROOM = {'bed2': (3.2, 3.4), 'bed1': (3.0, 3.2), 'bath': (1.4, 1.8), 'party': (5.0, 6.0)}

def rad(b): return math.radians(b)
def at(r, b, y=0.0): return (r * math.cos(rad(b)), y, r * math.sin(rad(b)))
def bearing(p): return math.degrees(math.atan2(p[2], p[0])) % 360

## ---- volumes. era: 'classical' (heritage, wet unless wrapped) or 'modern'.
## dry: walkable air. Every volume is a SuperEgg (centre, semi-axes u/v/w,
## epsilon, the bearing its w axis points along) cut level at `cut` (its
## socket or flat underside), or a cylinder for a trunk.
V = {}
def egg(key, name, era, centre, semi, eps, facing, dry, kind, cut=None, floor=None, **extra):
    V[key] = dict(key=key, name=name, era=era, c=centre, semi=semi, eps=eps, facing=facing, dry=dry, kind=kind,
                  cut=cut, floor=floor, **extra)

# Classical heritage on the floor
egg('tidehall', 'Tidehall', 'classical', (0, 8.0, -1.0), (16, 11, 14), 5.0, 90.0, True, 'castle', cut=2.0, inside='civic_hall',
    note='preserved and still the palace; now dry inside the civic hall, its roof the floor of the assembly')
# 0. The civic hall (a wrap): the whole palace under one glass egg. The city's
# business is done in it: the Tidekeeper's audiences in the old palace, the
# assembly on the palace roof terrace, the hearings round its feet. The secret
# way down from the fountain lands here, on the roof terrace.
egg('civic_hall', 'The civic hall', 'modern', (0, 0.6, -1.0), (22.0, 32.0, 20.5), 2.6, 90.0, True, 'wrap', cut=0.6, floor=2.0,
    wraps='tidehall', keeper='Tidekeeper Asaru', lock=True,
    program='the palace kept whole and dry; the assembly floor on its roof terrace under the crown of the glass; '
            'hearing benches round its feet on the old terrace; a pool lock at the foot of each avenue')
egg('lamp_house', 'Lamp House', 'classical', at(31, 112.5, 2.5), (5, 3.5, 4), 5.0, 112.5, False, 'classical',
    cut=0.0, note='pearl lamps grown in open trays')
egg('school_court', 'School court', 'classical', at(30, 157.5, 2.6), (7, 2.6, 4.5), 5.0, 157.5, False, 'colonnade',
    cut=0.0, note='a Minoan colonnade round an open court')
for i, (b, who, typ) in enumerate([(193.0, 'Oruko', 'double'), (213.0, 'Dakuro', 'double'), (237.0, 'Sekira', 'double'),
                                   (257.0, 'Munaja', 'double'), (124.0, 'Lunira, Korasi and Mira', 'workshop')]):
    r = 82.0 if i < 4 else 60.0
    egg('home_floor_%d' % (i + 1), ('Current House' if i < 4 else 'Lamp House') + ' home', 'classical', at(r, b, 2.2),
        (5.5 if typ == 'double' else 5.0, 3.0, 3.6), 5.0, b + 180 if i < 4 else b, False, 'home', cut=0.0, who=who, home=typ,
        household='Current House' if i < 4 else 'Lamp House')

# 1. WRAP (the British Museum's Great Court): the Exchange is a glass court
# round the preserved Hall of Records. The old hall becomes the dry archive
# (charts and records keep only in air); the trading floor runs round it,
# and a gallery at the tunnels' level looks down into the court.
EX = at(33.0, 67.5)
egg('exchange', 'The Exchange', 'modern', (EX[0], -3.0, EX[2]), (8.8, 15.0, 8.5), 2.4, 67.5, True, 'wrap',
    cut=0.0, floor=0.6, wraps='hall_of_records', keeper='Maresa', lock=True,
    program='trading floor round the old hall; Maresa\'s Nautilus Shell counter; Rodasu\'s Watering Can counter; '
            'a gallery at 5 m joining the ring tunnel; Dakuro\'s charts in the old hall')
HR = at(31.5, 67.5)
egg('hall_of_records', 'Hall of Records', 'classical', (HR[0], 3.6, HR[2]), (5.0, 3.6, 3.0), 5.0, 67.5, True, 'heritage',
    cut=0.6, inside='exchange', note='preserved classical hall, now dry: the city archive and Dakuro\'s chart room')

# 2. JOIN (the Singapore National Gallery): two preserved Strangers' Houses,
# where the classical city lodged visitors, each wrapped close in glass, and
# joined across the 0-degree avenue by a new glass common room that bridges it.
for key, b, side in [('west_house', 337.5, 'West'), ('east_house', 22.5, 'East')]:
    c = at(36.0, b)
    egg(key + '_wrap', 'The guest hall, %s house' % side.lower(), 'modern', (c[0], -6.0, c[2]), (10.5, 20.0, 9.0), 2.4, b, True,
        'wrap', cut=0.0, floor=0.6, wraps=key, lock=False)
    egg(key, "%s Strangers' House" % side, 'classical', (c[0], 2.85, c[2]), (4.1, 2.25, 4.6), 5.0, b, True, 'heritage',
        cut=0.6, inside=key + '_wrap', note='preserved guest house of the classical city, now dry')
egg('common_room', 'The guest hall, common room', 'modern', at(40.0, 0.0, NET_FLOOR + 1.0), (8.0, 5.0, 5.0), 2.4, 0.0, True,
    'bridge', cut=NET_FLOOR - 0.6, floor=NET_FLOOR, keeper='Isaro', lock=True,
    program='Isaro\'s counter, the common room and the party\'s gathering floor, the pool lock; a glass bridge over '
            'the avenue with Tidehall straight down it')

# The Glassworks, the hinge: the first air bubble, socketed at the warm vent.
GW = (0.0, 0.0, 118.0)
def ground(x, z):
    """The levelled floor, the mound, the Ring Current's channel, and the natural
    slope beyond 105 m (ocean_kingdom_terrain.gd, ported)."""
    d = math.hypot(x, z)
    def sm(a, b, t):
        t = min(1, max(0, (t - a) / (b - a))); return t * t * (3 - 2 * t)
    xw, zw = x, z - 540
    r = math.hypot(xw, zw)
    base = -42 + (-110 + 42) * sm(250, 930 * 0.94, r)
    base += math.sin(xw * .01) * 3.2 + math.cos(zw * .012) * 2.5 + math.sin((xw + zw) * .006) * 2 + math.sin(xw * .034) * math.cos(zw * .029) * .9
    for tx, tz, tr in [(420, 250, 150), (-380, -330, 190)]: base -= math.exp(-(math.hypot(xw - tx, zw - tz) / tr) ** 2) * 24
    h = (base + 72) * sm(105, 150, d)
    h += 2 * (1 - sm(20, 25, d))
    h -= 2 * sm(45, 46.6, d) * (1 - sm(51.4, 53, d))
    return h
GW_FLOOR = round(ground(0, 118) + 0.6, 2)
egg('glassworks', 'The Glassworks', 'modern', (0.0, GW_FLOOR - 2.0, 118.0), (8.0, 10.0, 8.0), 2.4, 90.0, True, 'grounded',
    cut=GW_FLOOR - 0.6, floor=GW_FLOOR, keeper='Kunei and Damaku', lock=True, smoked=True,
    program='the furnace over the vent, the blowing floor, the cooling racks; the first air bubble')

## The column: four glass trunks grow from the stumps of the old ring towers
## on the ring path, each threading its household's landing hall, with the
## household's wet homes docked round the hall, and a crown hall where the
## crown ring meets it. The 112.5 trunk climbs on to the Kraken lookout.
TRUNK_R = 4.0
TRUNKS = [  # bearing, household, landing floor, homes (type, who), crown hall program
    (22.5, 'Garden House', 16.0, [('double', 'Nesaja'), ('double', 'Rodasu'), ('double', 'Kasuno and Tami')],
     'the Walking Room: where Munaja teaches the young to walk on new legs'),
    (112.5, 'Glassworks household', 15.0, [('workshop', 'Kunei'), ('workshop', 'Damaku')],
     'the Watch Room: Ikara keeps the rota for the wall lookout and the four sea gates'),
    (202.5, 'Exchange household', 18.0, [('single', 'Maresa'), ('single', 'Pelaju'), ('single', 'Sujira')],
     'the Listening Room: Pelaju listens up toward the surface and the ships'),
    (292.5, 'Reef House', 20.0, [('single', 'Talisa'), ('single', 'Arimu'), ('single', 'Kaluja'), ('reef', 'Reef House workshop')],
     'the Reef House laboratory: Talisa\'s specimens, dry'),
]
POD = {'single': (3.6, 2.8, 4.0), 'double': (5.0, 3.0, 4.2), 'workshop': (4.6, 3.0, 4.4), 'reef': (5.6, 3.2, 4.6)}
HALL = (7.0, 4.0, 7.0)         # a landing hall: 14 m across, 8 m tall, floor 1.2 m below its girth
TRUNK_TOP = {}                 # the Kraken lookout has moved to the wall top (the enclosure)
for b, house, lf, homes, crown_prog in TRUNKS:
    tc = at(71.0, b)
    egg('stump_%g' % b, 'Ring tower stump', 'classical', (tc[0], 2.6, tc[2]), (5.2, 2.6, 5.2), 5.0, b, True, 'stump', cut=0.0,
        floor=0.6, note='the preserved base of an old ring tower; the trunk rises from it', lock=True)
    V['trunk_%g' % b] = dict(key='trunk_%g' % b, name='%s trunk' % house, era='modern', kind='trunk', dry=True,
                             c=(tc[0], 0, tc[2]), r=TRUNK_R, y0=NET_FLOOR, y1=TRUNK_TOP.get(b, CROWN) + 3.0, facing=b)
    egg('hall_%g' % b, '%s landing hall' % house, 'modern', (tc[0], lf + 1.2, tc[2]), HALL, 2.4, b, True, 'landing',
        floor=lf, household=house, lock=True, ballast=True,
        program='the household\'s dry hall on its trunk: where they meet visitors on legs; a pool lock to each home')
    n = len(homes)
    for k, (typ, who) in enumerate(homes):
        ang = b + (k - (n - 1) / 2) * (360.0 / n)            # spread round the hall, the first ones facing out
        a, h, d = POD[typ]
        reach = HALL[0] + d - 0.4                            # docked: the pod's rim meets the hall's
        pc = (tc[0] + reach * math.cos(rad(ang)), lf + 1.2, tc[2] + reach * math.sin(rad(ang)))
        egg('pod_%g_%d' % (b, k), ('Reef House workshop' if typ == 'reef' else '%s home' % house), 'modern', pc, (a, h, d), 2.4, ang,
            False, 'pod', household=house, who=who, home=typ, docks='hall_%g' % b, ballast=True)
    if b in TRUNK_TOP:
        egg('lookout', 'Kraken lookout', 'modern', (tc[0], TRUNK_TOP[b] + 1.0, tc[2]), (4.2, 3.2, 4.2), 2.4, 90.0, True,
            'watch', floor=TRUNK_TOP[b], who='Ikara', lock=False, ballast=True,
            program='a glass watch room 18 m below the surface, looking south over the Kraken\'s water')
    else:
        egg('crown_%g' % b, 'Crown hall', 'modern', (tc[0], CROWN + 1.2, tc[2]), (6.0, 3.6, 6.0), 2.4, b, True, 'crown',
            floor=CROWN, lock=True, ballast=True, program=crown_prog, **({'who': 'Ikara'} if 'Ikara' in crown_prog else {}))

## ---- glass tunnels: polylines of walking-floor points (x, floor y, z).
## Floor-level ones lie on the classical ring arcade, its old bridges over the
## Ring Current, and the avenue colonnade, so swimmers pass under them.
T = []
def arc(r, b0, b1, y, step=4.0):
    if b1 < b0: b1 += 360
    n = max(2, int(abs(b1 - b0) * math.pi / 180 * r / step))
    return [at(r, b0 + (b1 - b0) * i / n, y) for i in range(n + 1)]
def tunnel(key, name, pts, joins, carried):
    T.append(dict(key=key, name=name, pts=[tuple(round(v, 3) for v in p) for p in pts], joins=joins, carried=carried))

RING_R = 40.0
ring_nodes = [(0.0, 'common_room'), (22.5, 'east_house_wrap'), (67.5, 'exchange'), (112.5, None), (157.5, None),
              (202.5, None), (247.5, None), (292.5, None), (337.5, 'west_house_wrap')]
# the ring runs node to node; where a glass building stands on it, the ring
# stops at its glass and starts again on the other side
def node_half(key):
    v = V[key]; return math.degrees(v['semi'][0] / RING_R) if v['kind'] != 'bridge' else math.degrees(v['semi'][0] / RING_R)
starts = []
for b, key in ring_nodes:
    half = node_half(key) * 0.78 if key else 0.0
    starts.append((b - half, b + half, key))
for i in range(len(starts)):
    b0 = starts[i][1]; b1 = starts[(i + 1) % len(starts)][0]
    if (b1 - b0) % 360 > 300: continue        # the two glass buildings meet: no tunnel between them
    j = [k for k in (starts[i][2], starts[(i + 1) % len(starts)][2]) if k]
    tunnel('ring_%d' % i, 'Civic ring tunnel', arc(RING_R, b0, b1, NET_FLOOR), j, 'the classical ring arcade')
for b, *_ in TRUNKS:
    start = 44.5 if b == 22.5 else RING_R          # from the east house's glass, or from the ring
    tunnel('spoke_%g' % b, 'Spoke to the %s trunk' % next(t[1] for t in TRUNKS if t[0] == b),
           [at(r, b, NET_FLOOR) for r in (start, 46.0, 52.0, 71.0 - 5.2 + 0.5)], ['stump_%g' % b] + (['east_house_wrap'] if b == 22.5 else []),
           'the classical arcade and the old bridge over the Ring Current')
# the avenue tunnel beside the main avenue, out to the Glassworks
ax = AVENUE_HALF + 1.0 + TUBE_R + 0.3
z0 = math.sqrt(RING_R ** 2 - ax ** 2)
tunnel('avenue', 'Avenue tunnel', [(ax, NET_FLOOR, z0), (ax, NET_FLOOR, 70.0), (ax, NET_FLOOR, 100.0), (ax, NET_FLOOR, 111.0)],
       ['glassworks'], 'the classical avenue colonnade')
# the civic link: from the ring's junction with the avenue tunnel in to the civic hall's gallery
CX = -1.3                                     # between the Exchange and the Lamp House, over the avenue
tunnel('civic_link', 'Civic link', [(CX, NET_FLOOR, math.sqrt(RING_R ** 2 - CX ** 2)), (CX, NET_FLOOR, 30.0), (CX, NET_FLOOR, 18.6)], ['civic_hall'],
       'the classical avenue colonnade, over the old palace steps')
# the central trunk: the secret way down. It hangs from the stone shaft under
# the fountain, through the roof's air and the open column, into the crown of
# the civic hall, and lands on the palace roof terrace.
V['trunk_c'] = dict(key='trunk_c', name='Central trunk', era='modern', kind='trunk', dry=True, c=(0.0, 0, 0.0), r=TRUNK_R,
                    y0=19.0, y1=74.0, facing=90.0, secret=True,
                    note='glass from the waterline to the civic hall; an open spiral inside the hall down to the palace roof')
# the crown ring joins the trunk tops, 30 m up
crowns = [t[0] for t in TRUNKS]
for i, b in enumerate(crowns):
    nb = crowns[(i + 1) % len(crowns)]
    half = math.degrees(6.0 / 71.0) * 0.9
    tunnel('crown_%d' % i, 'Crown ring', arc(71.0, b + half, nb - half, CROWN, 6.0),
           ['crown_%g' % b if b not in TRUNK_TOP else 'trunk_%g' % b, 'crown_%g' % nb if nb not in TRUNK_TOP else 'trunk_%g' % nb],
           'free in the water, held level by the trunks and the halls\' ballast')

## ---- rooms: the guest rooms in the Strangers' Houses (local u along, w across, from the house centre)
ROOMS = {
    'east_house': [('guest room', 'bed2', (-3.85, -0.05), (-4.35, -0.75)), ('guest room', 'bed2', (0.05, 3.85), (-4.35, -0.75)),
                   ('guest room', 'bed2', (-3.85, -0.05), (0.75, 4.35)), ("Isaro's room", 'bed1', (0.05, 3.85), (0.75, 4.35))],
    'west_house': [('party room', 'party', (-3.85, 3.85), (-4.35, 1.1)), ('washroom', 'bath', (-3.85, -1.0), (2.5, 4.35)),
                   ('linen store', 'store', (1.0, 3.85), (2.5, 4.35))],
}
CORRIDOR = {'east_house': 1.4, 'west_house': 1.3}
## ramps inside wraps, from the old floor (0.6) up to the tunnels' gallery (NET_FLOOR): flights of
## (axis 'u' or 'w', the flight's lane centre on the other axis, start on its own axis, direction, y0, y1)
H1 = (0.6 + NET_FLOOR) / 2
RAMPS = {
    'exchange': [('u', 4.0, -4.6, 1, 0.6, NET_FLOOR)],
    'east_house_wrap': [('w', 5.1, -3.0, 1, 0.6, H1), ('w', 6.55, 0.04, -1, H1, NET_FLOOR)],   # a switchback beside the old house
    'west_house_wrap': [('w', -5.1, -3.0, 1, 0.6, H1), ('w', -6.55, 0.04, -1, H1, NET_FLOOR)],
    'civic_hall': [('u', 17.4, 5.3, -1, 2.0, NET_FLOOR)],       # from the old terrace up to the civic link's gallery
}


## ---- the enclosure: the city walls with a roof (section 11). An octagon that
## reads as a square with short mitred corners. The lower course is the first
## city's sea wall in a dark sturdy stone, up to just above the water; the
## upper course and the roof, built when the city closed itself, are a lighter
## stone in the same classical manner. Inside: the sea up to the waterline, then
## an air hall under a coffered vault. On top: a walkable stone roof with the
## fountain at its centre, whose pedestal hides the stair down.
WATER = 72.0                 # sea level above the city floor
WALL_IN = 135.0              # inner face of a side, from the centre
CHAMFER = 50.0               # inner length of a mitred corner (a side is ~199 m)
WALL_T = 8.0
WALL_CLEAR = 6.0             # nothing of the city closer than this to the inner face
DARK_TOP = WATER + 2.5       # the sturdy dark course ends just above the water
ROOF_TOP = 96.0              # a third above the water: 24 m of wall stands out of the sea
ROOF_SOFFIT = 88.0           # the vault's springing at the walls and piers; 16 m of air over the water
PARAPET = 1.2
def octagon(half, cut):
    """Corners of an octagon with apothem `half` on the sides and `cut` the
    chamfer face's apothem (distance of the mitred face from the centre)."""
    pts = []
    for k in range(8):
        th = rad(k * 45.0)
        a = half if k % 2 == 0 else cut           # apothem of the face whose normal is at k * 45
        pts.append((a, th))
    # vertices are the intersections of consecutive face lines
    out = []
    for k in range(8):
        a1, t1 = pts[k]; a2, t2 = pts[(k + 1) % 8]
        n1 = np.array([math.cos(t1), math.sin(t1)]); n2 = np.array([math.cos(t2), math.sin(t2)])
        out.append(tuple(np.linalg.solve(np.array([n1, n2]), np.array([a1, a2]))))
    return out
MITRE_IN = (2 * WALL_IN - CHAMFER / math.sqrt(2)) / math.sqrt(2)     # apothem of a mitred face, inside
INNER = octagon(WALL_IN, MITRE_IN)
OUTER = octagon(WALL_IN + WALL_T, MITRE_IN + WALL_T)
FACES = [(WALL_IN if k % 2 == 0 else MITRE_IN, k * 45.0) for k in range(8)]
def wall_dist(x, z):
    """Distance from the inner face of the walls, positive inside."""
    return min(a - (x * math.cos(rad(b)) + z * math.sin(rad(b))) for a, b in FACES)
# the roof's piers: eight at 100 m between the avenues, four at 60 m inside the
# trunks' quarters; stone, from the seabed to the vault
for b in [22.5 + 45 * k for k in range(8)]:
    c = at(100.0, b)
    V['pier_%g' % b] = dict(key='pier_%g' % b, name='Roof pier', era='enclosure', kind='pier', dry=False, c=(c[0], 0, c[2]), r=3.0,
                            y0=min(0.0, round(ground(c[0], c[2]), 2)), y1=ROOF_SOFFIT, facing=b)
for b in (67.5, 157.5, 247.5, 337.5):
    c = at(60.0, b)
    V['pier_in_%g' % b] = dict(key='pier_in_%g' % b, name='Roof pier', era='enclosure', kind='pier', dry=False, c=(c[0], 0, c[2]), r=2.6,
                               y0=0.0, y1=ROOF_SOFFIT, facing=b)
# the ancient spires: the first city's, older than anything preserved, left
# standing where they stood; some whole, some broken off (r, bearing, height, base radius, broken)
SPIRES = [(96.0, 8.0, 46.0, 3.4, False), (95.0, 60.0, 28.0, 3.0, True), (88.0, 152.0, 38.0, 3.2, False),
          (97.0, 214.0, 22.0, 3.0, True), (90.0, 265.0, 48.0, 3.6, False), (99.0, 328.0, 34.0, 3.2, True),
          (64.0, 174.0, 18.0, 2.6, True)]
for i, (r, b, h, br, broken) in enumerate(SPIRES):
    c = at(r, b)
    egg('spire_%d' % (i + 1), 'Ancient spire' + (', broken' if broken else ''), 'ancient', (c[0], h / 2, c[2]), (br, h / 2, br), 2.6, b,
        False, 'spire', cut=0.0, height=h, broken=broken, note='the first city\'s; never restored, never taken down')
LIGHT_WELLS = [dict(bearing=b, r=60.0, half=4.0) for b in AVENUES]   # glass-capped shafts in the roof over the avenues
GATES = [dict(bearing=b, width=14.0, height=24.0, wicket=(3.0, 4.0)) for b in (0.0, 90.0, 180.0, 270.0)]
FOUNTAIN = dict(tiers=[  # basin radius, rim height above the roof, pedestal radius under it
    dict(r=20.0, y=0.9, ped=6.0), dict(r=13.0, y=5.0, ped=3.6), dict(r=7.0, y=9.0, ped=2.0), dict(r=3.0, y=12.0, ped=1.0)],
    jet=16.0, oculus=(6.5, 14.0),        # the lowest basin's floor is glass between these radii: daylight falls through it down the column
    door_bearing=270.0)                  # behind the curtain from the second tier, a pivoting stone in the pedestal
SHAFT = dict(r=3.4, wall=1.6, y0=WATER + 1.0, y1=ROOF_TOP)   # a stone stair down the pedestal and through the roof to the waterline
LOOKOUT = dict(bearing=90.0, c=(0.0, ROOF_TOP, WALL_IN + WALL_T / 2), semi=(5.0, 3.4, 3.6), who='Ikara',
               program='the Kraken lookout: a glass watch room on the wall over the main gate, facing the islands')

## ---- checks
problems = []
def frame(v):
    """Unit axes (u, v, w) of a volume: w points along its facing bearing."""
    f = rad(v['facing']); w = np.array([math.cos(f), 0, math.sin(f)]); u = np.array([-math.sin(f), 0, math.cos(f)])
    return u, np.array([0, 1.0, 0]), w
def to_local(v, p):
    u, up, w = frame(v); d = np.asarray(p, float) - np.array(v['c'], float)
    return np.stack([d @ u, d @ up, d @ w], -1)
def inside(v, p, shrink=0.0):
    """True where p is inside v (shrunk by `shrink` metres) and above its cut."""
    p = np.atleast_2d(np.asarray(p, float))
    if v['kind'] in ('trunk', 'pier'):
        r = np.hypot(p[:, 0] - v['c'][0], p[:, 2] - v['c'][2])
        return (r <= v['r'] - shrink) & (p[:, 1] >= v['y0']) & (p[:, 1] <= v['y1'])
    l = to_local(v, p); a = np.maximum(np.array(v['semi'], float) - shrink, 0.01)
    ok = (np.abs(l[:, 0] / a[0]) ** v['eps'] + np.abs(l[:, 1] / a[1]) ** v['eps'] + np.abs(l[:, 2] / a[2]) ** v['eps']) <= 1
    if v.get('cut') is not None: ok &= p[:, 1] >= v['cut']
    return ok
def surface(v, n=28):
    if v['kind'] in ('trunk', 'pier'):
        t = np.linspace(0, 2 * np.pi, n, endpoint=False); ys = np.linspace(v['y0'], v['y1'], n)
        T_, Y_ = np.meshgrid(t, ys)
        return np.stack([v['c'][0] + v['r'] * np.cos(T_.ravel()), Y_.ravel(), v['c'][2] + v['r'] * np.sin(T_.ravel())], -1)
    eta = np.linspace(-np.pi / 2, np.pi / 2, n); om = np.linspace(0, 2 * np.pi, n, endpoint=False)
    E, O = np.meshgrid(eta, om); e = v['eps']
    ps = lambda x: np.sign(x) * np.abs(x) ** (2 / e)
    a, b, c = v['semi']
    l = np.stack([a * ps(np.cos(E)) * ps(np.sin(O)), b * ps(np.sin(E)), c * ps(np.cos(E)) * ps(np.cos(O))], -1).reshape(-1, 3)
    u, up, w = frame(v)
    p = np.array(v['c'], float) + l[:, :1] * u + l[:, 1:2] * up + l[:, 2:] * w
    if v.get('cut') is not None: p = p[p[:, 1] >= v['cut']]
    return p
def tube_points(t, step=1.0):
    out = []
    pts = [np.array(p, float) + [0, TUBE_FLOOR_OFFSET, 0] for p in t['pts']]
    for a, b in zip(pts, pts[1:]):
        n = max(1, int(np.linalg.norm(b - a) / step))
        for i in range(n): out.append(a + (b - a) * i / n)
    out.append(pts[-1]); return np.array(out)
def tube_shell(t):
    ax = tube_points(t, 2.0); out = []
    for i, p in enumerate(ax):
        d = ax[min(i + 1, len(ax) - 1)] - ax[max(i - 1, 0)]; d /= np.linalg.norm(d) or 1
        s = np.cross(d, [0, 1, 0]); s = s / (np.linalg.norm(s) or 1); up = np.cross(s, d)
        for k in range(10):
            th = 2 * np.pi * k / 10; out.append(p + TUBE_R * (math.cos(th) * s + math.sin(th) * up))
    return np.array(out)

MODERN = [v for v in V.values() if v['era'] == 'modern']
SHELL = {k: surface(v) for k, v in V.items()}
TSHELL = {t['key']: tube_shell(t) for t in T}

# 1. The open column: nothing modern over the mound, at any height.
for k, s in list(SHELL.items()) + list(TSHELL.items()):
    era = V[k]['era'] if k in V else 'modern'
    if era == 'modern' and k not in MOUND_OK and (np.hypot(s[:, 0], s[:, 2]) < MOUND).any():
        problems.append((k, 'stands over the mound, in the open column'))
# 2. Avenues stay open at the floor; 3. nothing stands in the Ring Current.
def low_points(s): return s[s[:, 1] < SWIM_CLEAR]
for k, s in list(SHELL.items()) + list(TSHELL.items()):
    if k in V and V[k]['kind'] in ('castle',): continue
    lp = low_points(s)
    if not len(lp): continue
    r = np.hypot(lp[:, 0], lp[:, 2])
    for b in AVENUES:
        f = rad(b); along = lp[:, 0] * math.cos(f) + lp[:, 2] * math.sin(f); lat = -lp[:, 0] * math.sin(f) + lp[:, 2] * math.cos(f)
        if ((np.abs(lat) < AVENUE_HALF + 1.0) & (along > MOUND) & (along < 105)).any():
            problems.append((k, 'stands in the avenue at %g' % b))
    if ((r > CURRENT[0]) & (r < CURRENT[1])).any(): problems.append((k, 'stands in the Ring Current'))
# 4. Clearance between volumes that are not joined.
joined = set()
for v in V.values():
    for f in ('inside', 'docks', 'wraps'):
        if v.get(f): joined.add(frozenset((v['key'], v[f])))
for b, *_ in TRUNKS:
    for other in ('stump_%g' % b, 'hall_%g' % b, 'crown_%g' % b, 'lookout' if b in TRUNK_TOP else None):
        if other: joined.add(frozenset(('trunk_%g' % b, other)))
    joined.add(frozenset(('hall_%g' % b, 'crown_%g' % b)))     # one trunk carries both: the gap between them is the trunk's
    for v in V.values():
        if v.get('docks') == 'hall_%g' % b: joined.add(frozenset(('trunk_%g' % b, v['key'])))
    for t in T:
        if t['key'] == 'spoke_%g' % b or ('trunk_%g' % b) in t['joins'] or ('crown_%g' % b) in t['joins']:
            joined.add(frozenset(('trunk_%g' % b, t['key'])))
joined |= {frozenset(('common_room', 'east_house_wrap')), frozenset(('common_room', 'west_house_wrap')),
           frozenset(('avenue', 'exchange')), frozenset(('trunk_c', 'civic_hall')), frozenset(('trunk_c', 'tidehall')),
           frozenset(('avenue', 'civic_link'))}   # both leave the ring at the same junction   # the avenue tunnel branches from the ring at the Exchange's door
for t in T:
    for j in t['joins']: joined.add(frozenset((t['key'], j)))
for i in range(len(T)):        # ring and crown segments meet one another at their ends
    for k in range(len(T)):
        if i < k and (np.linalg.norm(np.array(T[i]['pts'][0]) - np.array(T[k]['pts'][-1])) < 0.5 or
                      np.linalg.norm(np.array(T[i]['pts'][-1]) - np.array(T[k]['pts'][0])) < 0.5 or
                      np.linalg.norm(np.array(T[i]['pts'][0]) - np.array(T[k]['pts'][0])) < 0.5):
            joined.add(frozenset((T[i]['key'], T[k]['key'])))
# a spoke leaves the ring where the ring passes; the avenue tunnel likewise
for t in T:
    if t['key'].startswith('spoke') or t['key'] in ('avenue', 'civic_link'):
        for r in T:
            if r['key'].startswith('ring') and np.min(np.linalg.norm(np.array(r['pts']) - np.array(t['pts'][0]), axis=1)) < 3.0:
                joined.add(frozenset((t['key'], r['key'])))
# a spoke from inside a glass building on the ring joins that building
for b, key in ring_nodes:
    if key and b in [t[0] for t in TRUNKS]: joined.add(frozenset(('spoke_%g' % b, key)))
ALL = {**SHELL, **TSHELL}
keys = list(ALL)
def gap(a, b):
    A, B = ALL[a], ALL[b]
    best = np.inf
    for i in range(0, len(A), 400):
        d = np.linalg.norm(A[i:i + 400, None, :] - B[None, :, :], axis=-1); best = min(best, d.min())
    return best
centre = {k: ALL[k].mean(0) for k in keys}; reach = {k: np.linalg.norm(ALL[k] - centre[k], axis=1).max() for k in keys}
for i in range(len(keys)):
    for k in range(i + 1, len(keys)):
        a, b = keys[i], keys[k]
        if frozenset((a, b)) in joined: continue
        if np.linalg.norm(centre[a] - centre[b]) - reach[a] - reach[b] > CLEAR: continue
        g = gap(a, b)
        if g < CLEAR: problems.append((a, b, 'only %.1f m apart' % g))
# 5. Every tunnel ends in what it joins, and climbs no steeper than 1:6.
for t in T:
    ends = [np.array(t['pts'][0]) + [0, 0.3, 0], np.array(t['pts'][-1]) + [0, 0.3, 0]]
    for j in t['joins']:
        tgt = V.get(j)
        if tgt is None: continue
        if not any(inside(tgt, e, -1.5)[0] for e in ends): problems.append((t['key'], 'does not reach %s' % j))
    for p, q in zip(t['pts'], t['pts'][1:]):
        run = math.hypot(q[0] - p[0], q[2] - p[2])
        if run and abs(q[1] - p[1]) / run > MAX_TUNNEL_GRADE + 1e-6: problems.append((t['key'], 'is steeper than 1:6'))
    # swimmers pass under the floor-level tunnels
    if t['pts'][0][1] < 10 and min(p[1] for p in t['pts']) + TUBE_FLOOR_OFFSET - TUBE_R < SWIM_CLEAR - 1e-6:
        problems.append((t['key'], 'leaves less than %.1f m for swimmers beneath' % SWIM_CLEAR))
# 6. The dry network is one: every dry volume reachable from every other.
dry = [k for k, v in V.items() if v['dry']] + [t['key'] for t in T]
parent = {k: k for k in dry}
def find(k):
    while parent[k] != k: parent[k] = parent[parent[k]]; k = parent[k]
    return k
for pair in joined:
    p = list(pair)
    if len(p) == 2 and all(x in parent for x in p): parent[find(p[0])] = find(p[1])
for b, *_ in TRUNKS:                      # the stump's door opens into the trunk's foot
    parent[find('stump_%g' % b)] = find('trunk_%g' % b)
groups = {}
for k in dry: groups.setdefault(find(k), []).append(k)
if len(groups) > 1: problems.append(('the dry network is in %d pieces' % len(groups), sorted(map(sorted, groups.values()), key=len)[:2]))
# 7. Heritage stands clear inside its glass, and rooms fit their houses.
for v in V.values():
    if v.get('inside'):
        host = V[v['inside']]
        hs = surface(v, 16); hs = hs[hs[:, 1] > host['cut'] + 0.05]
        if not inside(host, hs, 1.5).all(): problems.append((v['key'], 'stands closer than 1.5 m to the glass of %s' % host['key']))
        if not inside(host, np.array(v['c']) + [0, v['semi'][1] + HEADROOM - 0.4, 0], 0.5)[0]:
            problems.append((v['key'], 'leaves no headroom over its roof inside %s' % host['key']))
for house, rooms in ROOMS.items():
    hv = V[house]; ha, hd = hv['semi'][0] - 0.25, hv['semi'][2] - 0.25
    for name, kind, (u0, u1), (w0, w1) in rooms:
        if min(u0, u1) < -ha - 1e-6 or max(u0, u1) > ha + 1e-6 or min(w0, w1) < -hd - 1e-6 or max(w0, w1) > hd + 1e-6:
            problems.append((house, name, 'does not fit inside the old walls'))
        if kind in MIN_ROOM:
            need = MIN_ROOM[kind]; s = sorted((abs(u1 - u0), abs(w1 - w0)))
            if s[0] < need[0] - 1e-6 or s[1] < need[1] - 1e-6: problems.append((house, name, 'is %.1f x %.1f m, under %.1f x %.1f' % (s[0], s[1], *need)))
# 8. Ramps from the old floor up to the gallery fit inside the glass with headroom.
TAN = math.tan(rad(RAMP_ANGLE))
def flight_points(v, fl):
    axis, lane, start, sign, y0, y1 = fl
    u, up, w = frame(v); c = np.array(v['c'], float); run = (y1 - y0) / TAN; pts = []
    for s_ in np.linspace(-LANDING, run + LANDING, 20):
        y = y0 + max(0, min(run, s_)) * TAN; pos = start + sign * s_
        for dl in (-RAMP_W / 2, RAMP_W / 2):
            uu, ww = (pos, lane + dl) if axis == 'u' else (lane + dl, pos)
            q = c + uu * u + ww * w; q[1] = y
            pts += [q, q + [0, HEADROOM, 0]]
    return np.array(pts)
RAMP_POLYS = {}
for key, flights in RAMPS.items():
    v = V[key]
    for fl in flights:
        pts = flight_points(v, fl)
        if not inside(v, pts, 0.3).all(): problems.append((key, 'has no room for its ramp up to the gallery', fl))
        for o in V.values():
            if o.get('inside') == key and inside(o, pts, -0.3).any(): problems.append((key, 'ramp runs into %s' % o['key']))
# 9. Landing halls: a walkable ring round the trunk with headroom; trunk ramps.
for b, house, lf, *_ in TRUNKS:
    h = V['hall_%g' % b]; tc = np.array(h['c'])
    ok = True
    for th in np.linspace(0, 2 * np.pi, 24, endpoint=False):
        for r in (TRUNK_R + 0.2, TRUNK_R + 0.2 + RAMP_W + 0.2):
            p = np.array([tc[0] + r * math.cos(th), lf, tc[2] + r * math.sin(th)])
            ok &= bool(inside(h, [p + [0, 0.05, 0], p + [0, HEADROOM, 0]], 0.3).all())
    if not ok: problems.append((h['key'], 'has no 1.6 m walkable ring round its trunk'))
TURN_RISE = 2 * math.pi * (TRUNK_R - 0.3 - RAMP_W / 2) * math.tan(rad(RAMP_ANGLE))
if TURN_RISE < HEADROOM + 0.4: problems.append(('trunk spiral ramps leave only %.1f m headroom' % (TURN_RISE - 0.4),))
# 10. People: sixteen homes, every household housed, every dry place with a pool lock near.
homes = [v for v in V.values() if v['kind'] in ('home', 'pod') and v.get('home') != 'reef']
if len(homes) != 16: problems.append(('there are %d homes, not sixteen' % len(homes),))
RESIDENTS = ['Tidekeeper Asaru', 'Ikara', 'Tudaro', 'Kunei', 'Damaku', 'Lunira', 'Korasi', 'Mira', 'Nesaja', 'Rodasu', 'Kasuno', 'Tami',
             'Maresa', 'Pelaju', 'Isaro', 'Sujira', 'Talisa', 'Arimu', 'Kaluja', 'Oruko', 'Dakuro', 'Sekira', 'Munaja']
named = ' '.join(str(v.get('who', '')) + ' ' + str(v.get('keeper', '')) + ' ' + str(v.get('note', '')) for v in V.values())
for p in RESIDENTS:
    if p.split()[-1] not in named and p not in ('Tidekeeper Asaru', 'Tudaro'): problems.append((p, 'has no place'))
locks = [k for k, v in V.items() if v.get('lock')]
for k in ('exchange', 'common_room', 'glassworks'):
    if k not in locks: problems.append((k, 'has no pool lock for swimmers'))

# 11. The enclosure: everything stands inside the walls with room, under the
# water (but the way down), and the walls keep out of the Kraken's water.
for k, s_ in ALL.items():
    d = min(wall_dist(p[0], p[2]) for p in s_)
    if d < WALL_CLEAR: problems.append((k, 'stands %.1f m from the walls' % d))
    if k not in ('trunk_c',) and not k.startswith('pier') and s_[:, 1].max() > WATER - 4: problems.append((k, 'rises within 4 m of the waterline'))
KRAKEN = (430.0, 350.0); CITY_Z = -540.0
k_min = min(math.hypot(x / KRAKEN[0], (z + CITY_Z) / KRAKEN[1]) for x, z in OUTER)
for i in range(8):        # along each face too
    (x0, z0_), (x1, z1) = OUTER[i], OUTER[(i + 1) % 8]
    for t in np.linspace(0, 1, 40): k_min = min(k_min, math.hypot((x0 + (x1 - x0) * t) / KRAKEN[0], (z0_ + (z1 - z0_) * t + CITY_Z) / KRAKEN[1]))
KRAKEN_GAP = (k_min - 1) * KRAKEN[1]
if KRAKEN_GAP < 40: problems.append(('the walls come within %.0f m of the Kraken\'s water' % KRAKEN_GAP,))
mitre = math.dist(INNER[0], INNER[1]); side = math.dist(INNER[1], INNER[2])
if not (mitre < side / 3): problems.append(('the mitred corners are not short against the sides', side, mitre))
# the light wells and the shaft keep off the piers; the gates stand on the avenues' ends
for w in LIGHT_WELLS:
    c = at(w['r'], w['bearing'])
    for v in V.values():
        if v['kind'] == 'pier' and math.hypot(c[0] - v['c'][0], c[2] - v['c'][2]) < w['half'] + v['r'] + 4: problems.append(('light well', w['bearing'], 'on', v['key']))
for g in GATES:
    gc = at(WALL_IN, g['bearing'])
    if abs(wall_dist(gc[0], gc[2])) > 1e-6: problems.append(('gate', g['bearing'], 'is not on a side'))
if FOUNTAIN['oculus'][0] < SHAFT['r'] + SHAFT['wall'] + 1.0 or FOUNTAIN['oculus'][1] > FOUNTAIN['tiers'][0]['r'] - 3:
    problems.append(('the fountain\'s glass floor does not fit between the shaft and the rim',))
if V['trunk_c']['y1'] < SHAFT['y0']: problems.append(('the central trunk does not reach the shaft',))
WALL_GROUND = []
for i in range(8):
    (x0, z0_), (x1, z1) = INNER[i], INNER[(i + 1) % 8]
    for t in np.linspace(0, 1, 9): WALL_GROUND.append(round(ground(x0 + (x1 - x0) * t, z0_ + (z1 - z0_) * t), 2))

if problems:
    for p in problems: print('PROBLEM', p)
    sys.exit(1)

# ---- write
def jv(v):
    out = {k: (list(map(lambda x: round(float(x), 3), val)) if isinstance(val, tuple) else val) for k, val in v.items()}
    return out
data = dict(volumes=[jv(v) for v in V.values()], tunnels=T, rooms=ROOMS, corridor=CORRIDOR, ramps=RAMPS, tan=math.tan(rad(RAMP_ANGLE)),
            trunks=[dict(bearing=b, household=h, landing=lf, homes=hm, crown=cp, top=TRUNK_TOP.get(b, CROWN)) for b, h, lf, hm, cp in TRUNKS],
            enclosure=dict(inner=[list(map(lambda v: round(float(v), 3), p)) for p in INNER],
                           outer=[list(map(lambda v: round(float(v), 3), p)) for p in OUTER], water=WATER, dark_top=DARK_TOP,
                           roof_top=ROOF_TOP, roof_soffit=ROOF_SOFFIT, parapet=PARAPET, wall_t=WALL_T, side=side, mitre=mitre,
                           wells=LIGHT_WELLS, gates=GATES, fountain=FOUNTAIN, shaft=SHAFT, lookout=LOOKOUT, kraken_gap=KRAKEN_GAP,
                           ground=[min(WALL_GROUND), max(WALL_GROUND)]),
            spires=SPIRES, ring_r=RING_R, net_floor=NET_FLOOR, crown=CROWN, turn_rise=TURN_RISE, avenues=AVENUES,
            ground_main=[(r, round(ground(0, r), 2)) for r in range(0, 141, 2)],
            ground_22=[(r, round(ground(r * math.cos(rad(22.5)), r * math.sin(rad(22.5))), 2)) for r in range(0, 141, 2)])
if '--json' in sys.argv:
    json.dump(data, open(sys.argv[sys.argv.index('--json') + 1], 'w'))
dryv = [v for v in V.values() if v['dry']]
print('enclosure: sides %.0f m, mitres %.0f m, walls %.0f to %.0f m over the floor at their foot, %.0f m clear of the Kraken' % (
    side, mitre, ROOF_TOP - max(WALL_GROUND), ROOF_TOP - min(WALL_GROUND), KRAKEN_GAP))
print('third pass: %d volumes (%d dry), %d tunnels (%.0f m), %d homes, trunk ramp %.1f m a turn' % (
    len(V), len(dryv), len(T), sum(sum(math.dist(p, q) for p, q in zip(t['pts'], t['pts'][1:])) for t in T), len(homes), TURN_RISE))
