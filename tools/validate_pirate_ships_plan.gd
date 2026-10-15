extends Node

const PirateShipsPlan := preload("res://scripts/pirate_ships_plan.gd")

## Plan validator for the two pirate ships. It reads only PirateShipsPlan (and
## the ocean terrain's height for the routes), so it runs before either ship is
## rebuilt:
##
##   Godot --headless --path . tools/validate_pirate_ships_plan.tscn
##
## Exit code 1 if anything FAILs. The rules are
## docs/architecture/ocean_pirate_ships_design.md and ocean_pirate_ships.md:
##   - every room stands inside the hull, less the planking, on its own deck,
##     with headroom under the deck above, and no two rooms overlap;
##   - every companion ramp is 1.4 m wide at 32 degrees, lands on both its
##     decks inside the hull, and keeps clear of the masts and other ramps;
##   - everything below the waterline lies in a dry volume;
##   - twelve crew, each with a room for every part of the day, and only the
##     gunner and the powder boy in the powder rooms;
##   - each route keeps deep water, stays in the Kraken's water, clears the
##     dock, stops over its own wreck every day, passes the galleon, and the
##     two ships never come within SEPARATION of each other.

const EPS := 0.01
const MAST_RADIUS := 0.45
const KRAKEN_MARGIN := 40.0
const DOCK_CLEAR := 60.0
const STOP_REACH := 25.0
const GALLEON_REACH := 45.0
const SEPARATION := 60.0
const DAYS := 7
const TERRAIN := preload("res://scripts/ocean_kingdom_terrain.gd")

var _failures := 0


func _ready() -> void:
	for key in PirateShipsPlan.SHIPS:
		_check_rooms(key)
		_check_ramps(key)
		_check_dry(key)
		_check_crew(key)
	var terrain = TERRAIN.new()
	for key in PirateShipsPlan.SHIPS:
		_check_route(key, terrain)
	terrain.free()
	_check_separation()
	print("---- validate_pirate_ships_plan: %d ships, %d FAIL" % [PirateShipsPlan.SHIPS.size(), _failures])
	get_tree().quit(1 if _failures > 0 else 0)


func _fail(message: String) -> void:
	_failures += 1
	print("FAIL ", message)


func _deck(key: String, name: String) -> Array:
	for d in PirateShipsPlan.SHIPS[key]["decks"]:
		if d[0] == name:
			return d
	return []


## The floor of the next deck above (name) at length z, or INF.
func _deck_above(key: String, name: String, z: float) -> float:
	var y0 := float(_deck(key, name)[1])
	var best := INF
	for d in PirateShipsPlan.SHIPS[key]["decks"]:
		var span: Vector2 = d[2]
		if float(d[1]) > y0 + EPS and z >= span.x and z <= span.y:
			best = minf(best, float(d[1]))
	return best


func _inside(key: String, x: float, z: float, y: float) -> bool:
	return absf(x) <= PirateShipsPlan.hull_half_breadth(key, z, y) - PirateShipsPlan.PLANKING + EPS


func _check_rooms(key: String) -> void:
	var ship: Dictionary = PirateShipsPlan.SHIPS[key]
	var rooms: Array = ship["rooms"]
	for room in rooms:
		var r: Rect2 = room[2]
		var deck := _deck(key, room[1])
		if deck.is_empty():
			_fail("%s: %s stands on no deck" % [key, room[0]])
			continue
		var y := float(deck[1])
		var span: Vector2 = deck[2]
		var fits := true
		for yy in [y + 0.3, y + 2.0]:
			for xx in [r.position.x, r.end.x]:
				for zz in [r.position.y, r.end.y, r.get_center().y]:
					fits = fits and _inside(key, xx, zz, yy)
		if not fits:
			_fail("%s: %s reaches outside the hull" % [key, room[0]])
		if r.position.y < span.x - EPS or r.end.y > span.y + EPS:
			_fail("%s: %s runs off the end of the %s" % [key, room[0], room[1]])
		if not ship["open"].has(room[0]):
			var above := minf(_deck_above(key, room[1], r.position.y + 0.2), _deck_above(key, room[1], r.end.y - 0.2))
			if above < INF and above - PirateShipsPlan.DECK_THICKNESS - y < PirateShipsPlan.HEADROOM - EPS:
				_fail("%s: %s has only %.2f m headroom" % [key, room[0], above - PirateShipsPlan.DECK_THICKNESS - y])
	for i in rooms.size():
		for j in range(i + 1, rooms.size()):
			if rooms[i][1] == rooms[j][1] and (rooms[i][2] as Rect2).grow(-EPS).intersects((rooms[j][2] as Rect2).grow(-EPS)):
				_fail("%s: %s and %s overlap" % [key, rooms[i][0], rooms[j][0]])


func _check_ramps(key: String) -> void:
	var ship: Dictionary = PirateShipsPlan.SHIPS[key]
	var ramps: Array = ship["ramps"]
	for ramp in ramps:
		var x: Vector2 = ramp["x"]
		var foot: Vector2 = ramp["foot"]
		var head: Vector2 = ramp["head"]
		var run: Vector2 = ramp["run"]
		var from := _deck(key, ramp["from"])
		var to := _deck(key, ramp["to"])
		var label := "%s: the %s-%s ramp" % [key, ramp["from"], ramp["to"]]
		if absf(x.y - x.x - PirateShipsPlan.RAMP_WIDTH) > EPS:
			_fail("%s is not %.1f m wide" % [label, PirateShipsPlan.RAMP_WIDTH])
		var rise := float(to[1]) - float(from[1])
		if absf(rise / (run.y - run.x) - tan(deg_to_rad(PirateShipsPlan.RAMP_ANGLE))) > 0.02:
			_fail("%s is not at %.0f degrees" % [label, PirateShipsPlan.RAMP_ANGLE])
		for zz in [foot.x, foot.y]:
			if not (_inside(key, x.x, zz, float(from[1]) + 0.3) and _inside(key, x.y, zz, float(from[1]) + 0.3)):
				_fail("%s's foot is outside the hull" % label)
		for zz in [head.x, head.y]:
			if not (_inside(key, x.x, zz, float(to[1]) + 0.3) and _inside(key, x.y, zz, float(to[1]) + 0.3)):
				_fail("%s's head is outside the hull" % label)
		var fspan: Vector2 = from[2]
		var tspan: Vector2 = to[2]
		if foot.x < fspan.x - EPS or foot.y > fspan.y + EPS:
			_fail("%s's foot stands off the %s" % [label, ramp["from"]])
		if head.x < tspan.x - EPS or head.y > tspan.y + EPS:
			_fail("%s's head lands off the %s" % [label, ramp["to"]])
		var z0 := minf(foot.x, head.x)
		var z1 := maxf(foot.y, head.y)
		for mast in ship["masts"]:
			var mz := float(mast[1])
			if z0 - MAST_RADIUS < mz and mz < z1 + MAST_RADIUS and x.x - MAST_RADIUS < 0.0 and 0.0 < x.y + MAST_RADIUS:
				_fail("%s runs into the %s" % [label, mast[0]])
	for i in ramps.size():
		for j in range(i + 1, ramps.size()):
			var a: Dictionary = ramps[i]
			var b: Dictionary = ramps[j]
			if not [a["from"], a["to"]].has(b["from"]) and not [a["from"], a["to"]].has(b["to"]):
				continue
			var ra := Rect2(a["x"].x, minf(a["foot"].x, a["head"].x), a["x"].y - a["x"].x, maxf(a["foot"].y, a["head"].y) - minf(a["foot"].x, a["head"].x))
			var rb := Rect2(b["x"].x, minf(b["foot"].x, b["head"].x), b["x"].y - b["x"].x, maxf(b["foot"].y, b["head"].y) - minf(b["foot"].x, b["head"].x))
			if ra.grow(-EPS).intersects(rb.grow(-EPS)):
				_fail("%s: the %s-%s and %s-%s ramps overlap" % [key, a["from"], a["to"], b["from"], b["to"]])


func _check_dry(key: String) -> void:
	var ship: Dictionary = PirateShipsPlan.SHIPS[key]
	for room in ship["rooms"]:
		var y := float(_deck(key, room[1])[1])
		if y >= 0.3:
			continue
		var dry := false
		for d in ship["dry"]:
			dry = dry or (y >= float(d[1]) - EPS and y < float(d[2]))
		if not dry:
			_fail("%s: %s is below the waterline outside a dry volume" % [key, room[0]])


func _check_crew(key: String) -> void:
	var ship: Dictionary = PirateShipsPlan.SHIPS[key]
	var crew: Array = ship["crew"]
	if crew.size() != 12:
		_fail("%s has a crew of %d, not twelve" % [key, crew.size()])
	var rooms := {}
	for room in ship["rooms"]:
		rooms[room[0]] = true
	for spot in PirateShipsPlan.OFF_DECK:
		rooms[spot] = true
	var schedule: Dictionary = ship["schedule"]
	for member in crew:
		var who: String = member[0]
		if not ["man", "woman", "boy", "girl"].has(member[1]):
			_fail("%s: %s has no gender" % [key, who])
		if not schedule.has(who) or schedule[who].size() != PirateShipsPlan.PARTS.size():
			_fail("%s: %s needs a room for every part of the day" % [key, who])
			continue
		for room in schedule[who]:
			if not rooms.has(room):
				_fail("%s: %s works in %s, which is not aboard" % [key, who, room])
			if PirateShipsPlan.RESTRICTED.has(room) and not PirateShipsPlan.RESTRICTED[room].has(who):
				_fail("%s: %s may not enter the %s" % [key, who, room])
	for i in PirateShipsPlan.PARTS.size():
		var aloft := 0
		for who in schedule:
			if schedule[who][i] == "foretop":
				aloft += 1
		if aloft > 1:
			_fail("%s: two lookouts at the masthead at %s" % [key, PirateShipsPlan.PARTS[i]])


func _check_route(key: String, terrain) -> void:
	var ship: Dictionary = PirateShipsPlan.SHIPS[key]
	var line: PackedVector2Array = ship["route"]
	var draft := float(ship["hull"]["draft"])
	var kraken := PirateShipsPlan.KRAKEN
	var limit := 1.0 - KRAKEN_MARGIN / minf(kraken.x, kraken.y)
	var shallow := 0
	var galleon := INF
	for p in line:
		if terrain._raw_height(p.x, p.y) > -(draft + 3.0):
			shallow += 1
		if Vector2(p.x / kraken.x, p.y / kraken.y).length() > limit:
			_fail("%s's route strays into the Kraken's water at %s" % [key, p])
			break
		if p.length() < DOCK_CLEAR:
			_fail("%s's route passes within %.0f m of the dock" % [key, DOCK_CLEAR])
			break
		galleon = minf(galleon, p.distance_to(PirateShipsPlan.WRECKS["galleon"]))
	if shallow > 0:
		_fail("%s's route crosses %d points shallower than %.1f m" % [key, shallow, draft + 3.0])
	if galleon > GALLEON_REACH:
		_fail("%s's route does not pass the contested galleon" % key)
	var wreck: Vector2 = PirateShipsPlan.WRECKS[ship["stop"]]
	for day in DAYS:
		var t := (day * 24.0 + float(ship["stop_hour"])) * PirateShipsPlan.GAME_SECONDS_PER_HOUR + 30.0
		if position(key, t).distance_to(wreck) > STOP_REACH:
			_fail("%s is not over the %s at its stop hour on day %d" % [key, ship["stop"], day])


func _check_separation() -> void:
	var keys := PirateShipsPlan.SHIPS.keys()
	var closest := INF
	var when := 0.0
	var t := 0.0
	var end := DAYS * 24.0 * PirateShipsPlan.GAME_SECONDS_PER_HOUR
	while t < end:
		var d := position(keys[0], t).distance_to(position(keys[1], t))
		if d < closest:
			closest = d
			when = t
		t += 2.0
	if closest < SEPARATION:
		_fail("the two ships come within %.0f m of each other at %.1f h" % [closest, fmod(when, 1440.0) / 60.0])


## Where a ship is at game time t (seconds from midnight on day 0): it sails
## its loop at its speed and lies hove to over its wreck for stop_minutes from
## its stop hour every day. The ship builder moves the ships with this.
static func position(key: String, t: float) -> Vector2:
	var ship: Dictionary = PirateShipsPlan.SHIPS[key]
	var line: PackedVector2Array = ship["route"]
	var hour := PirateShipsPlan.GAME_SECONDS_PER_HOUR
	var day_length := 24.0 * hour
	var day := floorf(t / day_length)
	var tt := t - day * day_length
	var t0 := float(ship["stop_hour"]) * hour
	var stop := float(ship["stop_minutes"]) / 60.0 * hour
	var moving := t - day * stop - clampf(tt - t0, 0.0, stop)
	var lengths := PackedFloat32Array()
	var total := 0.0
	var to_stop := 0.0
	for i in line.size():
		var l := line[i].distance_to(line[(i + 1) % line.size()])
		if i < int(ship["stop_index"]):
			to_stop += l
		lengths.append(l)
		total += l
	var speed := float(ship["speed"])
	var s := fposmod(to_stop + speed * (moving - t0), total)
	var acc := 0.0
	for i in lengths.size():
		if acc + lengths[i] >= s:
			var f := (s - acc) / lengths[i] if lengths[i] > 0.0 else 0.0
			return line[i].lerp(line[(i + 1) % line.size()], f)
		acc += lengths[i]
	return line[0]
