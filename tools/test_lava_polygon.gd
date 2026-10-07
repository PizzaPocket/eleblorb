extends Node

## Checks FireKingdomTerrain's polygon lava surfaces against the caldera
## reservoir's real outline: inside is lava at its height, a cove beyond the
## outline (but inside its bounding circle) is not, and the escape lands on
## dry ground just past the nearest edge.
##
##   Godot --headless --path . tools/test_lava_polygon.tscn

var _failures := 0


func _ready() -> void:
	var terrain: Node = (load("res://scripts/fire_kingdom_terrain.gd") as GDScript).new()
	var outline := PackedVector2Array()
	for point in FireCalderaPlan.reservoir_polygon():
		outline.append(FireCalderaPlan.to_world(point))
	terrain.register_lava_polygon(outline, FireCalderaGround.LAVA_Y)
	_expect(terrain.is_lava_area(FireCalderaPlan.to_world(Vector2.ZERO)), "the reservoir's centre is lava")
	_expect(is_equal_approx(float(terrain.get_lava_surface_height(FireCalderaPlan.to_world(Vector2(5, 5)))), FireCalderaGround.LAVA_Y), "the surface height is the reservoir's")
	# A cove: the bank pulls back toward the arrival, so a point at 28 m there
	# is dry although it is inside the outline's bounding circle.
	var cove := Vector2(0.0, -FireCalderaPlan.reservoir_radius(-PI * 0.5) - 1.0)
	_expect(not terrain.is_lava_area(FireCalderaPlan.to_world(cove)), "the arrival cove's bank is dry")
	var lobe := Vector2(cos(PI * 0.5), sin(PI * 0.5)) * (FireCalderaPlan.reservoir_radius(PI * 0.5) - 1.0)
	_expect(terrain.is_lava_area(FireCalderaPlan.to_world(lobe)), "the lobe toward Civic is lava to its edge")
	var escape: Vector3 = terrain.get_lava_escape_position(FireCalderaPlan.to_world(lobe))
	var escape_plan := Vector2(escape.x, escape.z)
	_expect(not terrain.is_lava_area(escape_plan), "the escape from the Civic lobe lands outside the lava")
	_expect(escape_plan.distance_to(FireCalderaPlan.to_world(lobe)) < 3.0, "the escape is the nearest edge, %.1f m away" % escape_plan.distance_to(FireCalderaPlan.to_world(lobe)))
	terrain.free()
	print("---- test_lava_polygon: %d FAIL" % _failures)
	get_tree().quit(1 if _failures > 0 else 0)


func _expect(condition: bool, what: String) -> void:
	print(("ok   " if condition else "FAIL ") + what)
	_failures += 0 if condition else 1
