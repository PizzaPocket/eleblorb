extends Node3D

const BLORB := preload("res://scenes/blorb.tscn")
var failures: Array[String] = []

class Ground extends Node3D:
	func get_mesh_height(_x: float, _z: float) -> float: return 0.0
	func get_mesh_normal(_x: float, _z: float) -> Vector3: return Vector3.UP
	func is_lake_area(_at: Vector2) -> bool: return false

class Opponent extends Node3D:
	var hits := 0
	var last_attacker: Blorb
	func take_damage(amount: float, attacker: Blorb = null) -> void:
		if amount > 0.0:
			hits += 1
			last_attacker = attacker

func _check(ok: bool, message: String) -> void:
	if not ok: failures.append(message)

func _ready() -> void:
	get_tree().create_timer(20.0).timeout.connect(func() -> void: get_tree().quit(2))
	var ground := Ground.new(); ground.name = "Terrain"; add_child(ground)
	var player := Node3D.new(); player.name = "Player"; player.position.x = 20; add_child(player)
	var blorb := BLORB.instantiate() as Blorb
	blorb.portrait_mode = true; add_child(blorb); blorb.set_process(false)
	blorb.add_to_group("blorbs")
	# Reuse cached tiny portraits to exercise the actual throwing/whiteout flow
	# headlessly, without asking the dummy renderer to capture a viewport.
	var image := Image.create(4, 4, false, Image.FORMAT_RGBA8)
	for element in ["", "fighting"]:
		var key := BlorbPortrait._cache_key(element, blorb.body_color, false, false, BlorbPortrait.FULLSCREEN_RESOLUTION)
		BlorbPortrait._cache[key] = ImageTexture.create_from_image(image)
	var thrown := ThrownItem.new(); thrown.item_name = "Boxing Gloves"; add_child(thrown)
	thrown.set_physics_process(false)
	thrown._resolve_hit(blorb)
	_check(blorb.element_state == "", "transformation happened before whiteout")
	while BlorbTransformationUI._busy: await get_tree().process_frame
	_check(blorb.element_state == "fighting", "glove throw did not transform Normal blorb")
	_check(blorb.has_core_item("Boxing Gloves"), "gloves missing from bound accessory")
	_check(ShopCatalog.find("Boxing Gloves").get("core_slot") == "accessory", "gloves have wrong equipment slot")
	_check(not ShopCatalog.find("Fighting Gem").is_empty(), "Fighting Gem missing from item/portrait catalog")
	_check(blorb.body.get_node("FightingGloves").get_child_count() == 2, "expected two gloves without physical arms")
	var eye_y := (blorb._eyes[0] as Node3D).global_position.y
	var glove := blorb.body.get_node("FightingGloves").get_child(0) as Node3D
	var fist_y := (glove.get_child(1) as Node3D).global_position.y
	_check(absf(fist_y - eye_y) < 0.15, "floating glove sits too high above eyes")
	_check(not blorb.can_merge("fighting"), "transformed blorb can merge twice")
	for glove_index in 2:
		var guard_glove := blorb._boxing._gloves[glove_index] as Node3D
		var side := -1.0 if glove_index == 0 else 1.0
		_check((guard_glove.basis.x.normalized() * side).dot(Vector3.UP) > 0.99, "free blorb chamber thumb is not upward")
	blorb._boxing._hand = 0; blorb._boxing._pose(1.0)
	_check(blorb._boxing._gloves[0].basis.z.normalized().dot(Vector3.UP) > 0.99, "free blorb impact orientation changed")
	blorb._boxing._pose(0.0)
	await _capture(blorb, "guard")
	var shiny := BLORB.instantiate() as Blorb; shiny.portrait_mode = true; shiny.is_shiny = true; add_child(shiny)
	_check(not shiny.can_merge("fighting"), "Shiny accepted Fighting conversion")
	shiny.queue_free()
	# A restored party record follows this same existing initial-element path.
	var restored := BLORB.instantiate() as Blorb
	restored.portrait_mode = true; restored.initial_element = blorb.element_state
	restored.core_items.assign(blorb.core_items); add_child(restored)
	_check(restored.core_items.count("Boxing Gloves") == 1 and restored.body.has_node("FightingGloves"), "restored fighter lost/duplicated gloves")
	restored.queue_free()
	blorb.portrait_mode = false; blorb._player = player; blorb._follow_glide_speed = 6.0
	blorb.in_party = true; blorb.allow_movement_hops = false
	var enemy := Opponent.new(); enemy.position = Vector3(0, 0, -4); add_child(enemy); enemy.add_to_group("skeletons")
	for frame in 180:
		await get_tree().physics_frame
		blorb._process(1.0 / 60.0)
	_check(blorb.global_position.distance_to(enemy.global_position) < 1.7, "fighter did not approach NME")
	_check(enemy.hits >= 3 and enemy.last_attacker == blorb, "punches did not damage/credit owning blorb")
	_check(not blorb._hop_is_attack, "fighter still uses body-lunge attack")
	_check(blorb.body.global_basis.z.normalized().dot((enemy.global_position - blorb.global_position).normalized()) > 0.9, "fighter faces away from its opponent")
	# Explicit impact tests isolate timing, range and cover from AI movement.
	blorb._cancel_autonomous_combat(); blorb.position = Vector3.ZERO
	enemy.position = Vector3(0, 0, -1.4)
	blorb._state = Blorb.State.COMBAT; blorb._combat_target = enemy
	var before := enemy.hits
	blorb._try_boxing_attack()
	_check(not blorb._boxing.advance(0.10) and enemy.hits == before, "damage before punch extension")
	if blorb._boxing.advance(0.10): blorb._apply_boxing_damage()
	_check(enemy.hits == before + 1, "impact did not connect exactly once")
	await _capture(blorb, "punch")
	if blorb._boxing.advance(0.20): blorb._apply_boxing_damage()
	_check(enemy.hits == before + 1, "punch dealt repeated damage")
	var wall := StaticBody3D.new(); var collider := CollisionShape3D.new(); var box := BoxShape3D.new()
	box.size = Vector3(4, 3, 0.2); collider.shape = box; wall.add_child(collider); add_child(wall); wall.position = Vector3(0, 1, -0.7)
	await get_tree().physics_frame
	blorb._boxing_target = enemy; blorb._apply_boxing_damage()
	_check(enemy.hits == before + 1, "punched through wall")
	wall.free()
	enemy.position.z = -8
	blorb._boxing_target = enemy; blorb._apply_boxing_damage()
	_check(enemy.hits == before + 1, "punched beyond melee reach")
	enemy.position.z = -1.4
	blorb._attack_cooldown = 0; blorb._try_boxing_attack(); blorb.melt()
	_check(not blorb._boxing.advance(1.0) and blorb._boxing_target == null, "melting retained queued punch")
	blorb._reform(); blorb._state = Blorb.State.COMBAT; blorb._combat_target = enemy
	blorb._try_boxing_attack(); blorb.begin_worn()
	_check(not blorb._boxing.advance(1.0) and blorb._boxing_target == null, "wearing retained queued punch")
	for failure in failures: push_error(failure)
	print("Fighting Blorb proof: %d failures; %d credited punches" % [failures.size(), enemy.hits])
	get_tree().quit(0 if failures.is_empty() else 1)


func _capture(blorb: Blorb, label_text: String) -> void:
	if "--capture" not in OS.get_cmdline_user_args() or DisplayServer.get_name() == "headless": return
	for layer in get_tree().root.get_children():
		if layer is CanvasLayer: layer.visible = false
	var env := WorldEnvironment.new(); var settings := Environment.new()
	settings.background_mode = Environment.BG_COLOR; settings.background_color = Color(0.12, 0.15, 0.18)
	settings.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; settings.ambient_light_color = Color(0.9, 0.94, 1.0); settings.ambient_light_energy = 0.8
	env.environment = settings; add_child(env)
	var light := DirectionalLight3D.new(); light.rotation_degrees = Vector3(-40, -30, 0); add_child(light)
	var camera := Camera3D.new(); add_child(camera)
	camera.position = blorb.position + blorb.body.global_basis.orthonormalized() * Vector3(2.8, 1.8, 4.0)
	camera.look_at(blorb.position + Vector3.UP * 0.6); camera.make_current()
	for frame in 4: await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var output := "res://wip/diagnostics/2026-10-17-fighting-blorb"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	get_viewport().get_texture().get_image().save_png(output + "/" + label_text + ".png")
	camera.queue_free(); light.queue_free(); env.queue_free()
