class_name HearthFire
extends Node3D

## One fire in one hearth: its flames, its warm light, its glowing embers and the
## smoke from its chimney. The fire is lit or banked by the village clock rather
## than burning all day, because a household does not keep a hearth roaring
## through a warm afternoon.
##
## Modes:
##   "always"   lit day and night (the inn keeps its common-room fire going)
##   "evening"  lit from dusk through the cold early morning (the default)
##   "hours"    lit between two clock hours, for a working fire (an oven that is
##              fired before dawn, a forge that works the day)
## `hours` is (from, to) in game hours and may run past midnight.

const EVENING := Vector2(17.0, 7.0)
const CHECK_INTERVAL := 0.5
const SMOKE_GROUP := "hearth_smoke"

var mode := "evening"
var hours := EVENING
var smoke: Array[ChimneySmoke.Puff] = []

var _flames: Array[GPUParticles3D] = []
var _lights: Array[Dictionary] = []
var _embers: Array[Dictionary] = []
var _lit := true
var _elapsed := CHECK_INTERVAL


## Builds the fire's node under `parent` from a schedule dictionary:
## {"mode": "always"|"evening"|"hours", "hours": [from, to]}.
static func create(parent: Node3D, schedule: Dictionary = {}) -> HearthFire:
	var fire := HearthFire.new()
	fire.name = "HearthFire"
	fire.mode = str(schedule.get("mode", "evening"))
	if schedule.has("hours"):
		var window: Array = schedule["hours"]
		fire.hours = Vector2(float(window[0]), float(window[1]))
		fire.mode = "hours"
	parent.add_child(fire)
	return fire


func add_flame(flame: GPUParticles3D) -> void:
	add_child(flame)
	_flames.append(flame)


func add_light(light: Light3D) -> void:
	add_child(light)
	_lights.append({"node": light, "energy": light.light_energy})


## `material` glows while the fire is lit and goes dark when it is banked.
func add_ember(material: StandardMaterial3D) -> void:
	_embers.append({"material": material, "energy": material.emission_energy_multiplier, "color": material.emission})


func lit_at(hour: float) -> bool:
	match mode:
		"always":
			return true
		_:
			var from_hour := hours.x
			var to_hour := hours.y
			if from_hour <= to_hour:
				return hour >= from_hour and hour < to_hour
			return hour >= from_hour or hour < to_hour


func _ready() -> void:
	_update(WorldState.game_time_hours, true)


func _process(delta: float) -> void:
	_elapsed += delta
	if _elapsed < CHECK_INTERVAL:
		return
	_elapsed = 0.0
	_update(WorldState.game_time_hours, false)


func _update(hour: float, force: bool) -> void:
	var lit := lit_at(hour)
	if lit == _lit and not force:
		return
	_lit = lit
	for flame in _flames:
		flame.emitting = lit
		flame.visible = lit
	for entry in _lights:
		var light := entry["node"] as Light3D
		if is_instance_valid(light):
			light.visible = lit
			light.light_energy = float(entry["energy"]) if lit else 0.0
	for entry in _embers:
		var material := entry["material"] as StandardMaterial3D
		material.emission_energy_multiplier = float(entry["energy"]) if lit else 0.0
	for puff in smoke:
		if is_instance_valid(puff.mesh):
			puff.mesh.visible = lit


## Applies the current clock to everything added so far. Call once the builder
## has finished adding flames, lights, embers and smoke.
func refresh() -> void:
	_update(WorldState.game_time_hours, true)


func is_lit() -> bool:
	return _lit
