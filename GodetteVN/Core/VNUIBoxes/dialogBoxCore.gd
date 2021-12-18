extends RichTextLabel
# Need to refactor. Use twene will allow flexible cps. But still need some 
# way to easily enable keyboard noise. 

# Not implemented yet because I cannot find any resource
# export(bool) var noise_on = false
# export(String) var noise_file_path = ''

onready var timer = $Timer

var autoCounter:int = 0
var skipCounter:int = 0
var adding:bool = false
var nw:bool = false

var _target_leng:int = 0


# var eod_str:String = "[fade start=1 length=4]  >>>[/fade]"
# var eod:bool = false

var FONTS:Dictionary = {}
const ft:PoolStringArray = PoolStringArray(['normal', 'bold', 'italics', 'bold_italics'])

signal load_next

func _ready():
	for f in ft:
		FONTS[f] = get('custom_fonts/%s_font'%f)
		
	var sb:VScrollBar = get_v_scroll()
	var _err:int = vn.get_node("GlobalTimer").connect("timeout",self, "_on_global_timeout")
	_err = sb.connect("mouse_entered", vn.Utils, "no_mouse")
	_err = sb.connect("mouse_exited", vn.Utils, "yes_mouse")

func reset_fonts():
	for f in ft:
		add_font_override('%s_font'%f, FONTS[f])

func set_chara_fonts(ev:Dictionary):
	for key in ev:
		ev[key] = ev[key].strip_edges()
		if ev[key] != '':
			add_font_override(key, load(ev[key]))

func set_dialog(words : String, cps:float = vn.cps, extend = false):
	# words will be already preprocessed
	#eod = false
	if extend:
		visible_characters = self.text.length()
		bbcode_text += " " +words
	else:
		visible_characters = 0
		bbcode_text = words
		
	_target_leng = self.text.length()
	
	if cps <= 0:
		visible_characters = _target_leng
		adding = false
		if nw:
			nw = false
			emit_signal("load_next")
		return
	
	$Tween.interpolate_property(self,'visible_characters',visible_characters,\
		_target_leng, float(_target_leng-visible_characters)/cps, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	$Tween.start()
	adding = true
	
func force_finish():
	$Tween.remove(self,"visible_characters")
	visible_characters = _target_leng
	adding = false
	if nw:
		nw = false
		if not vn.skipping:
			emit_signal("load_next")
			
func _on_Tween_tween_completed(object, key):
	if key == ":visible_characters" and object == self:
		force_finish()
	
#func force_finish():
#	if adding:
#		visible_characters = _target_leng  # + len(eod_str)
		#eod = true
#		#bbcode_text += eod_str
#		adding = false
#		timer.stop()
#		timer.wait_time = 0.3
#		timer.start()
#		if nw:
#			nw = false
#			if not vn.skipping:
#				emit_signal("load_next")

func _on_Timer_timeout():
	pass
	#if eod:
	#	var n:String = eod_str[12]
	#	eod_str = eod_str.replace(n,str((int(n)+1)%5))
	#	bbcode_text = bbcode_text.substr(0,_target_leng) + eod_str
	
	#visible_characters += 1
	#if visible_characters >= _target_leng:
	#	visible_characters = _target_leng  # + len(eod_str)
	#	#eod = true
	#	#bbcode_text += eod_str
	#	adding = false
	#	timer.stop()
	#	timer.wait_time = 0.3
	#	timer.start()
	#	if nw:
	#		nw = false
	#		emit_signal("load_next")

func _on_global_timeout():
	if get_parent().visible == false:
		return
	
	if vn.skipping:
		force_finish()
		skipCounter = (skipCounter + 1)%(vn.SKIP_SPEED)
		if skipCounter == 1:
			emit_signal("load_next")
	else:
		# Auto forwarding
		if not adding and vn.auto_on: 
			autoCounter += 1
			if autoCounter >= vn.auto_bound:
				autoCounter = 0
				if not nw:
					emit_signal("load_next")
		else:
			autoCounter = 0
		skipCounter = 0
	
