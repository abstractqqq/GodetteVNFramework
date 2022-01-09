extends DialogSkeleton
class_name LiteDialog


#--------------------------------- Implementation ----------------------------------
func load_event_at_index(ind:int) -> void:
	if ind >= current_block.size():
		print("Reached the end of block %s, entering an idle state." %[vn.Pgs.currentBlock])
		idle = true
	else:
		if debug_mode:print("Debug: current event index is " + str(current_index))
		interpret_events(current_block[ind])

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
		3: 
			.change_background(ev)
			yield(screen, "transition_finished")
			auto_load_next(!vn.inLoading)
			return
		4: .character_event(ev)
		5: change_weather(ev['weather'])
		6: .camera_effect(ev)
		7: express(ev['express'])
		8: .play_bgm(ev)
		9: .play_sound(ev)
		10: .set_dvar(ev)
		11: .play_sfx(ev)
		12: .then(ev) # No need to auto_load_next
		13: extend(ev)
		14:
			if debug_mode: print("!!! PREMADE EVENT:")
			interpret_events(vn.Utils.call_premade_events(ev['premade']))
			return
		15: _warning()
		16: _warning()
		17: generate_choices(ev)
		18: wait(ev['wait'])
		19: _warning()
		20: change_scene_to(ev['GDscene'])
		21: _warning()
		22: _warning()
		23: .play_voice(ev['voice'])
		24: auto_load_next()
		25: _warning()
		26: _warning()
		_: print("What is this?")
		
	if ev_type in [4,6,7,8,9,10,11,23]: # See comment in GeneralDialog
		auto_load_next(!vn.inLoading)

func auto_load_next(forw:bool=true):
	if forw:
		current_index += 1
		yield(get_tree(), "idle_frame")
		load_event_at_index(current_index)

#-------------------------------- ADV Dialog -----------------------------------
func generate_choices(ev:Dictionary):
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
	_check_hide_namebox(uid, true)

	cur_db.set_dialog(words, cps, false, use_beep)
	var t:String = _process_inline_symbols(words)
	# Need to track this 
	vn.Pgs.playback_events['speech'] = t
	# Keeps history just in case
	_to_hist(!use_beep and vn.voice_to_history, uid, t)
	stage.set_highlight(uid)
	wait_for_accept(args['wait'])

func extend(ev:Dictionary):
	# Cannot use extend with a choice, extend doesn't support font
	if vn.Pgs.playback_events['speech'] == '' or self.waiting_cho:
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

		cur_db.bbcode_text = vn.Pgs.playback_events['speech']
		cur_db.set_dialog(words, cps, true, use_beep)
		
		# Need to track this 
		vn.Pgs.playback_events['speech'] += " " + t
			
		stage.set_highlight(prev_speaker)
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
		waiting_acc = false
		auto_load_next()
	else: # The yield has been nullified, that means some outside code is trying to change dialog blocks
		# in which case, we set this back to default
		_nullify_prev_yield = false

# --------------------------------- Flow Control -------------------------------
func check_dialog():
	if cur_db.adding: 
		cur_db.force_finish()
	else: 
		emit_signal("player_accept", false)

func wait(time : float) -> void:
	if not vn.skipping and time >= 0.05:
		yield(get_tree().create_timer(time), "timeout")
	auto_load_next(!vn.inLoading)
	
func on_choice_made(ev : Dictionary, rollback_to_choice:bool = true) -> void:
	# rollback_to_choice is only used when called externally.
	_u.free_children(choiceContainer)
	waiting_cho = false
	choiceContainer.visible = false
	if ev.size() == 0:
		auto_load_next()
	else:
		interpret_events(ev)

#----------------------------- Screen and Camera effects-----------------------
func screen_effects(ev: Dictionary):
	var temp:Array = ev['screen'].split(" ")
	var ef:String = temp[0]
	match ef:
		"", "off": screen.removeLasting()
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

func tint(ev : Dictionary) -> void:
	screen.call(ev['screen'], _u.has_or_default(ev,'color',Color()),\
		_u.has_or_default(ev,'time',1.0))
	if ev['screen'] == "tint" : ev['time'] = 0.05

#--------------------------------- Weather -------------------------------------
func change_weather(we:String):
	screen.show_weather(we) # If given weather doesn't exist, nothing will happen
	auto_load_next(!vn.inLoading)

#----------------------------- Miscellaneous ----------------------------------
func conditional_branch(ev : Dictionary) -> void:
	if check_condition(ev['condition']):
		change_block_to(ev['then'],0)
	else:
		change_block_to(ev['else'],0)

func _warning():
	print("The event you input is not available in LiteDialog.")

#------------------------------- Change Godot Scene -----------------------------
func change_scene_to(path : String):
	stage.clean_up()
	change_weather('')
	print("You are changing scene. Rollback will be cleared. It's a good idea to explain "+\
	"to the player the rules about rollback.")
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
	if waiting_cho:
		return
	# Can I simplify this?
	if (ev.is_action_pressed("ui_accept") or ev.is_action_pressed('vn_accept')) and waiting_acc:
		# vn_accept is mouse left click
		if ev.is_action_pressed('vn_accept'):
			if not (vn.noMouse or vn.inNotif or vn.inSetting):
				check_dialog()
		else: # not mouse
			if not (vn.inNotif or vn.inSetting):
				check_dialog()
				
#---------------------------- new game, load, set up, end ----------------------
func auto_start(start_block:String="starter", start_id=null):
	var load_instr:String = "new_game"
	print("!!! Beta Notice: auto_start currently only works if you use json files for dialog. ---")
	
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
	_load_instr:String = "new_game", start_block:String="starter", start_id=null) -> void:
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
	all_blocks = blocks
	all_choices = choices
	all_conditions = conditions

	if start_id:
		current_index = get_target_index(start_block,start_id)
	else:
		current_index = 0
	if blocks.has(start_block):
		current_block = blocks[start_block]
	else:
		push_error("Start block %s not found." % start_block)

	if music.bgm != '': _cur_bgm = music.bgm
	if debug_mode: print("Debug: current block is " + start_block)
	load_event_at_index(current_index)
