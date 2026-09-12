extends Node

## Procedural volcanic ambience. The surface layer combines slow molten
## movement with irregular bubble collapses; below lava it is heavily
## low-passed and joined by a denser viscous-flow layer. Camera position and
## the terrain's true local lava height control the transition.

const SAMPLE_RATE:=44100.0
const SURFACE_BUS:=&"Lava Surface"
const SUBMERGED_BUS:=&"Lava Submerged"
const PROCEDURAL_AMBIENCE_GAIN:=2.35
const SURFACE_VOLUME_DB:=-8.5
const SURFACE_SUBMERGED_VOLUME_DB:=-17.0
const SUBMERGED_VOLUME_DB:=-10.5

var _surface_player:AudioStreamPlayer
var _submerged_player:AudioStreamPlayer
var _surface_playback:AudioStreamGeneratorPlayback
var _submerged_playback:AudioStreamGeneratorPlayback
var _surface_filter:AudioEffectLowPassFilter
var _submerged_filter:AudioEffectLowPassFilter
var _terrain:Node
var _rng:=RandomNumberGenerator.new()
var _clock:=0.0
var _surface_low:=0.0
var _surface_mid:=0.0
var _submerged_low:=0.0
var _submerged_mid:=0.0
var _immersion:=0.0
var _bubble_voices:Array[Dictionary]=[]

func _ready()->void:
	_rng.seed=0x1A7A2026
	_terrain=get_node_or_null("../Terrain")
	_prepare_buses()
	_surface_player=_make_player(SURFACE_BUS);_submerged_player=_make_player(SUBMERGED_BUS)
	_surface_player.play();_submerged_player.play()
	_surface_playback=_surface_player.get_stream_playback() as AudioStreamGeneratorPlayback
	_submerged_playback=_submerged_player.get_stream_playback() as AudioStreamGeneratorPlayback

func _process(delta:float)->void:
	var camera:=get_viewport().get_camera_3d();var submerged:=false
	if camera!=null and _terrain!=null:
		var xz:=Vector2(camera.global_position.x,camera.global_position.z)
		submerged=_terrain.is_lava_area(xz) and camera.global_position.y<_terrain.get_lava_surface_height(xz)-0.06
	_immersion=move_toward(_immersion,1.0 if submerged else 0.0,delta*1.7)
	_surface_filter.cutoff_hz=lerpf(9200.0,520.0,_immersion)
	_surface_player.volume_db=lerpf(SURFACE_VOLUME_DB,SURFACE_SUBMERGED_VOLUME_DB,_immersion)
	_submerged_player.volume_db=linear_to_db(maxf(_immersion,0.001))+SUBMERGED_VOLUME_DB
	_fill_buffers()

func _prepare_buses()->void:
	for bus_name in [SURFACE_BUS,SUBMERGED_BUS]:
		if AudioServer.get_bus_index(bus_name)<0:
			AudioServer.add_bus();AudioServer.set_bus_name(AudioServer.bus_count-1,bus_name)
	var surface_index:=AudioServer.get_bus_index(SURFACE_BUS)
	if AudioServer.get_bus_effect_count(surface_index)>0:_surface_filter=AudioServer.get_bus_effect(surface_index,0) as AudioEffectLowPassFilter
	if _surface_filter==null:
		_surface_filter=AudioEffectLowPassFilter.new();AudioServer.add_bus_effect(surface_index,_surface_filter)
	_surface_filter.cutoff_hz=9200.0;_surface_filter.resonance=0.08
	var submerged_index:=AudioServer.get_bus_index(SUBMERGED_BUS)
	if AudioServer.get_bus_effect_count(submerged_index)>0:_submerged_filter=AudioServer.get_bus_effect(submerged_index,0) as AudioEffectLowPassFilter
	if _submerged_filter==null:
		_submerged_filter=AudioEffectLowPassFilter.new();AudioServer.add_bus_effect(submerged_index,_submerged_filter)
	_submerged_filter.cutoff_hz=980.0;_submerged_filter.resonance=0.05

func _make_player(bus_name:StringName)->AudioStreamPlayer:
	var stream:=AudioStreamGenerator.new();stream.mix_rate=SAMPLE_RATE;stream.buffer_length=0.35
	var player:=AudioStreamPlayer.new();player.stream=stream;player.bus=bus_name;add_child(player);return player

func _fill_buffers()->void:
	if _surface_playback==null or _submerged_playback==null:return
	var frames:=mini(_surface_playback.get_frames_available(),_submerged_playback.get_frames_available())
	for _frame in frames:
		var sample:=_next_sample();_surface_playback.push_frame(Vector2(sample.x,sample.x*0.96));_submerged_playback.push_frame(Vector2(sample.y,sample.y))

func _next_sample()->Vector2:
	var dt:=1.0/SAMPLE_RATE;_clock+=dt
	var white:=_rng.randf_range(-1.0,1.0)
	_surface_low=lerpf(_surface_low,white,0.0012);_surface_mid=lerpf(_surface_mid,white,0.018)
	_submerged_low=lerpf(_submerged_low,white,0.00055);_submerged_mid=lerpf(_submerged_mid,white,0.006)
	var heave:=0.72+sin(TAU*0.083*_clock+0.5)*0.15+sin(TAU*0.137*_clock+2.2)*0.09
	if _rng.randf()<0.72/SAMPLE_RATE:_spawn_bubble()
	var pops:=_render_bubbles(dt)
	var surface:=(_surface_low*0.52+(_surface_mid-_surface_low)*0.22)*heave+pops*0.42
	var submerged:=_submerged_low*0.68+(_submerged_mid-_submerged_low)*0.18+pops*0.12
	return Vector2(surface,submerged)*PROCEDURAL_AMBIENCE_GAIN

func _spawn_bubble()->void:
	if _bubble_voices.size()>=5:return
	_bubble_voices.append({"age":0.0,"duration":_rng.randf_range(0.10,0.32),"frequency":_rng.randf_range(48.0,125.0),"phase":_rng.randf_range(0.0,TAU),"gain":_rng.randf_range(0.018,0.05)})

func _render_bubbles(dt:float)->float:
	var result:=0.0
	for index in range(_bubble_voices.size()-1,-1,-1):
		var voice:Dictionary=_bubble_voices[index];var age:float=float(voice["age"])+dt;var duration:float=float(voice["duration"])
		if age>=duration:_bubble_voices.remove_at(index);continue
		voice["age"]=age;var progress:=age/duration;var frequency:float=float(voice["frequency"])*lerpf(0.72,1.08,progress);var phase:float=float(voice["phase"])+TAU*frequency*dt;voice["phase"]=phase;_bubble_voices[index]=voice
		result+=sin(phase)*sin(PI*progress)*exp(-progress*2.3)*float(voice["gain"])
	return result
