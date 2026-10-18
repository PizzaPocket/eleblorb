class_name FireCalderaBake
extends RefCounted

## Offline roof CSG bake. Geometry is authored by the live building builders,
## converted to static meshes and collision in a tool scene, then keyed by the
## exact roof parameters those same builders pass at runtime.
const CACHE_PATH := "res://assets/generated/fire_caldera_roofs.scn"
const SOURCES := [
	"scripts/caldera_shell.gd", "scripts/solid_model.gd", "scripts/collision_policy.gd",
	"scripts/settlement_bake.gd", "scripts/loading_screen.gd", "scripts/fire_kingdom_terrain.gd", "scripts/fire_kingdom_village.gd",
	"scripts/fire_caldera_plan.gd", "scripts/fire_caldera_walkways_plan.gd", "scripts/fire_caldera_heartworks_plan.gd",
	"scripts/fire_caldera_plan_walks.gd", "scripts/fire_caldera_highline.gd", "scripts/fire_caldera_funicular.gd",
	"scripts/fire_caldera_ground.gd", "scripts/fire_caldera_heartworks.gd", "scripts/fire_caldera_buildings.gd", "scripts/fire_caldera_aro.gd",
	"scripts/fire_caldera_civic.gd", "scripts/fire_caldera_iren.gd", "scripts/fire_caldera_kel.gd",
	"scripts/fire_caldera_nahl.gd", "scripts/fire_caldera_oren.gd", "scripts/fire_caldera_renewal.gd",
	"scripts/fire_caldera_vara.gd", "scripts/village_inn.gd", "tools/fire_caldera_walkways_layout.py",
	"tools/fire_caldera_heartworks_layout.py", "tools/walkway_kit.py", "tools/bake_fire_caldera.gd",
]
static var _checked := false
static var _is_valid := false
static var _library: PackedScene
static var _stale_reported := false
static var _bake_in_progress := false


static func begin_bake() -> void:
	_bake_in_progress = true


static func roof_key(offset: Vector2, size: Vector2, top: float, rake: float, overhang: Dictionary, skylights: Array, colour: Color, pitch: float) -> String:
	var data := {
		"offset": [offset.x, offset.y], "size": [size.x, size.y], "top": top, "rake": rake,
		"overhang": overhang, "skylights": skylights, "colour": [colour.r, colour.g, colour.b, colour.a], "pitch": pitch,
	}
	var hash_context := HashingContext.new()
	hash_context.start(HashingContext.HASH_SHA256)
	hash_context.update(JSON.stringify(data).to_utf8_buffer())
	return hash_context.finish().hex_encode().substr(0, 20)


static func signature() -> String:
	var hash_context := HashingContext.new()
	hash_context.start(HashingContext.HASH_SHA256)
	for source: String in SOURCES:
		var path := "res://" + source
		if not FileAccess.file_exists(path):
			return "MISSING:" + source
		hash_context.update(FileAccess.get_file_as_bytes(path))
	return hash_context.finish().hex_encode()


static func valid() -> bool:
	if not _checked:
		_checked = true
		var manifest := CACHE_PATH + ".sha256"
		_is_valid = FileAccess.file_exists(manifest) and ResourceLoader.exists(CACHE_PATH) \
			and FileAccess.get_file_as_string(manifest).strip_edges() == signature()
		if _is_valid:
			_library = load(CACHE_PATH) as PackedScene
	if not _is_valid and not _stale_reported and not _bake_in_progress:
		_stale_reported = true
		push_error("Fire Caldera roof bake is missing or stale; run tools/bake_fire_caldera.tscn")
	return _is_valid


static func instantiate_roof(key: String, parent: Node3D) -> Node3D:
	if not valid() or _library == null:
		return null
	var root := _library.instantiate() as Node3D
	if root == null:
		return null
	var template := root.get_node_or_null("Roof_%s" % key) as Node3D
	if template == null:
		root.free()
		push_error("Fire Caldera roof bake has no entry for key %s" % key)
		return null
	var roof := template.duplicate(Node.DUPLICATE_USE_INSTANTIATION) as Node3D
	root.free()
	parent.add_child(roof)
	return roof
