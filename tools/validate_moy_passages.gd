extends Node3D

const BUILDER := preload("res://scripts/moy_city_bake_builder.gd")
const PLAN := preload("res://scripts/city_plan.gd")
const DATUM := -60.0
const PASSAGE_LOTS := [34, 71]

var _failures: Array[String] = []

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	for lot_index in PASSAGE_LOTS:
		var lot: Array = PLAN.LOTS[lot_index]
		var rect: Rect2 = lot[0]
		var kit: Dictionary = PLAN.LOT_KITS[lot_index]
		var body := BUILDER._market_house(lot_index, rect, kit)
		add_child(body)
		await get_tree().physics_frame
		var front := String(kit.get("front", "s"))
		var along_x := front in ["n", "s"]
		var travel_axis := Vector3.FORWARD if along_x else Vector3.RIGHT
		var depth := rect.size.y if along_x else rect.size.x
		var center := Vector3(rect.get_center().x, DATUM + 0.95, rect.get_center().y)
		var half_travel := depth * 0.5 + 0.8
		var forward_clear := _sweep(center - travel_axis * half_travel, travel_axis * (depth + 1.6))
		var reverse_clear := _sweep(center + travel_axis * half_travel, -travel_axis * (depth + 1.6))
		print("MOY_PASSAGE lot=", lot_index, " width=", PLAN.MARKET_HOUSE.passage.w,
			" front=", front, " rect=", rect, " door=", kit.get("door"),
			" headroom=", PLAN.MARKET_HOUSE.passage.h, " forward_fraction=", forward_clear,
			" reverse_fraction=", reverse_clear)
		_expect(forward_clear >= 0.999, "lot %d controller capsule clears forward" % lot_index)
		_expect(reverse_clear >= 0.999, "lot %d controller capsule clears in reverse" % lot_index)
		body.queue_free()
		await get_tree().process_frame
	print("MOY_PASSAGE failures=", _failures.size())
	for failure in _failures: push_error("MOY_PASSAGE_FAILURE " + failure)
	get_tree().quit(1 if not _failures.is_empty() else 0)

func _sweep(start: Vector3, motion: Vector3) -> float:
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.4
	capsule.height = 1.8
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = capsule
	query.transform = Transform3D(Basis.IDENTITY, start)
	query.motion = motion
	query.collision_mask = 1
	query.collide_with_bodies = true
	query.collide_with_areas = false
	var space := get_world_3d().direct_space_state
	var fractions := space.cast_motion(query)
	if fractions.size() >= 2 and float(fractions[0]) < 0.999:
		for step in range(101):
			query.transform.origin = start + motion * float(step) / 100.0
			var hits := space.intersect_shape(query, 4)
			if not hits.is_empty():
				var hit: Dictionary = hits[0]
				var collider: Object = hit.get("collider")
				print("MOY_PASSAGE_HIT point=", query.transform.origin, " collider=", collider, " shape=", hit.get("shape"))
				break
	return float(fractions[0]) if fractions.size() >= 2 else 0.0

func _expect(condition: bool, message: String) -> void:
	if not condition: _failures.append(message)
