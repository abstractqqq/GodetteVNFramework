extends TextureRect

var type : String

var following:bool = false
var dragging_start_pos:Vector2 = Vector2()

# Used if type = override, override_dcision
signal decision(yes)
# Used every time, convenience signal when yielding for notification
signal clicked


func _on_notifBox_gui_input(event:InputEvent):
	if event is InputEventMouseButton:
		if event.get_button_index() == 1:
			following = !following
			dragging_start_pos = get_local_mouse_position()

func _process(_delta):
	if following:
		self.rect_position = (get_global_mouse_position() - dragging_start_pos)

func set_text(which:String):
	self.type = which
	var tbox = self.get_node("notifText")
	match type:
		"quit":
			tbox.bbcode_text = "Do you want to quit the game?"
		"main":
			tbox.bbcode_text = "Do you want to go back to main menu?"
		"override":
			tbox.bbcode_text = "Do you want to override this file?"
		"rollback":
			tbox.bbcode_text = "You cannot rollback anymore."
			get_node("okButton").visible = true
			get_node("noButton").visible = false
			get_node("yesButton").visible = false
		"make_save":
			tbox.bbcode_text = "Do you want to make a save?"
		_:
			vn.Notifs.hide()

func _on_noButton_pressed():
	emit_signal("clicked")
	vn.Notifs.hide()

func _on_yesButton_pressed():
	match type:
		"main":
			vn.Files.write_to_config()
			screen.clean_up()
			music.stop_bgm()
			vn.Pgs.resetPlayback()
			vn.Pgs.history.clear()
			vn.dvar_initialization()
			vn.Scene.stage.clean_up()
			if get_tree().change_scene(vn.ROOT_DIR + vn.title_screen_path) == OK:
				vn.reset_states()
		"override":
			emit_signal("decision", true)
		"quit":
			get_tree().quit()
		"make_save":
			vn.Utils.make_a_save("", 0.2)
	
	emit_signal("clicked")
	vn.Notifs.hide()

func _on_okButton_pressed():
	emit_signal("clicked")
	vn.Notifs.hide()
