class_name BlorbBounce
extends RefCounted

## Finding the blorb a body is about to land on, for any character
## (docs/traversal_powers_architecture.md).
##
## An ordinary blorb can never become a stable floor: a body that touches one
## is thrown off it. Getting that right means resolving the contact before
## the physics solver can settle a CharacterBody against the crown and call
## it ground, so the crossing is predicted from this frame's own travel.
##
## Both characters searched for that blorb themselves, with the same loop and
## slightly different bands, and both re-checked what the blorb already
## checks for itself.

## Predict contact from this frame's downward travel before move_and_slide()
## can settle the body against the blorb. The small precontact band absorbs
## moving-blorb and physics-tick disagreement; the recovery depth catches a
## contact that began a frame earlier without turning side-brushes into jumps.
const PRECONTACT_MARGIN := 0.10
const RECOVERY_DEPTH := 0.22
## How far clear of the crown a body is placed once the bounce is resolved.
const RELEASE_CLEARANCE := 0.035
## Below this, a contact normal is a side-brush rather than a landing.
const CONTACT_NORMAL_MIN := 0.2


## The blorb whose crown this body's feet cross this frame, or null. The
## highest one wins, so stacked blorbs throw from the top.
static func predicted(
	tree: SceneTree, feet_y: float, projected_xz: Vector2, projected_feet_y: float
) -> Blorb:
	var best: Blorb = null
	var best_surface := -INF
	for node in tree.get_nodes_in_group("blorbs"):
		var candidate := node as Blorb
		if candidate == null:
			continue
		# A worn, melted or giant blorb answers null for itself here, so
		# nothing outside has to know which kinds can be bounced off.
		var surface: Variant = candidate.bounce_surface_height_at(projected_xz.x, projected_xz.y)
		if surface == null:
			continue
		var surface_y: float = surface as float
		if feet_y < surface_y - RECOVERY_DEPTH:
			continue
		if projected_feet_y > surface_y + PRECONTACT_MARGIN:
			continue
		if surface_y > best_surface:
			best_surface = surface_y
			best = candidate
	return best


## The blorb already under this body in the frame's resolved collisions, for
## the edge case where a squashed or moving crown differs from its analytic
## surface. Ordinary landings resolve through predicted() above.
static func in_contact(body: CharacterBody3D) -> Blorb:
	for index in body.get_slide_collision_count():
		var collision := body.get_slide_collision(index)
		if collision.get_normal().y < CONTACT_NORMAL_MIN:
			continue
		var candidate := collision.get_collider() as Blorb
		if candidate != null and not candidate.is_worn and not candidate.is_melted and candidate.blorb_type != "size":
			return candidate
	return null


## Where a body's feet rest to launch off `blorb`: never lower than they
## already are, on or above its rendered crown, and high enough that the
## body's own rounded bottom clears the blorb's collision sphere.
##
## That last part is the whole point. Off-centre, the crown under the feet
## sits lower than where the two colliders actually meet, so resting on the
## crown alone starts the next move inside the sphere; physics then reports
## that overlap as a fresh landing and the bounce repeats every frame without
## ever leaving, which is what a body frozen mid-jump over a permanently
## squashed blorb actually is.
static func rest_feet_y(blorb: Blorb, at: Vector3, feet_y: float, body_radius: float) -> float:
	var rest := feet_y
	var crown: Variant = blorb.bounce_surface_height_at(at.x, at.z)
	if crown != null:
		rest = maxf(rest, (crown as float) + RELEASE_CLEARANCE)
	var sphere: Dictionary = blorb.bounce_collider_sphere()
	var center: Vector3 = sphere["center"]
	var reach: float = float(sphere["radius"]) + body_radius
	var across := Vector2(at.x - center.x, at.z - center.z).length()
	if across < reach:
		# The body's lowest point sits `body_radius` above its feet.
		var clear_feet: float = center.y + sqrt(reach * reach - across * across) - body_radius
		rest = maxf(rest, clear_feet + RELEASE_CLEARANCE)
	return rest


## Where a body's feet rest once thrown clear of `surface_y`, where the
## blorb's own collider is not in question.
static func release_height(surface_y: float) -> float:
	return surface_y + RELEASE_CLEARANCE
