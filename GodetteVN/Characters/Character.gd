extends AnimatedSprite
class_name Character


# Exports
# Character metadata
export(String) var display_name
export(String) var unique_id
export(Color) var name_color = null
export(bool) var in_all = true
export(bool) var apply_highlight = true
export(bool) var fade_on_change = false
export(float, 0.1, 1) var fade_time = 0.6
export(bool) var use_character_font = false
export(String, FILE, '*.tres') var normal_font = ''
export(String, FILE, '*.tres') var bold_font = ''
export(String, FILE, '*.tres') var italics_font = ''
export(String, FILE, '*.tres') var bold_italics_font = ''

var _fading:bool = false
#-----------------------------------------------------
# Character attributes
var loc:Vector2 = Vector2()
var current_expression : String = ""

#-------------------------------------------------------------------------------


func change_expression(e : String, in_fadein:bool=false) -> bool:
	if e == "": e = 'default'
	if in_fadein: modulate.a = 0
	var expFrames:SpriteFrames = get_sprite_frames()
	if expFrames.has_animation(e) or e in ["flip", "flipv"]:
		var prev_exp:String = current_expression
		match e:
			"flip": flip_h = !flip_h
			"flipv": flip_v = !flip_v
			_:
				current_expression = e
				play(e)
		if not in_fadein and not _fading and prev_exp!='': # during fading, no dummy fadeout
			_dummy_fadeout(expFrames, prev_exp)
		return true
	else:
		print("!!! Warning: " + e + ' not found for character with uid ' + unique_id +"---")
		print("!!! Nothing is done.")
		return false

func change_scale(sc:Vector2, t:float, type:String="linear"):
	sc = Vector2(abs(sc.x), abs(sc.y))
	var tween:OneShotTween = OneShotTween.new()
	var _e = tween.interpolate_property(self,'scale',self.scale, sc,t,\
		vn.Utils.movement_type(type), Tween.EASE_IN_OUT)
	add_child(tween)
	_e = tween.start()

func shake(amount: float, time : float, mode = 0):
	# 0 : regular shake, 1 : vpunch, 2 : hpunch
	var _objTimer:ObjectTimer = ObjectTimer.new(self,time,0.02,"_shake_action", [mode,amount])
	add_child(_objTimer)
	
func _shake_action(params): # params[0] = mode, params[1] = amount
	match params[0]:
		0:position = loc + 0.02*MyUtils.random_vec(Vector2(-params[1],params[1]), Vector2(-params[1],params[1]))
		1:position = loc + 0.02*Vector2(loc.x, MyUtils.random_num(-params[1],params[1]))
		2:position = loc + 0.02*Vector2(MyUtils.random_num(-params[1],params[1]), loc.y)
		
# Is there a better way? If I use tween, then position will be locked, and bad news.
func jump(direc:Vector2, amount:float, time:float):
	var step : float = amount/(time/0.04)
	var _objTimer:ObjectTimer = ObjectTimer.new(self,time,0.02,"_jump_action", [direc,step], true)
	add_child(_objTimer)

func _jump_action(params):
	# params[0] = jump_dir, params[1] = step_size, params[-1] = total_counts, params[-2] = counter
	var size:int = params.size()
	if params[size-2] >= params[size-1]/2:
		position -= params[1] * params[0]
	else:
		position += params[1] * params[0]

func fadein(time : float, expression:String=""):
	var _e:bool = change_expression(expression, true)
	_fading = true
	var tween:OneShotTween = OneShotTween.new(self, "set", ["_fading", false])
	add_child(tween)
	var _err:bool = tween.interpolate_property(self, "modulate", Color(0,0,0,0), vn.DIM, time,
		Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	_err = tween.start()
	
func fadeout(t: float):
	vn.Utils.after_image(position, scale, modulate, flip_h, flip_v, rotation_degrees,\
		 get_sprite_frames().get_frame(current_expression,0), t, z_index, self)
	
func spin(sdir:int,deg:float,t:float,type:String="linear"):
	if sdir > 0:  sdir = 1
	else:  sdir = -1
	deg = (sdir*deg)
	var tween:OneShotTween = OneShotTween.new()
	var _err:bool = tween.interpolate_property(self,'rotation_degrees',self.rotation_degrees, self.rotation_degrees+deg,t,\
		vn.Utils.movement_type(type), Tween.EASE_IN_OUT)
	add_child(tween)
	_err = tween.start()

func _dummy_fadeout(expFrames:SpriteFrames, prev_exp:String):
	if fade_on_change and prev_exp != "":
		vn.Utils.after_image(position, scale, modulate, flip_h, flip_v\
			,rotation_degrees, expFrames.get_frame(prev_exp,0), fade_time, z_index)

# Don't ask why this code looks awkward. Ask what Godot does when multiple
# tweens are changing the same property.
func change_pos_2(loca:Vector2, time:float, type:String="linear", expr:String=''):
	self.loc = loca
	var m:int = vn.Utils.movement_type(type)
	var fake:FakeWalker = FakeWalker.new()
	fake.position = position
	stage.add_child(fake)
	var fake_tween:OneShotTween
	if expr == '':
		fake_tween = OneShotTween.new(fake,"queue_free",[])
	else:
		fake_tween = OneShotTween.new(self,"change_expression",[expr])
		var _err:int = fake_tween.connect("tween_all_completed", fake, "queue_free")
	fake.add_child(fake_tween)
	var _e:bool = fake_tween.interpolate_property(fake,"position",position,loca,time,m,Tween.EASE_IN_OUT)
	var _objTimer:ObjectTimer = ObjectTimer.new(self,time,0.01,"_follow_fake",[fake])
	add_child(_objTimer)
	_e = fake_tween.start()

func _follow_fake(params):
	var fake = params[0]
	if is_instance_valid(fake):
		position += fake.get_disp()

func is_fading():
	return _fading
