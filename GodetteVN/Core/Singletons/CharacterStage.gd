extends Node

const direction = {'up': Vector2.UP, 'down': Vector2.DOWN, 'left': Vector2.LEFT, 'right': Vector2.RIGHT}

# A duplicate method only for convenience.
func get_character_info(uid:String):
	if vn.Chs.all_chara.has(uid):
		return vn.Chs.all_chara[uid]
	else:
		push_error("No character with this uid {0} is found".format({0:uid}))

func set_sideImage(sc:Vector2 = Vector2(1,1), pos:Vector2 = Vector2(-35,530)):
	$other/sideImage.scale = sc
	$other/sideImage.position = pos
	
func change_expression(uid:String, expr:String):
	var info:Dictionary = vn.Chs.all_chara[uid]
	if info.has('path'):
		var _e:bool = find_chara_on_stage(uid).change_expression(expr)

func character_shake(uid : String, ev:Dictionary):
	if vn.skipping: return
	var amount:float = MyUtils.has_or_default(ev,'amount',250)
	var time:float = MyUtils.has_or_default(ev,'time',2)
	var mode:int = MyUtils.has_or_default(ev,'mode',0)
	if uid == 'all':
		for n in $characters.get_children():
			if n is Character and n.in_all: 
				n.shake(amount, time, mode)
	else:
		find_chara_on_stage(uid).shake(amount, time, mode)

func character_jump(uid:String, ev:Dictionary):
	if vn.skipping: return 
	var dir:Vector2 = MyUtils.has_or_default(ev,'dir',Vector2.UP)
	var amount:float = MyUtils.has_or_default(ev,'amount',80)
	var time:float = MyUtils.has_or_default(ev,'time',0.1)
	if uid == 'all':
		for n in $characters.get_children():
			if n is Character and n.in_all:
				n.jump(dir, amount, time)
	else:
		find_chara_on_stage(uid).jump(dir, amount, time)
		
func character_spin(uid:String, ev:Dictionary):
	# degrees:float = 360.0, time:float = 1.0, sdir:int = 1, type:String="linear"
	var sdir:int = MyUtils.has_or_default(ev,'sdir',1)
	var time:float = MyUtils.has_or_default(ev,'time',1)
	var degrees:float = MyUtils.has_or_default(ev,'deg',360)
	var type:String = MyUtils.has_or_default(ev,'type','linear')
	if uid == 'all':
		for n in $characters.get_children():
			if n is Character and n.in_all:
				if type == 'instant' or vn.skipping:
					n.rotation_degrees = degrees
				else:
					n.spin(sdir,degrees, time, type)
	else:
		var c:Character = find_chara_on_stage(uid)
		if type == 'instant' or vn.skipping:
			c.rotation_degrees = degrees
			c.target_deg = degrees
		else:
			c.spin(sdir,degrees,time,type)
		
func character_scale(uid:String, ev:Dictionary):
	# Currently doesn't support all
	if not ev.has('scale'):
		push_error("Character change scale event must have a scale field.")
	
	var c:Character = find_chara_on_stage(uid)
	var type:String = MyUtils.has_or_default(ev,'type','linear')
	if type == 'instant' or vn.skipping or vn.inLoading:
		c.scale = ev['scale']
		c.target_sc = ev['scale']
	else:
		c.change_scale(ev['scale'], MyUtils.has_or_default(ev,'time',1.0), type)
		
func character_move(uid:String, ev:Dictionary):
	if uid == 'all': 
		print("!!! Warning: Attempting to move all character at once.")
		print("!!! This is currently not allowed and this event is ignored.")
		return
	
	var type:String = MyUtils.has_or_default(ev,'type','linear')
	var expr:String = MyUtils.has_or_default(ev,'expression','')
	var c:Character = find_chara_on_stage(uid)
	if ev.has('loc'):
		if type == 'instant' or vn.skipping or vn.inLoading:
			c.position = ev['loc']
			c.loc = ev['loc']
			if expr != '': # empty string here means no expression change, not default.
				var _e:bool = c.change_expression(expr)
		else:
			c.change_pos_2(ev['loc'], MyUtils.has_or_default(ev,'time',1.0), type, expr)
	else:
		print("!!! Wrong move event format.")
		push_error("Character move expects a loc.")

func character_fadein(uid: String, ev:Dictionary) -> void:
	# Ignore accidental spriteless character fadein
	var time:float = MyUtils.has_or_default(ev,'time', 1.0)
	var expr:String = MyUtils.has_or_default(ev, 'expression', 'default')
	var info = vn.Chs.all_chara[uid]
	if info.has('path'):
		if vn.skipping:
			character_join(uid, ev)
		else:
			var c:Character = load(info['path']).instance()
			# If load fails, there will be a bug pointing to this line
			if c.apply_highlight:
				c.modulate = vn.DIM
			else:
				c.modulate = Color(1,1,1,1)
			c.modulate.a = 0
			c.loc = ev['loc']
			c.position = ev['loc']
			$characters.add_child(c)
			c.fadein(time,expr)

func character_fadeout(uid: String, ev:Dictionary) -> void:
	if vn.skipping:
		character_leave(uid)
	else:
		var time:float = MyUtils.has_or_default(ev,'time',1)
		if uid == 'all':
			for n in $characters.get_children():
				if n is Character and n.in_all:
					n.fadeout(time)
		else:
			find_chara_on_stage(uid).fadeout(time)

func character_join(uid: String, ev:Dictionary):
	var expr:String = MyUtils.has_or_default(ev,'expression','default')
	var info:Dictionary = vn.Chs.all_chara[uid]
	if info.has('path'):
		var ch_scene:PackedScene = load(info['path'])
		# If load fails, there will be a bug pointing to this line
		var c:Character = ch_scene.instance()
		$characters.add_child(c)
		if c.change_expression(expr):
			c.position = ev['loc']
			c.loc = ev['loc']
			c.modulate = vn.DIM

func character_add(uid:String, ev:Dictionary):
	var pt_name:String 
	var path:String 
	if ev.has_all(['path', 'at']):
		pt_name = ev['at']
		path = vn.ROOT_DIR + ev['path']
	else:
		print("!!! Character add event format error.")
		push_error('Character add expects "path" and "at" fields.')
	
	if uid == 'all':
		for c in $characters.get_children():
			if c is Character and c.in_all:
				for n in c.get_children():
					if n is Node2D and n.name == ('_' + pt_name):
						n.add_child(load(path).instance())
						break
	else:
		var c:Character = find_chara_on_stage(uid)
		for n in c.get_children():
			if n is Node2D and n.name == ('_' + pt_name):
				n.add_child(load(path).instance())
				break

func set_highlight(uid : String) -> void:
	var info:Dictionary = vn.Chs.all_chara[uid]
	if info.has('path'):
		for n in $characters.get_children():
			if n is Character and n.unique_id == uid and n.apply_highlight and not n.is_fading():
				n.modulate = Color(1,1,1,1)
				break

func remove_highlight() -> void:
	for n in $characters.get_children():
		if n is Character and n.apply_highlight:
			n.modulate = vn.DIM

func character_leave(uid : String):
	if uid == 'absolute_all':
		MyUtils.free_children($characters)
	elif uid == 'all':
		for n in $characters.get_children():
			if n is Character and n.in_all:
				n.call_deferred("free")
	else:
		find_chara_on_stage(uid).call_deferred("free")

func set_modulate_4_all(c : Color):
	for n in $characters.get_children():
		if n is Character and n.apply_highlight:
			n.modulate = c

func find_chara_on_stage(uid:String)->Character:
	for n in $characters.get_children():
		if n is Character and n.unique_id == uid:
			return n
			
	print('Warning: the character with uid {0} cannot be found or has not joined the stage.'.format({0:uid}))
	print("Depending on your event, you will get a bug or nothing will be done.")
	return null

func is_on_stage(uid : String) -> bool:
	for n in $characters.get_children():
		if n is Character and n.unique_id == uid:
			return true
	return false
	
func get_chara_pos(uid:String)->Vector2:
	return find_chara_on_stage(uid).position

func all_on_stage():
	var output:Array = []
	for n in $characters.get_children():
		if n is Character:
			output.append({"uid":n.unique_id, "expression":n.current_expression,\
			'loc': n.loc, 'deg': n.target_deg, 'fliph':n.flip_h,'flipv':n.flip_v, 'scale':n.target_sc})
	return output
	
func set_flip(uid:String, fliph:bool=false, flipv:bool=false):
	var c = find_chara_on_stage(uid)
	if c:
		c.flip_h = fliph
		c.flip_v = flipv
	
func clean_up():
	character_leave("absolute_all")
	set_sideImage()

# remove characters whose uid is not in arr
func remove_not_in(arr:PoolStringArray):
	for n in $characters.get_children():
		if n is Character and not (n.unique_id in arr ):
			n.call_deferred('free')
