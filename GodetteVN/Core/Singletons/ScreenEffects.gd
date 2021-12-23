extends CanvasLayer

signal transition_started
signal transition_mid_point_reached
signal transition_finished

var transition_data : Resource = null setget _set_transition_data, _get_transition_data

var _casted_transition_data : eh_TransitionData = null

onready var _color_panel: ColorRect = $eh_Transitions
onready var _animator: AnimationPlayer = $eh_Transitions/AnimationPlayer
onready var _shader: ShaderMaterial = _color_panel.material
#------------------------------------------------------------------------


const all_weathers:Dictionary = {
	'rain': "res://GodetteVN/Core/_Details/Weathers/rain.tscn",
	'snow': "res://GodetteVN/Core/_Details/Weathers/snow.tscn",
	'light': "res://GodetteVN/Core/_Details/Weathers/light.tscn",
	'dust': "res://GodetteVN/Core/_Details/Weathers/dust.tscn"
}

#--------------------------------------------------------------------------------------------------

func _ready(): # turn off everything on ready
	clean_up()
	
func show_weather(w_name:String):
	MyUtils.free_children($weather) # Weather is exclusive
	var w:Node = get_node("weather")
	if all_weathers.has(w_name):
		w.add_child(load(all_weathers[w_name]).instance())

func removeLasting():
	for n in $lasting.get_children():
		n.call_deferred('free')


func tint(c: Color,t : float):
	removeLasting()
	var tint:Node = load("res://GodetteVN/Core/_Details/tintRect.tscn").instance()
	$lasting.add_child(tint)
	tint.set_tint(c, t)
	
func tintWave(c: Color, t : float):
	removeLasting()
	var tint:Node = load("res://GodetteVN/Core/_Details/tintRect.tscn").instance()
	$lasting.add_child(tint)
	tint.set_tintwave(c, t)
	
func flashlight(sc : Vector2):
	removeLasting()
	var fl_scene:Node = load("res://GodetteVN/SpecialScenes/flashLightScreen.tscn").instance()
	$lasting.add_child(fl_scene)
	fl_scene.scale = sc
	
func screen_transition(mode:String, eff_name:String,color:Color,eff_dur:float,bg_path:String=''):
	if not (mode in ['full', 'in', 'out']):
		push_error("Transition mode can only be full, in, or out.")
	
	var func_identifer:String = "transition" 
	var params:Array = []
	match eff_name:
		"fade":
			func_identifer = eff_name
			params.append_array([color, eff_dur])
		"pixelate":
			func_identifer = eff_name
			params.append(eff_dur)
		_:
			_setup_transition_data(eff_name,color,eff_dur)
	
	if mode == "full":
		params.append(bg_path)
		call("play_%s_%s" %[func_identifer,mode], params)
	else:
		call("play_%s_%s" %[func_identifer,mode], params)

func reset():
	_color_panel.visible = false
	
#func set_debug(debug:bool, text:String=""):
#	var debugger = get_node_or_null("debugger")
#	if debugger:
#		if debug == false:
#			debugger.queue_free()
#		else:
#			debugger.text = text
		
func clean_up():
	removeLasting()
	MyUtils.free_children($weather)

### eh's Public Methods --------------------------------------------------------------------------------

func play_transition_in(_p=[]) -> void:
	_color_panel.visible = true
	_play_in_animation(
			_casted_transition_data.transition_in,
			_casted_transition_data.color,
			_casted_transition_data.duration
	)

func play_transition_out(_p=[]) -> void:
	_color_panel.visible = true
	_play_out_animation(
			_casted_transition_data.transition_out,
			_casted_transition_data.color,
			_casted_transition_data.duration
	)

func play_transition_full(params:Array) -> void:
	_color_panel.visible = true
	if _animator.is_playing():
		_raise_multiple_transition_error()
		return
	
	if vn.Scene:
		vn.Scene.hide_boxes()
		vn.Scene.QM.visible = false
	play_transition_in()
	yield(self, "transition_mid_point_reached")
	if vn.Scene:
		vn.Scene.bg.bg_change(params[0])
	play_transition_out()
	if vn.Scene:
		vn.Scene.show_boxes()
		if not vn.Scene.QM.hiding: 
			vn.Scene.QM.visible = true


func play_fade_in(params:Array) -> void:
	_play_in_animation("fade_in", params[0], params[1])

func play_fade_out(params:Array) -> void:
	_play_out_animation("fade_out", params[0], params[1])

func play_fade_full(params:Array) -> void:
	# Values in params
	# 0 : color
	# 1 : duration
	# 2 : bgpath
	if _animator.is_playing():
		_raise_multiple_transition_error()
		return
	
	if vn.Scene:
		vn.Scene.hide_boxes()
		vn.Scene.QM.visible = false
	play_fade_in([params[0], params[1]])
	if vn.Scene:
		vn.Scene.bg.bg_change(params[2])
	yield(self, "transition_mid_point_reached")
	play_fade_out([params[0], params[1]])
	if vn.Scene:
		vn.Scene.show_boxes()
		if not vn.Scene.QM.hiding: 
			vn.Scene.QM.visible = true
			
func play_pixelate_in(params:Array):
	# 0 : duration
	var r:Node = load("res://GodetteVN/Core/_Details/transitionRect.tscn").instance()
	add_child(r)
	r.pixelate_in(params[0])

func play_pixelate_out(params:Array):
	var r:Node = load("res://GodetteVN/Core/_Details/transitionRect.tscn").instance()
	add_child(r)
	r.pixelate_out(params[0])
	
func play_pixelate_full(params:Array)->void:
	# params
	# 0 : duration
	# 1 : bg_path
	if vn.Scene:
		vn.Scene.hide_boxes()
		vn.Scene.QM.visible = false
	play_pixelate_in([params[0]])
	yield(self,"transition_mid_point_reached")
	if vn.Scene:
		vn.Scene.bg.bg_change(params[1])
	play_pixelate_out([params[0]])
	if vn.Scene:
		vn.Scene.show_boxes()
		if not vn.Scene.QM.hiding: 
			vn.Scene.QM.visible = true

func change_transition_data_oneshot(data: eh_TransitionData) -> void:
	var backup_transition: eh_TransitionData = transition_data
	_set_transition_data(data)
	yield(self, "transition_finished")
	_set_transition_data(backup_transition)


func is_transitioning_in() -> bool:
	var is_fade_in = (
			_animator.assigned_animation == "fade_in"
			or _animator.assigned_animation == "reversed_in"
			or _animator.assigned_animation == "transition_in"
	)
	return _animator.is_playing() and is_fade_in


func is_transitioning_out() -> bool:
	var is_fade_out = (
			_animator.assigned_animation == "fade_out"
			or _animator.assigned_animation == "reversed_out"
			or _animator.assigned_animation == "transition_out"
	)
	return _animator.is_playing() and is_fade_out
	

#--------------------------------------------------------------------------------
### eh's Private Methods -------------------------------------------------------------------------------
func _setup_transition_data(eff_name:String, color:Color, eff_dur:float):
	var t_data = load(vn.TRANSITIONS_DIR+eff_name+".tres")
	t_data.duration = eff_dur
	t_data.color = color
	if t_data != null and t_data is eh_TransitionData:
		change_transition_data_oneshot(t_data)

func _play_in_animation(animation : String, color: Color, duration: float) -> void:
	if _animator.is_playing():
		_raise_multiple_transition_error()
		return
	
	_color_panel.color = color
	_set_playback_speed(duration)
	
	emit_signal("transition_started")
	_animator.play(animation)
	yield(_animator, "animation_finished")
	emit_signal("transition_mid_point_reached")


func _play_out_animation(animation : String, color: Color, duration: float) -> void:
	if _animator.is_playing():
		_raise_multiple_transition_error()
		return
	
	_color_panel.color = color
	_set_playback_speed(duration)
	_animator.play(animation)
	
	yield(_animator, "animation_finished")
	emit_signal("transition_finished")
	_color_panel.visible = false


func _set_playback_speed(duration: float) -> void:
	_animator.playback_speed = 1.0 / duration

func _set_transition_data(data : eh_TransitionData) -> void:
	if data == null:
		return
	
	transition_data = data
	_casted_transition_data = transition_data as eh_TransitionData
	
	if _shader != null:
		_shader.set_shader_param("mask", _casted_transition_data.mask)
		_shader.set_shader_param("smooth_size", _casted_transition_data.smooth_size)

func _get_transition_data() -> eh_TransitionData:
	if _casted_transition_data != null:
		return _casted_transition_data
	else:
		return null

func _raise_multiple_transition_error() -> void:
	push_error("A new transition is being called while another one is playing")
	# If you're in Debug or this is intended, press F12 or the continue 
	# button in the debugger to continue
	assert(false)

### -----------------------------------------------------------------------------------------------
