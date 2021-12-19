extends RichTextLabel

# Same as dialog box
onready var timer = $Timer

var autoCounter:int = 0
var skipCounter:int = 0
var adding:bool = false

# center = nvl in disguise
const default_size:Vector2 = Vector2(1100,800)
const default_pos:Vector2 = Vector2(410,50)
const CENTER_SIZE:Vector2 = Vector2(1100,300)
const CENTER_POS:Vector2 = Vector2(410,400)
var last_uid:String = ''
var new_dialog:String = ''

var _target_leng:int = 0

signal load_next
signal all_visible

func _ready():
	var _err:int = vn.get_node("GlobalTimer").connect("timeout",self, "_on_global_timeout")
	var sb = get_v_scroll()
	_err = sb.connect("mouse_entered", vn.Utils, "no_mouse")
	_err = sb.connect("mouse_exited", vn.Utils, "yes_mouse")

func set_dialog(uid : String, words : String, cps = vn.cps, suppress_name = false):
	$Tween.remove(self,"visible_characters")
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
			var n = ch_info["display_name"]
			var cstr:String = color.to_html(false)
			if self.text == '':
				self.bbcode_text += "[color=#" + cstr + "]" + n + ":[/color]\n"
			else:
				self.bbcode_text += "\n\n[color=#" + cstr + "]" + n + ":[/color]\n"
			
	else:
		self.bbcode_text += " "
	
	visible_characters = len(text)
	new_dialog = words
	bbcode_text += words
	_target_leng = len(text)
	
	if cps <= 0:
		visible_characters = _target_leng
		adding = false
		return
	
	$Tween.interpolate_property(self,'visible_characters',visible_characters,\
		_target_leng, float(_target_leng-visible_characters)/cps, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	$Tween.start()
	adding = true
	
func _on_Timer_timeout():
	pass
	
func force_finish():
	$Tween.remove(self,"visible_characters")
	visible_characters = _target_leng
	adding = false
	emit_signal("all_visible")

func _on_Tween_tween_completed(object, key):
	if key == ":visible_characters" and object == self:
		force_finish()

func get_text():
	return self.new_dialog

func center_mode():
	self.rect_position = CENTER_POS
	self.rect_size = CENTER_SIZE
	self.grow_horizontal = Control.GROW_DIRECTION_BOTH
	self.grow_vertical = Control.GROW_DIRECTION_BOTH
	self.bbcode_text = "[center]"

func queue_free():
	vn.Pgs.nvl_text = ""
	.queue_free()

func _on_global_timeout():
	if vn.skipping:
		force_finish()
		skipCounter = (skipCounter + 1)%(vn.SKIP_SPEED)
		if skipCounter == 1:
			emit_signal("load_next")
	else:
		if not adding and vn.auto_on and not MyUtils.has_job('auto_dialog_wait'): 
			autoCounter += 1
			if autoCounter >= vn.auto_time * 20:
				autoCounter = 0
				emit_signal("load_next")
		else:
			autoCounter = 0
		skipCounter = 0
