extends SceneTree

## Structural guard for the generated plan consumed by ChineseVillagePlanBuilder.
## Geometric fit/clearance remains calculated by chinese_village_plan.py, which
## owns the polygon operations and emits PROBLEMS with the plan.

const PLAN := preload("res://scripts/chinese_plan.gd")
const EXPECTED := {
	"islands": 8,
	"bridges": 10,
	"abutments": 20,
	"items": 54,
	"openings": 38,
	"paths": 65,
	"ramps": 9,
	"parapets": 27,
	"aprons": 19,
}

func _initialize() -> void:
	var errors: Array[String] = []
	_check_count(errors,"islands",PLAN.ISLANDS.size())
	_check_count(errors,"bridges",PLAN.BRIDGES.size())
	_check_count(errors,"abutments",PLAN.ABUTMENTS.size())
	_check_count(errors,"items",PLAN.ITEMS.size())
	_check_count(errors,"openings",PLAN.OPENINGS.size())
	_check_count(errors,"paths",PLAN.PATHS.size())
	_check_count(errors,"ramps",PLAN.RAMPS.size())
	_check_count(errors,"parapets",PLAN.PARAPETS.size())
	_check_count(errors,"aprons",PLAN.APRONS.size())
	var island_keys := {}
	for island in PLAN.ISLANDS:
		if island_keys.has(island.key):
			errors.append("duplicate island key: %s" % island.key)
		island_keys[island.key] = true
		if island.outline.size() < 4 or island.area < island.need:
			errors.append("island %s has an incomplete boundary or lacks its land budget" % island.key)
		if not _is_closed(island.outline):
			errors.append("island %s outline is not closed" % island.key)
	var item_keys := {}
	for item in PLAN.ITEMS:
		if item_keys.has(item.key):
			errors.append("duplicate item key: %s" % item.key)
		item_keys[item.key] = item
		if not island_keys.has(item.island):
			errors.append("item %s references unknown island %s" % [item.key,item.island])
		if item.rect.size()!=5 or float(item.rect[2])<=0.0 or float(item.rect[3])<=0.0:
			errors.append("item %s has invalid footprint data" % item.key)
	for opening in PLAN.OPENINGS:
		if not item_keys.has(opening.item):
			errors.append("opening references unknown item %s" % opening.item)
		elif item_keys[opening.item].island != opening.island:
			errors.append("opening %s is assigned to the wrong island" % opening.item)
		if float(opening.width)<=0.0 or opening.side not in ["n","s","e","w"]:
			errors.append("opening has invalid side or width")
	var bridge_keys := {}
	var chain_count := 0
	for bridge in PLAN.BRIDGES:
		var key := "%s-%s" % [bridge.a,bridge.b]
		bridge_keys[key] = true
		if bridge.ends.size()!=2 or float(bridge.width)<=0.0 or float(bridge.span)<=0.0:
			errors.append("bridge %s has invalid dimensions/endpoints" % key)
		if bridge.kind=="chain":
			chain_count += 1
		elif bridge.kind!="cantilever":
			errors.append("bridge %s has unknown construction %s" % [key,bridge.kind])
	var seated := {}
	for abutment in PLAN.ABUTMENTS:
		if not bridge_keys.has(abutment.bridge):
			errors.append("abutment references unknown bridge %s" % abutment.bridge)
		seated[abutment.bridge] = int(seated.get(abutment.bridge,0))+1
	for bridge_key in bridge_keys:
		if seated.get(bridge_key,0)!=2:
			errors.append("bridge %s needs two planned abutments" % bridge_key)
	if chain_count!=2:
		errors.append("expected two chain bridges, found %d" % chain_count)
	for path in PLAN.PATHS:
		if not island_keys.has(path.island) or path.pts.size()<2 or float(path.width)<=0.0:
			errors.append("path %s has an invalid island, width or polyline" % path.to)
	for ramp in PLAN.RAMPS:
		if ramp.foot.size()!=2 or ramp.head.size()!=2 or float(ramp.width)<=0.0:
			errors.append("ramp %s has invalid endpoints or width" % ramp.name)
		if ramp.name=="inner court to royal kitchen":
			if ramp.segments.size()!=5 or not is_equal_approx(float(ramp.width),3.2):
				errors.append("kitchen descent must have two 3.2 m flights and three landings")
			else:
				var flights := 0
				for section in ramp.segments:
					if section.kind=="flight":
						flights+=1
						var run := Vector2(float(section.a[0]),float(section.a[1])).distance_to(Vector2(float(section.b[0]),float(section.b[1])))
						var rise := absf(float(section.from_y)-float(section.to_y))
						if not is_equal_approx(run,4.5) or rise<=0.0 or rad_to_deg(atan(rise/run))>32.1:
							errors.append("kitchen ramp flight exceeds the 32 degree plan")
					elif section.kind!="landing" or not is_equal_approx(float(section.height),2.8) and not is_equal_approx(float(section.height),5.6) and not is_equal_approx(float(section.height),0.0):
						errors.append("kitchen ramp has an invalid landing")
				if flights!=2:
					errors.append("kitchen descent must contain two flights")
	var kitchen: Dictionary = item_keys.get("kitchen",{})
	if not kitchen.is_empty():
		if not is_equal_approx(float(kitchen.rect[0]),32.0) or not is_equal_approx(float(kitchen.rect[1]),-22.0) or kitchen.door!="-x":
			errors.append("royal kitchen must match its approved location and west entrance")
		var west_door := false
		for opening in PLAN.OPENINGS:
			if opening.item=="kitchen" and float(opening.normal[0]) < -0.99 and is_equal_approx(float(opening.width),2.0):
				west_door=true
		if not west_door:
			errors.append("royal kitchen needs its 2 m west door")
	for problem in PLAN.PROBLEMS:
		errors.append("plan geometry: %s" % str(problem))
	if not errors.is_empty():
		for error in errors:
			push_error(error)
		quit(1)
		return
	print("ChinesePlan structure is consistent: %d islands, %d bridges, %d placed items, %d openings, %d paths." % [PLAN.ISLANDS.size(),PLAN.BRIDGES.size(),PLAN.ITEMS.size(),PLAN.OPENINGS.size(),PLAN.PATHS.size()])
	quit(0)


func _check_count(errors: Array[String], key: String, actual: int) -> void:
	if actual!=int(EXPECTED[key]):
		errors.append("%s count changed: expected %d, got %d" % [key,EXPECTED[key],actual])


func _is_closed(outline: Array) -> bool:
	if outline.size()<2:
		return false
	var first: Array = outline[0]
	var last: Array = outline[outline.size()-1]
	return is_equal_approx(float(first[0]),float(last[0])) and is_equal_approx(float(first[1]),float(last[1]))
