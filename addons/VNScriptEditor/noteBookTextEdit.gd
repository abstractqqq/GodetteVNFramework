tool
extends TextEdit

export(Color) var field_val_color = Color(0, 0.574219, 0.426178)
export(Color) var line_comment_color = Color(0.445313, 0.445313, 0.445313)

var lineNum : int

# related to editing
var _cur_line:String = ''
var _pause:bool = false
#------------------------------------------------------------------------------------
func _ready():
	add_color_region("#", '', line_comment_color, true)
	add_color_region("::", ";", field_val_color)
	cursor_set_line(1)


func _input(_event):
	if Input.is_key_pressed(KEY_TAB) and not _pause and self.has_focus():
		_pause = true
		lineNum = cursor_get_line()
		_cur_line = get_line(lineNum).rstrip(' ')
		var t:String = get_selection_text().lstrip(" ").rstrip(" ")
		var se:PoolStringArray = t.split(" ")
		var lead:String = se[0]
		var sub:String = ''
		if se.size() > 1:
			sub = se[1]
		
		match selection_match(lead):
			0:cursor_action()
			1:character_action(lead, sub)
			2:camera_action(sub)
			3:screen_action(sub)
			4:bgm_action(sub)
			5:float_action()
			6:font_action()
			7:then_action()
			-1:return
			
		yield(get_tree().create_timer(0.2), 'timeout')
		_pause = false
		
func selection_match(lead:String) -> int:
	var m:int = -1
	match lead:
		"": m = 0
		"chara": m = 1
		"camera": m = 2
		"screen": m = 3
		"bgm": m = 4
		"float": m = 5
		"font": m = 6
		"then": m = 7
		_: m = 1 # anything else will be defaulted to chara
	return m

func cursor_action():
	set_line(lineNum, _cur_line + ":: ;")
	cursor_set_column(cursor_get_column() + 2)	


func character_action(lead:String, sub:String):
	set_line(lineNum,"")
	if lead == "chara": lead = "uid"
	match sub:
		"move": set_line(lineNum, "chara :: %s move; loc ::*; type :: linear; time :: 1;" % [lead])
		"jump": set_line(lineNum, "chara :: %s jump; amount :: 80; time :: 0.25; dir :: up;" % [lead])
		"join": set_line(lineNum, "chara :: %s join; loc ::*; expr :: default;" % [lead])
		"fadein": set_line(lineNum, "chara :: %s fadein; loc ::*; expr :: default ; time :: 1;" % [lead])
		"shake": set_line(lineNum, "chara :: %s shake; amount :: 250 ; time :: 2;" % [lead])
		"fadeout": set_line(lineNum, "chara :: %s fadeout; time :: 1 ;" % [lead])
		"add": set_line(lineNum, "chara :: %s add; path :: /ur/path/to/ur/scene.tscn; at :: point;" % [lead])
		"spin": set_line(lineNum, "chara :: %s spin; deg :: 360; time :: 1; type :: linear ; sdir :: 1;" % [lead])
		"leave": set_line(lineNum, "chara :: %s leave;" % [lead])
		"vpunch": set_line(lineNum, "chara :: %s vpunch;" % [lead])
		"hpunch": set_line(lineNum, "chara :: %s hpunch;" % [lead])
		"scale": set_line(lineNum, "chara :: %s scale; scale ::*; time :: 1 ; type:: linear;" % [lead])

func camera_action(sub:String):
	set_line(lineNum,"")
	match sub:
		"shake": set_line(lineNum, "camera :: shake; amount :: 250; time :: 2;")
		"zoom": set_line(lineNum, "camera :: zoom; scale ::*; loc :: 0 0; time :: 1; type :: linear;")
		"move": set_line(lineNum, "camera :: move; loc ::*; time :: 1; type :: linear;")
		"spin": set_line(lineNum, "camera :: spin; deg ::*; time :: 1; sdir :: 1; type :: linear;")

func screen_action(sub:String):
	set_line(lineNum,"")
	match sub:
		"tint": set_line(lineNum, "screen :: tint; color ::*; time :: 1;")
		"tintwave": set_line(lineNum, "screen :: tintwave; color ::*; time :: 1;")
		"flashlight": set_line(lineNum, "screen :: flashlight; scale :: 1 1;")

func bgm_action(sub:String):
	set_line(lineNum,"")
	match sub:
		"fadein": set_line(lineNum, "bgm ::*; fadein ::*; vol :: 0;")
		"fadeout": set_line(lineNum, "bgm :: off; fadeout ::*; vol :: 0;")

func float_action():
	set_line(lineNum,"")
	set_line(lineNum, "float :: ur_text; wait ::*; loc :: 400 400; fadein :: 1;")

func font_action():
	set_line(lineNum,"")
	set_line(lineNum, "font :: normal; path :: your_font_resource.tres;")
	
func then_action():
	set_line(lineNum,"")
	set_line(lineNum, "then :: target_block_name; target id :: your_id;")
