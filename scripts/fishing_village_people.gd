class_name FishingVillagePeople
extends RefCounted

## The fishing village's fifteen residents (docs/architecture/fishing_village.md,
## the census and its dress charter): each one's look, written per person from
## work, age, household and temperament; two lines in their own voice; and a
## day spent between home and work along the built decks. Nara (the shop) and
## Leena (the rest point) are placed by FloatingVillage and take their looks
## from here. Coordinates are plan metres (FishingVillagePlan).

const SAND := Color(0.80, 0.72, 0.56)
const CREAM := Color(0.90, 0.86, 0.76)
const INDIGO := Color(0.20, 0.26, 0.40)
const CHARCOAL := Color(0.22, 0.22, 0.24)
const FADED_BLUE := Color(0.42, 0.52, 0.62)
const OLIVE := Color(0.36, 0.40, 0.26)
const SANDAL := Color(0.30, 0.20, 0.12)

const TEAL := Color(0.24, 0.55, 0.52)
const OCHRE := Color(0.82, 0.58, 0.22)
const ARAN_GREEN := Color(0.30, 0.50, 0.32)
const CORAL := Color(0.76, 0.30, 0.28)
const TERRACOTTA := Color(0.72, 0.42, 0.22)
const VIOLET := Color(0.48, 0.38, 0.66)

# Places along the built decks, plan metres.
const SPINE_W := Vector2(-28.0, -6.4)
const SPINE_SEN := Vector2(-15.0, -6.7)
const SPINE_MID := Vector2(-2.0, -7.5)
const SPINE_NET := Vector2(8.0, -7.6)
const SPINE_E := Vector2(16.0, -6.0)
const HERON := Vector2(21.0, 0.0)
const LANDING := Vector2(-31.0, -9.0)
const VENN_VERANDA := Vector2(-29.5, -13.9)
const VENN_LIVING := Vector2(-29.5, -16.5)
const SLIP := Vector2(-41.0, -16.0)
const SLIP_SHELTER := Vector2(-42.5, -19.0)
const SEN_PORCH := Vector2(-15.5, -10.8)
const PAVILION := Vector2(-2.0, -1.0)
const PAVILION_WEST := Vector2(-7.5, 2.0)
const ARAN_VERANDA := Vector2(7.0, -2.2)
const ARAN_DOOR := Vector2(7.6, 1.15)
const PEARL_YARD := Vector2(9.2, 8.0)
const VALE_ARRIVAL := Vector2(27.6, -5.6)
const VALE_LIVING := Vector2(30.3, -6.6)
const VALE_WORK := Vector2(37.6, -6.0)
const CATCH_DECK := Vector2(40.0, 6.0)
const MOR_GANGWAY := Vector2(-23.5, 4.0)
const MOR_ARRIVAL := Vector2(-23.5, 10.0)

const ROUTE_LANDING_TO_SEN := [LANDING, SPINE_W, SPINE_SEN]
const ROUTE_SEN_TO_SCHOOL := [SPINE_SEN, Vector2(-15.0, -9.6), SEN_PORCH, Vector2(-12.0, -10.8), Vector2(-12.0, -12.4), Vector2(-12.4, -13.6)]
const ROUTE_SPINE_TO_PAVILION := [SPINE_MID, Vector2(-2.0, -5.0), PAVILION]
const ROUTE_SPINE_TO_ARAN := [SPINE_NET, Vector2(7.0, -4.6), ARAN_VERANDA]
const ROUTE_ARAN_TO_PEARL := [ARAN_VERANDA, ARAN_DOOR, Vector2(10.0, 1.6), Vector2(12.0, 3.0), Vector2(12.0, 5.2), Vector2(12.0, 6.6), PEARL_YARD]
const ROUTE_SPINE_TO_VALE := [SPINE_E, HERON, Vector2(23.0, -1.5), Vector2(25.6, -3.9), VALE_ARRIVAL, Vector2(28.3, -6.3), VALE_LIVING]
const ROUTE_VALE_TO_CATCH := [VALE_LIVING, Vector2(31.0, -4.4), Vector2(31.0, -3.6), Vector2(37.6, -3.6), Vector2(38.0, -2.6), Vector2(38.0, 2.6), CATCH_DECK]
const ROUTE_PAVILION_TO_MOR := [PAVILION, PAVILION_WEST, Vector2(-14.0, 3.0), Vector2(-20.0, 3.8), MOR_GANGWAY, Vector2(-23.5, 8.4), MOR_ARRIVAL]

## name -> {female, look, lines, schedule}. Looks: skin, shirt, pants, sleeve,
## hair, hair_color, body (height), chest, hips, belly, and the optional
## cropped, dress, beard, beard_color, glasses.
static var RESIDENTS := {
	"Nara Venn": {"female": true, "look": {
		"skin": Color(0.48, 0.31, 0.20), "shirt": TEAL, "pants": CHARCOAL, "sleeve": "none", "cropped": true,
		"hair": FigureHair.STYLE_PONYTAIL, "hair_color": Color(0.06, 0.05, 0.04), "body": 0.96, "chest": 0.97, "hips": 1.05, "belly": 1.0}},
	"Mateo Venn": {"female": false, "look": {
		"skin": Color(0.87, 0.68, 0.52), "shirt": FADED_BLUE, "pants": TEAL.darkened(0.35), "sleeve": "short",
		"hair": FigureHair.STYLE_FLAT_TOP, "hair_color": Color(0.28, 0.17, 0.09), "beard": "full", "beard_color": Color(0.28, 0.17, 0.09),
		"body": 1.08, "chest": 1.14, "hips": 1.0, "belly": 1.12},
		"lines": [
			"Hear that creak? Third pile from the end. She'll want a new cap before the rains.",
			"Hand me that... no, the other one. Never mind, I've got it.",
			"Sawdust in my tea again. Lio thinks it's hilarious.",
		],
		"schedule": [
			{"hour": 6.5, "at": SLIP_SHELTER, "range": 1.2, "route": [VENN_LIVING, VENN_VERANDA, LANDING, Vector2(-41.0, -11.0), SLIP, SLIP_SHELTER]},
			{"hour": 12.0, "at": PAVILION + Vector2(-2.5, -0.6), "range": 0.8, "route": [SLIP, Vector2(-41.0, -11.0), LANDING, SPINE_W, SPINE_SEN, SPINE_MID, Vector2(-2.0, -5.0), PAVILION]},
			{"hour": 13.5, "at": SLIP_SHELTER, "range": 1.2, "route": [Vector2(-2.0, -5.0), SPINE_MID, SPINE_SEN, SPINE_W, LANDING, Vector2(-41.0, -11.0), SLIP, SLIP_SHELTER]},
			{"hour": 19.0, "at": VENN_LIVING, "range": 0.6, "route": [SLIP, Vector2(-41.0, -11.0), LANDING, VENN_VERANDA, VENN_LIVING]},
		]},
	"Lio Venn": {"female": false, "look": {
		"skin": Color(0.62, 0.45, 0.32), "shirt": CREAM, "pants": TEAL, "sleeve": "short", "cropped": true,
		"hair": FigureHair.STYLE_AFRO, "hair_color": Color(0.07, 0.05, 0.04), "body": 0.93, "chest": 1.0, "hips": 0.98, "belly": 1.0},
		"lines": [
			"You swam here? From the shore? In your clothes?",
			"Been sorting these nails since breakfast. They're all the same size. I checked.",
			"See that heron? Same one every day. I call him the inspector.",
		],
		"schedule": [
			{"hour": 8.0, "at": Vector2(-12.6, -14.0), "range": 0.6, "route": [VENN_LIVING, VENN_VERANDA, LANDING] + ROUTE_LANDING_TO_SEN + ROUTE_SEN_TO_SCHOOL},
			{"hour": 11.0, "at": LANDING + Vector2(-2.0, 0.0), "range": 1.5, "route": [Vector2(-12.0, -12.4), Vector2(-12.0, -10.8), SEN_PORCH, Vector2(-15.0, -9.6), SPINE_SEN, SPINE_W, LANDING]},
			{"hour": 14.0, "at": SLIP_SHELTER + Vector2(1.0, 0.6), "range": 1.0, "route": [LANDING, Vector2(-41.0, -11.0), SLIP, SLIP_SHELTER]},
			{"hour": 19.5, "at": Vector2(-32.3, -16.9), "range": 0.4, "route": [SLIP, Vector2(-41.0, -11.0), LANDING, VENN_VERANDA, VENN_LIVING, Vector2(-31.0, -16.75), Vector2(-32.3, -16.9)]},
		]},
	"Mai Aran": {"female": true, "look": {
		"skin": Color(0.76, 0.58, 0.42), "shirt": ARAN_GREEN, "pants": INDIGO, "sleeve": "short", "cropped": true,
		"hair": FigureHair.STYLE_BUN, "hair_color": Color(0.20, 0.12, 0.07), "body": 0.92, "chest": 0.95, "hips": 1.1, "belly": 1.0},
		"lines": [
			"Careful, you're standing on my good basket.",
			"Four hundred shells this week and one pearl worth the trouble. That's a good week.",
			"If you find a shell with a pink lip, bring it here. Pree's collecting them, apparently.",
		],
		"schedule": [
			{"hour": 7.0, "at": PEARL_YARD, "range": 1.4, "route": [Vector2(10.0, 1.6)] + ROUTE_ARAN_TO_PEARL.slice(3)},
			{"hour": 12.0, "at": PAVILION + Vector2(2.4, -1.2), "range": 0.8, "route": [Vector2(12.0, 6.6), Vector2(12.0, 5.2), Vector2(12.0, 3.0), Vector2(10.0, 1.6), ARAN_DOOR, ARAN_VERANDA, Vector2(7.0, -4.6), SPINE_NET, SPINE_MID, Vector2(-2.0, -5.0), PAVILION]},
			{"hour": 13.0, "at": PEARL_YARD, "range": 1.4, "route": [Vector2(-2.0, -5.0), SPINE_MID, SPINE_NET] + ROUTE_SPINE_TO_ARAN.slice(1) + ROUTE_ARAN_TO_PEARL.slice(1)},
			{"hour": 18.5, "at": Vector2(9.5, 0.6), "range": 0.6, "route": [Vector2(12.0, 6.6), Vector2(12.0, 5.2), Vector2(12.0, 3.0), Vector2(10.0, 1.6), Vector2(9.5, 0.6)]},
		]},
	"Salim Aran": {"female": false, "look": {
		"skin": Color(0.47, 0.33, 0.23), "shirt": OCHRE, "pants": FADED_BLUE, "sleeve": "none", "cropped": true,
		"hair": FigureHair.STYLE_BUZZCUT, "hair_color": Color(0.32, 0.30, 0.32), "beard": "stubble", "beard_color": Color(0.46, 0.44, 0.44),
		"body": 1.02, "chest": 1.08, "hips": 1.0, "belly": 1.2},
		"lines": [
			"Pull that end tight for me? Thank you. Nobody ever offers.",
			"Something big went through this last night. Look at the size of that hole.",
			"Wind's off the plateau. They'll be lying deep today.",
		],
		"schedule": [
			{"hour": 6.0, "at": Vector2(8.6, -15.6), "range": 1.2, "route": [ARAN_DOOR, ARAN_VERANDA, Vector2(7.0, -4.6), SPINE_NET, Vector2(8.0, -11.0), Vector2(8.6, -15.6)]},
			{"hour": 12.0, "at": PAVILION + Vector2(2.0, -1.6), "range": 0.8, "route": [Vector2(8.0, -11.0), SPINE_NET, SPINE_MID, Vector2(-2.0, -5.0), PAVILION]},
			{"hour": 13.0, "at": Vector2(8.6, -15.6), "range": 1.2, "route": [Vector2(-2.0, -5.0), SPINE_MID, SPINE_NET, Vector2(8.0, -11.0), Vector2(8.6, -15.6)]},
			{"hour": 18.0, "at": ARAN_VERANDA + Vector2(0.0, 1.8), "range": 0.8, "route": [Vector2(8.0, -11.0), SPINE_NET, Vector2(7.0, -4.6), ARAN_VERANDA, ARAN_VERANDA + Vector2(0.0, 1.8)]},
		]},
	"Dala Aran": {"female": true, "look": {
		"skin": Color(0.45, 0.32, 0.22), "shirt": CREAM, "pants": OCHRE.darkened(0.25), "sleeve": "long", "dress": OCHRE.darkened(0.25),
		"hair": FigureHair.STYLE_BUN, "hair_color": Color(0.88, 0.86, 0.82), "body": 0.86, "chest": 0.9, "hips": 1.06, "belly": 1.0},
		"lines": [
			"Sit down, you're blocking my sky.",
			"Clouds stacking up over the plateau. Rain by supper.",
			"You look like you came a long way. Have you eaten?",
		],
		"schedule": [
			{"hour": 6.0, "at": Vector2(7.0, 3.0), "range": 0.3, "route": []},
			{"hour": 12.0, "at": PAVILION + Vector2(-1.0, -1.6), "range": 0.5, "route": [ARAN_VERANDA, Vector2(7.0, -4.6), SPINE_NET, SPINE_MID, Vector2(-2.0, -5.0), PAVILION]},
			{"hour": 14.5, "at": Vector2(7.0, 3.0), "range": 0.3, "route": [Vector2(-2.0, -5.0), SPINE_MID, SPINE_NET, Vector2(7.0, -4.6), ARAN_VERANDA, Vector2(7.0, 3.0)]},
			{"hour": 21.0, "at": Vector2(9.2, 2.9), "range": 0.3, "route": [ARAN_DOOR, Vector2(9.2, 1.6), Vector2(9.2, 2.9)]},
		]},
	"Pree Aran": {"female": true, "look": {
		"skin": Color(0.62, 0.45, 0.32), "shirt": ARAN_GREEN.lightened(0.25), "pants": OCHRE, "sleeve": "short", "cropped": true,
		"hair": FigureHair.STYLE_PIGTAILS, "hair_color": Color(0.20, 0.12, 0.07), "body": 0.76, "chest": 0.9, "hips": 1.0, "belly": 1.0},
		"lines": [
			"Don't move. There's a dragonfly on your shoulder. Oh. It's gone.",
			"Do you want to see a beetle? It lives under the yard. It's enormous.",
			"I'm not allowed on the grading table anymore. It wasn't my fault.",
		],
		"schedule": [
			{"hour": 7.5, "at": Vector2(-11.6, -13.4), "range": 0.5, "route": [ARAN_VERANDA, Vector2(7.0, -4.6), SPINE_NET, SPINE_MID, SPINE_SEN] + ROUTE_SEN_TO_SCHOOL.slice(1)},
			{"hour": 12.0, "at": PEARL_YARD + Vector2(1.2, 0.6), "range": 1.2, "route": [Vector2(-12.0, -12.4), Vector2(-12.0, -10.8), SEN_PORCH, Vector2(-15.0, -9.6), SPINE_SEN, SPINE_MID, SPINE_NET] + ROUTE_SPINE_TO_ARAN.slice(1) + ROUTE_ARAN_TO_PEARL.slice(1)},
			{"hour": 17.0, "at": Vector2(6.4, 0.8), "range": 0.6, "route": [Vector2(12.0, 6.6), Vector2(12.0, 5.2), Vector2(12.0, 3.0), Vector2(10.0, 1.6), ARAN_DOOR, Vector2(6.4, 0.8)]},
			{"hour": 20.0, "at": Vector2(12.4, -1.4), "range": 0.3, "route": [ARAN_DOOR, Vector2(10.0, 0.3), Vector2(12.5, 0.3), Vector2(12.4, -1.4)]},
		]},
	"Jori Vale": {"female": false, "look": {
		"skin": Color(0.96, 0.82, 0.69), "shirt": CORAL, "pants": INDIGO, "sleeve": "none", "cropped": true,
		"hair": FigureHair.STYLE_PONYTAIL, "hair_color": Color(0.55, 0.16, 0.08), "body": 0.99, "chest": 1.0, "hips": 1.0, "belly": 1.0},
		"lines": [
			"Haven't seen you before. Swimmer or ferry?",
			"Lake's flat as a plate. Won't last.",
			"Heading out past the rocks? Tell someone first. I mean it.",
		],
		"schedule": [
			{"hour": 5.5, "at": CATCH_DECK + Vector2(2.6, 1.6), "range": 1.0, "route": ROUTE_VALE_TO_CATCH + [CATCH_DECK + Vector2(2.6, 1.6)]},
			{"hour": 12.5, "at": Vector2(7.4, -15.0), "range": 1.0, "route": [CATCH_DECK, Vector2(38.0, 2.6), Vector2(38.0, -2.6), Vector2(37.6, -3.6), Vector2(31.0, -3.6), Vector2(31.0, -4.4), VALE_LIVING, Vector2(28.3, -6.3), VALE_ARRIVAL, Vector2(25.6, -3.9), Vector2(23.0, -1.5), HERON, SPINE_E, SPINE_NET, Vector2(8.0, -11.0), Vector2(7.4, -15.0)]},
			{"hour": 17.5, "at": HERON + Vector2(1.6, 0.6), "range": 0.8, "route": [Vector2(8.0, -11.0), SPINE_NET, SPINE_E, HERON]},
			{"hour": 20.5, "at": VALE_LIVING, "range": 0.6, "route": [HERON, Vector2(23.0, -1.5), Vector2(25.6, -3.9), VALE_ARRIVAL, Vector2(28.3, -6.3), VALE_LIVING]},
		]},
	"Osei Vale": {"female": false, "look": {
		"skin": Color(0.25, 0.17, 0.12), "shirt": SAND, "pants": CORAL.darkened(0.3), "sleeve": "short",
		"hair": FigureHair.STYLE_BALD, "hair_color": Color(0.05, 0.04, 0.03), "beard": "full", "beard_color": Color(0.05, 0.04, 0.03),
		"body": 1.1, "chest": 1.12, "hips": 1.02, "belly": 1.16},
		"lines": [
			"Smell that? Another hour. Come back then.",
			"No, you can't help with the fire. Nobody helps with the fire.",
			"Here, try a piece. Go on. See? Told you.",
		],
		"schedule": [
			{"hour": 6.0, "at": CATCH_DECK + Vector2(2.4, 3.6), "range": 1.2, "route": ROUTE_VALE_TO_CATCH + [CATCH_DECK + Vector2(2.4, 3.6)]},
			{"hour": 19.0, "at": VALE_LIVING + Vector2(-0.8, 0.8), "range": 0.6, "route": [CATCH_DECK, Vector2(38.0, 2.6), Vector2(38.0, -2.6), Vector2(37.6, -3.6), Vector2(31.0, -3.6), Vector2(31.0, -4.4), VALE_LIVING]},
		]},
	"Tavi Vale": {"female": false, "look": {
		"skin": Color(0.55, 0.40, 0.28), "shirt": CORAL, "pants": SAND, "sleeve": "short", "cropped": true,
		"hair": FigureHair.STYLE_BUZZCUT, "hair_color": Color(0.16, 0.10, 0.06), "body": 0.70, "chest": 0.92, "hips": 0.95, "belly": 1.0},
		"lines": [
			"Hear that engine? That's Ivo. He's late. He's always late.",
			"Want a float? I've got too many. Don't tell Jori.",
			"I held my breath for a hundred and twelve. Pree says I counted fast.",
		],
		"schedule": [
			{"hour": 7.5, "at": Vector2(-12.0, -13.0), "range": 0.5, "route": [VALE_LIVING, Vector2(28.3, -6.3), VALE_ARRIVAL, Vector2(25.6, -3.9), Vector2(23.0, -1.5), HERON, SPINE_E, SPINE_NET, SPINE_MID, SPINE_SEN] + ROUTE_SEN_TO_SCHOOL.slice(1)},
			{"hour": 12.0, "at": VALE_WORK, "range": 0.9, "route": [Vector2(-12.0, -12.4), Vector2(-12.0, -10.8), SEN_PORCH, Vector2(-15.0, -9.6), SPINE_SEN, SPINE_MID, SPINE_NET, SPINE_E, HERON, Vector2(23.0, -1.5), Vector2(25.6, -3.9), VALE_ARRIVAL, Vector2(28.3, -6.3), VALE_LIVING, Vector2(31.0, -4.4), Vector2(31.0, -3.6), Vector2(36.0, -3.6), VALE_WORK]},
			{"hour": 19.5, "at": Vector2(33.6, -5.4), "range": 0.3, "route": [Vector2(36.0, -3.6), Vector2(31.0, -3.6), Vector2(31.0, -4.4), VALE_LIVING, Vector2(32.0, -5.55), Vector2(33.6, -5.4)]},
		]},
	"Leena Mor": {"female": true, "look": {
		"skin": Color(0.58, 0.40, 0.28), "shirt": CREAM, "pants": TEAL.darkened(0.4), "sleeve": "short", "dress": TEAL.darkened(0.4),
		"hair": FigureHair.STYLE_BUN, "hair_color": Color(0.30, 0.27, 0.26), "body": 0.92, "chest": 0.96, "hips": 1.12, "belly": 1.0}},
	"Ivo Mor": {"female": false, "look": {
		"skin": Color(0.87, 0.68, 0.52), "shirt": TEAL, "pants": TERRACOTTA.darkened(0.3), "sleeve": "long",
		"hair": FigureHair.STYLE_BUZZCUT, "hair_color": Color(0.78, 0.76, 0.72), "beard": "full", "beard_color": Color(0.80, 0.78, 0.74),
		"body": 1.04, "chest": 1.08, "hips": 1.0, "belly": 1.24},
		"lines": [
			"Running late. The lake had opinions this morning.",
			"Mind the crates. The blue ones are bread, and if they get squashed I hear about it all week.",
			"Anything for the shore? I go back after lunch. Probably.",
		],
		"schedule": [
			{"hour": 6.0, "at": Vector2(-40.6, -3.2), "range": 1.0, "route": [MOR_ARRIVAL, Vector2(-23.5, 8.4), MOR_GANGWAY, Vector2(-28.0, 2.0), Vector2(-35.0, -2.0), Vector2(-40.6, -3.2)]},
			{"hour": 12.0, "at": PAVILION + Vector2(-3.0, -1.4), "range": 0.8, "route": [Vector2(-35.0, -2.0), Vector2(-28.0, 2.0), Vector2(-20.0, 3.8), Vector2(-14.0, 3.0), PAVILION_WEST, PAVILION]},
			{"hour": 14.0, "at": Vector2(-8.8, 11.0), "range": 0.7, "route": [PAVILION_WEST, Vector2(-14.0, 3.0), Vector2(-20.0, 3.8), MOR_GANGWAY, Vector2(-23.5, 8.5), Vector2(-12.0, 8.5), Vector2(-8.8, 9.6), Vector2(-8.8, 11.0)]},
			{"hour": 20.0, "at": Vector2(-10.6, 10.4), "range": 0.3, "route": [Vector2(-8.8, 9.6), Vector2(-10.4, 8.6), Vector2(-10.4, 9.6), Vector2(-10.6, 10.4)]},
		]},
	"Sela Mor": {"female": true, "look": {
		"skin": Color(0.70, 0.52, 0.38), "shirt": TERRACOTTA.darkened(0.3), "pants": INDIGO, "sleeve": "none", "cropped": true,
		"hair": FigureHair.STYLE_LONG, "hair_color": Color(0.06, 0.05, 0.04), "body": 0.98, "chest": 0.98, "hips": 1.04, "belly": 1.0},
		"lines": [
			"You swam all the way out? Next time wave at the ferry. We do stop.",
			"Dad says the ferry has moods. The ferry has a loose rudder pin.",
			"Grab the end of that line? Thanks.",
		],
		"schedule": [
			{"hour": 7.0, "at": LANDING + Vector2(-4.0, 3.0), "range": 1.2, "route": [MOR_ARRIVAL, Vector2(-23.5, 8.4), MOR_GANGWAY, Vector2(-28.0, 2.0), LANDING + Vector2(-4.0, 3.0)]},
			{"hour": 12.0, "at": Vector2(-9.4, 13.4), "range": 0.6, "route": [Vector2(-28.0, 2.0), MOR_GANGWAY, Vector2(-23.5, 8.5), Vector2(-12.0, 8.5), Vector2(-9.0, 9.6), Vector2(-9.4, 13.4)]},
			{"hour": 17.0, "at": PAVILION + Vector2(0.0, 2.6), "range": 1.2, "route": [Vector2(-9.0, 9.6), Vector2(-12.0, 8.5), Vector2(-23.5, 8.5), MOR_GANGWAY, Vector2(-20.0, 3.8), Vector2(-14.0, 3.0), PAVILION_WEST, PAVILION + Vector2(0.0, 2.6)]},
			{"hour": 21.5, "at": Vector2(-14.4, 9.6), "range": 0.4, "route": [PAVILION_WEST, Vector2(-14.0, 3.0), Vector2(-20.0, 3.8), MOR_GANGWAY, Vector2(-23.5, 8.5), MOR_ARRIVAL, Vector2(-22.5, 12.0), Vector2(-19.0, 12.0), Vector2(-17.0, 12.1), Vector2(-14.4, 11.4), Vector2(-14.4, 9.6)]},
		]},
	"Asha Sen": {"female": true, "look": {
		"skin": Color(0.33, 0.22, 0.16), "shirt": CREAM, "pants": VIOLET, "sleeve": "long", "dress": VIOLET, "glasses": true,
		"hair": FigureHair.STYLE_BUN, "hair_color": Color(0.05, 0.04, 0.03), "body": 0.94, "chest": 0.96, "hips": 1.1, "belly": 1.0},
		"lines": [
			"Is that a scrape? Let me see. You'll live. Keep it dry tonight.",
			"Quietly, please. Half of them are reading and the other half are pretending.",
			"I haven't sat down since sunrise. Tell me something that isn't a fever.",
		],
		"schedule": [
			{"hour": 7.5, "at": Vector2(-12.6, -14.6), "range": 0.5, "route": [Vector2(-18.0, -17.9), Vector2(-18.5, -16.3), Vector2(-18.5, -13.2), Vector2(-18.5, -11.0), Vector2(-12.0, -10.8), Vector2(-12.0, -12.4), Vector2(-12.6, -14.6)]},
			{"hour": 12.5, "at": Vector2(-15.6, -13.6), "range": 0.6, "route": [Vector2(-12.0, -12.4), Vector2(-12.0, -10.8), Vector2(-15.95, -10.8), Vector2(-15.95, -12.4), Vector2(-15.6, -13.6)]},
			{"hour": 18.0, "at": Vector2(-19.0, -13.4), "range": 0.5, "route": [Vector2(-15.95, -12.4), Vector2(-15.95, -10.8), Vector2(-18.5, -10.8), Vector2(-18.5, -12.4), Vector2(-19.0, -13.4)]},
			{"hour": 22.0, "at": Vector2(-18.0, -17.9), "range": 0.3, "route": [Vector2(-18.5, -13.2), Vector2(-18.5, -16.3), Vector2(-18.0, -17.9)]},
		]},
	"Rian Sen": {"female": false, "look": {
		"skin": Color(0.33, 0.22, 0.16), "shirt": VIOLET, "pants": OLIVE, "sleeve": "short",
		"hair": FigureHair.STYLE_LONG, "hair_color": Color(0.05, 0.04, 0.03), "body": 1.04, "chest": 1.05, "hips": 1.0, "belly": 1.04},
		"lines": [
			"Sorry, can't hear you over the saw. What?",
			"Look at this one. Same shell, three colours. Some of them I can't bring myself to cut.",
			"If you see my sister, tell her I ate.",
		],
		"schedule": [
			{"hour": 7.0, "at": Vector2(-16.2, -1.6), "range": 1.0, "route": [Vector2(-15.0, -17.9), Vector2(-15.5, -16.3), Vector2(-18.5, -16.3), Vector2(-18.5, -13.2), Vector2(-18.5, -11.0), SEN_PORCH, Vector2(-15.0, -9.6), SPINE_SEN, Vector2(-15.0, -4.2), Vector2(-16.2, -1.6)]},
			{"hour": 12.5, "at": PAVILION + Vector2(-2.0, 0.4), "range": 0.8, "route": [Vector2(-15.0, -4.2), SPINE_SEN, SPINE_MID, Vector2(-2.0, -5.0), PAVILION]},
			{"hour": 13.5, "at": Vector2(-16.2, -1.6), "range": 1.0, "route": [Vector2(-2.0, -5.0), SPINE_MID, SPINE_SEN, Vector2(-15.0, -4.2), Vector2(-16.2, -1.6)]},
			{"hour": 21.0, "at": Vector2(-15.0, -17.9), "range": 0.3, "route": [Vector2(-15.0, -4.2), SPINE_SEN, Vector2(-15.0, -9.6), SEN_PORCH, Vector2(-18.5, -11.0), Vector2(-18.5, -13.2), Vector2(-18.5, -16.3), Vector2(-15.5, -16.3), Vector2(-15.0, -17.9)]},
		]},
}


## Dresses `npc` from its look in RESIDENTS.
static func apply_look(npc: Node, name_text: String) -> void:
	var resident: Dictionary = RESIDENTS[name_text]
	var look: Dictionary = resident["look"]
	npc.is_female = bool(resident["female"])
	npc.skin_color = look["skin"]
	npc.shirt_color = look["shirt"]
	npc.pants_color = look["pants"]
	npc.shoe_color = SANDAL
	npc.glove_color = Color(0, 0, 0, 0)
	npc.sleeve_style = {"none": ProceduralFigure.SLEEVE_STYLE_NONE, "short": ProceduralFigure.SLEEVE_STYLE_SHORT, "long": ProceduralFigure.SLEEVE_STYLE_LONG}[str(look["sleeve"])]
	npc.hair_style = look["hair"]
	npc.hair_color = look["hair_color"]
	npc.body_scale = float(look["body"])
	npc.chest_build_scale = float(look["chest"])
	npc.hip_build_scale = float(look["hips"])
	npc.abdomen_width_scale = float(look["belly"])
	npc.cropped_trousers = bool(look.get("cropped", false))
	if look.has("dress"):
		npc.wears_dress = true
		npc.dress_color = look["dress"]
	if look.has("beard"):
		npc.beard_style = str(look["beard"])
		npc.beard_color = look["beard_color"]
	npc.has_glasses = bool(look.get("glasses", false))


## The residents who walk a day (everyone with a schedule).
static func walkers() -> Array[String]:
	var names: Array[String] = []
	for name_text: String in RESIDENTS:
		if RESIDENTS[name_text].has("schedule"):
			names.append(name_text)
	return names


## `name_text`'s day, with plan points moved into the world by `offset`.
static func world_schedule(name_text: String, offset: Vector2) -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	for entry: Dictionary in RESIDENTS[name_text]["schedule"]:
		var route: Array[Vector2] = []
		for point: Vector2 in entry["route"]:
			route.append(point + offset)
		entries.append({"hour": entry["hour"], "at": (entry["at"] as Vector2) + offset, "range": entry["range"], "route": route})
	return entries


## Where `name_text` is at `hour`: the anchor of the latest entry started.
static func place_at(name_text: String, hour: float) -> Vector2:
	var schedule: Array = RESIDENTS[name_text]["schedule"]
	var at: Vector2 = schedule[schedule.size() - 1]["at"]
	for entry: Dictionary in schedule:
		if float(entry["hour"]) <= hour:
			at = entry["at"]
	return at
