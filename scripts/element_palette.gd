class_name ElementPalette
extends RefCounted

## Canonical body-substance colors. Any form made by reshaping or extending
## an elemental blorb's own body keeps its exact RGB hue; transparency,
## roughness, emission and metallic response may still describe the form's
## material. Summoned environmental matter (such as an Air blorb's actual
## clouds) uses that matter's natural palette instead.
const WATER_BODY := Color(0.08,0.28,0.55)
const FIRE_BODY := Color(0.85,0.25,0.05)
const ELECTRIC_BODY := Color(0.92,0.82,0.15)
const ROCK_BODY := Color(0.50,0.43,0.36)
const GROUND_BODY := Color(0.30,0.20,0.10)
const AIR_BODY := Color(0.62,0.84,1.0)
const PLANT_BODY := Color(0.22,0.60,0.20)
const PSYCHIC_BODY := Color(0.45,0.28,0.62)
const CITY_BODY := Color(0.15,0.50,0.75)
const ICE_BODY := Color(0.78,0.92,0.98)
const SNOW_BODY := Color(0.94,0.96,0.98)
const WOOD_BODY := Color(0.42,0.26,0.15)
const SPACE_BODY := Color(0.105,0.055,0.18)


static func body_color(element: String) -> Color:
	match element:
		"water": return WATER_BODY
		"fire": return FIRE_BODY
		"electric": return ELECTRIC_BODY
		"rock": return ROCK_BODY
		"ground": return GROUND_BODY
		"air": return AIR_BODY
		"plant": return PLANT_BODY
		"psychic": return PSYCHIC_BODY
		"city": return CITY_BODY
		"ice": return ICE_BODY
		"snow": return SNOW_BODY
		"wood": return WOOD_BODY
		"space": return SPACE_BODY
		_: return Color(0.94,0.96,0.93)
