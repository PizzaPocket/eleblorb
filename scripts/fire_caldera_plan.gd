class_name FireCalderaPlan
extends RefCounted

## The Fire Kingdom caldera city's single plan (docs/architecture/
## fire_caldera_layout.md, approved 2026-10-06): the local frame, reservoir,
## plots, routes, emergency spokes, the lower city and its immersion shelves,
## the fourteen residents and the trade ledger. The city's builder and
## tools/validate_fire_plan.tscn read only this; nothing keeps a second list.
##
## Local frame: origin at the reservoir's centre, +Y from the kingdom gate into
## the city, +X to a visitor's right at the arrival threshold. Plot sizes are
## (across, deep): across runs along the bank, deep runs radially, and every
## building's front faces the reservoir.
##
## Changes from the layout's schematic numbers, found when the plan was first
## drawn to scale (recorded in the layout, section 4): the reserved envelopes
## of Kel, Civic, Aro and Renewal reached into the promenade (R1, 4 m wide at
## the bank plus 4 m), so they move outward along their own bearing by 3 to 6
## m and the reservoir's lobes toward them swell by 2 m rather than 3. Plots
## then turn a few degrees round the bank (Nahl 3, Vara 8, Aro 5) so no two
## reserved envelopes touch and each terrace link (R6, R7) has 5 m between
## its neighbours. Every adjacency and route connection is unchanged.

# ---------------------------------------------------------------------------
# Frame
# ---------------------------------------------------------------------------

## World plan positions (x, z) from the current terrain.
const GATE_WORLD := Vector2(0.0, -3.0)
const CENTRE_WORLD := Vector2(155.0, 85.0)
const FLOOR_RADIUS := 72.0
const SAFE_RADIUS := 58.0
const RIM_RADIUS := 112.0
const FLOOR_Y := -16.0


## Unit vector of local +Y in the world plan: from the gate to the centre.
static func forward() -> Vector2:
	return (CENTRE_WORLD - GATE_WORLD).normalized()


## Unit vector of local +X: a visitor's right, facing into the city.
static func right() -> Vector2:
	var f := forward()
	return Vector2(-f.y, f.x)


static func to_world(local: Vector2) -> Vector2:
	return CENTRE_WORLD + right() * local.x + forward() * local.y


static func to_local(world: Vector2) -> Vector2:
	var offset := world - CENTRE_WORLD
	return Vector2(offset.dot(right()), offset.dot(forward()))


# ---------------------------------------------------------------------------
# Reservoir: an irregular bank about a 30 m mean radius, broad lobes toward
# Aro, Renewal, Kel and Civic, shallower coves pulled back from the arrival
# sightline and the dry visitor counters (layout section 7).
# ---------------------------------------------------------------------------

const RESERVOIR_MEAN := 30.0
## [toward (local), push in metres]
const RESERVOIR_LOBES := [
	[Vector2(-39.0, 22.0), 2.0], [Vector2(-43.0, -4.0), 2.0], [Vector2(44.0, -4.0), 2.0], [Vector2(0.0, 43.0), 2.0],
	[Vector2(0.0, -46.0), -4.0], [Vector2(30.0, -34.0), -3.0], [Vector2(-27.0, -51.0), -3.0],
]
const LOBE_WIDTH := 0.42


## The bank's radius at bearing `angle` (radians, atan2 of local y, x).
static func reservoir_radius(angle: float) -> float:
	var radius := RESERVOIR_MEAN
	for lobe: Array in RESERVOIR_LOBES:
		var toward: Vector2 = lobe[0]
		var difference := wrapf(angle - toward.angle(), -PI, PI)
		radius += float(lobe[1]) * exp(-pow(difference / LOBE_WIDTH, 2.0))
	return radius


static func reservoir_polygon(samples: int = 96) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in samples:
		var angle := TAU * float(i) / float(samples)
		points.append(Vector2(cos(angle), sin(angle)) * reservoir_radius(angle))
	return points


# ---------------------------------------------------------------------------
# Plots (layout section 4). Centres and sizes in metres, local frame.
# ---------------------------------------------------------------------------

const PLOTS: Array[Dictionary] = [
	{"id": "ARRIVAL", "centre": Vector2(0.0, -46.0), "footprint": Vector2(16.0, 14.0), "reserved": Vector2(24.0, 20.0), "facing": Vector2(0.0, 1.0),
		"household": "", "program": "forecourt and paired pylons; the arrival axis stays 6 m clear", "occupied": false,
		# Open public ground: the arrival routes cross it.
		"open": true},
	{"id": "NAHL", "centre": Vector2(-36.5, -30.0), "footprint": Vector2(16.0, 12.0), "reserved": Vector2(22.0, 18.0),
		"household": "Nahl", "program": "tempering hall and Eris's suite; public face to the promenade, guest entrance toward arrival", "occupied": true,
		# The mediation room's conversation pit, dug into the plinth on its
		# uphill side, where the socket is deepest (in the building's frame).
		"pits": [{"at": Vector2(5.1, -3.5), "half": Vector2(1.95, 1.55), "depth": 0.5, "exponent": 4.0}],
		# A house of care: its plinth's top course is pale hot-spring sinter.
		"floor_finish": Color(0.90, 0.88, 0.83)},
	{"id": "GUEST", "centre": Vector2(-27.0, -51.0), "footprint": Vector2(15.5, 12.0), "reserved": Vector2(17.0, 14.0),
		"household": "Nahl", "program": "insulated guest house and party rest point, seen from arrival, apart from the treatment rooms", "occupied": true,
		# The enlarged shell nearly fills its reserved envelope; the foundation
		# supports it and the shallow public threshold terrace as one floor.
		"foundation": Vector2(17.0, 14.0),
		# Reached by R3 from the forecourt, not from the promenade.
		"on_promenade": false},
	{"id": "OREN", "centre": Vector2(30.0, -34.0), "footprint": Vector2(17.0, 12.0), "reserved": Vector2(22.0, 17.0),
		"household": "Oren", "program": "mineral counter to the arrival crescent; assay, secure store, preparation and receiving to the service loop", "occupied": true,
		# Split level (approved 2026-10-07): the shop at the promenade's level,
		# the workshop half 1.35 m up, flush with the service loop, joined by a
		# ramp along the staff corridor; the home's open-air ramp in the east
		# bay. Floors above the datum in the building's frame: flat
		# {"rect", "y"} or ramps {"rect", "from", "to", "axis"} rising from the
		# rect's low end (x or z) to its high end.
		"levels": [
			{"rect": Rect2(-8.5, -6.0, 15.0, 5.6), "y": 1.35},
			{"rect": Rect2(-8.5, -0.4, 9.7, 1.4), "y": 1.35},
			{"rect": Rect2(1.2, -0.4, 4.0, 1.4), "from": 1.35, "to": 0.0, "axis": "x"},
			{"rect": Rect2(-7.0, -6.8, 2.0, 0.8), "y": 1.35},
			{"rect": Rect2(6.5, -6.8, 2.0, 2.2), "y": 1.35},
			{"rect": Rect2(6.5, -4.6, 2.0, 4.24), "from": 1.35, "to": 4.0, "axis": "z"},
			{"rect": Rect2(6.5, -0.36, 2.0, 3.2), "y": 4.0},
		]},
	{"id": "KEL", "centre": Vector2(48.2, -4.4), "footprint": Vector2(19.0, 15.0), "reserved": Vector2(24.0, 20.0),
		"household": "Kel", "program": "armory gallery and receiving bay; residence on the quiet outer edge; protected descent to the deep forge", "occupied": true},
	{"id": "VARA", "centre": Vector2(32.9, 32.8), "footprint": Vector2(18.0, 14.0), "reserved": Vector2(23.0, 19.0),
		"household": "Vara", "program": "glass and metal studio round a daylight court; clean assembly to the promenade, hot forming toward Kel", "occupied": true},
	{"id": "CIVIC", "centre": Vector2(0.0, 49.0), "footprint": Vector2(24.0, 15.0), "reserved": Vector2(30.0, 21.0),
		"household": "", "program": "council, school, archive and upper observatory; landmark front to the reservoir and the arrival view", "occupied": true},
	{"id": "IREN", "centre": Vector2(-26.0, 50.0), "footprint": Vector2(12.0, 9.0), "reserved": Vector2(16.0, 13.0),
		"household": "Iren", "program": "household residence joined to the civic complex, acoustically apart", "occupied": true,
		# Reached by R5, behind the civic complex.
		"on_promenade": false},
	{"id": "ARO", "centre": Vector2(-39.4, 27.0), "footprint": Vector2(17.0, 13.0), "reserved": Vector2(22.0, 18.0),
		"household": "Aro", "program": "thermal works and household; public door on the terrace loop, service descent to the manifold", "occupied": true},
	{"id": "RENEWAL", "centre": Vector2(-33.35, -3.13), "footprint": Vector2(18.0, 14.0), "reserved": Vector2(23.0, 19.0),
		"household": "", "program": "tempering and gathering terrace above the submerged communal chamber", "occupied": false,
		# Revised 2026-10-08: a ghat. The terrace stands on the bank, its floor
		# level with the promenade that crosses its back (in its own frame, +Z
		# to the lava); in front, a broad flight of steps runs down into the
		# lava between two arms. Its own foundation (no plinth lip), the ground
		# cut away beneath it, each step a level for the height query.
		"crossed": true, "quay": true, "datum_at": Vector2(0.0, -2.8),
		"foundation_kind": "ghat", "sink": 6.0,
		"levels": [
			{"rect": Rect2(-7.0, 0.3, 14.0, 0.9), "y": -0.45},
			{"rect": Rect2(-7.0, 1.2, 14.0, 0.9), "y": -0.9},
			{"rect": Rect2(-7.0, 2.1, 14.0, 0.9), "y": -1.35},
			{"rect": Rect2(-7.0, 3.0, 14.0, 0.9), "y": -1.8},
			{"rect": Rect2(-7.0, 3.9, 14.0, 0.9), "y": -2.25},
			{"rect": Rect2(-7.0, 4.8, 14.0, 0.9), "y": -2.7},
			{"rect": Rect2(-7.0, 5.7, 14.0, 0.9), "y": -3.15},
			{"rect": Rect2(-7.0, 6.6, 14.0, 3.0), "y": -6.0},
		]},
]


static func plot(id: String) -> Dictionary:
	for entry in PLOTS:
		if str(entry["id"]) == id:
			return entry
	return {}


## The direction a plot's front faces: its own "facing", else toward the
## reservoir's centre.
static func facing(entry: Dictionary) -> Vector2:
	if entry.has("facing"):
		return (entry["facing"] as Vector2).normalized()
	return -(entry["centre"] as Vector2).normalized()


## Centre of the occupied shell. Most masses are centred in their reserved
## plot; an approved brief may offset one to make room for a named exterior
## use without moving the plot or any route.
static func mass_centre(entry: Dictionary) -> Vector2:
	var deep := facing(entry)
	var across := Vector2(-deep.y, deep.x)
	var offset: Vector2 = entry.get("mass_offset", Vector2.ZERO)
	return (entry["centre"] as Vector2) + across * offset.x + deep * offset.y


## A point in a building's own frame (CalderaShell's: +Z its front, origin
## its mass centre) in plan coordinates.
static func shell_to_plan(entry: Dictionary, local: Vector2) -> Vector2:
	var deep := facing(entry)
	var turned := Basis(Vector3.UP, atan2(deep.x, deep.y)) * Vector3(local.x, 0.0, local.y)
	return mass_centre(entry) + Vector2(turned.x, turned.z)


## A plan point in a building's own frame (the inverse of shell_to_plan).
static func plan_to_shell(entry: Dictionary, plan: Vector2) -> Vector2:
	var deep := facing(entry)
	var offset := plan - mass_centre(entry)
	var local := Basis(Vector3.UP, atan2(deep.x, deep.y)).inverse() * Vector3(offset.x, 0.0, offset.y)
	return Vector2(local.x, local.z)


## The height above the datum of a plot's built floor at a plan point (a
## raised level or a ramp), or NAN where the floor is the plinth's top.
static func level_height(entry: Dictionary, plan: Vector2) -> float:
	var levels: Array = entry.get("levels", [])
	if levels.is_empty():
		return NAN
	var local := plan_to_shell(entry, plan)
	for level: Dictionary in levels:
		var rect: Rect2 = level["rect"]
		if not rect.has_point(local):
			continue
		if level.has("y"):
			return float(level["y"])
		var t := (local.x - rect.position.x) / rect.size.x if str(level["axis"]) == "x" else (local.y - rect.position.y) / rect.size.y
		return lerpf(float(level["from"]), float(level["to"]), clampf(t, 0.0, 1.0))
	return NAN


## A plot's sunken pits (conversation pits dug into its plinth) as plan
## outlines: [{"outline": PackedVector2Array, "depth": float}].
static func pit_outlines(entry: Dictionary) -> Array[Dictionary]:
	var list: Array[Dictionary] = []
	for pit: Dictionary in entry.get("pits", []):
		var at: Vector2 = pit["at"]
		var half: Vector2 = pit["half"]
		var exponent := float(pit.get("exponent", 4.0))
		var outline := PackedVector2Array()
		for i in 48:
			var t := TAU * float(i) / 48.0
			var c := cos(t)
			var s := sin(t)
			var local := at + Vector2(signf(c) * pow(absf(c), 2.0 / exponent) * half.x, signf(s) * pow(absf(s), 2.0 / exponent) * half.y)
			outline.append(shell_to_plan(entry, local))
		list.append({"outline": outline, "depth": float(pit["depth"]), "lava": bool(pit.get("lava", false))})
	return list


## A plot's rectangle (footprint or reserved) as four corners, its depth along
## its facing.
static func plot_polygon(entry: Dictionary, key: String = "reserved") -> PackedVector2Array:
	var centre: Vector2 = entry["centre"]
	var size: Vector2 = entry[key]
	var deep := facing(entry)
	var across := Vector2(-deep.y, deep.x)
	var points := PackedVector2Array()
	for corner: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1)]:
		points.append(centre + across * corner.x * size.x * 0.5 + deep * corner.y * size.y * 0.5)
	return points


## The middle of a plot's front edge (its public threshold side).
static func front_point(entry: Dictionary, key: String = "reserved") -> Vector2:
	return (entry["centre"] as Vector2) + facing(entry) * (entry[key] as Vector2).y * 0.5


## The middle of a plot's back edge (service and receiving).
static func back_point(entry: Dictionary, key: String = "reserved") -> Vector2:
	return (entry["centre"] as Vector2) - facing(entry) * (entry[key] as Vector2).y * 0.5


# ---------------------------------------------------------------------------
# Routes (layout section 5). Rings are drawn from the bank and the plots, so a
# moved plot moves its routes with it.
# ---------------------------------------------------------------------------

## R1 runs this far out from the bank, centre line.
const PROMENADE_OFFSET := 4.0
## R2 runs this far behind the plots' back edges, centre line.
const SERVICE_OFFSET := 3.0
## Bearings (degrees) where R1 starts and ends: the promenade is broken at
## the arrival, from Nahl round the far bank to Oren.
const PROMENADE_FROM := -120.0
const PROMENADE_TO := -60.0
## R2 runs from the guest house's receiving side round to Nahl's care service.
const SERVICE_FROM := -118.0
const SERVICE_TO := 218.0


static func promenade() -> PackedVector2Array:
	var points := PackedVector2Array()
	# Going the long way round: west, far bank, east.
	var start := deg_to_rad(PROMENADE_FROM + 360.0)
	var finish := deg_to_rad(PROMENADE_TO)
	var steps := 60
	var radii := PackedFloat32Array()
	for i in steps + 1:
		radii.append(promenade_radius(lerpf(start, finish, float(i) / float(steps))))
	radii = _smooth_out(radii, 2)
	for i in steps + 1:
		var angle := lerpf(start, finish, float(i) / float(steps))
		points.append(Vector2(cos(angle), sin(angle)) * radii[i])
	return points


## A running maximum then a running mean of the same width: it smooths a ring
## that steps at plot edges without ever bringing it inside the raw radius.
static func _smooth_out(radii: PackedFloat32Array, window: int) -> PackedFloat32Array:
	var widened := PackedFloat32Array()
	for i in radii.size():
		var high := radii[i]
		for k in range(maxi(i - window, 0), mini(i + window + 1, radii.size())):
			high = maxf(high, radii[k])
		widened.append(high)
	var result := PackedFloat32Array()
	for i in radii.size():
		var total := 0.0
		var count := 0
		for k in range(maxi(i - window, 0), mini(i + window + 1, radii.size())):
			total += widened[k]
			count += 1
		result.append(total / float(count))
	return result


## R1's radius at a bearing: the bank plus its offset, but where the bank pulls
## back into a cove it keeps to the building fronts instead (no more than
## FRONT_TERRACE from a front), so every door stays on the promenade.
const FRONT_TERRACE := 4.5


static func promenade_radius(angle: float) -> float:
	var radius := reservoir_radius(angle) + PROMENADE_OFFSET
	for entry in PLOTS:
		if bool(entry.get("open", false)) or not bool(entry.get("on_promenade", true)):
			continue
		var centre: Vector2 = entry["centre"]
		var size: Vector2 = entry["reserved"]
		var half_angle := atan2(size.x * 0.5, centre.length() - size.y * 0.5)
		if absf(wrapf(angle - centre.angle(), -PI, PI)) <= half_angle:
			radius = maxf(radius, centre.length() - size.y * 0.5 - FRONT_TERRACE)
	return radius


## The service ring's radius at a bearing: just behind the deepest plot there.
static func service_radius(angle: float) -> float:
	var radius := 50.0
	for entry in PLOTS:
		var centre: Vector2 = entry["centre"]
		var size: Vector2 = entry["reserved"]
		var half_angle := atan2(size.x * 0.5 + SERVICE_OFFSET, centre.length()) + deg_to_rad(4.0)
		if absf(wrapf(angle - centre.angle(), -PI, PI)) <= half_angle:
			radius = maxf(radius, centre.length() + size.y * 0.5 + SERVICE_OFFSET)
	return radius


static func service_loop() -> PackedVector2Array:
	var start := deg_to_rad(SERVICE_FROM)
	var finish := deg_to_rad(SERVICE_TO)
	var steps := 84
	var radii := PackedFloat32Array()
	for i in steps + 1:
		radii.append(service_radius(lerpf(start, finish, float(i) / float(steps))))
	# Smoothed so it bends round the plots instead of stepping at their edges.
	radii = _smooth_out(radii, 2)
	var points := PackedVector2Array()
	for i in radii.size():
		var angle := lerpf(start, finish, float(i) / float(steps))
		points.append(Vector2(cos(angle), sin(angle)) * radii[i])
	return points


## Every route: id, width, class (public, service, link), role, points.
static func routes() -> Array[Dictionary]:
	var list: Array[Dictionary] = []
	var arrival := plot("ARRIVAL")
	var forecourt: Vector2 = arrival["centre"]
	var overlook := Vector2(0.0, -reservoir_radius(-PI * 0.5) - 1.5)
	list.append({"id": "R0", "width": 6.0, "class": "public", "role": "arrival axis: gate approach, pylons, forecourt, reservoir overlook",
		"points": PackedVector2Array([Vector2(0.0, -FLOOR_RADIUS - 6.0), Vector2(0.0, -56.0), forecourt, overlook])})
	var prom := promenade()
	list.append({"id": "R1", "width": 4.0, "class": "public", "role": "reservoir promenade", "points": prom})
	list.append({"id": "R2", "width": 3.5, "class": "service", "role": "outer service loop", "points": service_loop()})
	# R3 and R4: from the forecourt's flanks past the guest house and Oren to
	# the promenade's two ends.
	var guest_front := front_point(plot("GUEST"))
	# R3 runs straight from the forecourt's west side to the promenade's west
	# end (Nahl and Renewal beyond); the guest house's door takes a short
	# branch off it, so the hospitality route does not hook out and back.
	var guest_step := guest_front + facing(plot("GUEST")) * 3.0
	var r3_from := forecourt + Vector2(-10.0, 4.0)
	list.append({"id": "R3", "width": 4.0, "class": "public", "role": "arrival west link: forecourt, Nahl, Renewal",
		"points": PackedVector2Array([r3_from, prom[0]])})
	list.append({"id": "R3g", "width": 3.0, "class": "public", "role": "the guest house's door, off the arrival west link",
		"points": PackedVector2Array([r3_from.lerp(prom[0], 0.15), guest_step])})
	list.append({"id": "R4", "width": 4.0, "class": "public", "role": "arrival east link: forecourt, Oren, Kel",
		"points": PackedVector2Array([forecourt + Vector2(10.0, 2.0), prom[prom.size() - 1]])})
	# R5: from the promenade between Civic and Aro straight out to Iren's door,
	# past Civic's west end.
	var iren_front := front_point(plot("IREN"))
	list.append({"id": "R5", "width": 4.0, "class": "public", "role": "far civic link to the Iren residence",
		"points": PackedVector2Array([_on_ring(iren_front.angle(), prom), iren_front])})
	# R6 and R7: the resident terrace loop's radial links through the gaps
	# between plots, joining the promenade to the service loop (west: thermal
	# and care; east: craft and materials).
	for link: Array in [["R6", "thermal link, Renewal and Aro", "RENEWAL", "ARO"],
			["R7", "craft link, Oren and Kel", "OREN", "KEL"], ["R7b", "craft link, Kel and Vara", "KEL", "VARA"], ["R7c", "craft link, Vara and Civic", "VARA", "CIVIC"]]:
		var a: Vector2 = plot(str(link[2]))["centre"]
		var b: Vector2 = plot(str(link[3]))["centre"]
		var angle := _clear_bearing(str(link[2]), str(link[3]))
		var inner := _on_ring(angle, prom)
		var outer := Vector2(cos(angle), sin(angle)) * service_radius(angle)
		list.append({"id": str(link[0]), "width": 3.5, "class": "link", "role": str(link[1]), "points": PackedVector2Array([inner, outer])})
	return list


## Emergency ascent spokes (layout section 6): from the dry network out to a
## safe shelf beyond the caldera floor.
static func emergency_spokes() -> Array[Dictionary]:
	var list: Array[Dictionary] = []
	for spoke: Array in [["E0", -90.0, "arrival ascent"], ["E1", 131.0, "west ascent, Aro and Civic"], ["E2", 70.0, "far ascent, Civic and Vara"], ["E3", -26.0, "east ascent, Kel and Oren"]]:
		var angle := deg_to_rad(float(spoke[1]))
		var from := Vector2(0.0, -56.0) if str(spoke[0]) == "E0" else Vector2(cos(angle), sin(angle)) * service_radius(angle)
		list.append({"id": str(spoke[0]), "width": 3.5, "role": str(spoke[2]), "points": PackedVector2Array([from, Vector2(cos(angle), sin(angle)) * (FLOOR_RADIUS + 4.0)])})
	return list


## The arrival-to-civic sightline: nothing but the reservoir may cross it.
static func sightline() -> PackedVector2Array:
	return PackedVector2Array([(plot("ARRIVAL")["centre"] as Vector2), front_point(plot("CIVIC"), "footprint")])


static func _bisect(a: float, b: float) -> float:
	return a + wrapf(b - a, -PI, PI) * 0.5


## The bearing between two neighbouring plots whose radial line, from the
## promenade out to the service loop, keeps furthest from both: corners
## stick out, so the plain bisector can clip one.
static func _clear_bearing(a_id: String, b_id: String) -> float:
	var a := plot(a_id)
	var b := plot(b_id)
	var start := (a["centre"] as Vector2).angle()
	var span := wrapf((b["centre"] as Vector2).angle() - start, -PI, PI)
	var best := _bisect(start, start + span)
	var best_clearance := -INF
	for i in range(1, 60):
		var angle := start + span * float(i) / 60.0
		var direction := Vector2(cos(angle), sin(angle))
		var from := direction * promenade_radius(angle)
		var to := direction * service_radius(angle)
		var clearance := minf(_segment_polygon_distance(from, to, plot_polygon(a)), _segment_polygon_distance(from, to, plot_polygon(b)))
		if clearance > best_clearance:
			best_clearance = clearance
			best = angle
	return best


static func _segment_polygon_distance(from: Vector2, to: Vector2, polygon: PackedVector2Array) -> float:
	var best := INF
	for i in polygon.size():
		var closest := Geometry2D.get_closest_points_between_segments(from, to, polygon[i], polygon[(i + 1) % polygon.size()])
		best = minf(best, closest[0].distance_to(closest[1]))
	return best


## The promenade's point at a bearing (`_ring` kept for the call sites).
static func _on_ring(angle: float, _ring: PackedVector2Array) -> Vector2:
	return Vector2(cos(angle), sin(angle)) * promenade_radius(angle)


# ---------------------------------------------------------------------------
# Lower city (layout section 7)
# ---------------------------------------------------------------------------

## id, centre (local), depth band below the lava surface (m), purpose.
const LOWER_ROOMS: Array[Dictionary] = [
	{"id": "L0", "name": "renewal chamber", "centre": Vector2(-25.0, -8.0), "depth": Vector2(5.0, 8.0), "purpose": "communal immersion and the coming-of-age practice; seen from the Renewal terrace"},
	{"id": "L1", "name": "primary manifold", "centre": Vector2(-25.0, 15.0), "depth": Vector2(9.0, 13.0), "purpose": "Miru and Tovan's thermal distribution, controls and inspection loop"},
	{"id": "L2", "name": "deep observatory", "centre": Vector2(-2.0, 25.0), "depth": Vector2(14.0, 18.0), "purpose": "Selka's vent instruments below Civic"},
	{"id": "L3", "name": "fired archive", "centre": Vector2(-10.0, 18.0), "depth": Vector2(10.0, 14.0), "purpose": "cast and engraved records beside the observatory"},
	{"id": "L4", "name": "high-temperature forge", "centre": Vector2(24.0, 3.0), "depth": Vector2(10.0, 16.0), "purpose": "Daro, Vesa and Ruun's hot-work floor, with a secure lift to the gallery"},
	{"id": "L5", "name": "experimental materials bay", "centre": Vector2(18.0, 18.0), "depth": Vector2(8.0, 13.0), "purpose": "the shared Kel and Vara testing space"},
]

## The lower inspection loop: curved passages round the vent, never through
## it, so every occupied chamber has two ways out.
const LOWER_PASSAGES := [["L0", "L1"], ["L1", "L3"], ["L3", "L2"], ["L2", "L5"], ["L5", "L4"], ["L4", "L0"]]

## The three public immersion shelves: from a surface plot down to a room.
const IMMERSION_SHELVES: Array[Dictionary] = [
	{"id": "S0", "plot": "RENEWAL", "room": "L0", "note": "the gentlest and most social entry"},
	{"id": "S1", "plot": "CIVIC", "room": "L2", "note": "the deep scientific descent from the observation landing"},
	{"id": "S2", "plot": "KEL", "room": "L4", "note": "the protected hot-work landing, kept out of the gallery"},
]

## Service lifts: forge to Kel, experimental bay to Vara, archive to Civic.
const LIFTS := [["L4", "KEL"], ["L5", "VARA"], ["L3", "CIVIC"]]

## Thermal branches (section 8): the annular spine under the west and far bank
## from the manifold, and the separate hot branch. Neither runs under GUEST.
const THERMAL_BRANCHES: Array[Dictionary] = [
	{"id": "spine", "from": "L1", "serves": ["ARO", "IREN", "CIVIC", "VARA", "KEL", "NAHL", "RENEWAL"]},
	{"id": "hot", "from": "L4", "serves": ["L5"]},
]

# ---------------------------------------------------------------------------
# People (docs/architecture/fire_caldera_city.md, approved census) and trade
# ---------------------------------------------------------------------------

const RESIDENTS: Array[Dictionary] = [
	{"name": "Tovan Aro", "age": 63, "home": "ARO", "work": ["ARO", "L1"], "job": "senior vent steward"},
	{"name": "Miru Aro", "age": 38, "home": "ARO", "work": ["ARO", "L1"], "job": "thermal engineer and pipe fitter"},
	{"name": "Kes Aro", "age": 15, "home": "ARO", "work": ["ARO"], "job": "apprentice engineer"},
	{"name": "Selka Iren", "age": 46, "home": "IREN", "work": ["CIVIC", "L2"], "job": "geologist and seismologist"},
	{"name": "Aru Iren", "age": 43, "home": "IREN", "work": ["CIVIC", "L3"], "job": "teacher and archivist"},
	{"name": "Mena Iren", "age": 10, "home": "IREN", "work": ["CIVIC", "VARA"], "job": "pupil"},
	{"name": "Daro Kel", "age": 45, "home": "KEL", "work": ["KEL", "L4"], "job": "metallurgist and armorer"},
	{"name": "Vesa Kel", "age": 42, "home": "KEL", "work": ["KEL", "L4"], "job": "weaponsmith and fabricator"},
	{"name": "Ruun Kel", "age": 17, "home": "KEL", "work": ["KEL", "L4"], "job": "apprentice smith"},
	{"name": "Omi Vara", "age": 34, "home": "VARA", "work": ["VARA", "L5"], "job": "structural and scientific glassworker"},
	{"name": "Talen Vara", "age": 36, "home": "VARA", "work": ["VARA"], "job": "stained-glass designer and art metalworker"},
	{"name": "Pela Oren", "age": 40, "home": "OREN", "work": ["OREN"], "job": "mineral forager and gem cutter"},
	{"name": "Savi Oren", "age": 33, "home": "OREN", "work": ["OREN"], "job": "mineral preparer"},
	{"name": "Eris Nahl", "age": 71, "home": "NAHL", "work": ["NAHL", "GUEST", "RENEWAL"], "job": "temperer, mediator and guest caretaker"},
]

## The two visitor-facing counters and where their goods come from (the
## architecture skill's trade provenance rule). Stock itself stays open.
const TRADE := {
	"armory": {"vendor": "Daro Kel", "counter": "KEL", "made_at": ["L4", "KEL"], "makers": ["Daro Kel", "Vesa Kel", "Ruun Kel"], "inputs": "ore and alloy stock from Pela's receiving shelf"},
	"minerals": {"vendor": "Pela Oren", "counter": "OREN", "made_at": ["OREN"], "makers": ["Pela Oren"], "inputs": "deposits Pela surveys outside the caldera and dives for in the reservoir"},
}

## The rest point: the guest house, kept by Eris.
const REST_POINT := {"plot": "GUEST", "keeper": "Eris Nahl", "fee": 25}
