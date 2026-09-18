extends Node3D

## A continuously operating chair lift on one closed cable loop.
##
## BUG FIX: the chairs used to be AnimatableBody3D platforms, moved by
## directly writing global_position/rotation in _process() -- per this
## project's own established finding (AnimatableBody3D is unreliable here
## for script-driven movement a player needs to physically stand on and be
## carried by), that never actually worked: the chairs sat inert instead of
## visibly cycling around the loop. Rebuilt as plain StaticBody3D platforms
## moved in _physics_process() instead (the same "kinematically animated
## StaticBody3D" pattern this project already uses successfully elsewhere,
## e.g. dinosaur_titan.gd's own animated leg colliders) -- moving a real
## physics body specifically on the physics tick, not the render tick, is
## also what lets Godot's own CharacterBody3D floor-platform-velocity
## detection actually carry a standing player along for the ride. Nothing
## about player.gd needed to change for that: this lift's own cruise height
## (see CRUISE_HEIGHT below) sits well past player.gd's own
## MAX_TERRAIN_FOLLOW_HEIGHT proximity band, so its analytic ground-snap
## already leaves a rider's real physics-resolved height alone rather than
## fighting it back down to the far-below terrain.
##
## Per direct correction, the route height is no longer one flat
## CABLE_HEIGHT: each terminal now dips the whole loop down to
## TERMINAL_HEIGHT (chair height above ground, once CHAIR_DROP's own hang
## is subtracted, low enough to step onto directly from the terminal deck)
## over TERMINAL_RAMP_FRACTION of the route, then rises to a taller
## CRUISE_HEIGHT for the main span in between -- "raise the height of the
## line other than the beginning and end, so the player has a higher ride."
## The two straight spans are joined by sampled semicircles around the
## terminal bullwheels, so chairs never disappear or reverse at an endpoint.

const POLE_COUNT := 11
const CHAIR_COUNT := 10
## Per direct correction ("raise the height of the line... a higher ride").
## Raise all cable machinery without changing the seat path. CHAIR_DROP gains
## this exact amount too, so cable_y - drop—and therefore every pickup,
## cruise and drop-off chair altitude—remains invariant.
const MACHINERY_RAISE := 3.2
const CRUISE_HEIGHT := 13.5 + MACHINERY_RAISE
## How high the chair itself (not the cable) ends up above ground at each
## terminal, once CHAIR_DROP's own hang-below-cable is subtracted --
## TERMINAL_HEIGHT - CHAIR_DROP stays a small positive gap, low enough to
## step onto from the terminal deck without an awkward jump, but still
## clear of the deck itself.
## Leaves the enlarged chair clear of both terrain and the terminal deck.
## The former 2.5 put its seat surface partly inside the deck at the upper
## terminal, which is what made a carried rider strike the mountain there.
const TERMINAL_HEIGHT := 3.0 + MACHINERY_RAISE
## Fraction of the total route, at EACH end, that ramps between
## TERMINAL_HEIGHT and CRUISE_HEIGHT -- see _lift_height_at().
const TERMINAL_RAMP_FRACTION := 0.12
const LANE_OFFSET := 1.65
const CHAIR_DROP := 2.05 + MACHINERY_RAISE
const LIFT_SPEED := 12.0
## Detachable lifts ease through each terminal so boarding and unloading do
## not demand cruise-speed timing, then smoothly accelerate onto the span.
# Keep the former 3.36-unit terminal speed (8.0 * 0.42) even though the
# main-span cruise speed is now 50% faster.
const TERMINAL_SPEED_FACTOR := 0.28
const TERMINAL_SLOW_RADIUS := 8.5
const STEEL := Color(0.18,0.22,0.26)
const CABLE_COLOR := Color(0.08,0.09,0.1)
const SEAT_COLOR := Color(0.52,0.12,0.16)
const BULLWHEEL_RADIUS := LANE_OFFSET
const BULLWHEEL_COLOR := Color(0.24,0.26,0.29)
const TURN_SEGMENTS := 24
const CHAIR_SCALE := 1.15
## Lower the open, forward boarding edge slightly so a chair can scoop a
## waiting player onto its surface instead of presenting a level blunt lip.
const SEAT_BOARDING_PITCH := deg_to_rad(-4.0)

var _terrain: Node
var _cable_points: Array[Vector3] = []
var _loop_points: Array[Vector3] = []
var _chairs: Array[Dictionary] = []
var _route_length := 0.0


func _ready() -> void:
	_terrain=get_node("../Terrain")
	var endpoints: Array[Vector2]=_terrain.get_ski_lift_endpoints()
	var route_along:=Vector3(endpoints[1].x-endpoints[0].x,0.0,endpoints[1].y-endpoints[0].y).normalized()
	var route_lateral:=Vector3(-route_along.z,0.0,route_along.x)
	for i in POLE_COUNT:
		var t:=float(i)/float(POLE_COUNT-1)
		var planar:=endpoints[0].lerp(endpoints[1],t)
		var ground_y: float=_terrain.get_mesh_height(planar.x,planar.y)
		var height:=_lift_height_at(t)
		var cable_point:=Vector3(planar.x,ground_y+height,planar.y)
		_cable_points.append(cable_point)
		# Terminal machinery supports the two ends. Omitting a redundant pole
		# from the centre of each boarding deck leaves the turnaround and rider
		# path unobstructed, especially at the steep upper mountain terminal.
		if i>0 and i<POLE_COUNT-1:
			_build_pylon(Vector3(planar.x,ground_y,planar.y),height,route_lateral)
	_build_loop_path()
	_build_cables()
	_build_terminals()
	for i in CHAIR_COUNT:
		var chair:=_build_chair()
		_chairs.append({
			"body":chair,
			"progress":float(i)/float(CHAIR_COUNT),
			"initialized":false,
		})


## Low near both ends (t=0 and t=1, for boarding/alighting), raised to
## CRUISE_HEIGHT for the main span between them -- see this file's own
## class doc comment.
func _lift_height_at(t: float) -> float:
	var ramp_in:=smoothstep(0.0,TERMINAL_RAMP_FRACTION,t)
	var ramp_out:=smoothstep(0.0,TERMINAL_RAMP_FRACTION,1.0-t)
	return lerpf(TERMINAL_HEIGHT,CRUISE_HEIGHT,minf(ramp_in,ramp_out))


## Moved from _process() to _physics_process() -- see this file's own class
## doc comment for why that's the actual fix, not just the node-type change.
func _physics_process(delta: float) -> void:
	if _route_length<=0.001:
		return
	for state in _chairs:
		var old_progress: float=float(state["progress"])
		var old_sample:=_sample_route(old_progress)
		var speed_factor:=_terminal_speed_factor(old_sample[0] as Vector3)
		var progress: float=fposmod(old_progress+delta*LIFT_SPEED*speed_factor/_route_length,1.0)
		state["progress"]=progress
		var sample:=_sample_route(progress)
		var point: Vector3=sample[0]
		var tangent: Vector3=sample[1]
		var body:=state["body"] as StaticBody3D
		var next_position:=point-Vector3.UP*CHAIR_DROP
		# Chair faces local -Z (its backrest is on +Z), so -Z—not the
		# backrest—must point along the direction of cable travel.
		var next_yaw:=atan2(-tangent.x,-tangent.z)
		if bool(state["initialized"]):
			# StaticBody constant velocities tell CharacterBody riders exactly
			# how their moving floor is travelling. This also lets the low seat
			# impart its upward/forward motion when it catches a waiting player.
			body.constant_linear_velocity=(next_position-body.global_position)/maxf(delta,0.0001)
			body.constant_angular_velocity=Vector3(
				0.0,wrapf(next_yaw-body.rotation.y,-PI,PI)/maxf(delta,0.0001),0.0
			)
		else:
			body.constant_linear_velocity=Vector3.ZERO
			body.constant_angular_velocity=Vector3.ZERO
			state["initialized"]=true
		body.global_position=next_position
		body.rotation.y=next_yaw


## Both lanes pass close to the same endpoint while rounding its bullwheel.
## Planar distance therefore gives one continuous ease-in/ease-out profile
## across the complete semicircle without hard-coding route indices.
func _terminal_speed_factor(point: Vector3) -> float:
	var lower_distance:=Vector2(point.x,point.z).distance_to(Vector2(_cable_points[0].x,_cable_points[0].z))
	var upper_distance:=Vector2(point.x,point.z).distance_to(Vector2(_cable_points[-1].x,_cable_points[-1].z))
	var nearest:=minf(lower_distance,upper_distance)
	var blend:=smoothstep(BULLWHEEL_RADIUS,TERMINAL_SLOW_RADIUS,nearest)
	return lerpf(TERMINAL_SPEED_FACTOR,1.0,blend)


func _build_pylon(base: Vector3,height: float,lateral: Vector3) -> void:
	var body:=StaticBody3D.new()
	body.collision_layer=1
	body.collision_mask=0
	body.position=base
	var pole:=SuperEgg.build_part(Vector3(0.34,height*0.5,0.34),STEEL,2.3,2.3)
	pole.position.y=height*0.5
	body.add_child(pole)
	CollisionPolicy.add_cylinder(body,pole,0.34,height,pole.position,false)
	var crossbar:=SuperEgg.build_part(Vector3(2.55,0.18,0.22),STEEL,3.4,3.4)
	var x_axis:=lateral.normalized()
	var crossbar_basis:=Basis(x_axis,Vector3.UP,x_axis.cross(Vector3.UP)).orthonormalized()
	crossbar.transform=Transform3D(crossbar_basis,Vector3(0.0,height,0.0))
	body.add_child(crossbar)
	CollisionPolicy.add_box(body,crossbar,Vector3(5.1,0.36,0.44),crossbar.position,crossbar_basis,true)
	# The two cable nodes sit at the exact authored lane offsets rather than
	# merely passing somewhere above a world-axis-aligned crossbar.
	for side: float in [-1.0,1.0]:
		var node_position: Vector3=Vector3(0.0,height,0.0)+x_axis*LANE_OFFSET*side
		var saddle:=SuperEgg.build_part(Vector3(0.20,0.15,0.24),BULLWHEEL_COLOR,2.6,2.6)
		saddle.position=node_position
		body.add_child(saddle)
		CollisionPolicy.mark_decorative(saddle)
	add_child(body)


func _build_cables() -> void:
	for i in _loop_points.size():
		_add_segment(
			self,_loop_points[i],_loop_points[(i+1)%_loop_points.size()],
			0.055,CABLE_COLOR
		)


## Builds outbound lane, upper turnaround, return lane, and lower turnaround
## as one ordered polyline. Semicircles extend beyond each terminal along
## the main cable direction, matching a real bullwheel loop.
func _build_loop_path() -> void:
	_loop_points.clear()
	_route_length=0.0
	if _cable_points.size()<2:
		return
	var along:=Vector3(
		_cable_points[-1].x-_cable_points[0].x,0.0,
		_cable_points[-1].z-_cable_points[0].z
	).normalized()
	var lateral:=Vector3(-along.z,0.0,along.x)
	for point in _cable_points:
		_loop_points.append(point+lateral*LANE_OFFSET)
	var upper:=_cable_points[-1]
	for step in range(1,TURN_SEGMENTS+1):
		var angle:=PI*float(step)/float(TURN_SEGMENTS)
		_loop_points.append(upper+lateral*(cos(angle)*LANE_OFFSET)+along*(sin(angle)*LANE_OFFSET))
	for index in range(_cable_points.size()-2,-1,-1):
		_loop_points.append(_cable_points[index]-lateral*LANE_OFFSET)
	var lower:=_cable_points[0]
	for step in range(1,TURN_SEGMENTS+1):
		var angle:=PI+PI*float(step)/float(TURN_SEGMENTS)
		_loop_points.append(lower+lateral*(cos(angle)*LANE_OFFSET)+along*(sin(angle)*LANE_OFFSET))
	for i in _loop_points.size():
		_route_length+=_loop_points[i].distance_to(_loop_points[(i+1)%_loop_points.size()])


func _build_terminals() -> void:
	for point in [_cable_points[0],_cable_points[-1]]:
		var ground_y: float=_terrain.get_mesh_height(point.x,point.z)
		var body:=StaticBody3D.new()
		body.collision_layer=1
		var deck:=SuperEgg.build_part(Vector3(3.8,0.28,3.2),Color(0.34,0.24,0.17),3.8,3.8)
		deck.position=Vector3(point.x,ground_y+0.28,point.z)
		body.add_child(deck)
		CollisionPolicy.add_box(body,deck,Vector3(7.6,0.56,6.4),deck.position,Basis(),true)
		add_child(body)
		_build_terminal_base(point,ground_y)
		_build_bullwheel(point,ground_y)


## A raised detachable-lift terminal: broad ground plinth, rear-raked tower,
## and machinery cap beneath the bullwheel. Unlike a pole planted through a
## boarding deck, the tower leans in from the route-facing rear half, leaving
## the complete low chair sweep open for riders.
func _build_terminal_base(point: Vector3,ground_y: float) -> void:
	var other:=_cable_points[0] if point!=_cable_points[0] else _cable_points[-1]
	var toward_route:=Vector3(other.x-point.x,0.0,other.z-point.z).normalized()
	var lateral:=Vector3(-toward_route.z,0.0,toward_route.x)
	var body:=StaticBody3D.new()
	body.name="RaisedLiftTerminal"
	body.collision_layer=1
	body.collision_mask=0
	var plinth:=SuperEgg.build_part(Vector3(2.9,0.26,2.25),STEEL.darkened(0.16),3.6,3.6)
	plinth.position=Vector3(point.x,ground_y+0.26,point.z)-toward_route*1.25
	body.add_child(plinth)
	CollisionPolicy.add_box(body,plinth,Vector3(5.8,0.52,4.5),plinth.position,Basis(),true)
	# The turnaround semicircle occupies the outward (-toward_route) side of
	# each terminal. The first raised-base draft put this entire rake directly
	# into that chair sweep. Move it inward beneath the straight-span centreline
	# and keep it narrow enough that both offset chair lanes clear its sides.
	var tower_from:=Vector3(point.x,ground_y+0.5,point.z)+toward_route*1.55
	var tower_to:=Vector3(point.x,ground_y+TERMINAL_HEIGHT-0.48,point.z)+toward_route*0.72
	_add_structural_segment(body,tower_from,tower_to,0.46)
	var cap_axes:=Vector3(BULLWHEEL_RADIUS+0.72,0.22,1.42)
	var cap:=SuperEgg.build_part(cap_axes,STEEL,3.5,3.5)
	var cap_basis:=Basis(lateral,Vector3.UP,lateral.cross(Vector3.UP)).orthonormalized()
	var cap_position:=Vector3(point.x,ground_y+TERMINAL_HEIGHT-0.32,point.z)-toward_route*0.22
	cap.transform=Transform3D(cap_basis,cap_position)
	body.add_child(cap)
	CollisionPolicy.add_box(body,cap,cap_axes*2.0,cap_position,cap_basis,true)
	add_child(body)
	CollisionPolicy.validate_body(body)


func _add_structural_segment(body: StaticBody3D,from: Vector3,to: Vector3,radius: float) -> void:
	var delta:=to-from
	var y_axis:=delta.normalized()
	var seed:=Vector3.FORWARD if absf(y_axis.dot(Vector3.FORWARD))<0.9 else Vector3.RIGHT
	var x_axis:=seed.cross(y_axis).normalized()
	var z_axis:=x_axis.cross(y_axis).normalized()
	var basis:=Basis(x_axis,y_axis,z_axis)
	var midpoint:=(from+to)*0.5
	var segment:=SuperEgg.build_part(Vector3(radius,delta.length()*0.5,radius),STEEL,2.8,2.8)
	segment.transform=Transform3D(basis,midpoint)
	body.add_child(segment)
	CollisionPolicy.add_box(body,segment,Vector3(radius*2.0,delta.length(),radius*2.0),midpoint,basis,true)


## Horizontal bullwheel centred inside the real turnaround arc. The cable
## turns around it in plan view, so its axle is vertical—matching both the
## reference terminal and the actual horizontal semicircle in _loop_points.
func _build_bullwheel(point: Vector3,ground_y: float) -> void:
	var wheel:=SuperEgg.build_part(
		Vector3(BULLWHEEL_RADIUS,0.16,BULLWHEEL_RADIUS),BULLWHEEL_COLOR,2.0,2.0
	)
	wheel.position=Vector3(point.x,ground_y+TERMINAL_HEIGHT,point.z)
	add_child(wheel)
	CollisionPolicy.mark_decorative(wheel)
	var hub:=SuperEgg.build_part(Vector3(0.25,0.34,0.25),STEEL,2.4,2.4)
	hub.position=wheel.position
	add_child(hub)
	CollisionPolicy.mark_decorative(hub)


func _build_chair() -> StaticBody3D:
	var body:=StaticBody3D.new()
	body.collision_layer=1
	body.collision_mask=0
	var seat_axes:=Vector3(0.85,0.12,0.55)*CHAIR_SCALE
	var seat:=SuperEgg.build_part(seat_axes,SEAT_COLOR,3.5,3.5)
	seat.rotation.x=SEAT_BOARDING_PITCH
	body.add_child(seat)
	CollisionPolicy.add_box(body,seat,seat_axes*2.0,seat.position,Basis(Vector3.RIGHT,SEAT_BOARDING_PITCH),true)
	var back_axes:=Vector3(0.85,0.58,0.10)*CHAIR_SCALE
	var back:=SuperEgg.build_part(back_axes,SEAT_COLOR,3.5,3.5)
	back.position=Vector3(0.0,0.55*CHAIR_SCALE,0.48*CHAIR_SCALE)
	body.add_child(back)
	CollisionPolicy.add_box(body,back,back_axes*2.0,back.position,Basis(),true)
	# Attach behind the backrest, then sweep farther rearward before returning
	# to the cable high above the rider. A straight diagonal crossed the head
	# volume; this segmented curve preserves a completely open seat envelope.
	var hanger_bottom:=Vector3(0.0,back.position.y+back_axes.y*0.72,back.position.z)
	_add_chair_hanger_curve(body,hanger_bottom)
	add_child(body)
	CollisionPolicy.validate_body(body)
	return body


func _add_chair_hanger_curve(body: StaticBody3D,from: Vector3) -> void:
	var points: Array[Vector3]=[
		from,
		Vector3(0.0,lerpf(from.y,CHAIR_DROP,0.24),from.z+0.24),
		Vector3(0.0,lerpf(from.y,CHAIR_DROP,0.66),from.z+0.18),
		Vector3(0.0,CHAIR_DROP,0.0),
	]
	for i in points.size()-1:
		_add_chair_hanger_segment(body,points[i],points[i+1])


func _add_chair_hanger_segment(body: StaticBody3D,from: Vector3,to: Vector3) -> void:
	var delta:=to-from
	var y_axis:=delta.normalized()
	var seed:=Vector3.FORWARD if absf(y_axis.dot(Vector3.FORWARD))<0.9 else Vector3.RIGHT
	var x_axis:=seed.cross(y_axis).normalized()
	var z_axis:=x_axis.cross(y_axis).normalized()
	var basis:=Basis(x_axis,y_axis,z_axis)
	var midpoint:=(from+to)*0.5
	var hanger:=SuperEgg.build_part(Vector3(0.07,delta.length()*0.5,0.07),STEEL,2.2,2.2)
	hanger.transform=Transform3D(basis,midpoint)
	body.add_child(hanger)
	CollisionPolicy.add_box(body,hanger,Vector3(0.14,delta.length(),0.14),midpoint,basis,false)


func _sample_route(progress: float) -> Array:
	var target:=clampf(progress,0.0,1.0)*_route_length
	var travelled:=0.0
	for i in _loop_points.size():
		var a:=_loop_points[i]
		var b:=_loop_points[(i+1)%_loop_points.size()]
		var length:=a.distance_to(b)
		if travelled+length>=target or i==_loop_points.size()-1:
			var local_t:=clampf((target-travelled)/maxf(length,0.001),0.0,1.0)
			# Blend adjacent segment headings so chairs rotate continuously around
			# pylons and turnaround arcs instead of snapping at polyline vertices.
			var previous:=_loop_points[(i-1+_loop_points.size())%_loop_points.size()]
			var following:=_loop_points[(i+2)%_loop_points.size()]
			var tangent_a:=((a-previous).normalized()+(b-a).normalized()).normalized()
			var tangent_b:=((b-a).normalized()+(following-b).normalized()).normalized()
			return [a.lerp(b,local_t),tangent_a.lerp(tangent_b,local_t).normalized()]
		travelled+=length
	return [_loop_points[0],(_loop_points[1]-_loop_points[0]).normalized()]


func _add_segment(parent: Node3D,from: Vector3,to: Vector3,radius: float,color: Color) -> void:
	var delta:=to-from
	if delta.length()<0.001:
		return
	var y_axis:=delta.normalized()
	var seed:=Vector3.FORWARD if absf(y_axis.dot(Vector3.FORWARD))<0.9 else Vector3.RIGHT
	var x_axis:=seed.cross(y_axis).normalized()
	var z_axis:=x_axis.cross(y_axis).normalized()
	var segment:=SuperEgg.build_part(Vector3(radius,delta.length()*0.5,radius),color,2.2,2.2)
	segment.global_transform=Transform3D(Basis(x_axis,y_axis,z_axis),(from+to)*0.5)
	CollisionPolicy.mark_decorative(segment)
	parent.add_child(segment)
