class_name OhioPlan
extends RefCounted

## The one authored layout of Ohio. TownGenerator builds the village from these
## numbers and tools/validate_village.gd checks the result against them, so a
## building, a street or a yard is moved here and nowhere else. The reasons
## live in docs/architecture/ohio.md (section 3, the town plan).
##
## Town-local metres: +X east, +Z south, the origin is the fountain. Yaw is in
## degrees about Y: 0 puts a building's front door on its north (-Z) wall,
## -90 on its east wall, 90 on its west, 180 on its south. The plateau rim lies
## 85 to 95 m east of the fountain.

# ---------------------------------------------------------------------------
# Buildings (panel buildings built from the cell grid; order sets roof colours)
# ---------------------------------------------------------------------------

## Keys: name, at, yaw, cells (width, depth), floors, and the spec read by
## TownGenerator._dress_ohio_building: residential, work, chimney, chimney_side,
## chimney_z, entry, back, shutters, upper_beds (beds on the upper floor of a
## two-storey building, default 2; Pip's loft at the sawmill has one).
const BUILDINGS: Array[Dictionary] = [
	{"name":"FaskAndPrewittHouse","at":Vector2(-19.5,28),"yaw":-90.0,"cells":Vector2(4,3),"floors":2,
		"residential":true,"work":"home_joinery","chimney":true,"entry":"door","shutters":"all",
		"dressing":"porch","features":[{"kind":"oriel","x":4.27},{"kind":"cross_gable","x":0.0,"width":3.8}]},
	{"name":"RuskinSpringworks","at":Vector2(53,-27),"yaw":90.0,"cells":Vector2(3,2),"floors":1,
		"residential":true,"work":"mason","chimney":true,"entry":"door","shutters":"upper",
		"dressing":"corbel_hood"},
	{"name":"CrayAndThorneCottage","at":Vector2(19,38),"yaw":-90.0,"cells":Vector2(3,3),"floors":2,
		"residential":true,"work":"naturalist","chimney":true,"entry":"door","back":0.0,"shutters":"all",
		"dressing":"doorstep","roof":{"half_hip":-1.0},"features":[{"kind":"rose","x":1.45},{"kind":"bay_window","x":-2.88,"floor":0}]},
	{"name":"MeetingHouseAndArchive","at":Vector2(9,-18.5),"yaw":180.0,"cells":Vector2(5,3),"floors":1,
		"residential":false,"work":"civic","chimney":true,"entry":"civic","shutters":"none",
		"roof":{"belfry_gap":{"x":-4.2,"half":0.45}},
		"features":[{"kind":"hood_moulds"},{"kind":"cross_gable","x":0.0,"width":6.4},{"kind":"belfry","x":-4.2}]},
	{"name":"BarrowBakehouse","at":Vector2(-25,2),"yaw":-90.0,"cells":Vector2(3,2),"floors":1,
		"residential":true,"work":"bakery","chimney":true,"entry":"bakery","back":-3.6,"shutters":"upper",
		"roof":{"catslide":1.7},"stock":"faggots",
		"fire":{"openings":[{"z":0.25,"width":1.8,"height":1.3}],"stack_z":0.25}},
	{"name":"FaskWaterSawmill","at":Vector2(75,-95.2),"yaw":180.0,"cells":Vector2(5,3),"floors":2,
		"residential":false,"work":"joinery","chimney":true,"chimney_side":-1.0,"entry":"cart","shutters":"none",
		"fire":{"openings":[{"z":3.6,"width":1.3,"height":1.3}],"stack_z":3.6},
		"upper_beds":1,
		"features":[{"kind":"gable_hoist","side":1.0}]},
	{"name":"VeyHouse","at":Vector2(-7.5,-19.6),"yaw":180.0,"cells":Vector2(3,3),"floors":2,
		"residential":true,"work":"dealer","chimney":true,"entry":"door","back":0.0,"shutters":"all",
		"dressing":"door_case","features":[{"kind":"juliet","x":2.4}]},
	{"name":"KestSmithy","at":Vector2(27,-18.6),"yaw":180.0,"cells":Vector2(3,3),"floors":2,
		"residential":true,"work":"smithy","chimney":true,"entry":"forge","shutters":"upper","upper_beds":1,
		"fire":{"openings":[
			{"z":0.0,"width":1.5,"height":1.15,"kind":"forge","fire":{"mode":"hours","hours":[6.0,20.0]}},
			{"z":0.0,"width":1.2,"height":1.05,"floor":1}],"stack_z":0.0},
		"features":[{"kind":"hood_moulds"}]},
	{"name":"FerrisMillhouse","at":Vector2(-40,16),"yaw":90.0,"cells":Vector2(6,2),"floors":1,
		"residential":true,"work":"grain","chimney":true,"entry":"cart","back":0.0,"shutters":"upper",
		"roof":{"catslide":1.7},"stock":"sacks","features":[{"kind":"gable_hoist","side":-1.0}]},
	{"name":"SallowWardenCottage","at":Vector2(-27,43),"yaw":-90.0,"cells":Vector2(3,2),"floors":1,
		"residential":true,"work":"herbal","chimney":true,"entry":"door","back":0.0,"shutters":"all",
		"dressing":"herb_porch","roof":{"half_hip":-1.0}},
]

## The Holt Inn is built by VillageInn (its own interior plan) and faces the
## main street.
const INN_AT := Vector2(-30,-26)
const INN_ROAD_POINT := Vector2(-30,-13.4)
const INN_HALF := Vector2(9.6,8.0)

const WINDMILL_AT := Vector2(-44,-2.5)
const WINDMILL_YAW := -90.0

const FALSE_HERO_AT := Vector2(0,10)
const FALSE_HERO_YAW := 180.0

## Market stalls: each is the open face of a named seller's trade.
const STALLS := {
	"gem": {"at":Vector2(-3.4,-12.4),"yaw":0.0},
	"red": {"at":Vector2(24.9,-10.4),"yaw":0.0},
	"green": {"at":Vector2(-10.8,-12.2),"yaw":0.0},
}

## The trade ledger: every purchasable item on a stall has a source. `from` names
## who makes or gathers it, `at` the building where that happens (empty when it
## comes in from outside the village), and `carried_by` the person who brings it
## to the stall (empty when the seller makes it where she stands). The validator
## fails when a stall sells anything the ledger does not explain.
const TRADE := {
	"Aldren Vey": {"category":"antique","stall":"gem","goods":{
		"Fire Gem":{"from":"travellers on the road","at":"VeyStorehouse","carried_by":"Aldren Vey"},
		"Electric Gem":{"from":"travellers on the road","at":"VeyStorehouse","carried_by":"Aldren Vey"},
		"Corroded Pocket Compass":{"from":"road finds and trades","at":"VeyStorehouse","carried_by":"Aldren Vey"},
		"Sealed Reliquary Locket":{"from":"road finds and trades","at":"VeyStorehouse","carried_by":"Aldren Vey"},
		"Cracked Hourglass":{"from":"road finds and trades","at":"VeyStorehouse","carried_by":"Aldren Vey"},
	}},
	"Brinna Kest": {"category":"red","stall":"red","goods":{
		"Notched Shortsword":{"from":"Brinna Kest","at":"KestSmithy","carried_by":""},
		"Dented Breastplate":{"from":"Brinna Kest","at":"KestSmithy","carried_by":""},
		"Pitch Torch":{"from":"Brinna Kest, with pitch from Dorran Fask's sawmill","at":"KestSmithy","carried_by":""},
	}},
	"Nell Barrow": {"category":"green","stall":"green","goods":{
		"Rye Loaf":{"from":"Nell Barrow, from Cob Ferris's flour","at":"BarrowBakehouse","carried_by":"Tess"},
		"Wedge of Cheese":{"from":"the north farm, Tess's family","at":"","carried_by":"Tess"},
		"Dried Berries":{"from":"the east-field farms, Pip's family","at":"","carried_by":"Dorran Fask"},
		"Blorb Slime":{"from":"Ivy Thorne, foraged where wild blorbs gather; jars on commission","at":"CrayAndThorneCottage","carried_by":"Ivy Thorne"},
	}},
}

## Every standard names the point its bracket serves ("toward"). The generator
## derives the yaw from it with VillageWorks.yaw_facing(), so the lit side can
## never be typed in backwards, and the validator checks the bracket really
## reaches toward that point. Do not author a yaw for a lantern.
##
## Civic standards around the green turn toward the fountain.
const FOUNTAIN_LANTERNS: Array[Dictionary] = [
	# The north-west standard is deliberately omitted: the arrival axis must
	# terminate on the fountain, not on a lamp planted in its sightline.
	{"at":Vector2(11.4,-5.7),"toward":Vector2.ZERO},
	{"at":Vector2(-11.4,7.6),"toward":Vector2.ZERO},{"at":Vector2(11.4,7.6),"toward":Vector2.ZERO},
	{"at":Vector2(0,15.2),"toward":Vector2.ZERO},
]
## Roadside standards sit just off the worn way. Their "toward" is the nearest
## point on MAIN_STREET, found by street_point_near().
const LAMPS: Array[Dictionary] = [
	# Standards stand beside the road, never within the clear visual corridor
	# from the gateway to the fountain.
	{"at":Vector2(-45,-19.7)},
	{"at":Vector2(-33,-15.8)},
	{"at":Vector2(-19,-11.5)},
]


## The point on a polyline closest to `p`.
static func nearest_on_polyline(points: Array[Vector2], p: Vector2) -> Vector2:
	var best := points[0]
	var best_distance := INF
	for i in points.size() - 1:
		var candidate := Geometry2D.get_closest_point_to_segment(p, points[i], points[i + 1])
		var distance := candidate.distance_to(p)
		if distance < best_distance:
			best_distance = distance
			best = candidate
	return best


static func street_point_near(p: Vector2) -> Vector2:
	return nearest_on_polyline(MAIN_STREET, p)

# ---------------------------------------------------------------------------
# Square, gateway and overlook
# ---------------------------------------------------------------------------

const NOTICE_BOARD_AT := Vector2(2.5,-10.8)
const SQUARE_TREES: Array[Vector2] = [Vector2(-10.8,8.8),Vector2(10.8,9.3),Vector2(-12.0,-3.6),Vector2(12.2,-3.4)]
const SQUARE_BEDS: Array[Vector2] = [Vector2(-8.7,6.4),Vector2(8.6,6.7),Vector2(-9.0,-2.6),Vector2(9.1,-2.4)]
## A small social table in the north-west shade, outside the fountain routes
## and the harvest-supper lawn.
const GREEN_GAME_TABLE_AT := Vector2(-4.8,9.8)

## Two lantern piers either side of the arrival road, no gate and no walls, the
## welcome sign on a stone-ringed island inside them.
const ENTRANCE := {
	"center":Vector2(-52.0,-18.3), "along":Vector2(0.95,0.31), "half_gap":3.5,
	"sign":Vector2(-47.0,-9.5),
}

## A stone terrace on the rim where the east road ends.
# Its east edge stands at the cliff lip, 1.75 m back from where it first sat
# overhanging the drop; the ground under it varies by 1.1 m, so its foundation
# is a course or two, not a wall down the cliff (tools/ohio_cliff_probe.tscn).
const OVERLOOK := {"at":Vector2(76.3,1.7), "radius":5.8, "tree":Vector2(72.0,-2.5)}

# ---------------------------------------------------------------------------
# Ways (worn earth painted into the terrain) and trodden ground
# ---------------------------------------------------------------------------

const MAIN_STREET: Array[Vector2] = [
	Vector2(-60,-21.5), Vector2(-52,-18.3), Vector2(-44,-15.6), Vector2(-36,-13.4), Vector2(-28,-11.6),
	Vector2(-20,-8.6), Vector2(-12,-5.0), Vector2(-7,-2.0),
]

## {"name", "width", "points"}: every way and footpath in the village. The mill
## road's last stretch to the footbridge is added by the generator, where the
## bridge falls.
const WAYS: Array[Dictionary] = [
	{"name":"market street","width":3.6,"points":[Vector2(-13,-6.8),Vector2(-4,-8.2),Vector2(8,-8.6),Vector2(25,-8.4),Vector2(38,-9.5)]},
	{"name":"east road","width":3.5,"points":[Vector2(38,-9.5),Vector2(52,-7),Vector2(63,-3),Vector2(72,0.5),Vector2(75.5,1.5),Vector2(78,2)]},
	{"name":"mill road","width":2.6,"points":[Vector2(46,-9),Vector2(45,-20),Vector2(46,-34),Vector2(50,-48),Vector2(53,-62),Vector2(58,-74),Vector2(65,-83),Vector2(73,-87.5)]},
	# Kept on top of the rim: its old line ran its cliff-side edge out over a
	# 4 to 6 m drop between z 12 and 29, where the rim is notched; it now curves
	# inland behind the notch (tools/ohio_cliff_probe.tscn checks every metre).
	{"name":"edge walk","width":1.8,"points":[Vector2(74,8),Vector2(71,12),Vector2(66.5,16.5),Vector2(63.2,20.5),Vector2(63,26),Vector2(63,32),Vector2(60,36.5),Vector2(56,41),Vector2(50,47)]},
	{"name":"west lane","width":2.8,"points":[Vector2(-5,8),Vector2(-8.5,16),Vector2(-10.5,24),Vector2(-12.5,32),Vector2(-15.5,40),Vector2(-19.5,45)]},
	{"name":"east lane","width":2.8,"points":[Vector2(6,8),Vector2(10,15),Vector2(15.5,22),Vector2(21,29),Vector2(24.5,35),Vector2(24.2,38.0)]},
	{"name":"back lane","width":2.2,"points":[Vector2(-19.5,47.5),Vector2(-8,51),Vector2(8,51),Vector2(23,47.5)]},
	{"name":"orchard link","width":1.8,"points":[Vector2(24.5,38),Vector2(32,40),Vector2(40,41),Vector2(48,41)]},
	{"name":"grain yard lane","width":2.6,"points":[Vector2(-10,2),Vector2(-13,9),Vector2(-18,14),Vector2(-22.5,16.6),Vector2(-26.2,17.0)]},
	{"name":"drying shed path","width":2.0,"points":[Vector2(-33,34.8),Vector2(-32.8,37.6)]},
	{"name":"kitchen garden path","width":2.0,"points":[Vector2(8.65,43.0),Vector2(9.0,47.4),Vector2(8,51)]},
	{"name":"inn door path","width":2.0,"points":[Vector2(-30,-18.5),Vector2(-30,-13.4)]},
	{"name":"fask door path","width":2.0,"points":[Vector2(-14.6,28),Vector2(-13.0,28.1),Vector2(-11.4,28.2)]},
	{"name":"wren door path","width":2.0,"points":[Vector2(-23.5,43),Vector2(-21,43.6),Vector2(-19.5,44)]},
	{"name":"inn yard path","width":2.8,"points":[Vector2(-30,-26),Vector2(-30,-18.5),Vector2(-30,-13.4),Vector2(-28,-11.8)]},
	{"name":"physic garden path","width":2.1,"points":[Vector2(-19.5,47.5),Vector2(-21.0,51.0),Vector2(-35.8,51.0),Vector2(-35.8,46.0),Vector2(-34.5,43)]},
]

## Packed-earth working ground: {"center", "radii"}.
const WORN_GROUND: Array[Dictionary] = [
	{"center":Vector2(-52,-18.3),"radii":Vector2(4.4,3.8)},
	{"center":Vector2(-30,-36.5),"radii":Vector2(8,3.2)},
	{"center":Vector2(-29.6,-1.6),"radii":Vector2(3.2,2.4)},
	{"center":Vector2(-31.8,17),"radii":Vector2(4.5,5.5)},
	{"center":Vector2(48.6,-27),"radii":Vector2(2.8,3.6)},
	{"center":Vector2(75,-86.5),"radii":Vector2(6.5,3.2)},
	{"center":Vector2(61,-27.5),"radii":Vector2(4.2,3.2)},
	{"center":Vector2(-7.5,-25.4),"radii":Vector2(3.6,2.6)},
	{"center":Vector2(24,11),"radii":Vector2(6,4)},
	{"center":Vector2(75,1),"radii":Vector2(3.5,3.5)},
]

# ---------------------------------------------------------------------------
# Yards, gardens and outbuildings
# ---------------------------------------------------------------------------

## Cob's grain yard: the millhouse's east wall is its west side.
const GRAIN_YARD := {"center":Vector2(-31.8,17.0),"size":Vector2(10,15)}
const CART_SHELTER_AT := Vector2(-29.5,13.0)
const GRANARY_AT := Vector2(-30.2,21.8)
const STONE_YARD_AT := Vector2(61,-27.5)
const VEY_STOREHOUSE_AT := Vector2(-7.5,-29.5)
## The yard abuts the cottage's wall: the side against the house is open (the hedge
## ends at the wall), the back door opens straight into it, and the gate faces a path.
const KITCHEN_GARDEN := {"center":Vector2(8.65,38.0),"size":Vector2(11,9)}
const DRYING_SHED_AT := Vector2(-34.5,32.4)
const PHYSIC_GARDEN := {"center":Vector2(-35.8,43),"size":Vector2(11,9)}
const YOGI_AT := Vector2(-27.5,9.5)

## Garden trees ({"at", "fruit", "height"}) and foundation shrubs.
const TREES: Array[Dictionary] = [
	{"at":Vector2(-11.5,35.0),"fruit":false,"height":4.6},
	{"at":Vector2(9.0,35.5),"fruit":true,"height":4.3},
	{"at":Vector2(-16.0,-20.0),"fruit":true,"height":4.5},
	{"at":Vector2(18.0,-29.0),"fruit":false,"height":4.8},
	{"at":Vector2(43.0,26.5),"fruit":true,"height":4.2},
	{"at":Vector2(33,36),"fruit":true,"height":4.2},{"at":Vector2(39,34),"fruit":true,"height":4.4},
	{"at":Vector2(45,37),"fruit":true,"height":4.1},{"at":Vector2(35,43),"fruit":true,"height":4.3},
	{"at":Vector2(41,42),"fruit":true,"height":4.2},{"at":Vector2(47,45),"fruit":true,"height":4.0},
	{"at":Vector2(26.5,13.5),"fruit":false,"height":6.0},
]
const SHRUBS: Array[Vector2] = [Vector2(-25.4,23.0),Vector2(-25.4,31.5),Vector2(25.4,29.0)]

## Residents' own ground: where each keeps to and how far they drift.
const HOMES := {
	"Oswin Cray": {"at":Vector2(24.5, 40.5), "range":6.0},
	"Petra Voss": {"at":Vector2(6.5, -11.0), "range":3.5},
	"Dorran Fask": {"at":Vector2(75.0, -87.5), "range":4.0},
	"Wren Sallow": {"at":Vector2(-22.0, 44.5), "range":9.0},
	"Tam Ruskin": {"at":Vector2(49.0, -25.0), "range":5.0},
	"Halda Prewitt": {"at":Vector2(13.0, -11.0), "range":6.0},
	"Cob Ferris": {"at":Vector2(-33.5, 17.5), "range":3.5},
	"Ivy Thorne": {"at":Vector2(3.5, 3.5), "range":9.0},
	"Pip": {"at":Vector2(73.5, -87.5), "range":4.0},
	"Tess": {"at":Vector2(-21.5, -1.0), "range":4.0},
	"Wick": {"at":Vector2(-29.5, 17.5), "range":4.5},
}

## A small authored pedestrian timetable. Each stop's route is the route FROM
## the previous stop, drawn along the same lanes and working yards as WAYS.
## TownGenerator converts these town-local points to world space before handing
## them to NPC. The result is deliberately modest: people have a recognisable
## day without turning the village into a crowd simulation.
const DAILY_SCHEDULES := {
	"Oswin Cray": [
		{"hour":5.0,"at":Vector2(24.5,40.5),"range":3.0,"route":[]},
		{"hour":9.0,"at":Vector2(9.0,47.4),"range":2.4,"route":[Vector2(25.2,44.8),Vector2(23,47.5),Vector2(9.0,47.4)]},
		{"hour":17.5,"at":Vector2(24.5,40.5),"range":3.0,"route":[Vector2(23,47.5),Vector2(25.2,44.8),Vector2(24.5,40.5)]},
	],
	"Petra Voss": [
		{"hour":6.5,"at":Vector2(6.5,-11.0),"range":2.0,"route":[Vector2(2,-8.5),Vector2(6.5,-11.0)]},
		{"hour":12.5,"at":Vector2(0.5,5.5),"range":1.8,"route":[Vector2(8,-8.6),Vector2(4,-3),Vector2(0.5,5.5)]},
		{"hour":18.0,"at":Vector2(6.5,-11.0),"range":2.0,"route":[Vector2(4,-3),Vector2(8,-8.6),Vector2(6.5,-11.0)]},
	],
	"Dorran Fask": [
		{"hour":5.5,"at":Vector2(75.0,-87.5),"range":3.5,"route":[Vector2(-12.5,32),Vector2(-8.5,16),Vector2(-5,8),Vector2(8,-8.6),Vector2(38,-9.5),Vector2(45,-20),Vector2(46,-34),Vector2(50,-48),Vector2(53,-62),Vector2(58,-74),Vector2(65,-83),Vector2(75,-87.5)]},
		{"hour":18.0,"at":Vector2(-14.0,28),"range":1.8,"route":[Vector2(65,-83),Vector2(58,-74),Vector2(53,-62),Vector2(50,-48),Vector2(46,-34),Vector2(45,-20),Vector2(38,-9.5),Vector2(8,-8.6),Vector2(-5,8),Vector2(-8.5,16),Vector2(-12.5,32),Vector2(-14.0,28)]},
	],
	"Wren Sallow": [
		{"hour":5.0,"at":Vector2(50,47),"range":2.0,"route":[Vector2(-19.5,47.5),Vector2(8,51),Vector2(23,47.5),Vector2(50,47)]},
		{"hour":8.0,"at":Vector2(-31.5,43),"range":3.0,"route":[Vector2(23,47.5),Vector2(8,51),Vector2(-21,51),Vector2(-35.8,51),Vector2(-31.5,43)]},
		{"hour":17.0,"at":Vector2(50,47),"range":2.0,"route":[Vector2(-35.8,51),Vector2(-21,51),Vector2(8,51),Vector2(23,47.5),Vector2(50,47)]},
		{"hour":20.0,"at":Vector2(-22,44.5),"range":2.0,"route":[Vector2(23,47.5),Vector2(8,51),Vector2(-19.5,47.5),Vector2(-22,44.5)]},
	],
	"Tam Ruskin": [
		{"hour":6.0,"at":Vector2(49,-25),"range":2.5,"route":[Vector2(25,-8.4),Vector2(38,-9.5),Vector2(45,-20),Vector2(49,-25)]},
		{"hour":10.0,"at":Vector2(4.5,2.0),"range":2.5,"route":[Vector2(45,-20),Vector2(38,-9.5),Vector2(25,-8.4),Vector2(8,-8.6),Vector2(4.5,2.0)]},
		{"hour":14.0,"at":Vector2(49,-25),"range":2.5,"route":[Vector2(8,-8.6),Vector2(25,-8.4),Vector2(38,-9.5),Vector2(45,-20),Vector2(49,-25)]},
	],
	"Halda Prewitt": [
		{"hour":6.5,"at":Vector2(13,-11),"range":2.0,"route":[Vector2(-12.5,32),Vector2(-8.5,16),Vector2(-5,8),Vector2(8,-8.6),Vector2(13,-11)]},
		{"hour":13.0,"at":Vector2(18,-8.5),"range":3.0,"route":[Vector2(13,-11),Vector2(18,-8.5)]},
		{"hour":18.0,"at":Vector2(-14.0,28),"range":1.8,"route":[Vector2(8,-8.6),Vector2(-5,8),Vector2(-8.5,16),Vector2(-12.5,32),Vector2(-14.0,28)]},
	],
	"Cob Ferris": [
		{"hour":5.0,"at":Vector2(-33.5,17.5),"range":2.8,"route":[]},
		{"hour":18.5,"at":Vector2(-8,4),"range":3.0,"route":[Vector2(-26.2,17),Vector2(-18,14),Vector2(-10,2),Vector2(-8,4)]},
		{"hour":21.0,"at":Vector2(-33.5,17.5),"range":2.0,"route":[Vector2(-10,2),Vector2(-18,14),Vector2(-26.2,17),Vector2(-33.5,17.5)]},
	],
	"Ivy Thorne": [
		{"hour":6.0,"at":Vector2(24.5,40.5),"range":2.0,"route":[]},
		{"hour":9.5,"at":Vector2(3.5,3.5),"range":4.0,"route":[Vector2(25.2,35.0),Vector2(25.6,31.5),Vector2(21,29),Vector2(10,15),Vector2(6,8),Vector2(3.5,3.5)]},
		{"hour":18.5,"at":Vector2(24.5,40.5),"range":2.0,"route":[Vector2(6,8),Vector2(10,15),Vector2(21,29),Vector2(25.6,31.5),Vector2(25.2,35.0),Vector2(24.5,40.5)]},
	],
	"Pip": [
		{"hour":5.5,"at":Vector2(73.5,-87.5),"range":2.6,"route":[Vector2(65,-83),Vector2(73.5,-87.5)]},
		{"hour":18.0,"at":Vector2(68,-86),"range":2.0,"route":[Vector2(73.5,-87.5),Vector2(68,-86)]},
	],
	"Tess": [
		{"hour":6.0,"at":Vector2(-21.5,-1.0),"range":2.0,"route":[Vector2(-12,-5),Vector2(-21.5,-1.0)]},
		{"hour":9.0,"at":Vector2(-8.0,-5.6),"range":1.6,"route":[Vector2(-12,-5),Vector2(-8.0,-5.6)]},
		{"hour":15.0,"at":Vector2(-21.5,-1.0),"range":2.0,"route":[Vector2(-12,-5),Vector2(-21.5,-1.0)]},
	],
	"Wick": [
		{"hour":6.0,"at":Vector2(-29.5,17.5),"range":2.6,"route":[]},
		{"hour":12.0,"at":Vector2(3.0,4.0),"range":3.5,"route":[Vector2(-18,14),Vector2(-10,2),Vector2(3,4)]},
		{"hour":16.0,"at":Vector2(-29.5,17.5),"range":2.6,"route":[Vector2(-10,2),Vector2(-18,14),Vector2(-29.5,17.5)]},
	],
}

# ---------------------------------------------------------------------------
# The water: a tarn in the northern hills, a long way off, and the mill on its race
# ---------------------------------------------------------------------------

## The tarn (see TerrainGenerator's TOWN_POND_*), the sawmill on its graded bench
## on the village's side of the leat with its wheel in the race on the north
## wall, the aqueduct's course from the weir to the lip of the fall, and the
## timber yard in front of the mill door. There is no bridge.
const POND_CENTER := Vector2(30,-142)
const POND_RADIUS := 17.5
const POND_WEIR_RADIUS := 17.3
const MILL_CENTER := Vector2(75,-95.2)
const WHEEL_SPOT := Vector2(79,-102.0)
## The leat runs down the terrace the mill stands on, turns east and goes over the
## rim at the point nearest the village. The mill is south of the east run, on
## the village's side of the water, its wheel on the north wall; no bridge.
const AQUEDUCT_COURSE: Array[Vector2] = [
	Vector2(47.5,-142), Vector2(55,-142.3), Vector2(61,-141.8), Vector2(66,-140.5),
	Vector2(70,-138.5), Vector2(72,-133), Vector2(72.4,-124), Vector2(72.6,-114),
	Vector2(72.9,-107), Vector2(74.6,-103.4), Vector2(78,-102.0), Vector2(83.2,-102.0),
]
## No footbridge: nothing needs to cross the leat.
const BRIDGE_SPOT := Vector2(9999,9999)
const HEADGATE_AT := Vector2(58.5,-142.1)
const TIMBER_RACKS: Array[Vector2] = [Vector2(70.0,-87.2),Vector2(80.0,-87.2)]
const LOG_PILES: Array[Dictionary] = [
	{"at":Vector2(66.0,-84.0),"yaw":1.5708,"rows":3},
]
const POND_TREES: Array[Dictionary] = [
	{"at":Vector2(6,-150),"h":5.0},{"at":Vector2(14,-123),"h":4.4},{"at":Vector2(41,-164),"h":5.3},
	{"at":Vector2(27,-167),"h":4.7},{"at":Vector2(22,-120),"h":4.9},{"at":Vector2(10,-166),"h":4.2},
]
