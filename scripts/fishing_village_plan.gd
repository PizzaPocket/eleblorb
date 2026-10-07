class_name FishingVillagePlan
extends RefCounted

## The one authored layout of the Crossroads Fishing Village. The village
## builder consumes these numbers and tools/validate_fishing_plan.gd checks them,
## so a structure, route, lane or berth is moved here and nowhere else. The
## reasons live in docs/architecture/fishing_village_layout.md (the sections
## cited below) and the census in fishing_village.md.
##
## Local metres: origin is world (440, 0), +X east (away from the shore), +Z
## "south". Heights are relative to the lake surface W, which the terrain owns
## (get_lake_water_level()); nothing here copies its absolute value.

const WORLD_CENTER := Vector2(440.0, 0.0)

# ---------------------------------------------------------------------------
# Heights (layout section 7), relative to W
# ---------------------------------------------------------------------------

const DECK_TOP := 0.50
const HOUSE_FLOOR := 0.75
const FLOAT_DECK := 0.35
const SHELF_DEPTH_MIN := 2.5
const SHELF_DEPTH_MAX := 4.0
const MIN_HEADROOM := 3.2
const MAX_GANGWAY_DEGREES := 8.0
## The grade of the existing swim ramps (1.95 m over 8 m), the steepest allowed.
const MAX_RAMP_GRADE := 1.95 / 8.0
const EXIT_WIDTH := 3.4
const EXIT_CLEAR_WATER := 8.0
const PORTAL_CLEAR_BEHIND := 3.0

# ---------------------------------------------------------------------------
# Islets and shelves (section 2). Shelf rectangles are [x0, x1, z0, z1]; piles
# stand only inside them. Rock bodies are ellipses (centre, semi-axes).
# ---------------------------------------------------------------------------

const ANVIL_ROCK := {"center":Vector2(-4.0,-30.0),"half":Vector2(18.0,10.0),"crown":34.0}
const HERON_ROCK := {"center":Vector2(30.0,10.0),"half":Vector2(6.0,5.0),"crown":21.0}
## Both rocks rise from their shelves; the Heron shelf is a disc round the rock.
## The layout brief says 14 m, but its own Vale house, catch deck, portal landing
## and Heron landing reach 15 to 18 m from the rock's centre; 18 m carries them.
const HERON_SHELF_RADIUS := 18.0
const SHELF_RECTS: Array[Rect2] = [
	Rect2(-30.0,-22.0,46.0,28.0),   # Anvil south shelf, x -30..16, z -22..+6
	Rect2(-46.0,-22.0,16.0,26.0),   # arrival foot, x -46..-30, z -22..+4
	Rect2(-22.0,-40.0,36.0,20.0),   # the shoulder under Anvil Rock itself
	Rect2(12.0,-9.0,10.0,11.0),     # the saddle joining the two shelves, where the spine crosses
]

# ---------------------------------------------------------------------------
# Residents (fifteen, five households, from fishing_village.md)
# ---------------------------------------------------------------------------

const RESIDENTS := {
	"Nara":"Venn", "Mateo":"Venn", "Lio":"Venn",
	"Mai":"Aran", "Salim":"Aran", "Dala":"Aran", "Pree":"Aran",
	"Jori":"Vale", "Osei":"Vale", "Tavi":"Vale",
	"Leena":"Mor", "Ivo":"Mor", "Sela":"Mor",
	"Asha":"Sen", "Rian":"Sen",
}

# ---------------------------------------------------------------------------
# Structures (section 4). Keys: name, kind (how the builder dresses it), program, owner (a resident, or "village"),
# rect [x0, x1, z0, z1], support (piles | floating | lines | slip).
# ---------------------------------------------------------------------------

const STRUCTURES: Array[Dictionary] = [
	{"name":"ArrivalLanding","kind":"deck","program":"landing and market deck","owner":"Nara","rect":Rect2(-42.0,-12.0,14.0,14.0),"support":"piles"},
	# The house, its shop veranda and the 1 m threshold ramp down to the landing's
	# deck at z -12 (the footprint used to stop 1 m short of the landing).
	{"name":"VennHouse","kind":"house","program":"house and lake shop","owner":"Nara","rect":Rect2(-34.0,-20.0,9.0,8.0),"support":"piles"},
	{"name":"BoatwrightSlip","kind":"deck","program":"slip, timber rack and tool shelter","owner":"Mateo","rect":Rect2(-46.0,-22.0,6.0,9.0),"support":"slip"},
	{"name":"SenHouse","kind":"house","program":"house, clinic and school room","owner":"Asha","rect":Rect2(-20.0,-20.0,9.0,10.0),"support":"piles"},
	{"name":"ShellBarge","kind":"barge","program":"shell cutting and sealing barge","owner":"Rian","rect":Rect2(-20.0,-3.0,8.0,3.5),"support":"floating"},
	{"name":"CisternHouse","kind":"house","program":"cistern and shared stores","owner":"Leena","rect":Rect2(-6.0,-20.0,8.0,8.0),"support":"piles"},
	{"name":"NetShed","kind":"house","program":"net shed and gear loft","owner":"Salim","rect":Rect2(4.0,-20.0,8.0,8.0),"support":"piles"},
	{"name":"Pavilion","kind":"pavilion","program":"communal pavilion","owner":"Leena","rect":Rect2(-8.0,-4.0,12.0,8.0),"support":"piles"},
	{"name":"AranHouse","kind":"house","program":"house and weather watch","owner":"Dala","rect":Rect2(6.0,-3.0,8.0,8.0),"support":"piles"},
	{"name":"PearlYard","kind":"pontoon","program":"pearl and shell grading yard","owner":"Mai","rect":Rect2(6.0,5.0,10.0,5.0),"support":"floating"},
	{"name":"MusselLines","kind":"lines","program":"mussel basket lines","owner":"Mai","rect":Rect2(6.0,14.0,10.0,16.0),"support":"lines"},
	{"name":"ValeHouseboat","kind":"houseboat","program":"family houseboat and boat watch","owner":"Jori","rect":Rect2(26.0,-10.0,14.0,7.0),"support":"floating"},
	{"name":"CatchDeck","kind":"deck_shelter","program":"catch deck, drying shelter and smokehouse","owner":"Osei","rect":Rect2(36.0,2.0,8.0,12.0),"support":"piles"},
	{"name":"MorHouseboat","kind":"houseboat","program":"guest houseboat and rest point","owner":"Leena","rect":Rect2(-26.0,8.0,18.0,7.0),"support":"floating"},
	{"name":"PortalLanding","kind":"deck","program":"Ocean portal landing","owner":"village","rect":Rect2(26.0,16.0,9.0,8.0),"support":"piles"},
	{"name":"HeronLanding","kind":"deck","program":"jetty end and boat watch","owner":"village","rect":Rect2(18.0,-3.0,6.0,6.0),"support":"piles"},
]

## Pairs that touch by design (a house and its own deck, a deck and its slip).
const ATTACHED := [
	["AranHouse","PearlYard"], ["ArrivalLanding","VennHouse"],
	["Pavilion","MorHouseboat"],
]

# ---------------------------------------------------------------------------
# Routes (section 5). Width classes: spine 3.6, return 3.0, spur 2.4, gangway 2.6.
# Keys: name, class, width, points, ends (structures the route may enter).
# ---------------------------------------------------------------------------

const CLASS_MIN_WIDTH := {"spine":3.6,"return":3.0,"spur":2.4,"gangway":2.6}

const ROUTES: Array[Dictionary] = [
	{"name":"JettySpine","class":"spine","width":3.6,"ends":["ArrivalLanding","HeronLanding"],
		"points":[Vector2(-28,-6),Vector2(-10,-7),Vector2(6,-8),Vector2(16,-6),Vector2(21,0)]},
	{"name":"PavilionReturn","class":"return","width":3.0,"ends":["Pavilion","ArrivalLanding"],
		"points":[Vector2(-8,2),Vector2(-20,4),Vector2(-28,2)]},
	{"name":"PortalSpur","class":"spur","width":2.4,"ends":["HeronLanding","PortalLanding"],
		"points":[Vector2(21,3),Vector2(20,10),Vector2(23,17),Vector2(27,19)]},
	# The pavilion's principal approach, on the cistern's line: water to the
	# north of the spine, the meeting place to the south (layout section 3).
	{"name":"PavilionSpur","class":"return","width":3.6,"ends":["Pavilion"],"points":[Vector2(-2,-7),Vector2(-2,-4)]},
	{"name":"SenSpur","class":"spur","width":2.4,"ends":["SenHouse"],"points":[Vector2(-15,-7),Vector2(-15,-10)]},
	{"name":"CisternSpur","class":"spur","width":2.4,"ends":["CisternHouse"],"points":[Vector2(-2,-7),Vector2(-2,-12)]},
	{"name":"NetShedSpur","class":"spur","width":2.4,"ends":["NetShed"],"points":[Vector2(8,-7),Vector2(8,-12)]},
	# On the line of the Aran threshold ramp (x 6..8), which climbs to the
	# veranda's north end (its deck tucks under the ramp's foot); on x 8 it ran
	# into the house's corner.
	{"name":"AranSpur","class":"spur","width":2.4,"ends":["AranHouse"],"points":[Vector2(7,-7.6),Vector2(7,-3.5)]},
	{"name":"ValeGangway","class":"gangway","width":2.6,"ends":["HeronLanding","ValeHouseboat"],
		"points":[Vector2(24,-2),Vector2(27,-5)],"rise":DECK_TOP - FLOAT_DECK},
	{"name":"CatchGangway","class":"gangway","width":2.6,"ends":["ValeHouseboat","CatchDeck"],
		"points":[Vector2(38,-3),Vector2(38,2)],"rise":DECK_TOP - FLOAT_DECK},
	{"name":"ShellBargeGangway","class":"gangway","width":2.6,"ends":["JettySpine","ShellBarge"],
		"points":[Vector2(-15,-5),Vector2(-15,-3)],"rise":DECK_TOP - FLOAT_DECK},
	# Lands in the middle of the Mor houseboat's covered arrival deck (it used to
	# land on the line between that deck and the common cabin).
	{"name":"HouseboatGangway","class":"gangway","width":2.6,"ends":["PavilionReturn","MorHouseboat"],
		"points":[Vector2(-23.5,3.6),Vector2(-23.5,8)],"rise":DECK_TOP - FLOAT_DECK},
]

# ---------------------------------------------------------------------------
# Lanes (section 6): open water. Keys: name, width, points.
# ---------------------------------------------------------------------------

const LANES: Array[Dictionary] = [
	{"name":"ferry","width":8.0,"points":[Vector2(-42,-4),Vector2(-90,-4)]},
	{"name":"slip","width":6.0,"points":[Vector2(-46,-17),Vector2(-80,-17)]},
	{"name":"court_mouth","width":10.0,"points":[Vector2(-1,8),Vector2(-1,60)]},
	{"name":"working_boat","width":10.0,"points":[Vector2(44,8),Vector2(100,8)]},
	{"name":"paddle_run","width":2.4,"points":[Vector2(17.4,7),Vector2(17.4,13)]},
	{"name":"rescue","width":8.0,"points":[Vector2(-12,15),Vector2(-12,60)]},
]

## Boats: owner, berth (centre and half-size of the hull's water footprint) and
## the lane each approaches by. The houseboat is a structure, not listed here.
const BOATS: Array[Dictionary] = [
	{"name":"DiveSkiff","owner":"Nara","berth":Rect2(-46.0,-9.7,4.0,1.4),"lane":"ferry"},
	{"name":"FerryBoat","launch":true,"owner":"Ivo","berth":Rect2(-48.0,-3.8,6.0,1.8),"lane":"ferry"},
	# Afloat at the slipway's foot in the slip lane (its berth used to overlap the
	# slip's work apron).
	{"name":"RepairBoat","owner":"Mateo","berth":Rect2(-53.0,-16.9,5.0,1.8),"lane":"slip"},
	{"name":"WorkPunt","owner":"Mai","berth":Rect2(2.0,6.2,3.6,1.6),"lane":"court_mouth"},
	{"name":"WorkingBoat","owner":"Jori","berth":Rect2(44.0,6.8,6.0,2.4),"lane":"working_boat"},
	{"name":"UtilityBoat","owner":"Sela","berth":Rect2(-15.0,16.0,5.0,2.0),"lane":"rescue"},
	{"name":"PaddleSkiff","owner":"Salim","berth":Rect2(16.3,6.0,2.4,1.0),"lane":"paddle_run"},
]

# ---------------------------------------------------------------------------
# Swim exits (section 6): three public exits, derived heights, never copied.
# Keys: name, deck (structure), x0, x1, edge_z (the deck's south edge).
# ---------------------------------------------------------------------------

const SWIM_EXITS: Array[Dictionary] = [
	{"name":"Exit1","deck":"ArrivalLanding","x0":-38.0,"x1":-34.6,"edge_z":2.0},
	{"name":"Exit2","deck":"Pavilion","x0":-3.7,"x1":-0.3,"edge_z":4.0},
	{"name":"Exit3","deck":"PortalLanding","x0":28.0,"x1":31.4,"edge_z":24.0},
]

## Where a swimmer at head height `head_base` floats: the exit's lower end sits
## at W minus that float depth minus a hand's width (section 6).
static func exit_lower_end(head_base: float) -> float:
	return -LiquidEnvironment.float_depth(head_base) - 0.10


## Run needed to descend from the deck to the lower end at no more than the
## existing ramps' grade, rounded up to the half metre.
static func exit_run(head_base: float) -> float:
	return ceilf((DECK_TOP - exit_lower_end(head_base)) / MAX_RAMP_GRADE * 2.0) / 2.0


## The Ocean portal gate (section 9): faces north-west, 3 m clear behind it.
const PORTAL_GATE := {"at":Vector2(30.0,20.0),"facing":Vector2(-1.0,-1.0)}

## Panel colours per household, keeping the draft village's varied teal, ochre,
## coral, violet, terracotta and green range, as the design briefs assign them:
## Venn teal, Aran ochre, Vale coral red, Mor terracotta, Sen violet; shared
## structures are natural timber with green ridges and trim.
const HOUSEHOLD_COLORS := {
	"Venn":Color(0.24,0.55,0.52), "Aran":Color(0.82,0.58,0.22), "Vale":Color(0.76,0.30,0.28),
	"Mor":Color(0.72,0.42,0.22), "Sen":Color(0.48,0.38,0.66), "village":Color(0.32,0.52,0.30),
}


## The household an owner belongs to, or "village" for shared structures.
static func household_of(owner: String) -> String:
	return str(RESIDENTS.get(owner, "village"))

## Pairs that must never touch or share a deck (section 8), and the least gap.
const SEPARATED := [["PearlYard","CatchDeck"], ["CatchDeck","Pavilion"], ["CatchDeck","MorHouseboat"]]
const SEPARATION_GAP := 6.0

## Protected bounds: no hostile encounters inside this radius of the origin.
const PROTECTED_RADIUS := 70.0

# ---------------------------------------------------------------------------
# Trade ledger (fishing_village.md, "the current lake assortment"): every
# stocked item names a maker, where it is made and who carries it.
# ---------------------------------------------------------------------------

const TRADE := {
	"Nara Venn": {"category":"lake","stall":"lake","goods":{
		"Diving Helmet":{"from":"Mateo builds the housing, Rian seals it, Nara tests it","at":"VennHouse","carried_by":""},
		"Corroded Pocket Compass":{"from":"Ivo trades for damaged instruments, Rian cleans them","at":"","carried_by":"Ivo"},
		"Pitch Torch":{"from":"Ivo carries pitch from Ohio, Mateo assembles","at":"BoatwrightSlip","carried_by":""},
		"Blorb Slime":{"from":"Left with Nara on commission by travelling merchants","at":"","carried_by":"Nara"},
		"Rye Loaf":{"from":"Ivo's Ohio run, held in Leena's stores","at":"","carried_by":"Ivo"},
		"Dried Berries":{"from":"Ivo's Ohio run, held in Leena's stores","at":"","carried_by":"Ivo"},
	}},
}

# ---------------------------------------------------------------------------
# Geometry queries shared by the terrain and the validator
# ---------------------------------------------------------------------------

## Signed distance in metres from the nearest shelf: negative inside it.
static func shelf_distance(p: Vector2) -> float:
	var best := INF
	for rect in SHELF_RECTS:
		var dx := maxf(maxf(rect.position.x - p.x, p.x - rect.end.x), 0.0)
		var dz := maxf(maxf(rect.position.y - p.y, p.y - rect.end.y), 0.0)
		var outside := Vector2(dx, dz).length()
		if outside > 0.0:
			best = minf(best, outside)
		else:
			best = minf(best, -minf(minf(p.x - rect.position.x, rect.end.x - p.x), minf(p.y - rect.position.y, rect.end.y - p.y)))
	best = minf(best, p.distance_to(HERON_ROCK["center"]) - HERON_SHELF_RADIUS)
	return best
