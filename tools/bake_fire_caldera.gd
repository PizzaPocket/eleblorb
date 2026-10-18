extends Node

## Build the live Fire settlement in the editor process, then serialize its
## authored roof CSG as static geometry. Roof dimensions still come from the
## ordinary building constructors; this tool only converts their result.
const FireCalderaBake := preload("res://scripts/fire_caldera_bake.gd")
const SettlementBake := preload("res://scripts/settlement_bake.gd")

func _ready() -> void:
	FireCalderaBake.begin_bake()
	var world := Node3D.new()
	world.name = "FireCalderaBakeSource"
	add_child(world)
	var terrain: Node3D = (load("res://scripts/fire_kingdom_terrain.gd") as GDScript).new()
	terrain.name = "Terrain"
	world.add_child(terrain)
	var village: Node3D = (load("res://scripts/fire_kingdom_village.gd") as GDScript).new()
	village.name = "CalderaVillage"
	world.add_child(village)
	await LoadingScreen.wait_for_world_builds()
	var library := Node3D.new()
	library.name = "FireCalderaRoofLibrary"
	var roots := world.find_children("*", "CSGCombiner3D", true, false)
	print("FIRE_BAKE_TREE children=%d csg=%d" % [world.get_child_count(), roots.size()])
	var baked_count := 0
	for candidate: Node in roots:
		if not is_instance_valid(candidate) or not candidate.has_meta("fire_caldera_roof_key"):
			continue
		var original := candidate as CSGCombiner3D
		if original == null:
			continue
		var key := str(original.get_meta("fire_caldera_roof_key"))
		var wrapper := Node3D.new()
		wrapper.name = "Roof_%s" % key
		var csg := original.duplicate(Node.DUPLICATE_USE_INSTANTIATION) as CSGCombiner3D
		wrapper.add_child(csg)
		library.add_child(wrapper)
		SettlementBake.prepare(wrapper)
		baked_count += 1
	if baked_count == 0:
		push_error("Fire Caldera bake found no keyed roof CSG roots")
		get_tree().quit(1)
		return
	SettlementBake._set_owners(library, library)
	var packed := PackedScene.new()
	var pack_error := packed.pack(library)
	if pack_error != OK:
		push_error("Could not pack Fire Caldera roofs: %s" % error_string(pack_error))
		get_tree().quit(1)
		return
	var save_error := ResourceSaver.save(packed, FireCalderaBake.CACHE_PATH)
	if save_error != OK:
		push_error("Could not save Fire Caldera roof bake: %s" % error_string(save_error))
		get_tree().quit(1)
		return
	var manifest := FileAccess.open(FireCalderaBake.CACHE_PATH + ".sha256", FileAccess.WRITE)
	if manifest == null:
		push_error("Could not write Fire Caldera roof signature")
		get_tree().quit(1)
		return
	manifest.store_string(FireCalderaBake.signature() + "\n")
	manifest.close()
	print("BAKED_FIRE_CALDERA_ROOFS count=%d signature=%s" % [baked_count, FireCalderaBake.signature()])
	get_tree().quit(0)
