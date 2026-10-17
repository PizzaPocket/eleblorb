class_name HairOrnaments
extends RefCounted

## Shared hair/head ornament placement for humanoid NPC variants (Tempestar,
## Merfolk) -- queries FigureHair.hair_edges() for the REAL per-hairstyle
## envelope (the exact front/back/top/width numbers add_hair() itself builds
## the hair mesh from) instead of one hardcoded offset that only happened to
## clear a single style. Per direct correction: "make sure to account for
## the literal surface mesh of the hair... other jewelry and ornaments on
## the hair... a lot of them are like clipping into the head or definitely
## being clipped by some of the hairstyles." Every function here takes the
## head MESH (not the head pivot) -- the same local frame FigureHair/
## FigureEyes already build in -- matching how callers already fetch
## `pivots["head_mesh"]` from ProceduralFigure.build().

const LAUREL_LEAF_COUNT := 9
## Leaves span this much of the full circle, centered on the BACK -- per
## direct instruction, "a ring coming around the back of the head." Real
## laurel wreaths cluster leaves at the sides/back and leave the face
## itself bare, rather than a leaf sitting directly across the forehead.
const LAUREL_ARC_DEGREES := 300.0
const LAUREL_LEAF_SIZE := Vector3(0.014, 0.005, 0.028)
const LAUREL_FAN_ANGLE := deg_to_rad(35.0)
## A small clearance added past the hair's own real edge so leaves rest
## just outside the hair surface instead of exactly tangent to it (which
## can still visibly poke through at a mesh's own rounded corners).
const LAUREL_CLEARANCE := 0.006


## The real outward radius of `style`'s own hair envelope at horizontal
## angle `angle` (0 = straight back/-Z, +-PI/2 = the ears/+-X, PI = straight
## front/+Z) -- an ellipse-quadrant interpolation between the REAL width/
## front/back edges FigureHair.hair_edges() returns, not a single guessed
## number. Every hairstyle's own real envelope is rectangular-ish (an edges
## Dictionary), not literally elliptical, so this is an approximation --
## but one grounded in that style's own actual numbers, which is what
## actually varies from style to style, rather than a single constant that
## can only ever be right for one of them.
static func _envelope_radius_at(edges: Dictionary, angle: float) -> float:
	var z_edge: float = absf(edges["front"]) if cos(angle) < 0.0 else absf(edges["back"])
	var width: float = maxf(edges["width"], 0.001)
	z_edge = maxf(z_edge, 0.001)
	var x_term := sin(angle) / width
	var z_term := cos(angle) / z_edge
	var denom := sqrt(x_term * x_term + z_term * z_term)
	return 1.0 / maxf(denom, 0.001)


## A gold laurel wreath -- per direct instruction ("for the rulers to have
## something resembling a Greek crown. Like, gold Greek laurels. Which
## start as a ring coming around the back of the head"). `head_mesh` is the
## same MeshInstance3D FigureHair.add_hair() was called on for this same
## character; `style`/`semi_axes` must match that same call so the wreath
## always sits against whatever hairstyle is actually built, not a guess.
## Per direct correction against a real reference photo: the band is NOT a
## level ring -- it rises from low at the back/nape up to high near the
## front hairline (back_y/front_y below), each leaf stands roughly upright
## along that band rather than lying flat pointing straight outward, and it
## uses a real metallic gold material (see _gold_material()), not a flat
## diffuse color.
static func build_laurel_wreath(head_mesh: MeshInstance3D, semi_axes: Vector3, style: String, color: Color) -> Node3D:
	var edges := FigureHair.hair_edges(style, semi_axes)
	var gold_material := _gold_material(color)
	var half_arc := deg_to_rad(LAUREL_ARC_DEGREES) * 0.5
	var back_y: float = FigureEyes.top_y(semi_axes) * 0.35
	var front_y: float = edges["top"] * 0.85
	var wreath := Node3D.new()
	wreath.name = "LaurelWreath"
	head_mesh.add_child(wreath)
	for i in LAUREL_LEAF_COUNT:
		var t := float(i) / float(LAUREL_LEAF_COUNT - 1)
		var angle := lerpf(-half_arc, half_arc, t)
		var height_t := absf(angle) / half_arc
		var ring_y := lerpf(back_y, front_y, height_t)
		var radius := _envelope_radius_at(edges, angle) + LAUREL_CLEARANCE
		var outward := Vector3(sin(angle), 0.0, -cos(angle))
		var tangent := Vector3(cos(angle), 0.0, sin(angle))
		var pos := Vector3(0.0, ring_y, 0.0) + outward * radius
		# The leaf's own long axis (LAUREL_LEAF_SIZE.z) points mostly UP with
		# a slight outward lean, standing it up along the band instead of
		# flat/radial (per direct correction, "oriented vertically, not
		# horizontally"); tangent has zero Y and outward has zero Y, so this
		# stays a genuine orthonormal basis, not an approximate/skewed one.
		var z_axis := (outward * 0.5 + Vector3.UP).normalized()
		var y_axis := z_axis.cross(tangent).normalized()
		var sides: Array[float] = [-1.0, 1.0]
		for side in sides:
			var leaf := MeshInstance3D.new()
			leaf.mesh = SuperEgg.build_mesh(LAUREL_LEAF_SIZE, 2.2, 2.2)
			leaf.material_override = gold_material
			leaf.basis = Basis(tangent, y_axis, z_axis).rotated(outward, side * LAUREL_FAN_ANGLE)
			leaf.position = pos + tangent * side * 0.012
			wreath.add_child(leaf)
	return wreath


## The shared metallic gold recipe (matches sky_kingdom.gd's own
## _gold_material() -- same numbers, kept as its own copy since that one is
## a private instance method scoped to Sky Kingdom's own StandardMaterial3D
## caching, not a shared utility this file can call into).
static func _gold_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = 0.85
	material.roughness = 0.22
	return material


## A small ornament (shell or sea-flower, see merfolk.gd's own
## hair_ornament export) nestled against the real outward hair surface on
## one side of the head, at brow height -- replacing a single fixed local
## offset that clipped into bulkier hairstyles and floated away from
## slimmer ones. `side`: -1.0 or 1.0.
static func side_hair_anchor(semi_axes: Vector3, style: String, side: float) -> Dictionary:
	var edges := FigureHair.hair_edges(style, semi_axes)
	var angle := side * deg_to_rad(60.0)  # 0 = back, so 60 degrees puts this just behind the ear
	var radius := _envelope_radius_at(edges, angle) + LAUREL_CLEARANCE
	var outward := Vector3(sin(angle), 0.0, -cos(angle))
	var y := FigureEyes.top_y(semi_axes) * 0.55
	return {
		"position": Vector3(0.0, y, 0.0) + outward * radius,
		"outward": outward,
	}


## China village kit; every attachment reads the hairstyle's authored envelope.
static func build_village_headwear(head: MeshInstance3D, axes: Vector3, style: String, kind: String, color: Color) -> Node3D:
	var mount := Node3D.new()
	mount.name="VillageHeadwear"
	head.add_child(mount)
	var edges := FigureHair.hair_edges(style,axes)
	var top: float=maxf(float(edges.top),axes.y)
	if kind in ["wrap","kerchief"]:
		var band := SuperEgg.build_part(Vector3(float(edges.width)+0.008,0.028,(absf(float(edges.back))+absf(float(edges.front)))*0.5+0.006),color,SuperEgg.EPSILON_SOFT,SuperEgg.EPSILON_FLAT)
		band.name="TopknotWrap"
		band.position=Vector3(0,top*0.73,(float(edges.front)+float(edges.back))*0.5)
		mount.add_child(band)
		if kind=="kerchief":
			var cap:=SuperEgg.build_part(Vector3(float(edges.width)+0.008,0.045,axes.z*0.92),Color(0.78,0.78,0.69),SuperEgg.EPSILON_SOFT,SuperEgg.EPSILON_FLAT)
			cap.position=Vector3(0,top-0.025,-0.025)
			mount.add_child(cap)
		var knot:=SuperEgg.build_part(Vector3(0.035,0.025,0.025),color,2.0,2.0)
		knot.position=Vector3(0,top*0.75,float(edges.back)-0.01)
		mount.add_child(knot)
	elif kind=="pin":
		var anchor:=side_hair_anchor(axes,style,1.0)
		var pin:=SuperEgg.build_part(Vector3(0.11,0.007,0.007),Color(0.61,0.49,0.34),2.0,2.0)
		pin.name="BunHairpin"
		pin.position=Vector3(0,top*0.87,float(anchor.position.z))
		pin.rotation.z=0.16
		mount.add_child(pin)
	elif kind=="ribbons":
		for side: float in [-1.0,1.0]:
			var ribbon:=SuperEgg.build_part(Vector3(0.023,0.055,0.014),color,SuperEgg.EPSILON_SOFT,SuperEgg.EPSILON_FLAT)
			ribbon.position=Vector3(side*(float(edges.width)+0.015),top*0.5,float(edges.back)*0.6)
			mount.add_child(ribbon)
	elif kind in ["straw","back_hat"]:
		# Closed radial cone, softly rounded rim. Head and shoulders use separate
		# frames for the pushed-back roofer's hat, never a guessed scalp offset.
		var vertices:=PackedVector3Array()
		var normals:=PackedVector3Array()
		for i in 24:
			var a:=TAU*float(i)/24.0
			var b:=TAU*float(i+1)/24.0
			var p:=Vector3(cos(a)*0.33,0,sin(a)*0.33)
			var q:=Vector3(cos(b)*0.33,0,sin(b)*0.33)
			var apex:=Vector3(0,0.16,0)
			for point in [apex,q,p]:
				vertices.append(point); normals.append((q-apex).cross(p-apex).normalized())
		var arrays:=[]; arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX]=vertices;arrays[Mesh.ARRAY_NORMAL]=normals
		var hat:=MeshInstance3D.new();var mesh:=ArrayMesh.new()
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
		hat.mesh=mesh
		var mat:=StandardMaterial3D.new();mat.albedo_color=Color(0.64,0.53,0.34);mat.cull_mode=BaseMaterial3D.CULL_DISABLED
		hat.material_override=mat
		hat.name="StrawWorkHat"
		hat.position=Vector3(0,top+0.015,0)
		if kind=="back_hat":
			hat.position=Vector3(0,-0.16,float(edges.back)-0.10)
			hat.rotation.x=deg_to_rad(-65)
		mount.add_child(hat)
		var rim:=TorusMesh.new();rim.inner_radius=0.322;rim.outer_radius=0.336;rim.rings=24;rim.ring_segments=6
		var hem:=MeshInstance3D.new();hem.mesh=rim;hem.material_override=mat
		hat.add_child(hem)
	return mount


static func build_court_crown(head: MeshInstance3D, axes: Vector3, style: String) -> Node3D:
	var crown:=Node3D.new();crown.name="CourtCrown"
	head.add_child(crown)
	var edges:=FigureHair.hair_edges(style,axes)
	var board_y: float=maxf(float(edges.top),axes.y)+0.045
	var red:=Color(0.53,0.09,0.075)
	var cap:=SuperEgg.build_part(Vector3(axes.x*0.79,0.055,axes.z*0.72),Color(0.045,0.047,0.05),SuperEgg.EPSILON_SOFT,SuperEgg.EPSILON_FLAT)
	cap.position=Vector3(0,board_y-0.05,0)
	crown.add_child(cap)
	for top in [false,true]:
		var board:=SuperEgg.build_part(Vector3(0.215,0.009,0.19),Color(0.035,0.041,0.05) if top else red,SuperEgg.EPSILON_SOFT,SuperEgg.EPSILON_FLAT)
		board.name="CrownBlackTop" if top else "CrownRedUnderside"
		board.position=Vector3(0,board_y+(0.018 if top else 0.0),0)
		crown.add_child(board)
	for side: float in [-1.0,1.0]:
		for i in 12:
			var strand:=Node3D.new();strand.name="JadeStrand%s%02d"%["Front" if side>0 else "Back",i];crown.add_child(strand)
			var x:=lerpf(-0.19,0.19,float(i)/11.0)
			var cord:=SuperEgg.build_part(Vector3(0.0018,0.095,0.0018),Color(0.66,0.57,0.36),2.0,2.0)
			cord.position=Vector3(x,board_y-0.10,side*0.182);strand.add_child(cord)
			for bead_index in 5:
				var bead:=SuperEgg.build_part(Vector3(0.0055,0.006,0.0055),Color(0.78,0.83,0.72) if bead_index%2==0 else Color(0.32,0.53,0.45),2.0,2.0)
				bead.position=Vector3(x,board_y-0.035-float(bead_index)*0.035,side*0.182)
				strand.add_child(bead)
	return crown
