extends Node

var system_data:Dictionary = {}
const CONFIG_PATH:String = "user://config.json"
const _default_config_vars:Dictionary = {'bgm_volume':0, 'eff_volume':0,\
 'voice_volume':0,'auto_time':2, 'total_dialogs':0}

func _ready():
	load_config()
#------------------------------------------------------------------------------
func get_save_files():
	var files:Array = []
	var dir:Directory = Directory.new()
	if !dir.dir_exists(vn.SAVE_DIR):
		var _e:int = dir.make_dir_recursive(vn.SAVE_DIR)
	
	var _e:int = dir.open(vn.SAVE_DIR)
	_e = dir.list_dir_begin()
	var file:String = "1"
	while file != "":
		file = dir.get_next()
		if not file.begins_with("."):
			if file.get_extension() == 'dat':
				files.append(file)
				
	dir.list_dir_end()
	return files

func data2Thumbnail(img_data:PoolByteArray) -> ImageTexture:
	
	var img:Image = Image.new()
	img.create_from_data(vn.THUMBNAIL_WIDTH, vn.THUMBNAIL_HEIGHT,\
		false, vn.ThumbnailFormat, img_data)
	# Creates a texture according to the imageTexture data
	var texture:ImageTexture = ImageTexture.new()
	texture.create_from_image(img)
	return texture
	
func readSave(save) -> bool:
	var file:File = File.new()
	if file.open_encrypted_with_pass(save.path, File.READ, vn.PASSWORD) == OK:
		var data = file.get_var()
		vn.Pgs.currentSaveDesc = data['currentSaveDesc']
		vn.Pgs.currentIndex = data['currentIndex']
		vn.Pgs.currentNodePath = data['currentNodePath']
		vn.Pgs.currentBlock = data['currentBlock']
		vn.Pgs.history = data['history']
		vn.Pgs.rollback_records = data['rollback']
		vn.Pgs.playback_events = data['playback']
		vn.Pgs.load_instruction = "load_game"
		vn.Chs.chara_pointer = data['chara_pointer']
		vn.Chs.chara_name_patch = data['name_patches']
		vn.Chs.patch_display_names()
		vn.dvar = data['dvar']
		file.close()
	else:
		# load save failed. The save is corrupted or removed.
		push_error("Load save failed. Save file: %s" %save.path)
	
	return true

#-------------------------------------------------------------------------------
func get_chara_sprites(uid, which = "sprite"):
	# This method should only be used in development phase.
	# The exported project won't work with dir calls depending on
	# what kind of paths are passed.
	var sprites:Array = []
	var dir = Directory.new()
	if which == "anim" or which == "animation" or which == "spritesheet":
		which = vn.CHARA_ANIM
	elif which == "side" or which == "side_image" or which == "side image":
		which = vn.CHARA_SIDE
	else:
		which = vn.CHARA_DIR
		
	if !dir.dir_exists(which):
		var _e : int = dir.make_dir_recursive(which)
	
	var _e : int = dir.open(which)
	_e = dir.list_dir_begin()
	var pic:String = "1"
	while pic != "":
		pic = dir.get_next()
		if not pic.begins_with("."):
			var temp:PoolStringArray = pic.split(".")
			var ext:String = temp[temp.size()-1]
			if ext in ['png', 'jpg', 'jpeg']:
				var pic_id:String = (temp[0].split("_"))[0]
				if pic_id == uid:
					sprites.append(pic)
				
	dir.list_dir_end()
	return sprites

func get_backgrounds():
	# This method should only be used in development phase.
	# The exported project won't work with dir calls depending on
	# what kind of paths are passed.
	var bgs:Array = []
	var dir:Directory = Directory.new()
	if !dir.dir_exists(vn.BG_DIR):
		var _e:int = dir.make_dir_recursive(vn.BG_DIR)
	
	var _e:int = dir.open(vn.BG_DIR)
	_e = dir.list_dir_begin()
	var pic:String = "1"
	while pic != "":
		pic = dir.get_next()
		if not pic.begins_with("."):
			var temp:PoolStringArray = pic.split(".")
			var ext:String = temp[temp.size()-1]
			if ext in ['png', 'jpg', 'jpeg']:
				bgs.append(pic)
				
	dir.list_dir_end()
	return bgs

#-------------------------------------------------------------------------------
#func path_valid(path : String) -> bool:
#	# This method should only be used in development phase.
#	# Path checks might not work because of 
#	# the way paths are encoded.
#	var file = File.new()
#	var exists = file.file_exists(path)
#	file.close()
#	return exists
#------------------------ Loading Json -------------------------------

func load_json(path: String):
	var f:File = File.new()
	if f.open(path, File.READ) == OK:
		var t = JSON.parse(f.get_as_text()).get_result()
		f.close()
		return t
	else:
		push_error("Load json error. File probably corrupted.")
		
func load_config_with_pass():
	var directory:Directory = Directory.new();
	if not directory.file_exists(CONFIG_PATH):
		var file:File = File.new()
		if file.open_encrypted_with_pass(CONFIG_PATH, File.WRITE, vn.PASSWORD) == OK:
			file.store_line(JSON.print(_default_config_vars,'\t'))
			file.close()
		else: # Print out config file?
			push_error("Error making config file.")

	var f:File = File.new()
	if f.open_encrypted_with_pass(CONFIG_PATH, File.READ, vn.PASSWORD) == OK:
		var t = JSON.parse(f.get_as_text()).get_result()
		f.close()
		return t
	else:
		push_error("Error opening config file.")

#------------------------ Config, Volume, etc. -------------------------------

func write_to_config():
	var directory:Directory = Directory.new();
	if directory.file_exists(CONFIG_PATH):
		var file:File = File.new()
		if file.open_encrypted_with_pass(CONFIG_PATH, File.WRITE,vn.PASSWORD) == OK:
			file.store_line(JSON.print(system_data,'\t'))
			file.close()
		else:
			push_error("Error when opening config file.")
			
func load_config():
	system_data = load_config_with_pass()
	AudioServer.set_bus_volume_db(1, system_data["bgm_volume"])
	AudioServer.set_bus_volume_db(2, system_data["eff_volume"])
	AudioServer.set_bus_volume_db(3, system_data["voice_volume"])
	vn.auto_time = system_data['auto_time']
	
func regiester_dialog_json(fpath:String, spoiler_proof:bool=true):
	# Will make this dialog_json spolier-proof.
	if system_data.has(fpath) or system_data.has(fpath+'_size'):
		return 
	if fpath.ends_with(".json"):
		var dialogs = load_json(fpath)['Dialogs']
		if spoiler_proof:
			make_spoilerproof(fpath, dialogs)
		else:
			system_data[fpath+"_size"] = 0
			for branch in dialogs:
				system_data[fpath+"_size"] += _find_num_dialogs(dialogs[branch])
				system_data['total_dialogs'] += system_data[fpath+"_size"]
			

func make_spoilerproof(scene_path:String, all_dialog_blocks:Dictionary):
	if system_data.has(scene_path) == false:
		system_data[scene_path+"_size"] = 0
		var ev:Dictionary = {}
		for block in all_dialog_blocks:
			ev[block] = -1
			system_data[scene_path+"_size"] += _find_num_dialogs(all_dialog_blocks[block])
			system_data['total_dialogs'] += system_data[scene_path+"_size"]
			
		system_data[scene_path] = ev
		
func _find_num_dialogs(block:Array) -> int:
	var m:int = 0
	for ev in block:
		if ev.has('condition'):
			var new_ev:Dictionary = ev.duplicate()
			var _ok:bool = new_ev.erase('condition')
			if vn.event_reader(new_ev) == -1:
				m += 1
		elif vn.event_reader(ev) == -1:
			m += 1
	return m
	
func reset_all_spoilerproof():
	var regex:RegEx = RegEx.new()
	var _e:int = regex.compile("(^(res://)(.+)(\\.tscn)$)|(\\.json)$")
	for k in system_data:
		if regex.search(k):
			reset_spoilerproof(k)
	#if system_data['total_dialogs'] != 0:
	#	system_data['total_dialogs'] = 0

func reset_spoilerproof(scene_path:String):
	if system_data.has(scene_path):
		for key in system_data[scene_path]:
			system_data[scene_path][key] = -1
			
		# system_data['total_dialogs'] -= system_data[scene_path+"_size"]
	
func remove_spoilerproof(scene_path:String):
	if system_data.has(scene_path):
		var _e:bool = system_data.erase(scene_path)
		
func get_progress() -> float:
	var progress:int = 0
	var regex:RegEx = RegEx.new()
	var _e:int = regex.compile("^(res://)(.+)(\\.tscn)$")
	for k in system_data:
		if regex.search(k): # k is a scene_path
			for branch in system_data[k]:
				progress += system_data[k][branch] + 1
	
	print(progress)
	print(system_data['total_dialogs'])
	
	return min(1.0, float(progress) / float(system_data['total_dialogs']))

func _exit_tree():
	write_to_config()
