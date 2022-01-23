extends DialogSkeleton
class_name GeneralDialog

# Specific to general dialog
export(String) var scene_description
export(String, FILE, "*.tscn") var nvl_screen = 'res://GodetteVN/Core/_Details/nvlScene.tscn'
export(bool) var allow_rollback = true

# State controls
var nvl : bool = false
var centered : bool = false
var just_loaded : bool = false
var hide_all_boxes : bool = false
var hide_vnui : bool = false
var no_scroll : bool = false
var no_right_click : bool = false

#----------------------
# QM is needed for general dialog
onready var QM:Node2D = $VNUI/quickMenu
#-----------------------

#--------------------------------------------------------------------------------
	
#--------------------------------- Implementation ----------------------------------
func interpret_events(event:Dictionary):
	# Try to keep the code under each case <=3 lines
	# Also keep the number of cases small. Try to repeat the use of key words.
	var ev:Dictionary = event.duplicate(true)
	if debug_mode: print("Debug :" + str(ev))
	
	# Pre-parse, keep this at minimum
	if ev.has('expr'): ev['expression'] = ev['expr']
	if ev.has('loc'): ev['loc'] = _parse_loc(ev['loc'], ev)
	if ev.has('params'): ev['params'] = vn.Utils.read(ev['params'])
	if ev.has('color'): ev['color'] = _parse_color(ev['color'], ev)
	if ev.has('nvl'): ev['nvl'] = _parse_nvl(ev['nvl'])
	if ev.has('scale'): ev['scale'] = _parse_loc(ev['scale'], ev)
	if ev.has('dir'): ev['dir'] = _parse_dir(ev['dir'], ev)
	# End of pre-parse. Actual match event
	var ev_type:int = vn.event_reader(ev)
	match ev_type:
		-1: _parse_speech(ev)
		0: conditional_branch(ev)
		1:
			if check_condition(ev['condition']):
				var _e:bool = ev.erase('condition')
				interpret_events(ev)
				return
			else: auto_load_next()
		2: screen_effects(ev)
		3: change_background(ev)
		4: .character_event(ev)
		5: change_weather(ev['weather'])
		6: .camera_effect(ev)
		7: express(ev['express'])
		8: .play_bgm(ev)
		9: .play_sound(ev)
		10: .set_dvar(ev)
		11: .play_sfx(ev)
		12: then(ev)
		13: extend(ev)
		14:
			if debug_mode: print("!!! PREMADE EVENT:")
			interpret_events(vn.Utils.call_premade_events(ev['premade']))
			return
		15: system(ev)
		16: side_image_change(ev)
		17: generate_choices(ev)
		18: wait(ev['wait'])
		19: set_nvl(ev)
		20: change_scene_to(ev['GDscene'])
		21: history_manipulation(ev)
		22: flt_text(ev)
		23: .play_voice(ev['voice'])
		24: auto_load_next()
		25: call_method(ev)
		26: set_center(ev)
		_: print("What is this?")
		
	if ev_type in [4,6,7,8,9,10,11,23]: # These are calling parent methods,
		# which lack auto load next. Also, for other methods, it is not
		# advised to use auto_load_next here. There is a big difference
		# between auto_load_next here and after the method execution for some events.
		auto_load_next(!vn.inLoading)
		
func load_event_at_index(ind:int) -> void:
	if check_end_of_block(ind):
		print("Reached the end of block %s, entering an idle state." %[vn.Pgs.currentBlock])
		if self.nvl: nvl_off()
	else:
		if debug_mode:print("Debug: current event index is " + str(current_index))
		interpret_events(current_block[ind])

func auto_load_next(forw:bool=true):
	if forw:
		current_index += 1
		vn.Pgs.currentIndex = current_index
		if vn.skipping:
			yield(get_tree(), "idle_frame")
			if not vn.Pgs.checkSkippable():
				QM.reset_skip()
		load_event_at_index(current_index)

#------------------------------- NVL Dialog ------------------------------
func set_nvl(ev:Dictionary, auto_forw:bool=true):
	if typeof(ev['nvl']) == TYPE_BOOL:
		if ev['nvl']:
			nvl_on(_u.has_or_default(ev,'font',''))
		else: 
			nvl_off()
	elif ev['nvl'] == 'clear':
		cur_db.text = ''
		vn.Pgs.nvl_text = ""
	else:
		print("!!! Wrong nvl event format : %s" %ev)
		push_error('nvl expects a boolean or the keyword clear.')
	auto_load_next(auto_forw and !vn.inLoading)
	
func set_center(ev:Dictionary):
	self.centered = true
	if ev.has('font'):
		set_nvl({'nvl': true,'font':ev['font']}, false)
	else:
		set_nvl({'nvl': true}, false)
	var _has_voice:bool = _check_voice(ev)
	say(_u.has_or_default(ev,"who",""), ev['center'],
		_parse_speed(_u.has_or_default(ev,'speed', vn.cps)),
		{'ques': false, 'wait':_u.has_or_default(ev,'wait',0)})
		
func nvl_off():
	show_boxes()
	if self.nvl:
		cur_db.queue_free()
		cur_db = $VNUI/dialogBox/dialogBoxCore
		bg.modulate = stage.FOCUS
		stage.set_modulate_all()
		self.nvl = false
		self.centered = false

func nvl_on(font:String=''):
	clear_boxes()
	hide_boxes()
	var nvlScene:Node2D = load(nvl_screen).instance()
	cur_db = nvlScene.get_node('nvlBox')
	var _err:int = cur_db.connect('load_next', self, 'check_dialog')
	self.nvl = true
	if font != '':
		cur_db.add_font_override('normal_font', load(vn.ROOT_DIR+font))
	vnui.add_child(nvlScene)
	if centered:
		cur_db.center_mode()
		dimming(stage.CENTER_DIM)
	else:
		dimming(stage.NVL_DIM)
		
#-------------------------------- ADV Dialog -----------------------------------
func generate_choices(ev:Dictionary):
	# make a say event
	if self.nvl: nvl_off()
	else: clear_boxes()
	if vn.auto_on or vn.skipping:
		QM.disable_skip_auto()
	
	_parse_speech(ev, true)
	# Actual choices
	var options:Array = all_choices[ev['choice']]
	waiting_cho = true
	for i in range(options.size()):
		var ev2:Dictionary = options[i]
		match ev2.size():
			1: pass
			2: 
				if ev2.has('condition'):
					if not check_condition(ev2['condition']):
						# Other behaviors?
						continue # skip to the next choice if condition not met
				else:
					push_error('If a choice is size 2, then it has to have a condition.')
			_: push_error('Only size 1 or 2 dict will be accepted as choice.')
		var choice_text:String = ''
		for k in ev2:
			if k != "condition":
				choice_text = k # grab the key not equal to condition
				break
		
		var choice_ev:Dictionary = ev2[choice_text] # the choice action
		choice_text = vn.Utils.MarkUp(choice_text)
		# Preload?
		var choice:Node = load(choice_bar).instance()
		choice.setup_choice(choice_text,choice_ev,vn.show_chosen_choices)
		var _e:int = choice.connect("choice_made", self, "on_choice_made")
		choiceContainer.add_child(choice)
		# waiting for user choice
		
	choiceContainer.visible = true # make it visible now
	
func say(uid:String, words:String, cps:float=vn.cps, args:Dictionary={}):
	words = preprocess(words)
	var use_beep:bool = (latest_voice == '')
	if vn.skipping: cps = 0.0
	if self.nvl: # little awkward. But stable for now.
		if just_loaded:
			just_loaded = false
			if centered:
				cur_db.set_dialog(uid, words, cps, true, use_beep)
			else:
				cur_db.visible_characters = len(cur_db.text)
		else:
			if centered:
				cur_db.set_dialog(uid, words, cps, true, use_beep)
				vn.Pgs.nvl_text = ''
			else:
				cur_db.set_dialog(uid, words, cps, false, use_beep)
				vn.Pgs.nvl_text = cur_db.bbcode_text
			_to_hist(!use_beep and vn.voice_to_history, uid, words)
	else: # Normal dialog / ADV
		_check_hide_namebox(uid, true)
		if just_loaded:
			cur_db.set_dialog(words, cps, false, use_beep)
			just_loaded = false
		else:
			var t:String = _process_inline_symbols(words)
			vn.Pgs.playback_events['speech'] = t
			_to_hist(!use_beep and vn.voice_to_history, uid, t)
			# ---
			cur_db.set_dialog(words, cps, false, use_beep)
		
		stage.set_focus(uid)
	if not args['ques']: # Not a question, enter wait mode.
		wait_for_accept(args['wait'])

func extend(ev:Dictionary):
	# Cannot use extend with a choice, extend doesn't support font
	if vn.Pgs.playback_events['speech'] == '' or self.nvl or self.waiting_cho:
		print("!!! Warning: you're getting his warning either because you're in nvl mode")
		print("!!! Or because you're using extend without a previous speech event.")
		print("!!! Or because you're waiting for a choice to be made.")
		push_error("Unknown to extend dialog.")
	else:
		# get previous speaker from history
		# you will get an error by using extend as the first sentence
		var prev_speaker:String = vn.Pgs.history[-1][0]
		_check_hide_namebox(prev_speaker, false)
		var ext:String = 'extend'
		if ev.has('ext'): ext = 'ext'
		#
		var words:String = preprocess(ev[ext])
		var cps:float = _parse_speed(_u.has_or_default(ev,'speed',vn.cps))
		var use_beep:bool = !_check_voice(ev)
		var t:String = _process_inline_symbols(words)
		_to_hist(!use_beep and vn.voice_to_history, prev_speaker, t)
		if just_loaded:
			just_loaded = false
			cur_db.set_dialog(vn.Pgs.playback_events['speech'], vn.cps, false, use_beep)
			vn.Pgs.history.pop_back()
		else:
			cur_db.bbcode_text = vn.Pgs.playback_events['speech']
			vn.Pgs.playback_events['speech'] += " " + t
			cur_db.set_dialog(words, cps, true, use_beep)
			
		stage.set_focus(prev_speaker)
		# wait for accept
		wait_for_accept(_u.has_or_default(ev,'wait',0))

func wait_for_accept(wt:float=0):
	if wt >= 0.05 and not vn.skipping: # if a wait value is passed, wait and proceed, no interaction
		yield(cur_db, "all_visible")
		_u.schedule_job(self,"check_dialog",wt,[],'auto_dialog_wait')
	waiting_acc = true
	yield(self, "player_accept")
	if _nullify_prev_yield == false: # if this is false, then it's natural dialog progression
		if wt >= 0.05: _u.kill_job('auto_dialog_wait')
		if allow_rollback: vn.Pgs.makeSnapshot()
		if centered: nvl_off()
		if not self.nvl: stage.set_modulate_all()
		waiting_acc = false
		auto_load_next()
	else: # The yield has been nullified, that means some outside code is trying to change dialog blocks
		# in which case, we set this back to default
		_nullify_prev_yield = false

# --------------------------------- Flow Control -------------------------------
func check_dialog():
	if not QM.hiding: QM.visible = true
	if hide_vnui:
		hide_vnui = false
		if self.nvl:
			cur_db.visible = true
			if self.centered: dimming(stage.CENTER_DIM)
			else: dimming(stage.NVL_DIM)
		else:
			show_boxes()
	if cur_db.adding: 
		cur_db.force_finish()
	else: 
		emit_signal("player_accept", false)

func wait(time : float) -> void:
	if just_loaded: just_loaded = false
	if not vn.skipping and time >= 0.05:
		yield(get_tree().create_timer(time), "timeout")
	auto_load_next(!vn.inLoading)
	
func on_choice_made(ev : Dictionary, rollback_to_choice:bool = true) -> void:
	# rollback_to_choice is only used when called externally.
	QM.enable_skip_auto()
	_u.free_children(choiceContainer)
	if allow_rollback:
		if rollback_to_choice:
			vn.Pgs.makeSnapshot()
		else:
			vn.Pgs.rollback_records.clear()
	waiting_cho = false
	choiceContainer.visible = false
	interpret_events(ev)

func on_rollback(): # First prepare to rollback... ...
	QM.reset_auto_skip()
	if vn.Pgs.rollback_records.size() >= 1:
		waiting_acc = false
		if idle: # This if branch is needed because of how just_loaded works.
			# Notice (waiting_acc or idle). Ususally player can only rollback when waiting_acc, but
			# idle is the exception. So here we need to treat this a little differently.
			idle = false
		else:
			vn.Pgs.history.pop_back()
		screen.clean_up()
		vnui.set_side_image()
		camera.camera_reset()
		waiting_cho = false
		nvl_off()
		_u.free_children(choiceContainer)
		generate_nullify()
	else: # Show to readers that they cannot rollback further
		vn.Notifs.show('rollback')
		return
	#--------Actually rollback----------
	var last:Dictionary = vn.Pgs.rollback_records.pop_back()
	vn.dvar = last['dvar']
	propagate_dvar_calls()
	vn.Pgs.currentSaveDesc = last['currentSaveDesc']
	vn.Pgs.currentIndex = last['currentIndex']
	vn.Pgs.currentBlock = last['currentBlock']
	vn.Pgs.playback_events = last['playback']
	vn.Chs.chara_name_patch = last['name_patches']
	vn.Chs.patch_display_names()
	current_bname = vn.Pgs.currentBlock
	current_index = vn.Pgs.currentIndex
	current_block = all_blocks[vn.Pgs.currentBlock]
	load_playback(vn.Pgs.playback_events, true)
	load_event_at_index(current_index)
	
func load_playback(play_back:Dictionary, RBM:bool = false): # Roll Back Mode
	vn.inLoading = true
	if play_back.has('bg'):
		bg.bg_change(play_back['bg'])
	if play_back.has('bgm'):
		var bgm = play_back['bgm']
		if RBM:
			if _cur_bgm != bgm['bgm']:
				.play_bgm(bgm)
		else:
			.play_bgm(bgm)
	if play_back.has('screen'):
		screen_effects(play_back['screen'])
	if play_back.has('camera'):
		camera.set_camera(play_back['camera'])
	if play_back.has('weather'):
		change_weather(play_back['weather']['weather'])
	if play_back.has('side'):
		side_image_change(play_back['side'])
		
	var ctrl_state:Dictionary = play_back['control_state']
	for k in ctrl_state:
		if ctrl_state[k]:
			system({'system': k + " on"})
		else:
			system({'system': k + " off"})
	
	var onStageCharas:Array = []
	for d in play_back['charas']:
		if RBM:
			onStageCharas.push_back(d['uid'])
			if stage.is_on_stage(d['uid']):
				stage.character_move(d['uid'], {'loc':_parse_loc(d['loc'])})
				stage.change_expression(d['uid'], d['expression'])
			else:
				stage.character_join(d['uid'],{'loc': d['loc'], 'expression':d['expression']})
		else:
			stage.character_join(d['uid'],{'loc':d['loc'], 'expression':d['expression']})
		
		stage.set_flip(d['uid'],d['fliph'],d['flipv'])
		stage.character_scale(d['uid'],{'scale':d['scale'], 'type':"instant"})
		stage.character_spin(d['uid'], {'deg':d['deg'], 'type':'instant'})
	if RBM: stage.remove_not_in(onStageCharas)
	
	if play_back['nvl'] != '':
		nvl_on()
		vn.Pgs.nvl_text = play_back['nvl']
		cur_db.bbcode_text = vn.Pgs.nvl_text
	
	vn.inLoading = false
	just_loaded = true

#------------------- Related to Background and Godot Scene Change ----------------------
func change_background(ev : Dictionary):
	var need_2_yield:bool = .change_background(ev)
	vn.Pgs.playback_events['bg'] = ev['bg']
	if need_2_yield:
		yield(screen,"transition_finished")
	auto_load_next(!vn.inLoading)

#----------------------------- Screen and Camera effects-----------------------
func screen_effects(ev: Dictionary):
	var temp:Array = ev['screen'].split(" ")
	var ef:String = temp[0]
	match ef:
		"", "off": 
			screen.removeLasting()
			vn.Pgs.playback_events.erase('screen')
		"tint", "tintwave": tint(ev) # lasting
		"flashlight": flashlight(ev) # lasting
		_: # transcient
			if len(temp)==2 and not vn.skipping and ef in vn.TRANSITIONS:
				var mode:String = temp[1]
				var c:Color = _u.has_or_default(ev, "color", Color.black)
				var t:float = _u.has_or_default(ev,"time",1.0)
				if mode == "out": # this might be a bit counter-intuitive
					# but we have to stick with this
					screen.screen_transition('in',ef,c,t)
					yield(screen, "transition_mid_point_reached")
				elif mode == "in":
					screen.screen_transition('out',ef,c,t)
					yield(screen, "transition_finished")
			screen.reset()
	auto_load_next(!vn.inLoading)

func flashlight(ev:Dictionary):
	screen.flashlight(_u.has_or_default(ev, 'scale', Vector2(1,1)))
	vn.Pgs.playback_events['screen'] = ev

func tint(ev : Dictionary) -> void:
	screen.call(ev['screen'], _u.has_or_default(ev,'color',Color()),\
		_u.has_or_default(ev,'time',1.0))
	if ev['screen'] == "tint" : ev['time'] = 0.05
	vn.Pgs.playback_events['screen'] = ev

#--------------------------------- Weather -------------------------------------
func change_weather(we:String):
	screen.show_weather(we) # If given weather doesn't exist, nothing will happen
	if we in ["", "off"]:
		vn.Pgs.playback_events.erase('weather')
	else:
		vn.Pgs.playback_events['weather'] = {'weather':we}
	auto_load_next(!vn.inLoading)

#--------------------------------- History -------------------------------------
func history_manipulation(ev: Dictionary):
	# WARNING: 
	# THIS DOES NOT WORK WELL WITH CURRENT IMPLEMENTATION OF ROLLBACK
	var what:String = ev['history']
	if what == "push":
		if ev.size() != 2:
			print("!!! History event format error " + str(ev))
			push_error("History push should have only two fields.")
		
		for k in ev:
			if k != 'history':
				vn.Pgs.updateHistory([k, vn.Utils.MarkUp(ev[k])])
				break
	elif what == "pop":
		vn.Pgs.history.pop_back()
	else:
		print("!!! History event format error " + str(ev))
		push_error("History expects only push or pop.")
	auto_load_next(!vn.inLoading)

#----------------------------- Miscellaneous ----------------------------------
func conditional_branch(ev : Dictionary) -> void:
	if check_condition(ev['condition']):
		change_block_to(ev['then'],0)
	else:
		change_block_to(ev['else'],0)

func then(ev:Dictionary) -> void:
	if vn.Files.system_data.has(vn.Pgs.currentNodePath):
		if current_index > vn.Files.system_data[vn.Pgs.currentNodePath][current_bname]:
			vn.Files.system_data[vn.Pgs.currentNodePath][current_bname] = current_index
	elif dialog_json != '' and vn.Files.system_data.has(dialog_json):
		if current_index > vn.Files.system_data[dialog_json][current_bname]:
			vn.Files.system_data[dialog_json][current_bname] = current_index
	.then(ev)

func side_image_change(ev:Dictionary):
	var path:String = ev['side']
	var sideImage:Sprite = vnui.get_node('other/sideImage')
	if path == "":
		sideImage.texture = null
		vn.Pgs.playback_events.erase('side')
	else:
		sideImage.texture = load(vn.SIDE_IMAGE+path)
		vn.Pgs.playback_events['side'] = ev
		vnui.set_side_image(_u.has_or_default(ev,'scale',Vector2(1,1)),\
			_u.has_or_default(ev,'loc',Vector2(-35, 530)))
	auto_load_next(!vn.inLoading)

func flt_text(ev: Dictionary) -> void:
	var wt:float = ev['wait']
	ev['float'] = vn.Utils.MarkUp(ev['float'])
	var loc:Vector2 = _u.has_or_default(ev,'loc', Vector2(600,300))
	var in_t:float = _u.has_or_default(ev, 'fadein', 1)
	var f:FloatText = load(float_text).instance()
	if ev.has('font') and ev['font'] != "" and ev['font'] != "default":
		f.set_font(vn.ROOT_DIR+ev['font'])
	if ev.has('dir'):
		f.set_movement(ev['dir'], _u.has_or_default(ev,'speed', 30))
	add_child(f)
	if ev.has('time') and ev['time'] > wt:
		f.display(ev['float'], ev['time'], in_t, loc)
	else:
		f.display(ev['float'], wt, in_t, loc)
	
	var has_voice:bool = _check_voice(ev)
	if ev.has('hist') and (_parse_true_false(ev['hist'])):
		_to_hist((has_voice and vn.voice_to_history), _u.has_or_default(ev,'who',''), ev['float'] )
	wait(wt)

func hide_UI(show:bool=false):
	if show:
		hide_vnui = false
	else:
		hide_vnui = ! hide_vnui 
	if hide_vnui:
		QM.visible = false
		hide_boxes()
		if self.nvl:
			cur_db.visible = false
			dimming(stage.FOCUS)
	else:
		if not QM.hiding: QM.visible = true
		if self.nvl:
			cur_db.visible = true
			if self.centered: 
				dimming(stage.CENTER_DIM)
			else: 
				dimming(stage.NVL_DIM)
		else:
			show_boxes()

func hide_boxes():
	hide_all_boxes = true
	$VNUI/dialogBox.visible = false
	$VNUI/nameBox.visible = false
	
func show_boxes():
	if hide_all_boxes:
		$VNUI/dialogBox.visible = true
		$VNUI/nameBox.visible = true
		hide_all_boxes = false
	
func call_method(ev:Dictionary):
	# rollback and save are not taken care of.
	callv(ev['call'], _u.has_or_default(ev,'params',[]))
	auto_load_next(!vn.inLoading)

func system(ev : Dictionary):
	if ev.size() != 1:
		print("--- Warning: wrong system event format for " + str(ev)+" ---")
		push_error("---System event only receives one field.---")
	
	var k:String = ev.keys()[0]
	var temp:PoolStringArray = ev[k].split(" ")
	match temp[0]:
		"auto": # You cannot turn auto on.
			# Simply turns off dialog auto forward if somehow it is on.
			if temp[1] == "off": QM.reset_auto()
			
		"skip": # same as above
			if temp[1] == "off": QM.reset_skip()
				
		"clear": clear_boxes()
			
		"rollback", "roll_back" ,"RB":
			# Example {system: RB clear} clears all rollback saves
			# {system: RB clear_3} clears last 3 rollback saves
			if temp[1] == "clear":
				vn.Pgs.rollback_records.clear()
			else:
				var splitted:PoolStringArray = temp[1].split('_')
				if splitted[0] == 'clear' and splitted[1].is_valid_integer():
					for _i in range(int(splitted[1])):
						vn.Pgs.rollback_records.pop_back()
		"auto_save", "AS": # make a save, with 0 seconds delay, and save
			# at current index - 1 because the current event is sys:auto_save
			# Only place this immediately after a dialog to avoid unexpected errors.
			vn.Utils.make_a_save("[Auto Save] ",0,1)
		"make_save", "MS":
			QM.reset_auto_skip()
			vn.Notifs.show("make_save")
			yield(vn.Notifs.get_current_notif(), "clicked")

		# The above are not included in 'all'.
		"right_click", "RC":
			if temp[1] == "on":
				no_right_click = false
			elif temp[1] == "off":
				no_right_click = true
			vn.Pgs.control_state['right_click'] = no_right_click
				
		"quick_menu", "QM":
			if temp[1] == "on":
				QM.visible = true
				QM.hiding = false
				vn.Pgs.control_state['quick_menu'] = true
			elif temp[1] == "off":
				QM.visible = false
				QM.hiding = true
				vn.Pgs.control_state['quick_menu'] = false
		
		"boxes":
			if temp[1] == "on":
				show_boxes()
				vn.Pgs.control_state['boxes'] = true
			elif temp[1] == "off":
				hide_boxes()
				vn.Pgs.control_state['boxes'] = false
				
		"scroll":
			if temp[1] == "on":
				no_scroll = false
			elif temp[1] == "off":
				no_scroll = true
			vn.Pgs.control_state['scroll'] = !no_scroll 
				
		"all":
			if temp[1] == "on":
				no_scroll = false
				QM.visible = true
				QM.hiding = false
				no_right_click = false
				show_boxes()
				vn.Pgs.resetControlStates()
			elif temp[1] == "off":
				no_scroll = true
				QM.visible = false
				QM.hiding = true
				no_right_click = true
				hide_boxes()
				vn.Pgs.resetControlStates(false)
	auto_load_next(!vn.inLoading)
	
#------------------------------- Change Godot Scene -----------------------------
func change_scene_to(path : String):
	stage.clean_up()
	vnui.set_side_image()
	change_weather('')
	QM.reset_auto_skip()
	print("You are changing scene. Rollback will be cleared. It's a good idea to explain "+\
	"to the player the rules about rollback.")
	vn.Pgs.rollback_records.clear()
	if path in [vn.title_screen_path, vn.ending_scene_path] or path.to_lower() in ['title','ending']:
		music.stop_bgm()
		var _err:int = get_tree().change_scene(vn.ROOT_DIR + path)
	elif path == "free":
		music.stop_bgm()
		queue_free()
	else:
		var _err:int = get_tree().change_scene(vn.ROOT_DIR + path)

#--------------------------------- Player Input ----------------------------------
func _input(ev:InputEvent):
	if ev.is_action_pressed('vn_refresh') and not (OS.has_feature('standalone') \
		or vn.inNotif or vn.skipping or vn.inSetting):
			_refresh_script()
			return
	if ev.is_action_pressed('vn_rollback') and (waiting_acc or idle or waiting_cho) and not (vn.inSetting or\
		vn.inNotif or vn.skipping ) and allow_rollback:
		on_rollback()
		return
	if ev.is_action_pressed('vn_upscroll') and not (vn.inSetting or vn.inNotif or no_scroll):
		QM.on_historyButton_pressed() # bad name... but lol
		return
	# QM hiding means that quick menu is being hidden. If that is the case,
	# then the user probably wants to disable access to main menu too.
	if ev.is_action_pressed('ui_cancel') and not (vn.inSetting or vn.inNotif or QM.hiding):
		add_child(vn.MAIN_MENU.instance())
		return
	if waiting_cho:
		# Waiting for a choice. Do nothing. Any input will be nullified.
		# In a choice event, game resumes only when a choice button is selected.
		return
	if ev.is_action_pressed('vn_cancel') and not (vn.inNotif or vn.inSetting or no_right_click):
		hide_UI()
		return
	# Can I simplify this?
	if (ev.is_action_pressed("ui_accept") or ev.is_action_pressed('vn_accept')) and waiting_acc:
		if hide_vnui:
			hide_UI(true) # Show UI
		# vn_accept is mouse left click
		if ev.is_action_pressed('vn_accept'): # mouse
			if vn.auto_on or vn.skipping:
				if not vn.noMouse:
					QM.reset_auto_skip()
			else:
				if not (vn.noMouse or vn.inNotif or vn.inSetting):
					check_dialog()
		else: # not mouse
			if vn.auto_on or vn.skipping:
				cur_db.force_finish()
				QM.reset_auto_skip()
			if not (vn.inNotif or vn.inSetting):
				check_dialog()
				
#---------------------------- new game, load, set up, end ----------------------
func auto_start(start_block:String="starter", start_id=null):
	var load_instr:String = vn.Pgs.load_instruction
	print("!!! Beta Notice: auto_start currently only works if you use json files for dialog. ---")
	if not (load_instr in ["new_game", "load_game"]):
		print("!!! Unknown load instruction. It can either be new_game or load_game.")
		return false
	
	if self.dialog_json == "":
		print("!!! For auto_start, you need to provide a dialog json file.")
		return false
	else:
		var dialog_data = vn.Files.load_json(dialog_json)
		if dialog_data.has_all(['Dialogs', 'Choices']):
			var cond:Dictionary = _u.has_or_default(dialog_data,'Conditions',{})
			start_scene(dialog_data['Dialogs'],dialog_data['Choices'],cond, load_instr,\
				start_block, start_id)
			return true
		else:
			print("Dialog json file must contain 'Dialogs' and 'Choices' (even if empty).")
			return false
		
func start_scene(blocks : Dictionary, choices: Dictionary, conditions: Dictionary,\
	load_instr:String = "new_game", start_block:String="starter", start_id=null) -> void:
	# blocks: A dictionary, with keys being names for your dialogs, and values being
	# an array of events.
	# choices: A dictionary, with keys being the name for this choice, and values being
	# an array of options corresponding to this choice
	# conditions: A dictionary, with keys being the name for this condition, and values
	# being any type of boolean expression that can be evaludated by the system. 
	vn.Scene = self
	all_blocks.clear()
	all_choices.clear()
	all_conditions.clear()
	get_tree().set_auto_accept_quit(false)
	vn.Pgs.currentSaveDesc = scene_description
	vn.Pgs.currentNodePath = get_tree().current_scene.filename
	all_blocks = blocks
	all_choices = choices
	all_conditions = conditions
	if load_instr == "new_game":
		if start_id:
			current_index = get_target_index(start_block,start_id)
		else:
			current_index = 0
		if blocks.has(start_block):
			current_block = blocks[start_block]
		else:
			push_error("Start block %s not found." % start_block)
		current_bname = start_block
		vn.Pgs.currentIndex = current_index
		vn.Pgs.currentBlock = start_block # this is the name corresponding to the array
	elif load_instr == "load_game":
		vn.Pgs.load_instruction = "new_game" # reset after loading
		current_index = vn.Pgs.currentIndex
		current_bname = vn.Pgs.currentBlock
		current_block = all_blocks[vn.Pgs.currentBlock]
		load_playback(vn.Pgs.playback_events)
	else:
		push_error("Unknow loading instruction")
	
	if music.bgm != '': _cur_bgm = music.bgm
	if debug_mode: print("Debug: current block is " + vn.Pgs.currentBlock)
	load_event_at_index(current_index)

# Only works in editor, not in exported game.
func _refresh_script():
	if dialog_json != '' and (waiting_acc or waiting_cho):
		if allow_rollback:
			var new_data = vn.Files.load_json(dialog_json)
			if new_data.has_all(['Dialogs', 'Choices']):
				print("!!! All rollback records not in this block 'slice' will be removed.")
				vn.Pgs.remove_nonmatch_records()
				var d_blocks:Dictionary = new_data['Dialogs']
				# Check if current is still a dialog event in new script.
				if vn.event_reader(d_blocks[vn.Pgs.currentBlock][vn.Pgs.currentIndex]) != -1:
					print("!!! Refresh failed.")
					print("!!! It seems like you added or removed some events. "+\
						"You will have to restart the game to see the changes.")
					print("!!! This functionality is only intended for checking adjustments for "+\
						"existing events. Adding or removing may cause side effects.")
					return
				# Check if all available rollback record indices corersponds to 
				# dialogs in new script. If not, that means some new events got
				# injected and for safety reasons, don't allow refresh. 
				for ev in vn.Pgs.rollback_records:
					var bname:String = ev['currentBlock']
					var idx:int = ev['currentIndex']
					var ev_type:int = vn.event_reader(d_blocks[bname][idx])
					if ev_type == 1:
						var double_check:Dictionary = d_blocks[bname][idx].duplicate()
						var _e : bool = double_check.erase('condition')
						if vn.event_reader(double_check) == -1:
							continue 
					if ev_type != -1:
						print("!!! Refresh failed.")
						print("!!! It seems like you added or removed some events. "+\
							"You will have to restart the game to see the changes.")
						print("!!! This functionality is only intended for checking adjustments for "+\
							"existing events. Adding or removing may cause side effects.")
						return
						
				# Passes all the basic checks.
				waiting_cho = false
				waiting_acc = false
				vn.Pgs.update_playback() # What about in nvl mode?
				stage.character_leave('absolute_all')
				vn.Pgs.history.clear()
				_u.free_children(choiceContainer)
				generate_nullify()
				var cond:Dictionary = _u.has_or_default(new_data,'Conditions',{})
				start_scene(d_blocks, new_data['Choices'], cond, 'load_game',\
					vn.Pgs.currentBlock, vn.Pgs.currentIndex)
				print("!!! Refresh success.") 
				print("!!! History is cleaned because this functionality "+\
					"should only be used in a test setting.")
				
			else:
				print("!!! Refresh failed.")
				print("Dialog json file must contain 'Dialogs' and 'Choices' (even if empty).")
		else:
			print("!!! Refresh failed.")
			print("!!! This feature only works when allow_rollback is set to true.")
			print("!!! This is to prevent breaking the game by loading an updated script.")
		
	
