@tool
extends RefCounted
class_name MoyCityBakeBuilder

## Offline-only geometry authoring helper. The live city loads the saved packs;
## it never calls this builder or creates massing at Crossroads startup.
const PLAN := preload("res://scripts/city_plan.gd")
const TERRAIN_SCRIPT := preload("res://scripts/terrain_generator.gd")
const DATUM := -60.0
const CELL := 64.0
static var _soft_block_unit: ArrayMesh

static func build_packs() -> Dictionary:
	var packs := {}
	var tree_templates: Dictionary={}
	for s in PLAN.STREETS:
		var r: Rect2 = s.rect
		var body := _box_body("Street_%s" % s.name, Vector3(r.size.x, 0.16, r.size.y), Vector3(r.position.x + r.size.x * 0.5, DATUM - 0.05, r.position.y + r.size.y * 0.5), Color("#9c8970"))
		_add(packs, _cell(Vector2(r.get_center().x, r.get_center().y)), body)
	for o in PLAN.OPENS:
		var r: Rect2 = o.rect
		var body := _park_ground_body(r) if String(o.name) == "park" else _box_body("Open_%s" % o.name, Vector3(r.size.x, 0.18, r.size.y), Vector3(r.position.x + r.size.x * 0.5, DATUM - 0.02, r.position.y + r.size.y * 0.5), Color("#b9a586"))
		_add(packs, _cell(r.get_center()), body)
	for i in PLAN.OLD_TOWN.lanes.size():
		var lane: Dictionary = PLAN.OLD_TOWN.lanes[i]
		for j in lane.pts.size() - 1:
			var a: Array = lane.pts[j]
			var b: Array = lane.pts[j + 1]
			var p := Vector2(a[0], a[1]); var q := Vector2(b[0], b[1])
			var body := _segment_body("OldLane_%d_%d" % [i, j], p, q, float(lane.w), DATUM - 0.01, 0.08, Color("#947b61"))
			_add(packs, _cell((p + q) * 0.5), body)
	for square in PLAN.OLD_TOWN.squares:
		var pts: Array = square.pts
		var center := Vector2.ZERO
		for v in pts: center += Vector2(v[0], v[1])
		center /= float(pts.size())
		var body := _poly_floor("OldSquare_%s" % square.name, pts, DATUM + 0.03, Color("#c6b38f"))
		_add(packs, _cell(center), body)
	for i in PLAN.LOTS.size():
		var lot: Array = PLAN.LOTS[i]
		var r: Rect2 = lot[0]
		var kit: Dictionary = PLAN.LOT_KITS[i] if i < PLAN.LOT_KITS.size() and PLAN.LOT_KITS[i] is Dictionary else {}
		if String(kit.get("kit", "")) in ["tong_lau", "lockup", "infill"]:
			var market_body := _market_house(i, r, kit)
			if String(kit.get("kit", "")) == "infill":
				market_body.name = "Lot_%03d" % i
				market_body.set_meta("moy_p4_house", true)
			_add(packs, _cell(r.get_center()), market_body)
			continue
		if String(kit.get("kit", "")) == "tower": continue # Authored below by the P4 tower-house kit.
		var h := float(lot[1]) * float(PLAN.STOREY[lot[2]])
		var color := _lot_color(i, String(lot[2]))
		var body := _box_body("Lot_%03d" % i, Vector3(r.size.x, h, r.size.y), Vector3(r.get_center().x, DATUM + h * 0.5, r.get_center().y), color)
		_add_roof(body, r.size, h, color.lightened(0.15))
		_add(packs, _cell(r.get_center()), body)
	_add_market_streets(packs)
	for i in PLAN.OLD_HOUSES.size():
		var house: Dictionary = PLAN.OLD_HOUSES[i]
		var body := _old_moy_house("OldHouse_%02d" % i, house.corners, house.storeys, house.kit, int(house.get("front_edge", -1)), i)
		_add(packs, _cell(_polygon_center(house.corners)), body)
	for i in PLAN.LOTS.size():
		var lot: Array = PLAN.LOTS[i]
		var kit: Dictionary = PLAN.LOT_KITS[i] if i < PLAN.LOT_KITS.size() and PLAN.LOT_KITS[i] is Dictionary else {}
		if String(kit.get("kit", "")) == "tower":
			var rect: Rect2 = lot[0]
			var corners := [[rect.position.x, rect.position.y], [rect.end.x, rect.position.y], [rect.end.x, rect.end.y], [rect.position.x, rect.end.y]]
			var body := _old_moy_house("Lot_%03d" % i, corners, int(kit.get("storeys", lot[1])), kit, _front_edge_for_rect(String(kit.get("front", "s"))), 60 + i)
			_add(packs, _cell(rect.get_center()), body)
	_add_old_moy_shared_spaces(packs)
	for b in PLAN.BUILDINGS:
		if b.rect == null or int(b.n) in [11, 38]:
			continue
		if int(b.n) == 34:
			var flat_kit: Dictionary = PLAN.BUILDING_KITS.get(34, {}).duplicate(true)
			var flats := _market_house(34, b.rect, flat_kit)
			flats.name = "Market_Flats_Terrace_34"
			_add(packs, _cell(b.rect.get_center()), flats)
			continue
		var tower_kit: Dictionary = PLAN.BUILDING_KITS.get(int(b.n), {})
		if not tower_kit.is_empty() and String(tower_kit.get("kit", "")) == "tower":
			var r: Rect2 = b.rect
			var corners := [[r.position.x, r.position.y], [r.end.x, r.position.y], [r.end.x, r.end.y], [r.position.x, r.end.y]]
			var tower_label := "Building_%02d_%s" % [int(b.n), String(b.name).replace(" ", "_")]
			var tower := _old_moy_house(tower_label, corners, int(tower_kit.get("storeys", 6)), tower_kit, _front_edge_for_rect(String(tower_kit.get("front", "s"))), 90 + int(b.n))
			_add(packs, _cell(r.get_center()), tower)
			continue
		if int(b.n) == 13:
			var block := _block_tower_exterior()
			_add(packs, _cell(b.rect.get_center()), block)
			continue
		var body := _landmark(b)
		_add(packs, _cell(b.rect.get_center()), body)
		if int(b.n) == 1:
			var hotel_pack := Node3D.new()
			hotel_pack.name = "HotelPublicInteriorPack"
			hotel_pack.position = Vector3(b.rect.get_center().x, DATUM, b.rect.get_center().y)
			_add_hotel_public_interior(hotel_pack, PLAN.HOTEL)
			packs["hotel_interior"] = hotel_pack
	_add_deck(packs,tree_templates)
	_add_wall(packs)
	_add_park(packs,tree_templates)
	_add_estate_links(packs)
	_add_transit(packs)
	_add_gate_forms(packs)
	_add_civic_square(packs,tree_templates)
	_add_arch_front(packs)
	_add_city_dome(packs)
	_add_turbines(packs)
	for template in tree_templates.values(): (template as StaticBody3D).free()
	return packs


## P17's tower is a real climbable landmark rather than the generic massing
## box used by the surrounding skyline. Coordinates are derived from the
## locked plan; the facade, vent ledges, rail brackets and east balconies all
## carry collision because they read as physical structure.
static func _block_tower_exterior() -> StaticBody3D:
	var site: Dictionary = PLAN.TOWER_SITE["13"]
	var shaft: Array = site.shaft
	var left := float(shaft[0]); var front := float(shaft[1])
	var right := float(shaft[2]); var back := float(shaft[3])
	var center := Vector2((left + right) * 0.5, (front + back) * 0.5)
	var width := right - left; var depth := back - front
	var cfg: Dictionary = PLAN.BLOCK_TOWER
	var root := StaticBody3D.new()
	root.name = "Building_13_BLOCK_tower"
	root.collision_layer = 1; root.collision_mask = 1
	root.position = Vector3(center.x, DATUM, center.y)
	var dark := Color("#171b27"); var ceramic := Color("#252b3a")
	var azure := Color("#50bfff")
	# The broad base is set back four metres from the tower site boundary. Its
	# north wall keeps the single doorway opening; the leaf itself cannot open
	# until the lobby's post-fight control releases it.
	var base_w := width + 8.0; var base_d := depth + 8.0; var base_t := 1.2
	_add_building_box_part(root, Vector3(base_t, 9.0, base_d), Vector3(-base_w * 0.5 + base_t * 0.5, 4.5, 0), Color("#30323a"))
	_add_building_box_part(root, Vector3(base_t, 9.0, base_d), Vector3(base_w * 0.5 - base_t * 0.5, 4.5, 0), Color("#30323a"))
	_add_building_box_part(root, Vector3(base_w - base_t * 2.0, 9.0, base_t), Vector3(0, 4.5, base_d * 0.5 - base_t * 0.5), Color("#30323a"))
	var door_x := float(cfg.door[0]) - center.x
	var door_w := 2.2; var door_h := 3.0; var door_wall_z := -base_d * 0.5 + base_t * 0.5
	var door_left := -base_w * 0.5 + base_t; var door_right := base_w * 0.5 - base_t
	_add_building_box_part(root, Vector3(door_x - door_left - door_w * 0.5, 9.0, base_t), Vector3((door_left + door_x - door_w * 0.5) * 0.5, 4.5, door_wall_z), Color("#30323a"))
	_add_building_box_part(root, Vector3(door_right - door_x - door_w * 0.5, 9.0, base_t), Vector3((door_x + door_w * 0.5 + door_right) * 0.5, 4.5, door_wall_z), Color("#30323a"))
	_add_building_box_part(root, Vector3(door_w, 9.0 - door_h, base_t), Vector3(door_x, door_h + (9.0 - door_h) * 0.5, door_wall_z), Color("#30323a"))
	var door := StaticBody3D.new(); door.name = "BLOCK_Forecourt_Door"
	var door_script := load("res://scripts/moy_block_tower_door.gd")
	if door_script != null: door.set_script(door_script)
	var door_shape := BoxShape3D.new(); door_shape.size = Vector3(door_w, door_h, 0.32)
	var door_collision := CollisionShape3D.new(); door_collision.shape = door_shape; door_collision.position = Vector3(door_x, door_h * 0.5, -base_d * 0.5 + base_t)
	door.add_child(door_collision)
	var door_mesh := BoxMesh.new(); door_mesh.size = door_shape.size
	var door_visual := MeshInstance3D.new(); door_visual.mesh = door_mesh; door_visual.position = door_collision.position; door_visual.material_override = _material(Color("#090b10")); door.add_child(door_visual)
	root.add_child(door)
	# The shaft begins at the plinth roof and is split around its only open
	# louvre. The unbuilt storeys behind it remain solid wall thickness.
	var wall_t := 1.1; var shaft_bottom := 9.0; var shaft_h := 150.0 - shaft_bottom
	_add_building_box_part(root, Vector3(wall_t, shaft_h, depth), Vector3(-width * 0.5 + wall_t * 0.5, shaft_bottom + shaft_h * 0.5, 0), dark)
	_add_building_box_part(root, Vector3(wall_t, shaft_h, depth), Vector3(width * 0.5 - wall_t * 0.5, shaft_bottom + shaft_h * 0.5, 0), dark)
	_add_building_box_part(root, Vector3(width - wall_t * 2.0, shaft_h, wall_t), Vector3(0, shaft_bottom + shaft_h * 0.5, depth * 0.5 - wall_t * 0.5), dark)
	# North shaft wall includes a second-floor opening aligned with the only door.
	_add_building_box_part(root, Vector3(door_x - door_w * 0.5 + width * 0.5, shaft_h, wall_t), Vector3((-width * 0.5 + door_x - door_w * 0.5) * 0.5, shaft_bottom + shaft_h * 0.5, -depth * 0.5 + wall_t * 0.5), dark)
	_add_building_box_part(root, Vector3(width * 0.5 - door_x - door_w * 0.5, shaft_h, wall_t), Vector3((door_x + door_w * 0.5 + width * 0.5) * 0.5, shaft_bottom + shaft_h * 0.5, -depth * 0.5 + wall_t * 0.5), dark)
	_add_building_box_part(root, Vector3(door_w, shaft_h - door_h, wall_t), Vector3(door_x, shaft_bottom + door_h + (shaft_h - door_h) * 0.5, -depth * 0.5 + wall_t * 0.5), dark)
	# East face louvre opening at the 55% ring, two metres across and centred
	# on the authored entrance approach.
	var louvre_bottom := 81.7; var louvre_top := 83.3; var louvre_gap := 2.4
	_add_building_box_part(root, Vector3(wall_t, louvre_bottom - shaft_bottom, depth), Vector3(width * 0.5 - wall_t * 0.5, (shaft_bottom + louvre_bottom) * 0.5, 0), dark)
	_add_building_box_part(root, Vector3(wall_t, 150.0 - louvre_top, depth), Vector3(width * 0.5 - wall_t * 0.5, (150.0 + louvre_top) * 0.5, 0), dark)
	_add_building_box_part(root, Vector3(wall_t, louvre_top - louvre_bottom, (depth - louvre_gap) * 0.5), Vector3(width * 0.5 - wall_t * 0.5, (louvre_top + louvre_bottom) * 0.5, -(depth + louvre_gap) * 0.25), dark)
	_add_building_box_part(root, Vector3(wall_t, louvre_top - louvre_bottom, (depth - louvre_gap) * 0.5), Vector3(width * 0.5 - wall_t * 0.5, (louvre_top + louvre_bottom) * 0.5, (depth + louvre_gap) * 0.25), dark)
	# Dark hairline joints repeat on a four-metre course. They are visual inlays,
	# not openings or collision seams.
	for y in range(6, 150, 4):
		for z_side in [-1.0, 1.0]:
			var seam := MeshInstance3D.new(); var mesh := BoxMesh.new(); mesh.size = Vector3(width - 0.5, 0.035, 0.025)
			seam.mesh = mesh; seam.position = Vector3(0, float(y), z_side * (depth * 0.5 + 0.013)); seam.material_override = _material(ceramic.darkened(0.35)); root.add_child(seam)
		for x_side in [-1.0, 1.0]:
			var seam := MeshInstance3D.new(); var mesh := BoxMesh.new(); mesh.size = Vector3(0.025, 0.035, depth - 0.5)
			seam.mesh = mesh; seam.position = Vector3(x_side * (width * 0.5 + 0.013), float(y), 0); seam.material_override = _material(ceramic.darkened(0.35)); root.add_child(seam)
	# Solid continuous vent hoods; their upper ledges remain walkable. The 55%
	# ring leaves one opening on the east face for the warm-lit louvre.
	var vent_size: Array = cfg.vent
	var projection := float(vent_size[0]); var hood_height := float(vent_size[1])
	var z_len := depth + projection * 2.0
	for ring_i in cfg.vents.size():
		var y := float(cfg.vents[ring_i]) * 150.0
		var top := y
		var mid_y := top - hood_height * 0.5
		for side in [-1.0, 1.0]:
			# East face is +X. Split its middle ring around the entry louvre.
			if side > 0.0 and ring_i == 1:
				var gap := 2.8
				for z_sign in [-1.0, 1.0]:
					var seg_len := (z_len - gap) * 0.5
					var seg_z: float = z_sign * (gap * 0.5 + seg_len * 0.5)
					_add_building_box_part(root, Vector3(projection, hood_height, seg_len), Vector3(width * 0.5 + projection * 0.5, mid_y, seg_z), ceramic)
			else:
				_add_building_box_part(root, Vector3(projection, hood_height, z_len), Vector3(side * (width * 0.5 + projection * 0.5), mid_y, 0), ceramic)
			_add_building_box_part(root, Vector3(width, hood_height, projection), Vector3(0, mid_y, side * (depth * 0.5 + projection * 0.5)), ceramic)
		# A dark lip emphasizes the ledge edge and reads as the hood's drip line.
		for side in [-1.0, 1.0]:
			_add_building_box_part(root, Vector3(0.16, 0.10, z_len), Vector3(side * (width * 0.5 + projection - 0.08), top - 0.05, 0), Color("#10131b"))
	# A slim maintenance rail on the east face joins the 30% and 55% ledges.
	for y_step in range(0, 16):
		var y := 45.0 + float(y_step) * 2.5
		var bracket := _box_body("BLOCK_Rail_Bracket_%02d" % y_step, Vector3(1.15, 0.20, 0.72), Vector3(width * 0.5 + 0.38, y, 0), Color("#414752"))
		bracket.collision_layer = 1; root.add_child(bracket)
	# The open louvre is deliberately the only warm element on the facade.
	var louvre := MeshInstance3D.new(); louvre.name = "BLOCK_Open_Louvre"
	var louvre_mesh := BoxMesh.new(); louvre_mesh.size = Vector3(0.10, 1.6, 2.4); louvre.mesh = louvre_mesh
	var warm := StandardMaterial3D.new(); warm.albedo_color = Color("#ffbd70"); warm.emission_enabled = true; warm.emission = Color("#e98e42"); warm.emission_energy_multiplier = 1.8
	louvre.material_override = warm; louvre.position = Vector3(width * 0.5 + 0.02, 82.5, 0); root.add_child(louvre)
	# Crown panels fold in to a canted ridge; convex faces block escape and the
	# raised ribs give the arena approach a small set of parkour landings.
	var crown_top := float(cfg.crown.top); var crown_h := crown_top - 150.0
	for side in [-1.0, 1.0]:
		var panel := _block_panel(Vector3(side * width * 0.5, 150.0, 0), Vector3(side * 5.0, crown_top, 4.0), depth, dark.lightened(0.06))
		root.add_child(panel)
	for side in [-1.0, 1.0]:
		var panel := _block_panel(Vector3(0, 150.0, side * depth * 0.5), Vector3(0, crown_top - 12.0, side * 4.0), width, dark.lightened(0.03))
		root.add_child(panel)
	# The plaza-facing slit is the crown's only light.
	var eye := MeshInstance3D.new(); eye.name = "BLOCK_Crown_Eye"
	var eye_mesh := BoxMesh.new(); eye_mesh.size = Vector3(1.2, 24.0, 0.08); eye.mesh = eye_mesh
	var eye_material := StandardMaterial3D.new(); eye_material.albedo_color = azure; eye_material.emission_enabled = true; eye_material.emission = azure; eye_material.emission_energy_multiplier = 2.6
	eye.material_override = eye_material; eye.position = Vector3(0, 180.0, -depth * 0.5 - 0.06); root.add_child(eye)
	# East-neighbour balconies, every second storey to the 30% hood.
	var approach: Dictionary = cfg.inside.approach
	var neighbour: Array = approach.rect
	var nx0 := float(neighbour[0]); var nx1 := float(neighbour[2]); var nz := (float(neighbour[1]) + float(neighbour[3])) * 0.5
	var storey_height := 150.0 / float(cfg.inside.floors)
	for level in range(2, 11, 2):
		var y := float(level) * storey_height
		var balcony := _box_body("BLOCK_Approach_Balcony_%02d" % level, Vector3(2.0, 0.28, 3.4), Vector3(nx0 - 0.85, y, nz), Color("#353944"))
		root.add_child(balcony)
	return root


## P3 street kit. The plan owns each footprint, orientation and variant; these
## reusable builders only turn those records into shared, baked geometry.
static func _market_house(index: int, rect: Rect2, kit: Dictionary) -> StaticBody3D:
	var root := StaticBody3D.new()
	root.name = "MarketHouse_%03d" % index
	root.set_meta("market_lot", index)
	root.position = Vector3(rect.get_center().x, DATUM, rect.get_center().y)
	var front := String(kit.get("front", "s"))
	var along_x := front in ["n", "s"]
	var width := rect.size.x if along_x else rect.size.y
	var depth := rect.size.y if along_x else rect.size.x
	var storeys := int(kit.get("storeys", 2))
	var lockup := String(kit.get("kit", "")) == "lockup"
	var cfg: Dictionary = PLAN.MARKET_HOUSE
	var height := float(storeys) * float(cfg.storey)
	var palette := [Color("#438d83"), Color("#b9955c"), Color("#b66e62"), Color("#7898ad"), Color("#d2c4a7")]
	var colour: Color = palette[int(kit.get("colour", 0)) % palette.size()]
	# The continuous shell is the blocking house volume. The door leaf remains
	# closed at the plan's threshold; the facade layers use the same palette.
	var passage_lot := index == 34 or index == 71
	if passage_lot:
		var opening := float(cfg.passage.w)
		var side_span := maxf(0.0, width - opening) * 0.5
		if along_x:
			for side in [-1.0, 1.0]:
				_add_building_box_part(root, Vector3(side_span, float(cfg.storey), rect.size.y), Vector3(side * (opening * 0.5 + side_span * 0.5), float(cfg.storey) * 0.5, 0), colour)
			_add_building_box_part(root, Vector3(opening, float(cfg.storey) - float(cfg.passage.h), rect.size.y), Vector3(0, (float(cfg.storey) + float(cfg.passage.h)) * 0.5, 0), colour)
		else:
			for side in [-1.0, 1.0]:
				_add_building_box_part(root, Vector3(rect.size.x, float(cfg.storey), side_span), Vector3(0, float(cfg.storey) * 0.5, side * (opening * 0.5 + side_span * 0.5)), colour)
			_add_building_box_part(root, Vector3(rect.size.x, float(cfg.storey) - float(cfg.passage.h), opening), Vector3(0, (float(cfg.storey) + float(cfg.passage.h)) * 0.5, 0), colour)
		_add_building_box_part(root, Vector3(rect.size.x, height - float(cfg.storey), rect.size.y), Vector3(0, height * 0.5 + float(cfg.storey) * 0.5, 0), colour)
		# Keep the passage open through the foundation as well as the wall; the
		# threshold is the lane's ground plane and remains collision clear.
		var plinth_side := maxf(0.0, width - opening) * 0.5
		var passage_tangent := Vector3.RIGHT if along_x else Vector3.FORWARD
		for side in [-1.0, 1.0]:
			var plinth_size := _market_face_size(plinth_side, float(cfg.plinth), depth, along_x)
			var plinth_offset: Vector3 = passage_tangent * side * (opening * 0.5 + plinth_side * 0.5)
			_add_building_box_part(root, plinth_size, plinth_offset + Vector3.UP * (float(cfg.plinth) * 0.5), Color("#77766f"))
	else:
		_add_building_box_part(root, Vector3(rect.size.x, height, rect.size.y), Vector3(0, height * 0.5, 0), colour)
		_add_building_box_part(root, Vector3(rect.size.x + 0.12, float(cfg.plinth), rect.size.y + 0.12), Vector3(0, float(cfg.plinth) * 0.5, 0), Color("#77766f"))
	var outward := Vector3(0, 0, 1) if front == "s" else (Vector3(0, 0, -1) if front == "n" else (Vector3(1, 0, 0) if front == "e" else Vector3(-1, 0, 0)))
	var tangent := Vector3.RIGHT if along_x else Vector3.FORWARD
	var facade_depth := depth * 0.5 + 0.045
	var ground_y := 0.0
	if lockup:
		_add_building_box_part(root, _market_face_size(width * 0.98, 2.8, 0.07, along_x), outward * facade_depth + Vector3.UP * 1.4, Color("#555a5d"))
		for slat_y in range(12):
			var y := 0.2 + float(slat_y) * 0.22
			_add_market_visual_box(root, _market_face_size(width * 0.96, 0.035, 0.035, along_x), outward * (facade_depth + 0.05) + Vector3.UP * y, Color("#85898a"))
		_add_building_box_part(root, _market_face_size(width * 0.28, 0.8, 0.06, along_x), outward * facade_depth + Vector3.UP * 3.25, Color("#29343a"))
		_add_market_visual_box(root, _market_face_size(width * 0.31, 0.06, 0.05, along_x), outward * (facade_depth + 0.05) + Vector3.UP * 3.25, Color("#d2c4a7"))
	else:
		var floor_count := storeys
		for floor_i in range(1, floor_count):
			var y := float(floor_i) * float(cfg.storey)
			var is_veranda := bool(kit.get("veranda", false)) and String(kit.get("gen", "")) == "boom"
			var tile := String(kit.get("gen", "")) == "tile"
			var projection := float(cfg.boom.veranda.out) if is_veranda else (float(cfg.tile.balcony.d) if tile else float(cfg.boom.balcony.d))
			var first_tile_floor := tile and floor_i == 1
			if first_tile_floor:
				projection = float(cfg.tile.canopy.d)
				_add_building_box_part(root, _market_face_size(width * 0.96, float(cfg.tile.canopy.t), projection, along_x), outward * (depth * 0.5 + projection * 0.5) + Vector3.UP * float(cfg.tile.canopy.y), Color("#b9ad98"))
			elif floor_i >= (int(cfg.tile.balcony.first) if tile else 1):
				_add_building_box_part(root, _market_face_size(width * 0.91, 0.18, projection, along_x), outward * (depth * 0.5 + projection * 0.5) + Vector3.UP * (y + 0.08), Color("#b9ad98"))
			if is_veranda:
				for side in [-1.0, 1.0]:
					_add_building_box_part(root, _market_face_size(0.5, float(cfg.storey), 0.5, along_x), tangent * side * width * 0.44 + outward * (depth * 0.5 + projection - 0.25) + Vector3.UP * (y + float(cfg.storey) * 0.5), colour.lightened(0.2))
			if is_veranda:
				var rail_y := y + float(cfg.boom.veranda.rail)
				_add_building_box_part(root, _market_face_size(width * 0.84, 0.08, 0.08, along_x), outward * (depth * 0.5 + projection - 0.08) + Vector3.UP * rail_y, Color("#6f4f37"))
				for baluster_index in range(1, 10):
					var bx := -width * 0.4 + width * 0.8 * float(baluster_index) / 10.0
					_add_building_box_part(root, _market_face_size(0.06, maxf(0.1, rail_y - y - 0.18), 0.06, along_x), tangent * bx + outward * (depth * 0.5 + projection - 0.08) + Vector3.UP * (y + (rail_y - y) * 0.5), Color("#76573f"))
			elif floor_i >= (int(cfg.tile.balcony.first) if tile else 1):
				var rail_y := y + float(cfg.tile.balcony.rail if tile else cfg.boom.balcony.rail)
				_add_building_box_part(root, _market_face_size(width * 0.86, 0.06, 0.06, along_x), outward * (depth * 0.5 + projection - 0.04) + Vector3.UP * rail_y, Color("#39464b"))
				for rail_index in range(1, 7):
					var bx := -width * 0.4 + width * 0.8 * float(rail_index) / 7.0
					_add_building_box_part(root, _market_face_size(0.04, maxf(0.1, rail_y - y - 0.18), 0.04, along_x), tangent * bx + outward * (depth * 0.5 + projection - 0.04) + Vector3.UP * (y + (rail_y - y) * 0.5), Color("#39464b"))
			var window_y := y + (float(cfg.tile.window.sill) + float(cfg.tile.window.h) * 0.5 if tile else 1.32)
			var window_w := float(cfg.tile.window.w) if tile else float(cfg.boom.window.w)
			var window_h := float(cfg.tile.window.h) if tile else float(cfg.boom.window.h)
			_add_building_box_part(root, _market_face_size(window_w, window_h, 0.08, along_x), outward * facade_depth + Vector3.UP * window_y, Color("#31434a"))
			var window_trim := Color("#ddd1ba") if tile else Color("#e5d8bf")
			var frame_front := outward * (facade_depth + 0.045)
			for side in [-1.0, 1.0]:
				_add_market_visual_box(root, _market_face_size(0.07, window_h + 0.12, 0.05, along_x), tangent * side * (window_w * 0.5 + 0.035) + frame_front + Vector3.UP * window_y, window_trim)
			_add_market_visual_box(root, _market_face_size(window_w + 0.12, 0.07, 0.05, along_x), frame_front + Vector3.UP * (window_y - window_h * 0.5 - 0.035), window_trim)
			_add_market_visual_box(root, _market_face_size(window_w + 0.12, 0.07, 0.05, along_x), frame_front + Vector3.UP * (window_y + window_h * 0.5 + 0.035), window_trim)
			if not tile:
				for side in [-1.0, 1.0]:
					_add_building_box_part(root, _market_face_size(float(cfg.boom.shutter), 2.65, 0.05, along_x), tangent * side * (window_w * 0.5 + float(cfg.boom.shutter) * 0.5) + outward * (facade_depth + 0.03) + Vector3.UP * window_y, Color("#72583f"))
		# Shopfront canopy, picture sign frames and a simple closed street door.
		if String(kit.get("gen", "")) == "tile":
			_add_building_box_part(root, _market_face_size(width * 0.94, 0.2, float(cfg.tile.canopy.d), along_x), outward * (depth * 0.5 + float(cfg.tile.canopy.d) * 0.5) + Vector3.UP * float(cfg.tile.canopy.y), Color("#b9ad98"))
		elif passage_lot:
			var frontage_side := maxf(0.0, width - float(cfg.passage.w)) * 0.5
			for side in [-1.0, 1.0]:
				var side_shop := _market_face_size(frontage_side, 2.1, 0.08, along_x)
				var side_center: Vector3 = tangent * side * (float(cfg.passage.w) * 0.5 + frontage_side * 0.5)
				_add_building_box_part(root, side_shop, side_center + outward * facade_depth + Vector3.UP * 1.4, Color("#343e40"))
		else:
			_add_building_box_part(root, _market_face_size(width * 0.7, 2.1, 0.08, along_x), outward * facade_depth + Vector3.UP * 1.4, Color("#343e40"))
		var door_data: Variant = kit.get("door")
		if door_data is Array and door_data.size() >= 2:
			var door_pos := Vector2(float(door_data[0]), float(door_data[1])) - rect.get_center()
			var local := Vector3(door_pos.x, 1.2, door_pos.y)
			_add_building_box_part(root, _market_face_size(1.16, 2.35, 0.09, along_x), local + outward * (depth * 0.5 + 0.06), Color("#45372e"))
			var door_face := local + outward * (depth * 0.5 + 0.12)
			for side in [-1.0, 1.0]:
				_add_market_visual_box(root, _market_face_size(0.12, 2.55, 0.06, along_x), door_face + tangent * side * 0.66 + Vector3.UP * 0.05, Color("#77756d"))
			_add_market_visual_box(root, _market_face_size(1.42, 0.12, 0.06, along_x), door_face + Vector3.UP * 1.32, Color("#77756d"))
			_add_market_visual_box(root, _market_face_size(1.2, 0.4, 0.05, along_x), door_face + Vector3.UP * 2.62, Color(0.67, 0.82, 0.84, 0.72))
			_add_market_visual_box(root, _market_face_size(1.25, 0.04, 0.06, along_x), door_face + Vector3.UP * 2.43, Color("#77756d"))
			var target := Node3D.new(); target.name = "MarketDoor_%03d" % index
			target.position = Vector3(door_pos.x, 0.1, door_pos.y) + outward * (depth * 0.5 + 0.35)
			target.set_meta("reach_target", true); root.add_child(target)
			# A shallow, glazed picture window and trade shelves dress the
			# shopfront on the span left beside the closed house door.
			var door_tangent := door_pos.x if along_x else -door_pos.y
			for shop_side in [-1.0, 1.0]:
				var shop_start := -width * 0.5 if shop_side < 0.0 else door_tangent + 0.6
				var shop_end := door_tangent - 0.6 if shop_side < 0.0 else width * 0.5
				var shop_span := shop_end - shop_start
				if shop_span <= 0.7: continue
				var shop_center := (shop_start + shop_end) * 0.5
				var glass_center := tangent * shop_center + outward * (depth * 0.5 + 0.1)
				_add_market_visual_box(root, _market_face_size(shop_span, 1.9, 0.06, along_x), glass_center + Vector3.UP * 1.55, Color(0.24, 0.46, 0.49, 0.72))
				_add_market_visual_box(root, _market_face_size(shop_span, 0.24, 0.14, along_x), glass_center + Vector3.UP * 0.37, Color("#467b77"))
				var shelf_z := depth * 0.5 - minf(float(cfg.shop.depth), depth * 0.45)
				_add_market_visual_box(root, _market_face_size(shop_span * 0.82, 0.08, 0.24, along_x), tangent * shop_center + Vector3(0, 1.1, 0) + outward * shelf_z, Color("#624a36"))
				for goods_i in range(3):
					var gx := shop_center - shop_span * 0.28 + float(goods_i) * shop_span * 0.28
					_add_market_egg(root, _market_face_size(0.16, 0.2, 0.14, along_x), tangent * gx + outward * shelf_z + Vector3.UP * 1.34, [Color("#d5a055"), Color("#bf6459"), Color("#729a87")][goods_i])
		for sign_i in int(kit.get("signs", 0)):
			var sign_y := float(cfg.sign.y) + float(sign_i) * (float(cfg.sign.h) + float(cfg.sign.gap))
			var sign_center := outward * (depth * 0.5 + 0.12) + Vector3.UP * sign_y
			_add_building_box_part(root, _market_face_size(0.9, 0.7, 0.12, along_x), sign_center, Color("#d29b55"))
			_add_market_egg(root, _market_face_size(0.32, 0.25, 0.035, along_x), sign_center + outward * 0.08, [Color("#c95c54"), Color("#478c86"), Color("#d7c166")][sign_i % 3])
		if bool(kit.get("blade", false)):
			_add_building_box_part(root, Vector3(0.06, 0.06, float(cfg.sign.out)), outward * (depth * 0.5 + float(cfg.sign.out) * 0.5) + Vector3.UP * (float(cfg.sign.y) + 0.8), Color("#596970"))
			_add_building_box_part(root, _market_face_size(0.12, 1.1, 0.6, along_x), outward * (depth * 0.5 + float(cfg.sign.out)) + Vector3.UP * (float(cfg.sign.y) + 0.25), Color("#d29b55"))
	# Flat roof and parapet cap, with the plan-selected roof cue.
	_add_building_box_part(root, Vector3(rect.size.x + 0.15, 0.2, rect.size.y + 0.15), Vector3(0, height + 0.1, 0), Color("#8c8272"))
	_add_building_box_part(root, Vector3(rect.size.x, 1.0, 0.2), Vector3(0, height + 0.55, -rect.size.y * 0.5 + 0.1), colour.darkened(0.1))
	var roof_kind := String(kit.get("roof", "tanks"))
	if roof_kind == "tanks":
		for tank_x in [-width * 0.24, width * 0.24]:
			_add_building_box_part(root, Vector3(1.0, 2.1, 1.0), Vector3(tank_x, height + 1.25, 0), Color("#59676a"))
	elif roof_kind == "garden":
		_add_building_box_part(root, Vector3(width * 0.5, 0.5, depth * 0.42), Vector3(0, height + 0.35, 0), Color("#76644e"))
		for plant_x in [-width * 0.18, 0.0, width * 0.18]:
			_add_building_box_part(root, Vector3(0.45, 1.1, 0.45), Vector3(plant_x, height + 1.15, 0), Color("#658161"))
	elif roof_kind == "laundry":
		for side in [-1.0, 1.0]:
			_add_building_box_part(root, Vector3(0.06, 2.2, 0.06), Vector3(side * width * 0.26, height + 1.2, 0), Color("#66594c"))
		_add_building_box_part(root, Vector3(width * 0.52, 0.035, 0.035), Vector3(0, height + 2.1, 0), Color("#66594c"))
	StaticMerge.merge(root)
	return root


static func _market_face_size(span: float, vertical: float, depth: float, along_x: bool) -> Vector3:
	return Vector3(span, vertical, depth) if along_x else Vector3(depth, vertical, span)


static func _add_market_visual_box(root: Node3D, size: Vector3, center: Vector3, color: Color) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var visual := MeshInstance3D.new()
	visual.mesh = mesh
	visual.position = center
	visual.material_override = _material(color)
	CollisionPolicy.mark_decorative(visual)
	root.add_child(visual)
	return visual


static func _add_market_egg(root: Node3D, half: Vector3, center: Vector3, color: Color) -> MeshInstance3D:
	var visual := SuperEgg.build_part(half, color, SuperEgg.EPSILON_SOFT, SuperEgg.EPSILON_FLAT)
	visual.position = center
	CollisionPolicy.mark_decorative(visual)
	root.add_child(visual)
	return visual


static func _add_market_streets(packs: Dictionary) -> void:
	var cfg: Dictionary = PLAN.MARKET_HOUSE
	var arcade: Dictionary = PLAN.ARCADE_ROOF
	var roof := StaticBody3D.new(); roof.name = "Market_Arcade_Street_Roof"
	var x_mid := (float(arcade.x[0]) + float(arcade.x[1])) * 0.5
	var span_x := float(arcade.x[1]) - float(arcade.x[0])
	var z0 := float(arcade.z[0]); var z1 := float(arcade.z[1]); var roof_h := float(arcade.h)
	for z in arcade.arches:
		# These are still straight cross-ribs (the scheduled arched profile is a
		# known visual departure), but each has an explicit parkour collider.
		_add_market_roof_box(roof, Vector3(span_x, 0.3, 0.3), Vector3(x_mid, DATUM + roof_h, float(z)), Color("#596970"), CollisionPolicy.PARKOUR)
		for edge_x in [float(arcade.x[0]) + 0.15, float(arcade.x[1]) - 0.15]:
			_add_market_roof_box(roof, Vector3(0.3, roof_h, 0.25), Vector3(edge_x, DATUM + roof_h * 0.5, float(z)), Color("#596970"), CollisionPolicy.SOLID)
	# The translucent infill is a solid roof surface. Its box collider follows
	# the rendered panel's footprint so loading cannot expose a visual/collision
	# mismatch along the street.
	_add_market_roof_box(roof, Vector3(span_x, 0.06, z1 - z0), Vector3(x_mid, DATUM + roof_h + 0.2, (z0 + z1) * 0.5), Color(0.54, 0.72, 0.73, 0.58), CollisionPolicy.SOLID)
	StaticMerge.merge(roof)
	_add(packs, _cell(Vector2(x_mid, (z0 + z1) * 0.5)), roof)
	var lane: Dictionary = PLAN.LAMP_LANE
	for i in lane.lanterns.size():
		var x := float(lane.lanterns[i]); var body := Node3D.new(); body.name = "LampLane_Lantern_%02d" % i
		body.position = Vector3(x, DATUM + float(lane.lantern_y), (float(lane.z[0]) + float(lane.z[1])) * 0.5)
		var lantern_mesh := BoxMesh.new(); lantern_mesh.size = Vector3(0.3, 0.4, 0.3)
		var lantern := MeshInstance3D.new(); lantern.mesh = lantern_mesh
		var glow := _material(Color("#ffcb71")); glow.emission_enabled = true; glow.emission = Color("#ff9d40"); glow.emission_energy_multiplier = 1.1
		lantern.material_override = glow; body.add_child(lantern)
		_add(packs, _cell(Vector2(x, float(lane.z[0]) + 2.0)), body)
		if i < lane.lanterns.size() - 1 and float(lane.lanterns[i + 1]) - x <= float(cfg.lamp.lantern_every) * 1.5:
			var next_x := float(lane.lanterns[i + 1]); var string := Node3D.new(); string.name = "LampLane_String_%02d" % i
			string.position = Vector3((x + next_x) * 0.5, DATUM + float(lane.lantern_y) + 0.1, (float(lane.z[0]) + float(lane.z[1])) * 0.5)
			var cord_mesh := BoxMesh.new(); cord_mesh.size = Vector3(next_x - x, 0.025, 0.025)
			var cord := MeshInstance3D.new(); cord.mesh = cord_mesh; cord.material_override = _material(Color("#403a34")); string.add_child(cord)
			_add(packs, _cell(Vector2((x + next_x) * 0.5, float(lane.z[0]) + 2.0)), string)
	for i in lane.stalls.size():
		var stall: Dictionary = lane.stalls[i]; var c: Array = stall.c
		var body := _box_body("LampLane_Stall_%02d" % i, Vector3(2.4, 0.9, 1.0), Vector3(float(c[0]), DATUM + 0.45, float(c[1])), Color("#8b684d"))
		_add_building_box_part(body, Vector3(2.6, 0.08, 1.4), Vector3(0, 1.8, 0), Color("#b57550"))
		_add(packs, _cell(Vector2(float(c[0]), float(c[1]))), body)
	for way in PLAN.COURT_WAYS:
		if int(way.court) != 3 and int(way.court) != 5: continue
		var points: Array = way.pts; var floor := _poly_floor("Market_Court_%02d_Floor" % int(way.court), points, DATUM + 0.02, Color("#a99272"))
		_add(packs, _cell(Vector2(float(points[0][0]), float(points[0][1]))), floor)
		if way.has("passage"):
			var p: Dictionary = way.passage; var a: Array = p.court_end; var center := Vector2(float(a[0]), float(a[1]))
			var lamp := _round_column("Market_Court_Passage_Lamp_%02d" % int(way.court), 0.15, 0.4, Vector3(center.x, DATUM + float(p.h) - 0.2, center.y), Color("#ffd292"))
			_add(packs, _cell(center), lamp)


static func _add_market_roof_box(root: StaticBody3D, size: Vector3, center: Vector3, color: Color, policy: StringName) -> void:
	var mesh := BoxMesh.new()
	mesh.size = size
	var visual := MeshInstance3D.new()
	visual.mesh = mesh
	visual.position = center
	visual.material_override = _material(color)
	visual.set_meta(CollisionPolicy.POLICY_META, policy)
	root.add_child(visual)
	var shape := BoxShape3D.new()
	shape.size = size
	var collision := CollisionShape3D.new()
	collision.shape = shape
	collision.position = center
	collision.set_meta(CollisionPolicy.POLICY_META, policy)
	root.add_child(collision)


static func _block_panel(a: Vector3, b: Vector3, width: float, color: Color) -> StaticBody3D:
	var body := StaticBody3D.new(); body.name = "BLOCK_Crown_Face"; body.collision_layer = 1; body.collision_mask = 1
	var delta := b - a; body.position = (a + b) * 0.5
	var box := BoxMesh.new(); box.size = Vector3(0.45, delta.length(), width)
	var visual := MeshInstance3D.new(); visual.mesh = box; visual.material_override = _material(color)
	visual.rotation = Basis(Vector3.RIGHT, atan2(delta.x, delta.y)).get_euler(); body.add_child(visual)
	var shape := BoxShape3D.new(); shape.size = box.size
	var collision := CollisionShape3D.new(); collision.shape = shape; collision.rotation = visual.rotation; body.add_child(collision)
	return body


## The launch approach sits well outside Moy's core streaming radius, so it is
## baked as one small, separately streamed scene. All positions and widths
## come from LAUNCH_SITE; the one short internal approach joins the planned
## site gate to the south edge of the planned mount for the requested first
## playable access.
static func build_launch_site_pack() -> Node3D:
	var site: Dictionary = PLAN.LAUNCH_SITE
	var terrain = TERRAIN_SCRIPT.new()
	terrain.call("_build_chinese_rim_profile")
	var root := Node3D.new()
	root.name = "MoyLaunchApproach"
	var road_points: Array[Vector2] = []
	for point in site.track.pts:
		road_points.append(Vector2(float(point[0]), float(point[1])))
	var gate := Vector2(float(site.fence.gate[0]), float(site.fence.gate[1]))
	var pad := Vector2(float(site.pad[0]), float(site.pad[1]))
	var mount_half: Array = site.mount.half
	var pad_approach := Vector2(pad.x, pad.y + float(mount_half[1]))
	if road_points.back().distance_to(gate) > 0.1:
		road_points.append(gate)
	_add_ground_hugging_road(root, "ASAN_ServiceTrack", road_points, float(site.track.w), terrain)
	_add_ground_hugging_road(root, "ASAN_PadAccessRoad", [gate, pad_approach], float(site.track.w), terrain)

	var ground_y: float = terrain.get_mesh_height(pad.x, pad.y)
	var mount_size := Vector3(float(mount_half[0]) * 2.0, float(site.mount.deck), float(mount_half[1]) * 2.0)
	var mount := _box_body("ASAN_LaunchMount", mount_size, Vector3(pad.x, ground_y + mount_size.y * 0.5, pad.y), Color("#77766f"))
	_add_visual_box(mount, "LaunchDeck", Vector3(mount_size.x, 0.22, mount_size.z), Vector3(0.0, mount_size.y * 0.5 + 0.04, 0.0), Color("#9b978c"))
	root.add_child(mount)

	# Keep the model's north-running flame trench at its authored width and
	# endpoint, with a dark, solid floor at the real terrain surface.
	var trench: Dictionary = site.mount.trench
	var trench_to := Vector2(float(trench.to[0]), float(trench.to[1]))
	var trench_from := Vector2(pad.x, pad.y - float(mount_half[1]))
	var trench_points: Array[Vector2] = [trench_from, trench_to]
	_add_ground_hugging_surface(root, "ASAN_FlameTrench", trench_points, float(trench.w), terrain, Color("#493b30"), true)
	terrain.free()
	return root


static func _add_visual_box(parent: Node3D, label: String, size: Vector3, offset: Vector3, color: Color) -> void:
	var mesh := BoxMesh.new(); mesh.size = size
	var visual := MeshInstance3D.new(); visual.name = label; visual.mesh = mesh
	visual.position = offset; visual.material_override = _material(color); parent.add_child(visual)


static func _add_ground_hugging_road(parent: Node3D, label: String, points: Array[Vector2], width: float, terrain: Object) -> void:
	_add_ground_hugging_surface(parent, label, points, width, terrain, Color("#a58a65"), true)


static func _add_ground_hugging_surface(parent: Node3D, label: String, points: Array[Vector2], width: float, terrain: Object, color: Color, with_collision: bool) -> void:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var half := width * 0.5
	var left_edges: Array[Vector2] = []
	var right_edges: Array[Vector2] = []
	for point_index in points.size():
		var normal_before: Vector2
		var normal_after: Vector2
		if point_index == 0:
			var first_tangent: Vector2 = (points[1] - points[0]).normalized()
			normal_before = Vector2(-first_tangent.y, first_tangent.x)
			normal_after = normal_before
		elif point_index == points.size() - 1:
			var last_tangent: Vector2 = (points[-1] - points[-2]).normalized()
			normal_before = Vector2(-last_tangent.y, last_tangent.x)
			normal_after = normal_before
		else:
			var tangent_before: Vector2 = (points[point_index] - points[point_index - 1]).normalized()
			var tangent_after: Vector2 = (points[point_index + 1] - points[point_index]).normalized()
			normal_before = Vector2(-tangent_before.y, tangent_before.x)
			normal_after = Vector2(-tangent_after.y, tangent_after.x)
		var miter := (normal_before + normal_after).normalized()
		var denominator := maxf(absf(miter.dot(normal_after)), 0.25)
		var offset := miter * minf(half / denominator, width * 2.0)
		left_edges.append(points[point_index] + offset)
		right_edges.append(points[point_index] - offset)
	for segment_index in range(points.size() - 1):
		var a: Vector2 = points[segment_index]
		var b: Vector2 = points[segment_index + 1]
		var delta := b - a
		var length := delta.length()
		if length < 0.01: continue
		var samples := maxi(1, ceili(length / 2.0))
		for sample in samples:
			var t0 := float(sample) / float(samples)
			var t1 := float(sample + 1) / float(samples)
			var p00 := _terrain_surface_point(left_edges[segment_index].lerp(left_edges[segment_index + 1], t0), terrain)
			var p01 := _terrain_surface_point(right_edges[segment_index].lerp(right_edges[segment_index + 1], t0), terrain)
			var p10 := _terrain_surface_point(left_edges[segment_index].lerp(left_edges[segment_index + 1], t1), terrain)
			var p11 := _terrain_surface_point(right_edges[segment_index].lerp(right_edges[segment_index + 1], t1), terrain)
			for point in [p00, p01, p10, p10, p01, p11]:
				tool.set_normal(Vector3.UP)
				tool.add_vertex(point)
	var mesh := tool.commit()
	var body := StaticBody3D.new()
	body.name = label
	body.collision_layer = 1
	body.collision_mask = 1
	var visual := MeshInstance3D.new()
	visual.name = label + "Surface"
	visual.mesh = mesh
	visual.material_override = _material(color)
	body.add_child(visual)
	if with_collision:
		var shape := ConcavePolygonShape3D.new()
		shape.set_faces(mesh.get_faces())
		var collision := CollisionShape3D.new()
		collision.name = label + "Collision"
		collision.shape = shape
		body.add_child(collision)
	parent.add_child(body)


static func _terrain_surface_point(point: Vector2, terrain: Object) -> Vector3:
	return Vector3(point.x, float(terrain.call("get_mesh_height", point.x, point.y)) + 0.10, point.y)


static func build_silhouette() -> Node3D:
	var root := Node3D.new(); root.name="MoyDistantSilhouette"
	var box := BoxMesh.new(); box.size=Vector3.ONE
	var material := StandardMaterial3D.new(); material.albedo_color=Color("#a88f70"); material.roughness=1.0
	material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	material.vertex_color_use_as_albedo=true
	var lots := MultiMesh.new(); lots.transform_format=MultiMesh.TRANSFORM_3D; lots.use_colors=true; lots.mesh=box
	lots.instance_count=PLAN.LOTS.size()
	var lot_transforms: Array[Transform3D]=[]; var lot_colors: Array[Color]=[]
	for i in PLAN.LOTS.size():
		var l: Array=PLAN.LOTS[i]; var r: Rect2=l[0]; var h:=float(l[1])*float(PLAN.STOREY[l[2]])
		var transform:=Transform3D(Basis.from_scale(Vector3(r.size.x,h,r.size.y)),Vector3(r.get_center().x,DATUM+h*0.5,r.get_center().y)); var tint:=Color("#b9a181") if String(l[2])=="fabric" else Color("#a48f73")
		lots.set_instance_transform(i,transform); lots.set_instance_color(i,tint); lot_transforms.append(transform); lot_colors.append(tint)
	_store_multimesh_buffer(lots,lot_transforms,lot_colors)
	var li := MultiMeshInstance3D.new(); li.name="LotSilhouettes"; li.multimesh=lots; li.custom_aabb=_multimesh_bounds(lots,lot_transforms); li.material_override=material; li.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF; root.add_child(li)
	var old := MultiMesh.new(); old.transform_format=MultiMesh.TRANSFORM_3D; old.use_colors=true; old.mesh=box
	old.instance_count=PLAN.OLD_HOUSES.size()
	var old_transforms: Array[Transform3D]=[]; var old_colors: Array[Color]=[]
	for i in PLAN.OLD_HOUSES.size():
		var h: Dictionary=PLAN.OLD_HOUSES[i]; var pts: Array=h.corners
		var r:=_point_bounds(pts); var height:=float(h.storeys)*3.25
		var transform:=Transform3D(Basis.from_scale(Vector3(r.size.x,height,r.size.y)),Vector3(r.get_center().x,DATUM+height*0.5,r.get_center().y)); var tint:=Color("#c6aa82")
		old.set_instance_transform(i,transform); old.set_instance_color(i,tint); old_transforms.append(transform); old_colors.append(tint)
	_store_multimesh_buffer(old,old_transforms,old_colors)
	var oi := MultiMeshInstance3D.new(); oi.name="OldHouseSilhouettes"; oi.multimesh=old; oi.custom_aabb=_multimesh_bounds(old,old_transforms); oi.material_override=material; oi.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF; root.add_child(oi)
	for b in PLAN.BUILDINGS:
		if b.rect==null: continue
		var r: Rect2=b.rect; var h:=maxf(float(b.height),4.0)
		var n:=int(b.n); var center:=r.get_center()
		if n==1:
			for wing in [Vector4(-26,0,6,60),Vector4(26,0,6,60),Vector4(0,-30,46,6),Vector4(0,30,46,6)]: _silhouette_box(root,"HotelPodium",Vector3(wing.z,44,wing.w),Vector3(center.x+wing.x,DATUM+22,center.y+wing.y),material)
			var hotel_tower:=CylinderMesh.new(); hotel_tower.top_radius=10.5; hotel_tower.bottom_radius=14.0; hotel_tower.height=96; hotel_tower.radial_segments=8
			var ht:=MeshInstance3D.new(); ht.name="HotelTowerSilhouette"; ht.mesh=hotel_tower; ht.position=Vector3(center.x+26,DATUM+48,center.y+14); ht.material_override=material; root.add_child(ht)
			var drum:=CylinderMesh.new(); drum.top_radius=12.0; drum.bottom_radius=12.0; drum.height=12; drum.radial_segments=8
			var hd:=MeshInstance3D.new(); hd.name="HotelDrumSilhouette"; hd.mesh=drum; hd.position=Vector3(center.x+26,DATUM+102,center.y+14); hd.material_override=material; root.add_child(hd)
		elif n==12:
			var shaft:=CylinderMesh.new(); shaft.top_radius=12; shaft.bottom_radius=20; shaft.height=262; shaft.radial_segments=8
			var ws:=MeshInstance3D.new(); ws.name="WindspireSilhouette"; ws.mesh=shaft; ws.position=Vector3(center.x,DATUM+131,center.y); ws.material_override=material; root.add_child(ws)
			for i in 4: _silhouette_box(root,"WindspireCrownPylon",Vector3(2,18,2),Vector3(center.x+(-8.0 if i%2==0 else 8.0),DATUM+271,center.y+(-8.0 if i<2 else 8.0)),material)
		elif n==13:
			_silhouette_box(root,"BLOCKTowerSilhouette",Vector3(r.size.x,150,r.size.y),Vector3(center.x,DATUM+75,center.y),material)
			for sign in [-1.0,1.0]:
				var blade:=MeshInstance3D.new(); blade.name="BLOCKBladeSilhouette"; var bm:=BoxMesh.new(); bm.size=Vector3(5,62,54); blade.mesh=bm; blade.position=Vector3(center.x+sign*8,DATUM+181,center.y); blade.rotation.z=sign*deg_to_rad(12.0); blade.material_override=material; root.add_child(blade)
		else:
			var mesh:=BoxMesh.new(); mesh.size=Vector3(r.size.x,h,r.size.y)
			var vis:=MeshInstance3D.new(); vis.name="Landmark_%02d"%n; vis.mesh=mesh; vis.position=Vector3(center.x,DATUM+h*0.5,center.y); vis.material_override=material; vis.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF; root.add_child(vis)
	_add_silhouette_wall(root,material)
	_silhouette_box(root,"CityDomeSilhouette",Vector3(38,28,38),Vector3(PLAN.CENTER.x,DATUM+55.6,0),material)
	var crossing:=CylinderMesh.new(); crossing.top_radius=28.7; crossing.bottom_radius=28.7; crossing.height=1.0; crossing.radial_segments=32
	var crossing_vis:=MeshInstance3D.new(); crossing_vis.name="CrossingRingSilhouette"; crossing_vis.mesh=crossing; crossing_vis.position=Vector3(PLAN.CENTER.x,DATUM+6.5,0); crossing_vis.material_override=material; root.add_child(crossing_vis)
	for i in PLAN.TURBINES.size():
		var p: Vector2=PLAN.TURBINES[i]
		var tower_mesh:=CylinderMesh.new(); tower_mesh.top_radius=1.8; tower_mesh.bottom_radius=3.2; tower_mesh.height=95.0; tower_mesh.radial_segments=8
		var tower:=MeshInstance3D.new(); tower.name="TurbineSilhouette_%02d"%i; tower.mesh=tower_mesh; tower.position=Vector3(p.x,DATUM+47.5,p.y); tower.material_override=material; tower.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF; root.add_child(tower)
		var hub:=MeshInstance3D.new(); var hub_mesh:=SphereMesh.new(); hub_mesh.radius=2.4; hub.mesh=hub_mesh; hub.position=Vector3(p.x-6.5,DATUM+97.0,p.y); hub.material_override=material; hub.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF; root.add_child(hub)
		for blade_index in 3:
			var angle:=TAU*float(blade_index)/3.0
			var blade:=MeshInstance3D.new(); var bm:=BoxMesh.new(); bm.size=Vector3(0.8,64.0,3.2); blade.mesh=bm; blade.position=Vector3(p.x-6.5,DATUM+97.0+cos(angle)*32.0,p.y+sin(angle)*32.0); blade.rotation.x=angle; blade.material_override=material; blade.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF; root.add_child(blade)
	return root


static func _silhouette_box(root: Node3D, label: String, size: Vector3, center: Vector3, material: Material) -> void:
	var mesh:=BoxMesh.new(); mesh.size=size; var vis:=MeshInstance3D.new(); vis.name=label; vis.mesh=mesh; vis.position=center; vis.material_override=material; vis.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF; root.add_child(vis)


static func _add_silhouette_wall(root: Node3D, material: Material) -> void:
	var mesh:=BoxMesh.new(); mesh.size=Vector3.ONE
	var multi:=MultiMesh.new(); multi.transform_format=MultiMesh.TRANSFORM_3D; multi.mesh=mesh; multi.instance_count=64; var transforms: Array[Transform3D]=[]
	var r:=float(PLAN.WALL.r)
	for i in 64:
		var a:=TAU*float(i)/64.0; var b:=TAU*float(i+1)/64.0; var mid:Vector2=Vector2(PLAN.CENTER.x+r*cos((a+b)*0.5),r*sin((a+b)*0.5))
		var blocked:=false
		for gate in PLAN.WALL.gates:
			if Vector2(gate.p[0],gate.p[1]).distance_to(mid)<17.0: blocked=true
		var d:=Vector2(PLAN.CENTER.x+r*cos(b),r*sin(b))-Vector2(PLAN.CENTER.x+r*cos(a),r*sin(a))
		var segment_scale:=Vector3.ZERO if blocked else Vector3(d.length(),12.0,12.0)
		var transform:=Transform3D(Basis(Vector3.UP,-atan2(d.y,d.x))*Basis.from_scale(segment_scale),Vector3(mid.x,DATUM+6.0,mid.y))
		multi.set_instance_transform(i,transform); transforms.append(transform)
	_store_multimesh_buffer(multi,transforms)
	var wall:=MultiMeshInstance3D.new(); wall.name="RimWallSilhouette"; wall.multimesh=multi; wall.custom_aabb=_multimesh_bounds(multi,transforms); wall.material_override=material; wall.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF; root.add_child(wall)


static func _point_bounds(points: Array) -> Rect2:
	var minx:=INF; var maxx:=-INF; var minz:=INF; var maxz:=-INF
	for p in points:
		minx=minf(minx,float(p[0])); maxx=maxf(maxx,float(p[0])); minz=minf(minz,float(p[1])); maxz=maxf(maxz,float(p[1]))
	return Rect2(minx,minz,maxx-minx,maxz-minz)


static func _cell(p: Vector2) -> Vector2i:
	return Vector2i(floori((p.x + 800.0) / CELL), floori((p.y + 240.0) / CELL))


static func _station_platform_offset(crossing_tracks: bool) -> float:
	var track_offset: float=float(PLAN.CROSS.track) if crossing_tracks else 0.0
	var car_half: float=float(PLAN.TRAIN.car[2])*0.5
	var platform_half: float=float(PLAN.PLATFORMS.width)*0.5
	# PLATFORMS.boarding requires 7.5 cm clear; edge=1.4 alone overlaps
	# the 3.6 m car envelope, so use the actual car and platform widths.
	return track_offset+car_half+0.075+platform_half


static func _curved_platform_offset(track_radius: float) -> float:
	var flat_gap:=_station_platform_offset(false)
	var car_half_length:=float(PLAN.TRAIN.car[0])*0.5
	var platform_half_length:=float(PLAN.CROSS.platform[0])*0.5
	# A long car spans the chord while the platform follows the wall arc.
	return flat_gap+car_half_length*sin(platform_half_length/maxf(track_radius,0.1))


static func _add(packs: Dictionary, cell: Vector2i, node: Node3D) -> void:
	var label := String(node.name).to_lower()
	if "door" in label or "landing" in label or "liftstop" in label or "platform" in label:
		node.set_meta("reach_target", true)
	if "platform" in label: node.set_meta("station_platform", true)
	if _is_walk_deck_name(label):
		node.set_meta("walk_deck", true)
	_tag_walk_run_ids(node)
	if "enterable" in label:
		node.set_meta("enterable", true)
	if "clockroom" in label: node.set_meta("enterable", true)
	if "closed_shell" in label:
		node.set_meta("closed_shell", true)
	for child in node.find_children("*", "Node", true, false):
		var child_name := String(child.name).to_lower()
		if "foliage" in child_name or "cloud" in child_name or "trim" in child_name or "rope" in child_name or "particle" in child_name or "flower" in child_name or "grass" in child_name or "banner" in child_name:
			CollisionPolicy.mark_decorative(child)
	var key := "%02d_%02d" % [cell.x, cell.y]
	if not packs.has(key):
		var root := Node3D.new(); root.name = "MoyCell_%s" % key; packs[key] = root
	packs[key].add_child(node)


static func _is_walk_deck_name(label: String) -> bool:
	if "landing" in label or "platform" in label or "flight" in label or "ramp" in label or "walkway" in label:
		return true
	return label.begins_with("deck_") and not label.begins_with("deck_gardenbed_") and not label.begins_with("deck_parapet_")


static func _tag_walk_run_ids(root: Node) -> void:
	for node in [root] + root.find_children("*", "CollisionObject3D", true, false):
		if not node is CollisionObject3D: continue
		var label := String(node.name)
		var run_id := ""
		if label.begins_with("DeckGardenBed_"):
			var bed_parts := label.split("_")
			if bed_parts.size() >= 3: run_id = "DeckGardenBed_%s_%s" % [bed_parts[2], bed_parts[3] if bed_parts.size() > 3 and bed_parts[3].is_valid_int() else ""]
			if "_Segment_" in label: run_id = "DeckGardenBed_%s" % bed_parts[2]
		elif label.begins_with("Deck_"):
			var last_separator := label.rfind("_")
			if last_separator > 0 and label.substr(last_separator + 1).is_valid_int(): run_id = label.substr(0, last_separator)
		elif label.begins_with("RimWall_"):
			run_id = "RimWall"
		elif label.begins_with("OldLane_"):
			var lane_parts := label.split("_")
			if lane_parts.size() >= 3: run_id = "OldLane_%s" % lane_parts[1]
		elif label.begins_with("Street_"):
			run_id = label
		elif label.begins_with("Lot_"):
			run_id = label
		elif label.begins_with("WallLine_Track_"):
			run_id = "WallLine_Track"
		elif label.begins_with("WallLine_Rail_"):
			run_id = "WallLine_Rail"
		if not run_id.is_empty(): node.set_meta("walk_run_id", run_id)


static func _material(color: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new(); m.albedo_color = color; m.roughness = 0.92
	return m


static func _box_body(label: String, size: Vector3, center: Vector3, color: Color, softened := false) -> StaticBody3D:
	var body := StaticBody3D.new(); body.name = label; body.collision_layer = 1; body.collision_mask = 1
	body.position = center
	var shape := BoxShape3D.new(); shape.size = size
	var collision := CollisionShape3D.new(); collision.shape = shape; body.add_child(collision)
	var mesh: Mesh
	var visual := MeshInstance3D.new()
	if softened:
		if _soft_block_unit == null: _soft_block_unit=SuperEgg.build_mesh(Vector3.ONE*0.5,SuperEgg.EPSILON_FLAT,SuperEgg.EPSILON_FLAT,8,12)
		mesh=_soft_block_unit; visual.scale=size
	else:
		var box:=BoxMesh.new(); box.size=size; mesh=box
	visual.mesh = mesh; visual.material_override = _material(color); body.add_child(visual)
	return body


static func _park_ground_body(rect: Rect2) -> StaticBody3D:
	# The terrain already contains the authored 4 m pond basin. Make the park
	# paving a baked grid with actual pond and tower-drum openings. The helix
	# ground landings are level with the datum, so the lawn must not overlap them.
	var pond: Dictionary = PLAN.PARK.pond
	var pond_center := Vector2(float(pond.c[0]), float(pond.c[1]))
	var pond_radii := Vector2(float(pond.r[0]), float(pond.r[1]))
	var tower_centers: Array[Vector2] = []
	for tower in PLAN.CROSSING.towers:
		tower_centers.append(Vector2(float(tower.c[0]), float(tower.c[1])))
	var drum_radius := float(PLAN.CROSSING.tower.drum)
	var step := 1.0
	var surface_y := DATUM + float(PLAN.CROSSING.lawn_y)
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for ix in ceili(rect.size.x / step):
		var x0 := rect.position.x + float(ix) * step
		var x1 := minf(rect.end.x, x0 + step)
		for iz in ceili(rect.size.y / step):
			var z0 := rect.position.y + float(iz) * step
			var z1 := minf(rect.end.y, z0 + step)
			var closest := Vector2(clampf(pond_center.x, x0, x1), clampf(pond_center.y, z0, z1))
			var basin_point := (closest - pond_center) / pond_radii
			if basin_point.length_squared() <= 1.0:
				continue
			var tower_open := false
			for tower_center in tower_centers:
				var nearest := Vector2(clampf(tower_center.x, x0, x1), clampf(tower_center.y, z0, z1))
				if nearest.distance_to(tower_center) <= drum_radius:
					tower_open = true
					break
			if tower_open:
				continue
			var a := Vector3(x0, surface_y, z0)
			var b := Vector3(x0, surface_y, z1)
			var c := Vector3(x1, surface_y, z0)
			var d := Vector3(x1, surface_y, z1)
			tool.set_normal(Vector3.UP); tool.add_vertex(a)
			tool.set_normal(Vector3.UP); tool.add_vertex(b)
			tool.set_normal(Vector3.UP); tool.add_vertex(c)
			tool.set_normal(Vector3.UP); tool.add_vertex(c)
			tool.set_normal(Vector3.UP); tool.add_vertex(b)
			tool.set_normal(Vector3.UP); tool.add_vertex(d)
	var mesh := tool.commit()
	var body := StaticBody3D.new()
	body.name = "Open_park"
	body.collision_layer = 1
	body.collision_mask = 1
	var visual := MeshInstance3D.new()
	visual.name = "ParkGroundPaving"
	visual.mesh = mesh
	visual.material_override = _material(Color("#b9a586"))
	body.add_child(visual)
	var faces := mesh.get_faces()
	var shape := ConcavePolygonShape3D.new()
	shape.set_faces(faces)
	var collision := CollisionShape3D.new()
	collision.name = "ParkGroundPavingWithoutPondCollision"
	collision.shape = shape
	body.add_child(collision)
	return body


static func _rain_garden_polygons(data: Dictionary, index: int, step_degrees: float) -> Array:
	# A ring bed from r_in to r about the tower's centre, cut by a paved corridor
	# along each bearing in `paths` and clear of the lift. Built as a few
	# polygons: a top, outer walls, no hidden faces and no bottom (it lies on the
	# ground). Collision is the convex pieces of the same polygons.
	var center := Vector2(float(data.c[0]), float(data.c[1]))
	var inner := float(data.r_in)
	var outer := float(data.r)
	var path_half := float(data.path_width) * 0.5 + 0.16
	var lift_world := Vector2(float(PLAN.CROSSING.towers[index].lift.c[0]), float(PLAN.CROSSING.towers[index].lift.c[1]))
	var lift_local := lift_world - center
	var lift_radius := float(data.lift_clear) + 0.16
	var bearings: Array[float] = []
	for bearing in data.paths: bearings.append(fposmod(float(bearing), 360.0))
	bearings.sort()
	var cutters: Array = []
	for bearing in bearings:
		var direction := Vector2(cos(deg_to_rad(bearing)), sin(deg_to_rad(bearing)))
		var side := Vector2(-direction.y, direction.x)
		cutters.append(_rain_garden_orient(PackedVector2Array([-side * path_half, side * path_half, direction * (outer + 0.5) + side * path_half, direction * (outer + 0.5) - side * path_half])))
	var lift_circle := PackedVector2Array()
	for step in 32: lift_circle.append(lift_local + Vector2(cos(TAU * step / 32.0), sin(TAU * step / 32.0)) * lift_radius)
	cutters.append(_rain_garden_orient(lift_circle))
	var polygons: Array = []
	for k in bearings.size():
		var a0 := bearings[k]
		var a1 := bearings[(k + 1) % bearings.size()]
		if a1 <= a0: a1 += 360.0
		var sector := PackedVector2Array()
		var steps := maxi(2, ceili((a1 - a0) / step_degrees))
		for step in steps + 1:
			var angle := deg_to_rad(lerpf(a0, a1, float(step) / steps))
			sector.append(Vector2(cos(angle), sin(angle)) * outer)
		for step in steps + 1:
			var angle := deg_to_rad(lerpf(a1, a0, float(step) / steps))
			sector.append(Vector2(cos(angle), sin(angle)) * inner)
		var pieces: Array = [_rain_garden_orient(sector)]
		for cutter in cutters:
			var next_pieces: Array = []
			for piece in pieces:
				for result in Geometry2D.clip_polygons(piece, cutter):
					var oriented := _rain_garden_orient(result)
					if Geometry2D.is_polygon_clockwise(result) == Geometry2D.is_polygon_clockwise(piece) and absf(_polygon_area(oriented)) > 0.05:
						next_pieces.append(oriented)
			pieces = next_pieces
		polygons.append_array(pieces)
	return polygons


static func _crossing_rain_garden(data: Dictionary, index: int) -> StaticBody3D:
	# The visual follows the ring at 3 degrees; the collision at 9 degrees (a 0.02 m chord) in convex pieces.
	var center := Vector2(float(data.c[0]), float(data.c[1]))
	var polygons := _rain_garden_polygons(data, index, 3.0)
	var height := 0.22
	var body := StaticBody3D.new()
	body.name = "CrossingRainGarden_%02d" % index
	body.position = Vector3(center.x, DATUM, center.y)
	body.collision_layer = 1
	body.collision_mask = 1
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for polygon in polygons:
		var triangles := Geometry2D.triangulate_polygon(polygon)
		for t in range(0, triangles.size(), 3):
			var a := Vector3(polygon[triangles[t]].x, height, polygon[triangles[t]].y)
			var b := Vector3(polygon[triangles[t + 1]].x, height, polygon[triangles[t + 1]].y)
			var c := Vector3(polygon[triangles[t + 2]].x, height, polygon[triangles[t + 2]].y)
			_add_facing_triangle(tool, a, b, c, Vector3.UP)
		var area := _polygon_area(polygon)
		for i in polygon.size():
			var p0: Vector2 = polygon[i]
			var p1: Vector2 = polygon[(i + 1) % polygon.size()]
			var edge := p1 - p0
			if edge.length_squared() < 0.000001: continue
			var outward := Vector2(edge.y, -edge.x).normalized() if area > 0.0 else Vector2(-edge.y, edge.x).normalized()
			var wall_normal := Vector3(outward.x, 0.0, outward.y)
			var b0 := Vector3(p0.x, 0.0, p0.y)
			var b1 := Vector3(p1.x, 0.0, p1.y)
			var t0 := Vector3(p0.x, height, p0.y)
			var t1 := Vector3(p1.x, height, p1.y)
			_add_facing_triangle(tool, b0, b1, t1, wall_normal)
			_add_facing_triangle(tool, b0, t1, t0, wall_normal)
	var piece_index := 0
	for polygon in _rain_garden_polygons(data, index, 9.0):
		for convex in Geometry2D.decompose_polygon_in_convex(polygon):
			var points := PackedVector3Array()
			for point in convex:
				points.append(Vector3(point.x, 0.0, point.y))
				points.append(Vector3(point.x, height, point.y))
			var shape := ConvexPolygonShape3D.new()
			shape.points = points
			var collision := CollisionShape3D.new()
			collision.name = "CrossingRainGardenRingCollision_%02d" % piece_index
			collision.shape = shape
			body.add_child(collision)
			piece_index += 1
	var visual := MeshInstance3D.new()
	visual.name = "CrossingRainGardenRing"
	visual.mesh = tool.commit()
	visual.material_override = _material(Color("#648350"))
	body.add_child(visual)
	return body


static func _add_prism_faces(tool: SurfaceTool, bottom: Array, top: Array) -> void:
	# A convex prism from four bottom corners and the four above them, in one order round.
	var center := Vector3.ZERO
	for corner in bottom + top: center += corner
	center /= 8.0
	_add_facing_triangle(tool, top[0], top[1], top[2], Vector3.UP)
	_add_facing_triangle(tool, top[0], top[2], top[3], Vector3.UP)
	for i in 4:
		var j := (i + 1) % 4
		var mid: Vector3 = (bottom[i] + bottom[j]) * 0.5
		var outward := Vector3(mid.x - center.x, 0.0, mid.z - center.z).normalized()
		_add_facing_triangle(tool, bottom[i], bottom[j], top[j], outward)
		_add_facing_triangle(tool, bottom[i], top[j], top[i], outward)


static func _prism_collision(body: StaticBody3D, name: String, bottom: Array, top: Array) -> void:
	var points := PackedVector3Array()
	for corner in bottom + top: points.append(corner)
	var shape := ConvexPolygonShape3D.new()
	shape.points = points
	var collision := CollisionShape3D.new()
	collision.name = name
	collision.shape = shape
	body.add_child(collision)


static func _flight_underfill(label: String, a: Vector3, b: Vector3, half_width: float, floor_y: float, soffit_drop: float = 0.0) -> StaticBody3D:
	# A solid skirt under a flight's low end, from the floor up to the belt's underside, for as far as the
	# clearance is under 2.5 m: nobody walks into the wedge under a stair. World coordinates, body at the origin.
	var low := a if a.y <= b.y else b
	var high := b if a.y <= b.y else a
	var delta := Vector2(high.x - low.x, high.z - low.z)
	var run := delta.length()
	if run < 0.5 or high.y - low.y < 0.1: return null
	var dir := delta / run
	var lateral := Vector2(-dir.y, dir.x)
	var slope := (high.y - low.y) / run
	var under_y0 := low.y - 0.45 / cos(atan2(high.y - low.y, run))
	# soffit_drop: how far under the line the lowest soffit hangs (a stair's sawtooth hangs lower than the belts).
	var lowest := low.y - maxf(soffit_drop, 0.45 / cos(atan2(high.y - low.y, run)))
	var s_max := minf(run, (2.5 + floor_y - lowest) / slope)
	if s_max < 0.3: return null
	var bottom: Array = []
	var top: Array = []
	for s in [0.0, s_max]:
		for side in ([-1.0, 1.0] if s == 0.0 else [1.0, -1.0]):
			var plan: Vector2 = Vector2(low.x, low.z) + dir * float(s) + lateral * float(side) * half_width
			bottom.append(Vector3(plan.x, floor_y - 0.1, plan.y))
			top.append(Vector3(plan.x, maxf(floor_y + 0.02, under_y0 + slope * s), plan.y))
	var body := StaticBody3D.new()
	body.name = label
	body.set_meta("solid_fill", true)
	body.collision_layer = 1
	body.collision_mask = 1
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	_add_prism_faces(tool, bottom, top)
	_prism_collision(body, label + "Collision", bottom, top)
	var visual := MeshInstance3D.new()
	visual.name = label + "Visual"
	visual.mesh = tool.commit()
	visual.material_override = _material(Color("#b3a27e"))
	body.add_child(visual)
	return body


static func _helix_underfill(label: String, hand: Dictionary, depth: float, r_in: float, r_out: float) -> StaticBody3D:
	# The first rising turn of a hand lifts off the ground: under it the soffit is under 2.3 m until the tread is
	# 2.3 + depth up. That wedge is filled, sector by sector (6 degrees), up to the soffit's far edge. Local to the tower.
	var body := StaticBody3D.new()
	body.name = label
	body.set_meta("solid_fill", true)
	body.collision_layer = 1
	body.collision_mask = 1
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var count := 0
	for seg in hand.profile:
		var y0 := float(seg[2])
		var y1 := float(seg[3])
		if not is_zero_approx(y0) or y1 <= y0: continue
		var a0 := float(seg[0])
		var a1 := float(seg[1])
		var rate := (y1 - y0) / (a1 - a0)
		var span := minf(a1 - a0, (2.3 + depth) / rate)   # 2.3 m clears the 2.2 m rule and stops short of the other hand's ground landing
		var steps := maxi(1, ceili(span / 6.0))
		for i in steps:
			var d0 := deg_to_rad(a0 + span * float(i) / steps)
			var d1 := deg_to_rad(a0 + span * float(i + 1) / steps)
			var top_y := rate * (a0 + span * float(i + 1) / steps - a0) - depth
			if top_y < 0.1: continue
			var bottom: Array = [Vector3(cos(d0) * r_in, -0.1, sin(d0) * r_in), Vector3(cos(d1) * r_in, -0.1, sin(d1) * r_in), Vector3(cos(d1) * r_out, -0.1, sin(d1) * r_out), Vector3(cos(d0) * r_out, -0.1, sin(d0) * r_out)]
			var top: Array = []
			for corner in bottom: top.append(Vector3(corner.x, top_y, corner.z))
			_add_prism_faces(tool, bottom, top)
			_prism_collision(body, "%sCollision_%02d" % [label, count], bottom, top)
			count += 1
	if count == 0:
		body.free()
		return null
	var visual := MeshInstance3D.new()
	visual.name = label + "Visual"
	visual.mesh = tool.commit()
	visual.material_override = _material(Color("#aaa58f"))
	body.add_child(visual)
	return body


static func _polygon_deck_body(label: String, outline: PackedVector2Array, top_y: float, thickness: float, color: Color) -> StaticBody3D:
	# A deck of any outline (world x, z): a top, a soffit and sides, with convex pieces for collision.
	var polygon := _rain_garden_orient(outline)
	var area := _polygon_area(polygon)
	var bottom_y := top_y - thickness
	var body := StaticBody3D.new()
	body.name = label
	body.collision_layer = 1
	body.collision_mask = 1
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var triangles := Geometry2D.triangulate_polygon(polygon)
	for t in range(0, triangles.size(), 3):
		var p0: Vector2 = polygon[triangles[t]]
		var p1: Vector2 = polygon[triangles[t + 1]]
		var p2: Vector2 = polygon[triangles[t + 2]]
		_add_facing_triangle(tool, Vector3(p0.x, top_y, p0.y), Vector3(p1.x, top_y, p1.y), Vector3(p2.x, top_y, p2.y), Vector3.UP)
		_add_facing_triangle(tool, Vector3(p0.x, bottom_y, p0.y), Vector3(p1.x, bottom_y, p1.y), Vector3(p2.x, bottom_y, p2.y), Vector3.DOWN)
	for i in polygon.size():
		var a: Vector2 = polygon[i]
		var b: Vector2 = polygon[(i + 1) % polygon.size()]
		var edge := b - a
		if edge.length_squared() < 0.000001: continue
		var outward := Vector2(edge.y, -edge.x).normalized() if area > 0.0 else Vector2(-edge.y, edge.x).normalized()
		var wall_normal := Vector3(outward.x, 0.0, outward.y)
		_add_facing_triangle(tool, Vector3(a.x, bottom_y, a.y), Vector3(b.x, bottom_y, b.y), Vector3(b.x, top_y, b.y), wall_normal)
		_add_facing_triangle(tool, Vector3(a.x, bottom_y, a.y), Vector3(b.x, top_y, b.y), Vector3(a.x, top_y, a.y), wall_normal)
	var piece_index := 0
	for convex in Geometry2D.decompose_polygon_in_convex(polygon):
		var points := PackedVector3Array()
		for point in convex:
			points.append(Vector3(point.x, bottom_y, point.y))
			points.append(Vector3(point.x, top_y, point.y))
		var shape := ConvexPolygonShape3D.new()
		shape.points = points
		var collision := CollisionShape3D.new()
		collision.name = "%sCollision_%02d" % [label, piece_index]
		collision.shape = shape
		body.add_child(collision)
		piece_index += 1
	var visual := MeshInstance3D.new()
	visual.name = label + "Visual"
	visual.mesh = tool.commit()
	visual.material_override = _material(color)
	body.add_child(visual)
	return body


static func _add_box_faces(tool: SurfaceTool, lo: Vector3, hi: Vector3) -> void:
	var corners := [Vector3(lo.x, lo.y, lo.z), Vector3(hi.x, lo.y, lo.z), Vector3(hi.x, lo.y, hi.z), Vector3(lo.x, lo.y, hi.z), Vector3(lo.x, hi.y, lo.z), Vector3(hi.x, hi.y, lo.z), Vector3(hi.x, hi.y, hi.z), Vector3(lo.x, hi.y, hi.z)]
	var faces := [[4, 7, 6, 5, Vector3.UP], [0, 1, 2, 3, Vector3.DOWN], [0, 3, 7, 4, Vector3.LEFT], [1, 5, 6, 2, Vector3.RIGHT], [0, 4, 5, 1, Vector3.FORWARD], [3, 2, 6, 7, Vector3.BACK]]
	for face in faces:
		_add_facing_triangle(tool, corners[face[0]], corners[face[1]], corners[face[2]], face[4])
		_add_facing_triangle(tool, corners[face[0]], corners[face[2]], corners[face[3]], face[4])


static func _stair_body(label: String, foot: Vector3, head: Vector3, width: float) -> StaticBody3D:
	# A stone stair of 0.18 m risers, one box per step hanging the escalator section's depth below its
	# own lower tread edge (a sawtooth soffit). World coordinates, body at the origin.
	var rise := head.y - foot.y
	var run := head.x - foot.x
	var count := maxi(1, ceili(absf(rise) / 0.18))
	var depth := float(PLAN.ESCALATORS.section.depth)
	var body := StaticBody3D.new()
	body.name = label
	body.collision_layer = 1
	body.collision_mask = 1
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in count:
		var x0 := foot.x + run * float(i) / count
		var x1 := foot.x + run * float(i + 1) / count
		var top := foot.y + rise * float(i + 1) / count
		var bottom := foot.y + rise * float(i) / count - depth
		var lo := Vector3(minf(x0, x1), bottom, foot.z - width * 0.5)
		var hi := Vector3(maxf(x0, x1), top, foot.z + width * 0.5)
		_add_box_faces(tool, lo, hi)
		var shape := BoxShape3D.new()
		shape.size = hi - lo
		var collision := CollisionShape3D.new()
		collision.name = "Step_%02d" % i
		collision.shape = shape
		collision.position = (lo + hi) * 0.5
		body.add_child(collision)
	var visual := MeshInstance3D.new()
	visual.name = "StairSteps"
	visual.mesh = tool.commit()
	visual.material_override = _material(Color("#d3c6ad"))
	body.add_child(visual)
	return body


static func _rain_garden_orient(points: PackedVector2Array) -> PackedVector2Array:
	# One winding for every polygon fed to the clipper: holes come back reversed.
	var result := PackedVector2Array(points)
	if Geometry2D.is_polygon_clockwise(result): result.reverse()
	return result


static func _polygon_area(points: PackedVector2Array) -> float:
	var area := 0.0
	for i in points.size():
		var p0: Vector2 = points[i]
		var p1: Vector2 = points[(i + 1) % points.size()]
		area += p0.x * p1.y - p1.x * p0.y
	return area * 0.5


static func _add_facing_triangle(tool: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, facing: Vector3) -> void:
	# Godot's front faces are clockwise, so the front normal is (c - a) x (b - a).
	var normal := (c - a).cross(b - a)
	var vertices: Array[Vector3] = [a, b, c]
	if normal.dot(facing) < 0.0: vertices = [a, c, b]
	for vertex in vertices:
		tool.set_normal(facing)
		tool.add_vertex(vertex)


static func _round_column(label: String, radius: float, height: float, center: Vector3, color: Color) -> StaticBody3D:
	var body:=StaticBody3D.new(); body.name=label; body.position=center; body.collision_layer=1; body.collision_mask=1
	var mesh:=CylinderMesh.new(); mesh.top_radius=radius; mesh.bottom_radius=radius; mesh.height=height; mesh.radial_segments=12
	var visual:=MeshInstance3D.new(); visual.mesh=mesh; visual.material_override=_material(color); body.add_child(visual)
	var shape:=CylinderShape3D.new(); shape.radius=radius; shape.height=height; var col:=CollisionShape3D.new(); col.shape=shape; body.add_child(col)
	return body


static func _add_building_box_part(root: StaticBody3D, size: Vector3, center: Vector3, color: Color) -> void:
	var shape:=BoxShape3D.new(); shape.size=size
	var collision:=CollisionShape3D.new(); collision.shape=shape; collision.position=center; root.add_child(collision)
	var mesh:=BoxMesh.new(); mesh.size=size
	var visual:=MeshInstance3D.new(); visual.mesh=mesh; visual.position=center; visual.material_override=_material(color); root.add_child(visual)


static func _segment_body(label: String, a: Vector2, b: Vector2, width: float, bottom: float, height: float, color: Color) -> StaticBody3D:
	var d := b - a
	var body := _box_body(label, Vector3(d.length(), height, width), Vector3((a.x+b.x)*0.5, bottom+height*0.5, (a.y+b.y)*0.5), color)
	body.rotation.y = -atan2(d.y, d.x)
	return body


static func _set_box_collision_margin(body: StaticBody3D, margin: float) -> void:
	for child in body.get_children():
		if child is CollisionShape3D and child.shape is BoxShape3D:
			(child.shape as BoxShape3D).margin=margin


static func _set_body_glass(body: StaticBody3D, color: Color) -> void:
	var glass:=StandardMaterial3D.new(); glass.albedo_color=color; glass.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA; glass.roughness=0.2; glass.metallic=0.05
	for child in body.get_children():
		if child is MeshInstance3D: (child as MeshInstance3D).material_override=glass


static func _add_roof(body: StaticBody3D, footprint: Vector2, height: float, color: Color) -> void:
	var mesh := BoxMesh.new(); mesh.size = Vector3(footprint.x, 0.15, footprint.y)
	var roof := MeshInstance3D.new(); roof.name = "WalkableRoof"; roof.mesh = mesh; roof.material_override = _material(color)
	roof.position.y = height * 0.5 - 0.075; body.add_child(roof)


static func _lot_color(index: int, kind: String) -> Color:
	if kind == "midrise": return [Color("#cfc5ad"), Color("#b6c9bd"), Color("#d4b2a7"), Color("#b5c8d3"), Color("#bfc3c3")][index % 5]
	return [Color("#d9c6a6"), Color("#c5a17d"), Color("#d6b2a7"), Color("#b3c4ba"), Color("#b9c7d0"), Color("#c5bdac")][index % 6]


static func _old_house_color(index: int) -> Color:
	return [Color("#d5c09d"), Color("#c8a685"), Color("#d1b2a3"), Color("#b2c4b8"), Color("#c0c6cf")][index % 5]


## P4: replace each old-town mass with its plan-selected tower-house form.
## The footprint remains one blocking shell so the old routes cannot leak
## through the dense blocks while the facade kit is dressed in shared materials.
static func _old_moy_house(label: String, points: Array, storeys: int, kit: Dictionary, front_edge: int, palette_index: int) -> StaticBody3D:
	var height := float(storeys) * float(PLAN.TOWER_HOUSE.storey)
	var root := _polygon_building(label, points, height, _old_house_color(palette_index))
	root.set_meta("moy_p4_house", true)
	root.set_meta("moy_p4_tower_house", String(kit.get("kit", "tower")) == "tower")
	root.set_meta("moy_p4_kit", String(kit.get("kit", "tower")))
	if points.size() < 3:
		return root
	if String(kit.get("kit", "tower")) == "infill":
		var edge := int(kit.get("front_edge", front_edge))
		if edge < 0 or edge >= points.size(): edge = 0
		var ia := Vector2(points[edge][0], points[edge][1]); var ib := Vector2(points[(edge + 1) % points.size()][0], points[(edge + 1) % points.size()][1])
		var it := (ib - ia).normalized(); var io := Vector2(it.y, -it.x); var ic := (ia + ib) * 0.5
		var iw := ia.distance_to(ib); var tile_colors := [Color("#71949a"), Color("#b17e68"), Color("#c8ad78"), Color("#73907e")]
		for row in range(mini(8, storeys)):
			for col in range(maxi(1, int(iw / 1.2))):
				var along := (float(col) + 0.5) / float(maxi(1, int(iw / 1.2))) * iw - iw * 0.5
				var fc := ic + it * along + io * 0.06
				_add_old_face_box(root, Vector3(0.26, 0.24, 0.045), Vector3(fc.x, DATUM + 0.55 + float(row) * 1.0, fc.y), io, tile_colors[(row + col) % tile_colors.size()])
		_add_building_box_part(root, Vector3(0.9, height * 0.82, 0.16), Vector3(0, height * 0.55, 0), Color("#96b9c1"))
		return root
	if String(kit.get("kit", "tower")) != "tower": return root
	var base_kind := String(kit.get("base_kind", "stone"))
	var base_storeys := int(kit.get("base", 1))
	var base_height := minf(height - 3.0, float(PLAN.TOWER_HOUSE.plinth) + float(base_storeys) * (0.7 if base_kind == "stone" else 0.65))
	var a := Vector2(points[0][0], points[0][1]); var b := Vector2(points[1][0], points[1][1])
	if front_edge >= 0 and front_edge < points.size():
		a = Vector2(points[front_edge][0], points[front_edge][1]); b = Vector2(points[(front_edge + 1) % points.size()][0], points[(front_edge + 1) % points.size()][1])
	var tangent := (b - a).normalized(); var outward := Vector2(tangent.y, -tangent.x)
	var span := a.distance_to(b); var face_center := (a + b) * 0.5
	var wall_depth := 0.08
	# Material bands are separate scheduled courses and remain decorative here;
	# the continuous shell is the conservative player/party blocker.
	_add_old_face_box(root, Vector3(span * 0.94, base_height, wall_depth), Vector3(face_center.x, DATUM + base_height * 0.5, face_center.y), outward, Color("#625d54"))
	# The ground-floor leaf and its gypsum reveal are visible even though the
	# continuous shell remains the closed-door blocker in this exterior-only pass.
	var door_tint: Color = [Color("#416b79"), Color("#5d8060"), Color("#a87942")][palette_index % 3]
	var door_at := face_center + outward * 0.09
	_add_old_face_box(root, Vector3(1.17, 2.38, 0.045), Vector3(door_at.x, DATUM + 1.19, door_at.y), outward, door_tint)
	for dx in [-0.64, 0.64]:
		var jamb: Vector2 = door_at + tangent * dx
		_add_old_face_box(root, Vector3(0.12, 2.55, 0.08), Vector3(jamb.x, DATUM + 1.28, jamb.y), outward, Color("#eee7d8"))
	_add_old_face_box(root, Vector3(1.4, 0.12, 0.08), Vector3(door_at.x, DATUM + 2.52, door_at.y), outward, Color("#eee7d8"))
	_add_old_face_box(root, Vector3(0.32, 0.32, 0.035), Vector3(door_at.x, DATUM + 2.83, door_at.y), outward, Color("#c59b55"))
	var courses := int(floor((height - base_height) / float(PLAN.TOWER_HOUSE.storey)))
	for floor_i in range(maxi(1, courses)):
		var y0 := base_height + float(floor_i) * float(PLAN.TOWER_HOUSE.storey)
		var y := y0 + float(PLAN.TOWER_HOUSE.storey) * 0.55
		var window_count := maxi(1, int(floor(span / 2.4)))
		for wi in range(window_count):
			var xoff := (float(wi) + 0.5) / float(window_count) * span - span * 0.5
			var c := face_center + tangent * xoff + outward * 0.06
			_add_old_face_box(root, Vector3(0.7, 1.25, 0.06), Vector3(c.x, DATUM + y, c.y), outward, Color("#34434a"))
			_add_old_face_box(root, Vector3(0.78, 0.08, 0.1), Vector3(c.x, DATUM + y - 0.68, c.y), outward, Color("#eee7d8"))
		# White frieze and pale string course at each brick-floor datum.
		_add_old_face_box(root, Vector3(span * 0.96, 0.16, 0.10), Vector3(face_center.x, DATUM + y0 + float(PLAN.TOWER_HOUSE.storey), face_center.y), outward, Color("#eee7d8"))
	# A flat roof terrace, crenellated parapet, west-facing wind catcher and the
	# optional rooftop room follow kit flags. These are solid/landing shapes.
	_add_old_face_box(root, Vector3(span * 0.96, 0.16, 0.16), Vector3(face_center.x, DATUM + height + 0.08, face_center.y), outward, Color("#e4dac8"))
	_add_old_face_box(root, Vector3(span * 0.96, 0.65, 0.18), Vector3(face_center.x, DATUM + height + 0.48, face_center.y), outward, Color("#985e4c"))
	var merlon_count := maxi(2, int(span / 1.8))
	for mi in range(merlon_count):
		var mx := (float(mi) + 0.5) / float(merlon_count) * span - span * 0.5
		var mc := face_center + tangent * mx
		_add_building_box_part(root, Vector3(minf(0.6, span / float(merlon_count) * 0.7), 0.5, 0.24), Vector3(mc.x - root.position.x, height + 1.05, mc.y - root.position.z), Color("#985e4c"))
	_add_building_box_part(root, Vector3(1.6, 4.5, 1.2), Vector3(0, height + 2.5, -0.5), Color("#eee7d8"))
	if bool(kit.get("manzar", false)):
		_add_building_box_part(root, Vector3(4.0, 2.2, 4.5), Vector3(0, height + 1.1, 0), Color("#eee7d8"))
	StaticMerge.merge(root)
	return root


static func _front_edge_for_rect(front: String) -> int:
	# Corners are ordered SW, SE, NE, NW. Return the edge that faces the selected road.
	return 0 if front == "s" else (2 if front == "n" else (1 if front == "e" else 3))


static func _add_old_face_box(root: StaticBody3D, size: Vector3, center: Vector3, outward: Vector2, color: Color) -> void:
	var mesh := BoxMesh.new(); mesh.size = size
	var visual := MeshInstance3D.new(); visual.mesh = mesh; visual.position = center - root.position
	visual.rotation.y = -atan2(outward.y, outward.x) + PI * 0.5
	visual.material_override = _material(color); CollisionPolicy.mark_decorative(visual); root.add_child(visual)


static func _add_old_moy_shared_spaces(packs: Dictionary) -> void:
	for i in PLAN.OLD_TOWN.courts.size():
		var court: Dictionary = PLAN.OLD_TOWN.courts[i]
		var pts: Array = court.get("pts", [])
		if pts.size() < 3: continue
		var center := _polygon_center(pts)
		_add(packs, _cell(center), _poly_floor("OldMoyCourt_%02d" % i, pts, DATUM + 0.04, Color("#b9a586")))
		var bench := _box_body("OldMoyCourtBench_%02d" % i, Vector3(1.6, 0.5, 0.45), Vector3(center.x, DATUM + 0.28, center.y), Color("#765b42"))
		_add(packs, _cell(center), bench)
	for i in PLAN.OLD_TOWN.pockets.size():
		var pocket: Dictionary = PLAN.OLD_TOWN.pockets[i]
		var pts: Array = pocket.get("pts", [])
		if pts.size() < 3 or String(pocket.get("kind", "")) == "paving": continue
		var center := _polygon_center(pts)
		_add(packs, _cell(center), _poly_floor("OldMoyPocket_%02d" % i, pts, DATUM + 0.05, Color("#b9a586")))
		if String(pocket.get("kind", "")) in ["pocket", "yard"]:
			var bench := _box_body("OldMoyPocketBench_%02d" % i, Vector3(1.2, 0.45, 0.4), Vector3(center.x, DATUM + 0.25, center.y), Color("#765b42"))
			_add(packs, _cell(center), bench)
	for i in PLAN.OLD_TOWN.roof_links.size():
		var link: Dictionary = PLAN.OLD_TOWN.roof_links[i]
		var foot: Array = link.foot; var head: Array = link.head
		var start := Vector3(foot[0], DATUM + float(link.y[0]), foot[1])
		var finish := Vector3(head[0], DATUM + float(link.y[1]), head[1])
		var delta := finish - start
		var ramp := _box_body("OldMoyRoofRamp_%02d" % i, Vector3(float(link.w), 0.14, delta.length()), (start + finish) * 0.5, Color("#79563b"))
		ramp.rotation.y = atan2(delta.x, delta.z)
		ramp.rotation.x = -atan2(delta.y, Vector2(delta.x, delta.z).length())
		for child in ramp.get_children(): child.set_meta(CollisionPolicy.POLICY_META, CollisionPolicy.PARKOUR)
		# Paired timber rails follow the ramp's local run and stay with its
		# collider, leaving the 1.2 m walking strip clear between them.
		for side in [-1.0, 1.0]:
			var rail_size := Vector3(0.08, 0.9, delta.length())
			var rail_mesh := BoxMesh.new(); rail_mesh.size = rail_size
			var rail_visual := MeshInstance3D.new(); rail_visual.mesh = rail_mesh
			rail_visual.position = Vector3(side * (float(link.w) * 0.5 - 0.04), 0.52, 0.0)
			rail_visual.material_override = _material(Color("#76573f"))
			CollisionPolicy.mark_decorative(rail_visual); ramp.add_child(rail_visual)
			var rail_shape := BoxShape3D.new(); rail_shape.size = rail_size
			var rail_collision := CollisionShape3D.new(); rail_collision.shape = rail_shape
			rail_collision.position = rail_visual.position
			rail_collision.set_meta(CollisionPolicy.POLICY_META, CollisionPolicy.PARKOUR)
			ramp.add_child(rail_collision)
		_add(packs, _cell(Vector2((foot[0] + head[0]) * 0.5, (foot[1] + head[1]) * 0.5)), ramp)
	var first_square: Dictionary = PLAN.OLD_TOWN.squares[0]
	var well: Dictionary = first_square.get("first_well", {})
	if not well.is_empty():
		var head: Dictionary = well.get("head", {})
		var c: Array = head.get("c", [0.0, 0.0]); var center := Vector2(c[0], c[1])
		var well_body := _round_column("CinemaSquareFirstWell", float(head.get("r", 1.1)), float(head.get("h", 0.8)), Vector3(center.x, DATUM + float(head.get("h", 0.8)) * 0.5, center.y), Color("#77736b"))
		for child in well_body.get_children(): child.set_meta(CollisionPolicy.POLICY_META, CollisionPolicy.PARKOUR)
		_add(packs, _cell(center), well_body)


static func _polygon_center(points: Array) -> Vector2:
	var c := Vector2.ZERO
	for p in points: c += Vector2(p[0], p[1])
	return c / float(points.size())


static func _normalise_polygon_ring(points: Array) -> PackedVector2Array:
	var ring := PackedVector2Array()
	for point in points:
		ring.append(Vector2(float(point[0]), float(point[1])))
	if ring.size() < 3:
		return ring
	var area_twice := 0.0
	for i in ring.size():
		var a := ring[i]
		var b := ring[(i + 1) % ring.size()]
		area_twice += a.x * b.y - b.x * a.y
	# Geometry2D and the checks use Godot's clockwise-front convention:
	# (c - a) x (b - a). In our XZ plane, positive signed area makes the
	# emitted (a,b,c) top triangles face +Y under that convention.
	if area_twice < 0.0:
		ring.reverse()
	return ring


static func _poly_floor(label: String, points: Array, y: float, color: Color) -> StaticBody3D:
	var body := StaticBody3D.new(); body.name = label; body.collision_layer = 1; body.collision_mask = 1
	var center := _polygon_center(points); body.position = Vector3(center.x, y, center.y)
	var vertices := PackedVector2Array()
	for p in _normalise_polygon_ring(points): vertices.append(Vector2(p.x-center.x, p.y-center.y))
	var indices := Geometry2D.triangulate_polygon(vertices)
	var st := SurfaceTool.new(); st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for t in range(0, indices.size(), 3):
		var a: Vector2 = vertices[indices[t]]; var b: Vector2 = vertices[indices[t+1]]; var c: Vector2 = vertices[indices[t+2]]
		st.set_normal(Vector3.UP); st.add_vertex(Vector3(a.x,0,a.y)); st.add_vertex(Vector3(b.x,0,b.y)); st.add_vertex(Vector3(c.x,0,c.y))
	var mesh := st.commit(); mesh.surface_set_material(0,_material(color))
	var visual := MeshInstance3D.new(); visual.name = "PolygonFloorMesh"; visual.mesh=mesh; body.add_child(visual)
	var collision := CollisionShape3D.new(); collision.name = "PolygonFloorCollision"; collision.shape=mesh.create_trimesh_shape(); body.add_child(collision)
	return body


static func _polygon_building(label: String, points: Array, height: float, color: Color) -> StaticBody3D:
	var body := StaticBody3D.new(); body.name = label; body.collision_layer = 1; body.collision_mask = 1
	var center := _polygon_center(points); body.position = Vector3(center.x, DATUM, center.y)
	body.set_meta("polygon_points", points.duplicate(true))
	body.set_meta("polygon_height", height)
	var vertices := PackedVector2Array()
	for p in _normalise_polygon_ring(points): vertices.append(Vector2(p.x-center.x, p.y-center.y))
	var indices := Geometry2D.triangulate_polygon(vertices)
	var st := SurfaceTool.new(); st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for t in range(0, indices.size(), 3):
		var a: Vector2 = vertices[indices[t]]; var b: Vector2 = vertices[indices[t+1]]; var c: Vector2 = vertices[indices[t+2]]
		st.set_normal(Vector3.UP); st.add_vertex(Vector3(a.x,height,a.y)); st.add_vertex(Vector3(b.x,height,b.y)); st.add_vertex(Vector3(c.x,height,c.y))
		st.set_normal(Vector3.DOWN); st.add_vertex(Vector3(a.x,0,a.y)); st.add_vertex(Vector3(c.x,0,c.y)); st.add_vertex(Vector3(b.x,0,b.y))
	for i in vertices.size():
		var a: Vector2 = vertices[i]; var b: Vector2 = vertices[(i+1)%vertices.size()]
		var n := Vector3(b.y-a.y, 0, a.x-b.x).normalized()
		st.set_normal(n); st.add_vertex(Vector3(a.x,0,a.y)); st.add_vertex(Vector3(b.x,height,b.y)); st.add_vertex(Vector3(a.x,height,a.y))
		st.set_normal(n); st.add_vertex(Vector3(a.x,0,a.y)); st.add_vertex(Vector3(b.x,0,b.y)); st.add_vertex(Vector3(b.x,height,b.y))
	var mesh := st.commit(); mesh.surface_set_material(0, _material(color))
	var visual := MeshInstance3D.new(); visual.name = "PolygonBuildingMesh"; visual.mesh = mesh; body.add_child(visual)
	var collision := CollisionShape3D.new(); collision.name = "PolygonBuildingCollision"; collision.shape = mesh.create_trimesh_shape(); body.add_child(collision)
	return body


static func _landmark(b: Dictionary) -> Node3D:
	var r: Rect2 = b.rect; var h := float(b.height); var center := r.get_center(); var n := int(b.n)
	var palette := [Color("#d8c9ad"),Color("#b7c9c0"),Color("#d6b0a4"),Color("#b4c8d7"),Color("#bdc2c3")]
	var color: Color = palette[(n*3+1)%palette.size()]
	match n:
		12: color=Color("#e0e2d9") # pale wind-polished metal
		13: color=Color("#aaaead") # BLOCK's quiet windowless concrete
		14: color=Color("#aebfce")
		15: color=Color("#d2a99c")
		18,20,21,49,50,53: color=Color("#c6b99f")
		33,35: color=Color("#d5b188")
		37: color=Color("#d6c7a6")
		_: pass
	if n == 1:
		var body := Node3D.new(); body.name = "Building_1_GrandHotel"
		body.set_meta("closed_shell", true); body.set_meta("enterable", true)
		body.position = Vector3(center.x,DATUM,center.y)
		var entrance_target := Node3D.new(); entrance_target.name = "HotelPublicEntranceReachTarget"; entrance_target.position = Vector3(0,0,24); entrance_target.set_meta("reach_target",true); body.add_child(entrance_target)
		# Four separate podium wings keep the public atrium open at ground and Deck.
		for wing in [Vector4(-26,0,6,60),Vector4(26,0,6,60),Vector4(0,-30,46,6),Vector4(-12.7,30,20.6,6),Vector4(12.7,30,20.6,6)]:
			var wall := _box_body("HotelAtriumWing",Vector3(wing.z,44,wing.w),Vector3(wing.x,22,wing.y),color); body.add_child(wall)
		# Four moving leaves in the model's front entrance. The door stays a
		# separate body so the public entrance remains clear of the podium wings.
		var revolving:=AnimatableBody3D.new(); revolving.name="HotelRevolvingDoor"; revolving.position=Vector3(0,0,24); revolving.set_script(load("res://scripts/moy_hotel_revolving_door.gd"))
		var hub:=CylinderMesh.new(); hub.top_radius=0.18; hub.bottom_radius=0.18; hub.height=2.6; hub.radial_segments=12
		var hub_vis:=MeshInstance3D.new(); hub_vis.mesh=hub; hub_vis.position.y=1.3; hub_vis.material_override=_material(Color("#8f795b")); revolving.add_child(hub_vis)
		for leaf_i in 4:
			var leaf:=Node3D.new(); leaf.rotation.y=TAU*float(leaf_i)/4.0
			var panel_mesh:=BoxMesh.new(); panel_mesh.size=Vector3(1.22,2.45,0.07)
			var panel:=MeshInstance3D.new(); panel.mesh=panel_mesh; panel.position=Vector3(0.64,1.3,0); panel.material_override=_material(Color("#9ab6b4")); leaf.add_child(panel)
			var panel_shape:=BoxShape3D.new(); panel_shape.size=panel_mesh.size; var panel_col:=CollisionShape3D.new(); panel_col.shape=panel_shape; panel_col.position=panel.position; leaf.add_child(panel_col); revolving.add_child(leaf)
		body.add_child(revolving)
		for side in [-1.0,1.0]:
			var swing:=_box_body("HotelSwingDoorLeaf",Vector3(1.2,2.5,0.08),Vector3(side*2.05,1.25,24.0),Color("#9ab6b4")); body.add_child(swing)
		var tower_data: Dictionary = PLAN.HOTEL.tower
		var origin: Array = PLAN.HOTEL.origin
		var tower_center := _hotel_local(center, float(origin[0]), float(origin[1]), float(tower_data.c[0]), float(tower_data.c[1]))
		_hotel_tower_shell(body, tower_center, float(tower_data.r), float(tower_data.top), PLAN.HOTEL.lifts)
		var tower_glass:=StandardMaterial3D.new(); tower_glass.albedo_color=Color(0.58,0.72,0.72,0.22); tower_glass.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA; tower_glass.roughness=0.28
		for child in body.get_node("HotelTowerShellWithLiftClearances").get_children():
			if child is MeshInstance3D: (child as MeshInstance3D).material_override=tower_glass
		var rib_cfg: Array=tower_data.rib
		for rib_i in int(tower_data.ribs):
			var a:=TAU*float(rib_i)/float(tower_data.ribs); var rib:=_round_column("HotelTowerRib_%02d"%rib_i,float(rib_cfg[0])*0.5,float(tower_data.top),Vector3(tower_center.x+cos(a)*(float(tower_data.r)-0.12),float(tower_data.top)*0.5,tower_center.y+sin(a)*(float(tower_data.r)-0.12)),Color("#c5c5b5")); body.add_child(rib)
		var drum_data: Dictionary = PLAN.HOTEL.drum
		# The tank ring is a capped service band. Above it, the Windrose is a
		# glass lounge with forty fixed mullions and a slow turning light ring.
		var tank := CylinderMesh.new(); tank.top_radius=float(drum_data.r); tank.bottom_radius=float(drum_data.r); tank.height=float(drum_data.tank[1])-float(drum_data.tank[0]); tank.radial_segments=40
		var tank_vis := MeshInstance3D.new(); tank_vis.name="HotelTankDrum"; tank_vis.mesh=tank; tank_vis.position=Vector3(tower_center.x,(float(drum_data.tank[0])+float(drum_data.tank[1]))*0.5,tower_center.y); tank_vis.material_override=_material(Color("#a98a65")); body.add_child(tank_vis)
		var glass:=StandardMaterial3D.new(); glass.albedo_color=Color(0.48,0.70,0.72,0.27); glass.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA; glass.roughness=0.32
		var lounge_h:=float(drum_data.lounge[1])-float(drum_data.lounge[0]); var lounge_mesh:=CylinderMesh.new(); lounge_mesh.top_radius=float(drum_data.r); lounge_mesh.bottom_radius=float(drum_data.r); lounge_mesh.height=lounge_h; lounge_mesh.radial_segments=40
		var lounge:=MeshInstance3D.new(); lounge.name="HotelWindroseGlazing"; lounge.mesh=lounge_mesh; lounge.position=Vector3(tower_center.x,(float(drum_data.lounge[0])+float(drum_data.lounge[1]))*0.5,tower_center.y); lounge.material_override=glass; body.add_child(lounge)
		for rib_i in int(drum_data.mullions):
			var a:=TAU*float(rib_i)/float(drum_data.mullions); var mullion:=_round_column("HotelWindroseMullion_%02d"%rib_i,0.12,lounge_h,Vector3(tower_center.x+cos(a)*(float(drum_data.r)-0.12),(float(drum_data.lounge[0])+float(drum_data.lounge[1]))*0.5,tower_center.y+sin(a)*(float(drum_data.r)-0.12)),Color("#a98a65")); body.add_child(mullion)
		var ring_root:=Node3D.new(); ring_root.name="HotelWindroseTurningLight"; ring_root.position=Vector3(tower_center.x,float(drum_data.lounge[0])+0.6,tower_center.y); ring_root.set_script(load("res://scripts/moy_hotel_windrose.gd")); body.add_child(ring_root)
		var ring:=_annulus_visual("HotelWindroseLightRing",float(drum_data.r)-0.6,float(drum_data.r),64,0.16,0.0); ring_root.add_child(ring)
		# Forty ribs continue the tower rhythm through the tank and dome base.
		for rib_i in int(drum_data.ribs):
			var a:=TAU*float(rib_i)/float(drum_data.ribs); var rib:=_round_column("HotelDrumRib_%02d"%rib_i,0.22,float(drum_data.dome_top)-float(drum_data.tank[1]),Vector3(tower_center.x+cos(a)*(float(drum_data.r)-0.18),(float(drum_data.tank[1])+float(drum_data.dome_top))*0.5,tower_center.y+sin(a)*(float(drum_data.r)-0.18)),Color("#a98a65")); body.add_child(rib)
		return body
	if String(b.kind) == "estate":
		var body := StaticBody3D.new(); body.name="Building_%02d_%s" % [n,String(b.name).replace(" ","_")]; body.collision_layer=1; body.collision_mask=1
		body.position=Vector3(center.x,DATUM,center.y); body.rotation.y=-deg_to_rad(float(b.angle))
		var open_h := 4.0; var upper_h := h-open_h
		var upper_mesh := BoxMesh.new(); upper_mesh.size=Vector3(r.size.x,upper_h,r.size.y)
		var upper := MeshInstance3D.new(); upper.mesh=upper_mesh; upper.position.y=open_h+upper_h*0.5; upper.material_override=_material(color); body.add_child(upper)
		var upper_shape := BoxShape3D.new(); upper_shape.size=upper_mesh.size
		var upper_collision := CollisionShape3D.new(); upper_collision.shape=upper_shape; upper_collision.position=upper.position; body.add_child(upper_collision)
		for sx in [-1.0,1.0]:
			for sz in [-1.0,1.0]:
				var post := BoxMesh.new(); post.size=Vector3(1.1,open_h,1.1)
				var post_vis := MeshInstance3D.new(); post_vis.mesh=post; post_vis.position=Vector3(sx*(r.size.x*0.5-0.7),open_h*0.5,sz*(r.size.y*0.5-0.7)); post_vis.material_override=_material(color.darkened(0.12)); body.add_child(post_vis)
				var post_shape := BoxShape3D.new(); post_shape.size=post.size
				var post_collision := CollisionShape3D.new(); post_collision.shape=post_shape; post_collision.position=post_vis.position; body.add_child(post_collision)
		return body
	var body := _box_body("Building_%02d_%s" % [n,String(b.name).replace(" ","_")],Vector3(r.size.x,h,r.size.y),Vector3(center.x,DATUM+h*0.5,center.y),color)
	body.rotation.y = -deg_to_rad(float(b.angle))
	if String(b.form) == "twist":
		var shaft := CylinderMesh.new(); shaft.top_radius=12; shaft.bottom_radius=20; shaft.height=h; shaft.radial_segments=12
		var visual := MeshInstance3D.new(); visual.mesh=shaft; visual.position=Vector3(0,0,0); visual.rotation.y=body.rotation.y; visual.material_override=_material(Color("#bd9f79")); body.add_child(visual)
	elif String(b.form) == "capsule" or String(b.form) == "dune":
		var shaft := CylinderMesh.new(); shaft.top_radius=14 if String(b.form)=="capsule" else 10; shaft.bottom_radius=16; shaft.height=h; shaft.radial_segments=12
		var visual := MeshInstance3D.new(); visual.mesh=shaft; visual.position=Vector3.ZERO; visual.material_override=_material(Color("#c2a984")); body.add_child(visual)
	if n == 13:
		# Canted folded blades rise to the authored 212 m crown top.
		var crown_h := 62.0
		for sign in [-1.0,1.0]:
			var blade := _box_body("BLOCK_CantedBlade",Vector3(5,crown_h,54),Vector3(sign*8,h*0.5+crown_h*0.5,0),Color("#4e504a")); blade.rotation.z=sign*deg_to_rad(12); body.add_child(blade)
	if n == 12:
		# Windspire's authored 18 m crown rises from the 262 m shaft to +280 m.
		var crown := _box_body("WindspireCrown",Vector3(r.size.x+10,18,r.size.y+10),Vector3(0,h*0.5+9,0),Color("#9f8a6d")); body.add_child(crown)
	var roof_mesh := BoxMesh.new(); roof_mesh.size=Vector3(r.size.x,0.15,r.size.y)
	var roof := MeshInstance3D.new(); roof.mesh=roof_mesh; roof.position=Vector3(0,h*0.5-0.075,0); roof.rotation.y=body.rotation.y; roof.material_override=_material(color.lightened(0.17)); body.add_child(roof)
	return body


static func _add_hotel_public_interior(body: Node3D, hotel: Dictionary) -> void:
	var origin: Array=hotel.origin; var ox:=float(origin[0]); var oz:=float(origin[1]); var center:=Vector2(body.position.x,body.position.z)
	var floor_color:=Color("#c9b99d")
	# Forecourt, entrance hall and atrium floor follow HOTEL's rectangles.
	for record in [[hotel.forecourt,"HotelForecourt"],[hotel.entrance_hall,"HotelEntranceHall"]]:
		var q: Array=record[0]; var p0:=_hotel_local(center,ox,oz,float(q[0]),float(q[1])); var p1:=_hotel_local(center,ox,oz,float(q[2]),float(q[3]))
		var slab:=_box_body(String(record[1]),Vector3(p1.x-p0.x,0.24,p1.y-p0.y),Vector3((p0.x+p1.x)*0.5,0.12,(p0.y+p1.y)*0.5),floor_color); body.add_child(slab)
	# The desk and picture sign occupy their measured model positions in the atrium.
	var desk0:=_hotel_local(center,ox,oz,44.4,31.0); var desk1:=_hotel_local(center,ox,oz,45.4,45.0)
	var reception:=_box_body("HotelReceptionDesk",Vector3(desk1.x-desk0.x,1.1,desk1.y-desk0.y),Vector3((desk0.x+desk1.x)*0.5,0.55,(desk0.y+desk1.y)*0.5),Color("#806c52")); body.add_child(reception)
	var concierge:=_box_body("HotelConciergeDesk",Vector3(2.2,1.0,1.1),Vector3(desk0.x-1.5,0.5,(desk0.y+desk1.y)*0.5),Color("#927a5b")); body.add_child(concierge)
	var iris_stand:=_box_body("HotelIrisStand",Vector3(0.9,1.0,0.9),Vector3(desk0.x-3.2,0.5,(desk0.y+desk1.y)*0.5),Color("#b89d70")); body.add_child(iris_stand)
	var sign_center:=_hotel_local(center,ox,oz,26.0,56.5); var picture:=_box_body("HotelChandelierPictureSign",Vector3(2.0,1.6,0.12),Vector3(sign_center.x,4.8,sign_center.y),Color("#c5ad78")); body.add_child(picture)
	for x in range(2,51,4):
		var post_at:=_hotel_local(center,ox,oz,float(x),59.5); var post:=_round_column("HotelForecourtColonnadePost",0.32,6.5,Vector3(post_at.x,3.25,post_at.y),Color("#9e8e70")); body.add_child(post)
	# One pitched glass roof drains away from the tower. Four metre bronze
	# trusses carry the glazing; the high clerestory and front box gutter follow
	# the data elevations and leave the capsule slots in the cylindrical core.
	var sky: Dictionary=hotel.skylight; var skylight_glass_mat:=StandardMaterial3D.new(); skylight_glass_mat.albedo_color=Color(0.45,0.66,0.69,0.22); skylight_glass_mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA; skylight_glass_mat.roughness=0.2
	var skylight_body:=StaticBody3D.new(); skylight_body.name="HotelPitchedSkylight"; skylight_body.collision_layer=1; skylight_body.collision_mask=1; body.add_child(skylight_body)
	var z_high:=float(hotel.tower.c[1])-float(origin[1]); var z_low:=float(hotel.void.z_south)
	for sx in range(10,43,4):
		for zi in range(0,ceili((z_low-z_high)/4.0)):
			var za:=z_high+float(zi)*4.0; var zb:=minf(z_low,za+4.0); var ya:=lerpf(float(sky.high),float(sky.low),(za-z_high)/(z_low-z_high)); var yb:=lerpf(float(sky.high),float(sky.low),(zb-z_high)/(z_low-z_high)); var zm:=(za+zb)*0.5; var ym:=(ya+yb)*0.5
			var panel_mesh:=BoxMesh.new(); panel_mesh.size=Vector3(4.0,0.08,Vector2(4.0,zb-za).length()); var panel:=MeshInstance3D.new(); panel.name="HotelSkylightGlassPanel"; panel.mesh=panel_mesh; panel.position=Vector3(float(sx)-26.0,ym,zm-30.0); panel.rotation.x=atan2(ya-yb,zb-za); panel.material_override=skylight_glass_mat; skylight_body.add_child(panel)
			var panel_shape:=BoxShape3D.new(); panel_shape.size=panel_mesh.size; var panel_col:=CollisionShape3D.new(); panel_col.shape=panel_shape; panel_col.position=panel.position; panel_col.rotation=panel.rotation; skylight_body.add_child(panel_col)
	for zi in range(0,ceili((z_low-z_high)/float(sky.truss))+1):
		var z:=minf(z_low,z_high+float(zi)*float(sky.truss)); var y:=lerpf(float(sky.high),float(sky.low),(z-z_high)/(z_low-z_high)); var truss:=_segment_body("HotelSkylightTruss",Vector2(-16.0,z-30.0),Vector2(16.0,z-30.0),0.18,y-0.09,0.18,Color("#887753")); truss.rotation.x=0.0; body.add_child(truss)
	var high_louvre:=_box_body("HotelTowerLouvreBand",Vector3(32.0,0.8,0.28),Vector3(0.0,47.5,z_high-30.0),Color("#8b7959")); body.add_child(high_louvre)
	var front_gutter:=_box_body("HotelFrontBoxGutter",Vector3(32.0,0.9,0.42),Vector3(0.0,float(sky.low)-0.25,z_low-30.0),Color("#75694f")); body.add_child(front_gutter)
	var rain: Dictionary=hotel.rain; var cis: Dictionary=rain.cistern; var cr: Array=cis.rect; var cx:=(float(cr[0])+float(cr[2]))*0.5-26.0; var cz:=(float(cr[1])+float(cr[3]))*0.5-30.0; var cistern:=_box_body("HotelForecourtCistern",Vector3(float(cr[2])-float(cr[0]),float(cis.depth),float(cr[3])-float(cr[1])),Vector3(cx,-float(cis.depth)*0.5,cz),Color("#867b65")); body.add_child(cistern)
	for outlet in rain.outlets:
		var outlet_local:=_hotel_local(center,ox,oz,float(outlet[0]),float(outlet[1])); var downpipe:=_round_column("HotelRainOutletPipe",0.1,44.0,Vector3(outlet_local.x,22.0,outlet_local.y),Color("#81765e")); body.add_child(downpipe)
	var void_data: Dictionary=hotel.void; var left:=float(void_data.x[0])-26.0; var right:=float(void_data.x[1])-26.0
	var south:=float(void_data.z_north)-30.0; var north:=float(void_data.z_south)-30.0
	# Atrium floor under the 32 x 26 m void, with the rock garden at its authored centre.
	var atrium:=_box_body("HotelAtriumFloor",Vector3(32.0,0.24,north-south),Vector3(0,0.12,(south+north)*0.5),floor_color); body.add_child(atrium)
	var garden: Dictionary=hotel.rock_garden; var gc:=_hotel_local(center,ox,oz,float(garden.c[0]),float(garden.c[1]));
	var gravel:=_round_column("HotelRockGardenGravel",float(garden.r),0.14,Vector3(gc.x,0.07,gc.y),Color("#b9ad91")); body.add_child(gravel)
	# Six rocks and two trees follow the model's coordinates; no extra planting.
	var rocks: Array=[[-3.4,-2.0,0.9,1.6],[3.6,1.8,1.1,2.2],[-1.5,3.8,0.7,1.1],[2.2,-3.6,0.8,1.4],[-4.3,1.6,0.6,0.9],[4.4,-1.4,0.5,0.8]]
	for i in rocks.size():
		var q: Array=rocks[i]; var rock:=NatureProps.build_rock(float(q[2]),true); rock.name="HotelRockGardenStone_%02d"%i; rock.position=Vector3(gc.x+float(q[0]),0.12,gc.y+float(q[1])); rock.scale=Vector3(1.0,float(q[3])/(float(q[2])*2.0),0.8); body.add_child(rock)
	var pavilion: Array=garden.pavilion; var pavilion_base:=_box_body("HotelRockGardenPavilionBase",Vector3(float(pavilion[0])-0.4,0.35,float(pavilion[1])-0.4),Vector3(gc.x,0.28,gc.y),Color("#927956")); body.add_child(pavilion_base)
	for sx in [-1.0,1.0]:
		for sz in [-1.0,1.0]:
			var post:=_round_column("HotelRockGardenPavilionPost",0.14,float(pavilion[2])*0.8,Vector3(gc.x+sx*(float(pavilion[0])*0.5-0.3),float(pavilion[2])*0.4,gc.y+sz*(float(pavilion[1])*0.5-0.3)),Color("#866f4d")); body.add_child(post)
	var pavilion_roof:=_box_body("HotelRockGardenPavilionRoof",Vector3(float(pavilion[0])+1.2,0.28,float(pavilion[1])+1.2),Vector3(gc.x,float(pavilion[2])*0.8+0.2,gc.y),Color("#d0bd93")); body.add_child(pavilion_roof)
	for x in [13.2,38.8]:
		var tree_at:=_hotel_local(center,ox,oz,float(x),29.0); var planter:=_box_body("HotelRockGardenTreePlanter",Vector3(2.0,0.8,2.0),Vector3(tree_at.x,0.4,tree_at.y),Color("#b6a17e")); body.add_child(planter)
		var trunk:=_round_column("HotelRockGardenTreeTrunk",0.2,4.0,Vector3(tree_at.x,2.8,tree_at.y),Color("#795b3c")); body.add_child(trunk)
		var crown:=_box_body("HotelRockGardenTreeCrown",Vector3(4.4,3.2,4.4),Vector3(tree_at.x,5.0,tree_at.y),Color("#647e55")); body.add_child(crown)
	var pod: Dictionary=hotel.pod; var pc:=_hotel_local(center,ox,oz,float(pod.c[0]),float(pod.c[1])); var pod_body:=_box_body("HotelGardenPod",Vector3(5.0,3.2,5.0),Vector3(pc.x,1.7,pc.y),Color("#d9c6a4")); body.add_child(pod_body)
	# Decorative shallow runnel, segmented along the HOTEL survey polyline.
	var runnel: Array=hotel.runnel
	for i in runnel.size()-1:
		var a:=_hotel_local(center,ox,oz,float(runnel[i][0]),float(runnel[i][1])); var b:=_hotel_local(center,ox,oz,float(runnel[i+1][0]),float(runnel[i+1][1]))
		var channel:=_segment_body("HotelRunnelChannel_%02d"%i,a,b,1.1,0.02,0.09,Color("#9f9278")); body.add_child(channel)
		channel.get_child(0).scale.z=1.0
		var water_mesh:=BoxMesh.new(); water_mesh.size=Vector3(a.distance_to(b),0.07,0.6); var water:=MeshInstance3D.new(); water.name="HotelRunnelWater_%02d"%i; water.mesh=water_mesh; water.position=Vector3((a.x+b.x)*0.5,0.075,(a.y+b.y)*0.5); water.rotation.y=-atan2(b.y-a.y,b.x-a.x); water.material_override=_material(Color("#699eb1")); body.add_child(water)
	# Two ramp runs with intermediate landings, each end landing tied to the atrium and mezzanine.
	for ri in hotel.ramps.size():
		var ramp: Array=hotel.ramps[ri]
		var curve: Array=[]; var p0: Vector2=Vector2(float(ramp[0][0]),float(ramp[0][1])); var p1: Vector2=Vector2(float(ramp[1][0]),float(ramp[1][1])); var p2: Vector2=Vector2(float(ramp[2][0]),float(ramp[2][1])); var control:=2.0*p1-(p0+p2)*0.5
		for si in 18:
			var t0:=float(si)/18.0; var t1:=float(si+1)/18.0; var q0:=p0*(1.0-t0)*(1.0-t0)+control*2.0*(1.0-t0)*t0+p2*t0*t0; var q1:=p0*(1.0-t1)*(1.0-t1)+control*2.0*(1.0-t1)*t1+p2*t1*t1
			var a2:=_hotel_local(center,ox,oz,q0.x,q0.y); var b2:=_hotel_local(center,ox,oz,q1.x,q1.y); var y0:=6.5*t0; var y1:=6.5*t1
			var flight:=_ramp_body("HotelDoubleRamp_%d_%02d"%[ri,si],Vector3(a2.x,y0,a2.y),Vector3(b2.x,y1,b2.y),float(hotel.ramp_width),0.35,Color("#c9b99d")); body.add_child(flight)
			var lateral: Vector2=(b2-a2).normalized().orthogonal()
			for side in [-1.0,1.0]:
				var offset: Vector2=lateral*side*(float(hotel.ramp_width)*0.5-0.08)
				var rail:=_ramp_body("HotelRampGuard_%d_%02d_%d"%[ri,si,int(side)],Vector3(a2.x+offset.x,y0+0.9,a2.y+offset.y),Vector3(b2.x+offset.x,y1+0.9,b2.y+offset.y),0.12,0.12,Color("#a9c5c6")); body.add_child(rail)
		var foot:=_hotel_local(center,ox,oz,float(ramp[0][0]),float(ramp[0][1])); var bend:=_hotel_local(center,ox,oz,float(ramp[1][0]),float(ramp[1][1])); var head:=_hotel_local(center,ox,oz,float(ramp[2][0]),float(ramp[2][1]))
		for endpoint in [[foot,0.0],[head,6.5]]:
			var loc: Vector2=endpoint[0]; var yy:=float(endpoint[1]); var land:=_box_body("HotelRampLanding_%d_%.1f"%[ri,yy],Vector3(float(hotel.landing),0.28,float(hotel.landing)),Vector3(loc.x,yy-0.14,loc.y),floor_color); body.add_child(land)
		var support:=_round_column("HotelRampMidSupport_%d"%ri,0.5,3.0,Vector3(bend.x,1.5,bend.y),Color("#9b8c72")); body.add_child(support)
	# Mezzanine and levels 3–12: exact void dimensions, 2.4 m ledges, shifted with its lean.
	for level_index in 11:
		var level:=6.5 if level_index==0 else 11.5+float(level_index-1)*float(hotel.storey)
		var lean:=-float(void_data.lean)*float(maxi(0,level_index-1)); var s:=south+lean; var n:=north+lean
		for side in [-1.0,1.0]:
			var x0:=left-2.4 if side<0 else right; var x1:=left if side<0 else right+2.4
			var strip:=_box_body("HotelGallerySide_%02d_%d"%[level_index,int(side)],Vector3(2.4,0.3,n-s),Vector3((x0+x1)*0.5,level-0.15,(s+n)*0.5),Color("#c9b99d")); body.add_child(strip)
		for side in [-1.0,1.0]:
			var z0:=s-2.4 if side<0 else n; var z1:=s if side<0 else n+2.4
			var strip:=_box_body("HotelGalleryEnd_%02d_%d"%[level_index,int(side)],Vector3(right-left,0.3,2.4),Vector3((left+right)*0.5,level-0.15,(z0+z1)*0.5),Color("#c9b99d")); body.add_child(strip)
		# Inner-void guards on the four open edges.
		for edge in [Vector4(left, s, right, s),Vector4(left,n,right,n),Vector4(left,s,left,n),Vector4(right,s,right,n)]:
			var a3:=Vector2(edge.x,edge.y); var b3:=Vector2(edge.z,edge.w); var rail:=_segment_body("HotelGalleryVoidRail_%02d"%level_index,a3,b3,0.12,level,1.1,Color("#876d50")); body.add_child(rail)
		var planter:=_segment_body("HotelGalleryPlanterTrough_%02d"%level_index,Vector2(left,s),Vector2(right,s),0.42,level+1.05,0.22,Color("#667d52")); body.add_child(planter)
		var vine_mesh:=CylinderMesh.new(); vine_mesh.top_radius=0.035; vine_mesh.bottom_radius=0.025; vine_mesh.height=1.8; vine_mesh.radial_segments=5
		var vine_multi:=MultiMesh.new(); vine_multi.transform_format=MultiMesh.TRANSFORM_3D; vine_multi.mesh=vine_mesh; vine_multi.instance_count=9
		for vine_i in 9:
			var x:=lerpf(left+1.0,right-1.0,float(vine_i)/8.0); var drift:=0.16*sin(float(vine_i)*1.7+float(level_index)); vine_multi.set_instance_transform(vine_i,Transform3D(Basis.from_scale(Vector3.ONE),Vector3(x,level+0.12,s+drift)))
		var vines:=MultiMeshInstance3D.new(); vines.name="HotelGalleryHangingPlants_%02d"%level_index; vines.multimesh=vine_multi; vines.position=Vector3(0,0.0,0); vines.material_override=_material(Color("#607b50")); body.add_child(vines)
		# Closed room fronts define the opaque range beyond the walking ledges.
		# Door leaves replace short wall sections on both sides of each gallery.
		var door_positions:=PackedFloat32Array([s+5.0,n-5.0])
		for side in [-1.0,1.0]:
			var wall_x:=left-2.48 if side<0 else right+2.48
			var cuts:=PackedFloat32Array([s])
			for door_z in door_positions:
				cuts.append(door_z-0.65); cuts.append(door_z+0.65)
			cuts.append(n)
			for cut_i in range(0,cuts.size()-1,2):
				var z0:=cuts[cut_i]; var z1:=cuts[cut_i+1]
				if z1-z0<0.1: continue
				var wall:=_box_body("HotelGalleryRoomFront",Vector3(0.16,3.25,z1-z0),Vector3(wall_x,level+1.625,(z0+z1)*0.5),Color("#d2c4a8")); body.add_child(wall)
			for door_z in door_positions:
				var door:=_box_body("HotelGalleryClosedRoomDoor",Vector3(0.14,2.2,1.25),Vector3(wall_x,level+1.1,door_z),Color("#806b50")); body.add_child(door)
	# Direct mezzanine route to the authored skybridge and Deck door.
	var deck_landing:=_box_body("HotelDeckDoorSkybridgeLanding",Vector3(6.0,0.3,12.0),Vector3(-4.0,6.35,24.0),floor_color); body.add_child(deck_landing)
	# Chandelier arm and compact shared crystal multimesh (300 visible crystals at this prototype scale).
	var arm: Dictionary=hotel.arm; var chandelier: Dictionary=hotel.chandelier; var arm_root:=_hotel_local(center,ox,oz,26.0,float(arm.root_z)); var arm_tip:=_hotel_local(center,ox,oz,float(arm.tip[0]),float(arm.tip[1]))
	for i in 8:
		var t0:=float(i)/8.0; var t1:=float(i+1)/8.0; var a:=arm_root.lerp(arm_tip,t0); var b:=arm_root.lerp(arm_tip,t1); var depth0:=lerpf(float(arm.depth[0]),float(arm.depth[1]),t0); var depth1:=lerpf(float(arm.depth[0]),float(arm.depth[1]),t1); var middle_depth:=(depth0+depth1)*0.5
		var beam:=_ramp_body("HotelChandelierArm_%02d"%i,Vector3(a.x,float(arm.bottom)+depth0,a.y),Vector3(b.x,float(arm.bottom)+depth1,b.y),float(arm.width),middle_depth,Color("#777b78")); body.add_child(beam)
	for rope_i in int(arm.ropes):
		var offset:=float(rope_i)-float(arm.ropes-1)*0.5; var rope:=_round_column("HotelChandelierSuspensionRope_%02d"%rope_i,0.022,float(arm.bottom)-float(chandelier.bottom),Vector3(arm_tip.x+offset*0.18,(float(arm.bottom)+float(chandelier.bottom))*0.5,arm_tip.y),Color("#8a8b7d")); body.add_child(rope)
	var chandelier_center:=_hotel_local(center,ox,oz,float(chandelier.c[0]),float(chandelier.c[1])); var core:=_box_body("HotelChandelierCore",Vector3(1.2,float(chandelier.top)-float(chandelier.bottom),1.2),Vector3(chandelier_center.x,(float(chandelier.top)+float(chandelier.bottom))*0.5,chandelier_center.y),Color("#e8dba8")); body.add_child(core)
	var crystal:=BoxMesh.new(); crystal.size=Vector3(0.12,0.18,0.12); var multimesh:=MultiMesh.new(); multimesh.transform_format=MultiMesh.TRANSFORM_3D; multimesh.mesh=crystal; multimesh.instance_count=int(chandelier.crystals)
	for i in int(chandelier.crystals):
		var tier:=i%int(chandelier.tiers); var band:=i/int(chandelier.tiers); var count_per_tier:=int(chandelier.crystals)/int(chandelier.tiers); var angle:=TAU*float(band)/float(count_per_tier); var radius:=float(chandelier.r)*(0.48+0.1*float(tier)); var y:=lerpf(float(chandelier.bottom),float(chandelier.top),float(tier)/float(chandelier.tiers-1)); multimesh.set_instance_transform(i,Transform3D(Basis.IDENTITY,Vector3(cos(angle)*radius,y,sin(angle)*radius)))
	var crystals:=MultiMeshInstance3D.new(); crystals.name="HotelChandelierCrystals"; crystals.multimesh=multimesh; crystals.material_override=_material(Color("#fff0bb")); body.add_child(crystals)
	for tier in int(chandelier.tiers):
		var radius:=float(chandelier.r)*(0.45+0.1*float(tier)); var y:=lerpf(float(chandelier.bottom),float(chandelier.top),float(tier)/float(chandelier.tiers-1)); var ring:=_annulus_visual("HotelChandelierBronzeRing_%02d"%tier,radius-0.07,radius,64,0.1,y); ring.position.x=chandelier_center.x; ring.position.z=chandelier_center.y; ring.material_override=_material(Color("#9f8055")); body.add_child(ring)
	# Four manually called rideable glass capsules, three stops only.
	var lift_cfg: Dictionary=hotel.lifts
	for i in 4:
		var bearing:=deg_to_rad(float(lift_cfg.bearings[i])); var lift:=AnimatableBody3D.new(); lift.name="HotelCapsuleLift_%d"%i; lift.collision_layer=1; lift.collision_mask=1; lift.position=Vector3(float(lift_cfg.track)*cos(bearing),0.0,float(lift_cfg.track)*sin(bearing)-16.0); lift.rotation.y=PI*0.5-bearing; lift.set_script(load("res://scripts/moy_hotel_lift.gd")); lift.set("stop_levels",PackedFloat32Array([0.0,6.5,89.5])); lift.set("stop_names",PackedStringArray(["Atrium floor","Mezzanine","Level 27 — Party suite"])); lift.set("cab_depth",float(lift_cfg.depth))
		var deck:=BoxMesh.new(); deck.size=Vector3(2.6,0.25,float(lift_cfg.depth)); var deck_vis:=MeshInstance3D.new(); deck_vis.mesh=deck; deck_vis.material_override=_material(Color("#a7bdc4")); lift.add_child(deck_vis); var deck_shape:=BoxShape3D.new(); deck_shape.size=deck.size; var deck_col:=CollisionShape3D.new(); deck_col.shape=deck_shape; lift.add_child(deck_col)
		var glass_mat:=StandardMaterial3D.new(); glass_mat.albedo_color=Color(0.38,0.65,0.72,0.25); glass_mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
		for side in [-1.0,1.0]:
			var pane:=MeshInstance3D.new(); var pane_mesh:=BoxMesh.new(); pane_mesh.size=Vector3(0.08,2.7,float(lift_cfg.depth)); pane.mesh=pane_mesh; pane.position.x=side*1.3; pane.material_override=glass_mat; lift.add_child(pane)
		var back:=MeshInstance3D.new(); var back_mesh:=BoxMesh.new(); back_mesh.size=Vector3(2.6,2.7,0.08); back.mesh=back_mesh; back.position.z=-float(lift_cfg.depth)*0.5; back.material_override=glass_mat; lift.add_child(back); body.add_child(lift)
		var bulb_mesh:=SphereMesh.new(); bulb_mesh.radius=0.07; bulb_mesh.height=0.14; bulb_mesh.radial_segments=6; bulb_mesh.rings=3
		var bulb_multi:=MultiMesh.new(); bulb_multi.transform_format=MultiMesh.TRANSFORM_3D; bulb_multi.mesh=bulb_mesh; bulb_multi.instance_count=42
		for bulb_i in 42:
			var ring_i:=bulb_i/14; var bearing_i:=bulb_i%14; var angle:=TAU*float(bearing_i)/14.0; var y:=float([0.25,1.7,3.15][ring_i]); var radius:=0.8 if ring_i!=1 else 1.36; bulb_multi.set_instance_transform(bulb_i,Transform3D(Basis.IDENTITY,Vector3(cos(angle)*radius,y,sin(angle)*radius)))
		var bulbs:=MultiMeshInstance3D.new(); bulbs.name="HotelCapsuleBulbs_%d"%i; bulbs.multimesh=bulb_multi; bulbs.material_override=_material(Color("#e6d28a")); lift.add_child(bulbs)
		for stop_i in 3:
			var radial := Vector3(cos(bearing), 0.0, sin(bearing))
			var call_at := lift.position + Vector3.UP * float([0.0, 6.5, 89.5][stop_i]) + radial * (float(lift_cfg.depth) * 0.5 + 0.8)
			_add_moy_lift_call(body, lift, stop_i, String(["Atrium floor", "Mezzanine", "Level 27 — Party suite"][stop_i]), call_at)
	# Level 27 lobby and an empty south-facing party suite.
	var suite_y:=89.5; var corridor:=_annulus_body("HotelLevel27RingCorridor",5.5,7.3,64,0.3,suite_y); corridor.position.x=0.0; corridor.position.z=-16.0; body.add_child(corridor)
	var suite:=_box_body("HotelLevel27PartySuite",Vector3(16,0.3,10),Vector3(0,suite_y-0.15,21),Color("#c9b99d")); body.add_child(suite)
	for side in [-1.0,1.0]:
		var wall:=_box_body("HotelPartySuiteWall",Vector3(0.2,3.0,10),Vector3(side*8,suite_y+1.5,21),Color("#e6dac1")); body.add_child(wall)
	var park_window:=_box_body("HotelPartySuiteParkWindow",Vector3(10,2.4,0.14),Vector3(0,suite_y+1.5,26),Color(0.45,0.67,0.72,0.35)); _set_body_glass(park_window,Color(0.45,0.67,0.72,0.35)); body.add_child(park_window)

static func _hotel_local(center: Vector2, origin_x: float, origin_z: float, x: float, z: float) -> Vector2:
	return Vector2(origin_x+x-center.x,origin_z+z-center.y)


static func _hotel_tower_shell(parent: Node3D, center: Vector2, radius: float, height: float, lift_cfg: Dictionary) -> void:
	# Faceted collision shell leaves the authored full-height lift slots open;
	# the former cylinder collider sealed both the hotel interior and the exits.
	var shell := StaticBody3D.new()
	shell.name = "HotelTowerShellWithLiftClearances"
	shell.collision_layer = 1
	shell.collision_mask = 1
	var segments := 96
	var slot_half := atan2(float(lift_cfg.slot) * 0.5, radius)
	var bearing_values: Array = lift_cfg.bearings
	var material := _material(Color("#d1b78f"))
	for i in segments:
		var angle := TAU * (float(i) + 0.5) / float(segments)
		var in_slot := false
		for bearing_degrees in bearing_values:
			if absf(wrapf(angle - deg_to_rad(float(bearing_degrees)), -PI, PI)) <= slot_half + PI / float(segments):
				in_slot = true
				break
		if in_slot: continue
		var arc := TAU * radius / float(segments) * 1.02
		var panel_size := Vector3(0.42, height, arc)
		var angle_center := Vector3(center.x + cos(angle) * (radius - 0.21), height * 0.5, center.y + sin(angle) * (radius - 0.21))
		var panel_mesh := BoxMesh.new(); panel_mesh.size = panel_size
		var panel := MeshInstance3D.new(); panel.name = "HotelTowerWallPanel_%02d" % i; panel.mesh = panel_mesh; panel.position = angle_center; panel.rotation.y = -angle; panel.material_override = material; shell.add_child(panel)
		var shape := BoxShape3D.new(); shape.size = panel_size
		var collision := CollisionShape3D.new(); collision.shape = shape; collision.position = angle_center; collision.rotation.y = -angle; shell.add_child(collision)
	parent.add_child(shell)


static func _add_moy_lift_call(parent: Node3D, lift: Node, index: int, label: String, at: Vector3) -> void:
	var post := Node3D.new()
	post.name = "%s_Call_%s" % [lift.name, label.to_snake_case()]
	post.position = at
	post.set_meta("reach_target", true)
	post.set_meta("reach_link_id", String(lift.name))
	parent.add_child(post)
	CalderaLift._control_post(post, Vector3.ZERO)
	var area := Interactable.attach(post, "Call the lift", 1.2, func() -> void: lift.call("go_to", index), Callable(), Callable(), false, 1.5)
	area.position = Vector3(0.0, 1.0, 0.0)


static func _add_deck(packs: Dictionary, tree_templates: Dictionary) -> void:
	var level := DATUM + float(PLAN.DECK.level)
	# The authored paired columns carry each Deck run from terrain to its soffit.
	for column_index in PLAN.DECK.columns.size():
		var p: Array=PLAN.DECK.columns[column_index]
		var column_height:=float(PLAN.DECK.level)-float(PLAN.DECK.depth)
		var column:=_round_column("DeckColumn_%03d"%column_index,float(PLAN.DECK.col)*0.5,column_height,Vector3(float(p[0]),DATUM+column_height*0.5,float(p[1])),Color("#978b74"))
		_add(packs,_cell(Vector2(float(p[0]),float(p[1]))),column)
	for run in PLAN.DECK.runs:
		var pts: Array = run.pts
		for j in pts.size()-1:
			var a := Vector2(pts[j][0],pts[j][1]); var b := Vector2(pts[j+1][0],pts[j+1][1])
			var width := float(run.w)
			var depth:=float(PLAN.CROSSING.ring_depth) if String(run.name)=="Crossing Ring" else 0.9
			var bridge := _segment_body("Deck_%s_%d" % [run.name,j],a,b,width,level-depth,depth,Color("#b8a782"))
			_add(packs,_cell((a+b)*0.5),bridge)
	for parapet_index in PLAN.DECK.parapets.size():
		var seg: Array=PLAN.DECK.parapets[parapet_index]
		var a:=Vector2(float(seg[0]),float(seg[1])); var b:=Vector2(float(seg[2]),float(seg[3]))
		var kind:=String(seg[5]); var width:=0.12 if kind=="rail" else 0.08
		var rail:=_segment_body("DeckParapet_%03d_%s"%[parapet_index,kind],a,b,width,level,float(seg[4]),Color("#858c87") if kind=="rail" else Color("#a9c5c6"))
		_add(packs,_cell((a+b)*0.5),rail)
	for bed_i in PLAN.DECK.beds.size():
		var bed: Dictionary=PLAN.DECK.beds[bed_i]; var bed_root:=Node3D.new(); bed_root.name="DeckGardenBed_%02d"%bed_i
		var pts: Array=bed.pts
		bed_root.set_meta("plan_width",float(bed.w))
		for j in pts.size()-1:
			var a:=Vector2(pts[j][0],pts[j][1]); var b:=Vector2(pts[j+1][0],pts[j+1][1])
			var body:=_segment_body("DeckGardenBed_%02d_Segment_%03d"%[bed_i,j],a,b,float(bed.w),level,0.45,Color("#756f55"))
			bed_root.add_child(body)
		var bed_center:=Vector2(float(pts[0][0]),float(pts[0][1])); _add(packs,_cell(bed_center),bed_root)
	for i in PLAN.DECK.trees.size():
		var tree_data: Dictionary=PLAN.DECK.trees[i]; var c: Vector2=Vector2(tree_data.c[0],tree_data.c[1])
		var key:="round|%.2f|%s"%[float(tree_data.h),Color("#839568").to_html()]
		var tree:=_instance_tree(tree_templates,key,"round",float(tree_data.h),Color("#839568"),i); tree.name="DeckTree_%02d"%i; tree.position=Vector3(c.x,DATUM+float(tree_data.y),c.y)
		_add(packs,_cell(c),tree)
	for ramp in PLAN.DECK.ramps:
		var c: Vector2 = Vector2(ramp.c[0],ramp.c[1])
		var directions: Dictionary = {"n":Vector2(0,-1),"s":Vector2(0,1),"e":Vector2(1,0),"w":Vector2(-1,0)}
		var head_dir: Vector2 = directions[String(ramp.head)]
		var foot_dir: Vector2 = directions[String(ramp.foot)]
		var top := Vector3(c.x,DATUM+6.5,c.y)+Vector3(head_dir.x,0,head_dir.y)*5.6
		var mid := Vector3(c.x,DATUM+3.25,c.y)
		var bottom := Vector3(c.x,DATUM,c.y)+Vector3(foot_dir.x,0,foot_dir.y)*5.2
		top = Vector3(c.x,DATUM+6.5,c.y)+Vector3(head_dir.x,0,head_dir.y)*5.2
		var lower_flight := _ramp_body("DeckRamp_%s_lower" % ramp.name,bottom,mid,2.6,0.55,Color("#a99470"))
		var upper_flight := _ramp_body("DeckRamp_%s_upper" % ramp.name,mid,top,2.6,0.55,Color("#a99470"))
		var landing := _box_body("DeckRamp_%s_landing"%ramp.name,Vector3(3.8,0.35,3.8),mid,Color("#b6a17b"))
		var foot_landing:=_box_body("DeckRamp_%s_FootLanding"%ramp.name,Vector3(3.8,0.35,3.8),bottom-Vector3.UP*0.175,Color("#b6a17b"))
		var head_landing:=_box_body("DeckRamp_%s_HeadLanding"%ramp.name,Vector3(3.8,0.35,3.8),top-Vector3.UP*0.175,Color("#b6a17b"))
		for body in [lower_flight,upper_flight,landing,foot_landing,head_landing]: _add(packs,_cell(c),body)
	for escalator in PLAN.DECK.escalators:
		var f: Array=escalator.foot; var h: Array=escalator.head
		var foot:=Vector3(f[0],DATUM,f[1]); var head:=Vector3(h[0],DATUM+6.5,h[1])
		_add_escalator_pair(packs,"DeckEscalator_%s"%String(escalator.name),foot,head,2.6)
	for lift in PLAN.DECK.lifts:
		var c: Vector2=Vector2(lift.c[0],lift.c[1]); var radius:=float(lift.r)
		for sx in [-1.0,1.0]:
			for sz in [-1.0,1.0]:
				var post:=_box_body("DeckLiftGuide",Vector3(0.22,6.5,0.22),Vector3(c.x+sx*(radius-0.2),DATUM+3.25,c.y+sz*(radius-0.2)),Color("#9caaac")); _add(packs,_cell(c),post)
		var car:=AnimatableBody3D.new(); car.name="DeckLift_%s"%String(lift.name).replace(" ","_"); car.position=Vector3(c.x,DATUM,c.y); car.set_script(load("res://scripts/moy_lift_platform.gd")); car.set("base_height",DATUM); car.set("stop_levels",PackedFloat32Array([0.0,6.5])); car.set("stop_names",PackedStringArray(["Park ground","Deck"]))
		var platform:=BoxMesh.new(); platform.size=Vector3(radius*2,0.28,radius*2); var pv:=MeshInstance3D.new(); pv.mesh=platform; pv.material_override=_material(Color("#c7d1ce")); car.add_child(pv)
		var ps:=BoxShape3D.new(); ps.size=platform.size; var pc:=CollisionShape3D.new(); pc.shape=ps; car.add_child(pc); _add(packs,_cell(c),car)
		var controls := Node3D.new(); controls.name = "DeckLiftControls_%s" % String(lift.name).replace(" ", "_")
		_add_moy_lift_call(controls, car, 0, "Park ground", Vector3(c.x, DATUM, c.y + radius + 1.0))
		_add_moy_lift_call(controls, car, 1, "Deck", Vector3(c.x, DATUM + 6.5, c.y + radius + 1.0))
		_add(packs, _cell(c), controls)
	_add_crossing_towers(packs)


static func _add_wall(packs: Dictionary) -> void:
	var r := float(PLAN.WALL.r); var thick := float(PLAN.WALL.thick)
	for i in 64:
		var a := TAU*float(i)/64.0; var b := TAU*float(i+1)/64.0; var mid := (a+b)*0.5
		var p := Vector2(PLAN.CENTER.x+r*cos(mid),r*sin(mid))
		var open := false
		for gate in PLAN.WALL.gates:
			if Vector2(gate.p[0],gate.p[1]).distance_to(p) < 17.0: open=true
		if open: continue
		var body := _segment_body("RimWall_%02d"%i,Vector2(PLAN.CENTER.x+r*cos(a),r*sin(a)),Vector2(PLAN.CENTER.x+r*cos(b),r*sin(b)),thick,DATUM,12.0,Color("#8f8773"))
		_add(packs,_cell(p),body)


static func _add_park(packs: Dictionary, tree_templates: Dictionary) -> void:
	var playground: Dictionary = PLAN.PARK.playground
	for tower in playground.towers:
		var c := Vector2(tower[0],tower[1]); var h := float(tower[2]); var radius := float(tower[3])
		var body := _box_body("Playground_%s" % String(tower[4]),Vector3(radius*2,h,radius*2),Vector3(c.x,DATUM+h*0.5,c.y),Color("#d4ac69"))
		_add(packs,_cell(c),body)
	var lawn: Array=PLAN.PARK.lawn
	var lawn_rect:=Rect2(lawn[0],lawn[1],lawn[2]-lawn[0],lawn[3]-lawn[1])
	# Raise the turf above the plaza/open paving top to prevent z-fighting and
	# make the authored lawn read as grass instead of a pavement-coloured slab.
	var grass:=_box_body("ParkLawn",Vector3(lawn_rect.size.x,0.12,lawn_rect.size.y),Vector3(lawn_rect.get_center().x,DATUM+0.13,lawn_rect.get_center().y),Color("#65a66b"))
	_add(packs,_cell(lawn_rect.get_center()),grass)
	var dry: Array = PLAN.PARK.dry_garden
	var dry_rect := Rect2(float(dry[0]), float(dry[1]), float(dry[2]) - float(dry[0]), float(dry[3]) - float(dry[1]))
	var gravel := _box_body("ParkDryGardenGravel", Vector3(dry_rect.size.x, 0.035, dry_rect.size.y), Vector3(dry_rect.get_center().x, DATUM + 0.095, dry_rect.get_center().y), Color("#938269"))
	_add(packs, _cell(dry_rect.get_center()), gravel)
	var pond: Dictionary = PLAN.PARK.pond; var c := Vector2(pond.c[0],pond.c[1]); var r: Vector2 = Vector2(pond.r[0],pond.r[1])
	var water := MeshInstance3D.new(); water.name="MoyReedPondSurface"; var mesh := CylinderMesh.new(); mesh.top_radius=1; mesh.bottom_radius=1; mesh.height=0.002; mesh.radial_segments=96; water.mesh=mesh
	water.scale=Vector3(r.x,1,r.y); water.position=Vector3(c.x,DATUM+float(pond.surface),c.y)
	water.material_override=VillageWorks.water_material(); water.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var root := Node3D.new(); root.name="MoyReedPond"; root.add_child(water)
	root.set_meta("water_surface_y",DATUM+float(pond.surface)); root.set_meta("water_depth",float(pond.surface)-float(pond.bed[-1][1])); CollisionPolicy.mark_hazard(root)
	_add(packs,_cell(c),root)
	for i in PLAN.PARK.trees.size():
		var data: Dictionary=PLAN.PARK.trees[i]; var p: Vector2=Vector2(data.c[0],data.c[1]); var h:=float(data.h)
		var leaf_color:=Color("#81936a"); var kind:=String(data.kind); var key:="%s|%.2f|%s"%[kind,h,leaf_color.to_html()]
		var tree:=_instance_tree(tree_templates,key,kind,h,leaf_color,i)
		tree.name="ParkTree_%02d_%s"%[i,String(data.kind)]; tree.position=Vector3(p.x,DATUM,p.y); _add(packs,_cell(p),tree)
	var shrub_mesh_root:=NatureProps.build_bush(Color("#648756")); StaticMerge.merge(shrub_mesh_root)
	var shrub_mesh_instance:=shrub_mesh_root.get_child(0) as MeshInstance3D
	var shrub_mesh: Mesh=shrub_mesh_instance.mesh; var shrub_material: Material=shrub_mesh_instance.material_override
	shrub_mesh_root.free()
	var shrub_transforms: Dictionary={}; var shrub_counts: Dictionary={}
	for p in PLAN.PARK.shrubs:
		var pos:=Vector2(float(p[0]),float(p[1])); var cell:=_cell(pos)
		if not shrub_transforms.has(cell): shrub_transforms[cell]=[]; shrub_counts[cell]=0
		(shrub_transforms[cell] as Array).append(Transform3D(Basis.from_scale(Vector3(6.5,4.7,6.5)),Vector3(pos.x,DATUM,pos.y))); shrub_counts[cell]=int(shrub_counts[cell])+1
	_add_plant_multimeshes(packs,"ParkShrub",shrub_mesh,shrub_material,shrub_transforms,shrub_counts)
	var reed_mesh:=BoxMesh.new(); reed_mesh.size=Vector3(0.09,1.0,0.09); var reed_transforms: Dictionary={}; var reed_counts: Dictionary={}
	for data in PLAN.PARK.reeds:
		var p: Vector2=Vector2(data.c[0],data.c[1]); var cell:=_cell(p)
		if not reed_transforms.has(cell): reed_transforms[cell]=[]; reed_counts[cell]=0
		for stem in int(data.stems):
			var height:=float(data.h); var origin:=Vector3(p.x+(float(stem)-1.0)*0.16,DATUM+height*0.5,p.y)
			(reed_transforms[cell] as Array).append(Transform3D(Basis.from_scale(Vector3.ONE*Vector3(1,height,1)),origin))
		reed_counts[cell]=int(reed_counts[cell])+1
	_add_plant_multimeshes(packs,"ParkReedClump",reed_mesh,_material(Color("#758e58")),reed_transforms,reed_counts)
	for i in PLAN.PARK.rocks.size():
		var data: Dictionary=PLAN.PARK.rocks[i]; var p: Vector2=Vector2(data.c[0],data.c[1]); var half: Array=data.half
		var size:=Vector3(float(half[0])*2,float(half[1])*2,float(half[2])*2); var center:=Vector3(p.x,DATUM+float(half[1]),p.y)
		if float(half[1])>=1.0:
			_add(packs,_cell(p),_box_body("ParkRock_%02d"%i,size,center,Color("#777467")))
		else:
			var rock:=MeshInstance3D.new(); rock.name="ParkRock_%02d"%i; var rockmesh:=BoxMesh.new(); rockmesh.size=size; rock.mesh=rockmesh; rock.position=center; rock.material_override=_material(Color("#777467")); var holder:=Node3D.new(); holder.add_child(rock); _add(packs,_cell(p),holder)
	var agave_root:=Node3D.new()
	for leaf in 5:
		var blade:=MeshInstance3D.new(); var agavemesh:=BoxMesh.new(); agavemesh.size=Vector3(0.18,1.5,0.42); blade.mesh=agavemesh; blade.position=Vector3(0,0.72,0); blade.rotation.z=deg_to_rad(float(leaf-2)*20.0); blade.rotation.y=TAU*float(leaf)/5.0; blade.material_override=_material(Color("#80946c")); agave_root.add_child(blade)
	StaticMerge.merge(agave_root); var agave_instance:=agave_root.get_child(0) as MeshInstance3D; var agave_mesh:Mesh=agave_instance.mesh; var agave_material:Material=agave_instance.material_override; agave_root.free()
	var agave_transforms: Dictionary={}; var agave_counts: Dictionary={}
	for p in PLAN.PARK.agave:
		var pos:=Vector2(float(p[0]),float(p[1])); var cell:=_cell(pos)
		if not agave_transforms.has(cell): agave_transforms[cell]=[]; agave_counts[cell]=0
		(agave_transforms[cell] as Array).append(Transform3D(Basis.IDENTITY,Vector3(pos.x,DATUM,pos.y))); agave_counts[cell]=int(agave_counts[cell])+1
	_add_plant_multimeshes(packs,"ParkAgave",agave_mesh,agave_material,agave_transforms,agave_counts)


static func _add_plant_multimeshes(packs: Dictionary, item_name: String, mesh: Mesh, material: Material, transforms_by_cell: Dictionary, item_counts: Dictionary) -> void:
	for cell in transforms_by_cell:
		var transforms: Array=transforms_by_cell[cell]; var multimesh:=MultiMesh.new(); multimesh.transform_format=MultiMesh.TRANSFORM_3D; multimesh.mesh=mesh; multimesh.instance_count=transforms.size()
		var typed_transforms: Array[Transform3D]=[]
		for i in transforms.size():
			var transform: Transform3D=transforms[i]; multimesh.set_instance_transform(i,transform); typed_transforms.append(transform)
		_store_multimesh_buffer(multimesh,typed_transforms)
		var instance:=MultiMeshInstance3D.new(); instance.name="%sMultiMesh_%s"%[item_name,str(cell)]; instance.multimesh=multimesh; instance.custom_aabb=_multimesh_bounds(multimesh,typed_transforms); instance.material_override=material; instance.set_meta("moy_item_count",int(item_counts[cell])); CollisionPolicy.mark_decorative(instance)
		_add(packs,cell,instance)


static func _store_multimesh_buffer(multimesh: MultiMesh, transforms: Array[Transform3D], colors: Array[Color]=[]) -> void:
	var stride:=12+(4 if multimesh.use_colors else 0)+(4 if multimesh.use_custom_data else 0)
	var buffer:=PackedFloat32Array(); buffer.resize(transforms.size()*stride)
	for i in transforms.size():
		var t:=transforms[i]; var values: Array[float]=[t.basis.x.x,t.basis.y.x,t.basis.z.x,t.origin.x,t.basis.x.y,t.basis.y.y,t.basis.z.y,t.origin.y,t.basis.x.z,t.basis.y.z,t.basis.z.z,t.origin.z]
		for j in 12: buffer[i*stride+j]=values[j]
		var cursor:=i*stride+12
		if multimesh.use_colors:
			var color: Color=colors[i] if i<colors.size() else Color.WHITE
			buffer[cursor]=color.r; buffer[cursor+1]=color.g; buffer[cursor+2]=color.b; buffer[cursor+3]=color.a; cursor+=4
		if multimesh.use_custom_data:
			buffer[cursor]=0.0; buffer[cursor+1]=0.0; buffer[cursor+2]=0.0; buffer[cursor+3]=0.0
	multimesh.buffer=buffer


static func _multimesh_bounds(multimesh: MultiMesh, transforms: Array[Transform3D]) -> AABB:
	var mesh_bounds:=multimesh.mesh.get_aabb(); var bounds:=AABB()
	for i in transforms.size():
		var instance_bounds:=transforms[i]*mesh_bounds
		bounds=instance_bounds if i==0 else bounds.merge(instance_bounds)
	return bounds


static func _instance_tree(cache: Dictionary, key: String, kind: String, height: float, leaf: Color, seed_index: int) -> StaticBody3D:
	if not cache.has(key):
		var rng:=RandomNumberGenerator.new(); rng.seed=seed_index+1
		var template: StaticBody3D
		match kind:
			"round": template=NatureProps.build_round_tree(height,leaf)
			"flowering": template=NatureProps.build_flowering_tree(height,leaf,Color("#d96b45"),rng)
			"palm": template=NatureProps.build_palm_tree(height,0.0,rng)
			_: template=NatureProps.build_banyan_tree(height,rng)
		template.position=Vector3.ZERO; cache[key]=template
	return (cache[key] as StaticBody3D).duplicate() as StaticBody3D


static func _add_estate_links(packs: Dictionary) -> void:
	for i in PLAN.ESTATE.linkways.size():
		var link: Array = PLAN.ESTATE.linkways[i]
		for j in link.size()-1:
			var a := Vector2(link[j][0],link[j][1]); var b := Vector2(link[j+1][0],link[j+1][1])
			var body := _segment_body("EstateLink_%d_%d"%[i,j],a,b,3.0,DATUM+6.5,0.8,Color("#b3a27d"))
			_add(packs,_cell((a+b)*0.5),body)


static func _add_meridian_pier(packs: Dictionary, x: float, rail: float, pier_index: int) -> void:
	var stem_top:=DATUM+28.0; var rail_y:=DATUM+rail
	var stem:=_round_column("MeridianPierStem_%02d"%pier_index,1.2,(stem_top-DATUM),Vector3(x,DATUM+(stem_top-DATUM)*0.5,0),Color("#888173")); _add(packs,_cell(Vector2(x,0)),stem)
	for side_index in 2:
		var side: float=-1.0 if side_index==0 else 1.0
		var arm_foot:=Vector3(x,DATUM+25.5,0); var arm_head:=Vector3(x,DATUM+rail-1.2,side*2.7)
		var arm:=_ramp_body("MeridianPierYArm_%02d_%d"%[pier_index,side_index],arm_foot,arm_head,1.15,1.15,Color("#888173")); _add(packs,_cell(Vector2(x,0)),arm)
		var girder:=_box_body("MeridianBoxGirder_%02d_%d"%[pier_index,side_index],Vector3(36.0,1.2,1.0),Vector3(x,rail_y-1.2,side*1.7),Color("#77766f")); _add(packs,_cell(Vector2(x,0)),girder)
	# GREEN specifies a 2 m mesh sleeve from +2 to +28 m. Wrap four leafy
	# sheets around the actual pier stem; the vine geometry is decorative.
	for side in 4:
		var angle := float(side) * PI * 0.5
		var sleeve := _vine_sheet(1.8, 26.0, pier_index * 17 + side)
		sleeve.name = "MeridianVineSleeve_%02d_%d" % [pier_index, side]
		sleeve.position = Vector3(x + cos(angle) * 1.25, DATUM + 15.0, sin(angle) * 1.25)
		sleeve.rotation.y = PI * 0.5 - angle
		_add(packs, _cell(Vector2(x, 0.0)), sleeve)


static func _add_crossing_towers(packs: Dictionary) -> void:
	var cfg: Dictionary=PLAN.CROSSING; var tcfg: Dictionary=cfg.tower
	for ti in cfg.towers.size():
		var data: Dictionary=cfg.towers[ti]; var c: Vector2=Vector2(data.c[0],data.c[1]); var root:=Node3D.new(); root.name="CrossingTower_%02d"%ti; root.position=Vector3(c.x,DATUM,c.y)
		var trunk:=_round_column("CrossingTowerTrunk",float(tcfg.trunk),float(cfg.roof.y),Vector3(0,float(cfg.roof.y)*0.5,0),Color("#8e948d")); root.add_child(trunk)
		# A single continuous strip and collider per authored flight or landing.
		for hand in data.hands:
			var is_up:=String(hand.hand)=="up"
			for pi in hand.profile.size():
				var seg: Array=hand.profile[pi]; var a0:=deg_to_rad(float(seg[0])); var a1:=deg_to_rad(float(seg[1])); var y0:=float(seg[2]); var y1:=float(seg[3])
				var mesh:=_helix_closed_section_mesh(a0,a1,y0,y1,1.4,4.0,float(PLAN.ESCALATORS.section.depth),4.0)
				var body:=StaticBody3D.new(); body.name="CrossingHand_%02d_%s_%d"%[ti,String(hand.hand),pi]; body.collision_layer=1; body.collision_mask=1
				body.set_meta("walk_deck", true)
				body.set_meta("walk_run_id", "CrossingHelix_%02d_%s" % [ti, String(hand.hand)])
				if not is_equal_approx(y0,y1): body.set_meta("flight", true)
				var visual:=MeshInstance3D.new(); visual.name="CrossingHandDeck"; visual.mesh=mesh; visual.material_override=_material(Color("#aaa58f" if y1!=y0 else "#b5a783")); body.add_child(visual)
				var shape:=ConcavePolygonShape3D.new(); shape.set_faces(mesh.get_faces()); var collision:=CollisionShape3D.new(); collision.shape=shape; body.add_child(collision)
				if not is_equal_approx(y0,y1):
					body.set_script(load("res://scripts/moy_escalator.gd")); body.set("helix_center",Vector3.ZERO); body.set("helix_rise_per_radian",(y1-y0)/(a1-a0)); body.set("helix_direction",1.0 if is_up else -1.0); body.set("travel_speed",0.55)
					body.set_meta("helix_span",absf(a1-a0)); body.set_meta("helix_a0",a0); body.set_meta("helix_a1",a1); body.set_meta("helix_y0",y0); body.set_meta("helix_y1",y1); body.set_meta("helix_tread_radius",2.7)
					# Add a visible underside and side returns below the continuous
					# walking surface. They are visual only; the top remains the
					# sole collision surface for traversal and handovers.
					var belt_depth := float(PLAN.ESCALATORS.section.depth)
					var return_material := _material(Color("#454b4b"))
					var underside := MeshInstance3D.new(); underside.name = "HelixBelt_Return"
					underside.mesh = _helix_strip_mesh(a0,a1,y0-belt_depth,y1-belt_depth,1.4,4.0,0.2); underside.material_override = return_material; body.add_child(underside)
					var inner_side := MeshInstance3D.new(); inner_side.name = "HelixBelt_InnerEdge"
					inner_side.mesh = _helix_strip_mesh(a0,a1,y0-belt_depth,y1-belt_depth,1.4,1.52,0.2); inner_side.material_override = return_material; body.add_child(inner_side)
					var outer_side := MeshInstance3D.new(); outer_side.name = "HelixBelt_OuterEdge"
					outer_side.mesh = _helix_strip_mesh(a0,a1,y0-belt_depth,y1-belt_depth,3.88,4.0,0.2); outer_side.material_override = return_material; body.add_child(outer_side)
					var glass_material:=StandardMaterial3D.new(); glass_material.albedo_color=Color(0.48,0.68,0.72,0.24); glass_material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA; glass_material.roughness=0.2
					for rail_radius in [1.48,3.92]:
						var glass_mesh:=_helix_guard_mesh(a0,a1,y0,y1,rail_radius,float(PLAN.ESCALATORS.handrail.height),4.0)
						var glass_node:=MeshInstance3D.new(); glass_node.name="HelixGlassBalustrade"; glass_node.mesh=glass_mesh; glass_node.material_override=glass_material; body.add_child(glass_node)
						var glass_shape:=ConcavePolygonShape3D.new(); glass_shape.set_faces(glass_mesh.get_faces()); var glass_col:=CollisionShape3D.new(); glass_col.name="HelixGlassBalustradeCollision"; glass_col.shape=glass_shape; body.add_child(glass_col)
					var tread_material := _material(Color("#d7d8d1")); var tread_mesh := BoxMesh.new(); tread_mesh.size = Vector3(0.06,0.035,2.45)
					var tread_count := maxi(4, ceili(absf(a1-a0)*2.7/0.7))
					for tread_index in tread_count:
						var tread := MeshInstance3D.new(); tread.name = "HelixMovingTread_%02d" % tread_index; tread.mesh = tread_mesh; tread.material_override = tread_material
						var fraction := float(tread_index) / float(tread_count)
						if not is_up: fraction = 1.0 - fraction
						tread.set_meta("helix_fraction", fraction); tread.set_meta("helix_radius",2.7); tread.set_meta("helix_offset_y",0.05); tread.set_meta("underside_visual_only",true)
						var tread_angle := lerpf(a0,a1,fraction); var tread_y := lerpf(y0,y1,fraction)
						tread.position = Vector3(cos(tread_angle)*2.7,tread_y+0.05,sin(tread_angle)*2.7); tread.rotation.y = -tread_angle-PI*0.5; body.add_child(tread)
					for rail_radius in [1.48,3.92]:
						for rail_i in 2:
							var rail_belt:=MeshInstance3D.new(); rail_belt.name="HelixMovingRubberHandrail"; var rbm:=BoxMesh.new(); rbm.size=Vector3(0.72,0.09,0.13); rail_belt.mesh=rbm; rail_belt.material_override=_material(Color("#242827")); var fraction:=float(rail_i)*0.5; if not is_up: fraction=1.0-fraction; rail_belt.set_meta("helix_fraction",fraction); rail_belt.set_meta("helix_radius",rail_radius); rail_belt.set_meta("helix_offset_y",float(PLAN.ESCALATORS.handrail.height)); var ra:=lerpf(a0,a1,fraction); var ry:=lerpf(y0,y1,fraction)+float(PLAN.ESCALATORS.handrail.height); rail_belt.position=Vector3(cos(ra)*rail_radius,ry,sin(ra)*rail_radius); rail_belt.rotation.y=-ra-PI*0.5; body.add_child(rail_belt)
				root.add_child(body)
		for hand in data.hands:
			var hand_fill:=_helix_underfill("CrossingHandFill_%02d_%s"%[ti,String(hand.hand)],hand,float(PLAN.ESCALATORS.section.depth),float(tcfg.band[0]),float(tcfg.band[1]))
			if hand_fill!=null: root.add_child(hand_fill)
		for level in [6.5,14.2,37.0]:
			var inner_radius:=maxf(float(tcfg.gallery_r[0]),float(tcfg.gallery_clear))/cos(PI/48.0)
			var ann:=_annulus_body("CrossingGallery_%.1f"%level,inner_radius,float(tcfg.gallery_r[1]),48,1.0,level); root.add_child(ann)
			for rail_i in 36:
				var a_deg:=float(rail_i)*10.0; var b_deg:=float(rail_i+1)*10.0; var mid_deg:float=(a_deg+b_deg)*0.5
				if _crossing_hand_landing_open(data.hands,level,mid_deg) or _crossing_way_out_open(data.ways_out,level,mid_deg,float(tcfg.rail_r)): continue
				var rail_radius:=float(tcfg.rail_r)
				var a:=Vector2(c.x+cos(deg_to_rad(a_deg))*rail_radius,c.y+sin(deg_to_rad(a_deg))*rail_radius)
				var b:=Vector2(c.x+cos(deg_to_rad(b_deg))*rail_radius,c.y+sin(deg_to_rad(b_deg))*rail_radius)
				var rail:=_segment_body("CrossingGalleryInnerRail_%02d_%.1f_%02d"%[ti,level,rail_i],a,b,0.12,DATUM+level,1.1,Color("#80908a")); _add(packs,_cell(c),rail)
		for rib_i in int(tcfg.ribs):
			var angle:=TAU*(float(rib_i)+0.5)/float(tcfg.ribs); var rib:=_round_column("CrossingTowerRib_%02d"%rib_i,0.22,float(cfg.roof.y),Vector3(cos(angle)*float(tcfg.drum),float(cfg.roof.y)*0.5,sin(angle)*float(tcfg.drum)),Color("#a4aaa2")); root.add_child(rib)
		for ci in cfg.climbers.size():
			var climber: Array=cfg.climbers[ci]
			if int(climber[0])!=ti: continue
			var angle:=deg_to_rad(float(climber[1])); var y0:=float(climber[2]); var y1:=float(climber[3]); var width:=2.35
			# The plan's bearing is radial.  The panel width lies tangent to the
			# tower; using the bearing directly yawed it 90 degrees around the
			# drum and made the vines project outward instead of following the ribs.
			var panel := _vine_sheet(width, y1 - y0, 9000 + ci)
			panel.name = "CrossingClimberVineSheet_%03d" % ci
			panel.position = Vector3(cos(angle) * 6.02, (y0 + y1) * 0.5, sin(angle) * 6.02)
			panel.rotation.y = -angle - PI * 0.5
			root.add_child(panel)
			if y0>0:
				var planter:=_box_body("CrossingClimberPlanter_%03d"%ci,Vector3(0.55,0.5,0.8),Vector3(cos(angle)*5.55,y0+0.25,sin(angle)*5.55),Color("#746e54")); root.add_child(planter)
		for hoop_i in data.hoops.size():
			var hoop_level:=float(data.hoops[hoop_i])
			var hoop:=_annulus_visual("CrossingTowerHoop_%02d"%hoop_i,5.85,6.1,48,0.12,hoop_level); root.add_child(hoop)
		var lift_data: Dictionary=data.lift; var lc: Array=lift_data.c; var lift:=AnimatableBody3D.new(); lift.name="CrossingTowerLift"; lift.position=Vector3(float(lc[0])-c.x,0,float(lc[1])-c.y); lift.set_script(load("res://scripts/moy_lift_platform.gd")); lift.set("base_height",0.0)
		var tower_stops:=PackedFloat32Array(data.levels); tower_stops.append(float(cfg.dome.base)); lift.set("stop_levels",tower_stops); lift.set("stop_names",PackedStringArray(["Park ground", "Deck concourse", "City Hall level", "Meridian platform", "Clock Room"]))
		var liftmesh:=BoxMesh.new(); liftmesh.size=Vector3(2.6,0.22,2.6); var lv:=MeshInstance3D.new(); lv.mesh=liftmesh; lv.material_override=_material(Color("#bfd0ce")); lift.add_child(lv); var ls:=BoxShape3D.new(); ls.size=liftmesh.size; var lcol:=CollisionShape3D.new(); lcol.shape=ls; lift.add_child(lcol); root.add_child(lift)
		var lift_controls := Node3D.new(); lift_controls.name = "CrossingTowerLiftCalls"
		var lift_radial := Vector2(float(lc[0]) - c.x, float(lc[1]) - c.y).normalized()
		for stop_i in tower_stops.size():
			var level := float(tower_stops[stop_i])
			var call_at := Vector3(float(lc[0]) - c.x + lift_radial.x * 2.3, level, float(lc[1]) - c.y + lift_radial.y * 2.3)
			var label := String(["Park ground", "Deck concourse", "City Hall level", "Meridian platform", "Clock Room"][stop_i])
			_add_moy_lift_call(lift_controls, lift, stop_i, label, call_at)
		root.add_child(lift_controls)
		# The glazed shaft is visual only; four separate guide posts carry it
		# without sealing the lift or its landings with one tall collider.
		var shaft_center:=Vector3(float(lc[0])-c.x,20.2,float(lc[1])-c.y)
		var glass_material:=StandardMaterial3D.new(); glass_material.albedo_color=Color(0.55,0.72,0.75,0.22); glass_material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA; glass_material.roughness=0.18; glass_material.metallic=0.08
		for sx in [-1.0,1.0]:
			for sz in [-1.0,1.0]:
				var guide:=_box_body("CrossingLiftGuide",Vector3(0.12,40.4,0.12),shaft_center+Vector3(sx*1.3,0,sz*1.3),Color("#a6b7b7")); root.add_child(guide)
		for wall_side in 4:
			var pane:=MeshInstance3D.new(); pane.name="CrossingLiftGlass"; var glass:=BoxMesh.new(); glass.size=Vector3(2.5,40.0,0.04) if wall_side<2 else Vector3(0.04,40.0,2.5); pane.mesh=glass; pane.position=shaft_center+([Vector3(0,0,-1.3),Vector3(0,0,1.3),Vector3(-1.3,0,0),Vector3(1.3,0,0)][wall_side]); pane.material_override=glass_material; root.add_child(pane)
		# Data-directed clear connections from the gallery to the ring/bridges,
		# then onward to the exact line platform at each intermediate level.
		var ring_open:=Vector2(c.x-float(cfg.c[0]),c.y-float(cfg.c[1])).normalized()
		var ring_start:=c+ring_open*float(tcfg.gallery_r[1]); var ring_end:=Vector2(float(cfg.c[0]),float(cfg.c[1]))+ring_open*float(cfg.ring[0])
		_add_crossing_walkway(packs,"CrossingTower_%02d_RingLink"%ti,ring_start,ring_end,6.5,2.4,Color("#b6a782"))
		for run in PLAN.DECK.runs:
			if String(run.name)!="Crossing bridge north" and String(run.name)!="Crossing bridge south": continue
			var pts: Array=run.pts; var nearest:=_nearest_point_on_segment(c,Vector2(pts[0][0],pts[0][1]),Vector2(pts[-1][0],pts[-1][1]))
			if c.distance_to(nearest)<=float(tcfg.gallery_r[1])+0.25: _add_crossing_walkway(packs,"CrossingTower_%02d_CrossBridgeLink_%s"%[ti,String(run.name)],c+(nearest-c).normalized()*float(tcfg.gallery_r[1]),nearest,6.5,2.4,Color("#b6a782"))
		var spine_side:=1.0 if String(data.spine_platform)=="east" else -1.0
		var spine_target:=Vector2(float(cfg.c[0])+spine_side*_station_platform_offset(true),c.y)
		var spine_start:=c+Vector2(cos(deg_to_rad(float(data.opens["14.2"]))),sin(deg_to_rad(float(data.opens["14.2"]))))*float(tcfg.gallery_r[1])
		_add_crossing_walkway(packs,"CrossingTower_%02d_SpinePlatformBridge"%ti,spine_start,spine_target,14.2,2.4,Color("#b6a782"))
		var meridian_side:=1.0 if String(data.high_platform)=="south" else -1.0
		var meridian_target:=Vector2(float(cfg.c[0]),float(cfg.c[1])+meridian_side*_station_platform_offset(true))
		var meridian_start:=c+Vector2(cos(deg_to_rad(float(data.opens["37.0"]))),sin(deg_to_rad(float(data.opens["37.0"]))))*float(tcfg.gallery_r[1])
		_add_crossing_walkway(packs,"CrossingTower_%02d_MeridianPlatformBridge"%ti,meridian_start,meridian_target,37.0,2.4,Color("#b6a782"))
		var lift_world:=Vector2(float(lc[0]),float(lc[1])); var lift_direction:Vector2=(lift_world-c).normalized()
		for connection_level in [6.5,14.2,37.0]:
			_add_crossing_walkway(packs,"CrossingTower_%02d_LiftGallery_%0.1f"%[ti,connection_level],c+lift_direction*float(tcfg.gallery_r[1]),lift_world,connection_level,1.8,Color("#b6a782"))
		_add_crossing_walkway(packs,"CrossingTower_%02d_LiftSpineLanding"%ti,lift_world,spine_target,14.2,1.8,Color("#b6a782"))
		_add_crossing_walkway(packs,"CrossingTower_%02d_LiftMeridianLanding"%ti,lift_world,meridian_target,37.0,1.8,Color("#b6a782"))
		_add(packs,_cell(c),root)
	var roof_pts: Array=[]; var roof_cfg: Dictionary=cfg.roof; var roof_half:=float(roof_cfg.half); var exp:=float(roof_cfg.n)
	for ri in 64:
		var angle:=TAU*float(ri)/64.0; var cx:=cos(angle); var sz:=sin(angle)
		roof_pts.append([float(cfg.c[0])+roof_half*signf(cx)*pow(absf(cx),2.0/exp),float(cfg.c[1])+roof_half*signf(sz)*pow(absf(sz),2.0/exp)])
	var roof:=_polygon_building("CrossingRoof",roof_pts,float(roof_cfg.th),Color("#d2c7a7")); roof.position.y=DATUM+float(roof_cfg.y); _add(packs,_cell(Vector2(cfg.c[0],cfg.c[1])),roof)
	for beam_index in cfg._beams.spine.z.size():
		var z: float=cfg._beams.spine.z[beam_index]; var beam_y0:=float(cfg._beams.spine.y[0]); var beam_y1:=float(cfg._beams.spine.y[1])
		# One central span joins both ring girders and stays outside every helix band.
		var beam:=_box_body("CrossingSpineHeadBeam_%d"%beam_index,Vector3(14.8,beam_y1-beam_y0,1.6),Vector3(-560.0,DATUM+(beam_y0+beam_y1)*0.5,z),Color("#8d948b")); _add(packs,_cell(Vector2(-560.0,z)),beam)
	for beam_index in cfg._beams.high.x.size():
		var x: float=cfg._beams.high.x[beam_index]; var beam_y0:=float(cfg._beams.high.y[0]); var beam_y1:=float(cfg._beams.high.y[1])
		var beam:=_box_body("CrossingMeridianHeadBeam_%d"%beam_index,Vector3(1.6,beam_y1-beam_y0,14.8),Vector3(x,DATUM+(beam_y0+beam_y1)*0.5,0.0),Color("#8d948b")); _add(packs,_cell(Vector2(x,0.0)),beam)
	for garden_index in cfg.rain_gardens.size():
		var garden: Dictionary=cfg.rain_gardens[garden_index]; var gc:=Vector2(float(garden.c[0]),float(garden.c[1])); var ring:=_crossing_rain_garden(garden,garden_index); _add(packs,_cell(gc),ring)
		for path_index in garden.paths.size():
			var angle:=deg_to_rad(float(garden.paths[path_index])); var direction:=Vector2(cos(angle),sin(angle))
			var start:=gc+direction*float(garden.r_in); var finish:=gc+direction*float(garden.r)
			var path:=_segment_body("CrossingRainGardenPath_%02d_%02d"%[garden_index,path_index],start,finish,float(garden.path_width),DATUM-0.12,0.16,Color("#b9a586")); _add(packs,_cell(gc),path)
		for reed in garden.reeds:
			var rp:=Vector2(float(reed[0]),float(reed[1])); var clump:=Node3D.new(); clump.name="CrossingRainReeds_%0.2f_%0.2f"%[rp.x,rp.y]; clump.position=Vector3(rp.x,DATUM,rp.y)
			for ri in 3:
				var leafmesh:=BoxMesh.new(); leafmesh.size=Vector3(0.08,float(reed[2]),0.08); var leaf:=MeshInstance3D.new(); leaf.mesh=leafmesh; leaf.position.y=float(reed[2])*0.5; leaf.material_override=_material(Color("#7e945e")); clump.add_child(leaf)
			_add(packs,_cell(rp),clump)


static func _annulus_body(label: String, inner: float, outer: float, segments: int, thickness: float, y: float) -> StaticBody3D:
	var body:=StaticBody3D.new(); body.name=label; body.position.y=y-thickness*0.5; body.collision_layer=1; body.collision_mask=1
	var mesh:=_flat_annulus_mesh(inner,outer,segments,thickness)
	var vis:=MeshInstance3D.new(); vis.mesh=mesh; vis.material_override=_material(Color("#b6a580")); body.add_child(vis)
	var col:=CollisionShape3D.new(); var shape:=ConcavePolygonShape3D.new(); shape.set_faces(mesh.get_faces()); col.shape=shape; body.add_child(col)
	return body

static func _flat_annulus_mesh(inner: float, outer: float, segments: int, thickness: float) -> ArrayMesh:
	var st:=SurfaceTool.new(); st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in segments:
		var a:=TAU*float(i)/float(segments); var b:=TAU*float(i+1)/float(segments)
		var ia0:=Vector3(cos(a)*inner,-thickness*0.5,sin(a)*inner); var oa0:=Vector3(cos(a)*outer,-thickness*0.5,sin(a)*outer)
		var ia1:=Vector3(cos(b)*inner,-thickness*0.5,sin(b)*inner); var oa1:=Vector3(cos(b)*outer,-thickness*0.5,sin(b)*outer)
		var ib0:=ia0+Vector3.UP*thickness; var ob0:=oa0+Vector3.UP*thickness; var ib1:=ia1+Vector3.UP*thickness; var ob1:=oa1+Vector3.UP*thickness
		for tri in [[ib0,ob0,ob1],[ib0,ob1,ib1],[oa0,ia0,ia1],[oa0,ia1,oa1],[ob0,oa0,oa1],[ob0,oa1,ob1],[ia0,ib0,ib1],[ia0,ib1,ia1]]:
			for v in tri: st.add_vertex(v)
	return st.commit()

static func _helix_strip_mesh(a0: float,a1: float,y0: float,y1: float,r_inner: float,r_outer: float,step_degrees: float) -> ArrayMesh:
	var count:=maxi(1,ceili(absf(rad_to_deg(a1-a0))/step_degrees)); var st:=SurfaceTool.new(); st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in count:
		var f0:=float(i)/count; var f1:=float(i+1)/count; var aa:=lerpf(a0,a1,f0); var ab:=lerpf(a0,a1,f1); var ya:=lerpf(y0,y1,f0); var yb:=lerpf(y0,y1,f1)
		var p0:=Vector3(cos(aa)*r_inner,ya,sin(aa)*r_inner); var p1:=Vector3(cos(aa)*r_outer,ya,sin(aa)*r_outer); var q0:=Vector3(cos(ab)*r_inner,yb,sin(ab)*r_inner); var q1:=Vector3(cos(ab)*r_outer,yb,sin(ab)*r_outer)
		st.add_vertex(p0); st.add_vertex(p1); st.add_vertex(q1); st.add_vertex(p0); st.add_vertex(q1); st.add_vertex(q0)
	return st.commit()


static func _helix_closed_section_mesh(a0: float,a1: float,y0: float,y1: float,r_inner: float,r_outer: float,depth: float,step_degrees: float) -> ArrayMesh:
	var count:=maxi(1,ceili(absf(rad_to_deg(a1-a0))/step_degrees)); var st:=SurfaceTool.new(); st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in count:
		var f0:=float(i)/count; var f1:=float(i+1)/count; var aa:=lerpf(a0,a1,f0); var ab:=lerpf(a0,a1,f1); var ya:=lerpf(y0,y1,f0); var yb:=lerpf(y0,y1,f1)
		var ti0:=Vector3(cos(aa)*r_inner,ya,sin(aa)*r_inner); var to0:=Vector3(cos(aa)*r_outer,ya,sin(aa)*r_outer); var ti1:=Vector3(cos(ab)*r_inner,yb,sin(ab)*r_inner); var to1:=Vector3(cos(ab)*r_outer,yb,sin(ab)*r_outer)
		var bi0:=ti0-Vector3.UP*depth; var bo0:=to0-Vector3.UP*depth; var bi1:=ti1-Vector3.UP*depth; var bo1:=to1-Vector3.UP*depth
		for v in [ti0,to0,to1,ti0,to1,ti1,bi0,bi1,bo1,bi0,bo1,bo0,ti0,ti1,bi1,ti0,bi1,bi0,to0,bo0,bo1,to0,bo1,to1]: st.add_vertex(v)
		if i==0:
			for v in [ti0,bi0,bo0,ti0,bo0,to0]: st.add_vertex(v)
		if i==count-1:
			for v in [ti1,to1,bo1,ti1,bo1,bi1]: st.add_vertex(v)
	return st.commit()


static func _helix_guard_mesh(a0: float,a1: float,y0: float,y1: float,radius: float,height: float,step_degrees: float) -> ArrayMesh:
	var count:=maxi(1,ceili(absf(rad_to_deg(a1-a0))/step_degrees)); var st:=SurfaceTool.new(); st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in count:
		var f0:=float(i)/count; var f1:=float(i+1)/count; var aa:=lerpf(a0,a1,f0); var ab:=lerpf(a0,a1,f1); var ya:=lerpf(y0,y1,f0); var yb:=lerpf(y0,y1,f1)
		var a0v:=Vector3(cos(aa)*radius,ya,sin(aa)*radius); var b0v:=Vector3(cos(aa)*radius,ya+height,sin(aa)*radius); var a1v:=Vector3(cos(ab)*radius,yb,sin(ab)*radius); var b1v:=Vector3(cos(ab)*radius,yb+height,sin(ab)*radius)
		for v in [a0v,b0v,b1v,a0v,b1v,a1v]: st.add_vertex(v)
	return st.commit()


static func _crossing_hand_landing_open(hands: Array, level: float, bearing: float) -> bool:
	for hand in hands:
		for profile in hand.profile:
			if not is_equal_approx(float(profile[2]),level) or not is_equal_approx(float(profile[3]),level): continue
			var span:=fposmod(float(profile[1])-float(profile[0]),360.0)
			if fposmod(bearing-float(profile[0]),360.0)<=span: return true
	return false


static func _crossing_way_out_open(ways: Array, level: float, bearing: float, rail_radius: float) -> bool:
	for way in ways:
		if not is_equal_approx(float(way.y), level): continue
		var half_angle:=rad_to_deg(asin(clampf(float(way.width)*0.5/rail_radius,0.0,1.0)))+5.0
		if absf(wrapf(bearing-float(way.bearing)+180.0,0.0,360.0)-180.0)<=half_angle: return true
	return false


static func _nearest_point_on_segment(p: Vector2, a: Vector2, b: Vector2) -> Vector2:
	var delta:=b-a; var t:=clampf((p-a).dot(delta)/maxf(delta.length_squared(),0.001),0.0,1.0); return a+delta*t


static func _add_crossing_walkway(packs: Dictionary, label: String, a: Vector2, b: Vector2, level: float, width: float, color: Color) -> void:
	var direction:=b-a
	if direction.length()<0.05: return
	var walk:=_segment_body(label,a,b,width,DATUM+level-0.3,0.3,color)
	_add(packs,_cell((a+b)*0.5),walk)


static func _annulus_visual(label: String, inner: float, outer: float, segments: int, thickness: float, y: float) -> Node3D:
	var vis:=MeshInstance3D.new(); vis.name=label; vis.mesh=_flat_annulus_mesh(inner,outer,segments,thickness); vis.position.y=y; vis.material_override=_material(Color("#a4aaa2")); return vis


static func _add_transit(packs: Dictionary) -> void:
	for service in PLAN.CROSS.services:
		var line_name := String(service.line)
		var route := PackedVector3Array()
		for p in service.path: route.append(Vector3(p[0],DATUM+float(service.rail),p[1]))
		var lane_paths: Array[PackedVector3Array] = [PackedVector3Array(), PackedVector3Array()]
		for lane in 2:
			var offset := -float(PLAN.CROSS.track) if lane == 0 else float(PLAN.CROSS.track)
			for i in route.size():
				var before := route[maxi(0,i-1)]; var after := route[mini(route.size()-1,i+1)]
				var tangent := after-before; tangent.y=0.0
				var across := Vector3(-tangent.z,0.0,tangent.x).normalized()
				lane_paths[lane].append(route[i]+across*offset)
		for i in route.size()-1:
			var a:=route[i]; var b:=route[i+1]; var mid:=(a+b)*0.5
			var bed:=_ramp_body("%s_Track_%d"%[line_name,i],a-Vector3.UP*0.7,b-Vector3.UP*0.7,8.0,1.2,Color("#77766f"))
			_add(packs,_cell(Vector2(mid.x,mid.z)),bed)
			var tangent:=b-a; tangent.y=0.0; var across:=Vector3(-tangent.z,0.0,tangent.x).normalized()
			for lane in 2:
				var lane_offset:float=-float(PLAN.CROSS.track) if lane==0 else float(PLAN.CROSS.track)
				for rail_side in [-1.0,1.0]:
					var rail_offset:float=lane_offset+rail_side*0.7175
					var rail:=_ramp_body("%s_Rail_%d_%d_%d"%[line_name,i,lane,int(rail_side)],a+across*rail_offset,b+across*rail_offset,0.16,0.2,Color("#555b5d"))
					_add(packs,_cell(Vector2(mid.x,mid.z)),rail)
		var pier_xs: Array = service.get("piers", [])
		if not pier_xs.is_empty():
			for pier_index in pier_xs.size():
				_add_meridian_pier(packs,float(pier_xs[pier_index]),float(service.rail),pier_index)
		elif line_name == "Spine Line":
			for frame_index in service.frames.size():
				var frame: Array=service.frames[frame_index]
				var fx:=float(frame[0]); var fz:=float(frame[1]); var top:=DATUM+float(service.rail)-1.2
				if absf(fx-PLAN.CENTER.x)<1.0 and absf(fz)<20.0: continue
				for leg_index in 2:
					var xoff: float=-3.2 if leg_index==0 else 3.2
					var height:=top-DATUM
					var leg:=_box_body("SpineFrameLeg_%02d_%d"%[frame_index,leg_index],Vector3(0.9,height,0.9),Vector3(fx+xoff,DATUM+height*0.5,fz),Color("#938a78")); _add(packs,_cell(Vector2(fx+xoff,fz)),leg)
					var vine := _vine_sheet(0.84, height, 12000 + frame_index * 2 + leg_index)
					vine.name = "SpineFrameCoralVine_%02d_%d" % [frame_index, leg_index]
					vine.position = Vector3(fx + xoff, DATUM + height * 0.5, fz + 0.47)
					_add(packs, _cell(Vector2(fx + xoff, fz)), vine)
				var beam:=_box_body("SpineFrameBeam_%02d"%frame_index,Vector3(7.3,0.9,0.9),Vector3(fx,top-0.45,fz),Color("#938a78")); _add(packs,_cell(Vector2(fx,fz)),beam)
		for station in PLAN.CROSS.stations:
			if not station.lines.has(line_name): continue
			var p: Vector2=Vector2(station.at[0],station.at[1]); var plat := PLAN.CROSS.platform
			var station_y:=DATUM+float(station.get("rail",service.rail))+float(PLAN.PLATFORMS.floor)
			var along_z:=line_name=="Spine Line"
			var platform_offset:=_station_platform_offset(true)
			for side in [-1.0,1.0]:
				var platform_size:=Vector3(float(PLAN.PLATFORMS.width),0.3,plat[0]) if along_z else Vector3(plat[0],0.3,float(PLAN.PLATFORMS.width))
				var platform_center:=Vector3(p.x+(side*platform_offset if along_z else 0.0),station_y-0.15,p.y+(0.0 if along_z else side*platform_offset))
				var platform := _box_body("Station_%s_%s_%d"%[line_name,String(station.name).replace(" ","_"),int(side)],platform_size,platform_center,Color("#c4b18b")); _set_box_collision_margin(platform,0.0); platform.set_meta("reach_link_id",line_name)
				_add(packs,_cell(p),platform)
				var crossing_meridian:=String(station.name)=="The Crossing" and line_name=="Meridian Line"
				if not crossing_meridian:
					var canopy_size:=Vector3(platform_size.x,0.18,platform_size.z)
					var canopy:=_box_body("StationCanopy_%s_%s_%d"%[line_name,String(station.name).replace(" ","_"),int(side)],canopy_size,platform_center+Vector3.UP*(float(PLAN.PLATFORMS.canopy)+0.24),Color("#c0b99f")); _add(packs,_cell(p),canopy)
			if line_name=="Spine Line" and station.has("_interchange"):
				var outward:=signf(float(station.at[1])); var z0:=float(station.at[1])+outward*float(plat[0])*0.5; var gap:=float(station._interchange.gap)+0.3
				var slab_depth:=float(PLAN.PLATFORMS.floor); var slab_width:=2.0*(platform_offset+float(PLAN.PLATFORMS.width)*0.5)
				var slab:=_box_body("SpineWallInterchange",Vector3(slab_width,slab_depth,gap),Vector3(p.x,DATUM+float(service.rail)+slab_depth*0.5,z0+outward*gap*0.5),Color("#b6a17b")); _add(packs,_cell(Vector2(p.x,z0)),slab)
		if line_name=="Spine Line":
			for station in PLAN.CROSS.stations:
				if not station.has("_access"): continue
				for side_data in station._access:
					for flight_index in side_data.flights.size():
						var flight: Dictionary=side_data.flights[flight_index]
						var foot:=Vector3(flight.foot[0],DATUM+float(flight.foot[2]),flight.foot[1]); var head:=Vector3(flight.head[0],DATUM+float(flight.head[2]),flight.head[1])
						_add_escalator_pair(packs,"SpineAccess_%s_%s_%d"%[String(station.name).replace(" ","_"),String(side_data.side),flight_index],foot,head,float(flight.w))
						if side_data.has("runout") and flight_index==0:
							var runout: Dictionary=side_data.runout; var rp: Array=runout.c; var sz: Array=runout.size
							var slab:=_box_body("SpineAccessRunout",Vector3(sz[0],0.3,sz[1]),Vector3(rp[0],DATUM+float(runout.y)-0.15,rp[1]),Color("#b6a17b")); _add(packs,_cell(Vector2(rp[0],rp[1])),slab)
						if side_data.has("apron"):
							var ap: Dictionary=side_data.apron; var ac: Array=ap.c; var az: Array=ap.size
							var slab:=_box_body("SpineAccessApron",Vector3(az[0],0.35,az[1]),Vector3(ac[0],DATUM+float(ap.y)-0.175,ac[1]),Color("#b6a17b")); _add(packs,_cell(Vector2(ac[0],ac[1])),slab)
		var loop := false
		var path := route
		var stops := PackedVector3Array()
		for station in PLAN.CROSS.stations:
			if station.lines.has(line_name): stops.append(Vector3(station.at[0],DATUM+float(station.get("rail",service.rail)),station.at[1]))
		var line_plan: Dictionary=PLAN.TIMETABLE.lines.get(line_name,{})
		for train_index in int(line_plan.get("trains",1)):
			var lane:=mini(train_index,1); var lane_path:=lane_paths[lane]
			var train := _make_train(line_name,lane_path,int(PLAN.TRAIN.consists[line_name].cars),float(PLAN.CROSS.cars.speed),loop,stops,float(PLAN.TIMETABLE.dwell.ordinary),train_index,1 if train_index%2==0 else -1)
			train.set("schedule_events",line_plan.events); train.set("schedule_offset",float(line_plan.offset)); train.set("schedule_headway",float(PLAN.TIMETABLE.headway)); train.set("schedule_circuit",float(line_plan.circuit)); train.set("schedule_train_index",train_index)
			_add(packs,_cell(Vector2(path[0].x,path[0].z)),train)
	for core in PLAN.CROSSING.cores: _add_station_core(packs,core,"CrossingCore")
	for service in PLAN.CROSS.services:
		if String(service.line)=="Spine Line":
			for z in [-200.0,200.0]:
				var stop:=_box_body("SpineBufferStop",Vector3(8.0,0.8,1.0),Vector3(-560.0,DATUM+13.2,z),Color("#9c3428")); _add(packs,_cell(Vector2(-560,z)),stop)
	_add_wall_transit(packs)


static func _make_train(label: String, path: PackedVector3Array, cars: int, speed: float, loop: bool, stops := PackedVector3Array(), dwell := 4.0, lane := 0, direction := 1) -> Node3D:
	var train := Node3D.new(); train.name="MoyTrain_%s_%d"%[label.replace(" ","_"),lane]; train.set_script(load("res://scripts/moy_ride_train.gd"))
	train.set("service_name",label); train.set("path",path); train.set("cars",cars); train.set("speed",speed); train.set("loop",loop); train.set("stops",stops); train.set("dwell",dwell); train.set("initial_direction",direction)
	train.call("_build_consist")
	return train


static func _ramp_body(label: String, foot: Vector3, head: Vector3, width: float, thickness: float, color: Color) -> StaticBody3D:
	var delta := head-foot
	var x_axis := delta.normalized()
	var z_axis := Vector3(-x_axis.z,0.0,x_axis.x).normalized()
	var y_axis := z_axis.cross(x_axis).normalized()
	var body := _box_body(label,Vector3(delta.length(),thickness,width),(foot+head)*0.5,color)
	body.basis=Basis(x_axis,y_axis,z_axis)
	return body


static func _add_ramp_guardrails(body: StaticBody3D, width: float, length: float) -> void:
	for side in [-1.0,1.0]:
		_add_building_box_part(body,Vector3(length,0.9,0.12),Vector3(0.0,0.65,side*(width*0.5-0.06)),Color("#806f59"))


static func _add_escalator_pair(packs: Dictionary, label: String, foot: Vector3, head: Vector3, total_width: float, pad_sink: float = 0.0, pad_beyond: bool = false) -> void:
	var horizontal:=head-foot; horizontal.y=0.0
	var lateral:=Vector3(-horizontal.z,0.0,horizontal.x).normalized()
	if lateral.length_squared()<0.5: lateral=Vector3.RIGHT
	var belt_width:=minf(1.2,total_width*0.46)
	var a:=foot-lateral*belt_width*0.5; var b:=head-lateral*belt_width*0.5
	var up:=_ramp_body("%s_Up"%label,a,b,belt_width,float(PLAN.ESCALATORS.section.depth),Color("#b3a27e"))
	up.set_meta("flight", true); up.set_meta("walk_deck", true); up.set_meta("walk_run_id", "Escalator:%s" % label)
	up.set_script(load("res://scripts/moy_escalator.gd")); up.set("travel_direction",(b-a).normalized()); up.set("travel_speed",0.35)
	up.set("belt_length",(b-a).length()); up.set("belt_width",belt_width); up.set("belt_thickness",float(PLAN.ESCALATORS.section.depth))
	_add_escalator_belt_visuals(up, (b-a).length(), belt_width, float(PLAN.ESCALATORS.section.depth))
	_add_escalator_handrails(up,(b-a).length(),belt_width,float(PLAN.ESCALATORS.handrail.height))
	_add(packs,_cell(Vector2((a.x+b.x)*0.5,(a.z+b.z)*0.5)),up)
	var c:=foot+lateral*belt_width*0.5; var d:=head+lateral*belt_width*0.5
	var down:=_ramp_body("%s_Down"%label,d,c,belt_width,float(PLAN.ESCALATORS.section.depth),Color("#a49372"))
	down.set_meta("flight", true); down.set_meta("walk_deck", true); down.set_meta("walk_run_id", "Escalator:%s" % label)
	down.set_script(load("res://scripts/moy_escalator.gd")); down.set("travel_direction",(c-d).normalized()); down.set("travel_speed",0.35)
	down.set("belt_length",(c-d).length()); down.set("belt_width",belt_width); down.set("belt_thickness",float(PLAN.ESCALATORS.section.depth))
	_add_escalator_belt_visuals(down, (c-d).length(), belt_width, float(PLAN.ESCALATORS.section.depth))
	_add_escalator_handrails(down,(c-d).length(),belt_width,float(PLAN.ESCALATORS.handrail.height))
	_add(packs,_cell(Vector2((c.x+d.x)*0.5,(c.z+d.z)*0.5)),down)
	var along_z:=absf(horizontal.z)>absf(horizontal.x)
	var landing_size:=Vector3(total_width+0.6,0.3,2.4) if along_z else Vector3(2.4,0.3,total_width+0.6)
	for endpoint_i in 2:
		var endpoint: Vector3=foot if endpoint_i==0 else head
		# pad_beyond: a shallow pad just past the flight's end, on the deck it meets, not half under the belt box.
		var pad_center:=endpoint-Vector3.UP*(0.15+pad_sink); var pad_size:=landing_size
		if pad_beyond and horizontal.length_squared()>0.01:
			var outward:=horizontal.normalized()*(-1.0 if endpoint_i==0 else 1.0)
			pad_center+=outward*0.65
			if along_z: pad_size.z=1.2
			else: pad_size.x=1.2
		var landing:=_box_body("%s_Landing_%d"%[label,endpoint_i],pad_size,pad_center,Color("#b6a17b"))
		landing.set_meta("walk_deck", true); landing.set_meta("walk_run_id", "Escalator:%s" % label); landing.set_meta("reach_link_id", "Escalator:%s" % label)
		_add(packs,_cell(Vector2(endpoint.x,endpoint.z)),landing)
		if pad_beyond:
			landing.remove_meta("reach_target")
			var lane_target:=Node3D.new(); lane_target.name="ReachTarget"; lane_target.position=-lateral*belt_width*0.5; lane_target.set_meta("reach_target",true); landing.add_child(lane_target)


static func _add_escalator_handrails(body: StaticBody3D, length: float, width: float, height: float) -> void:
	var glass := StandardMaterial3D.new(); glass.albedo_color=Color(0.48,0.68,0.72,0.24); glass.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA; glass.roughness=0.2
	for side in [-1.0,1.0]:
		var z: float=side*(width*0.5-0.055)
		var size:=Vector3(length, height, 0.11)
		_add_building_box_part(body,size,Vector3(0.0,float(PLAN.ESCALATORS.section.depth)*0.5+height*0.5,z),Color(0.48,0.68,0.72,0.24))
		var pane:=body.get_child(body.get_child_count()-1) as MeshInstance3D; pane.name="EscalatorGlassBalustrade"; pane.material_override=glass
		var rubber:=StandardMaterial3D.new(); rubber.albedo_color=Color("#242827"); rubber.roughness=0.4
		for segment in 2:
			var belt:=MeshInstance3D.new(); belt.name="Moving_Rubber_Handrail_%d_%d"%[int(side),segment]; var mesh:=BoxMesh.new(); mesh.size=Vector3(0.75,0.09,0.13); belt.mesh=mesh; belt.material_override=rubber; belt.position=Vector3(-length*0.25+float(segment)*length*0.5,float(PLAN.ESCALATORS.section.depth)*0.5+height,z); belt.set_meta("handrail_distance",length*0.25+float(segment)*length*0.5); body.add_child(belt)
		for end in [-1.0,1.0]:
			_add_building_box_part(body,Vector3(0.22,0.9,0.22),Vector3(end*(length*0.5-0.15),float(PLAN.ESCALATORS.section.depth)*0.5+height*0.5,z),Color("#676b69"))


static func _add_escalator_belt_visuals(body: StaticBody3D, length: float, width: float, thickness: float) -> void:
	# The existing box remains the sole walking collider. This baked closed-loop
	# ribbon makes the return belt and rounded end turns visible without adding
	# collision that could snag the player below the steps.
	var side_material := _material(Color("#454b4b"))
	var ribbon := MeshInstance3D.new(); ribbon.name = "Belt_Return_And_End_Rolls"
	var st := SurfaceTool.new(); st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var radius := thickness * 0.5; var half := length * 0.5; var path := PackedVector2Array()
	var arc_steps := 8
	path.append(Vector2(-half, radius)); path.append(Vector2(half, radius))
	for i in range(1, arc_steps + 1):
		var angle := PI * 0.5 - PI * float(i) / float(arc_steps)
		path.append(Vector2(half + cos(angle) * radius, sin(angle) * radius))
	path.append(Vector2(-half, -radius))
	for i in range(1, arc_steps + 1):
		var angle := -PI * 0.5 - PI * float(i) / float(arc_steps)
		path.append(Vector2(-half + cos(angle) * radius, sin(angle) * radius))
	for i in path.size():
		var p0 := path[i]; var p1 := path[(i + 1) % path.size()]
		var a := Vector3(p0.x, p0.y, -width * 0.5); var b := Vector3(p0.x, p0.y, width * 0.5)
		var c := Vector3(p1.x, p1.y, width * 0.5); var d := Vector3(p1.x, p1.y, -width * 0.5)
		for vertex in [a, b, c, a, c, d]: st.add_vertex(vertex)
	ribbon.mesh = st.commit(); ribbon.material_override = side_material; body.add_child(ribbon)
	var tread_material := _material(Color("#d7d8d1"))
	var tread_mesh := BoxMesh.new(); tread_mesh.size = Vector3(0.055, 0.035, width * 0.88)
	var perimeter := 2.0 * length + PI * thickness
	var tread_count := maxi(8, ceili(perimeter / 0.7))
	for i in tread_count:
		var tread := MeshInstance3D.new(); tread.name = "Moving_Tread_%02d" % i
		tread.mesh = tread_mesh; tread.material_override = tread_material
		tread.set_meta("belt_distance", perimeter * float(i) / float(tread_count)); tread.set_meta("underside_visual_only",true)
		body.add_child(tread)


static func _vine_sheet(width: float, height: float, seed_value: int) -> MultiMeshInstance3D:
	# Reuse NatureProps' SuperEgg leaves, arranged as a dense sheet of its
	# actual jungle hanging vines. MultiMesh keeps the baked public city cheap.
	var rng := RandomNumberGenerator.new(); rng.seed = seed_value
	var prototype := NatureProps.build_hanging_vine(0.8, rng)
	var leaf := prototype.get_child(0) as MeshInstance3D
	var mesh := leaf.mesh
	var material := leaf.material_override
	prototype.free()
	var strand_count := maxi(2, ceili(width / 0.28))
	var segment_count := maxi(4, ceili(height / 0.18))
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = mesh
	multimesh.instance_count = strand_count * segment_count
	var instance := MultiMeshInstance3D.new(); instance.multimesh = multimesh
	instance.material_override = material
	var bounds := AABB(Vector3(-width * 0.5 - 0.2, -height * 0.5 - 0.1, -0.12), Vector3(width + 0.4, height + 0.2, 0.24))
	instance.custom_aabb = bounds
	for strand in strand_count:
		var x := lerpf(-width * 0.5, width * 0.5, float(strand) / float(strand_count - 1))
		var phase := rng.randf_range(0.0, TAU)
		for segment in segment_count:
			var y := height * 0.5 - 0.09 - float(segment) * 0.18
			var sway := sin(float(segment) * 0.9 + phase) * 0.03
			var transform := Transform3D(Basis(Vector3.BACK, sway * 2.0), Vector3(x + sway, y, 0.0))
			multimesh.set_instance_transform(strand * segment_count + segment, transform)
	return instance


static func _add_station_core(packs: Dictionary, core: Dictionary, prefix: String) -> void:
	var c:=Vector2(core.c[0],core.c[1]); var sx:=float(core.size[0]); var sz:=float(core.size[1])
	var levels: Array=core.levels; var max_level:=float(levels[-1]); var frame_height:=max_level+float(core.canopy)
	var post_index:=0
	for xside in [-1.0,1.0]:
		for zside in [-1.0,1.0]:
			var post:=_box_body("%s_%s_Frame_%d"%[prefix,String(core.name).replace(" ","_"),post_index],Vector3(0.45,frame_height,0.45),Vector3(c.x+xside*(sx*0.5-0.25),DATUM+frame_height*0.5,c.y+zside*(sz*0.5-0.25)),Color("#a99a79")); post_index+=1
			_add(packs,_cell(c),post)
	var flights: Array=core.flights
	var p:=-(sz*0.5-1.5); var direction:=1.0
	for i in flights.size():
		var flight: Array=flights[i]; var low:=DATUM+float(flight[0]); var high:=DATUM+float(flight[1]); var run:=float(flight[2])
		var q:=p+direction*run
		# Match the drawing's accumulating switchback: each flight starts where
		# the previous ended, then reverses direction on the next run.
		var foot:=Vector3(c.x,low,c.y+p)
		var head:=Vector3(c.x,high,c.y+q)
		_add_escalator_pair(packs,"%s_%s_Flight_%02d"%[prefix,String(core.name).replace(" ","_"),i],foot,head,2.6)
		var landing_z:=q+direction*0.75
		var landing:=_box_body("%s_%s_Landing_%02d"%[prefix,String(core.name).replace(" ","_"),i],Vector3(3.6,0.35,1.5),Vector3(c.x,high-0.175,c.y+landing_z),Color("#baa781"))
		_add(packs,_cell(Vector2(c.x,c.y+landing_z)),landing)
		var canopy:=_ramp_body("%s_%s_Canopy_%02d"%[prefix,String(core.name).replace(" ","_"),i],foot+Vector3.UP*float(core.canopy),head+Vector3.UP*float(core.canopy),2.9,0.16,Color("#9c927d"))
		_add(packs,_cell(Vector2(c.x,c.y)),canopy)
		p=q; direction=-direction
	# Two small public lift platforms share each open-air core with the ramps.
	for side_index in 2:
		var side: float=-1.0 if side_index==0 else 1.0
		var lift_x:float=c.x+side*(sx*0.5-1.0)
		var car:=AnimatableBody3D.new(); car.name="%s_%s_Lift_%d"%[prefix,String(core.name).replace(" ","_"),side_index]
		car.position=Vector3(lift_x,DATUM,c.y); car.set_script(load("res://scripts/moy_lift_platform.gd"))
		car.set("base_height",DATUM); car.set("stop_levels",PackedFloat32Array([0.0,max_level])); car.set("stop_names",PackedStringArray(["Station ground", "Station deck"]))
		var mesh:=BoxMesh.new(); mesh.size=Vector3(1.5,0.25,1.5); var vis:=MeshInstance3D.new(); vis.mesh=mesh; vis.material_override=_material(Color("#c7d1ce")); car.add_child(vis)
		var shape:=BoxShape3D.new(); shape.size=mesh.size; var col:=CollisionShape3D.new(); col.shape=shape; car.add_child(col)
		_add(packs,_cell(c),car)
		var controls := Node3D.new(); controls.name = "%s_%s_LiftControls_%d" % [prefix, String(core.name).replace(" ", "_"), side_index]
		_add_moy_lift_call(controls, car, 0, "Station ground", Vector3(lift_x + side * 2.1, DATUM, c.y))
		_add_moy_lift_call(controls, car, 1, "Station deck", Vector3(lift_x + side * 2.1, DATUM + max_level, c.y))
		_add(packs, _cell(c), controls)


static func _add_gate_forms(packs: Dictionary) -> void:
	var color:=Color("#b39b73")
	for leg in PLAN.ARCH.legs:
		var r:=Rect2(float(leg[0]),float(leg[1]),float(leg[2])-float(leg[0]),float(leg[3])-float(leg[1])); var center:=r.get_center()
		# Open six-metre public halls at both feet; corner piers carry the upper leg.
		for sx in [-1.0,1.0]:
			for sz in [-1.0,1.0]: _add(packs,_cell(center),_box_body("MeridianArchPublicHallPier",Vector3(3.0,6.0,3.0),Vector3(center.x+sx*(r.size.x*0.5-1.5),DATUM+3.0,center.y+sz*(r.size.y*0.5-1.5)),color))
		_add(packs,_cell(center),_box_body("MeridianArchPublicHallLintel",Vector3(r.size.x,1.0,r.size.y),Vector3(center.x,DATUM+6.5,center.y),color))
		_add(packs,_cell(center),_box_body("MeridianArchLegUpper",Vector3(r.size.x,51.0,r.size.y),Vector3(center.x,DATUM+46.5,center.y),color))
		# Plan train_hall.arc defines the actual wall openings; leave the 12–21 m band clear through each data-defined leg.
		var hall: Dictionary=PLAN.ARCH.train_hall; var hall_index:=0 if center.y<0 else 1; var bounds: Array=hall.x[hall_index]
		var left_width:=maxf(0.0,float(bounds[0])-r.position.x); var right_start:=minf(r.size.x,float(bounds[1])-r.position.x)
		# The east wall of the band is the outer platform's place: city.md puts the outer pair down the leg's east side and its landing inside the leg
		# (ARCH.front.legs.outer_landing, x -347.04 to -342.2). A solid pier there swallows both, so only the west wall stands.
		for part in [Rect2(r.position.x,r.position.y,left_width,r.size.y)]:
			if part.size.x>0.1: _add(packs,_cell(center),_box_body("MeridianArchTrainHallPier",Vector3(part.size.x,9.0,part.size.y),Vector3(part.get_center().x,DATUM+16.5,part.get_center().y),color))
	var east_leg: Array=PLAN.ARCH.legs[0]
	_add_bridge_station(packs,"MeridianArch",float(PLAN.ARCH.lower[0]),float(PLAN.ARCH.lower[1]),float(east_leg[0]),float(east_leg[2]),float(PLAN.ARCH.opening))
	var top_levels: Array=PLAN.ARCH.top; var top_body:=_box_body("MeridianArchTopBridge",Vector3(PLAN.ARCH.opening,float(top_levels[1])-float(top_levels[0]),6.0),Vector3(-352.5,DATUM+(float(top_levels[0])+float(top_levels[1]))*0.5,0),color); _add(packs,_cell(Vector2(-352.5,0)),top_body)
	var west_towers: Array=PLAN.WEST_GATE.towers
	for i in west_towers.size():
		var t: Array=west_towers[i]; var r:=Rect2(float(t[0]),float(t[1]),float(t[2])-float(t[0]),float(t[3])-float(t[1])); var c:=r.get_center(); var hall:=PLAN.WEST_GATE.train_hall; var bounds: Array=hall.x[i]
		for sx in [-1.0,1.0]:
			for sz in [-1.0,1.0]: _add(packs,_cell(c),_box_body("WestGatePassagePier",Vector3(3.0,6.0,3.0),Vector3(c.x+sx*(r.size.x*0.5-1.5),DATUM+3,c.y+sz*(r.size.y*0.5-1.5)),Color("#a78b64")))
		_add(packs,_cell(c),_box_body("WestGatePassageLintel",Vector3(r.size.x,1.0,r.size.y),Vector3(c.x,DATUM+6.5,c.y),Color("#a78b64")))
		_add(packs,_cell(c),_box_body("WestGateTowerUpper",Vector3(r.size.x,23.0,r.size.y),Vector3(c.x,DATUM+32.5,c.y),Color("#a78b64")))
		var left_width:=maxf(0.0,float(bounds[0])-r.position.x); var right_start:=minf(r.size.x,float(bounds[1])-r.position.x)
		for part in [Rect2(r.position.x,r.position.y,left_width,r.size.y),Rect2(r.position.x+right_start,r.position.y,r.size.x-right_start,r.size.y)]:
			if part.size.x>0.1: _add(packs,_cell(c),_box_body("WestGateTrainHallPier",Vector3(part.size.x,9.0,part.size.y),Vector3(part.get_center().x,DATUM+16.5,c.y),Color("#a78b64")))
	var west_bridge:=PLAN.WEST_GATE.bridge
	var west_leg: Array=PLAN.WEST_GATE.towers[0]
	_add_bridge_station(packs,"WestGate",float(west_bridge[0]),float(west_bridge[1]),float(west_leg[0]),float(west_leg[2]),float(PLAN.ARCH.opening))
	for core in PLAN.ARCH.cores: _add_station_core(packs,core,"EastGateCore")
	for core in PLAN.WEST_GATE.cores: _add_station_core(packs,core,"WestGateCore")
	# Public doors from the City Hall halls onto Civic Plaza.


static func _add_civic_square(packs: Dictionary, tree_templates: Dictionary) -> void:
	var data: Dictionary = PLAN.CIVIC_SQUARE
	var r: Array = data.rect
	var mr: Array=data.mirror.rect
	var reach_start := Node3D.new()
	reach_start.name = "CivicPlazaReachStart"
	reach_start.position = Vector3(-380.0, DATUM + 0.13, 0.0)
	reach_start.set_meta("reach_start", true)
	_add(packs, _cell(Vector2(reach_start.position.x, reach_start.position.z)), reach_start)
	var pave_rects: Array=[Rect2(float(r[0]),float(r[1]),float(mr[0])-float(r[0]),float(r[3])-float(r[1])),Rect2(float(mr[2]),float(r[1]),float(r[2])-float(mr[2]),float(r[3])-float(r[1])),Rect2(float(mr[0]),float(r[1]),float(mr[2])-float(mr[0]),float(mr[1])-float(r[1])),Rect2(float(mr[0]),float(mr[3]),float(mr[2])-float(mr[0]),float(r[3])-float(mr[3]))]
	for i in pave_rects.size():
		var pr: Rect2=pave_rects[i]; var paving := _box_body("CivicPlazaPaving_%02d"%i,Vector3(pr.size.x,0.18,pr.size.y),Vector3(pr.get_center().x,DATUM+0.04,pr.get_center().y),Color("#c7b99d")); _add(packs,_cell(pr.get_center()),paving)
	for lawn in data.lawns:
		var lr: Array = lawn.rect
		var cross: Array=data.cross_axis.x
		for piece in 2:
			var x0:=float(lr[0]) if piece==0 else float(cross[1]); var x1:=float(cross[0]) if piece==0 else float(lr[2])
			var body := _box_body("CivicPlazaLawn_%s_%d" % [String(lawn.name).to_snake_case(),piece],Vector3(x1-x0,0.12,float(lr[3])-float(lr[1])),Vector3((x0+x1)*0.5,DATUM+0.16,(float(lr[1])+float(lr[3]))*0.5),Color("#67a66b"))
			_add(packs,_cell(Vector2((x0+x1)*0.5,(float(lr[1])+float(lr[3]))*0.5)),body)
		var path:=_box_body("CivicPlazaHotelWalk",Vector3(float(cross[1])-float(cross[0]),0.08,float(lr[3])-float(lr[1])),Vector3((float(cross[0])+float(cross[1]))*0.5,DATUM+0.16,(float(lr[1])+float(lr[3]))*0.5),Color("#c7b99d")); _add(packs,_cell(Vector2(path.position.x,path.position.z)),path)
	for fountain in data.fountains:
		var c: Vector2 = Vector2(fountain.c[0],fountain.c[1]); var radius := float(fountain.r)
		var basin := _box_body("CivicFountainBasin_%s" % str(fountain.name).replace(" ","_"),Vector3(radius*2,0.25,radius*2),Vector3(c.x,DATUM+0.35,c.y),Color("#8eaaad"))
		_add(packs,_cell(c),basin)
		var jet := _box_body("CivicFountainJet",Vector3(0.3,1.8,0.3),Vector3(c.x,DATUM+1.35,c.y),Color("#d6e8e6")); _add(packs,_cell(c),jet)
	for row in data.tree_rows:
		var start := float(row.x[0]); var finish := float(row.x[1]); var step := float(row.every); var index := 0
		while start + float(index)*step <= finish + 0.01:
			var p := Vector2(start + float(index)*step,float(row.z)); var tree := _instance_tree(tree_templates,"square_round_9","round",float(row.h),Color("#829c69"),index)
			tree.name="CivicPlazaTree_%s_%02d"%[str(int(row.z)).replace("-","n"),index]; tree.position=Vector3(p.x,DATUM,p.y); _add(packs,_cell(p),tree); index += 1
	for monument in data.monuments:
		var c: Vector2=Vector2(monument.c[0],monument.c[1]); var size: Array=monument.size
		var plinth := _box_body("CivicPlazaMonument_%s"%str(monument.name).replace(" ","_"),Vector3(float(size[0]),float(monument.h),float(size[1])),Vector3(c.x,DATUM+float(monument.h)*0.5,c.y),Color("#b3a58d")); _add(packs,_cell(c),plinth)
	for statue in data.statues:
		var c: Vector2=Vector2(statue.c[0],statue.c[1]); var body := _box_body("CivicPlazaStatue",Vector3(1.2,2.2,1.2),Vector3(c.x,DATUM+1.1,c.y),Color("#8d8a78")); _add(packs,_cell(c),body)
	for flag in data.flagstaffs:
		var c: Vector2=Vector2(flag.c[0],flag.c[1]); var pole := _round_column("CivicPlazaFlagstaff",0.12,float(flag.h),Vector3(c.x,DATUM+float(flag.h)*0.5,c.y),Color("#b6a77e")); _add(packs,_cell(c),pole)
	# The reflecting pool is decorative, but explicitly hazardous and queried as water.
	var mirror: Dictionary=data.mirror; var mirror_rect: Array=mirror.rect; var center:=Vector2((float(mirror_rect[0])+float(mirror_rect[2]))*0.5,(float(mirror_rect[1])+float(mirror_rect[3]))*0.5)
	var pool := MeshInstance3D.new(); pool.name="CivicReflectingPoolSurface"; var pm:=PlaneMesh.new(); pm.size=Vector2(float(mirror_rect[2])-float(mirror_rect[0]),float(mirror_rect[3])-float(mirror_rect[1])); pool.mesh=pm; pool.position=Vector3(center.x,DATUM-float(mirror.depth),center.y); pool.material_override=VillageWorks.water_material()
	var hazard:=Node3D.new(); hazard.name="CivicReflectingPool"; hazard.add_child(pool); hazard.set_meta("water_surface_y",pool.position.y); hazard.set_meta("water_depth",float(mirror.depth)); CollisionPolicy.mark_hazard(hazard); _add(packs,_cell(center),hazard)


static func _add_arch_front(packs: Dictionary) -> void:
	var front: Dictionary=PLAN.ARCH.front; var rostrum: Dictionary=front.rostrum; var rx: Array=rostrum.x; var rz: Array=rostrum.z; var y:=float(rostrum.y); var y_rostrum:=y
	# Rostrum piers leave the authored central bay and two portals open.
	var west_open: Array=[[-3.0,3.0]]
	var east_open: Array=[[-float(PLAN.ARCH.opening)*0.5,float(PLAN.ARCH.opening)*0.5]]
	for leg in front.legs:
		var steps_z: float=float(leg.steps.z); var half_width: float=float(leg.steps.width)*0.5
		west_open.append([steps_z-half_width-0.08,steps_z+half_width+0.08])
		var sign_z:=-1.0 if String(leg.side)=="north" else 1.0
		east_open.append([minf(sign_z*float(rostrum.portals[0]),sign_z*float(rostrum.portals[1])),maxf(sign_z*float(rostrum.portals[0]),sign_z*float(rostrum.portals[1]))])
	for side in [-1.0,1.0]:
		var x: float=(float(rx[0])+float(rx[1]))*0.5+side*(float(rx[1])-float(rx[0]))*0.5
		var openings: Array=west_open if side<0.0 else east_open
		openings.sort_custom(func(a: Array, b: Array) -> bool: return a[0]<b[0])
		var z_cursor:=float(rz[0]); var pier_index:=0
		for gap in openings:
			if float(gap[0])-z_cursor>0.3:
				var length:=float(gap[0])-z_cursor
				_add(packs,_cell(Vector2(x,z_cursor+length*0.5)),_box_body("CityHallRostrumPier_%d_%d"%[0 if side<0.0 else 1,pier_index],Vector3(0.6,5.0,length),Vector3(x,DATUM+y+2.5,z_cursor+length*0.5),Color("#d3c6ad")))
				pier_index+=1
			z_cursor=maxf(z_cursor,float(gap[1]))
		if float(rz[1])-z_cursor>0.3:
			var length:=float(rz[1])-z_cursor
			_add(packs,_cell(Vector2(x,z_cursor+length*0.5)),_box_body("CityHallRostrumPier_%d_%d"%[0 if side<0.0 else 1,pier_index],Vector3(0.6,5.0,length),Vector3(x,DATUM+y+2.5,z_cursor+length*0.5),Color("#d3c6ad")))
	# The lintel spans the gate's opening only: the legs' scissor flights climb through the rest of the Rostrum's width.
	_add(packs,_cell(Vector2(-367,0)),_box_body("CityHallRostrumLintel",Vector3(7.0,0.6,float(PLAN.ARCH.opening)),Vector3(-367,DATUM+y+5.0,0),Color("#d3c6ad")))
	# The Rostrum itself (city.md, the front): the 7 m balcony across the whole west
	# front at +14.2 with the speaker's bay on the axis, and the deck across the gate's
	# opening to the Wall Line's inner platform. One run, so their seam is not an overlap.
	var bay: Dictionary=rostrum.bay; var bay_c:=Vector2(float(bay.c[0]),float(bay.c[1])); var bay_r:=float(bay.r)
	var outline:=PackedVector2Array([Vector2(float(rx[1]),float(rz[0])),Vector2(float(rx[0]),float(rz[0])),Vector2(float(rx[0]),bay_c.y-bay_r)])
	for arc_step in range(1,12):
		var arc_angle:=deg_to_rad(-90.0-180.0*float(arc_step)/12.0)
		outline.append(bay_c+Vector2(cos(arc_angle),sin(arc_angle))*bay_r)
	outline.append(Vector2(float(rx[0]),bay_c.y+bay_r)); outline.append(Vector2(float(rx[0]),float(rz[1]))); outline.append(Vector2(float(rx[1]),float(rz[1])))
	var rostrum_deck:=_polygon_deck_body("CityHallRostrumDeck",outline,DATUM+y,0.4,Color("#c9b999"))
	rostrum_deck.set_meta("walk_deck",true); rostrum_deck.set_meta("walk_run_id","CityHallRostrum"); _add(packs,_cell(Vector2(-367,0)),rostrum_deck)
	var opening_x: Array=rostrum.opening_x; var opening_half:=float(PLAN.ARCH.opening)*0.5
	var opening_deck:=_box_body("CityHallRostrumOpeningDeck",Vector3(float(opening_x[1])-float(opening_x[0]),0.4,opening_half*2.0),Vector3((float(opening_x[0])+float(opening_x[1]))*0.5,DATUM+y-0.2,0),Color("#c9b999"))
	opening_deck.set_meta("walk_deck",true); opening_deck.set_meta("walk_run_id","CityHallRostrum"); _add(packs,_cell(Vector2(-361.3,0)),opening_deck)
	for leg in front.legs:
		var side:=String(leg.side)
		for flight in leg.flights:
			var band: Array=front.bands[String(flight.band)]; var ys: Array=flight.y; var zs: Array=flight.z
			var foot:=Vector3((float(band[0])+float(band[1]))*0.5,DATUM+float(ys[0]),float(zs[0])); var head:=Vector3(foot.x,DATUM+float(ys[1]),float(zs[1]))
			_add_escalator_pair(packs,"CityHall_%s_%s"%[side,String(flight.name)],foot,head,2.8,0.04,true)
			if is_equal_approx(float(ys[0]),y):
				var flight_fill:=_flight_underfill("CityHallSkirtF1_%s_%s"%[side,String(flight.name)],foot,head,1.25,DATUM+float(ys[0]))
				if flight_fill!=null: _add(packs,_cell(Vector2(foot.x,foot.z)),flight_fill)
		for gallery in leg.galleries:
			var band_name:=String(gallery.band); var xr: Array
			if band_name=="AB": xr=[minf(float(front.bands.A[0]),float(front.bands.B[0])),maxf(float(front.bands.A[1]),float(front.bands.B[1]))]
			else: xr=front.bands[band_name]
			var zr: Array=gallery.z; var gy:=DATUM+float(gallery.y)
			var g:=_box_body("CityHallGallery_%s_%s"%[side,String(gallery.name)],Vector3(absf(float(xr[1])-float(xr[0])),0.38,absf(float(zr[1])-float(zr[0]))),Vector3((float(xr[0])+float(xr[1]))*0.5,gy-0.19,(float(zr[0])+float(zr[1]))*0.5),Color("#c9b999")); _add(packs,_cell(Vector2(g.position.x,g.position.z)),g)
		var ov: Dictionary=leg.over_tracks; var ox: Array=ov.x; var oz: Array=ov.z
		var walk:=_box_body("CityHallOverTrackWalk_%s"%side,Vector3(float(ox[1])-float(ox[0]),0.4,absf(float(oz[1])-float(oz[0]))),Vector3((float(ox[0])+float(ox[1]))*0.5,DATUM+float(ov.y)-0.2,(float(oz[0])+float(oz[1]))*0.5),Color("#c9b999")); _add(packs,_cell(Vector2(walk.position.x,walk.position.z)),walk)
		var outer: Dictionary=leg.outer; var oys: Array=outer.y; var ozs: Array=outer.z
		# The pair's head is drawn on the landing's east edge (x outer.x[1]); its belts are 2.2 m wide about that line, so the head sits one belt half-width inside the landing.
		_add_escalator_pair(packs,"CityHallOuter_%s"%side,Vector3(float(outer.x[0]),DATUM+float(oys[0]),float(ozs[0])),Vector3(float(outer.x[1])-1.1,DATUM+float(oys[1]),float(ozs[1])),2.8,0.04,true)
		var outer_fill:=_flight_underfill("CityHallSkirtOuter_%s"%side,Vector3(float(outer.x[0]),DATUM+float(oys[0]),float(ozs[0])),Vector3(float(outer.x[1])-1.1,DATUM+float(oys[1]),float(ozs[1])),1.25,DATUM+float((leg.outer_landing as Dictionary).y))
		if outer_fill!=null: _add(packs,_cell(Vector2(float(outer.x[1]),float(ozs[1]))),outer_fill)
		var ol: Dictionary=leg.outer_landing; var olx: Array=ol.x; var olz: Array=ol.z
		var landing:=_box_body("CityHallOuterLanding_%s"%side,Vector3(float(olx[1])-float(olx[0]),0.4,absf(float(olz[1])-float(olz[0]))),Vector3((float(olx[0])+float(olx[1]))*0.5,DATUM+float(ol.y)-0.2,(float(olz[0])+float(olz[1]))*0.5),Color("#c9b999")); _add(packs,_cell(Vector2(landing.position.x,landing.position.z)),landing)
		var steps: Dictionary=leg.steps; var footx:=float(steps.foot); var headx:=float(steps.head); var half: Array=steps.half; var half_y:=float(steps.half_y)
		# Two flights share the half-landing (city.md): the forecourt (the plaza's paving, +0.13) to the half-landing, then on to the Rostrum.
		var flights: Array=[[footx,0.13,float(half[0]),half_y],[float(half[1]),half_y,headx,y_rostrum]]
		for lane in steps.lanes:
			var z:=float(lane.z)
			for flight_i in flights.size():
				var span: Array=flights[flight_i]
				var a:=Vector3(float(span[0]),DATUM+float(span[1]),z); var b:=Vector3(float(span[2]),DATUM+float(span[3]),z)
				if String(lane.kind).contains("escalator"):
					if String(lane.kind)=="down escalator": var swap:=a; a=b; b=swap
					_add_escalator_pair(packs,"CityHallSteps_%s_%s_%d"%[side,String(lane.kind).to_snake_case(),flight_i],a,b,2.4,0.04,true)
				else:
					_add(packs,_cell(Vector2((a.x+b.x)*0.5,z)),_stair_body("CityHallStair_%s_%d"%[side,flight_i],a,b,float(lane.w)))
		var steps_reach:=0.0
		for lane in steps.lanes: steps_reach=maxf(steps_reach,absf(float(lane.z)-float(steps.z)))
		steps_reach+=1.25   # the outer lanes are 2.4 m wide pairs about their centre lines
		var steps_fill:=_flight_underfill("CityHallSkirtSteps_%s"%side,Vector3(footx,DATUM+0.13,float(steps.z)),Vector3(float(half[0]),DATUM+half_y,float(steps.z)),steps_reach,DATUM+0.13,float(PLAN.ESCALATORS.section.depth))
		if steps_fill!=null: _add(packs,_cell(Vector2(footx,float(steps.z))),steps_fill)
		var half_land:=_box_body("CityHallStepsHalfLanding_%s"%side,Vector3(absf(float(half[1])-float(half[0])),0.4,float(steps.width)),Vector3((float(half[0])+float(half[1]))*0.5,DATUM+half_y-0.2,float(steps.z)),Color("#c9b999")); _add(packs,_cell(Vector2(half_land.position.x,half_land.position.z)),half_land)
		for li in leg.lifts.size():
			var ld: Dictionary=leg.lifts[li]; var c: Vector2=Vector2(ld.c[0],float(ld.c[1])); var stops: Array=ld.stops
			var car:=AnimatableBody3D.new(); car.name="CityHall_%s_Lift_%d"%[side,li]; car.position=Vector3(c.x,DATUM,c.y); car.set_script(load("res://scripts/moy_lift_platform.gd")); car.set("base_height",DATUM)
			var levels:=PackedFloat32Array(); var labels:=PackedStringArray()
			for stop in stops: levels.append(float(stop)); labels.append("Floor %s"%str(stop))
			car.set("stop_levels",levels); car.set("stop_names",labels)
			var cm:=BoxMesh.new(); cm.size=Vector3(float(ld.size),0.22,float(ld.size)); var cv:=MeshInstance3D.new(); cv.mesh=cm; cv.material_override=_material(Color(0.55,0.74,0.77,0.35)); car.add_child(cv); var cs:=BoxShape3D.new(); cs.size=cm.size; var cc:=CollisionShape3D.new(); cc.shape=cs; car.add_child(cc); _add(packs,_cell(c),car)
			var controls:=Node3D.new(); controls.name=car.name+"Controls"
			var door_reach:=float(ld.size)*0.5+0.9; var call_offset:=Vector2(-door_reach,0.0)
			if str(ld.door)!="w": call_offset=Vector2(0.0,float(ld.door)*door_reach)
			for stop_i in stops.size(): _add_moy_lift_call(controls,car,stop_i,"Floor %s"%str(stops[stop_i]),Vector3(c.x+call_offset.x,DATUM+float(stops[stop_i]),c.y+call_offset.y))
			_add(packs,_cell(c),controls)
	# Only the plan-authored guard runs are built; glass and shoe share a solid body.
	for guard in PLAN.ARCH.front_guard.runs:
		var pts: Array=guard.pts; var level:=DATUM+float(guard.y)
		for i in range(pts.size()-1):
			var a:=Vector2(pts[i][0],pts[i][1]); var b:=Vector2(pts[i+1][0],pts[i+1][1]); var center:=(a+b)*0.5; var length:=a.distance_to(b)
			var rail:=_segment_body("CityHallFrontGuard",a,b,0.12,level,1.1,Color(0.45,0.66,0.69,0.3)); _set_body_glass(rail,Color(0.45,0.66,0.69,0.3))
			for trim in 2:
				var shoe:=MeshInstance3D.new(); shoe.name="CityHallFrontGuardBronzeShoe"; var sm:=BoxMesh.new(); sm.size=Vector3(length,0.08,0.16); shoe.mesh=sm; shoe.position.y=-0.5; shoe.material_override=_material(Color("#92704a")); rail.add_child(shoe)
				if trim==1: shoe.position.y=0.54; shoe.name="CityHallFrontGuardBronzeTopRail"
			_add(packs,_cell(center),rail)

static func _add_bridge_station(packs: Dictionary,label: String,y0: float,y1: float,x0: float,x1: float,width_z: float) -> void:
	var cx:=(x0+x1)*0.5; var cy:=DATUM+y0; var length:=x1-x0
	_add(packs,_cell(Vector2(cx,0)),_box_body(label+"BridgeFloor",Vector3(length,0.8,width_z),Vector3(cx,cy+0.4,0),Color("#bca37c")))
	_add(packs,_cell(Vector2(cx,0)),_box_body(label+"BridgeRoof",Vector3(length,0.6,width_z),Vector3(cx,DATUM+y1-0.3,0),Color("#bca37c")))
	for side in [-1.0,1.0]:
		var glass_side:=_box_body(label+"BridgeGlassSide",Vector3(length,y1-y0-1.4,0.12),Vector3(cx,DATUM+(y0+y1)*0.5,side*(width_z*0.5-0.06)),Color(0.45,0.65,0.69,0.24)); _set_body_glass(glass_side,Color(0.45,0.65,0.69,0.24)); _add(packs,_cell(Vector2(cx,side*width_z*0.5)),glass_side)
	# Tracks remain in the central 8 m; platforms flank them, with open ends.
	var platform_offset:=_station_platform_offset(true)
	for side in [-1.0,1.0]:
		var pz: float=side*platform_offset
		var platform:=_box_body(label+"BridgePlatform",Vector3(float(PLAN.CROSS.platform[0]),0.3,float(PLAN.PLATFORMS.width)),Vector3(cx,DATUM+y0+5.0-0.15,pz),Color("#c4b18b")); _set_box_collision_margin(platform,0.0)
		platform.set_meta("reach_link_id","Meridian Line" if label=="MeridianArch" else "Wall Line")
		_add(packs,_cell(Vector2(cx,pz)),platform)


static func _add_city_dome(packs: Dictionary) -> void:
	var cfg: Dictionary=PLAN.CROSSING; var dome: Dictionary=cfg.dome; var base:=float(dome.base); var center:=Vector2(float(cfg.c[0]),float(cfg.c[1]))
	var root:=Node3D.new(); root.name="CrossingCityDome"; root.position=Vector3(center.x,DATUM+base,center.y)
	var drum: Dictionary=dome.drum; var half:=float(drum.half); var exponent:=float(drum.n); var glass:=StandardMaterial3D.new(); glass.albedo_color=Color(0.38,0.63,0.68,0.18); glass.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA; glass.roughness=0.15
	# Continuous faceted superellipse glass enclosure; collision keeps the roof edge safe.
	var eye_sill_y := float(dome.clocks.eye.sill_y)-base
	var eye_r := float(dome.clocks.eye.r)
	for i in 96:
		var a:=TAU*float(i)/96.0; var b:=TAU*float(i+1)/96.0
		var xa:=half*signf(cos(a))*pow(absf(cos(a)),2.0/exponent); var za:=half*signf(sin(a))*pow(absf(sin(a)),2.0/exponent)
		var xb:=half*signf(cos(b))*pow(absf(cos(b)),2.0/exponent); var zb:=half*signf(sin(b))*pow(absf(sin(b)),2.0/exponent)
		var angle_mid := (a+b)*0.5
		var eye_bearing := -1
		for face_i in dome.clocks.bearings.size():
			var bearing := deg_to_rad(float(dome.clocks.bearings[face_i]))
			if absf(wrapf(angle_mid-bearing,-PI,PI)) < eye_r/half + 0.02: eye_bearing=face_i; break
		var length := Vector2(xa,za).distance_to(Vector2(xb,zb))
		if eye_bearing < 0:
			var panel:=_box_body("DomeGlassPanel_%02d"%i,Vector3(length,float(drum.h),0.12),Vector3((xa+xb)*0.5,float(drum.h)*0.5,(za+zb)*0.5),Color(0.42,0.67,0.72,0.28)); panel.rotation.y=-atan2(zb-za,xb-xa)
			for panel_child in panel.get_children():
				if panel_child is MeshInstance3D: (panel_child as MeshInstance3D).material_override=glass
			_add(packs,_cell(center),panel)
		else:
			# Split each eye-facing pane into sill and crown pieces. The opening has no glass or collider.
			for part in 2:
				var py := 0.0 if part==0 else eye_sill_y+2.0*eye_r
				var ph := eye_sill_y if part==0 else float(drum.h)-py
				if ph < 0.1: continue
				var panel:=_box_body("DomeGlassEyeRim_%02d_%d"%[i,part],Vector3(length,ph,0.12),Vector3((xa+xb)*0.5,py+ph*0.5,(za+zb)*0.5),Color(0.42,0.67,0.72,0.28)); panel.rotation.y=-atan2(zb-za,xb-xa)
				for panel_child in panel.get_children():
					if panel_child is MeshInstance3D: (panel_child as MeshInstance3D).material_override=glass
				_add(packs,_cell(center),panel)
	# The revised Great Court shell removes the old posts and ring beam.
	# Older plans may still explicitly request that support arrangement.
	var rib_count := int(dome.get("ribs", 0))
	for ri in rib_count:
		var a:=TAU*float(ri)/float(rib_count); var rib:=_round_column("DomeSteelRib_%02d"%ri,0.24,float(drum.h),Vector3(half*cos(a),float(drum.h)*0.5,half*sin(a)),Color("#879b9d")); root.add_child(rib)
	if rib_count > 0:
		var top_ring:=_annulus_visual("DomeTopSteelRing",half-0.25,half+0.25,96,0.32,float(drum.h)); root.add_child(top_ring)
	# A slim bronze sleeve follows each open eye; it frames, but never fills, the flight path.
	var chord:=float(dome.clocks.eye.chord); var eye_top:=eye_sill_y+2.0*eye_r
	for bearing_degrees in dome.clocks.bearings:
		var bearing:=deg_to_rad(float(bearing_degrees)); var radial:=Vector3(cos(bearing),0,sin(bearing)); var tangent:=Vector3(-sin(bearing),0,cos(bearing)); var eye_center:=radial*half
		for side in [-1.0,1.0]:
			var jamb:=MeshInstance3D.new(); jamb.name="ClockEyeBronzeSleeveJamb"; var jm:=BoxMesh.new(); jm.size=Vector3(0.12,2.0*eye_r,0.12); jamb.mesh=jm; jamb.position=eye_center+tangent*side*(chord*0.5); jamb.position.y=eye_sill_y+eye_r; jamb.rotation.y=-bearing; jamb.material_override=_material(Color("#92704a")); root.add_child(jamb)
		for yy in [eye_sill_y,eye_top]:
			var rim:=MeshInstance3D.new(); rim.name="ClockEyeBronzeSleeveRim"; var rm:=BoxMesh.new(); rm.size=Vector3(chord+0.24,0.12,0.12); rim.mesh=rm; rim.position=eye_center+Vector3.UP*yy; rim.rotation.y=-bearing; rim.material_override=_material(Color("#92704a")); root.add_child(rim)
	var cupola: Dictionary=dome.cupola; var cap:=MeshInstance3D.new(); cap.name="DomeGlassCupola"; var cupola_mesh:=_superellipsoid_mesh(half,float(cupola.h),exponent,72,20); cap.mesh=cupola_mesh; cap.position.y=float(drum.h); cap.material_override=glass; root.add_child(cap)
	var crown_ring:=_annulus_visual("DomeBellCrownRing",float(dome.lattice.crown)-0.06,float(dome.lattice.crown)+0.06,72,0.07,float(drum.h)+float(cupola.h)); root.add_child(crown_ring)
	var cs:=CollisionShape3D.new(); var css:=ConcavePolygonShape3D.new(); css.set_faces(cupola_mesh.get_faces()); cs.shape=css; var collision_body:=StaticBody3D.new(); collision_body.name="DomeCupolaLanding"; collision_body.position.y=float(drum.h); collision_body.add_child(cs); root.add_child(collision_body)
	_add_dome_lattice(root,half,float(drum.h),float(cupola.h),exponent,float(dome.lattice.row),float(dome.lattice.member),int(dome.lattice.around))
	var clock_root:=Node3D.new(); clock_root.name="CityClockFaces"; clock_root.position.y=float(dome.clocks.centre); clock_root.set_meta("moy_keep_children",true); clock_root.set_script(load("res://scripts/moy_timekeeper.gd")); clock_root.set("game_clock_path",NodePath("/root/World/DayNightCycle")); root.add_child(clock_root)
	for face_i in 4:
		var bearing:=deg_to_rad(float(dome.clocks.bearings[face_i])); var face:=Node3D.new(); face.name="ClockFace_%d"%face_i; face.position=Vector3(cos(bearing)*half,0,sin(bearing)*half); face.rotation.y=-bearing+PI*0.5; clock_root.add_child(face)
		for ring in dome.clocks.rings:
			var ring_name:=String(ring[0]); var inner:=float(ring[1]); var outer:=float(ring[2]); var anim:=Node3D.new(); anim.name="CityClock_%s_%d"%[ring_name,face_i]; face.add_child(anim)
			var visual:=MeshInstance3D.new(); visual.mesh=_flat_annulus_mesh(inner,outer,48,0.16); visual.rotation.x=PI*0.5; visual.material_override=_material(Color("#a88955")); anim.add_child(visual)
			if ring_name!="bezel":
				var marker: Dictionary=dome.clocks.markers[ring_name]; var arrow:=_clock_arrow(inner,outer,float(marker.arc),float(dome.clocks.proud)); arrow.name="Arrow"; anim.add_child(arrow)
			else:
				for tick in 48:
					var angle:=TAU*float(tick)/48.0; var mark_width:=float(dome.clocks.marks.minute.w); var mark_len:=float(dome.clocks.marks.minute.len)
					if tick%4==0: mark_width=float(dome.clocks.marks.hour); mark_len=float(dome.clocks.marks.quarter) if tick%12==0 else float(dome.clocks.marks.hour)
					var box:=BoxMesh.new(); box.size=Vector3(mark_width,mark_len,0.08)
					var tick_mesh:=MeshInstance3D.new(); tick_mesh.mesh=box; tick_mesh.position=Vector3(cos(angle)*7.5,sin(angle)*7.5,0.2); tick_mesh.rotation.z=angle-PI*0.5; tick_mesh.material_override=_material(Color("#45433d")); anim.add_child(tick_mesh)
	var bell: Dictionary=dome.bell; var bell_node:=MeshInstance3D.new(); bell_node.name="CityBell_SOUND_PLACEHOLDER"; var bell_mesh:=CylinderMesh.new(); bell_mesh.top_radius=float(bell.mouth)*0.35; bell_mesh.bottom_radius=float(bell.mouth)*0.5; bell_mesh.height=float(bell.height); bell_node.mesh=bell_mesh; bell_node.position.y=float(bell.bottom)+float(bell.height)*0.5-base; bell_node.material_override=_material(Color("#96764a")); root.add_child(bell_node)
	var bell_script_root:=Node3D.new(); bell_script_root.name="CityBellScheduler"; bell_script_root.set_script(load("res://scripts/moy_timekeeper.gd")); bell_script_root.set("bell_path",NodePath("../CityBell_SOUND_PLACEHOLDER")); var audio_placeholder:=AudioStreamPlayer3D.new(); audio_placeholder.name="CityBellAudio_PLACEHOLDER_NO_ASSET"; bell_script_root.add_child(audio_placeholder); root.add_child(bell_script_root)
	_add_clock_room(packs, cfg)
	_add(packs,_cell(center),root)


static func _add_clock_room(packs: Dictionary, cfg: Dictionary) -> void:
	var room: Dictionary=cfg.dome.room; var center:=Vector2(float(cfg.c[0]),float(cfg.c[1])); var level:=DATUM+float(cfg.dome.base)
	var xs: Array[float]=[-580.0,-540.0]; var zs: Array[float]=[-20.0,20.0]
	for arrival in room.arrivals:
		var w: Array=arrival.well; xs.append(float(w[0])); xs.append(float(w[2])); zs.append(float(w[1])); zs.append(float(w[3]))
	xs.sort(); zs.sort()
	for xi in range(xs.size()-1):
		for zi in range(zs.size()-1):
			var x0:=xs[xi]; var x1:=xs[xi+1]; var z0:=zs[zi]; var z1:=zs[zi+1]
			if x1-x0<0.1 or z1-z0<0.1: continue
			var hole:=false
			for arrival in room.arrivals:
				var w: Array=arrival.well
				if x0>=float(w[0])-0.01 and x1<=float(w[2])+0.01 and z0>=float(w[1])-0.01 and z1<=float(w[3])+0.01: hole=true; break
			if hole: continue
			var tile:=_box_body("ClockRoomTerrazzo",Vector3(x1-x0,0.32,z1-z0),Vector3((x0+x1)*0.5,level-0.16,(z0+z1)*0.5),Color("#d5d1c7")); _add(packs,_cell(center),tile)
	var rose:=_annulus_visual("ClockRoomCompassRose",1.5,3.6,64,0.04,level+0.02); rose.position.x=center.x; rose.position.z=center.y; _add(packs,_cell(center),rose)
	for widening in room.widenings:
		var wr: Array=widening.rect; var platform:=_box_body("ClockRoomPlatformWidening_%s"%String(widening.side),Vector3(float(wr[2])-float(wr[0]),0.32,float(wr[3])-float(wr[1])),Vector3((float(wr[0])+float(wr[2]))*0.5,DATUM+float(widening.y)-0.16,(float(wr[1])+float(wr[3]))*0.5),Color("#c4b18b")); _add(packs,_cell(center),platform)
	for arrival_index in room.arrivals.size():
		var arrival: Dictionary=room.arrivals[arrival_index]
		var foot: Array=arrival.foot; var head: Array=arrival.head; var ys: Array=arrival.y
		_add_escalator_pair(packs,"ClockRoomArrival_%02d_%s"%[arrival_index,String(arrival.side)],Vector3(float(foot[0]),DATUM+float(ys[0]),float(foot[1])),Vector3(float(head[0]),DATUM+float(ys[1]),float(head[1])),3.2)
		var w: Array=arrival.well; var corners: Array=[Vector2(float(w[0]),float(w[1])),Vector2(float(w[2]),float(w[1])),Vector2(float(w[2]),float(w[3])),Vector2(float(w[0]),float(w[3]))]
		var open_edge:=0 if String(arrival.side)=="north" else 2
		for i in 4:
			if i==open_edge: continue
			var a: Vector2=corners[i]; var b: Vector2=corners[(i+1)%corners.size()]; var guard:=_segment_body("ClockRoomWellGuard",a,b,0.12,level+0.55,1.1,Color(0.4,0.65,0.68,0.35)); _add(packs,_cell(center),guard)
	for lift_index in room.lifts.size():
		var lift: Dictionary=room.lifts[lift_index]
		var c: Vector2=Vector2(lift.c[0],lift.c[1]); var toward: Vector2=(center-c).normalized(); var tangent:=Vector2(-toward.y,toward.x); var half:=float(lift.r); var h:=float(room.lantern)
		var lift_label:=String(lift.tower).replace("-","_")
		var back:=_box_body("ClockRoomLiftLanternBack_%s"%lift_label,Vector3(half*2,h,0.12),Vector3(c.x-toward.x*half,level+h*0.5,c.y-toward.y*half),Color(0.45,0.68,0.72,0.28)); back.rotation.y=-atan2(tangent.y,tangent.x); _set_body_glass(back,Color(0.45,0.68,0.72,0.28)); _add(packs,_cell(center),back)
		for side in [-1.0,1.0]:
			var wall:=_box_body("ClockRoomLiftLanternSide_%s_%d"%[lift_label,int(side)],Vector3(half*2,h,0.12),Vector3(c.x+tangent.x*side*half,level+h*0.5,c.y+tangent.y*side*half),Color(0.45,0.68,0.72,0.28)); wall.rotation.y=-atan2(toward.y,toward.x); _set_body_glass(wall,Color(0.45,0.68,0.72,0.28)); _add(packs,_cell(center),wall)


static func _clock_arrow(inner: float, outer: float, arc: float, proud: float) -> MeshInstance3D:
	var half:=deg_to_rad(arc)*0.5; var st:=SurfaceTool.new(); st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var a:=Vector3(cos(-half)*inner,sin(-half)*inner,proud); var b:=Vector3(cos(half)*inner,sin(half)*inner,proud); var tip:=Vector3(outer,0,proud)
	for side in [-1.0,1.0]:
		var z: float=proud+side*0.05; st.set_normal(Vector3(0,0,side)); st.add_vertex(Vector3(a.x,a.y,z)); st.add_vertex(Vector3(b.x,b.y,z)); st.add_vertex(Vector3(tip.x,tip.y,z))
	var mesh:=st.commit(); var arrow:=MeshInstance3D.new(); arrow.mesh=mesh; var mat:=StandardMaterial3D.new(); mat.albedo_color=Color("#f03f35"); mat.emission_enabled=true; mat.emission=Color("#f03f35"); arrow.material_override=mat; return arrow


static func _superellipsoid_mesh(radius: float,height: float,exponent: float,segments: int,rings: int) -> ArrayMesh:
	var st:=SurfaceTool.new(); st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for row in rings:
		var t0:=float(row)/float(rings); var t1:=float(row+1)/float(rings)
		for col in segments:
			var u0:=TAU*float(col)/float(segments); var u1:=TAU*float(col+1)/float(segments)
			var p00:=_dome_point(radius,height,exponent,u0,t0); var p10:=_dome_point(radius,height,exponent,u1,t0); var p01:=_dome_point(radius,height,exponent,u0,t1); var p11:=_dome_point(radius,height,exponent,u1,t1)
			st.add_vertex(p00); st.add_vertex(p01); st.add_vertex(p11); st.add_vertex(p00); st.add_vertex(p11); st.add_vertex(p10)
	return st.commit()


static func _dome_point(radius: float,height: float,exponent: float,angle: float,t: float) -> Vector3:
	var angular_denom:=pow(pow(absf(cos(angle)),exponent)+pow(absf(sin(angle)),exponent),1.0/exponent)
	var r:=radius*sqrt(maxf(0.0,1.0-t*t))/maxf(angular_denom,0.001)
	return Vector3(cos(angle)*r,height*t,sin(angle)*r)


static func _add_dome_lattice(root: Node3D, radius: float, drum_height: float, crown_height: float, exponent: float, row_step: float, member_diameter: float, around: int) -> void:
	var heights: Array[float]=[0.0]
	var y:=row_step
	while y<drum_height+crown_height:
		heights.append(y); y+=row_step
	heights.append(drum_height+crown_height)
	var transforms: Array[Transform3D]=[]
	for row in heights.size():
		var h:=heights[row]
		for spoke in around:
			var angle:=TAU*float(spoke)/float(around); var next:=TAU*float(spoke+1)/float(around)
			var angular_denom:=pow(pow(absf(cos(angle)),exponent)+pow(absf(sin(angle)),exponent),1.0/exponent)
			var r0:=radius*sqrt(maxf(0.0,1.0-pow(maxf(0.0,h-drum_height)/crown_height,2.0)))/angular_denom
			var r1:=r0
			var a:=Vector3(cos(angle)*r0,h,sin(angle)*r0); var b:=Vector3(cos(next)*r1,h,sin(next)*r1)
			transforms.append(_dome_strut_transform(a,b))
		if row>=heights.size()-1: continue
		var next_h:=heights[row+1]
		for spoke in around:
			var angle:=TAU*float(spoke)/float(around); var next_angle:=TAU*float((spoke+1)%around)/float(around)
			var da:=pow(pow(absf(cos(angle)),exponent)+pow(absf(sin(angle)),exponent),1.0/exponent)
			var ra:=radius*sqrt(maxf(0.0,1.0-pow(maxf(0.0,h-drum_height)/crown_height,2.0)))/da
			var db:=pow(pow(absf(cos(next_angle)),exponent)+pow(absf(sin(next_angle)),exponent),1.0/exponent)
			var rb:=radius*sqrt(maxf(0.0,1.0-pow(maxf(0.0,next_h-drum_height)/crown_height,2.0)))/db
			var a:=Vector3(cos(angle)*ra,h,sin(angle)*ra); var b:=Vector3(cos(angle)*rb,next_h,sin(angle)*rb)
			transforms.append(_dome_strut_transform(a,b))
			var diagonal_start:=Vector3(cos(angle)*ra,h,sin(angle)*ra) if row%2==0 else Vector3(cos(next_angle)*ra,h,sin(next_angle)*ra)
			var diagonal_end:=Vector3(cos(next_angle)*rb,next_h,sin(next_angle)*rb) if row%2==0 else Vector3(cos(angle)*rb,next_h,sin(angle)*rb)
			transforms.append(_dome_strut_transform(diagonal_start,diagonal_end))
	var mesh:=CylinderMesh.new(); mesh.top_radius=member_diameter*0.5; mesh.bottom_radius=member_diameter*0.5; mesh.height=1.0; mesh.radial_segments=6
	var multimesh:=MultiMesh.new(); multimesh.transform_format=MultiMesh.TRANSFORM_3D; multimesh.mesh=mesh; multimesh.instance_count=transforms.size(); _store_multimesh_buffer(multimesh,transforms)
	var members:=MultiMeshInstance3D.new(); members.name="DomeTriangulatedWhiteSteelGrid"; members.multimesh=multimesh; members.material_override=_material(Color("#f0eee5")); members.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF; root.add_child(members)


static func _dome_strut_transform(a: Vector3, b: Vector3) -> Transform3D:
	var direction: Vector3=(b-a).normalized(); var x_axis:=Vector3.UP.cross(direction).normalized()
	if x_axis.length_squared()<0.1: x_axis=Vector3.RIGHT
	var z_axis:=x_axis.cross(direction).normalized(); var basis:=Basis(x_axis,direction,z_axis)
	basis=basis.scaled(Vector3(1.0,a.distance_to(b),1.0))
	return Transform3D(basis,(a+b)*0.5)

static func _superellipsoid_point(radius: float,height: float,exponent: float,u: float,v: float) -> Vector3:
	var cv:=cos(v); var sv:=sin(v); var cu:=cos(u); var su:=sin(u)
	var x:=radius*signf(cv*cu)*pow(absf(cv*cu),2.0/exponent); var z:=radius*signf(cv*su)*pow(absf(cv*su),2.0/exponent)
	return Vector3(x,(sv*0.5+0.5)*height,z)


static func _add_turbines(packs: Dictionary) -> void:
	for i in PLAN.TURBINES.size():
		var p: Vector2=PLAN.TURBINES[i]
		var root:=Node3D.new(); root.name="WindTurbine_%02d"%i; root.position=Vector3(p.x,DATUM,p.y)
		var tower:=StaticBody3D.new(); tower.name="WindTurbineTower"; tower.collision_layer=1; tower.collision_mask=1
		var shaft:=CylinderMesh.new(); shaft.top_radius=1.8; shaft.bottom_radius=3.2; shaft.height=95.0; shaft.radial_segments=10
		var shaft_vis:=MeshInstance3D.new(); shaft_vis.mesh=shaft; shaft_vis.position.y=47.5; shaft_vis.material_override=_material(Color("#e3ded1")); tower.add_child(shaft_vis)
		var shaft_shape:=CylinderShape3D.new(); shaft_shape.radius=3.2; shaft_shape.height=95.0
		var shaft_col:=CollisionShape3D.new(); shaft_col.shape=shaft_shape; shaft_col.position.y=47.5; tower.add_child(shaft_col); root.add_child(tower)
		# The basin's prevailing wind comes from the west: every rotor points
		# west, including the west pair (which must not face back toward Moy).
		var face:=PI
		var nacelle:=_box_body("WindTurbineNacelle",Vector3(12,4.5,4.5),Vector3(-2.5,97.0,0.0),Color("#e3ded1")); nacelle.rotation.y=PI; root.add_child(nacelle)
		var hub_center:=Vector3(-6.5,97.0,0.0)
		var hub:=StaticBody3D.new(); hub.name="WindTurbineHub"; hub.position=hub_center
		var hub_mesh:=SphereMesh.new(); hub_mesh.radius=2.4; var hub_vis:=MeshInstance3D.new(); hub_vis.mesh=hub_mesh; hub_vis.material_override=_material(Color("#e3ded1")); hub.add_child(hub_vis)
		var hub_shape:=SphereShape3D.new(); hub_shape.radius=2.4; var hub_col:=CollisionShape3D.new(); hub_col.shape=hub_shape; hub.add_child(hub_col); root.add_child(hub)
		var rotor:=Node3D.new(); rotor.name="WindTurbineRotor"; rotor.position=hub_center; rotor.rotation.y=-PI*0.5; rotor.set_script(load("res://scripts/moy_wind_turbine_rotor.gd")); rotor.set("turns_per_minute",2.0); root.add_child(rotor)
		for blade_index in 3:
			var angle:=TAU*float(blade_index)/3.0
			var blade:=AnimatableBody3D.new(); blade.name="WindTurbineBlade_%d"%blade_index; blade.collision_layer=1; blade.collision_mask=1; blade.sync_to_physics=true; blade.rotation.z=angle; rotor.add_child(blade)
			var blade_mesh:=BoxMesh.new(); blade_mesh.size=Vector3(3.2,64.0,0.8)
			var blade_vis:=MeshInstance3D.new(); blade_vis.mesh=blade_mesh; blade_vis.position.y=32.0; blade_vis.material_override=_material(Color("#e3ded1")); blade.add_child(blade_vis)
			var blade_shape:=CapsuleShape3D.new(); blade_shape.radius=1.6; blade_shape.height=64.0
			var blade_col:=CollisionShape3D.new(); blade_col.shape=blade_shape; blade_col.position.y=32.0; blade.add_child(blade_col)
		_add(packs,_cell(p),root)


static func _add_wall_transit(packs: Dictionary) -> void:
	var points: Array = PLAN.WALL.centreline
	var rail_y := DATUM + float(PLAN.WALL.height) + 1.2
	var lane_paths: Array[PackedVector3Array] = [PackedVector3Array(), PackedVector3Array()]
	for p in points:
		for lane in 2:
			var radius := PLAN.WALL.r + float(PLAN.WALL.track_axis) + float(lane)*float(PLAN.WALL.track_spacing)
			var radial := Vector2(p[0]-PLAN.CENTER.x,p[1]-PLAN.CENTER.y).normalized()
			lane_paths[lane].append(Vector3(PLAN.CENTER.x+radial.x*radius,rail_y,PLAN.CENTER.y+radial.y*radius))
	for i in points.size()-1:
		var a := Vector2(points[i][0],points[i][1]); var b := Vector2(points[i+1][0],points[i+1][1])
		var bed := _segment_body("WallLine_Track_%d"%i,a,b,8.0,rail_y-0.7,1.4,Color("#77766f")); _add(packs,_cell((a+b)*0.5),bed)
		for lane in 2:
			var la := Vector2(lane_paths[lane][i].x,lane_paths[lane][i].z); var lb := Vector2(lane_paths[lane][i+1].x,lane_paths[lane][i+1].z)
			var across := Vector2(-(lb-la).y,(lb-la).x).normalized()
			for rail_side in [-1.0,1.0]:
				var rail := _segment_body("WallLine_Rail_%d_%d_%d"%[i,lane,int(rail_side)],la+across*rail_side*0.7175,lb+across*rail_side*0.7175,0.16,rail_y,0.2,Color("#555b5d")); _add(packs,_cell((a+b)*0.5),rail)
	var wall_stops := PackedVector3Array()
	for station in PLAN.WALL.stations:
		wall_stops.append(Vector3(station.p[0],rail_y,station.p[1]))
		var station_point:=Vector2(station.p[0],station.p[1])
		var radial: Vector2=(station_point-Vector2(PLAN.CENTER.x,PLAN.CENTER.y)).normalized()
		var theta:=atan2(radial.y,radial.x)
		for lane in 2:
			var track_radius:=float(PLAN.WALL.r)+float(PLAN.WALL.track_axis)+float(lane)*float(PLAN.WALL.track_spacing)
			var platform_half_length:=float(PLAN.CROSS.platform[0])*0.5
			var platform_segments:=maxi(1,ceili(rad_to_deg(platform_half_length*2.0/track_radius)/2.0))
			var platform_offset:=_curved_platform_offset(track_radius)
			var platform_radius:=track_radius+(-platform_offset if lane==0 else platform_offset)
			for segment_index in platform_segments:
				var a_angle:=theta-platform_half_length/track_radius+(platform_half_length*2.0)/track_radius*float(segment_index)/float(platform_segments)
				var b_angle:=theta-platform_half_length/track_radius+(platform_half_length*2.0)/track_radius*float(segment_index+1)/float(platform_segments)
				var a:=Vector2(PLAN.CENTER.x+platform_radius*cos(a_angle),PLAN.CENTER.y+platform_radius*sin(a_angle))
				var b:=Vector2(PLAN.CENTER.x+platform_radius*cos(b_angle),PLAN.CENTER.y+platform_radius*sin(b_angle))
				var platform:=_segment_body("WallLine_Station_%s_Platform_%d_%d"%[String(station.name).replace(" ","_"),lane,segment_index],a,b,float(PLAN.PLATFORMS.width),rail_y+0.7,0.3,Color("#c4b18b")); _set_box_collision_margin(platform,0.0)
				_add(packs,_cell((a+b)*0.5),platform)
				var canopy:=_segment_body("WallLine_Station_%s_Canopy_%d_%d"%[String(station.name).replace(" ","_"),lane,segment_index],a,b,float(PLAN.PLATFORMS.width),rail_y+float(PLAN.PLATFORMS.floor)+float(PLAN.PLATFORMS.canopy),0.18,Color("#bcb49b")); _add(packs,_cell((a+b)*0.5),canopy)
	for lane in 2:
		var line_name: String="Wall Line inner" if lane==0 else "Wall Line outer"
		var line_plan: Dictionary=PLAN.TIMETABLE.lines[line_name]
		for train_index in int(line_plan.trains):
			var train := _make_train(line_name,lane_paths[lane],int(PLAN.TRAIN.consists["Wall Line"].cars),float(line_plan.speed),true,wall_stops,float(PLAN.TIMETABLE.dwell.ordinary),lane*3+train_index,1 if lane==0 else -1)
			train.set("schedule_events",line_plan.events); train.set("schedule_offset",float(line_plan.offset)); train.set("schedule_headway",float(PLAN.TIMETABLE.headway)); train.set("schedule_circuit",float(line_plan.circuit)); train.set("schedule_train_index",train_index)
			_add(packs,_cell(Vector2(lane_paths[lane][0].x,lane_paths[lane][0].z)),train)
