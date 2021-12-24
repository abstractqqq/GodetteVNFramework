extends ScrollContainer

# Make this multithreaded in the future
func _ready():
	var saves:Array = vn.Files.get_save_files()
	var file:File = File.new()
	for i in range(saves.size()):
		var saveSlot:Node = vn.Pre.SAVE_SLOT.instance()
		var path:String = vn.SAVE_DIR + saves[i]
		if file.open_encrypted_with_pass(path, File.READ, vn.PASSWORD) == OK:
			var data = file.get_var()
			saveSlot.setup_for_scene(data,0,path)
			$allSaves.add_child(saveSlot)
			file.close()
		else:
			push_error("Loading save file %s failed." %saves[i])

	for i in 3: # always provide some empty slots
		make_empty_save()


func make_empty_save():
	var newSlot:Node = vn.Pre.SAVE_SLOT.instance()
	var _e : int = newSlot.connect("save_made", self, "make_empty_save")
	$allSaves.add_child(newSlot)
