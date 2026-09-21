class_name SuitPowers
extends RefCounted

## What each worn limb blorb is doing this frame, for any character
## (docs/traversal_powers_architecture.md).
##
## Twelve limb-and-element combinations, each gated on the same three things:
## the button is held, that slot's worn blorb is of that element, and it can
## pay the magic. Both characters used to work this out for themselves, in
## twelve parallel lines apiece, along with the same derived hovers and the
## same sound pulses. A power that behaves differently depending on who is
## holding the button is the exact failure this project keeps hitting, so the
## answer lives here once.
##
## Nothing here knows which body it belongs to. Callers pass the suit, the
## frame, and whether either hand is committed to something else, such as a
## thrown item or a weapon.

## Magic drained per second of continuous use, by element. City is arms-only
## and folds into the same forward-stream damage pipeline as electric.
const WATER_MP_PER_SECOND := 3.0
const FIRE_MP_PER_SECOND := 4.5
const ELECTRIC_MP_PER_SECOND := 4.0
const CITY_MP_PER_SECOND := 4.0

var left_arm_water := false
var right_arm_water := false
var left_arm_fire := false
var right_arm_fire := false
var left_arm_electric := false
var right_arm_electric := false
var left_arm_city := false
var right_arm_city := false
var left_leg_water := false
var right_leg_water := false
var left_leg_fire := false
var right_leg_fire := false

## Derived from the pairs above: a matched pair of jets is a hover, and both
## pairs together are flight.
var water_leg_hover := false
var fire_hand_hover := false
var fire_leg_hover := false
var fire_limb_flight := false


## One frame of every limb power. `swimming` keeps water feet jetting
## backward to swim rather than downward to hover; `left_arm_busy` and
## `right_arm_busy` leave a hand alone that is already holding something.
func update(
	suit: BlorbSuitController, delta: float, swimming: bool,
	left_arm_busy: bool = false, right_arm_busy: bool = false, sound_key: int = 0
) -> void:
	left_arm_water = _consume(suit, "arm_left", "left_arm_power", "water", WATER_MP_PER_SECOND, delta, left_arm_busy)
	right_arm_water = _consume(suit, "arm_right", "right_arm_power", "water", WATER_MP_PER_SECOND, delta, right_arm_busy)
	left_arm_fire = _consume(suit, "arm_left", "left_arm_power", "fire", FIRE_MP_PER_SECOND, delta, left_arm_busy)
	right_arm_fire = _consume(suit, "arm_right", "right_arm_power", "fire", FIRE_MP_PER_SECOND, delta, right_arm_busy)
	left_arm_electric = _consume(suit, "arm_left", "left_arm_power", "electric", ELECTRIC_MP_PER_SECOND, delta, left_arm_busy)
	right_arm_electric = _consume(suit, "arm_right", "right_arm_power", "electric", ELECTRIC_MP_PER_SECOND, delta, right_arm_busy)
	left_arm_city = _consume(suit, "arm_left", "left_arm_power", "city", CITY_MP_PER_SECOND, delta, left_arm_busy)
	right_arm_city = _consume(suit, "arm_right", "right_arm_power", "city", CITY_MP_PER_SECOND, delta, right_arm_busy)
	left_leg_water = _consume(suit, "leg_left", "left_leg_power", "water", WATER_MP_PER_SECOND, delta)
	right_leg_water = _consume(suit, "leg_right", "right_leg_power", "water", WATER_MP_PER_SECOND, delta)
	left_leg_fire = _consume(suit, "leg_left", "left_leg_power", "fire", FIRE_MP_PER_SECOND, delta)
	right_leg_fire = _consume(suit, "leg_right", "right_leg_power", "fire", FIRE_MP_PER_SECOND, delta)
	if any_water():
		UISounds.pulse_power_loop(&"water", sound_key)
	if any_fire():
		UISounds.pulse_power_loop(&"fire", sound_key)
	if any_electric() or any_city():
		UISounds.pulse_power_loop(&"electric", sound_key)
	water_leg_hover = left_leg_water and right_leg_water and not swimming
	fire_hand_hover = left_arm_fire and right_arm_fire
	# A matched pair of downward foot jets supplies the same lift and fall
	# braking as the matched hand jets. It stays a level hover on its own;
	# both pairs together upgrade that lift into directional four-limb flight.
	fire_leg_hover = left_leg_fire and right_leg_fire
	fire_limb_flight = fire_hand_hover and fire_leg_hover


## Whether any jet is currently holding the body up by itself.
func powered_hover_active() -> bool:
	return water_leg_hover or fire_hand_hover or fire_leg_hover or fire_limb_flight


## How many water limbs are jetting, which is what a swimmer's blast is
## worth (see SwimMode.jet_speed_multiplier()).
func swim_jet_count() -> int:
	var count := 0
	for jetting in [left_arm_water, right_arm_water, left_leg_water, right_leg_water]:
		if jetting:
			count += 1
	return count


func any_water() -> bool:
	return left_arm_water or right_arm_water or left_leg_water or right_leg_water


func any_fire() -> bool:
	return left_arm_fire or right_arm_fire or left_leg_fire or right_leg_fire


func any_electric() -> bool:
	return left_arm_electric or right_arm_electric


func any_city() -> bool:
	return left_arm_city or right_arm_city


## The fire slots currently jetting, which flight reads as boosters.
func firing_leg_slots() -> Array[String]:
	var slots: Array[String] = []
	if left_leg_fire:
		slots.append("leg_left")
	if right_leg_fire:
		slots.append("leg_right")
	return slots


func clear() -> void:
	left_arm_water = false
	right_arm_water = false
	left_arm_fire = false
	right_arm_fire = false
	left_arm_electric = false
	right_arm_electric = false
	left_arm_city = false
	right_arm_city = false
	left_leg_water = false
	right_leg_water = false
	left_leg_fire = false
	right_leg_fire = false
	water_leg_hover = false
	fire_hand_hover = false
	fire_leg_hover = false
	fire_limb_flight = false


static func _consume(
	suit: BlorbSuitController, slot: String, action: String, element: String,
	rate: float, delta: float, busy: bool = false
) -> bool:
	if busy or suit == null or UIState.modal_open or not Input.is_action_pressed(action):
		return false
	var blorb := suit.worn_blorb_in_slot(slot)
	if blorb == null or blorb.element_state != element:
		return false
	return blorb.consume_mp(rate * delta)
