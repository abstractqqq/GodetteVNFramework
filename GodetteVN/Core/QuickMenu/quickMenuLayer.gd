extends Node2D

var hiding:bool = false

func _on_SettingButton_pressed():
	reset_auto_skip()
	vn.Scene.add_child(load(vn.SETTING_PATH).instance())

func on_historyButton_pressed():
	reset_auto_skip()
	vn.Scene.add_child(load(vn.HIST_PATH).instance())


func _on_saveButton_pressed():
	reset_auto_skip()
	vn.Utils.create_thumbnail()
	vn.Scene.add_child(load(vn.SAVE_PATH).instance())


func _on_quitButton_pressed():
	vn.Notifs.show("quit")
	reset_auto_skip()
	
func _on_mainButton_pressed():
	vn.Notifs.show("main")
	reset_auto_skip()


func _on_autoButton_pressed():
	reset_skip()
	vn.auto_on = not vn.auto_on
	if vn.auto_on:
		$autoButton.modulate = Color(1,0,0,1)
	else:
		$autoButton.modulate = Color(1,1,1,1)

func reset_auto():
	$autoButton.disabled = false
	$autoButton.modulate = Color(1,1,1,1)
	vn.auto_on = false


func _on_skipButton_pressed():
	reset_auto()
	vn.skipping = not vn.skipping
	if vn.skipping:
		$skipButton.modulate = Color(1,0,0,1)
	else:
		$skipButton.modulate = Color(1,1,1,1)

func reset_skip():
	$skipButton.disabled = false
	$skipButton.modulate = Color(1,1,1,1)
	vn.skipping = false
	
func _on_loadButton_pressed():
	reset_auto_skip()
	get_parent().add_child(load(vn.LOAD_PATH).instance())

func reset_auto_skip():
	reset_auto()
	reset_skip()

func disable_skip_auto():
	reset_auto_skip()
	$autoButton.disabled = true
	$skipButton.disabled = true
	
func enable_skip_auto():
	$autoButton.disabled = false
	$skipButton.disabled = false


func _on_QsaveButton_pressed():
	var flt = load("res://GodetteVN/Core/_Details/floatText.tscn").instance()
	screen.add_child(flt)
	flt.display("Quick save made.", 2, 0.5, Vector2(60,60), 'res://fonts/ARegular.tres')
	vn.Utils.make_a_save("[Quick Save] ")
