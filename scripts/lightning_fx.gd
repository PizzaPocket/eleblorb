class_name LightningBolt
extends Node3D

## A real jagged lightning bolt, not a particle spray -- per direct report,
## tuning the ordinary GPUParticles3D soft-billboard technique (see
## particle_fx.gd) for "electric" never stopped reading as a wide spray of
## water/sparks, because a spray of independent particles simply can't
## produce a coherent zigzag LINE the way an actual arc of electricity
## looks. This instead rebuilds a genuine jagged polyline mesh every few
## frames (a fresh random jitter each time, for a flicker/crackle look),
## rendered as a double-crossed quad ribbon (two perpendicular quad strips
## sharing the same centerline) -- the standard cheap trick for a beam/bolt
## effect that reads reasonably from most camera angles without needing
## true per-frame billboard math.
##
## Aimed exactly the way every other elemental stream in this project is:
## the caller sets this node's own position/`look_at()` each frame (see
## player.gd's own _update_water_stream()) -- local -Z is the bolt's own
## "forward," matching that same convention, so this needs no per-caller
## special-casing beyond a dedicated small aiming function (this is a plain
## Node3D, not a GPUParticles3D, so it can't share that function's own
## GPUParticles3D-typed signature -- see player.gd's _update_lightning_
## bolt()).
##
## Deliberately NOT a GPUParticles3D subclass: nothing here uses Godot's
## particle system at all, so subclassing it would just carry unused
## per-frame particle-sim overhead for no benefit.

const RANGE := 6.0
const SEGMENT_COUNT := 9
const JITTER_AMOUNT := 0.16
const REGEN_INTERVAL := 0.045
const THICKNESS := 0.05

## Shared tint constants -- both player.gd (worn arm powers) and blorb.gd
## (a free-roaming blorb's own autonomous combat stream) spawn bolts tinted
## from here, so Electric/City read identically regardless of which script
## is doing the streaming. Bright yellow-white for Electric, cooler
## blue-white for City.
const ELECTRIC_LIGHTNING_COLOR := Color(0.95, 0.85, 0.2)
const CITY_LIGHTNING_COLOR := Color(0.3, 0.6, 1.0)

## Whether the bolt is currently visible/animating -- matches GPUParticles3D's
## own `emitting` property name so callers reasoning about "is this stream
## on" feel consistent across both stream types, even though this is a
## plain bool here, not a real particle-emission toggle.
var emitting: bool = false:
	set(value):
		emitting = value
		if _mesh_instance != null:
			_mesh_instance.visible = value

## Set once at creation (see spawn() below) and left alone -- the whole
## bolt (core-to-edge color range) is built from this single tint.
var color: Color = Color(1.0, 0.95, 0.3)

var _mesh_instance: MeshInstance3D
var _regen_timer: float = 0.0
var _rng := RandomNumberGenerator.new()


static func spawn(parent: Node3D, bolt_color: Color) -> LightningBolt:
	var bolt := LightningBolt.new()
	bolt.color = bolt_color
	parent.add_child(bolt)
	return bolt


func _ready() -> void:
	_rng.randomize()
	_mesh_instance = MeshInstance3D.new()
	_mesh_instance.name = "LightningMesh"
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	material.vertex_color_use_as_albedo = true
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_mesh_instance.material_override = material
	_mesh_instance.visible = false
	add_child(_mesh_instance)


func _process(delta: float) -> void:
	if not emitting:
		return
	_regen_timer -= delta
	if _regen_timer <= 0.0:
		_regen_timer = REGEN_INTERVAL
		_regenerate()


## Builds a fresh jittered polyline from local origin to local
## Vector3(0, 0, -RANGE) and renders it as a double-crossed quad ribbon.
## Rebuilt from scratch (not eased from the previous shape) every
## REGEN_INTERVAL -- a real arc doesn't interpolate smoothly between two
## jagged shapes, it just jumps, which IS the flicker/crackle look.
func _regenerate() -> void:
	var points: Array[Vector3] = []
	points.append(Vector3.ZERO)
	for i in range(1, SEGMENT_COUNT):
		var t := float(i) / float(SEGMENT_COUNT)
		var point := Vector3(0.0, 0.0, -RANGE * t)
		var side := Vector3(_rng.randf_range(-1.0, 1.0), _rng.randf_range(-1.0, 1.0), 0.0)
		if side.length_squared() > 0.0001:
			side = side.normalized()
		# Tapered to zero at both ends (sin(t*PI) peaks at the midpoint) so
		# the bolt never visibly detaches from its own source or target.
		var taper := sin(t * PI)
		point += side * JITTER_AMOUNT * taper
		points.append(point)
	points.append(Vector3(0.0, 0.0, -RANGE))
	_mesh_instance.mesh = _build_ribbon_mesh(points)


func _build_ribbon_mesh(points: Array[Vector3]) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var hot := Color(1.0, 1.0, 1.0, 1.0)
	for i in points.size() - 1:
		var a := points[i]
		var b := points[i + 1]
		var dir := (b - a).normalized()
		var up := Vector3.UP
		var right := dir.cross(up)
		if right.length_squared() < 0.0001:
			right = Vector3.RIGHT
		right = right.normalized() * THICKNESS
		var cross_axis := dir.cross(right).normalized() * THICKNESS
		# Per-segment brightness rolled fresh each regeneration -- a real
		# arc doesn't glow evenly along its own length, some stretches read
		# brighter/hotter than others at any given instant.
		var segment_color := hot.lerp(color, _rng.randf_range(0.15, 0.75))
		segment_color.a = _rng.randf_range(0.75, 1.0)
		_add_quad(st, a - right, a + right, b + right, b - right, segment_color)
		_add_quad(st, a - cross_axis, a + cross_axis, b + cross_axis, b - cross_axis, segment_color)
	st.generate_normals()
	return st.commit()


static func _add_quad(st: SurfaceTool, p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3, quad_color: Color) -> void:
	st.set_color(quad_color)
	st.add_vertex(p0)
	st.set_color(quad_color)
	st.add_vertex(p1)
	st.set_color(quad_color)
	st.add_vertex(p2)
	st.set_color(quad_color)
	st.add_vertex(p0)
	st.set_color(quad_color)
	st.add_vertex(p2)
	st.set_color(quad_color)
	st.add_vertex(p3)
