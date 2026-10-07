class_name SnowBuildings
extends RefCounted

## Per-program dressing for the Snow Village's log houses: which openings each
## building gets, the covered gallery under a bellcast roof, lean-tos, the
## stabbur's stone piers. Interiors and hearths live in SnowInteriors and
## NordicHearth.
##
## Dormers are deliberately absent: every occupied floor here sits behind full
## height log walls and has real windows, and the attic above is unoccupied, so a
## dormer would be a lie (architecture skill, section 4).

const CELL := LogHouse.CELL
const STOREY := LogHouse.STOREY
const TIMBER := Color(0.30, 0.20, 0.13)
const DWELLING_KINDS := ["textile", "warden", "fisher", "forester", "inn", "inn_wing"]


static func openings_for(spec: Dictionary) -> Array[Dictionary]:
	var cells: Vector2 = spec["cells"]
	var floors := int(spec.get("floors", 1))
	var kind := str(spec["kind"])
	var width := cells.x * CELL
	var depth := cells.y * CELL
	var hearth: Dictionary = spec.get("hearth", {})
	var hearth_side := float(hearth.get("side", 0.0))
	var door_x := float(spec.get("door_x", 0.0))
	var shutters := DWELLING_KINDS.has(kind)
	var out: Array[Dictionary] = []
	if kind == "woodstore":
		return out
	# Front door.
	var wide := float(spec.get("wide_door", 0.0))
	var door_width := 1.2
	var door_top := LogHouse.DOOR_TOP
	var leaves := 1
	if kind == "inn" or kind == "rescue":
		door_width = 1.8
		leaves = 2
	if wide > 0.0:
		door_width = wide
		door_top = 2.78
		leaves = 2
	if kind == "naust":
		door_width = 3.2
		door_top = 2.78
		leaves = 2
	var has_front_door := kind != "inn_wing"
	if has_front_door:
		out.append({"wall": "front", "x": door_x, "width": door_width, "bottom": 0.0, "top": door_top, "kind": "door", "leaves": leaves})
	# Passage between the inn and its sleeping wing: matching doors in the two
	# walls that touch.
	if spec.has("passage_x"):
		var wall := "front" if kind == "inn_wing" else "back"
		out.append({"wall": wall, "x": float(spec["passage_x"]), "width": 1.2, "bottom": 0.0, "top": LogHouse.DOOR_TOP, "kind": "door", "leaves": 1})
	if spec.has("service_door"):
		var service: Dictionary = spec["service_door"]
		out.append({"wall": str(service["wall"]), "x": float(service["x"]), "width": 1.2, "bottom": 0.0, "top": LogHouse.DOOR_TOP, "kind": "door", "leaves": 1})
	for extra: Dictionary in spec.get("extra_openings", []):
		out.append(extra)
	if kind in ["icehouse", "smokehouse", "stabbur"]:
		return out
	# Windows: one per cell on the long walls (not beside a door), one per
	# storey on the ends (never on the hearth gable).
	var passage_x: Variant = spec.get("passage_x", null)
	for floor_index in floors:
		var base := float(floor_index) * STOREY
		var bottom := base + LogHouse.WINDOW_SILL
		var top := base + 2.1
		for i in int(cells.x):
			var x := (float(i) + 0.5) * CELL - width * 0.5
			if kind != "inn_wing" and floor_index == 0 and absf(x - door_x) < door_width * 0.5 + 1.1:
				continue
			if passage_x != null and absf(x - float(passage_x)) < 1.6:
				continue
			var service: Dictionary = spec.get("service_door", {})
			if str(service.get("wall", "")) == "front" and absf(x - float(service["x"])) < 1.7:
				continue
			var front_kind := "window"
			var front_width := LogHouse.WINDOW_W
			if kind == "inn" and floor_index == 0:
				front_kind = "wide"
				front_width = 1.5
			if kind == "textile" and floor_index == 0 and x < door_x:
				front_kind = "wide"
				front_width = 1.5
			# The wing's front wall touches the inn's back wall: no windows there.
			if kind != "inn_wing":
				out.append({"wall": "front", "x": x, "width": front_width, "bottom": bottom, "top": top, "kind": front_kind, "shutters": shutters and front_kind == "window"})
			# Likewise the inn's back wall faces the wing, and a boat house has no rear lights.
			if kind != "inn" and kind != "naust":
				out.append({"wall": "back", "x": x, "width": LogHouse.WINDOW_W, "bottom": bottom, "top": top, "kind": "window", "shutters": shutters})
		for side: float in [-1.0, 1.0]:
			if side == hearth_side:
				continue
			var wall := "west" if side < 0.0 else "east"
			var window_z := -1.2 if kind == "inn" else 0.0
			var service_gate: Dictionary = spec.get("service_door", {})
			if str(service_gate.get("wall", "")) == wall and floor_index == 0 and absf(window_z - float(service_gate["x"])) < 1.7:
				continue
			out.append({"wall": wall, "x": window_z, "width": LogHouse.WINDOW_W, "bottom": bottom, "top": top, "kind": "window", "shutters": shutters})
	if kind == "bathhouse":
		# Small high lights only: a steamed hot room does not need a view.
		out = out.filter(func(o: Dictionary) -> bool: return str(o["kind"]) == "door" or str(o["wall"]) != "back")
	return out


# ---------------------------------------------------------------------------
# Gallery
# ---------------------------------------------------------------------------

## A covered walkway on posts along the whole front wall, roofed by the long
## bellcast flare LogHouse builds when `gallery` is set. Posts stay clear of the
## door.
static func gallery(body: StaticBody3D, spec: Dictionary) -> void:
	var cells: Vector2 = spec["cells"]
	var width := cells.x * CELL
	var depth := cells.y * CELL
	var depth_out := float(spec["gallery"])
	var floors := int(spec.get("floors", 1))
	var pitch := deg_to_rad(float(spec.get("pitch_deg", 46.0)))
	var profile := LogHouse.roof_profile(width, depth, floors, pitch, true, depth_out)
	var tip := profile[profile.size() - 1]
	var post_z := -(depth * 0.5 + depth_out - 0.12)
	var post_top := tip.y + 0.12 * tan(deg_to_rad(15.0)) - LogHouse.ROOF_T - 0.12
	var door_x := float(spec.get("door_x", 0.0))
	var deck := SuperEgg.build_part(
		Vector3(width * 0.5 + 0.25, 0.08, depth_out * 0.5 + 0.05), TownProps.FLOOR_COLOR.darkened(0.15), SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT
	)
	deck.position = Vector3(0.0, 0.07, -(depth * 0.5 + depth_out * 0.5))
	body.add_child(deck)
	CollisionPolicy.add_box(body, deck, Vector3(width + 0.5, 0.16, depth_out + 0.1), deck.position, Basis(), true)
	var count := maxi(int(ceil((width - 0.6) / 3.2)), 2)
	for i in count + 1:
		var x := lerpf(-width * 0.5 + 0.35, width * 0.5 - 0.35, float(i) / float(count))
		if absf(x - door_x) < 1.35:
			x = door_x + (1.35 if x >= door_x else -1.35)
		var post := SuperEgg.build_part(Vector3(0.13, post_top * 0.5, 0.13), TIMBER, SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT)
		post.position = Vector3(x, post_top * 0.5, post_z)
		body.add_child(post)
		CollisionPolicy.add_box(body, post, Vector3(0.26, post_top, 0.26), post.position, Basis(), false)
		# A carved bracket from post to header.
		var bracket := SuperEgg.build_part(Vector3(0.05, 0.4, 0.045), TIMBER.lightened(0.05), SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT)
		bracket.position = Vector3(x + (0.32 if x < door_x else -0.32), post_top - 0.32, post_z)
		bracket.rotation.z = 0.8 if x < door_x else -0.8
		body.add_child(bracket)
		CollisionPolicy.mark_decorative(bracket)
	var beam := SuperEgg.build_part(Vector3(width * 0.5 + 0.2, 0.12, 0.13), TIMBER, SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT)
	beam.position = Vector3(0.0, post_top + 0.06, post_z)
	body.add_child(beam)
	CollisionPolicy.mark_decorative(beam)


# ---------------------------------------------------------------------------
# Lean-to, woodpile, piers
# ---------------------------------------------------------------------------

## An open timber lean-to against a gable end (`side` -1 west, +1 east).
static func lean_to(body: StaticBody3D, spec: Dictionary, side: float, depth_out: float) -> void:
	var cells: Vector2 = spec["cells"]
	var width := cells.x * CELL
	var depth := cells.y * CELL
	var angle := deg_to_rad(11.0)
	var wall_y := 2.95
	var centre_x := side * (width * 0.5 + depth_out * 0.5)
	var tilt := Basis(Vector3.BACK, -side * angle)
	var drop := depth_out * tan(angle)
	var roof := TownProps.roof_slab(Vector3(depth_out * 0.5 + 0.35, 0.07, depth * 0.5 + 0.3), LogHouse.ROOF_COLOR)
	var roof_centre := Vector3(centre_x, wall_y - drop * 0.5 + 0.1, 0.0)
	roof.transform = Transform3D(tilt, roof_centre)
	body.add_child(roof)
	CollisionPolicy.add_box(body, roof, Vector3(depth_out + 0.7, 0.14, depth + 0.6), roof_centre, tilt, true)
	var snow := SuperEgg.build_part(
		Vector3(depth_out * 0.5 + 0.28, 0.05, depth * 0.5 + 0.22), LogHouse.SNOW, 4.2, 4.2
	)
	snow.transform = Transform3D(tilt, roof_centre + tilt.y * 0.12)
	snow.set_meta(DesignAudit.ROOF_COVER_META, true)
	body.add_child(snow)
	CollisionPolicy.mark_decorative(snow)
	var outer_x := side * (width * 0.5 + depth_out)
	var post_h := wall_y - drop - 0.1
	for post_z: float in [-depth * 0.5 + 0.2, 0.0, depth * 0.5 - 0.2]:
		var post := SuperEgg.build_part(Vector3(0.12, post_h * 0.5, 0.12), TIMBER, SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT)
		post.position = Vector3(outer_x, post_h * 0.5, post_z)
		body.add_child(post)
		CollisionPolicy.add_box(body, post, Vector3(0.24, post_h, 0.24), post.position, Basis(), false)
	var beam := SuperEgg.build_part(Vector3(0.12, 0.11, depth * 0.5 + 0.2), TIMBER, SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT)
	beam.position = Vector3(outer_x, post_h + 0.05, 0.0)
	body.add_child(beam)
	CollisionPolicy.mark_decorative(beam)


## A stack of split logs lying along local X, `rows` high.
static func log_stack(parent: Node3D, at: Vector3, length: float, rows: int, yaw: float = 0.0) -> void:
	var holder := StaticBody3D.new()
	holder.collision_layer = 1
	holder.position = at
	holder.rotation.y = yaw
	parent.add_child(holder)
	var per_row := maxi(int(length / 0.3), 2)
	for row in rows:
		for i in per_row:
			var offset := 0.15 if row % 2 == 1 else 0.0
			var x := -length * 0.5 + 0.15 + float(i) * (length - 0.3) / float(per_row - 1) + offset * 0.0
			var log := SuperEgg.build_part(Vector3(0.16, 0.115, 0.5), Color(0.58, 0.40, 0.24).darkened(0.05 * float((i + row) % 3)), 3.4, 3.4)
			log.position = Vector3(x, 0.12 + float(row) * 0.225, 0.0)
			holder.add_child(log)
			CollisionPolicy.mark_decorative(log)
	var half := Vector3(length * 0.5, float(rows) * 0.225 * 0.5 + 0.05, 0.5)
	var solid := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = half * 2.0
	solid.shape = shape
	solid.position = Vector3(0.0, half.y, 0.0)
	holder.add_child(solid)


## Stone piers under a raised store, with a stepped stair at the door.
static func stabbur_piers(body: StaticBody3D, spec: Dictionary, lift: float) -> void:
	var cells: Vector2 = spec["cells"]
	var width := cells.x * CELL
	var depth := cells.y * CELL
	for sx: float in [-1.0, 0.0, 1.0]:
		for sz: float in [-1.0, 1.0]:
			var pier := SuperEgg.build_part(Vector3(0.28, lift * 0.5 + 0.05, 0.28), LogHouse.STONE, SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_SOFT)
			pier.position = Vector3(sx * (width * 0.5 - 0.4), lift * 0.5 - 0.02, sz * (depth * 0.5 - 0.4))
			body.add_child(pier)
			CollisionPolicy.add_box(body, pier, Vector3(0.56, lift + 0.1, 0.56), pier.position, Basis(), false)
			# A flat staddle stone on each pier keeps rodents from climbing.
			var cap := SuperEgg.build_part(Vector3(0.4, 0.05, 0.4), LogHouse.STONE.darkened(0.15), SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT)
			cap.position = Vector3(pier.position.x, lift - 0.04, pier.position.z)
			body.add_child(cap)
			CollisionPolicy.mark_decorative(cap)
	for step in 3:
		var tread := SuperEgg.build_part(Vector3(0.7, lift / 6.0, 0.28), TIMBER.lightened(0.1), SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT)
		var rise := lift * (float(step) + 0.5) / 3.0
		tread.position = Vector3(float(spec.get("door_x", 0.0)), rise * 0.5, -(depth * 0.5 + 0.35 + float(2 - step) * 0.55))
		tread.scale.y = 1.0
		body.add_child(tread)
		CollisionPolicy.add_box(body, tread, Vector3(1.4, rise, 0.56), tread.position, Basis(), true)


## The stave-style bell turret on the rescue hall's ridge, the charter's single
## accent: an open square frame with a hanging bell under a three-tier concave
## roof, each tier a little narrower, crowned with a finial.
static func bell_tower(body: StaticBody3D, spec: Dictionary) -> void:
	var cells: Vector2 = spec["cells"]
	var width := cells.x * CELL
	var depth := cells.y * CELL
	var floors := int(spec.get("floors", 1))
	var pitch := deg_to_rad(float(spec.get("pitch_deg", 46.0)))
	var ridge_y := LogHouse.roof_profile(width, depth, floors, pitch, false)[0].y
	var base := ridge_y - 0.1
	var half := 0.62
	var height := 1.9
	for sx: float in [-1.0, 1.0]:
		for sz: float in [-1.0, 1.0]:
			var post := SuperEgg.build_part(Vector3(0.08, height * 0.5, 0.08), TIMBER, SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT)
			post.position = Vector3(sx * half, base + height * 0.5, sz * half)
			body.add_child(post)
			CollisionPolicy.mark_decorative(post)
	for level: float in [0.15, height]:
		for axis in 2:
			for sign_value: float in [-1.0, 1.0]:
				var beam := SuperEgg.build_part(
					Vector3(half + 0.08 if axis == 0 else 0.06, 0.06, 0.06 if axis == 0 else half + 0.08), TIMBER,
					SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT
				)
				beam.position = Vector3(
					0.0 if axis == 0 else sign_value * half, base + level, sign_value * half if axis == 0 else 0.0
				)
				body.add_child(beam)
				CollisionPolicy.mark_decorative(beam)
	var bell := SuperEgg.build_part(Vector3(0.3, 0.34, 0.3), Color(0.74, 0.58, 0.24), 2.0, 2.2)
	bell.position = Vector3(0.0, base + height - 0.6, 0.0)
	body.add_child(bell)
	CollisionPolicy.mark_decorative(bell)
	var clapper := SuperEgg.build_part(Vector3(0.05, 0.05, 0.05), TIMBER.darkened(0.3), 2.0, 2.0)
	clapper.position = Vector3(0.0, base + height - 0.98, 0.0)
	body.add_child(clapper)
	CollisionPolicy.mark_decorative(clapper)
	# Three concave tiers, snow on each.
	var tiers: Array[Vector3] = [Vector3(1.0, 0.0, 0.07), Vector3(0.78, 0.38, 0.06), Vector3(0.52, 0.74, 0.05)]
	for tier in tiers:
		var slab := SuperEgg.build_part(Vector3(tier.x, tier.z, tier.x), LogHouse.ROOF_COLOR, 3.6, 3.6)
		slab.position = Vector3(0.0, base + height + 0.08 + tier.y, 0.0)
		slab.rotation.y = PI * 0.25 * tier.y
		body.add_child(slab)
		CollisionPolicy.mark_decorative(slab)
		var snow := SuperEgg.build_part(Vector3(tier.x * 0.82, 0.03, tier.x * 0.82), LogHouse.SNOW, 3.6, 3.6)
		snow.position = Vector3(0.0, base + height + 0.08 + tier.y + tier.z + 0.03, 0.0)
		snow.rotation.y = PI * 0.25 * tier.y
		body.add_child(snow)
		CollisionPolicy.mark_decorative(snow)
	var finial := SuperEgg.build_part(Vector3(0.05, 0.32, 0.05), TIMBER, 2.2, 2.2)
	finial.position = Vector3(0.0, base + height + 1.35, 0.0)
	body.add_child(finial)
	CollisionPolicy.mark_decorative(finial)
