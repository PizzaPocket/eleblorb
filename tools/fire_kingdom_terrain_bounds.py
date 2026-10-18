"""Bounds on the Fire Kingdom's live terrain height, for plan checks outside the caldera's fine ground.

The game's ground outside the city patch is FireKingdomTerrain's coarse mesh: a 121 x 121 grid over 1800 m (15 m
cells), each vertex at _legacy_terrain_height. That height adds FastNoiseLite noise (amplitude 6 m) that Python
cannot reproduce exactly, so this module answers with bounds: the mesh height at a point lies between `low` and
`high`, the vertices' heights with the noise at -6 and +6, interpolated over the same triangles. A structure that
must clear the ground clears `high`; a pier or socket that must reach it goes below `low`.

Ported from scripts/fire_kingdom_terrain.gd (_legacy_terrain_height, _coarse_mesh_height); keep them in step.
Rivers only ever lower the ground, so they are left out of `high` and make `low` conservative only where they are
not (the funicular's corridor is checked to stand clear of every river).
"""
import math

HALF_SIZE, RESOLUTION = 900.0, 121
CENTRE_WORLD, GATE_WORLD = (155.0, 85.0), (0.0, -3.0)
FLOOR_RADIUS, RIM_RADIUS, OUTER_RADIUS, RIM_Y, FLOOR_Y, LIP_Y = 52.0, 112.0, 205.0, 48.0, 30.0, 48.0
GATE_CLEAR, GATE_BLEND, GATE_Y = 22.0, 38.0, 0.0
LAVA_POOLS = [(-190, -145), (-315, 175), (335, -210)]
LAVA_RADIUS, LAVA_RIM_START, LAVA_RIM_END, LAVA_FLOOR_Y = 31.0, 58.0, 135.0, -18.0
SECONDARY = [(50, -350), (410, 180)]
NOISE = 6.0
RIVER_PATHS = [
    [(-760, 360), (-600, 330), (-470, 280), (-350, 285), (-210, 275), (-80, 250), (70, 235), (235, 250), (355, 105), (500, 20), (710, -95)],
    [(-690, -430), (-560, -350), (-450, -265), (-355, -155), (-300, -45), (-230, 70), (-150, 180), (-80, 250)],
    [(730, -470), (610, -385), (510, -335), (430, -305), (430, -165), (475, -70), (500, 20)],
]
RIVER_REACH = 9.5 + 4.5 + 18.0 + 17.0   # half width, shore, meander and surface overlap: anything nearer may be lowered


def _forward():
    dx, dy = CENTRE_WORLD[0] - GATE_WORLD[0], CENTRE_WORLD[1] - GATE_WORLD[1]; n = math.hypot(dx, dy)
    return dx / n, dy / n


def to_world(local):
    fx, fy = _forward(); rx, ry = -fy, fx
    return (CENTRE_WORLD[0] + rx * local[0] + fx * local[1], CENTRE_WORLD[1] + ry * local[0] + fy * local[1])


def to_local(world):
    fx, fy = _forward(); rx, ry = -fy, fx; ox, oy = world[0] - CENTRE_WORLD[0], world[1] - CENTRE_WORLD[1]
    return (ox * rx + oy * ry, ox * fx + oy * fy)


def _ss(a, b, x):
    t = min(max((x - a) / (b - a), 0.0), 1.0); return t * t * (3 - 2 * t)


def _bowl(local):
    t = min(max((math.hypot(*local) - FLOOR_RADIUS) / (RIM_RADIUS - FLOOR_RADIUS), 0.0), 1.0)
    return FLOOR_Y + (LIP_Y - FLOOR_Y) * t * t


# The funicular's graded corridor (FireCalderaWalkwaysPlan.SITE.funicular.corridor, 2026-10-18): the flank's noise
# fades to nothing within `clear` of the line and back to full by `blend`, as builders grade a railway's way. The
# ground under the track is then the smooth flank exactly, so the plan can set the track on it to the centimetre.
CORRIDOR = None   # dict(a=(x, z), b=(x, z) world, clear=, blend=)


def _seg_dist(p, a, b):
    L2 = (b[0] - a[0]) ** 2 + (b[1] - a[1]) ** 2
    t = max(0.0, min(1.0, ((p[0] - a[0]) * (b[0] - a[0]) + (p[1] - a[1]) * (b[1] - a[1])) / L2))
    return math.hypot(p[0] - a[0] - t * (b[0] - a[0]), p[1] - a[1] - t * (b[1] - a[1]))


def noise_weight(x, z):
    if CORRIDOR is None: return 1.0
    return _ss(CORRIDOR['clear'], CORRIDOR['blend'], _seg_dist((x, z), CORRIDOR['a'], CORRIDOR['b']))


def legacy(x, z, noise):
    """_legacy_terrain_height with the noise term replaced by `noise` in [-1, 1] (faded in the funicular's corridor)."""
    r = math.hypot(x, z)
    base = noise * noise_weight(x, z) * NOISE * _ss(0.0, 38.0, r)
    for c in LAVA_POOLS:
        d = math.dist((x, z), c)
        if d < LAVA_RADIUS: base = LAVA_FLOOR_Y
        elif d < LAVA_RIM_START: base = LAVA_FLOOR_Y + (38.0 - LAVA_FLOOR_Y) * _ss(LAVA_RADIUS, LAVA_RIM_START, d)
        elif d < LAVA_RIM_END: base += 38.0 * (1 - _ss(LAVA_RIM_START, LAVA_RIM_END, d))
    for c in SECONDARY:
        base += max(0.0, 1.0 - math.dist((x, z), c) / 145.0) * 42.0
    d = math.dist((x, z), CENTRE_WORLD)
    if d < RIM_RADIUS: base = _bowl(to_local((x, z)))
    elif d < OUTER_RADIUS: base = RIM_Y + (base - RIM_Y) * _ss(RIM_RADIUS, OUTER_RADIUS, d)
    g = math.dist((x, z), GATE_WORLD)
    if g < GATE_BLEND: base = GATE_Y + (base - GATE_Y) * _ss(GATE_CLEAR, GATE_BLEND, g)
    return base


def _plane(a, b, c, x, z):
    den = (b[2] - c[2]) * (a[0] - c[0]) + (c[0] - b[0]) * (a[2] - c[2])
    wa = ((b[2] - c[2]) * (x - c[0]) + (c[0] - b[0]) * (z - c[2])) / den
    wb = ((c[2] - a[2]) * (x - c[0]) + (a[0] - c[0]) * (z - c[2])) / den
    return wa * a[1] + wb * b[1] + (1 - wa - wb) * c[1]


def coarse(x, z, noise):
    """_coarse_mesh_height, every vertex at `noise`."""
    s = HALF_SIZE * 2 / (RESOLUTION - 1)
    fx = min(max((x + HALF_SIZE) / s, 0.0), RESOLUTION - 1.001); fz = min(max((z + HALF_SIZE) / s, 0.0), RESOLUTION - 1.001)
    ix, iz = min(int(fx), RESOLUTION - 2), min(int(fz), RESOLUTION - 2)
    v = lambda i, k: (-HALF_SIZE + i * s, legacy(-HALF_SIZE + i * s, -HALF_SIZE + k * s, noise), -HALF_SIZE + k * s)
    a, b, c, d = v(ix, iz), v(ix + 1, iz), v(ix, iz + 1), v(ix + 1, iz + 1)
    return _plane(a, c, b, x, z) if fx - ix + fz - iz <= 1.0 else _plane(b, c, d, x, z)


def set_corridor(a_local, b_local, clear, blend):
    global CORRIDOR
    CORRIDOR = dict(a=to_world(a_local), b=to_world(b_local), clear=clear, blend=blend)


def bounds_local(local):
    """(low, high) of the live ground under a point in FireCalderaPlan's local frame. Inside the rim the city's
    fine ground is the analytic bowl, exact; outside it the coarse mesh, bounded."""
    if math.hypot(*local) <= RIM_RADIUS: h = _bowl(local); return h, h
    x, z = to_world(local)
    return coarse(x, z, -1.0), coarse(x, z, 1.0)


def river_distance_local(local):
    x, z = to_world(local); best = 1e9
    for P in RIVER_PATHS:
        for a, b in zip(P, P[1:]):
            L2 = (b[0] - a[0]) ** 2 + (b[1] - a[1]) ** 2
            t = max(0.0, min(1.0, ((x - a[0]) * (b[0] - a[0]) + (z - a[1]) * (b[1] - a[1])) / L2))
            best = min(best, math.hypot(x - a[0] - t * (b[0] - a[0]), z - a[1] - t * (b[1] - a[1])))
    return best
