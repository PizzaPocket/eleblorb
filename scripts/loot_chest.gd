extends StaticBody3D

## Reusable, collidable chest with a physically hinged lid. A stable loot_id
## makes its contents one-time campaign loot while the chest itself remains
## available to open and shut on later visits.

var _lid_hinge: StaticBody3D
var _area: Area3D
var _is_open := false
var _moving := false
var _loot_id := ""
var _loot: Array[Dictionary] = []
var _contents: Array[Dictionary] = []


func configure(
	loot_id: String, loot: Array[Dictionary], wood: Color,
	length: float = 0.9
) -> void:
	name = "LootChest" if loot_id == "" else "LootChest_%s" % loot_id
	collision_layer = 1
	collision_mask = 0
	_loot_id = loot_id
	_loot.assign(loot)
	_is_open = loot_id != "" and WorldState.is_collected(loot_id)
	# A hollow carcase: floor, front and back boards and two ends, so the inside
	# is a real space (items rest in it, and it is seen when the lid is up). One
	# solid box stands in for it in physics, since nobody walks into a chest.
	var wall := 0.04
	var carcase: Array[Dictionary] = [
		{"half": Vector3(length * 0.5 - wall, 0.025, 0.28 - wall), "at": Vector3(0.0, 0.05, 0.0)},
		{"half": Vector3(length * 0.5, 0.22, wall * 0.5), "at": Vector3(0.0, 0.22, -0.28 + wall * 0.5)},
		{"half": Vector3(length * 0.5, 0.22, wall * 0.5), "at": Vector3(0.0, 0.22, 0.28 - wall * 0.5)},
		{"half": Vector3(wall * 0.5, 0.22, 0.28 - wall), "at": Vector3(-length * 0.5 + wall * 0.5, 0.22, 0.0)},
		{"half": Vector3(wall * 0.5, 0.22, 0.28 - wall), "at": Vector3(length * 0.5 - wall * 0.5, 0.22, 0.0)},
	]
	var base: MeshInstance3D = null
	for part: Dictionary in carcase:
		var board := SuperEgg.build_part(part["half"] as Vector3, wood, SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT)
		board.position = part["at"] as Vector3
		add_child(board)
		if base == null:
			base = board
		else:
			CollisionPolicy.mark_decorative(board)
	var carcase_centre := Vector3(0.0, 0.22, 0.0)
	ClearZones.mark_furniture(CollisionPolicy.add_box(self, base, Vector3(length, 0.44, 0.56), carcase_centre, Basis(), true))
	_lid_hinge = StaticBody3D.new()
	_lid_hinge.collision_layer = 1
	_lid_hinge.collision_mask = 0
	_lid_hinge.position = Vector3(0.0, 0.44, 0.28)
	add_child(_lid_hinge)
	var lid := SuperEgg.build_part(Vector3(length * 0.5 + 0.02, 0.05, 0.29), wood.lightened(0.1), SuperEgg.EPSILON_SOFT, SuperEgg.EPSILON_FLAT)
	lid.position = Vector3(0.0, 0.05, -0.28)
	_lid_hinge.add_child(lid)
	var lid_collision := CollisionShape3D.new()
	var lid_shape := BoxShape3D.new()
	lid_shape.size = Vector3(length + 0.04, 0.10, 0.58)
	lid_collision.shape = lid_shape
	lid_collision.position = lid.position
	_lid_hinge.add_child(lid_collision)
	var lock_plate := SuperEgg.build_part(Vector3(0.06, 0.07, 0.02), Color(0.8, 0.62, 0.22), 2.4, 2.4)
	lock_plate.position = Vector3(0.0, 0.36, -0.29)
	add_child(lock_plate)
	CollisionPolicy.mark_decorative(lock_plate)
	_lid_hinge.rotation.x = deg_to_rad(105.0) if _is_open else 0.0
	_area = Interactable.attach(self, _prompt(), 2.0, _activate, Callable(), Callable(), true, 1.0)
	_build_physical_contents(length)
	_set_contents_available(_is_open)


func _prompt() -> String:
	return "Close chest" if _is_open else "Open chest"


func _activate() -> void:
	if _moving:
		return
	_is_open = not _is_open
	_moving = true
	if _is_open:
		UISounds.play_foley(&"chest_open", 0.55, get_instance_id())
		# Opening reveals something special: the discovery sting, as the lid clears.
		if _has_uncollected_special():
			get_tree().create_timer(0.3).timeout.connect(func() -> void: UISounds.play_special_find())
	else:
		get_tree().create_timer(0.3).timeout.connect(func() -> void:
			if is_instance_valid(self) and is_inside_tree():
				UISounds.play_foley(&"chest_close", 0.58, get_instance_id())
		)
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(_lid_hinge, "rotation:x", deg_to_rad(105.0) if _is_open else 0.0, 0.38)
	tween.finished.connect(func() -> void: _moving = false)
	_set_contents_available(_is_open)
	if is_instance_valid(_area):
		_area.set_meta("prompt", _prompt())


## Contents are real world items, not a reward packet fired by the lid. Each
## quantity gets its own stable collection id, visual, and interaction. This
## lets opening reveal the cache and leaves the satisfying pickup to the
## player while still surviving scene reloads correctly.
func _build_physical_contents(length: float) -> void:
	if _loot_id == "" or WorldState.is_collected(_loot_id):
		return
	var expanded: Array[Dictionary] = []
	for entry in _loot:
		var quantity := maxi(int(entry.get("quantity", 1)), 1)
		for count in quantity:
			expanded.append(entry)
	var remaining_index := 0
	for index in expanded.size():
		var item_id := "%s_item_%d" % [_loot_id,index]
		if WorldState.is_collected(item_id):
			continue
		var entry := expanded[index]
		var item_name := str(entry.get("name", ""))
		var catalog := ShopCatalog.find(item_name)
		var color: Color = entry.get("color",catalog.get("color",Color.WHITE))
		var holder := Node3D.new()
		holder.name = "ChestItem_%s_%d" % [item_name.replace(" ",""),index]
		var columns := mini(expanded.size(),3)
		var row := int(remaining_index/3)
		var column := remaining_index%3
		var spacing := minf(0.25,length/maxf(float(columns),1.0))
		holder.position = Vector3((float(column)-float(columns-1)*0.5)*spacing,0.13+float(row)*0.1,-0.04+float(row)*0.1)
		var visual: Node3D
		var builder: Callable = catalog.get("build_visual",Callable())
		if builder.is_valid():
			visual = builder.call(0.42) as Node3D
		else:
			visual = SuperEgg.build_part(Vector3(0.08,0.06,0.08),color,2.4,2.4)
		holder.add_child(visual)
		add_child(holder)
		var area := Interactable.attach(
			holder,"Pick up %s" % item_name.to_lower(),0.72,
			Callable(self,"_collect_item").bind(item_id,holder,item_name,color),
			Callable(),Callable(),true,0.75
		)
		area.set_meta("interaction_priority",1.25)
		_contents.append({"node":holder,"area":area})
		remaining_index += 1


func _set_contents_available(available: bool) -> void:
	for content in _contents:
		var node := content.get("node") as Node3D
		var area := content.get("area") as Area3D
		if is_instance_valid(node):
			node.visible = available
		if is_instance_valid(area):
			# Deferred because a chest can be closed while an Area callback is
			# unwinding from the same physics frame.
			area.set_deferred("monitoring",available)
			area.set_deferred("monitorable",available)


func _collect_item(item_id: String,node: Node3D,item_name: String,color: Color) -> void:
	if not _is_open or WorldState.is_collected(item_id):
		return
	WorldState.mark_collected(item_id)
	if item_name == "Tokoin":
		TokoinWallet.add(1)
	else:
		Inventory.add(item_name,color)
	Hud.show_message("Picked up %s." % item_name)
	if is_instance_valid(node):
		node.queue_free()
	if _all_contents_collected():
		WorldState.mark_collected(_loot_id)


## A "special" item is flagged in the loot entry (`"special": true`) or is a
## non-purchasable piece of gear (a helm or other core item found, not bought).
func _has_uncollected_special() -> bool:
	var index := 0
	for entry in _loot:
		var quantity := maxi(int(entry.get("quantity",1)),1)
		var catalog := ShopCatalog.find(str(entry.get("name","")))
		var special := bool(entry.get("special",false)) or (
			str(catalog.get("core_item","")) != "" and not bool(catalog.get("purchasable",false))
		)
		for count in quantity:
			if special and not WorldState.is_collected("%s_item_%d" % [_loot_id,index]):
				return true
			index += 1
	return false


func _all_contents_collected() -> bool:
	var index := 0
	for entry in _loot:
		var quantity := maxi(int(entry.get("quantity",1)),1)
		for count in quantity:
			if not WorldState.is_collected("%s_item_%d" % [_loot_id,index]):
				return false
			index += 1
	return true
