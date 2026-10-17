"""The Fire Caldera's local frame and plots, as FireCalderaPlan has them (scripts/fire_caldera_plan.gd).

Shared by the Python plan tools for the caldera. Keep PLOTS in step with FireCalderaPlan.PLOTS; the walkway
tool checks that the model's surface export agrees with it when one is embedded.
"""
import math

LAVA_Y = 29.2
FLOOR_RADIUS, RIM_RADIUS, FLOOR_Y, LIP_Y = 52.0, 112.0, 30.0, 48.0
HIGHLINE_RADIUS, HIGHLINE_WIDTH, HIGHLINE_DATUM = 72.0, 4.8, 42.5
REVEAL = 1.2        # SocketPlinth.REVEAL: a platform's edge beyond its foundation size
PLAN_EXPONENT = 10.0

RESERVOIR_MEAN = 52.0
LOBES = [((-39.0, 22.0), -0.5, 0.42), ((-50.0, -5.0), 2.5, 0.42), ((-50.0, -5.0), 2.5, 0.18), ((44.0, -4.0), -0.5, 0.42),
         ((0.0, 43.0), 2.0, 0.42), ((0.0, -46.0), -4.0, 0.42), ((30.0, -34.0), -3.0, 0.42), ((-27.0, -51.0), -3.0, 0.42)]

PLOTS = [
    dict(id='ARRIVAL', centre=(0.0, -106.0), footprint=(16.0, 10.0), reserved=(22.0, 12.0), open=True),
    dict(id='NAHL', centre=(-63.75, -52.27), footprint=(16.0, 12.0), reserved=(22.0, 18.0), foundation=(22.0, 18.0), site='highline'),
    dict(id='GUEST', centre=(22.0, -98.5), footprint=(15.5, 12.0), reserved=(19.0, 16.0), foundation=(19.0, 16.0), site='gate_platform', facing=(-1.0, 0.0)),
    dict(id='OREN', centre=(41.8, -47.4), footprint=(17.0, 12.0), reserved=(22.0, 17.0), site='ground'),
    dict(id='KEL', centre=(57.6, -21.0), footprint=(19.0, 15.0), reserved=(24.0, 17.0), foundation=(21.0, 17.0), site='ground'),
    dict(id='VARA', centre=(59.0, 58.9), footprint=(18.0, 14.0), reserved=(23.0, 19.0), foundation=(23.0, 19.0), site='highline'),
    dict(id='CIVIC', centre=(0.0, 83.9), footprint=(24.0, 15.0), reserved=(30.0, 21.0), foundation=(30.0, 21.0), site='highline'),
    dict(id='IREN', centre=(-37.3, 71.8), footprint=(12.0, 9.0), reserved=(16.0, 13.0), foundation=(16.0, 13.0), site='highline'),
    dict(id='ARO', centre=(-51.0, 35.7), footprint=(17.0, 13.0), reserved=(22.0, 16.0), foundation=(19.0, 15.0), site='ground'),
    dict(id='RENEWAL', centre=(-58.7, -5.5), footprint=(18.0, 14.0), reserved=(23.0, 19.0), foundation=(22.6, 18.6), site='ground'),
]
PLOT = {p['id']: p for p in PLOTS}


def bank(bearing):
    """FireCalderaPlan.reservoir_radius at a bearing in degrees."""
    a = math.radians(bearing); r = RESERVOIR_MEAN
    for (tx, ty), push, width in LOBES:
        diff = (a - math.atan2(ty, tx) + math.pi) % (2 * math.pi) - math.pi
        r += push * math.exp(-(diff / width) ** 2)
    return r


def bowl_y(r):
    """FireCalderaGround.outer_bowl_height."""
    t = min(max((r - FLOOR_RADIUS) / (RIM_RADIUS - FLOOR_RADIUS), 0.0), 1.0)
    return FLOOR_Y + (LIP_Y - FLOOR_Y) * t * t


def flank_y(r):
    """The volcano's outer flank beyond the lip (fire_kingdom_terrain's legacy height, without its noise)."""
    if r <= RIM_RADIUS: return bowl_y(r)
    t = min(max((r - RIM_RADIUS) / (205.0 - RIM_RADIUS), 0.0), 1.0); s = t * t * (3 - 2 * t)
    return LIP_Y * (1 - s)


def pol(r, b): a = math.radians(b); return (r * math.cos(a), r * math.sin(a))
def brg(x, y): return math.degrees(math.atan2(y, x))
def adiff(a, b): return (a - b + 180) % 360 - 180


def facing(p):
    if 'facing' in p:
        f = p['facing']; n = math.hypot(*f); return (f[0] / n, f[1] / n)
    c = p['centre']; n = math.hypot(*c); return (-c[0] / n, -c[1] / n)


def shell_to_plan(p, local):
    """A point in a building's own frame (+y its front, toward its facing) in plan coordinates."""
    dx, dy = facing(p); a = math.atan2(dx, dy); c, s = math.cos(a), math.sin(a)
    x, z = local
    return (p['centre'][0] + x * c + z * s, p['centre'][1] - x * s + z * c)


def plan_to_shell(p, q):
    dx, dy = facing(p); a = math.atan2(dx, dy); c, s = math.cos(a), math.sin(a)
    ox, oy = q[0] - p['centre'][0], q[1] - p['centre'][1]
    return (ox * c - oy * s, ox * s + oy * c)


def shell_turn(p):
    """The plan angle (radians) of a building's own +x axis."""
    q0 = shell_to_plan(p, (0, 0)); q1 = shell_to_plan(p, (1, 0))
    return math.atan2(q1[1] - q0[1], q1[0] - q0[0])
