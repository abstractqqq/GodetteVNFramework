extends CanvasLayer

export(bool) var show_quick_menu = true
export(bool) var draggable_dialog = false
export(bool) var resizable_dialog = false
export(bool) var name_box_follow_chara = false
export(bool) var fix_relative_name_box_pos = true

onready var dbox = $dialogBox/dialogBoxCore
onready var fixed_diff = $nameBox.rect_position-$dialogBox.rect_position

func _ready():
	set_dialog_box_options(draggable_dialog,resizable_dialog)
	if show_quick_menu == false: free_QM()

func free_QM():
	get_node("quickMenu").queue_free()

func get_dialog_box():
	return dbox

func namebox_follow_chara(uid:String):
	if name_box_follow_chara and stage.is_on_stage(uid):
		var cpos:Vector2 = stage.get_chara_pos(uid)
		var mid:float = get_viewport().size.x / 2.0
		if cpos.x < mid:
			$nameBox.rect_position.x = $dialogBox.rect_position.x
		else:
			$nameBox.rect_position.x = $dialogBox.rect_position.x + $dialogBox.rect_size.x - $nameBox.rect_size.x

func reset_namebox_pos(pos = Vector2(0,0)):
	if fix_relative_name_box_pos:
		$nameBox.rect_position = $dialogBox.rect_position+fixed_diff
	else:
		$nameBox.rect_position = pos
	
func set_dialog_box_options(draggable:bool=false, resizable:bool=false):
	$dialogBox.resizable = resizable
	$dialogBox.draggable = draggable
	if resizable == false:
		$dialogBox.hide_resize_handler()

