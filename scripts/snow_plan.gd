class_name SnowPlan
extends RefCounted

## The single authored plan of the Snow Village (Ice Kingdom). The generator
## builds only from this file and tools/validate_village.gd checks the result
## against it. Coordinates are village-local metres (x east, z south) from the
## terrain's village centre, which sits on a flat pad of radius 62 m.
##
## Layout (see docs/architecture/snow_village.md, sections 2a and 3): a Norse
## farm-hamlet (tun) grown into a small modern mountain town. An irregular ring
## of houses stands round an open common yard. The inn is the long hall on the
## north side of the yard. The lift base plaza lies at the pad's north-west
## corner, between Niko's workshop and Elin's hall, where the bunny run ends and
## the chair lift starts. The lake road leaves the yard's south-east corner for
## the fishing ground and the kingdom's arrival point, passing the fisher's
## yard; the boat and net house (naust) stands at its lower end.
##
## Building frame: the front wall (door) is local -Z. Yaw is in degrees: 0 faces
## north (-Z), 180 south, 90 west, -90 east. `cells` is (ridge length, depth) in
## 3.2 m cells.

const FOOTPRINT_CELL := 3.2

## Where the kingdom's snowboard route ends and the chair lift starts (mirrored
## in IceKingdomTerrain, which owns the heights).
const LIFT_LOWER := Vector2(-30.0, -56.0)
const BUNNY_RUNOUT := Vector2(-30.0, -40.0)

const YARD_CENTER := Vector2(10.0, -4.0)
const YARD_RADII := Vector2(19.0, 12.0)
## Solveig's winter-goods stall: the open sales face of the textile house, on the
## yard side of its north end, facing the yard.
const WINTER_STALL := Vector2(32.6,-7.8)
const PLAZA_CENTER := Vector2(-16.0, -43.0)
const PLAZA_RADII := Vector2(15.0, 7.5)

## name, at, yaw, cells, floors, kind, resident, program notes in `spec`.
## `kind` selects the interior and dressing in the generator.
const BUILDINGS: Array[Dictionary] = [
	{"name":"SnowrestInn","at":Vector2(12,-28),"yaw":180.0,"cells":Vector2(5,3),"floors":1,
		"kind":"inn","resident":"Astrid Snowrest","polite":true,"gallery":3.0,"bellcast":true,
		"door_x":4.0,"hearth":{"style":"peis","side":-1.0,"z":0.0},
		"hearth2":{"style":"kakelugn","side":1.0,"z":3.7},
		"passage_x":1.0,"service_door":{"wall":"east","x":2.3},
		"extra_openings":[{"wall":"back","x":6.4,"width":0.9,"bottom":1.0,"top":2.1,"kind":"window"}],"vault":true},
	{"name":"SnowrestInnWing","at":Vector2(14.5,-36),"yaw":180.0,"cells":Vector2(5,2),"floors":1,
		"kind":"inn_wing","resident":"Astrid Snowrest","attached_to":"SnowrestInn",
		"hearth":{"style":"kakelugn","side":1.0,"z":0.0},"passage_x":3.5,"flat_ceiling":true},
	{"name":"MountainRescueHall","at":Vector2(-14,-30),"yaw":-90.0,"cells":Vector2(4,3),"floors":2,
		"kind":"rescue","resident":"Elin","polite":true,"gallery":3.4,"bellcast":true,
		"door_x":0.0,"hearth":{"style":"peis","side":1.0,"z":0.0},"bell_frame":true},
	{"name":"LiftWorkshop","at":Vector2(-14,-54),"yaw":180.0,"cells":Vector2(4,3),"floors":1,
		"kind":"workshop","resident":"Niko","door_x":-2.2,"wide_door":2.8,
		"hearth":{"style":"kakelugn","side":1.0,"z":2.0},
		"lean_to":{"side":-1.0,"depth":3.0}},
	{"name":"TextileHouse","at":Vector2(40,-2),"yaw":90.0,"cells":Vector2(4,3),"floors":2,
		"kind":"textile","resident":"Mara","also":"Solveig Woolcap","door_x":3.2,
		"vestibule":2.4,"hearth":{"style":"kakelugn","side":1.0,"z":0.8}},
	{"name":"CommunalBathhouse","at":Vector2(48,-26),"yaw":90.0,"cells":Vector2(3,2),"floors":1,
		"kind":"bathhouse","resident":"communal","door_x":2.4,"vestibule":2.0,
		"hearth":{"style":"kiuas","side":-1.0,"z":0.0}},
	{"name":"WardenHouse","at":Vector2(46,30),"yaw":90.0,"cells":Vector2(4,2),"floors":1,
		"kind":"warden","resident":"Tomas","also":"Soren","door_x":-2.4,"vestibule":2.2,
		"hearth":{"style":"kakelugn","side":-1.0,"z":0.0}},
	{"name":"IceHouse","at":Vector2(46,20.4),"yaw":90.0,"cells":Vector2(2,2),"floors":1,
		"kind":"icehouse","resident":"Soren","attached_to":"WardenHouse","turf":true},
	{"name":"FisherHome","at":Vector2(24,40),"yaw":-90.0,"cells":Vector2(3,2),"floors":1,
		"kind":"fisher","resident":"Ivar","also":"Freya","door_x":0.0,"vestibule":2.2,
		"hearth":{"style":"kakelugn","side":-1.0,"z":0.0}},
	{"name":"Smokehouse","at":Vector2(24,52.5),"yaw":-90.0,"cells":Vector2(2,2),"floors":1,
		"kind":"smokehouse","resident":"Freya"},
	{"name":"NetShed","at":Vector2(36,52),"yaw":0.0,"cells":Vector2(3,2),"floors":1,
		"kind":"naust","resident":"Ivar"},
	{"name":"ForesterHome","at":Vector2(-28,28),"yaw":-90.0,"cells":Vector2(3,2),"floors":1,
		"kind":"forester","resident":"Anja","door_x":0.0,"vestibule":2.2,
		"hearth":{"style":"kakelugn","side":1.0,"z":0.0}},
	{"name":"VillageStabbur","at":Vector2(-12,10),"yaw":-90.0,"cells":Vector2(2,2),"floors":1,
		"kind":"stabbur","resident":"Astrid Snowrest","also":"Elin","raised":true},
	{"name":"CommunalWoodStore","at":Vector2(32,-39),"yaw":180.0,"cells":Vector2(3,1),"floors":1,
		"kind":"woodstore","resident":"Anja","open_front":true},
]

## The trade ledger (see OhioPlan.TRADE): Solveig's frontage is the open sales
## face of the textile house, and the provisions on it come from named hands.
const TRADE := {
	"Solveig Woolcap": {"category":"snow","stall":"winter","goods":{
		"Toboggan":{"from":"Solveig Woolcap, knitted at the textile house","at":"TextileHouse","carried_by":""},
		"Rye Loaf":{"from":"Astrid Snowrest, baked in the inn kitchen","at":"SnowrestInn","carried_by":"Freya"},
		"Dried Berries":{"from":"Anja, gathered at the pine edge and dried at her home","at":"ForesterHome","carried_by":"Anja"},
	}},
}

## Yard furniture and landmarks (kind, at, size or yaw). All are solids for the
## validator, and the sightline from the lake road into the yard must stay open.
const YARD_FEATURES: Array[Dictionary] = [
	{"name":"CommunalHearth","kind":"communal_hearth","at":Vector2(10.0,3.2),"radius":3.8},
	{"name":"YardCistern","kind":"cistern","at":Vector2(-2.0,4.5),"radius":1.0},
	{"name":"WeatherMast","kind":"mast","at":Vector2(-6.2,-21.0),"height":6.0},
]

## Lamp standards, in the order they are met walking from the plaza to the yard
## and out along the lake road.
const LAMPS: Array[Vector2] = [
	Vector2(-24.0,-46.5), Vector2(-5.5,-40.0), Vector2(-2.0,-30.0), Vector2(-1.0,-18.0),
	Vector2(22.0,-17.0), Vector2(32.0,6.0), Vector2(36.5,24.0), Vector2(41.0,40.0),
	Vector2(-22.0,12.0), Vector2(30.0,-20.0),
]

## Ways: name, width, points. Worn light earth under trodden snow. Every way
## ends at a door, gate, yard or plaza.
const WAYS: Array[Dictionary] = [
	{"name":"LiftLane","width":3.6,"points":[Vector2(-20,-38),Vector2(-9,-36.5),Vector2(-3.4,-28),Vector2(-2.4,-18),Vector2(2,-10)]},
	{"name":"WorkshopApron","width":3.0,"points":[Vector2(-20,-47),Vector2(-16.2,-47.6),Vector2(-12.2,-48.4)]},
	{"name":"BunnyRunout","width":6.0,"points":[Vector2(-29,-40),Vector2(-24,-40.5),Vector2(-14,-41)]},
	{"name":"HallApron","width":3.0,"points":[Vector2(-6.5,-30),Vector2(-4.4,-29.2),Vector2(-3.4,-28)]},
	{"name":"InnApron","width":3.4,"points":[Vector2(8,-22.4),Vector2(9,-16),Vector2(10,-9)]},
	{"name":"InnWestService","width":2.6,"points":[Vector2(3.2,-30.3),Vector2(-1,-29.4),Vector2(-3.4,-28)]},
	{"name":"InnEastApron","width":2.6,"points":[Vector2(22,-12),Vector2(21.5,-18),Vector2(20,-22.4)]},
	{"name":"InnEastLane","width":2.6,"points":[Vector2(19,-22.6),Vector2(30,-24.5),Vector2(38,-26),Vector2(43.6,-28.3)]},
	{"name":"WoodLane","width":2.4,"points":[Vector2(32,-36),Vector2(37,-31),Vector2(39.4,-26.7)]},
	{"name":"EastLane","width":3.0,"points":[Vector2(26,-3),Vector2(30,-4.2),Vector2(34.0,-5.2)]},
	{"name":"LakeRoad","width":3.4,"points":[Vector2(20,6),Vector2(26,14),Vector2(30,24),Vector2(34,34),Vector2(42,44),Vector2(60,58),Vector2(84,70),Vector2(102,82)]},
	{"name":"WardenLane","width":2.4,"points":[Vector2(36,35.5),Vector2(39,33.4),Vector2(42.2,32.4)]},
	{"name":"IceHouseLane","width":2.2,"points":[Vector2(29,21.4),Vector2(35,20.8),Vector2(42.2,20.4)]},
	{"name":"FisherLane","width":2.6,"points":[Vector2(38.8,40),Vector2(33,40),Vector2(27.6,40)]},
	{"name":"NetShedLane","width":2.6,"points":[Vector2(41,45),Vector2(37.4,48),Vector2(36,48.4)]},
	{"name":"SmokeLane","width":2.2,"points":[Vector2(30,40.4),Vector2(28.8,46),Vector2(27.6,52.5)]},
	{"name":"StabburLane","width":2.4,"points":[Vector2(-1,5),Vector2(-6,8.4),Vector2(-8.2,10)]},
	{"name":"ForesterLane","width":2.6,"points":[Vector2(0,6),Vector2(-12,18),Vector2(-20,26),Vector2(-24.2,28)]},
	{"name":"TextilePlotLane","width":2.2,"points":[Vector2(28,17),Vector2(36,12),Vector2(42,8.6),Vector2(45.7,5.6)]},
	{"name":"WoodYardLane","width":2.4,"points":[Vector2(-22.6,29.5),Vector2(-22.8,34.5),Vector2(-30,37.2),Vector2(-37.5,36.6)]},
	{"name":"YardCrossing","width":3.0,"points":[Vector2(2,-10),Vector2(8,-6),Vector2(16,-1),Vector2(26,-3)]},
]

## Where each walking resident keeps to: a spot at their own door or workplace
## and how far they drift from it. Astrid (the inn's keeper), Solveig (at her
## stall) and Ivar (at the fishing hole) stay where they work, so they have no
## timetable.
const HOMES := {
	"Elin": {"at":Vector2(-6.5,-30.0), "range":2.0},
	"Niko": {"at":Vector2(-11.8,-48.4), "range":2.2},
	"Anja": {"at":Vector2(-23.0,28.0), "range":2.0},
	"Mara": {"at":Vector2(32.5,-5.2), "range":2.0},
	"Tomas": {"at":Vector2(41.0,32.4), "range":2.0},
	"Soren": {"at":Vector2(41.2,20.4), "range":1.8},
	"Freya": {"at":Vector2(29.0,52.0), "range":1.6},
}

## A small timetable each. Every route runs along the same ways as WAYS, from the
## previous stop; the validator fails any segment that cuts through a building.
const DAILY_SCHEDULES := {
	"Elin": [
		{"hour":6.0,"at":Vector2(-4.4,-20.5),"range":1.5,"route":[Vector2(-4.4,-29.2),Vector2(-3.4,-26),Vector2(-2.6,-21),Vector2(-4.4,-20.5)]},
		{"hour":8.0,"at":Vector2(-6.5,-30.0),"range":2.0,"route":[Vector2(-2.6,-21),Vector2(-3.4,-26),Vector2(-4.4,-29.2),Vector2(-6.5,-30.0)]},
		{"hour":12.0,"at":Vector2(8.2,-1.5),"range":2.2,"route":[Vector2(-4.4,-29.2),Vector2(-3.4,-26),Vector2(-2.4,-18),Vector2(2,-10),Vector2(8.2,-1.5)]},
		{"hour":13.5,"at":Vector2(-6.5,-30.0),"range":2.0,"route":[Vector2(2,-10),Vector2(-2.4,-18),Vector2(-3.4,-26),Vector2(-4.4,-29.2),Vector2(-6.5,-30.0)]},
		{"hour":19.0,"at":Vector2(14.5,3.0),"range":2.0,"route":[Vector2(-4.4,-29.2),Vector2(-3.4,-26),Vector2(-2.4,-18),Vector2(2,-10),Vector2(8,-8.5),Vector2(14.5,3.0)]},
		{"hour":21.5,"at":Vector2(-6.5,-30.0),"range":1.8,"route":[Vector2(8,-8.5),Vector2(2,-10),Vector2(-2.4,-18),Vector2(-3.4,-26),Vector2(-4.4,-29.2),Vector2(-6.5,-30.0)]},
	],
	"Niko": [
		{"hour":6.5,"at":Vector2(-11.8,-48.4),"range":2.2,"route":[]},
		{"hour":8.0,"at":Vector2(-24.0,-47.6),"range":2.0,"route":[Vector2(-16.2,-47.6),Vector2(-20,-47),Vector2(-24.0,-47.6)]},
		{"hour":12.0,"at":Vector2(8.0,-20.4),"range":1.6,"route":[Vector2(-14,-44),Vector2(-9,-36.5),Vector2(-3.4,-28),Vector2(-2.4,-18),Vector2(2,-10),Vector2(10,-9),Vector2(9,-16),Vector2(8.0,-20.4)]},
		{"hour":13.5,"at":Vector2(-11.8,-48.4),"range":2.2,"route":[Vector2(9,-16),Vector2(10,-9),Vector2(2,-10),Vector2(-2.4,-18),Vector2(-3.4,-28),Vector2(-9,-36.5),Vector2(-14,-44),Vector2(-11.8,-48.4)]},
	],
	"Anja": [
		{"hour":5.5,"at":Vector2(-23.0,28.0),"range":2.0,"route":[]},
		{"hour":8.0,"at":Vector2(32.0,-35.4),"range":1.8,"route":[Vector2(-20,26),Vector2(-12,18),Vector2(0,6),Vector2(10,-4),Vector2(22.5,-14),Vector2(24,-21.5),Vector2(28,-24.2),Vector2(37,-31),Vector2(32.0,-35.4)]},
		{"hour":15.0,"at":Vector2(-23.0,28.0),"range":2.0,"route":[Vector2(37,-31),Vector2(28,-24.2),Vector2(24,-21.5),Vector2(22.5,-14),Vector2(10,-4),Vector2(0,6),Vector2(-12,18),Vector2(-20,26),Vector2(-23.0,28.0)]},
		{"hour":19.0,"at":Vector2(20.0,-1.0),"range":2.0,"route":[Vector2(-20,26),Vector2(-12,18),Vector2(0,6),Vector2(10,2),Vector2(20.0,-1.0)]},
		{"hour":21.0,"at":Vector2(-23.0,28.0),"range":2.0,"route":[Vector2(10,2),Vector2(0,6),Vector2(-12,18),Vector2(-20,26),Vector2(-23.0,28.0)]},
	],
	"Mara": [
		{"hour":6.5,"at":Vector2(32.5,-5.2),"range":2.0,"route":[]},
		{"hour":12.0,"at":Vector2(8.0,-20.4),"range":1.6,"route":[Vector2(30,-4.2),Vector2(26,-3),Vector2(20,-3.5),Vector2(14,-9),Vector2(10,-9),Vector2(9,-16),Vector2(8.0,-20.4)]},
		{"hour":15.0,"at":Vector2(-11.8,-48.4),"range":2.0,"route":[Vector2(9,-16),Vector2(10,-9),Vector2(2,-10),Vector2(-2.4,-18),Vector2(-3.4,-28),Vector2(-9,-36.5),Vector2(-14,-44),Vector2(-11.8,-48.4)]},
		{"hour":17.0,"at":Vector2(32.5,-5.2),"range":2.0,"route":[Vector2(-14,-44),Vector2(-9,-36.5),Vector2(-3.4,-28),Vector2(-2.4,-18),Vector2(2,-10),Vector2(10,-4),Vector2(20,-3.5),Vector2(26,-3),Vector2(30,-4.2),Vector2(32.5,-5.2)]},
		{"hour":19.5,"at":Vector2(42.0,-28.4),"range":1.6,"route":[Vector2(30,-4.2),Vector2(26,-3),Vector2(22,-12),Vector2(19,-22.6),Vector2(30,-24.5),Vector2(38,-26),Vector2(42.0,-28.4)]},
	],
	"Tomas": [
		{"hour":5.5,"at":Vector2(41.0,32.4),"range":2.0,"route":[]},
		{"hour":7.0,"at":Vector2(60.0,58.0),"range":2.0,"route":[Vector2(39,33.4),Vector2(36,35.5),Vector2(37.6,38.5),Vector2(42,44),Vector2(51,51),Vector2(60.0,58.0)]},
		{"hour":12.0,"at":Vector2(-6.5,-30.0),"range":2.0,"route":[Vector2(51,51),Vector2(42,44),Vector2(37.6,38.5),Vector2(34,34),Vector2(30,24),Vector2(26,14),Vector2(20,6),Vector2(10,-4),Vector2(2,-10),Vector2(-2.4,-18),Vector2(-3.4,-28),Vector2(-4.4,-29.2),Vector2(-6.5,-30.0)]},
		{"hour":15.0,"at":Vector2(41.0,32.4),"range":2.0,"route":[Vector2(-4.4,-29.2),Vector2(-3.4,-28),Vector2(-2.4,-18),Vector2(2,-10),Vector2(10,-4),Vector2(20,6),Vector2(26,14),Vector2(30,24),Vector2(34,34),Vector2(36,35.5),Vector2(39,33.4),Vector2(41.0,32.4)]},
		{"hour":19.0,"at":Vector2(16.0,3.0),"range":2.0,"route":[Vector2(36,35.5),Vector2(34,34),Vector2(30,24),Vector2(26,14),Vector2(20,6),Vector2(16.0,3.0)]},
		{"hour":21.0,"at":Vector2(41.0,32.4),"range":2.0,"route":[Vector2(20,6),Vector2(26,14),Vector2(30,24),Vector2(34,34),Vector2(36,35.5),Vector2(39,33.4),Vector2(41.0,32.4)]},
	],
	"Soren": [
		{"hour":6.0,"at":Vector2(41.2,20.4),"range":1.8,"route":[]},
		{"hour":9.0,"at":Vector2(84.0,70.0),"range":2.5,"route":[Vector2(35,20.8),Vector2(29,21.4),Vector2(30,24),Vector2(34,34),Vector2(42,44),Vector2(60,58),Vector2(84.0,70.0)]},
		{"hour":15.0,"at":Vector2(41.2,20.4),"range":1.8,"route":[Vector2(60,58),Vector2(42,44),Vector2(34,34),Vector2(30,24),Vector2(29,21.4),Vector2(35,20.8),Vector2(41.2,20.4)]},
		{"hour":19.0,"at":Vector2(18.5,-1.0),"range":2.0,"route":[Vector2(35,20.8),Vector2(29,21.4),Vector2(26,14),Vector2(20,6),Vector2(18.5,-1.0)]},
		{"hour":21.0,"at":Vector2(41.2,20.4),"range":1.8,"route":[Vector2(20,6),Vector2(26,14),Vector2(29,21.4),Vector2(35,20.8),Vector2(41.2,20.4)]},
	],
	"Freya": [
		{"hour":5.0,"at":Vector2(29.0,52.0),"range":1.6,"route":[]},
		{"hour":6.5,"at":Vector2(3.2,-30.3),"range":1.4,"route":[Vector2(28.8,46),Vector2(30,40.4),Vector2(36,38),Vector2(34,34),Vector2(30,24),Vector2(26,14),Vector2(20,6),Vector2(10,-4),Vector2(2,-10),Vector2(-2.4,-18),Vector2(-3.4,-28),Vector2(-1,-29.4),Vector2(3.2,-30.3)]},
		{"hour":7.5,"at":Vector2(29.6,-5.0),"range":1.2,"route":[Vector2(-1,-29.4),Vector2(-3.4,-28),Vector2(-2.4,-18),Vector2(2,-10),Vector2(10,-4),Vector2(20,-3.5),Vector2(26,-3),Vector2(29.6,-5.0)]},
		{"hour":10.0,"at":Vector2(29.0,40.0),"range":2.0,"route":[Vector2(26,-3),Vector2(20,6),Vector2(26,14),Vector2(30,24),Vector2(34,34),Vector2(36,38),Vector2(33,40),Vector2(29.0,40.0)]},
		{"hour":14.0,"at":Vector2(37.4,47.6),"range":2.0,"route":[Vector2(33,40),Vector2(38.8,40),Vector2(41,45),Vector2(37.4,47.6)]},
		{"hour":19.0,"at":Vector2(15.5,3.5),"range":2.0,"route":[Vector2(41,45),Vector2(34,34),Vector2(30,24),Vector2(26,14),Vector2(20,6),Vector2(15.5,3.5)]},
		{"hour":21.0,"at":Vector2(29.0,52.0),"range":1.6,"route":[Vector2(20,6),Vector2(26,14),Vector2(30,24),Vector2(34,34),Vector2(36,38),Vector2(30,40.4),Vector2(28.8,46),Vector2(29.0,52.0)]},
	],
}

## Grounds. Every plot has a job and a tender, and abuts the house it serves (the
## house wall is that side of the enclosure; the gate faces the lane that serves
## it). Rects are village-local (x, z, width, depth). `board_sides` are the sides
## clad as a solid windbreak (west and north face the weather).
const PLOTS: Array[Dictionary] = [
	{"name":"TextilePlot","tender":"Mara and Solveig","job":"winter greens for the house table",
		"rect":Rect2(44.8,-7.0,8.2,10.5),"abuts":"west","board_sides":["east","north"],
		"gate":{"side":"south","at":45.7},
		"beds":[
			{"kind":"frame","at":Vector2(49.0,-5.0),"size":Vector2(4.8,1.3)},
			{"kind":"leeks","at":Vector2(49.0,-2.2),"size":Vector2(4.8,1.3)},
			{"kind":"kale","at":Vector2(49.0,0.6),"size":Vector2(4.8,1.3)},
		],
		"barrel":Vector2(52.0,-6.0),"compost":Vector2(52.0,2.4)},
	{"name":"ForesterYard","tender":"Anja","job":"wood yard, cold frames and the drying of berries",
		"rect":Rect2(-42.0,21.5,10.8,13.0),"abuts":"east","board_sides":["west","north"],
		"gate":{"side":"south","at":-37.5},
		"beds":[
			{"kind":"frame","at":Vector2(-37.0,24.4),"size":Vector2(4.4,1.2)},
			{"kind":"kale","at":Vector2(-37.0,27.0),"size":Vector2(4.4,1.2)},
		],
		"barrel":Vector2(-33.4,22.8),"compost":Vector2(-40.6,23.0),
		"stacks":[Vector3(-40.7,28.6,PI*0.5),Vector3(-40.7,31.4,PI*0.5),Vector3(-35.2,33.0,0.0)],
		"block":Vector2(-37.8,30.6),"sawhorse":Vector2(-35.4,30.4)},
]

## Firewood on blank walls, as a facade pattern: building, wall, x along the wall,
## stack length, rows. Never across a door or under a window pair.
const WOODPILES: Array[Dictionary] = [
	{"building":"WardenHouse","wall":"back","x":1.6,"length":2.4,"rows":4},
	{"building":"FisherHome","wall":"back","x":2.4,"length":2.2,"rows":4},
	{"building":"Smokehouse","wall":"back","x":0.0,"length":1.8,"rows":3},
	{"building":"SnowrestInnWing","wall":"back","x":-1.6,"length":1.6,"rows":4},
	{"building":"SnowrestInnWing","wall":"back","x":4.8,"length":1.6,"rows":4},
	{"building":"MountainRescueHall","wall":"back","x":0.0,"length":2.6,"rows":4},
]

## Blobs of worn ground that tell use: mud at the cistern, wood chips in Anja's
## yard, and the snow-cleared communal hearth court.
const WEAR_BLOBS: Array[Dictionary] = [
	{"center":Vector2(-2.0,4.5),"radii":Vector2(3.2,2.8)},
	{"center":Vector2(-37.8,30.6),"radii":Vector2(4.6,3.0)},
	{"center":Vector2(10.0,3.2),"radii":Vector2(4.6,4.2)},
]

## Pine groves: (centre, radius, count). Groves stand west and north of the
## settlement and behind the east lanes, in irregular clumps with open snow
## between them (never a continuous belt, and never on a way or near a wall).
const PINE_GROVES: Array[Dictionary] = [
	{"center":Vector2(-14,-68),"radius":7.0,"count":5},
	{"center":Vector2(-46,-8),"radius":9.0,"count":7},
	{"center":Vector2(-40,38),"radius":8.0,"count":6},
	{"center":Vector2(12,-56),"radius":8.0,"count":5},
	{"center":Vector2(60,-14),"radius":8.0,"count":5},
	{"center":Vector2(58,8),"radius":5.0,"count":3},
	{"center":Vector2(8,60),"radius":8.0,"count":4},
]
