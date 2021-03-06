extends CanvasLayer

export(bool) var use_scroll = true
export(bool) var show_quick_menu = true
export(bool) var draggable_dialog = false
export(bool) var resizable_dialog = false
export(bool) var name_box_follow_chara = false
export(bool) var fix_relative_name_box_pos = true


onready var dbox = $dialogBox/dialogBoxCore
onready var fixed_diff = $nameBox.rect_position-$dialogBox.rect_position

func _ready():
	set_dialog_box_options(draggable_dialog,resizable_dialog)
	if show_quick_menu == false: 
		$quickMenu.queue_free()
	if not use_scroll:
		dbox.scroll_active = false
		dbox.scroll_following = true

func get_dialog_box():
	return dbox

func namebox_follow_chara(uid:String):
	if name_box_follow_chara and vn.Scene.stage.is_on_stage(uid):
		var cpos:Vector2 = vn.Scene.stage.get_chara_pos(uid)
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

func set_side_image(sc:Vector2 = Vector2(1,1), pos:Vector2 = Vector2(-35,530)):
	$other/sideImage.scale = sc
	$other/sideImage.position = pos

