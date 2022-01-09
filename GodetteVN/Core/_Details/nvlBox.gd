extends RichTextLabel

export(String, FILE, "*.ogg") var beep_path = ''
var autoCounter:int = 0
var skipCounter:int = 0
var adding:bool = false
var _grouping:bool = false
var _groupSize:int = 0
var _beep:bool = false

# center = nvl in disguise
const default_size:Vector2 = Vector2(1100,800)
const default_pos:Vector2 = Vector2(410,50)
const CENTER_SIZE:Vector2 = Vector2(1100,300)
const CENTER_POS:Vector2 = Vector2(-580,420)
var last_uid:String = ''
var _target_leng:int = 0

signal load_next
signal all_visible

func _ready():
	beep_path = beep_path.split("/")[-1]
	var _e:int = vn.get_node("GlobalTimer").connect("timeout",self, "_on_global_timeout")
	var sb:VScrollBar = get_v_scroll()
	_e = sb.connect("mouse_entered", vn.Utils, "no_mouse")
	_e = sb.connect("mouse_exited", vn.Utils, "yes_mouse")

func set_dialog(uid : String, words : String, cps = vn.cps, suppress_name:bool = false, beep:bool=false):
	_beep = beep and (beep_path != '')
	if suppress_name: # if name should not be shown, as in the center case treat it as if it is the narrator
		uid = ""
	if (uid != last_uid):
		last_uid = uid
		if uid == "":
			if self.text != '':
				self.bbcode_text += "\n\n"
		else:
			var ch_info:Dictionary = vn.Chs.all_chara[uid]
			var color:Color = MyUtils.has_or_default(ch_info,"name_color",Color.black)
			var n:String = ch_info["display_name"]
			var cstr:String = color.to_html(false)
			if self.text == '':
				self.bbcode_text += "[color=#" + cstr + "]" + n + ":[/color]\n"
			else:
				self.bbcode_text += "\n\n[color=#" + cstr + "]" + n + ":[/color]\n"
			
	else:
		self.bbcode_text += " "
	
	visible_characters = text.length()
	bbcode_text += words
	_target_leng = text.length()
	if cps <= 0: # finalized = text without the special escapes like \_ and \%
		visible_characters = -1
		adding = false
		return
	
	$Timer.wait_time = max(0.015, 1.0/cps)
	$Timer.start()
	adding = true
	
func force_finish():
	if adding:
		self.visible_characters = _target_leng
		adding = false
		$Timer.stop()
		emit_signal("all_visible")
	
func _on_Timer_timeout():
	visible_characters += 1
	if _beep: music.play_sound(beep_path,0.0,'Voice',vn.VOICE_DIR)
	if visible_characters >= _target_leng:
		force_finish()

func center_mode():
	self.rect_position = CENTER_POS
	self.rect_size = CENTER_SIZE
	self.grow_horizontal = Control.GROW_DIRECTION_BOTH
	self.grow_vertical = Control.GROW_DIRECTION_BOTH
	self.bbcode_text = "[center]"

func queue_free():
	vn.Pgs.nvl_text = ""
	var par = get_parent()
	if par:
		par.queue_free()
	else:
		.queue_free()

func _on_global_timeout():
	if vn.skipping:
		skipCounter = (skipCounter + 1)%(vn.SKIP_SPEED)
		if skipCounter == 1:
			emit_signal("load_next")
	else:
		if !adding and vn.auto_on and !MyUtils.has_job('auto_dialog_wait'): 
			autoCounter += 1
			if autoCounter >= vn.auto_time * 20:
				autoCounter = 0
				emit_signal("load_next")
		else:
			autoCounter = 0
		skipCounter = 0
