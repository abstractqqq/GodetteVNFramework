extends CanvasLayer

#------------------------------------------------------------------------------
func _ready():
	get_tree().set_auto_accept_quit(true)
	OS.set_window_maximized(true)
	# update_saves()

func _on_exitButton_pressed():
	vn.Files.write_to_config()
	get_tree().quit()

func _on_settingsButton_pressed():
	add_child(load(vn.SETTING_PATH).instance())

func _on_newGameButton_pressed():
	vn.Pgs.load_instruction = "new_game"
	var _e:int = get_tree().change_scene(vn.ROOT_DIR + vn.start_scene_path)

func _on_loadButton_pressed():
	add_child(load(vn.LOAD_PATH).instance())

# Ideally, you wouldn't need this function. If you need this, you're probably
# working on a bigger project than you think.
# You can either update all saves at once... Or update the selected save in vn.Files.
# Game Update Behavior ???
# When launching your updated game, you should still be able to use your
# previous save data. But we might need to make some changes to the save
# data. 
# Every time you update the game, you update this function as well.
#------------------------------------------------------------------------------
# func update_saves():
	# Show a screen telling the players about the update
	# and what will happen to the saves...
	
	# Handling save update... ...
#	var saves:Array = vn.Files.get_save_files()
#	var file:File = File.new()
#	for s in saves:
#		var data
#		if file.open_encrypted_with_pass(vn.SAVE_DIR+s, File.READ, vn.PASSWORD) == OK:
#			data = file.get_var()
#			var ver:String = data['GAME_VERSION']
#			# update version of the save
#			# Depending on the update, you might want to deprecate the saves.
#			data['GAME_VERSION'] = vn.GAME_VERSION 
#			var _b:String = data['currentBlock']
#			var _idx:int = data['currentIndex']
#			var _scene:String = data['currentNodePath']
#			if ver == "0.0" and vn.GAME_VERSION == "0.01": # For example, there is
#				# a version difference... ...
#				data['history'] = []
#				data['rollback'] = []
#				#if scene == "res://GodetteVN/sampleScene2.tscn" and b == "starter":
#				#	if idx > 10:
#				#		data['currentIndex'] = idx + 1 # Because I inserted one thing at idx 10
#				#		# do other stuff here.
#						
#		if file.open_encrypted_with_pass(vn.SAVE_DIR+s, File.WRITE, vn.PASSWORD) == OK:
#			file.store_var(data)
#			file.close()
