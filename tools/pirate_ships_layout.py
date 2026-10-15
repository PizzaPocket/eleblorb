"""Authoring tool for the two pirate ships (docs/architecture/ocean_pirate_ships_design.md
and ocean_pirate_ships.md). Each ship is a building that moves: its hull shape,
decks, rooms, companion ramps, masts, the dry volumes below its waterline,
every crew member's work spot through the day, and its route and daily stop
over a wreck. It checks them all and writes scripts/pirate_ships_plan.gd, the
one plan the ship builder and tools/validate_pirate_ships_plan.tscn read.

    python3 tools/pirate_ships_layout.py [--json out.json]

Ship-local metres, as ocean_kingdom_denizens.gd builds the ship: +z is the
bow, x athwartships (+x starboard), y up from the waterline. Routes are world
metres (x, z). Sizes are world scale (about 1.1 x real, with 2.4 m headroom on
every deck the hero walks).
"""
import json, math, os, sys

RAMP_ANGLE = 32.0
LANDING = 1.2
RAMP_WIDTH = 1.4
HEADROOM = 2.4
DECK_THICKNESS = 0.25
PLANKING = 0.3          # hull planking and frames inside the outline
MAST_RADIUS = 0.45

## ---- hull shape: half-breadth at length position z and height y
def half_breadth(ship, z, y):
    h = SHIPS[ship]['hull']
    half_len = h['length'] / 2
    t = z / half_len
    if t >= 1 or t <= -1: return 0.0
    if t > 0:   # the bow: fine entry
        plan = (1 - t ** h['bow_n']) ** (1 / h['bow_n'])
    else:       # the stern: fuller, ending in a transom or a rounded stern
        plan = max((1 - (-t) ** h['stern_n']) ** (1 / h['stern_n']), h['transom'] if -t < 0.995 else 0.0)
    if y < 0:   # below the waterline the sections narrow to the keel
        d = -y / h['draft']
        if d >= 1: return 0.0
        section = (1 - d ** 2.5) ** 0.5
    else:       # above it, the tumblehome draws the sides in: plumb at the
                # waterline, curving in to the weather deck, then gently on up
        section = 1 - h['tumble'] * min(1.0, y / h['tumble_top']) ** 2 - h.get('tumble_above', 0.0) * max(0.0, y - h['tumble_top']) / 3.0
    return round(h['beam'] / 2 * plan * section, 3)

## ---- the ships
SHIPS = {
    'harbinger': dict(
        name='Harbinger', captain='Captain Brine', draft=5.0,
        hull=dict(length=42.0, beam=11.5, draft=5.0, bow_n=2.2, stern_n=4.0, transom=0.62, tumble=0.08, tumble_top=7.2),
        decks=[  # name, floor y, z range the deck spans
            ('hold', -4.4, (-15.0, 14.0)),
            ('berth deck', -1.6, (-18.5, 17.5)),
            ('gun deck', 1.4, (-20.5, 19.0)),
            ('spar deck', 4.4, (-20.8, 19.5)),
            ('quarterdeck', 7.2, (-20.8, -13.0)),
            ('forecastle', 7.2, (13.0, 19.5)),
        ],
        masts=[('foremast', 11.0), ('mainmast', -1.0), ('mizzen', -11.5)],
        rooms=[  # name, deck, (x0, x1, z0, z1), program, who
            ('hold stores', 'hold', (-2.6, 2.6, -11.0, 3.0), 'water casks, food, cables, spare spars', 'Pip Salt fetches'),
            ('magazine', 'hold', (-2.2, 2.2, 7.6, 12.2), 'powder in a lined, lamp-free room', 'Rook Gale only'),
            ('crew berth', 'berth deck', (-4.3, 4.3, 2.4, 12.6), 'hammocks in rows, sea chests', 'the crew'),
            ('wardroom', 'berth deck', (-2.0, 2.0, -16.0, -10.5), 'shared table for the officers', 'officers'),
            ('cabin, Mara Reef', 'berth deck', (-4.8, -2.2, -13.2, -10.5), 'first mate\'s cabin', 'Mara Reef'),
            ('cabin, Old Kelp', 'berth deck', (2.2, 4.8, -13.2, -10.5), 'sailing master\'s cabin', 'Old Kelp'),
            ('cabin, Ada Shoal', 'berth deck', (-4.6, -2.2, -16.4, -13.6), 'surgeon\'s cabin', 'Ada Shoal'),
            ('surgery', 'berth deck', (2.2, 4.6, -16.4, -13.6), 'a cot, a chest of instruments, a lamp', 'Ada Shoal'),
            ('carpenter\'s walk', 'berth deck', (-4.9, -2.8, -9.5, 1.4), 'timber, plugs, tools', 'Tobias Wake'),
            ('sail room', 'berth deck', (2.8, 4.9, -9.5, 1.4), 'spare canvas, palm and needles', 'Hester Lane'),
            ('great cabin', 'gun deck', (-3.8, 3.8, -19.0, -13.0), 'day cabin, chart table and logbook, sleeping cabin', 'Captain Brine'),
            ('battery', 'gun deck', (-4.8, 4.8, -12.4, 9.0), 'eight guns, mess tables between them', 'Rook Gale keeps the guns'),
            ('galley', 'gun deck', (-3.8, 3.8, 9.6, 14.6), 'iron stove with its flue through the deck, water butt, provision locker', 'Eben Marsh'),
            ('coach', 'spar deck', (-3.4, 3.4, -19.6, -13.6), 'chart room under the quarterdeck', 'Old Kelp'),
            ('waist', 'spar deck', (-4.0, 4.0, -13.0, 13.0), 'capstan, main hatch, the ship\'s boat on its booms', 'the watch on deck'),
            ('boatswain\'s store', 'spar deck', (-2.8, 2.8, 13.6, 17.6), 'rope and blocks under the forecastle', 'Silas Thorne'),
            ('quarterdeck', 'quarterdeck', (-3.4, 3.4, -19.6, -13.2), 'wheel and binnacle, the captain\'s post', 'Captain Brine; Old Kelp'),
            ('forecastle', 'forecastle', (-2.8, 2.8, 13.2, 17.6), 'ship\'s bell, anchors, heads at the bow', 'Silas Thorne'),
        ],
        open_decks=['spar deck', 'quarterdeck', 'forecastle', 'waist'],
        ramps=[  # from deck, to deck, x0, x1, foot z, direction (+1 runs toward the bow as it climbs)
            ('hold', 'berth deck', -2.2, -0.8, -4.0, -1),
            ('berth deck', 'gun deck', 0.8, 2.2, -2.6, -1),
            ('gun deck', 'spar deck', -2.2, -0.8, 6.2, -1),
            ('spar deck', 'quarterdeck', -4.0, -2.6, -8.6, -1),
            ('spar deck', 'forecastle', 1.6, 3.0, 8.6, 1),
        ],
        dry=[('hold', -4.9, -1.6), ('berth deck', -1.6, 1.4)],
        crew=[  # name, gender, role, watch
            ('Captain Brine', 'man', 'captain', '-'), ('Mara Reef', 'woman', 'first mate', 'A'),
            ('Old Kelp', 'man', 'sailing master', 'B'), ('Nell Crow', 'woman', 'lookout', 'A'),
            ('Tobias Wake', 'man', 'carpenter', 'idler'), ('Pip Salt', 'boy', 'ship\'s boy', 'A'),
            ('Rook Gale', 'man', 'gunner', 'A'), ('Ada Shoal', 'woman', 'surgeon', 'idler'),
            ('Silas Thorne', 'man', 'boatswain', 'B'), ('Eben Marsh', 'man', 'cook', 'idler'),
            ('Hester Lane', 'woman', 'sailmaker', 'idler'), ('Josiah Penn', 'man', 'coxswain', 'B'),
        ],
    ),
    'belle_fortune': dict(
        name='Belle Fortune', captain='Capitaine Lucien Souci', draft=4.2,
        hull=dict(length=38.0, beam=10.0, draft=4.2, bow_n=2.1, stern_n=3.4, transom=0.55, tumble=0.3, tumble_top=2.4, tumble_above=0.03),
        decks=[
            ('hold', -3.6, (-13.5, 13.0)),
            ('lower deck', -0.6, (-16.5, 16.0)),
            ('weather deck', 2.4, (-18.5, 17.5)),
            ('poop deck', 5.2, (-18.6, -10.0)),
            ('forecastle', 5.2, (12.0, 17.2)),
        ],
        masts=[('foremast', 9.5), ('mainmast', -0.5), ('mizzen', -9.0)],
        rooms=[
            ('plunder hold', 'hold', (-2.4, 2.4, -10.0, 4.0), 'heaps of plunder, water casks', 'Jacob de Wit; Moineau fetches'),
            ('powder room', 'hold', (-2.0, 2.0, 6.4, 10.4), 'powder behind a door', 'Bridget Nolan only'),
            ('crew quarters', 'lower deck', (-3.2, 3.2, -11.0, 10.0), 'hammocks anywhere, six guns cut in unevenly, sea chests painted every colour', 'the crew; Bridget Nolan\'s guns'),
            ('sickbay', 'lower deck', (-2.8, 2.8, -15.4, -11.4), 'a hammock, a sea chest of remedies', 'Henri Dufour'),
            ('carpenter\'s corner', 'lower deck', (-2.7, -0.8, 10.4, 13.0), 'timber and tools', 'Gaspard Ferrand'),
            ('sail locker', 'lower deck', (0.8, 2.7, 10.4, 13.0), 'canvas', 'Sami Haddad'),
            ('great cabin', 'weather deck', (-2.25, 2.25, -16.4, -10.4), 'the council room: the articles on the bulkhead, the long table for votes, dice and shares, Anneke\'s charts', 'everyone; Bastien Roux keeps the ledger'),
            ('waist', 'weather deck', (-2.5, 2.5, -9.6, 11.0), 'lashed cargo, the boat, the main hatch', 'Yaw Mensah runs the deck'),
            ('galley', 'weather deck', (-1.5, 1.5, 12.2, 15.6), 'stove, hanging pots, Teo\'s stores', 'Teo Abad'),
            ('captain\'s cabin', 'poop deck', (-1.9, 1.9, -17.0, -13.6), 'the captain\'s chest and hammock', 'Capitaine Lucien Souci'),
            ('poop deck', 'poop deck', (-2.4, 2.4, -13.4, -10.2), 'the wheel', 'Capitaine Lucien Souci'),
            ('forecastle', 'forecastle', (-1.4, 1.4, 12.2, 16.0), 'the bell and the anchors', 'Yaw Mensah'),
        ],
        open_decks=['waist', 'poop deck', 'forecastle'],
        ramps=[
            ('hold', 'lower deck', -2.0, -0.6, -2.4, -1),
            ('lower deck', 'weather deck', 0.6, 2.0, -4.4, 1),
            ('weather deck', 'poop deck', -2.4, -1.0, -5.6, -1),
            ('weather deck', 'forecastle', 0.5, 1.9, 7.6, 1),
        ],
        dry=[('hold', -4.0, -0.6), ('lower deck', -0.6, 2.4)],
        crew=[
            ('Capitaine Lucien Souci', 'man', 'captain', '-'), ('Bastien Roux', 'man', 'quartermaster', 'B'),
            ('Yaw Mensah', 'man', 'boatswain', 'A'), ('Anneke Vos', 'woman', 'navigator', 'B'),
            ('Teo Abad', 'man', 'cook', 'idler'), ('Bridget Nolan', 'woman', 'gunner', 'B'),
            ('Sami Haddad', 'man', 'sailmaker', 'idler'), ('Moineau', 'boy', 'cabin hand', 'A'),
            ('Gaspard Ferrand', 'man', 'carpenter', 'idler'), ('Henri Dufour', 'man', 'surgeon', 'idler'),
            ('Inês Prado', 'woman', 'lookout', 'A'), ('Jacob de Wit', 'man', 'able seaman', 'A'),
        ],
    ),
}

## ---- work spots through the day (ocean_pirate_ships.md 4): for each part of
## the day, the room each crew member works or sleeps in. Two people may share
## a room, never a spot: the builder spreads a room's people over its floor.
PARTS = ['dawn', 'morning', 'noon', 'afternoon', 'dusk', 'night']
SCHEDULE = {
    'harbinger': {
        'Captain Brine':  ['great cabin', 'quarterdeck', 'quarterdeck', 'quarterdeck', 'great cabin', 'great cabin'],
        'Mara Reef':      ['waist', 'waist', 'quarterdeck', 'waist', 'battery', 'quarterdeck'],
        'Old Kelp':       ['cabin, Old Kelp', 'coach', 'quarterdeck', 'coach', 'battery', 'cabin, Old Kelp'],
        'Nell Crow':      ['foretop', 'foretop', 'foretop', 'waist', 'battery', 'foretop'],
        'Tobias Wake':    ['crew berth', 'carpenter\'s walk', 'carpenter\'s walk', 'carpenter\'s walk', 'battery', 'crew berth'],
        'Pip Salt':       ['waist', 'hold stores', 'waist', 'waist', 'galley', 'waist'],
        'Rook Gale':      ['waist', 'battery', 'battery', 'battery', 'battery', 'forecastle'],
        'Ada Shoal':      ['cabin, Ada Shoal', 'surgery', 'surgery', 'surgery', 'wardroom', 'cabin, Ada Shoal'],
        'Silas Thorne':   ['crew berth', 'waist', 'forecastle', 'boatswain\'s store', 'battery', 'crew berth'],
        'Eben Marsh':     ['galley', 'galley', 'galley', 'galley', 'galley', 'crew berth'],
        'Hester Lane':    ['crew berth', 'sail room', 'sail room', 'sail room', 'battery', 'crew berth'],
        'Josiah Penn':    ['crew berth', 'waist', 'waist', 'ship\'s boat', 'battery', 'crew berth'],
    },
    'belle_fortune': {
        'Capitaine Lucien Souci': ['captain\'s cabin', 'poop deck', 'poop deck', 'poop deck', 'great cabin', 'captain\'s cabin'],
        'Bastien Roux':   ['crew quarters', 'great cabin', 'poop deck', 'great cabin', 'great cabin', 'poop deck'],
        'Yaw Mensah':     ['waist', 'waist', 'waist', 'ship\'s boat', 'waist', 'crew quarters'],
        'Anneke Vos':     ['crew quarters', 'great cabin', 'poop deck', 'great cabin', 'waist', 'poop deck'],
        'Teo Abad':       ['galley', 'galley', 'galley', 'waist', 'galley', 'crew quarters'],
        'Bridget Nolan':  ['crew quarters', 'crew quarters', 'waist', 'great cabin', 'waist', 'waist'],
        'Sami Haddad':    ['crew quarters', 'sail locker', 'sail locker', 'waist', 'waist', 'crew quarters'],
        'Moineau':        ['galley', 'plunder hold', 'waist', 'waist', 'waist', 'crew quarters'],
        'Gaspard Ferrand': ['crew quarters', 'carpenter\'s corner', 'carpenter\'s corner', 'carpenter\'s corner', 'waist', 'crew quarters'],
        'Henri Dufour':   ['sickbay', 'sickbay', 'sickbay', 'sickbay', 'great cabin', 'sickbay'],
        'Inês Prado':     ['foretop', 'foretop', 'foretop', 'waist', 'waist', 'foretop'],
        'Jacob de Wit':   ['crew quarters', 'plunder hold', 'waist', 'ship\'s boat', 'waist', 'forecastle'],
    },
}
OFF_DECK = {'foretop', 'ship\'s boat'}   # the masthead platform and the boat over the wreck
RESTRICTED = {'magazine': ['Rook Gale', 'Pip Salt'], 'powder room': ['Bridget Nolan', 'Moineau']}

## ---- routes (world metres): each ship's loop, smoothed, and its daily stop
## hove to beside its own wreck (ocean_floor_landscape.md 3). The loops thread
## the islands inside the Kraken's water, in opposite directions, and both pass
## the contested galleon.
WRECKS = {'brig': (200.0, -30.0), 'galleon': (70.0, 170.0), 'schooner': (-60.0, -190.0)}
ROUTES = {
    'harbinger': dict(points=[(262, -150), (250, -62), (218, -30), (214, 70), (150, 190), (58, 212), (-20, 280), (-150, 270),
                              (-280, 190), (-320, 0), (-280, -170), (-130, -280), (20, -290), (160, -250)],
                      laps=3, stop='brig', stop_hour=14.7, stop_minutes=60),
    'belle_fortune': dict(points=[(-60, -208), (-150, -170), (-215, -90), (-262, 40), (-235, 150), (-150, 205), (-40, 210), (35, 194),
                                  (95, 135), (160, 112), (152, 42), (90, 8), (70, -45), (25, -110), (20, -175)],
                          laps=5, stop='schooner', stop_hour=12.0, stop_minutes=60, reverse=True),
}
KRAKEN = (430.0, 350.0)
KRAKEN_MARGIN = 40.0
DOCK = (0.0, 0.0)
DOCK_CLEAR = 60.0
SHIP_SEPARATION = 60.0
STOP_REACH = 25.0
GALLEON_REACH = 45.0
GAME_SECONDS_PER_HOUR = 60.0

## a port of ocean_kingdom_terrain.gd's _raw_height, for depths along the routes
ISLANDS = [(-118, 72, 116, 10.5), (42, 138, 43, 5.2), (112, 88, 31, 3.8), (151, -26, 54, 6.0), (72, -118, 35, 4.4), (-34, -154, 48, 5.5), (-152, -91, 27, 3.4)]
def smooth(a, b, x):
    t = min(1, max(0, (x - a) / (b - a))); return t * t * (3 - 2 * t)
def seabed(x, z):
    r = math.hypot(x, z)
    base = -42 + (-110 + 42) * smooth(250, 930 * 0.94, r)
    base += math.sin(x * 0.010) * 3.2 + math.cos(z * 0.012) * 2.5 + math.sin((x + z) * 0.006) * 2.0 + math.sin(x * 0.034) * math.cos(z * 0.029) * 0.9
    for tx, tz, tr in [(420, 250, 150), (-380, -330, 190)]: base -= math.exp(-(math.hypot(x - tx, z - tz) / tr) ** 2) * 24
    h = base
    for cx, cz, rad, top in ISLANDS:
        d = math.hypot(x - cx, z - cz)
        if d < rad:
            rise = smooth(0, 1, 1 - d / rad) ** 0.34; h = max(h, base + (top - base) * rise)
    nat = smooth(105, 150, math.hypot(x, z + 540))
    return -72 + (h + 72) * nat

def catmull(pts, n=12):
    out = []; m = len(pts)
    for i in range(m):
        p0, p1, p2, p3 = pts[i - 1], pts[i], pts[(i + 1) % m], pts[(i + 2) % m]
        for k in range(n):
            t = k / n; t2 = t * t; t3 = t2 * t
            out.append(tuple(0.5 * ((2 * p1[j]) + (-p0[j] + p2[j]) * t + (2 * p0[j] - 5 * p1[j] + 4 * p2[j] - p3[j]) * t2 + (-p0[j] + 3 * p1[j] - 3 * p2[j] + p3[j]) * t3) for j in (0, 1)))
    return out

# ---- derived geometry
problems = []
def deck_y(ship, name): return next(y for n, y, _ in SHIPS[ship]['decks'] if n == name)
def deck_above(ship, name, x, z):
    """The floor of the next deck above (name) at (x, z), or None."""
    y0 = deck_y(ship, name); best = None
    for n, y, (z0, z1) in SHIPS[ship]['decks']:
        if y > y0 + 0.01 and z0 <= z <= z1 and (best is None or y < best): best = y
    return best
def room_deck(ship, rname): return next((r[1] for r in SHIPS[ship]['rooms'] if r[0] == rname), None)
RAMP_RUNS = {}
for key, s in SHIPS.items():
    rects = []
    for name, deck, (x0, x1, z0, z1), prog, who in s['rooms']:
        y = deck_y(key, deck)
        for yy in (y + 0.3, y + 2.0):
            for xx in (x0, x1):
                for zz in (z0, z1, (z0 + z1) / 2):
                    if abs(xx) > half_breadth(key, zz, yy) - PLANKING:
                        problems.append((key, name, 'reaches outside the hull at x %.1f, z %.1f, y %.1f (half-breadth %.2f)' % (xx, zz, yy, half_breadth(key, zz, yy))))
                        break
        span = next(sp for n, _, sp in s['decks'] if n == deck)
        if z0 < span[0] - 0.01 or z1 > span[1] + 0.01: problems.append((key, name, 'runs off the end of its deck'))
        above = max((deck_above(key, deck, (x0 + x1) / 2, zz) or 99) for zz in (z0 + 0.2, z1 - 0.2))
        above = min((deck_above(key, deck, (x0 + x1) / 2, zz) or 99) for zz in (z0 + 0.2, z1 - 0.2))
        if name not in s['open_decks'] and above < 99 and above - DECK_THICKNESS - y < HEADROOM - 0.01:
            problems.append((key, name, 'has only %.2f m headroom' % (above - DECK_THICKNESS - y)))
        for mname, mz in s['masts']:
            if z0 - MAST_RADIUS < mz < z1 + MAST_RADIUS and x0 - MAST_RADIUS < 0 < x1 + MAST_RADIUS and name not in s['open_decks'] and deck not in ('quarterdeck', 'forecastle', 'poop deck'):
                pass  # a mast may rise through a room (it does on every ship); ramps must not meet it
        rects.append((deck, name, (x0, x1, z0, z1)))
    for i in range(len(rects)):
        for j in range(i + 1, len(rects)):
            a, b = rects[i], rects[j]
            if a[0] == b[0] and a[2][0] < b[2][1] - 0.01 and b[2][0] < a[2][1] - 0.01 and a[2][2] < b[2][3] - 0.01 and b[2][2] < a[2][3] - 0.01:
                problems.append((key, a[1], b[1], 'overlap on the %s' % a[0]))
    runs = []
    for fdeck, tdeck, x0, x1, zf, dr in s['ramps']:
        rise = deck_y(key, tdeck) - deck_y(key, fdeck)
        run = rise / math.tan(math.radians(RAMP_ANGLE))
        z_lo, z_hi = sorted([zf, zf + dr * run])
        foot = (zf - dr * LANDING, zf); head = (zf + dr * run, zf + dr * (run + LANDING))
        runs.append(dict(f=fdeck, t=tdeck, x0=x0, x1=x1, run=(round(z_lo, 2), round(z_hi, 2)), foot=tuple(sorted(foot)), head=tuple(sorted(head)), rise=rise))
        if abs(x1 - x0 - RAMP_WIDTH) > 0.01: problems.append((key, '%s ramp is not %.1f m wide' % (fdeck, RAMP_WIDTH)))
        # the ramp, its landings and its head stay inside the hull and the decks
        for zz in (min(foot + head), max(foot + head)):
            for xx in (x0, x1):
                for yy, deck in ((deck_y(key, fdeck) + 0.2, fdeck), (deck_y(key, tdeck) + 0.2, tdeck)):
                    pass
        for zz in foot:
            if max(abs(x0), abs(x1)) > half_breadth(key, zz, deck_y(key, fdeck) + 0.3) - PLANKING: problems.append((key, fdeck, 'ramp foot outside the hull'))
        for zz in head:
            if max(abs(x0), abs(x1)) > half_breadth(key, zz, deck_y(key, tdeck) + 0.3) - PLANKING: problems.append((key, tdeck, 'ramp head outside the hull'))
        tspan = next(sp for n, _, sp in s['decks'] if n == tdeck)
        if not (tspan[0] <= head[0] and head[1] <= tspan[1]): problems.append((key, tdeck, 'ramp head lands off the deck'))
        fspan = next(sp for n, _, sp in s['decks'] if n == fdeck)
        if not (fspan[0] <= foot[0] and foot[1] <= fspan[1]): problems.append((key, fdeck, 'ramp foot stands off the deck'))
        for mname, mz in s['masts']:
            if min(foot + head) - MAST_RADIUS < mz < max(foot + head) + MAST_RADIUS and x0 - MAST_RADIUS < 0 < x1 + MAST_RADIUS:
                problems.append((key, '%s ramp runs into the %s' % (fdeck, mname)))
        # headroom over the ramp: nothing above it but the deck it climbs to
        top = deck_above(key, tdeck, (x0 + x1) / 2, (z_lo + z_hi) / 2)
        if top is not None and top - DECK_THICKNESS - deck_y(key, tdeck) < HEADROOM - 0.01 and tdeck not in ('spar deck', 'weather deck'):
            problems.append((key, '%s ramp head has too little headroom' % tdeck))
    RAMP_RUNS[key] = runs
    # two ramps on one deck do not overlap
    for i in range(len(runs)):
        for j in range(i + 1, len(runs)):
            a, b = runs[i], runs[j]
            shared = {a['f'], a['t']} & {b['f'], b['t']}
            if shared and a['x0'] < b['x1'] and b['x0'] < a['x1']:
                za = (min(a['foot'] + a['head']), max(a['foot'] + a['head'])); zb = (min(b['foot'] + b['head']), max(b['foot'] + b['head']))
                if za[0] < zb[1] and zb[0] < za[1]: problems.append((key, 'ramps %s-%s and %s-%s overlap' % (a['f'], a['t'], b['f'], b['t'])))
    # every space below the waterline lies in a dry volume
    for name, deck, (x0, x1, z0, z1), prog, who in s['rooms']:
        y = deck_y(key, deck)
        if y < 0.3 and not any(lo - 0.01 <= y < hi for _, lo, hi in s['dry']): problems.append((key, name, 'is below the waterline outside a dry volume'))
    # crew: twelve, each with a gender and a spot for every part of the day
    if len(s['crew']) != 12: problems.append((key, 'crew of %d, not twelve' % len(s['crew'])))
    sched = SCHEDULE[key]
    rooms = {r[0] for r in s['rooms']} | OFF_DECK
    for name, gender, role, watch in s['crew']:
        if gender not in ('man', 'woman', 'boy', 'girl'): problems.append((key, name, 'has no gender'))
        if name not in sched or len(sched[name]) != len(PARTS): problems.append((key, name, 'needs a spot for every part of the day')); continue
        for part, room in zip(PARTS, sched[name]):
            if room not in rooms: problems.append((key, name, part, 'works in %s, which is not on this ship' % room))
            if room in RESTRICTED and name not in RESTRICTED[room]: problems.append((key, name, 'may not enter the %s' % room))
    # the captain is at the wheel by day
    capt = s['captain']
    wheel = 'quarterdeck' if key == 'harbinger' else 'poop deck'
    if sched[capt][PARTS.index('noon')] != wheel: problems.append((key, 'the captain is not at the wheel at noon'))
    # one person aloft at the masthead and one boat crew at a time
    for i, part in enumerate(PARTS):
        top = [n for n in sched if sched[n][i] == 'foretop']
        if len(top) > 1: problems.append((key, part, 'two lookouts at the masthead', top))

# ---- routes: depth, the Kraken, the dock, the wrecks, and the two ships apart
ROUTE_PTS = {}
def resample(pts, step=4.0):
    out = [pts[0]]; acc = 0.0
    loop = pts + [pts[0]]
    for a, b in zip(loop, loop[1:]):
        L = math.hypot(b[0] - a[0], b[1] - a[1]); n = max(1, int(L / step))
        for k in range(1, n + 1): out.append((a[0] + (b[0] - a[0]) * k / n, a[1] + (b[1] - a[1]) * k / n))
    return out[:-1]
def lap_length(line): return sum(math.hypot(b[0] - a[0], b[1] - a[1]) for a, b in zip(line, line[1:] + line[:1]))
for key, r in ROUTES.items():
    pts = r['points'][::-1] if r.get('reverse') else r['points']
    line = resample(catmull(pts))
    ROUTE_PTS[key] = line
    draft = SHIPS[key]['draft']
    shallow = [(round(x), round(z), round(seabed(x, z), 1)) for x, z in line if seabed(x, z) > -(draft + 3.0)]
    if shallow: problems.append((key, 'route runs over water shallower than %.1f m' % (draft + 3), shallow[:3]))
    k = max(math.hypot(x / KRAKEN[0], z / KRAKEN[1]) for x, z in line)
    if k > 1 - KRAKEN_MARGIN / min(KRAKEN): problems.append((key, 'route strays into the Kraken\'s water (%.2f)' % k))
    if min(math.hypot(x - DOCK[0], z - DOCK[1]) for x, z in line) < DOCK_CLEAR: problems.append((key, 'route passes too close to the dock'))
    w = WRECKS[r['stop']]
    near = min(range(len(line)), key=lambda i: math.hypot(line[i][0] - w[0], line[i][1] - w[1]))
    r['stop_index'] = near
    if math.hypot(line[near][0] - w[0], line[near][1] - w[1]) > STOP_REACH: problems.append((key, 'never comes within %g m of the %s' % (STOP_REACH, r['stop'])))
    # the ship sails a whole number of laps a day between stops, so its timetable
    # repeats daily and it is over its wreck at the same hour every day
    r['speed'] = r['laps'] * lap_length(line) / ((24 - r['stop_minutes'] / 60) * GAME_SECONDS_PER_HOUR)
    if not 4.0 <= r['speed'] <= 7.0: problems.append((key, 'sails at %.1f m/s to keep its timetable' % r['speed']))
    g = WRECKS['galleon']
    if min(math.hypot(x - g[0], z - g[1]) for x, z in line) > GALLEON_REACH: problems.append((key, 'does not pass the contested galleon'))
def position(key, t):
    """Where the ship is at game time t (real seconds from midnight, day 0)."""
    line = ROUTE_PTS[key]; r = ROUTES[key]
    seglen = [math.hypot(b[0] - a[0], b[1] - a[1]) for a, b in zip(line, line[1:] + line[:1])]
    L = sum(seglen); stop_s = sum(seglen[:r['stop_index']])
    day = 24 * GAME_SECONDS_PER_HOUR
    d, tt = divmod(t, day)
    t0 = r['stop_hour'] * GAME_SECONDS_PER_HOUR; dur = r['stop_minutes'] / 60 * GAME_SECONDS_PER_HOUR
    # distance sailed: the stop is placed so the ship reaches its wreck exactly at the stop hour
    moving = t - (d * dur) - (min(max(tt - t0, 0), dur))
    s = (stop_s - r['speed'] * t0 + r['speed'] * moving) % L
    acc = 0.0
    for i, sl in enumerate(seglen):
        if acc + sl >= s:
            a, b = line[i], line[(i + 1) % len(line)]; f = (s - acc) / sl if sl else 0
            return (a[0] + (b[0] - a[0]) * f, a[1] + (b[1] - a[1]) * f)
        acc += sl
    return line[0]
closest = min((math.hypot(position('harbinger', t)[0] - position('belle_fortune', t)[0], position('harbinger', t)[1] - position('belle_fortune', t)[1]), t)
              for t in range(0, int(7 * 24 * GAME_SECONDS_PER_HOUR), 2))
if closest[0] < SHIP_SEPARATION: problems.append(('the two ships come within %.0f m of each other at %.1f h (day %d)' % (closest[0], (closest[1] % 1440) / 60, closest[1] // 1440),))
for key, r in ROUTES.items():
    w = WRECKS[r['stop']]
    for day in range(7):
        p = position(key, (day * 24 + r['stop_hour']) * GAME_SECONDS_PER_HOUR + 30)
        if math.hypot(p[0] - w[0], p[1] - w[1]) > STOP_REACH: problems.append((key, 'is not over its wreck at its stop hour on day %d' % day, p))

if problems:
    for p in problems: print('PROBLEM', p)
    sys.exit(1)

# ---- write the plan
def q(t): return json.dumps(t, ensure_ascii=False)
def v2(p): return 'Vector2(%g, %g)' % (round(p[0], 2), round(p[1], 2))
def pts(poly): return 'PackedVector2Array([%s])' % ', '.join(v2(p) for p in poly)
def hull_outline(key, y, n=48):
    L = SHIPS[key]['hull']['length'] / 2
    zs = [L * (-1 + 2 * k / n) for k in range(n + 1)]
    side = [(half_breadth(key, z, y), z) for z in zs]
    return [(x, z) for x, z in side] + [(-x, z) for x, z in reversed(side)]
out = []; w_ = out.append
w_('class_name PirateShipsPlan')
w_('extends RefCounted')
w_('')
w_('## The two pirate ships\' single plan (docs/architecture/ocean_pirate_ships_design.md and')
w_('## ocean_pirate_ships.md). GENERATED by tools/pirate_ships_layout.py: edit there and')
w_('## rerun, never here. The ship builder and tools/validate_pirate_ships_plan.tscn')
w_('## read only this.')
w_('##')
w_('## Ship-local metres: +z the bow, x athwartships (+x starboard), y up from the')
w_('## waterline. Rooms are Rect2(x0, z0, width, length) on their deck. Routes are')
w_('## world (x, z). hull_half_breadth() gives the hull\'s shape at any (z, y).')
w_('')
w_('const RAMP_ANGLE := %.1f' % RAMP_ANGLE)
w_('const LANDING := %g' % LANDING)
w_('const RAMP_WIDTH := %g' % RAMP_WIDTH)
w_('const HEADROOM := %g' % HEADROOM)
w_('const DECK_THICKNESS := %g' % DECK_THICKNESS)
w_('const PLANKING := %g' % PLANKING)
w_('const PARTS: Array[String] = [%s]' % ', '.join(q(p) for p in PARTS))
w_('const OFF_DECK: Array[String] = [%s]' % ', '.join(q(p) for p in sorted(OFF_DECK)))
w_('const RESTRICTED := %s' % q(RESTRICTED))
w_('const WRECKS := {%s}' % ', '.join('%s: %s' % (q(k), v2(v)) for k, v in WRECKS.items()))
w_('const KRAKEN := %s' % v2(KRAKEN))
w_('const GAME_SECONDS_PER_HOUR := %.1f' % GAME_SECONDS_PER_HOUR)
w_('')
w_('static var SHIPS := {')
for key, s in SHIPS.items():
    r = ROUTES[key]
    w_('\t%s: {' % q(key))
    w_('\t\t"name": %s, "captain": %s, "hull": %s,' % (q(s['name']), q(s['captain']), q(s['hull'])))
    w_('\t\t"decks": [%s],' % ', '.join('[%s, %g, %s]' % (q(n), y, v2(sp)) for n, y, sp in s['decks']))
    w_('\t\t"masts": [%s],' % ', '.join('[%s, %g]' % (q(n), z) for n, z in s['masts']))
    w_('\t\t"rooms": [%s],' % ', '.join('[%s, %s, Rect2(%g, %g, %g, %g), %s, %s]' % (q(n), q(d), x0, z0, x1 - x0, z1 - z0, q(p), q(wh)) for n, d, (x0, x1, z0, z1), p, wh in s['rooms']))
    w_('\t\t"open": %s,' % q(s['open_decks']))
    w_('\t\t"ramps": [%s],' % ', '.join('{"from": %s, "to": %s, "x": %s, "run": %s, "foot": %s, "head": %s}' % (q(a['f']), q(a['t']), v2((a['x0'], a['x1'])), v2(a['run']), v2(a['foot']), v2(a['head'])) for a in RAMP_RUNS[key]))
    w_('\t\t"dry": [%s],' % ', '.join('[%s, %g, %g]' % (q(n), lo, hi) for n, lo, hi in s['dry']))
    w_('\t\t"crew": [%s],' % ', '.join('[%s, %s, %s, %s]' % (q(n), q(g), q(ro), q(wa)) for n, g, ro, wa in s['crew']))
    w_('\t\t"schedule": %s,' % q(SCHEDULE[key]))
    w_('\t\t"route": %s, "speed": %g, "laps": %d, "stop": %s, "stop_hour": %g, "stop_minutes": %g, "stop_index": %d,' % (pts(ROUTE_PTS[key]), r['speed'], r['laps'], q(r['stop']), r['stop_hour'], r['stop_minutes'], r['stop_index']))
    w_('\t},')
w_('}')
w_('')
w_('')
w_('## The hull\'s half-breadth (metres from the centreline) at length z and height y.')
w_('static func hull_half_breadth(ship: String, z: float, y: float) -> float:')
w_('\tvar h: Dictionary = SHIPS[ship]["hull"]')
w_('\tvar half_len := float(h["length"]) * 0.5')
w_('\tvar t := z / half_len')
w_('\tif t >= 1.0 or t <= -1.0:')
w_('\t\treturn 0.0')
w_('\tvar plan := 0.0')
w_('\tif t > 0.0:')
w_('\t\tplan = pow(1.0 - pow(t, float(h["bow_n"])), 1.0 / float(h["bow_n"]))')
w_('\telse:')
w_('\t\tplan = pow(1.0 - pow(-t, float(h["stern_n"])), 1.0 / float(h["stern_n"]))')
w_('\t\tif -t < 0.995:')
w_('\t\t\tplan = maxf(plan, float(h["transom"]))')
w_('\tvar section := 0.0')
w_('\tif y < 0.0:')
w_('\t\tvar d := -y / float(h["draft"])')
w_('\t\tif d >= 1.0:')
w_('\t\t\treturn 0.0')
w_('\t\tsection = sqrt(1.0 - pow(d, 2.5))')
w_('\telse:')
w_('\t\tsection = 1.0 - float(h["tumble"]) * pow(minf(1.0, y / float(h["tumble_top"])), 2.0) - float(h.get("tumble_above", 0.0)) * maxf(0.0, y - float(h["tumble_top"])) / 3.0')
w_('\treturn float(h["beam"]) * 0.5 * plan * section')
root = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..')
open(os.path.join(root, 'scripts', 'pirate_ships_plan.gd'), 'w').write('\n'.join(out) + '\n')
if '--json' in sys.argv:
    path = sys.argv[sys.argv.index('--json') + 1]
    data = {}
    for key, s in SHIPS.items():
        data[key] = dict(name=s['name'], decks=s['decks'], masts=s['masts'], rooms=s['rooms'], ramps=RAMP_RUNS[key], dry=s['dry'],
                         hull=s['hull'], outlines={n: hull_outline(key, y + 0.3) for n, y, _ in s['decks']},
                         waterline=hull_outline(key, 0.0), route=ROUTE_PTS[key], stop=ROUTES[key]['stop'],
                         sections={str(z): [(half_breadth(key, z, y / 4), y / 4) for y in range(-int(s['draft'] * 4), 33)] for z in (0,)})
    json.dump(dict(ships=data, wrecks=WRECKS, kraken=KRAKEN), open(path, 'w'), ensure_ascii=False)
print('wrote scripts/pirate_ships_plan.gd: %s' % ', '.join('%s %d rooms %d ramps' % (k, len(s['rooms']), len(RAMP_RUNS[k])) for k, s in SHIPS.items()))
