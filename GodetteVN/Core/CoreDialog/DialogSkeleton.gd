extends Node2D
class_name DialogSkeleton
# This is not the bare minimum you need to make a dialog system.
# This is a set of general instructions that are currently
# used in GeneralDialog class and should be reusable in other dialog systems I will
# make in the future (and universal in the system)

# Think of this as an interface/abstract class.

export(String, FILE, "*.json") var dialog_json 
export(bool) var debug_mode

export(String, FILE, "*.tscn") var choice_bar = 'res://GodetteVN/Core/ChoiceBar/choiceBar.tscn'
export(String, FILE, "*.tscn") var float_text = 'res://GodetteVN/Core/_Details/floatText.tscn'

# Core data
var current_index : int = 0
var current_block : Array
var current_bname:String = "starter"
var all_blocks:Dictionary
# Dictionary of lists, where each list is a list of events (dictionaries)
# {"starter": [ev1, ev2,...], "branch1":[ev1, ev2,..]}

# Format of choices:
# all_choices = { "c1":[{"a": {'then':"block2"} },{"b":{'then':'block3'},{'c':{'dvar':'...'}]
#		"c2": [... , ...]
# }
# You can decide the format of your choices.


var all_choices:Dictionary

# Format of conditions
# First conditions can be given in the form, where a,b,c,d,e,f are assumed to be dvars.
# ["a > b", "c > d"] means "a > b" and "c > d"
# ["a > b", "or", "c > d"] means "a > b" or "c > d"
# ["a > b", or ["c > d", "e > f"]] means "a > b" or ("c > d" and "e > f")
# all_conditions should look like
# {"cond1": "["a > b", "c > d"]"}
# Then in events, you can put {... , "condition":"cond1"} to make it conditional.
var all_conditions:Dictionary
# Other
var latest_voice:String = ''
var idle : bool = false
var _cur_bgm:String = ''
var _nullify_prev_yield : bool = false
# State controls

var waiting_acc : bool = false
var waiting_cho : bool = false
var one_time_font_change : bool = false
# Dvar Propagation
var _propagate_dvar_list:Dictionary = {}
#----------------------
# Important components
# If you put VNUI and a VNBackground as subnode, you will have all these.
# If you are, for instance, making a cell phone dialog system, then you
# will need to repoint these dialog variables, and maybe you do not want to use
# VNUI.
onready var vnui = $VNUI
onready var cur_db:RichTextLabel = $VNUI/dialogBox/dialogBoxCore
onready var speaker:RichTextLabel = $VNUI/nameBox/speaker
onready var choiceContainer:Control = $VNUI/choiceContainer
onready var stage: Node = $CharacterStage
onready var camera:Camera2D = screen.get_node('camera')
onready var bg:TextureRect = $VNBackground
onready var _u:Node = MyUtils

#-----------------------
# signals
signal player_accept(npv)
signal dvar_set
signal block_ends(bname)
# 
func _ready():
	var _err:int = self.connect("player_accept", self, '_yield_check')
	_err = cur_db.connect('load_next', self, 'check_dialog')
	vn.Pgs.resetControlStates()
#------------------------------ Core --------------------------------
# You need to implement these.
func interpret_events(ev:Dictionary) -> void:
	print(vn.event_reader(ev))

func say(_uid:String, _words:String, _cps:float=0.0, _args:Dictionary={}) -> void:
	pass
	
func generate_chocies(_ev:Dictionary) -> void:
	pass
	
func load_event_at_index(_idx:int) -> void:
	pass

func auto_load_next(_forw:bool=true) -> void:
	pass
	
	
#--------------------------- Game Progression ----------------------------------
func change_block_to(bname:String, bindex:int = 0) -> void:
	if all_blocks.has(bname):
		current_block = all_blocks[bname]
		if bindex >= current_block.size()-1:
			push_error("Cannot go back to the last event of block " + bname + ".")
		else:
			idle = false
			vn.Pgs.currentBlock = bname
			vn.Pgs.currentIndex = bindex
			current_index = bindex
			current_bname = bname
			if debug_mode:
				print("Debug: current block is " + bname)
				print("Debug: current index is " + str(bindex))
			load_event_at_index(current_index)
	else:
		push_error('Cannot find block with the name ' + bname) 
		
func get_target_index(bname : String, target_id):
	for i in range(all_blocks[bname].size()):
		var ev:Dictionary = all_blocks[bname][i]
		if ev.has('id') and (ev['id'] == target_id):
			return i
	print('!!! Cannot find event with id %s in %s, defaulted to index 0.' % [target_id, bname])
	return 0
	
func then(ev:Dictionary) -> void:
	if ev.has('target id'):
		change_block_to(ev['then'], 1 + get_target_index(ev['then'], ev['target id']))
	else:
		change_block_to(ev['then'],0)
	current_bname = ev['then']
	
func check_end_of_block(ind:int) -> bool:
	if ind >= current_block.size():
		emit_signal("block_ends", current_bname)
		return true
	else:
		return false

#----------------------------- Dialog Event Sequence ---------------------------
# ev : the speech event, ques : is this a question (a choice?)
func _parse_speech(ev:Dictionary, ques:bool=false) -> void:
	# Voice will be played first
	var _has_voice:bool = _check_voice(ev)
	# Set up one time font change
	one_time_font_change = ev.has('font')
	if one_time_font_change:
		cur_db.add_font_override('normal_font', load(vn.FONT_DIR + ev['font']))

	# Get actual dialog key value
	# Possible keys for an speech event: 
	# font, voice, choice, wait, speed. 
	var uid:String = "_"
	var combined:String = ""
	var other_keys:Dictionary = {'speed':true,'voice':true,'choice':true,'wait':true,'font':true}
	for k in ev:
		if not k in other_keys:
			uid = express(k)
			combined = k
			break
	if uid == "_":
		print("!!! Speech event uid format error: " + str(ev))
		print("!!! It might be the case that you made a typo and so the event is mistakenly thought "+
			"to be a speech event.")
		push_error("Speech event format error.")
	
	# ques: false -> not a question
	say(uid, ev[combined],_u.has_or_default(ev,'speed',vn.cps), 
		{'ques':ques, 'wait':_u.has_or_default(ev,'wait',0)})
	
func express(combine:String):
	var temp:PoolStringArray = combine.split(" ")
	var uid:String = temp[0]
	if uid in vn.Chs.all_chara:
		uid = vn.Chs.forward_uid(uid)
	else: return "_"
	match temp.size():
		1:pass
		2:stage.change_expression(uid,temp[1])
		_: push_error("!!! What is this? %s" %combine)

	return uid
	
#---------------------- Camera, Character, Background --------------------------
# These are all unnecessary. But if you want to use the rich built in features,
# for camera and characters, and background changes, you can use these functions.
func camera_effect(ev:Dictionary):
	var action : String = ev['camera']
	match action:
		"vpunch", "hpunch", "shake": action = 'shake' 
		"reset", '': action = 'reset'
		"zoom", 'move', 'spin': pass
		_:
			print("!!! Unknown camera event: " + str(ev))
			push_error("Camera effect format error.")
	camera.call("camera_%s"%action, ev)

func character_event(ev:Dictionary) -> void:
	var temp:PoolStringArray = ev['chara'].split(" ")
	if temp.size() != 2:
		push_error('Expecting a uid and an effect name separated by a space.')
	var uid:String = vn.Chs.forward_uid(temp[0]) # uid of the character
	var ef:String = temp[1] # what character effect
	if uid == 'all' or stage.is_on_stage(uid):
		match ef: # jump and shake will be ignored during skipping
			"shake", "vpunch", "hpunch":
				var modes:Dictionary = {"shake":0, "vpunch":1,"hpunch":2}
				ev['mode'] = modes[ef]
				ef = "shake"
			"leave","fadeout","spin","jump", "scale","add":
				pass 
			'move': 
				if ev.has('vamount'):
					ev['loc'] = _parse_loc(ev['vamount']) + stage.get_chara_pos(uid)
			_: 
				push_error('Unknown character event/action: %s' % ev)
		stage.call("character_%s"%ef, uid, ev)
	else: # uid is not all, and character not on stage, must be join or fadein
		if ev.has('loc') and ef in ['join','fadein']:
			stage.call("character_%s"%ef, uid, ev)
		else:
			print("!!! Found unknown character event %s" %ev)
			print("!!! The character " + uid + "is either not on stage or this is not a character "+
				"join/fadein event.")
			print("!!! Is there a typo in your code?")
			push_error("Character event format error.")

# Change background, returns true or false. true: we need to yield, false: no need.
func change_background(ev : Dictionary):
	var path:String = ev['bg']
	if ev.size() == 1 or vn.skipping or vn.inLoading:
		bg.bg_change(path)
		return false
	else: # size > 1
		var eff_name:String=""
		for k in ev:
			if k in vn.TRANSITIONS:
				eff_name = k
				break
		if eff_name == "":
			print("!!! Unknown transition at " + str(ev))
			push_error("Unknown transition type given in bg change event.")
		var eff_dur:float = float(ev[eff_name])/2 # transition effect total duration / 2
		var color:Color = _u.has_or_default(ev, 'color', Color.black)
		clear_boxes()
		screen.screen_transition("full",eff_name,color,eff_dur,path)
		return true

#------------------------------ Related to Dvar --------------------------------
func set_dvar(ev : Dictionary) -> void:
	var og:String = ev['dvar']
	# The order is crucial, = has to be at the end.
	var separators:Array = ["+=","-=","*=","/=", "^=", "="]
	var sep:String = ""
	var splitted:PoolStringArray
	var left:String
	var right:String
	
	# Worse than if else chains, but whatever...
	for s in separators:
		if s in og:
			sep = s
			splitted = og.split(s)
			left = splitted[0].strip_edges()
			right = splitted[1].strip_edges()
			break
	
	if sep == "":
		print("!!! Dvar error: " + str(ev))
		push_error("No assignment found.")
		
	if vn.dvar.has(left):
		if typeof(vn.dvar[left])== TYPE_STRING:
			# If we get string, just set it to RHS
			vn.dvar[left] = right
		else:
			var result = vn.Utils.read(right)
			if result: # right is a string, and returned false
				vn.dvar[left] = result
			else:
				match sep:
					"=": vn.dvar[left] = vn.Utils.calculate(right)
					"+=": vn.dvar[left] += vn.Utils.calculate(right)
					"-=": vn.dvar[left] -= vn.Utils.calculate(right)
					"*=": vn.dvar[left] *= vn.Utils.calculate(right)
					"/=": vn.dvar[left] /= vn.Utils.calculate(right)
					"^=": vn.dvar[left] = pow(vn.dvar[left], vn.Utils.calculate(right))
	else:
		print("!!! Dvar error: " + str(ev))
		push_error("Dvar {0} not found".format({0:left}))
	
	emit_signal("dvar_set")
	propagate_dvar_calls(left)
	
func check_condition(cond_list) -> bool:
	if typeof(cond_list) == TYPE_STRING: # if this is a string, not a list
		cond_list = [cond_list]
	var final_result:bool = true # start by assuming final_result is true
	var is_or:bool = false
	while cond_list.size() > 0:
		var result:bool = false
		var cond = cond_list.pop_front()
		if all_conditions.has(cond):
			cond = all_conditions[cond]
		var type:int = typeof(cond)
		if type == TYPE_STRING:
			if cond in ["or","||"]:
				is_or = true
				continue
			elif vn.dvar.has(cond) and typeof(vn.dvar[cond]) == TYPE_BOOL:
				result = vn.dvar[cond]
				final_result = _a_what_b(is_or, final_result, result)
				is_or = false
				continue
				
			var parsed:PoolStringArray = split_equation(cond)
			var front = parsed[0]
			var rel:String= parsed[1]
			var back= parsed[2]
			front = vn.Utils.calculate(front)
			back = vn.Utils.calculate(back)
			match rel:
				"=", "==": result = (front == back)
				"<=": result = (front <= back)
				">=": result = (front >= back)
				"<": result = (front < back)
				">": result = (front > back)
				"!=": result = (front!= back)
				_: print("Unknown relation %s. Nothing is done." %rel)
			final_result = _a_what_b(is_or, final_result, result)
		elif type == TYPE_ARRAY: # array type
			final_result = _a_what_b(is_or, final_result, check_condition(cond))
		else:
			push_error("Unknown entry in the condition array %s." %cond_list)

		is_or = false
	# If for loop ends, then all conditions must be passed. 
	return final_result
	
func _a_what_b(is_or:bool, a:bool, b:bool)->bool:
	if is_or: return (a or b)
	else: return (a and b)
	
func split_equation(line:String):
	var front_var:String = ''
	var back_var:String = ''
	var rel:String = ''
	var presymbol:bool = true
	for i in line.length():
		var le:String = line[i]
		if le != " ":
			var is_symbol:bool = _u.has_or_default({'>':true,'<':true, '=':true
					,'!':true, '+':true, '-':true, '*':true, '/':true},le,false)
			if is_symbol:
				presymbol = false
				rel += le
			if not (is_symbol) and presymbol:
				front_var += le
			if not (is_symbol) and not presymbol:
				back_var += le
	# Check if back var is an expression or a variable
	return [front_var, rel, back_var]
	
#----------------------------- Special Effect Scenes ---------------------------
func play_sfx(ev : Dictionary) -> void:
	var target_scene:Node = load(vn.ROOT_DIR + ev['sfx']).instance()
	if ev.has('loc'):
		target_scene.set("position", ev['loc'])
	if ev.has('params'):
		target_scene.set("params", ev['params'])
	add_child(target_scene)
	if ev.has('anim'):
		var a:AnimationPlayer = target_scene.get_node_or_null('AnimationPlayer')
		if a and a.has_animation(ev['anim']):
			a.play(ev['anim'])

#-----------------------------Sound, Voice--------------------------------------
func play_sound(ev :Dictionary) -> void:
	if ev.has('delay'):
		_u.schedule_job(music,"play_sound",max(0.05, ev['delay']),[ev['audio'], _u.has_or_default(ev, "vol", 0.0)])
	else:
		music.play_sound(ev['audio'], _u.has_or_default(ev, "vol", 0.0))
	
func play_voice(path:String) -> void:
	music.play_sound(path,0.0,"Voice",vn.VOICE_DIR)
	
func play_bgm(ev:Dictionary) -> void:
	_cur_bgm = ev['bgm']
	var vol:float = 0.0
	var type:String = "linear"
	var _e:bool = false 
	if ev.has('vol'):
		vol = ev['vol']
		_e = ev.erase('vol')
	if ev.has('type'):
		type = ev['type']
		_e = ev.erase('type')
	match ev:
		{'bgm'}:
			if _cur_bgm in ["", "off"]:
				music.stop_bgm()
			else:
				music.play_bgm(_cur_bgm, vol)
		{'bgm','fadein'}:
			if vn.skipping or type == "instant":
				music.play_bgm(_cur_bgm, vol)
			else:
				music.fadein(_cur_bgm, ev['fadein'], vol, type)
		{'bgm','fadeout'}:
			music.fadein(_cur_bgm, ev['fadeout'], vol, type)
		_:
			print("!!! Unknown bgm event: " + str(ev))
			push_error("Unknown bgm event format.")
	if not vn.inLoading: # Track this just in case.
		vn.Pgs.playback_events['bgm'] = {'bgm':_cur_bgm,'vol':vol}
#-------------------------------------------------------------------------------
# Utilities, not very important
func clear_boxes():
	speaker.bbcode_text = ''
	cur_db.bbcode_text = ''

func get_all_dialog_blocks():
	return all_blocks

func register_dvar_propagation(method_name:String, dvar_name:String)->void:
	if vn.dvar.has(dvar_name):
		_propagate_dvar_list[method_name] = dvar_name
	else:
		print("The dvar %s cannot be found. Nothing is done." % dvar_name)

func propagate_dvar_calls(dvar_name:String='')->void:
	# propagate to call all methods that should be called when a dvar is changed. 
	if dvar_name == '':
		for k in _propagate_dvar_list.keys():
			propagate_call(k, [vn.dvar[_propagate_dvar_list[k]]], true)
	else:
		for k in _propagate_dvar_list.keys():
			if _propagate_dvar_list[k] == dvar_name:
				propagate_call(k, [vn.dvar[dvar_name]], true)

# Checks if we need to hide name box. If not, checks uid color and font override.
func _check_hide_namebox(uid:String, check_font:bool=true):
	if not _hide_namebox(uid):
		vnui.namebox_follow_chara(uid)
		var info = vn.Chs.all_chara[uid]
		speaker.set("custom_colors/default_color", info["name_color"])
		speaker.bbcode_text = info["display_name"]
		if check_font and info.has('font') and info['font'] and not one_time_font_change:
			var fonts:Dictionary = {'normal_font': info['normal_font'],
			'bold_font': info['bold_font'],
			'italics_font':info['italics_font'],
			'bold_italics_font':info['bold_italics_font']}
			cur_db.set_chara_fonts(fonts)
		elif not one_time_font_change:
			cur_db.reset_fonts()
	
func _hide_namebox(uid:String):
	if vn.Chs.all_chara.has(uid):
		var info:Dictionary = vn.Chs.all_chara[uid]
		if info.has('no_nb') and typeof(info['no_nb'])==TYPE_BOOL and info['no_nb']:
			$VNUI/nameBox.visible = false
			return true
	return false
	
func _check_voice(ev:Dictionary)->bool:
	latest_voice = _u.has_or_default(ev,'voice','')
	if latest_voice != '' and not vn.skipping:
		play_voice(ev['voice'])
		return true
	return false
	
func _to_hist(has_v:bool, who:String, text:String)->void:
	if has_v: 
		vn.Pgs.updateHistory([who, text, latest_voice])
	else: 
		vn.Pgs.updateHistory([who, text])
		
func _process_inline_symbols(text:String):
	text = vn.Utils.replace_special_symbols(text, "(%(\\d+\\.?\\d+)%)|((?<!\\\\)_)|((?<!\\\\)%)")
	return vn.Utils.replace_special_symbols(text, "(\\\\_)|(\\\\%)")

func dimming(c : Color):
	bg.modulate = c
	stage.set_modulate_all(c)
	
func generate_nullify():
	# Suppose you're in an invetigation scene. Speaker A says something, then 
	# the dialog will enter an yield state and if a player_accept signal comes in, 
	# it will continue. If the signal is generated by generate_nullify(), then
	# the previous yield state will be 'nullified'.
	emit_signal("player_accept", true)

# yield_check, generate_nullify will make npy = true
func _yield_check(npy : bool): # npy = nullily_previous_yield
	_nullify_prev_yield = npy

#---------------------------- Extra Preprocessing -------------------------------
func _parse_loc(loc, ev = {}) -> Vector2:
	var t:int = typeof(loc)
	if t == TYPE_VECTOR2: return loc
	if t == TYPE_STRING and (loc.to_lower() == "r"):
		var v:Vector2 = get_viewport().size
		return MyUtils.random_vec(Vector2(100,v.x-100),Vector2(80,v.y-80))
	# If you get error here, that means the string cannot be split
	# as floats with delimiter space.
	var vec:PoolRealArray = loc.split_floats(" ")
	if vec.size() != 2:
		print("!!! Incorrect loc vector format in event: " + str(ev))
		push_error("!!! 2D vector should have two real numbers separated by a space.")
	return Vector2(vec[0], vec[1])
	
func _parse_dir(dir, ev = {}) -> Vector2:
	if dir in vn.DIRECTION: return vn.DIRECTION[dir]
	elif typeof(dir) == TYPE_STRING and (dir.to_lower() == "r"):
		return MyUtils.random_vec(Vector2(-1,1), Vector2(-1,1)).normalized()
	else:
		return _parse_loc(dir, ev).normalized()

func _parse_color(color, ev = {}) -> Color:
	if typeof(color) == TYPE_COLOR:
		return color
	if color.is_valid_html_color():
		return Color(color)
	else:
		var color_vec:PoolRealArray = color.split_floats(" ", false)
		match color_vec.size():
			3: return Color(color_vec[0], color_vec[1], color_vec[2])
			4: return Color(color_vec[0], color_vec[1], color_vec[2], color_vec[3])
			_:
				print("!!! Error color format: " + str(ev))
				push_error("Expecting value of the form float1 float2 float3( float4) after color.")
		return Color()
		
func _parse_nvl(nvl_state):
	var t:int = typeof(nvl_state)
	if t == TYPE_BOOL:
		return nvl_state
	elif t == TYPE_STRING:
		match nvl_state.to_lower():
			"clear": return nvl_state
			"on", "true":  return true
			"off", "false": return false
			_:
				print("!!! Format error for NVL event.")
				push_error("Expecting either boolean or 'true'/'false','on'/'off' strings.")

func _parse_true_false(truth) -> bool:
	match typeof(truth):
		TYPE_BOOL: return truth
		TYPE_STRING:
			if truth.to_lower() == "true": return true
			else: return false # A little sloppy
		_: return false
		
func _parse_speed(sp):
	match typeof(sp):
		TYPE_REAL,TYPE_INT: return float(sp)
		TYPE_STRING:
			if sp in vn.cps_map:
				return vn.cps_map[sp]
			elif sp.is_valid_float():
				return max(abs(float(sp)),0.015)
			else:
				return vn.cps

# Move this to somewhere else? 
func _notification(what):
	if what == MainLoop.NOTIFICATION_WM_QUIT_REQUEST:
		vn.Notifs.show("quit")

func preprocess(words : String) -> String:
	var leng:int = words.length()
	var output:String = ''
	var inner:String = ""
	var c:String = ''
	var i:int = 0
	while i < leng:
		# Regular Parsing
		c = words[i]
		inner = ""
		if c == '[':
			i += 1
			while words[i] != ']':
				inner += words[i]
				i += 1
				if i >= leng:
					push_error("Please do not use [] unless for bbcode and display dvar purposes.")
			match inner:
				"sm": output += ";"
				"dc": output += "::"
				"nl": output += "\n"
				"lb": output += "["
				"rb": output += "]"
				_: 
					if vn.dvar.has(inner): output += str(vn.dvar[inner])
					else: output += '[' + inner + ']'
		else:
			output += c
		i += 1
		
	return output
