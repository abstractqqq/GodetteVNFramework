extends CanvasLayer

#------------------------------------------------------------------------------
func _ready():
	get_tree().set_auto_accept_quit(true)
	OS.set_window_maximized(true)

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
