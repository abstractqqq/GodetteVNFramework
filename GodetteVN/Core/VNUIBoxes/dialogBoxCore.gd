extends RichTextLabel

# Should be contained in a texture rect / color rect.

# Not implemented yet because I cannot find any resource
# export(bool) var noise_on = false
export(String, FILE, "*.ogg") var beep_path = ''

var autoCounter:int = 0
var skipCounter:int = 0
var adding:bool = false
var _target_leng:int = 0
var _grouping:bool = false
var _groupSize:int = 0
var _groupedWord:String = ''
var _beep:bool = false

# var eod_str:String = "[fade start=1 length=4]  >>>[/fade]"
# var eod:bool = false

var DEFAULT_FONTS:Dictionary = {'normal':'','bold':'','italics':'','bold_italics':''}

signal load_next
signal all_visible

func _ready():
	for f in DEFAULT_FONTS:
		DEFAULT_FONTS[f] = get('custom_fonts/%s_font'%f)
	
	var sb:VScrollBar = get_v_scroll()
	var _err:int = vn.get_node("GlobalTimer").connect("timeout",self, "_on_global_timeout")
	_err = sb.connect("mouse_entered", vn.Utils, "no_mouse")
	_err = sb.connect("mouse_exited", vn.Utils, "yes_mouse")

func reset_fonts():
	for f in DEFAULT_FONTS:
		add_font_override('%s_font'%f, DEFAULT_FONTS[f])

func set_chara_fonts(ev:Dictionary):
	for key in ev:
		ev[key] = ev[key].strip_edges()
		if ev[key] != '':
			add_font_override(key, load(ev[key]))

func set_dialog(words : String, cps:float = vn.cps, extend:bool = false, beep:bool = false):
	# words will be already preprocessed
	#eod = false
	_beep = beep and (beep_path != '')
	if extend:
		visible_characters = text.length()
		bbcode_text += " " + words
	else:
		visible_characters = 0
		bbcode_text = words
		
	_target_leng = text.length()
	if cps <= 0:
		bbcode_text = vn.Pgs.playback_events['speech'] 
		visible_characters = -1
		adding = false
		return
	
	$Timer.wait_time = max(0.015, 1.0/cps)
	$Timer.start()
	adding = true
	
func force_finish():
	$Timer.stop()
	while adding:
		_on_Timer_timeout()
		# visible_characters = _target_leng  # + len(eod_str)
		#eod = true
#		#bbcode_text += eod_str

func _on_Timer_timeout():
	#if eod:
	#	var n:String = eod_str[12]
	#	eod_str = eod_str.replace(n,str((int(n)+1)%5))
	#	bbcode_text = bbcode_text.substr(0,_target_leng) + eod_str
	var delay:bool = false
	if _grouping:
		_groupedWord += text[visible_characters + _groupSize]
		_groupSize += 1
		delay = true
	else:
		_groupSize = 0
	var cur:int = visible_characters + _groupSize
	var leng:int = text.length()
	if cur < leng:
		var pattern:String = '' 
		var valid:bool = true
		match text[cur]:
			"\\":
				if cur + 1 >= leng or not text[cur+1] in ["_","%"]:
					valid = false
				else:
					pattern = "\\\\"
			"%":
				_grouping = !_grouping
				if _grouping: _groupedWord = ''
				delay = _grouping
				pattern = "%"
			"_": 
				delay = true
				pattern = "_"
			_: valid = false
		# print(text[cur], " Delay : ", delay)
		if valid:
			bbcode_text = vn.Utils.eliminate_special_symbols(bbcode_text, pattern, false)
			_target_leng -= 1
	elif _grouping:
		visible_characters = text.length()
		_add_visible()
		return 

	_add_visible(delay)
		#eod = true
		#bbcode_text += eod_str

func _add_visible(delay:bool = false):
	if not delay:
		if _groupedWord.is_valid_float():
			$Timer.wait_time = max(0.015, 1.0/float(_groupedWord))
			bbcode_text = vn.Utils.eliminate_special_symbols(bbcode_text, _groupedWord, false)
			_groupedWord = ''
		else:
			visible_characters += (1 + _groupSize)
			if _beep: music.play_voice(beep_path)
		if visible_characters >= _target_leng:
			_grouping = false
			_groupSize = 0
			_beep = false
			visible_characters = int(max(_target_leng, -1))
			adding = false
			$Timer.stop()
			emit_signal("all_visible")

func _on_global_timeout():
	if get_parent().visible:
		if vn.skipping:
			skipCounter = (skipCounter + 1)%(vn.SKIP_SPEED)
			if skipCounter == 0:
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
	
