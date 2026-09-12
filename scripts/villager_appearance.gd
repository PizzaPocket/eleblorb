class_name VillagerAppearance
extends RefCounted

## Shared, data-driven human-villager appearance assignment. Kingdom
## generators provide their own culturally/climatically appropriate palettes,
## while this helper consistently applies the full set of human variation:
## skin, outfit pieces, hair, height, build, gender-aware hairstyles and dress.
## Pools should contain at least as many entries as their consumers when a
## generator wants a no-repeat first pass.
static func apply_profile(npc: Node, population_index: int, gender_index: int, is_female: bool, profile: Dictionary) -> void:
	npc.is_female = is_female
	npc.skin_color = _pick_color(profile["skin_colors"], population_index)
	npc.shirt_color = _pick_color(profile["shirt_colors"], population_index)
	npc.pants_color = _pick_color(profile["pants_colors"], population_index)
	npc.shoe_color = _pick_color(profile["shoe_colors"], population_index)
	npc.glove_color = _pick_color(profile["glove_colors"], population_index)
	npc.sleeve_style = str(profile.get("sleeve_style", ProceduralFigure.SLEEVE_STYLE_LONG))
	npc.hair_color = _pick_color(profile["hair_colors"], population_index)
	npc.abdomen_width_scale = _pick_float(profile["abdomen_scales"], population_index)

	var gender_key := "female" if is_female else "male"
	npc.body_scale = _pick_float(profile[gender_key + "_body_scales"], gender_index)
	npc.chest_build_scale = _pick_float(profile[gender_key + "_chest_scales"], gender_index)
	npc.hip_build_scale = _pick_float(profile[gender_key + "_hip_scales"], gender_index)
	npc.hair_style = _pick_string(profile[gender_key + "_hair_styles"], gender_index)
	if npc.hair_style == FigureHair.STYLE_LONG:
		var lengths: Array = profile.get("long_hair_lengths", [0.0])
		npc.hair_length_variance = _pick_float(lengths, gender_index)

	var dress_indices: Array = profile.get("dress_indices", [])
	npc.wears_dress = is_female and population_index in dress_indices
	if npc.wears_dress:
		npc.dress_color = npc.pants_color
		npc.dress_has_covered_legs = bool(profile.get("dress_has_covered_legs", false))


static func _pick_color(pool_value: Variant, index: int) -> Color:
	var pool: Array = pool_value
	return pool[index % pool.size()]


static func _pick_float(pool_value: Variant, index: int) -> float:
	var pool: Array = pool_value
	return float(pool[index % pool.size()])


static func _pick_string(pool_value: Variant, index: int) -> String:
	var pool: Array = pool_value
	return str(pool[index % pool.size()])
