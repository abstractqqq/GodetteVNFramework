extends ScrollContainer

# Multithreading only creates more problems. (If I am doing it right...)
func _ready():
	# Create the appearance
	var saves:Array = vn.Files.get_save_files()
	var size:int = saves.size()
	var file:File = File.new()
	for i in range(size):
		var saveSlot:Node = vn.Pre.SAVE_SLOT.instance()
		var path:String = vn.SAVE_DIR+saves[i]
		if file.open_encrypted_with_pass(path, File.READ, vn.PASSWORD) == OK:
			var data = file.get_var()
			saveSlot.setup_for_scene(data, 1, path)
			var _e:int = saveSlot.connect('load_ready', self, 'load_save')
			$allSaves.add_child(saveSlot)
		else:
			push_error("Loading save file %s failed." %saves[i])
	
	file.close()

func load_save():
	vn.reset_states() # inSetting = false
	vn.Scene.stage.character_leave('absolute_all')
	var _e:bool = get_tree().change_scene(vn.Pgs.currentNodePath)
