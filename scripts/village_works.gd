class_name VillageWorks
extends RefCounted

## Working-landscape props shared by the villages: a masonry-lined managed
## channel, footbridge, timber and log stacks, cart shelter, mason's stone yard,
## woven hedge and a roof bell gablet. Everything is built from SuperEgg parts
## with its collider authored beside its visual (CollisionPolicy), and every
## function takes a `ground` Callable (Vector2 -> float) so the caller's own
## terrain sampling places it.
##
## All positions are in the PARENT node's XZ space.

const STONE := Color(0.60, 0.58, 0.55)
const STONE_DARK := Color(0.46, 0.44, 0.42)
const WATER := Color(0.16, 0.45, 0.68)
const PLANK := Color(0.62, 0.45, 0.27)
const PLANK_DARK := Color(0.45, 0.31, 0.18)
const LOG := Color(0.40, 0.27, 0.16)
const LOG_END := Color(0.66, 0.50, 0.30)
const HEDGE := Color(0.18, 0.40, 0.17)
const BRASS := Color(0.80, 0.62, 0.22)
const CURB_HEIGHT := 0.5
const CURB_THICKNESS := 0.4
const WATER_LEVEL := 0.3
const OHIO_GRASS := Color(0.07451, 0.63922, 0.40392)
const SHARED_WATER_SHADER: Shader = preload("res://scripts/ocean_water.gdshader")


static func _ground(ground: Callable, at: Vector2) -> float:
	var height: float = ground.call(at)
	return height


static func _part(
	body: StaticBody3D, half: Vector3, color: Color, position: Vector3, basis: Basis = Basis(),
	solid: bool = true, parkour: bool = true, epsilon: float = SuperEgg.EPSILON_FLAT
) -> MeshInstance3D:
	var mesh := SuperEgg.build_part(half, color, epsilon, SuperEgg.EPSILON_FLAT)
	mesh.transform = Transform3D(basis, position)
	body.add_child(mesh)
	if solid:
		CollisionPolicy.add_box(body, mesh, half * 2.0, position, basis, parkour)
	else:
		CollisionPolicy.mark_decorative(mesh)
	return mesh


## A small building's roof as a true roof slab (TownProps.roof_slab, the shared
## thickness and edge), replacing a thin rounded box of half-thickness
## `old_half`: its underside stays where that box's was, so the posts and walls
## cut to meet it still do. `half` is (across, along); `basis` y is its normal.
static func _roof_slab(body: StaticBody3D, half: Vector2, color: Color, centre: Vector3, basis: Basis, old_half: float) -> void:
	var at := centre + basis.y * (TownProps.ROOF_THICKNESS * 0.5 - old_half)
	var slab := TownProps.roof_slab(Vector3(half.x, TownProps.ROOF_THICKNESS * 0.5, half.y), color)
	slab.transform = Transform3D(basis, at)
	body.add_child(slab)
	CollisionPolicy.add_box(body, slab, Vector3(half.x * 2.0, TownProps.ROOF_THICKNESS, half.y * 2.0), at, basis, true)


static func _body(parent: Node3D, node_name: String, position: Vector3 = Vector3.ZERO, yaw: float = 0.0) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = node_name
	body.collision_layer = 1
	body.collision_mask = 0
	body.position = position
	body.rotation.y = yaw
	parent.add_child(body)
	return body


## Yaw that turns a local +Z axis toward `direction` (XZ).
static func yaw_along(direction: Vector2) -> float:
	return atan2(direction.x, direction.y)


## Yaw that turns an object's local -Z (the lit side of every lantern, the front
## of a door or a sign) from `from` toward `toward`. yaw_along() above points
## local +Z along a direction instead, which is the opposite end: using it for
## a lantern points its bracket away from the street it serves.
static func yaw_facing(from: Vector2, toward: Vector2) -> float:
	var direction := toward - from
	return atan2(-direction.x, -direction.y)


# ---------------------------------------------------------------------------
# Managed stream
# ---------------------------------------------------------------------------

static func water_material() -> ShaderMaterial:
	# One two-sided water treatment for village ponds, channels and lakes. From
	# below it becomes the same bright translucent ceiling proven in the demo
	# ocean instead of an opaque blue polygon hiding the world above.
	var material := ShaderMaterial.new()
	material.shader = SHARED_WATER_SHADER
	material.set_shader_parameter(
		"surface_color",
		Color(TownProps.WATER_COLOR.r,TownProps.WATER_COLOR.g,TownProps.WATER_COLOR.b,0.76)
	)
	return material


## Orders a triangle so it faces up.
static func _up_triangle(tool: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	var facing := (c - a).cross(b - a)
	var second := b if facing.y >= 0.0 else c
	var third := c if facing.y >= 0.0 else b
	for vertex in [a, second, third]:
		tool.set_normal(Vector3.UP)
		tool.add_vertex(vertex)


## A masonry aqueduct: a solid causeway carrying a stone-curbed channel whose
## floor follows `beds` (floor height at each sample), with ONE continuous
## water surface running its whole length. The causeway reaches down to the
## ground, so it is a raised embankment wherever the floor stands above it.
static func build_aqueduct(
	parent: Node3D, samples: Array[Vector2], beds: Array[float], width: float,
	ground: Callable, node_name: String = "Aqueduct"
) -> StaticBody3D:
	var body := _body(parent, node_name)
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var left: Array[Vector3] = []
	var right: Array[Vector3] = []
	for i in samples.size():
		var before := samples[maxi(i - 1, 0)]
		var after := samples[mini(i + 1, samples.size() - 1)]
		var tangent := (after - before).normalized()
		var normal := Vector2(-tangent.y, tangent.x)
		var surface_y := beds[i] + WATER_LEVEL
		var a := samples[i] + normal * width * 0.5
		var b := samples[i] - normal * width * 0.5
		left.append(Vector3(a.x, surface_y, a.y))
		right.append(Vector3(b.x, surface_y, b.y))
	for i in samples.size() - 1:
		var a := samples[i]
		var b := samples[i + 1]
		var delta := b - a
		var length := delta.length()
		if length < 0.01:
			continue
		var direction := delta / length
		var normal := Vector2(-direction.y, direction.x)
		var middle := (a + b) * 0.5
		var bed := (beds[i] + beds[i + 1]) * 0.5
		var basis := Basis(Vector3.UP, yaw_along(direction))
		var base := _ground(ground, middle)
		var bottom := minf(base, bed) - 0.3
		var core_height := bed - bottom
		_part(
			body, Vector3(width * 0.5 + CURB_THICKNESS, core_height * 0.5, length * 0.5 + 0.12), STONE_DARK,
			Vector3(middle.x, bottom + core_height * 0.5, middle.y), basis
		)
		for side: float in [-1.0, 1.0]:
			var at := middle + normal * side * (width * 0.5 + CURB_THICKNESS * 0.5)
			_part(
				body, Vector3(CURB_THICKNESS * 0.5, CURB_HEIGHT * 0.5, length * 0.5 + 0.12), STONE,
				Vector3(at.x, bed + CURB_HEIGHT * 0.5, at.y), basis, true, true, SuperEgg.EPSILON_SOFT
			)
		_up_triangle(tool, left[i], right[i], left[i + 1])
		_up_triangle(tool, left[i + 1], right[i], right[i + 1])
	var water := MeshInstance3D.new()
	water.name = "AqueductWater"
	water.mesh = tool.commit()
	water.material_override = water_material()
	water.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	body.add_child(water)
	CollisionPolicy.mark_decorative(water)
	return body


const CASCADE_SHADER := """
shader_type spatial;
render_mode cull_disabled;
uniform vec4 water_color : source_color = vec4(0.08, 0.28, 0.55, 1.0);
uniform vec4 foam_color : source_color = vec4(0.94, 0.98, 1.0, 1.0);
uniform float speed = 2.4;
void fragment() {
	float across = abs(UV.x - 0.5) * 2.0;
	float streak = sin(UV.y * 1.7 - TIME * speed + sin(UV.x * 17.0) * 1.6);
	float streak2 = sin(UV.y * 0.9 - TIME * speed * 0.7 + UV.x * 23.0);
	float foam = smoothstep(0.55, 0.95, streak * 0.6 + streak2 * 0.5);
	foam = max(foam * 0.55, smoothstep(0.72, 1.0, across) * 0.8);
	ALBEDO = mix(water_color.rgb, foam_color.rgb, foam);
	ROUGHNESS = 0.08;
	METALLIC = 0.1;
}
"""


## Water running down the terrain from `centre` (Vector2 positions, with
## `start_y` the surface height it leaves the channel at) to the shore. The
## ribbon is draped on the actual ground, edge by edge, so it reads as a
## cascade down the slope; its surface scrolls with foam.
static func build_cascade(
	parent: Node3D, centre: Array[Vector2], widths: Array[float], start_y: float,
	shore_y: float, ground: Callable, node_name: String = "Cascade", heights: Array[float] = []
) -> MeshInstance3D:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rows: Array = []
	var travelled := 0.0
	for i in centre.size():
		var before := centre[maxi(i - 1, 0)]
		var after := centre[mini(i + 1, centre.size() - 1)]
		var tangent := (after - before).normalized()
		var normal := Vector2(-tangent.y, tangent.x)
		if i > 0:
			travelled += centre[i].distance_to(centre[i - 1])
		var half := widths[i] * 0.5
		var a := centre[i] + normal * half
		var b := centre[i] - normal * half
		var ya := maxf(_ground(ground, a) + 0.16, shore_y + 0.1)
		var yb := maxf(_ground(ground, b) + 0.16, shore_y + 0.1)
		if i == 0:
			ya = start_y
			yb = start_y
		# A free-falling arc carries its own heights instead of hugging the ground.
		if not heights.is_empty():
			ya = heights[i]
			yb = heights[i]
		rows.append({"l": Vector3(a.x, ya, a.y), "r": Vector3(b.x, yb, b.y), "v": travelled})
	for i in rows.size() - 1:
		var r0: Dictionary = rows[i]
		var r1: Dictionary = rows[i + 1]
		var corners: Array = [
			[r0["l"], Vector2(0.0, r0["v"])], [r0["r"], Vector2(1.0, r0["v"])],
			[r1["l"], Vector2(0.0, r1["v"])], [r1["r"], Vector2(1.0, r1["v"])],
		]
		for triple in [[0, 1, 2], [2, 1, 3]]:
			for index in triple:
				tool.set_normal(Vector3.UP)
				tool.set_uv(corners[index][1])
				tool.add_vertex(corners[index][0])
	var shader := Shader.new()
	shader.code = CASCADE_SHADER
	var material := ShaderMaterial.new()
	material.shader = shader
	var water := MeshInstance3D.new()
	water.name = node_name
	water.mesh = tool.commit()
	water.material_override = material
	water.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(water)
	CollisionPolicy.mark_decorative(water)
	return water


const FALL_SHADER := """
shader_type spatial;
render_mode cull_disabled;
uniform vec4 water_color : source_color = vec4(0.30, 0.52, 0.70, 1.0);
uniform vec4 foam_color : source_color = vec4(0.95, 0.98, 1.0, 1.0);
uniform float speed = 3.4;
void fragment() {
	// Streaks run down the fall (UV.y is distance fallen) and wrap round it
	// (UV.x goes once round the cross-section).
	float wrap = UV.x * 6.2831;
	// Long streaks down the fall that waver as the water shifts, pulsed by
	// slugs of white water travelling down them.
	float lanes = sin(wrap * 9.0 + sin(UV.y * 0.32 - TIME * speed * 0.55 + wrap * 2.0) * 1.6);
	float lanes2 = sin(wrap * 5.0 - 1.3 + sin(UV.y * 0.21 - TIME * speed * 0.4) * 2.1);
	float pulses = sin(UV.y * 0.55 - TIME * speed) * 0.5 + 0.5;
	float foam = smoothstep(0.25, 0.95, lanes * 0.55 + lanes2 * 0.35 + pulses * 0.35);
	// The water whitens as it falls and breaks up.
	foam = max(foam, clamp(UV.y * 0.012, 0.0, 0.55));
	ALBEDO = mix(water_color.rgb, foam_color.rgb, foam);
	ROUGHNESS = 0.12;
	METALLIC = 0.05;
}
"""


## Water leaving a spout at `mouth` (world-frame point in `parent`), moving
## horizontally along `direction` at `speed` m/s and falling freely to
## `base_y`: a tube along the true arc, not a flat ribbon. Its cross-section is
## a flat sheet where it leaves the lip and swells into a rounder, wider column
## as it falls and breaks up, so it has body from every side.
static func build_fall(
	parent: Node3D, mouth: Vector3, direction: Vector2, speed: float, width: float,
	base_y: float, node_name: String = "WaterFall"
) -> MeshInstance3D:
	const RING := 14
	const SAMPLES := 48
	var drop := maxf(mouth.y - base_y, 0.5)
	var fall_time := sqrt(2.0 * drop / 9.81)
	var dir3 := Vector3(direction.x, 0.0, direction.y).normalized()
	var side := Vector3(-dir3.z, 0.0, dir3.x)
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rings: Array = []
	var travelled := 0.0
	var previous := mouth
	for k in SAMPLES + 1:
		var t := fall_time * float(k) / float(SAMPLES)
		var at := mouth + dir3 * speed * t + Vector3.DOWN * (0.5 * 9.81 * t * t)
		var velocity := dir3 * speed + Vector3.DOWN * (9.81 * t)
		var forward := velocity.normalized()
		var up := side.cross(forward).normalized()
		var f := float(k) / float(SAMPLES)
		var half_w := width * 0.5 * (1.0 + 0.9 * f)
		var half_d := lerpf(0.14, half_w * 0.75, smoothstep(0.0, 0.6, f))
		if k > 0:
			travelled += at.distance_to(previous)
		previous = at
		var ring: Array = []
		for i in RING + 1:
			var a := TAU * float(i) / float(RING)
			ring.append({"p": at + side * cos(a) * half_w + up * sin(a) * half_d, "n": (side * cos(a) / half_w + up * sin(a) / half_d).normalized(), "uv": Vector2(float(i) / float(RING), travelled)})
		rings.append(ring)
	for k in SAMPLES:
		for i in RING:
			var a: Dictionary = rings[k][i]
			var b: Dictionary = rings[k][i + 1]
			var c: Dictionary = rings[k + 1][i]
			var d: Dictionary = rings[k + 1][i + 1]
			for v: Dictionary in [a, c, b, b, c, d]:
				tool.set_normal(v["n"])
				tool.set_uv(v["uv"])
				tool.add_vertex(v["p"])
	var shader := Shader.new()
	shader.code = FALL_SHADER
	var material := ShaderMaterial.new()
	material.shader = shader
	var water := MeshInstance3D.new()
	water.name = node_name
	water.mesh = tool.commit()
	water.material_override = material
	water.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(water)
	CollisionPolicy.mark_decorative(water)
	return water


## A small spring-fed reservoir: a raised sheet of water held by an earth
## berm, with a stone dam where the channel leaves it (toward `outlet`).
static func build_reservoir(
	parent: Node3D, center: Vector2, radius: float, level_y: float, outlet: Vector2, ground: Callable
) -> void:
	var body := _body(parent, "SpringReservoir")
	var base := _ground(ground, center)
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rim: Array[Vector3] = []
	var segments := 28
	for i in segments:
		var angle := TAU * float(i) / float(segments)
		var wobble := 1.0 + 0.07 * sin(angle * 3.0 + 1.1) + 0.04 * cos(angle * 5.0)
		var point := center + Vector2(cos(angle), sin(angle)) * radius * wobble
		rim.append(Vector3(point.x, level_y, point.y))
	var hub := Vector3(center.x, level_y, center.y)
	for i in segments:
		_up_triangle(tool, hub, rim[(i + 1) % segments], rim[i])
	var water := MeshInstance3D.new()
	water.name = "ReservoirWater"
	water.mesh = tool.commit()
	water.material_override = water_material()
	water.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	body.add_child(water)
	CollisionPolicy.mark_decorative(water)
	# Earth berm all the way round, except the outlet.
	var outlet_angle := atan2(outlet.y - center.y, outlet.x - center.x)
	var berm_top := level_y + 0.45
	var berm_segments := 24
	var berm_color := Color(0.16, 0.50, 0.30)
	for i in berm_segments:
		var angle := TAU * (float(i) + 0.5) / float(berm_segments)
		if absf(angle_difference(angle, outlet_angle)) < 0.32:
			continue
		var ring := radius + 0.9
		var at := center + Vector2(cos(angle), sin(angle)) * ring
		var chord := 2.0 * ring * sin(PI / float(berm_segments))
		var low := minf(base, _ground(ground, at)) - 0.3
		var height := berm_top - low
		var tangent_basis := Basis(Vector3.UP, atan2(-cos(angle), -sin(angle)))
		_part(
			body, Vector3(chord * 0.5 + 0.35, height * 0.5, 1.2), berm_color.lightened(0.03 * float(i % 3)),
			Vector3(at.x, low + height * 0.5, at.y), tangent_basis, true, true, SuperEgg.EPSILON_SOFT
		)


## Water for a terrain-native spring pond.  There is intentionally no berm:
## the terrain generator supplies the bowl and natural bank.  The last metres
## of this irregular water sheet continue under that bank so no dry seam can
## ever appear between the two surfaces.
static func build_natural_pond(
	parent: Node3D,center: Vector2,radius: float,level_y: float,seed_value: int = 9917
) -> MeshInstance3D:
	var rng:=RandomNumberGenerator.new()
	rng.seed=seed_value
	var segments:=48
	var radii: Array[float]=[]
	for i in segments:
		var angle:=TAU*float(i)/float(segments)
		var broad:=sin(angle*3.0+0.8)*0.065+cos(angle*5.0-0.35)*0.035
		radii.append(radius*(1.0+broad)+rng.randf_range(-0.28,0.28))
	var tool:=SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var hub:=Vector3(center.x,level_y,center.y)
	for i in segments:
		var a:=TAU*float(i)/float(segments)
		var b:=TAU*float((i+1)%segments)/float(segments)
		var pa:=Vector3(center.x+cos(a)*radii[i],level_y,center.y+sin(a)*radii[i])
		var pb:=Vector3(center.x+cos(b)*radii[(i+1)%segments],level_y,center.y+sin(b)*radii[(i+1)%segments])
		_up_triangle(tool,hub,pb,pa)
	var water:=MeshInstance3D.new()
	water.name="NaturalSpringPondWater"
	water.mesh=tool.commit()
	water.material_override=water_material()
	water.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(water)
	CollisionPolicy.mark_decorative(water)
	return water


## A locally tessellated continuation of the real terrain around Ohio's
## spring pond. The outskirts height field is intentionally very coarse at
## this distance (one vertex roughly every 18 m), which is fine for broad
## hills but cannot describe a small shoreline without faceting it into a
## handful of giant triangles. This annular patch samples the same ground at
## its outer edge, then supplies enough intermediate rings for a smooth,
## irregular bank. Its inner edge is submerged beneath the water mesh, so the
## shoreline is an overlap rather than a fragile coincident seam.
static func build_natural_pond_bank(
	parent: Node3D,center: Vector2,water_radius: float,water_level: float,
	outer_radius: float,ground: Callable,seed_value: int = 9917
) -> StaticBody3D:
	var body:=_body(parent,"NaturalSpringPondBank")
	var rng:=RandomNumberGenerator.new()
	rng.seed=seed_value
	const SEGMENTS:=72
	var ring_fractions: Array[float]=[0.0,0.20,0.43,0.68,1.0]
	var ring_radii: Array[float]=[
		water_radius*0.67,water_radius*0.86,water_radius*1.04,
		lerpf(water_radius,outer_radius,0.52),outer_radius
	]
	var broad_wobble: Array[float]=[]
	for i in SEGMENTS:
		var angle:=TAU*float(i)/float(SEGMENTS)
		broad_wobble.append(
			1.0+0.052*sin(angle*3.0+0.8)+0.031*cos(angle*5.0-0.35)
			+rng.randf_range(-0.008,0.008)
		)
	var vertices: Array[Vector3]=[]
	for ring_index in ring_radii.size():
		var fraction:float=ring_fractions[ring_index]
		for i in SEGMENTS:
			var angle:=TAU*float(i)/float(SEGMENTS)
			var radius:float=ring_radii[ring_index]*broad_wobble[i]
			var point:=center+Vector2(cos(angle),sin(angle))*radius
			var outer_ground:float=_ground(ground,point)
			var authored_height:float
			if ring_index==0:
				authored_height=water_level-0.55
			elif ring_index==1:
				authored_height=water_level-0.10
			elif ring_index==2:
				authored_height=water_level+0.20
			else:
				authored_height=lerpf(water_level+0.20,outer_ground+0.035,smoothstep(0.43,1.0,fraction))
			vertices.append(Vector3(point.x,authored_height,point.y))
	var tool:=SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for ring_index in ring_radii.size()-1:
		for i in SEGMENTS:
			var next:=(i+1)%SEGMENTS
			var a:=vertices[ring_index*SEGMENTS+i]
			var b:=vertices[ring_index*SEGMENTS+next]
			var c:=vertices[(ring_index+1)*SEGMENTS+i]
			var d:=vertices[(ring_index+1)*SEGMENTS+next]
			_up_triangle(tool,a,b,c)
			_up_triangle(tool,b,d,c)
	# Weld the shared ring vertices before rebuilding normals. This keeps the
	# bank smoothly shaded while retaining a genuinely triangulated collision
	# surface rather than faking smoothness with an unrelated collider.
	tool.index()
	tool.generate_normals()
	var bank_mesh:=tool.commit()
	var visual:=MeshInstance3D.new()
	visual.name="NaturalPondTerrainBank"
	visual.mesh=bank_mesh
	var material:=StandardMaterial3D.new()
	material.albedo_color=OHIO_GRASS
	material.roughness=0.95
	visual.material_override=material
	visual.set_meta(CollisionPolicy.POLICY_META,CollisionPolicy.PARKOUR)
	body.add_child(visual)
	var collision:=CollisionShape3D.new()
	collision.name="NaturalPondTerrainBankCollision"
	collision.shape=bank_mesh.create_trimesh_shape()
	collision.set_meta(CollisionPolicy.POLICY_META,CollisionPolicy.PARKOUR)
	body.add_child(collision)
	return body


## The only constructed edge at the tarn: a low stone weir of two curved
## cheeks standing on the spill sill, either side of the channel. The sill is
## the one place the water leaves the bowl, and the cheeks hold the water's
## edge there, so it ends against stone rather than hanging over falling
## ground. `center` is the tarn's centre and `radius` where the cheeks stand.
static func build_pond_weir(
	parent: Node3D,center: Vector2,radius: float,level_y: float,ground: Callable
) -> void:
	var body:=_body(parent,"SpringPondWeir")
	for side in [-1.0,1.0]:
		for i in 6:
			var angle:float=side*(0.115+float(i)*0.088)
			var spot:=center+Vector2(cos(angle),sin(angle))*radius
			var tangent:=Vector2(-sin(angle),cos(angle))
			var base:=_ground(ground,spot)
			var bottom:=minf(base,level_y)-1.0
			var top:=level_y+0.42
			var half_height:=(top-bottom)*0.5
			_part(
				body,Vector3(1.25,half_height,1.0),STONE if i%2==0 else STONE_DARK,
				Vector3(spot.x,bottom+half_height,spot.y),Basis(Vector3.UP,yaw_along(tangent)),
				true,true,SuperEgg.EPSILON_SOFT
			)


## Timber sluice across the channel where the race narrows toward the wheel.
static func build_headgate(parent: Node3D, at: Vector2, flow: Vector2, width: float, ground: Callable, base_y: float = -INF) -> void:
	var base := _ground(ground, at) if base_y == -INF else base_y
	var body := _body(parent, "Headgate", Vector3(at.x, base, at.y), yaw_along(flow))
	var span := width * 0.5 + CURB_THICKNESS + 0.25
	for side: float in [-1.0, 1.0]:
		_part(body, Vector3(0.18, 1.0, 0.18), PLANK_DARK, Vector3(side * span, 1.0, 0.0), Basis(), true, false)
	_part(body, Vector3(span + 0.3, 0.14, 0.16), PLANK_DARK, Vector3(0.0, 2.1, 0.0), Basis(), true, true)
	# The gate plank is raised clear of the water, leaving the race flowing under it.
	_part(body, Vector3(width * 0.5, 0.45, 0.07), PLANK, Vector3(0.0, 1.45, 0.0), Basis(), true, false)


## A low plank bridge: flat deck `deck_rise` above the ground with a ramp at
## each end and rails both sides. `axis` is the direction of travel across the
## channel. Raise `deck_rise` to clear the channel curbs.
static func build_footbridge(
	parent: Node3D, at: Vector2, axis: Vector2, channel_width: float, ground: Callable,
	deck_rise: float = 0.62
) -> void:
	const DECK_WIDTH := 1.1
	var base := _ground(ground, at)
	var yaw := yaw_along(axis)
	var body := _body(parent, "Footbridge", Vector3(at.x, base, at.y), yaw)
	var ramp_run := deck_rise * 3.0
	var half_span := channel_width * 0.5 + CURB_THICKNESS + 0.5
	_part(body, Vector3(DECK_WIDTH, 0.07, half_span), PLANK, Vector3(0.0, deck_rise, 0.0))
	var ramp_angle := atan2(deck_rise, ramp_run)
	var ramp_length := sqrt(deck_rise * deck_rise + ramp_run * ramp_run)
	for end: float in [-1.0, 1.0]:
		_part(
			body, Vector3(DECK_WIDTH, 0.06, ramp_length * 0.5), PLANK_DARK,
			Vector3(0.0, deck_rise * 0.5 + 0.035, end * (half_span + ramp_run * 0.5)),
			Basis(Vector3.RIGHT, ramp_angle * end)
		)
	for side: float in [-1.0, 1.0]:
		var rail_x := side * (DECK_WIDTH - 0.05)
		_part(
			body, Vector3(0.05, 0.05, half_span), PLANK_DARK,
			Vector3(rail_x, deck_rise + 0.95, 0.0), Basis(), true, false
		)
		var post_count := maxi(int(half_span * 2.0 / 1.4), 2)
		for i in post_count + 1:
			var z := lerpf(-half_span + 0.1, half_span - 0.1, float(i) / float(post_count))
			_part(body, Vector3(0.06, 0.5, 0.06), PLANK_DARK, Vector3(rail_x, deck_rise + 0.5, z), Basis(), true, false)


# ---------------------------------------------------------------------------
# Timber and log stacks
# ---------------------------------------------------------------------------

## Sawn planks stickered in a rack: end frames and layered boards.
static func build_timber_rack(parent: Node3D, at: Vector2, yaw: float, ground: Callable) -> void:
	var body := _body(parent, "TimberRack", Vector3(at.x, _ground(ground, at), at.y), yaw)
	for end: float in [-1.0, 1.0]:
		for z: float in [-0.6, 0.6]:
			_part(body, Vector3(0.1, 1.05, 0.1), PLANK_DARK, Vector3(end * 2.1, 1.05, z), Basis(), true, false)
	var layers := 6
	for layer in layers:
		var tone := PLANK if layer % 2 == 0 else PLANK.darkened(0.12)
		_part(
			body, Vector3(2.0, 0.07, 0.55), tone, Vector3(0.0, 0.26 + float(layer) * 0.29, 0.0),
			Basis(), layer == 0, true
		)
		_part(body, Vector3(1.9, 0.04, 0.6), PLANK_DARK, Vector3(0.0, 0.17 + float(layer) * 0.29, 0.0), Basis(), false)
	# One collider for the whole stack, so the boards need not each carry one.
	var stack := SuperEgg.build_part(Vector3(2.0, 0.9, 0.58), PLANK, SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT)
	stack.position = Vector3(0.0, 0.95, 0.0)
	stack.visible = false
	body.add_child(stack)
	CollisionPolicy.add_box(body, stack, Vector3(4.0, 1.8, 1.16), stack.position, Basis(), true)


## Logs stacked in a pyramid, lying along local Z (so yaw 0 puts them parallel
## to a wall that runs north-south and clear of it). Each log is a squarish
## SuperEgg with a plain sawn end, no separate disc.
static func build_log_pile(parent: Node3D, at: Vector2, yaw: float, ground: Callable, rows: int = 3) -> void:
	var body := _body(parent, "LogPile", Vector3(at.x, _ground(ground, at), at.y), yaw)
	const RADIUS := 0.2
	const HALF_LENGTH := 1.6
	var top := 0.0
	for row in rows:
		var count := rows - row
		for i in count:
			var x := (float(i) - float(count - 1) * 0.5) * RADIUS * 2.05
			var y := RADIUS + float(row) * RADIUS * 1.9
			var tone := LOG.lightened(0.05 * float((i + row) % 3))
			var log := SuperEgg.build_part(Vector3(RADIUS, RADIUS, HALF_LENGTH), tone, 4.0, 4.0)
			log.position = Vector3(x, y, 0.0)
			body.add_child(log)
			CollisionPolicy.mark_decorative(log)
			top = maxf(top, y + RADIUS)
	var collider := SuperEgg.build_part(Vector3(RADIUS * float(rows), top * 0.5, HALF_LENGTH), LOG, 4.0, 4.0)
	collider.position = Vector3(0.0, top * 0.5, 0.0)
	collider.visible = false
	body.add_child(collider)
	CollisionPolicy.add_box(body, collider, Vector3(RADIUS * 2.0 * float(rows), top, HALF_LENGTH * 2.0), collider.position, Basis(), true)


# ---------------------------------------------------------------------------
# Yards
# ---------------------------------------------------------------------------

## Open-fronted cart shed: four posts, a lean-to roof, and a parked handcart.
## The open side faces local -Z.
static func build_cart_shelter(parent: Node3D, at: Vector2, yaw: float, roof: Color, ground: Callable) -> void:
	var body := _body(parent, "CartShelter", Vector3(at.x, _ground(ground, at), at.y), yaw)
	var front_top:=2.30
	var back_top:=2.90
	for x: float in [-2.0, 2.0]:
		_part(body,Vector3(0.12,front_top*0.5,0.12),PLANK_DARK,Vector3(x,front_top*0.5,-1.3),Basis(),true,false)
		_part(body,Vector3(0.12,back_top*0.5,0.12),PLANK_DARK,Vector3(x,back_top*0.5,1.3),Basis(),true,false)
	_part(body, Vector3(2.0, 1.0, 0.05), PLANK, Vector3(0.0, 1.1, 1.38), Basis(), true, false)
	# Derive the roof directly from the support heights. The underside meets
	# both post pairs rather than floating above one and clipping into the other.
	var slope:=atan2(back_top-front_top,2.6)
	_roof_slab(body,Vector2(2.35,1.6),roof,Vector3(0.0,(front_top+back_top)*0.5+0.05,0.0),Basis(Vector3.RIGHT,-slope),0.05)
	# Parked handcart.
	_part(body, Vector3(0.7, 0.08, 1.0), PLANK, Vector3(0.0, 0.62, 0.0), Basis(), true, true)
	_part(body, Vector3(0.7, 0.2, 0.05), PLANK_DARK, Vector3(0.0, 0.8, 1.0), Basis(), false)
	for side: float in [-1.0, 1.0]:
		var wheel := SuperEgg.build_part(Vector3(0.05, 0.5, 0.5), PLANK_DARK, 2.0, 2.0)
		wheel.position = Vector3(side * 0.78, 0.5, 0.0)
		body.add_child(wheel)
		CollisionPolicy.mark_decorative(wheel)
	for i in 2:
		_part(body, Vector3(0.04, 0.04, 1.0), PLANK_DARK, Vector3(-0.35 + float(i) * 0.7, 0.62, -1.9), Basis(), false)


## A workaday raised grain store with one loading opening and a pent roof.
## It deliberately avoids cottage windows, shutters, porch and chimney.
static func build_granary_shed(
	parent: Node3D,at: Vector2,yaw: float,roof: Color,ground: Callable
) -> void:
	var body:=_body(parent,"Granary",Vector3(at.x,_ground(ground,at),at.y),yaw)
	for x: float in [-1.7,1.7]:
		for z: float in [-0.9,0.9]:
			_part(body,Vector3(0.16,0.22,0.16),STONE_DARK,Vector3(x,0.22,z),Basis(),true,false)
	_part(body,Vector3(2.0,0.10,1.25),PLANK,Vector3(0,0.50,0),Basis(),true,true)
	# The pent roof falls toward the back (+Z). Every wall is cut to meet its
	# underside: the front stands tallest, the back lowest, and the side walls
	# slope between them. (A level 3 m wall under a tilted roof left the front
	# open under a floating roof and pushed the back wall up through it.)
	var pitch:=deg_to_rad(12.0)
	var roof_centre_y:=3.18
	var roof_half_depth:=1.48
	var slab_half:=0.06
	var embed:=0.03
	var front_top:=roof_centre_y+1.25*tan(pitch)-slab_half/cos(pitch)+embed
	var back_top:=roof_centre_y-1.25*tan(pitch)-slab_half/cos(pitch)+embed
	var floor_top:=0.55
	var side_polygon: Array[Vector2]=[
		Vector2(-1.25,floor_top),Vector2(1.25,floor_top),Vector2(1.25,back_top),Vector2(-1.25,front_top),
	]
	for x: float in [-2.0,2.0]:
		RoofForms.prism(
			body,side_polygon,Vector3(x,0.0,0.0),
			Basis(Vector3(0,0,1),Vector3(0,1,0),Vector3(1,0,0)),0.2,PLANK_DARK,true
		)
	var back_half:=(back_top-floor_top)*0.5
	_part(body,Vector3(2.0,back_half,0.10),PLANK_DARK,Vector3(0,floor_top+back_half,1.25),Basis(),true,false)
	var front_half:=(front_top-floor_top)*0.5
	for x: float in [-1.45,1.45]:
		_part(body,Vector3(0.55,front_half,0.10),PLANK_DARK,Vector3(x,floor_top+front_half,-1.25),Basis(),true,false)
	# Door header: from the head of the loading opening up to the front top.
	var header_bottom:=2.56
	var header_half:=(front_top-header_bottom)*0.5
	_part(body,Vector3(0.90,header_half,0.10),PLANK_DARK,Vector3(0,header_bottom+header_half,-1.25),Basis(),true,false)
	_roof_slab(body,Vector2(2.25,roof_half_depth),roof.darkened(0.18),Vector3(0,roof_centre_y,0),Basis(Vector3.RIGHT,pitch),slab_half)


## The mason's contained yard: rough stone samples and a lime pit.
static func build_stone_yard(parent: Node3D, at: Vector2, yaw: float, ground: Callable) -> void:
	var body := _body(parent, "StoneYard", Vector3(at.x, _ground(ground, at), at.y), yaw)
	var blocks: Array[Vector4] = [
		Vector4(-2.4, 1.2, 0.9, 0.45), Vector4(-1.2, 1.0, 0.7, 0.35),
		Vector4(-1.9, 1.4, 0.8, 0.4), Vector4(-2.7, 0.2, 0.55, 0.3),
		Vector4(2.4, -1.3, 0.8, 0.35),
	]
	for block in blocks:
		var shade := STONE.darkened(0.04 * float(int(absf(block.x * 7.0)) % 4))
		_part(
			body, Vector3(block.z, block.w, block.z * 0.8), shade,
			Vector3(block.x, block.w, block.y), Basis(Vector3.UP, block.x), true, true,
			SuperEgg.EPSILON_SOFT
		)
	# Lime pit: a stone-curbed box, its surface pale.
	for side: float in [-1.0, 1.0]:
		_part(body, Vector3(1.0, 0.3, 0.12), STONE_DARK, Vector3(1.4, 0.3, side * 0.9))
		_part(body, Vector3(0.12, 0.3, 0.9), STONE_DARK, Vector3(1.4 + side * 0.9, 0.3, 0.0))
	_part(body, Vector3(0.84, 0.02, 0.78), Color(0.88, 0.86, 0.80), Vector3(1.4, 0.34, 0.0), Basis(), false)


## Woven hedge along a polyline, solid like the boundary it is.
static func build_hedge_run(parent: Node3D, points: Array[Vector2], ground: Callable) -> void:
	var body := _body(parent, "WovenHedge")
	for i in points.size() - 1:
		var a := points[i]
		var b := points[i + 1]
		var delta := b - a
		var length := delta.length()
		if length < 0.1:
			continue
		var middle := (a + b) * 0.5
		var tone := HEDGE.lightened(0.03 * float(i % 3))
		_part(
			body, Vector3(0.42, 0.5, length * 0.5 + 0.1), tone,
			Vector3(middle.x, _ground(ground, middle) + 0.5, middle.y),
			Basis(Vector3.UP, yaw_along(delta / length)), true, true, SuperEgg.EPSILON_SOFT
		)


## Low dry-stone wall along a polyline: rolled blocks in alternating tones, a
## flat coping on top, landable and solid like the field wall it is.
static func build_dry_wall(parent: Node3D, points: Array[Vector2], ground: Callable, height: float = 0.8) -> void:
	var body := _body(parent, "DryStoneWall")
	for i in points.size() - 1:
		var a := points[i]
		var b := points[i + 1]
		var delta := b - a
		var length := delta.length()
		if length < 0.1:
			continue
		var middle := (a + b) * 0.5
		var basis := Basis(Vector3.UP, yaw_along(delta / length))
		var base := _ground(ground, middle) - 0.1
		var tone := STONE.darkened(0.06) if i % 2 == 0 else STONE.lightened(0.02)
		_part(
			body, Vector3(0.3, height * 0.5, length * 0.5 + 0.08), tone,
			Vector3(middle.x, base + height * 0.5, middle.y), basis, true, true, SuperEgg.EPSILON_SOFT
		)
		_part(
			body, Vector3(0.36, 0.06, length * 0.5 + 0.1), STONE.lightened(0.1),
			Vector3(middle.x, base + height + 0.04, middle.y), basis, false, false, SuperEgg.EPSILON_SOFT
		)


## A squat square stone pier of a gateway with no gate: plinth, shaft and
## coping, carrying whatever the caller stands on top (a lantern). Returns the
## body; the top of the coping is `PIER_HEIGHT` above the ground.
const PIER_HEIGHT := 1.5
static func build_gate_pier(parent: Node3D, at: Vector2, yaw: float, ground: Callable) -> StaticBody3D:
	var base := _ground(ground, at) - 0.1
	var body := _body(parent, "GatePier", Vector3(at.x, base, at.y), yaw)
	_part(body, Vector3(0.58, 0.18, 0.58), STONE_DARK, Vector3(0.0, 0.18, 0.0))
	_part(body, Vector3(0.45, 0.55, 0.45), STONE, Vector3(0.0, 0.9, 0.0), Basis(), true, true)
	_part(body, Vector3(0.56, 0.07, 0.56), STONE.lightened(0.1), Vector3(0.0, 1.5, 0.0), Basis(), false, false, SuperEgg.EPSILON_SOFT)
	return body


## A bed ringed with stones, raised a hand's breadth: the island a sign or a
## tree stands in at a verge.
static func build_verge_island(parent: Node3D, at: Vector2, radius: float, ground: Callable) -> void:
	var body := _body(parent, "VergeIsland", Vector3(at.x, _ground(ground, at), at.y))
	var count := 14
	for i in count:
		var angle := TAU * float(i) / float(count)
		var spot := Vector3(cos(angle), 0.0, sin(angle)) * radius
		var stone := _part(
			body, Vector3(0.34, 0.16, 0.26), STONE if i % 2 == 0 else STONE_DARK, spot + Vector3(0.0, 0.1, 0.0),
			Basis(Vector3.UP, angle + PI * 0.5), true, true, SuperEgg.EPSILON_SOFT
		)
		stone.name = "RingStone"
	_part(body, Vector3(radius, 0.07, radius), Color(0.30, 0.22, 0.14), Vector3(0.0, 0.07, 0.0), Basis(), false, false, SuperEgg.EPSILON_SOFT)


## A lattice trellis against a wall for a climber: two uprights and crossed
## slats, flat to the wall (local +Z is out from the wall).
static func build_trellis(parent: Node3D, at: Vector2, yaw: float, width: float, height: float, ground: Callable) -> void:
	var body := _body(parent, "Trellis", Vector3(at.x, _ground(ground, at), at.y), yaw)
	for side: float in [-1.0, 1.0]:
		_part(body, Vector3(0.04, height * 0.5, 0.04), PLANK_DARK, Vector3(side * width * 0.5, height * 0.5, 0.0), Basis(), true, false)
	for i in 5:
		var y := 0.35 + (height - 0.5) * float(i) / 4.0
		_part(body, Vector3(width * 0.5, 0.025, 0.025), PLANK, Vector3(0.0, y, 0.04), Basis(), false, false)
	for i in 4:
		var x := lerpf(-width * 0.5 + 0.2, width * 0.5 - 0.2, float(i) / 3.0)
		_part(body, Vector3(0.025, height * 0.5 - 0.1, 0.025), PLANK, Vector3(x, height * 0.5, 0.06), Basis(), false, false)


## A working raised garden bed: solid timber edging around a soft soil mound.
## Crops are planted by the caller so one builder serves kitchen and physic beds.
static func build_raised_bed(
	parent: Node3D, at: Vector2, size: Vector2, ground: Callable,
	soil: Color = Color(0.45, 0.30, 0.17), node_name: String = "RaisedBed"
) -> StaticBody3D:
	var body := _body(parent, node_name, Vector3(at.x, _ground(ground, at), at.y))
	var half := size * 0.5
	_part(body, Vector3(maxf(half.x - 0.12, 0.1), 0.10, maxf(half.y - 0.12, 0.1)), soil, Vector3(0, 0.10, 0), Basis(), true, true, SuperEgg.EPSILON_SOFT)
	for z_sign: float in [-1.0, 1.0]:
		_part(body, Vector3(half.x, 0.09, 0.07), PLANK_DARK, Vector3(0, 0.14, z_sign * half.y), Basis(), true, true)
	for x_sign: float in [-1.0, 1.0]:
		_part(body, Vector3(0.07, 0.09, half.y), PLANK_DARK, Vector3(x_sign * half.x, 0.14, 0), Basis(), true, true)
	return body


static func build_garden_barrel(parent: Node3D, at: Vector2, ground: Callable) -> StaticBody3D:
	var body := _body(parent, "GardenWaterBarrel", Vector3(at.x, _ground(ground, at), at.y))
	_part(body, Vector3(0.34, 0.48, 0.34), PLANK, Vector3(0, 0.48, 0), Basis(), true, false, 2.2)
	for y in [0.18, 0.76]:
		_part(body, Vector3(0.35, 0.025, 0.35), Color(0.20, 0.20, 0.22), Vector3(0, y, 0), Basis(), false, false, 2.2)
	return body


static func build_compost_heap(parent: Node3D, at: Vector2, ground: Callable) -> StaticBody3D:
	var body := _body(parent, "CompostHeap", Vector3(at.x, _ground(ground, at), at.y))
	_part(body, Vector3(0.55, 0.28, 0.48), Color(0.28, 0.22, 0.12), Vector3(0, 0.25, 0), Basis(), true, true, SuperEgg.EPSILON_SOFT)
	for side: float in [-1.0, 1.0]:
		_part(body, Vector3(0.035, 0.32, 0.52), PLANK_DARK, Vector3(side * 0.6, 0.30, 0), Basis(), true, false)
	return body


static func build_bee_skep(parent: Node3D, at: Vector2, ground: Callable) -> StaticBody3D:
	var body := _body(parent, "BeeSkep", Vector3(at.x, _ground(ground, at), at.y))
	_part(body, Vector3(0.42, 0.08, 0.42), PLANK_DARK, Vector3(0, 0.08, 0), Basis(), true, false)
	_part(body, Vector3(0.30, 0.40, 0.30), Color(0.72, 0.58, 0.30), Vector3(0, 0.48, 0), Basis(), true, false, 2.1)
	_part(body, Vector3(0.08, 0.055, 0.035), Color(0.10, 0.08, 0.04), Vector3(0, 0.30, -0.29), Basis(), false, false, 2.2)
	return body


static func build_scarecrow(parent: Node3D, at: Vector2, ground: Callable) -> StaticBody3D:
	var body := _body(parent, "GardenScarecrow", Vector3(at.x, _ground(ground, at), at.y))
	_part(body, Vector3(0.055, 1.05, 0.055), PLANK_DARK, Vector3(0, 1.05, 0), Basis(), true, false)
	_part(body, Vector3(0.72, 0.045, 0.045), PLANK_DARK, Vector3(0, 1.58, 0), Basis(), true, false)
	_part(body, Vector3(0.24, 0.32, 0.08), Color(0.28, 0.42, 0.62), Vector3(0, 1.38, 0), Basis(), false, false, SuperEgg.EPSILON_SOFT)
	_part(body, Vector3(0.17, 0.17, 0.17), Color(0.74, 0.58, 0.31), Vector3(0, 1.94, 0), Basis(), false, false, 2.2)
	_part(body, Vector3(0.27, 0.035, 0.27), Color(0.52, 0.27, 0.12), Vector3(0, 2.11, 0), Basis(), false, false, 2.4)
	return body


# ---------------------------------------------------------------------------
# Village square furniture
# ---------------------------------------------------------------------------

## A solid round platform of stone (radial slabs), `top` high, for a fountain
## or monument to stand on.
static func build_disc_platform(
	parent: Node3D, at: Vector2, radius: float, top: float, color: Color, ground: Callable,
	node_name: String = "Platform", segments: int = 28
) -> StaticBody3D:
	var body := _body(parent, node_name, Vector3(at.x, _ground(ground, at), at.y))
	for i in segments:
		var angle := TAU * (float(i) + 0.5) / float(segments)
		var chord := 2.0 * radius * sin(PI / float(segments))
		var radial := Vector3(cos(angle), 0.0, sin(angle))
		var basis := Basis(Vector3.UP, atan2(radial.x, radial.z))
		var tone := color.lightened(0.03 * float(i % 3))
		_part(
			body, Vector3(chord * 0.5 + 0.04, top * 0.5, radius * 0.5), tone,
			radial * radius * 0.5 + Vector3(0.0, top * 0.5, 0.0), basis, true, true
		)
	return body


## A paved circular terrace on gently graded terrain. Unlike build_disc_platform,
## this is not one flat pizza-slice assembly sampled only at its centre. Each
## flagstone samples and follows the local tangent plane, so the visible and
## collidable faces stay together on a natural slope instead of alternately
## hovering above it and disappearing into it.
static func build_graded_flagstone_terrace(
	parent: Node3D, at: Vector2, radius: float, color: Color, ground: Callable,
	node_name: String = "GradedTerrace", ground_normal: Callable = Callable()
) -> StaticBody3D:
	var body := _body(parent, node_name)
	var scale_factor := radius / 5.8
	var rings := [
		{"radius":0.0, "count":1, "radial_half":0.86},
		{"radius":1.35, "count":8, "radial_half":0.64},
		{"radius":2.8, "count":14, "radial_half":0.72},
		{"radius":4.55, "count":20, "radial_half":0.82},
	]
	for ring_index in rings.size():
		var ring: Dictionary = rings[ring_index]
		var ring_radius := float(ring["radius"]) * scale_factor
		var count := int(ring["count"])
		for index in count:
			var angle := 0.0 if count == 1 else TAU * (float(index) + 0.5 * float(ring_index % 2)) / float(count)
			var spot := at + Vector2(cos(angle), sin(angle)) * ring_radius
			var normal: Vector3 = (
				ground_normal.call(spot) if ground_normal.is_valid()
				else _sample_ground_normal(ground, spot)
			)
			var tangent := Vector3(-sin(angle), 0.0, cos(angle))
			tangent = (tangent - normal * tangent.dot(normal)).normalized()
			var across := tangent.cross(normal).normalized()
			var basis := Basis(tangent, normal, across)
			var radial_half := float(ring["radial_half"]) * scale_factor
			var tangent_half: float
			if count == 1:
				tangent_half = 0.86 * scale_factor
			else:
				var arc := TAU * ring_radius / float(count)
				tangent_half = minf(arc * 0.46, 0.78 * scale_factor)
			var half := Vector3(tangent_half, 0.075, radial_half)
			var tone := color.lightened(0.018 * float((index + ring_index) % 4))
			var centre := Vector3(spot.x, _ground(ground, spot), spot.y) + normal * 0.02
			# Half the stone remains below the sampled terrain; its planar top and
			# collider sit just proud of the grade without producing a raised disc.
			_part(body, half, tone, centre, basis, true, true, SuperEgg.EPSILON_FLAT)
	return body


## A level paved terrace at a cliff overlook. The walking surface is one stable
## flat cylinder, while overlapping horizontal SuperEgg flagstones provide the
## visible finish. This deliberately does not inherit the cliff's local tangent:
## pavers pitched down the escarpment made the viewpoint slippery and sent its
## path paint over the edge. A low row of broad coping stones marks only the
## drop-facing arc and never becomes a perimeter wall.
static func build_flat_overlook_terrace(
	parent: Node3D, at: Vector2, radius: float, color: Color, ground: Callable,
	node_name: String = "FlatOverlookTerrace", surface_override: float = NAN
) -> StaticBody3D:
	# On a slope the deck's level comes from its foundation (SlopeFoundation),
	# which also supplies the collider; on level ground it sits on the grade.
	var on_foundation := not is_nan(surface_override)
	var surface_y := surface_override if on_foundation else _ground(ground, at) + 0.095
	var body := _body(parent, node_name)
	# The flags are laid as real paving is: on a lime mortar bed over packed
	# fill, the joints pointed nearly flush. Without it the gaps between the
	# rounded flags looked straight down into the hollow foundation. A plain
	# cylinder is right here: it is seen only through the joints and is the
	# fill the round deck needs.
	var bed := MeshInstance3D.new()
	bed.name = "MortarBed"
	var bed_mesh := CylinderMesh.new()
	bed_mesh.top_radius = radius * 0.97
	bed_mesh.bottom_radius = radius * 0.97
	bed_mesh.height = 0.45
	bed_mesh.radial_segments = 40
	bed.mesh = bed_mesh
	var bed_material := StandardMaterial3D.new()
	bed_material.albedo_color = color.lerp(Color(0.80, 0.77, 0.70), 0.45).darkened(0.12)
	bed_material.roughness = 0.95
	bed.material_override = bed_material
	bed.position = Vector3(at.x, surface_y - 0.05 - bed_mesh.height * 0.5, at.y)
	body.add_child(bed)
	CollisionPolicy.mark_decorative(bed)
	var rings := [
		{"radius":0.0, "count":1, "tangent":0.95, "radial":0.95},
		{"radius":1.55, "count":9, "tangent":0.78, "radial":0.72},
		{"radius":3.15, "count":15, "tangent":0.72, "radial":0.82},
		{"radius":4.72, "count":22, "tangent":0.68, "radial":0.88},
	]
	for ring_index in rings.size():
		var ring: Dictionary = rings[ring_index]
		var ring_radius := float(ring["radius"]) * radius / 5.8
		var count := int(ring["count"])
		for index in count:
			var angle := 0.0 if count == 1 else TAU * (float(index) + 0.37 * float(ring_index % 2)) / float(count)
			var spot := at + Vector2(cos(angle), sin(angle)) * ring_radius
			var yaw := angle + PI * 0.5 + sin(float(index * 13 + ring_index * 7)) * 0.08
			var half := Vector3(
				float(ring["tangent"]) * radius / 5.8,
				0.075,
				float(ring["radial"]) * radius / 5.8
			)
			var tone := color.lightened(0.015 * float((index + ring_index * 2) % 4))
			_part(
				body, half, tone,
				Vector3(spot.x, surface_y - half.y + 0.006, spot.y),
				Basis(Vector3.UP, yaw), false, true, SuperEgg.EPSILON_FLAT
			)
	# One collider is the exact deck the player sees. Individual dressing stones
	# are non-colliding so their overlaps cannot produce bumps or snag a wheel.
	if not on_foundation:
		var collision := CollisionShape3D.new()
		var shape := CylinderShape3D.new()
		shape.radius = radius * 0.91
		shape.height = 0.16
		collision.shape = shape
		collision.position = Vector3(at.x, surface_y - shape.height * 0.5, at.y)
		collision.set_meta(CollisionPolicy.POLICY_META, CollisionPolicy.PARKOUR)
		body.add_child(collision)
		body.set_meta(CollisionPolicy.POLICY_META, CollisionPolicy.PARKOUR)
	# Flush, broad stones on the east/drop arc read as a finished edge without
	# forming the rim wall the overlook explicitly must not have.
	var coping_count := 9
	for index in coping_count:
		var angle := deg_to_rad(55.0 - 110.0 * float(index) / float(coping_count - 1))
		var spot := at + Vector2(cos(angle), sin(angle)) * radius * 0.89
		_part(
			body, Vector3(0.58, 0.085, 0.34), color.lightened(0.035),
			Vector3(spot.x, surface_y - 0.075, spot.y), Basis(Vector3.UP, angle + PI * 0.5),
			false, true, SuperEgg.EPSILON_FLAT
		)
	return body


static func _sample_ground_normal(ground: Callable, at: Vector2, step: float = 0.65) -> Vector3:
	var left := _ground(ground, at + Vector2(-step, 0.0))
	var right := _ground(ground, at + Vector2(step, 0.0))
	var back := _ground(ground, at + Vector2(0.0, -step))
	var front := _ground(ground, at + Vector2(0.0, step))
	return Vector3(left - right, 2.0 * step, back - front).normalized()


## A stone bench facing the point `toward`, long axis tangent to it.
static func build_bench(parent: Node3D, at: Vector2, toward: Vector2, ground: Callable) -> void:
	var facing := (toward - at).normalized()
	var body := _body(parent, "Bench", Vector3(at.x, _ground(ground, at), at.y), yaw_along(facing))
	_part(body, Vector3(0.95, 0.06, 0.26), STONE.lightened(0.08), Vector3(0.0, 0.52, 0.0), Basis(), true, true)
	for end: float in [-0.75, 0.75]:
		_part(body, Vector3(0.09, 0.25, 0.23), STONE_DARK, Vector3(end, 0.25, 0.0), Basis(), true, false)


## A compact social table for the shaded edge of Ohio's green. It supports a
## quiet board game without occupying the open harvest-supper lawn or adding a
## second monument to compete with the fountain.
static func build_game_table(parent: Node3D, at: Vector2, ground: Callable) -> StaticBody3D:
	var body := _body(parent, "GreenGameTable", Vector3(at.x, _ground(ground, at), at.y))
	_part(body, Vector3(0.82, 0.055, 0.62), PLANK, Vector3(0.0, 0.78, 0.0), Basis(), true, true)
	for x: float in [-0.58, 0.58]:
		for z: float in [-0.39, 0.39]:
			_part(body, Vector3(0.055, 0.36, 0.055), PLANK_DARK, Vector3(x, 0.38, z), Basis(), true, false)
	for z: float in [-1.05, 1.05]:
		_part(body, Vector3(0.92, 0.055, 0.24), PLANK, Vector3(0.0, 0.48, z), Basis(), true, true)
		for x: float in [-0.7, 0.7]:
			_part(body, Vector3(0.055, 0.22, 0.18), PLANK_DARK, Vector3(x, 0.24, z), Basis(), true, false)
	# Two small opposing groups of smooth playing stones. They are decoration,
	# not pickups and carry no written rule or instruction.
	for side in 2:
		for piece_index in 4:
			var piece := SuperEgg.build_part(
				Vector3(0.065, 0.025, 0.065),
				STONE_DARK if side == 0 else Color(0.84, 0.76, 0.58), 2.2, 2.2
			)
			piece.position = Vector3(-0.42 + float(piece_index) * 0.28, 0.865, -0.2 + float(side) * 0.4)
			body.add_child(piece)
			CollisionPolicy.mark_decorative(piece)
	return body


## Parish notice board: two posts carrying a pitched cap, with a pinned board.
static func build_notice_board(parent: Node3D, at: Vector2, yaw: float, roof: Color, ground: Callable) -> void:
	var body := _body(parent, "NoticeBoard", Vector3(at.x, _ground(ground, at), at.y), yaw)
	const HEIGHT := 2.3
	for x: float in [-0.85, 0.85]:
		_part(body, Vector3(0.09, (HEIGHT + SINK_DEPTH) * 0.5, 0.09), PLANK_DARK, Vector3(x, (HEIGHT - SINK_DEPTH) * 0.5, 0.0), Basis(), true, false)
	_part(body, Vector3(0.8, 0.5, 0.04), PLANK, Vector3(0.0, 1.4, 0.0), Basis(), true, false)
	for i in 4:
		var sheet := SuperEgg.build_part(Vector3(0.14, 0.18, 0.006), Color(0.9, 0.87, 0.78), SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT)
		sheet.position = Vector3(-0.55 + float(i) * 0.37, 1.42 + 0.05 * float(i % 2), -0.045)
		body.add_child(sheet)
		CollisionPolicy.mark_decorative(sheet)
	var pitch := deg_to_rad(28.0)
	for side: float in [-1.0, 1.0]:
		_part(
			body, Vector3(0.55, 0.035, 0.2), roof,
			Vector3(side * 0.47, HEIGHT + 0.12, 0.0), Basis(Vector3.BACK, -pitch * side), false
		)
	_part(body, Vector3(0.95, 0.06, 0.08), PLANK_DARK, Vector3(0.0, HEIGHT - 0.06, 0.0), Basis(), false)


const SINK_DEPTH := 0.25


# ---------------------------------------------------------------------------
# Fences
# ---------------------------------------------------------------------------

const FENCE_HEIGHT := 1.15
const FENCE_POST_SPACING := 2.1
const FENCE_POST_HALF := 0.075


## A continuous post-and-rail fence along a polyline: posts at every corner and
## at most FENCE_POST_SPACING apart, three rails running unbroken from post to
## post, and one collider per bay. It is one structure, not a row of pieces.
static func build_fence_run(
	parent: Node3D, points: Array[Vector2], ground: Callable, node_name: String = "FenceRun"
) -> StaticBody3D:
	var body := _body(parent, node_name)
	var posts: Array[Vector2] = [points[0]]
	for i in points.size() - 1:
		var a := points[i]
		var b := points[i + 1]
		var bays := maxi(int(ceilf(a.distance_to(b) / FENCE_POST_SPACING)), 1)
		for bay in range(1, bays + 1):
			posts.append(a.lerp(b, float(bay) / float(bays)))
	for post_at in posts:
		var base := _ground(ground, post_at)
		var half := Vector3(FENCE_POST_HALF, (FENCE_HEIGHT + 0.3) * 0.5, FENCE_POST_HALF)
		_part(body, half, PLANK_DARK, Vector3(post_at.x, base + FENCE_HEIGHT * 0.5 - 0.05, post_at.y), Basis(), true, false)
	for i in posts.size() - 1:
		var a := posts[i]
		var b := posts[i + 1]
		var delta := b - a
		var length := delta.length()
		if length < 0.05:
			continue
		var middle := (a + b) * 0.5
		var base := (_ground(ground, a) + _ground(ground, b)) * 0.5
		var basis := Basis(Vector3.UP, yaw_along(delta / length))
		for rail_y: float in [0.3, 0.68, 1.04]:
			_part(
				body, Vector3(0.025, 0.05, length * 0.5), PLANK,
				Vector3(middle.x, base + rail_y, middle.y), basis, false
			)
		# One collider for the whole bay, rail-to-ground.
		var collider := SuperEgg.build_part(Vector3(0.05, FENCE_HEIGHT * 0.5, length * 0.5), PLANK, SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT)
		collider.visible = false
		collider.position = Vector3(middle.x, base + FENCE_HEIGHT * 0.5, middle.y)
		collider.basis = basis
		body.add_child(collider)
		CollisionPolicy.add_box(body, collider, Vector3(0.1, FENCE_HEIGHT, length), collider.position, basis, true)
	return body


## A field gate between two heavier gateposts, its leaf hinged at `hinge` and
## swung open toward `inward` (a unit XZ direction).
static func build_gate(
	parent: Node3D, hinge: Vector2, latch: Vector2, inward: Vector2, ground: Callable
) -> void:
	var body := _body(parent, "Gate")
	for post_at in [hinge, latch]:
		var base := _ground(ground, post_at)
		var half := Vector3(0.11, (FENCE_HEIGHT + 0.55) * 0.5, 0.11)
		_part(body, half, PLANK_DARK, Vector3(post_at.x, base + (FENCE_HEIGHT + 0.55) * 0.5 - 0.15, post_at.y), Basis(), true, false)
		_part(body, Vector3(0.15, 0.04, 0.15), PLANK_DARK.lightened(0.1), Vector3(post_at.x, base + FENCE_HEIGHT + 0.42, post_at.y), Basis(), false)
	var span := hinge.distance_to(latch)
	var along := (latch - hinge) / span
	var swing := along * cos(deg_to_rad(70.0)) + inward * sin(deg_to_rad(70.0))
	var base := _ground(ground, hinge)
	var leaf := _body(body, "GateLeaf", Vector3(hinge.x, base, hinge.y), yaw_along(swing.normalized()))
	var leaf_length := span - 0.3
	for rail_y: float in [0.3, 0.7, 1.05]:
		_part(leaf, Vector3(0.03, 0.055, leaf_length * 0.5), PLANK, Vector3(0.0, rail_y, 0.15 + leaf_length * 0.5), Basis(), false)
	for end: float in [0.17, leaf_length + 0.13]:
		_part(leaf, Vector3(0.04, 0.55, 0.04), PLANK_DARK, Vector3(0.0, 0.68, end), Basis(), false)
	var brace_angle := atan2(0.75, leaf_length)
	_part(leaf, Vector3(0.025, 0.04, sqrt(leaf_length * leaf_length + 0.75 * 0.75) * 0.5), PLANK_DARK, Vector3(0.0, 0.68, 0.15 + leaf_length * 0.5), Basis(Vector3.RIGHT, brace_angle), false)
	var collider := SuperEgg.build_part(Vector3(0.05, 0.55, leaf_length * 0.5), PLANK, SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT)
	collider.visible = false
	collider.position = Vector3(0.0, 0.6, 0.15 + leaf_length * 0.5)
	leaf.add_child(collider)
	CollisionPolicy.add_box(leaf, collider, Vector3(0.1, 1.1, leaf_length), collider.position, Basis(), false)


# ---------------------------------------------------------------------------
# Roof bell gablet
# ---------------------------------------------------------------------------

## A small open bell gablet on the FRONT (local -Z) roof slope of a gable
## building: four posts rise from the slope, a little pitched roof caps them,
## and the bell hangs between. Rooftop landing surface is left to the main roof.
static func build_bell_gablet(
	building: StaticBody3D, d_cells: int, floors: int, roof: Color, slope_z: float = 1.9
) -> void:
	var half_depth := float(d_cells) * TownProps.CELL_SIZE * 0.5
	var eave_y := float(floors) * TownProps.FLOOR_HEIGHT
	var base_z := -slope_z
	var base_y: float = TownProps.roof_top_y(eave_y, half_depth, slope_z + 0.5) - 0.1
	var post_top: float = TownProps.roof_top_y(eave_y, half_depth, slope_z - 0.5) + 1.7
	var height := post_top - base_y
	for x: float in [-0.7, 0.7]:
		for z_offset: float in [-0.5, 0.5]:
			var mesh := SuperEgg.build_part(Vector3(0.08, height * 0.5, 0.08), VillageWorks.PLANK_DARK, 2.6, 2.6)
			mesh.position = Vector3(x, base_y + height * 0.5, base_z + z_offset)
			building.add_child(mesh)
			CollisionPolicy.mark_decorative(mesh)
	var pitch := TownProps.ROOF_PITCH
	var run := 1.05
	var ridge_y := post_top + 0.55
	for side: float in [-1.0, 1.0]:
		var panel := SuperEgg.build_part(Vector3(run / cos(pitch) * 0.5, 0.05, 0.7), roof, SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT)
		panel.position = Vector3(side * run * 0.5, ridge_y - run * 0.5 * tan(pitch), base_z)
		panel.rotation.z = -side * pitch
		building.add_child(panel)
		CollisionPolicy.mark_decorative(panel)
	var beam := SuperEgg.build_part(Vector3(0.1, 0.1, 0.78), roof, 2.15, 2.15)
	beam.position = Vector3(0.0, ridge_y + 0.04, base_z)
	building.add_child(beam)
	CollisionPolicy.mark_decorative(beam)
	var bell := SuperEgg.build_part(Vector3(0.28, 0.32, 0.28), BRASS, 2.0, 2.0)
	bell.position = Vector3(0.0, post_top - 0.45, base_z)
	building.add_child(bell)
	CollisionPolicy.mark_decorative(bell)
	var yoke := SuperEgg.build_part(Vector3(0.78, 0.05, 0.05), VillageWorks.PLANK_DARK, 2.6, 2.6)
	yoke.position = Vector3(0.0, post_top - 0.1, base_z)
	building.add_child(yoke)
	CollisionPolicy.mark_decorative(yoke)
