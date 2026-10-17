extends Node3D

const BUILDER := preload("res://scripts/chinese_village_plan_builder.gd")
const BAKE := preload("res://scripts/settlement_bake.gd")


func _ready() -> void:
	var authored := BUILDER.build(self,Vector2(250,-650),0.0,false)
	# The CSG server evaluates the authored apertures on the deferred frame.
	for i in 3: await get_tree().process_frame
	var root: Node3D=authored.root
	await BUILDER.settle_landscape_pines(root)
	BAKE.prepare(root)
	var packed := PackedScene.new()
	var error := packed.pack(root)
	if error==OK:
		DirAccess.make_dir_recursive_absolute("res://assets/generated")
		error=ResourceSaver.save(packed,BAKE.CACHE_PATH,ResourceSaver.FLAG_COMPRESS)
	if error!=OK:
		push_error("Chinese village bake failed: %s" % error_string(error))
		get_tree().quit(1)
		return
	var manifest := FileAccess.open(BAKE.CACHE_PATH+".sha256",FileAccess.WRITE)
	manifest.store_line(BAKE.signature())
	manifest.close()
	print("Baked Chinese architecture, collision and instanced vegetation: ",BAKE.CACHE_PATH)
	get_tree().quit()
