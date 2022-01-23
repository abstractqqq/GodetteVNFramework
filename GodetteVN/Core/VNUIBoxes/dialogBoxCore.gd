extends RichTextLabel

# Should be contained in a texture rect / color rect.

# Not implemented yet because I cannot find any resource
# export(bool) var noise_on = false
export(String, FILE, "*.ogg") var beep_path = ''
export(String, FILE, "*.png") var EOD_pic = ''
export(int) var EOD_pic_lengh = 8

var adding:bool = false
var _auto_counter:int = 0
var _skip_counter:int = 0
var _target_leng:int = 0
var _grouping:bool = false
var _groupSize:int = 0
var _groupedWord:String = ''
var _lastUnderscoreIdx:int = 0
var _lastPctIdx:int = 0
var _lastSlashIdx:int = 0
var _beep:bool = false
var _eod:bool = false
var _eod_num:int = 0
var _eod_counter:int = 0
var _finalized_text:String = ''

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
	beep_path = beep_path.split("/")[-1]

func reset_fonts():
	for f in DEFAULT_FONTS:
		add_font_override('%s_font'%f, DEFAULT_FONTS[f])

func set_chara_fonts(ev:Dictionary):
	for key in ev:
		ev[key] = ev[key].strip_edges()
		if ev[key] != '':
			add_font_override(key, load(ev[key]))

func set_dialog(words:String, cps:float = vn.cps, extend:bool = false, beep:bool = false):
	# words will be already preprocessed
	#eod = false
	_lastPctIdx = -1
	_lastUnderscoreIdx = -1
	_lastSlashIdx = -1
	_eod = false
	_eod_num = 0
	_beep = beep and (beep_path != '')
	if extend:
		visible_characters = text.length()
		bbcode_text = vn.Pgs.playback_events['speech'] # + " " + words
	else:
		_finalized_text = ''
		visible_characters = 0
		bbcode_text = words
		
	_target_leng = text.length()
	if cps < 0.015:
		bbcode_text = vn.Pgs.playback_events['speech']
		visible_characters = _target_leng
		adding = false
		return
	
	$Timer.wait_time = max(0.015, 1.0/cps)
	$Timer.start()
	adding = true
	
func force_finish():
	$Timer.stop()
	_beep = false
	while adding:
		_on_Timer_timeout()
	_finalized_text = bbcode_text 
	if EOD_pic != '' and EOD_pic_lengh > 1:
		_eod = true


func _on_Timer_timeout():
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
					_lastSlashIdx = bbcode_text.findn("\\", _lastSlashIdx+1)
				else:
					pattern = "\\\\"
					if text[cur+1] == "_": _lastUnderscoreIdx = bbcode_text.findn("_", _lastUnderscoreIdx+1)
					elif text[cur+1] == "%": _lastPctIdx = bbcode_text.findn("%", _lastPctIdx+1)
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
			if pattern == "%":
				bbcode_text = vn.Utils.replace_special_symbols(bbcode_text, pattern, '', false, _lastPctIdx+1)
			elif pattern == "_":
				bbcode_text = vn.Utils.replace_special_symbols(bbcode_text, pattern, '',false, _lastUnderscoreIdx+1)
			elif pattern == "\\\\":
				bbcode_text = vn.Utils.replace_special_symbols(bbcode_text, pattern, '',false, _lastSlashIdx+1)
			_target_leng -= 1
	elif _grouping:
		visible_characters = text.length()
		_add_visible()
		return 

	_add_visible(delay)

func _add_visible(delay:bool = false):
	if not delay:
		if _groupedWord.is_valid_float():
			$Timer.wait_time = max(0.015, 1.0/float(_groupedWord))
			bbcode_text = vn.Utils.eliminate_special_symbols(bbcode_text, _groupedWord, false)
			_groupedWord = ''
		else:
			visible_characters += (1 + _groupSize)
			if _beep: music.play_sound(beep_path,0.0,'Voice',vn.VOICE_DIR)
		if visible_characters >= _target_leng:
			_grouping = false
			_groupSize = 0
			_beep = false
			visible_characters = int(max(_target_leng, -1))
			adding = false
			$Timer.stop()
			emit_signal("all_visible")
			_finalized_text = bbcode_text 
			if EOD_pic != '' and EOD_pic_lengh > 1:
				_eod = true
				visible_characters = -1

func _on_global_timeout():
	if get_parent().visible:
		if vn.skipping:
			_skip_counter = (_skip_counter + 1)%(vn.SKIP_SPEED)
			if _skip_counter == 0:
				emit_signal("load_next")
		else:
			# EOD Behavior
			if !adding and _eod:
				_eod_counter += 1
				if _eod_counter >= 2: # 2 means update per 2*0.05 seconds
					_eod_counter = 0
					bbcode_text = _finalized_text + " "
					var temp:PoolStringArray = EOD_pic.split("_")
					_eod_num = (_eod_num + 1) % EOD_pic_lengh
					add_image(load(temp[0]+"_"+str(_eod_num)+".png"),20,20)
			# Auto Behavior
			if !adding and vn.auto_on and !MyUtils.has_job('auto_dialog_wait'): 
				_auto_counter += 1
				if _auto_counter >= vn.auto_time * 20:
					_auto_counter = 0
					emit_signal("load_next")
			else:
				_auto_counter = 0
			_skip_counter = 0
	
