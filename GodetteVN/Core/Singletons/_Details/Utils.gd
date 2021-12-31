extends Node

# Eventually, some utilities will be moved out to a singleton 
# Utilities node.

# A collection of utility functions
var regex:RegEx = RegEx.new()
#-------------------------------------------------------------------------
# Premade event sections:
# What are premade events? If you have an event like
# {chara : j fadein, loc : '1600 900', time : 1}
# which you know you will be using many times, then you can make it 
# into an premade event putting it here with a unique key so that you
# can retrieve it anytime without typing all the commands. All you need 
# to type is that {premade: your_name_for_the_event }
var premade_events:Dictionary = {
	"EXAMPLE" : {"" : "Hello World!"},
}



func call_premade_events(key:String) -> Dictionary:
	if premade_events.has(key):
		return premade_events[key]
	else:
		push_error("!!! Premade event cannot be found. Check spelling.")
		return {}

# End of premade events section
#-------------------------------------------------------------------------
# Other functions that might be used globally

func movement_type(type:String)-> int:
	var m:int = 0
	match type:
		"linear": m = 0
		"sine": m = 1
		"quint": m = 2
		"quart": m = 3
		"quad": m = 4
		"expo": m = 5
		"elastic": m = 6
		"cubic": m = 7
		"circ": m = 8
		"bounce": m = 9
		"back" : m = 10
		_: m = 0
	return m

#----------------------------------------------------------------

func calculate(what:String):
	# what means what to calculate, should be an algebraic expression
	# only dvars are allowed
	var c:DvarCalculator = DvarCalculator.new()
	var res : float = c.calculate(what)
	c.call_deferred('free')
	return res

#----------------------------------------------------------------------
# creates an after image. Used for fadeout effects / other fancy effects

func after_image(pos:Vector2, scale:Vector2, m:Color, fliph:bool, flipv:bool, deg:float, texture:Texture, ft:float,z:int,to_free:Node=null):
	if to_free: # if a to_free node is give, this node will be freed. Used in character fadeout.
		to_free.call_deferred('free')
	
	var dummy:Sprite = Sprite.new()
	dummy.z_index = z+1
	dummy.name = "_dummy"
	dummy.scale = scale
	dummy.position = pos
	dummy.texture = texture
	dummy.flip_h = fliph
	dummy.flip_v = flipv
	dummy.modulate = m
	dummy.rotation_degrees = deg
	stage.add_child(dummy)
	var tween:OneShotTween = OneShotTween.new(dummy, "queue_free")
	dummy.add_child(tween)
	var _e:int = tween.interpolate_property(dummy, "modulate", m, Color(m.r, m.g, m.b, 0), ft,
		Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	_e = tween.start()

#----------------------------------------------------------------------
# Make a save.

func create_thumbnail(width = vn.THUMBNAIL_WIDTH, height = vn.THUMBNAIL_HEIGHT):
	var thumbnail = get_viewport().get_texture().get_data()
	thumbnail.flip_y()
	thumbnail.convert(vn.ThumbnailFormat)
	thumbnail.resize(width, height, Image.INTERPOLATE_BILINEAR)
	# print(thumbnail.get_format())
	var dir:Directory = Directory.new()
	if !dir.dir_exists(vn.THUMBNAIL_DIR):
		var _err = dir.make_dir_recursive(vn.THUMBNAIL_DIR)
		
	var file:File = File.new()
	var save_path:String = vn.THUMBNAIL_DIR + 'thumbnail.dat'
	if file.open(save_path, File.WRITE) == OK:
		# store raw image data
		file.store_var(thumbnail.get_data())
		file.close()
		
# Need to Refactor
func make_a_save(msg = "[Quick Save] " , delay:float = 0.0, offset_by:int = 0):
	yield(get_tree().create_timer(max(0.05, delay)), 'timeout')
	create_thumbnail() # delay is mostly used to control the timing of the thumbnail

	var temp:String = vn.Pgs.currentSaveDesc
	var curId:int = vn.Pgs.currentIndex
	vn.Pgs.currentIndex = vn.Pgs.currentIndex - offset_by
	vn.Pgs.currentSaveDesc = msg + temp
	var path:String = vn.SAVE_DIR + 'save' + str(OS.get_system_time_msecs()) + '.dat'
	write_to_save(path, gather_save_data())
	vn.Pgs.currentSaveDesc = temp
	vn.Pgs.currentIndex = curId
	
func gather_save_data():
	vn.Files.write_to_config()
	# appearance of save slot
	var dt:Dictionary = OS.get_datetime()
	dt['month'] = str(dt['month'])
	dt['day'] = str(dt['day'])
	dt['year'] = str(dt['year'])
	dt['hour'] = str(dt['hour'])
	dt['minute'] = str(dt['minute'])
	dt['second'] = str(dt['second'])
	var datetime:String = dt['month'] + "/" + dt['day'] + "/" + dt['year'] + \
	",  " + dt['hour'] + ":" + dt['minute'] + ':' + dt['second']
	# Actual save
	vn.Pgs.update_playback()
	var data:Dictionary = {'currentNodePath':vn.Pgs.currentNodePath, 'currentBlock': vn.Pgs.currentBlock,\
	'currentIndex': vn.Pgs.currentIndex, 'thumbnail': latest_thumbnail(),\
	'currentSaveDesc': vn.Pgs.currentSaveDesc, 'history':vn.Pgs.history,\
	'playback': vn.Pgs.playback_events, 'datetime': datetime,\
	'dvar':vn.dvar, 'rollback':vn.Pgs.rollback_records, 'chara_pointer':vn.Chs.chara_pointer,
	'name_patches':vn.Chs.chara_name_patch, 'control_state':vn.Pgs.control_state}
	
	# Need to gather non VN data if there is.
	# Not implemented yet.
	
	return data

func latest_thumbnail():
	var dir:Directory = Directory.new()
	if !dir.dir_exists(vn.THUMBNAIL_DIR):
		var _err:int = dir.make_dir_recursive(vn.THUMBNAIL_DIR)
		return "res://gui/default_save_thumbnail.png"

	# so directory already exists
	var _err:int = dir.open(vn.THUMBNAIL_DIR)
	_err = dir.list_dir_begin()
	var file_name:String = "1"
	while file_name != "":
		file_name = dir.get_next()
		if file_name[0] != ".":
			if file_name == 'thumbnail.dat':
				var file:File = File.new()
				if file.open(vn.THUMBNAIL_DIR + file_name, File.READ) == OK:
					dir.list_dir_end()
					var v = file.get_var()
					file.close()
					return v
				else: # file won't open because of some error
					dir.list_dir_end()
					return "res://gui/default_save_thumbnail.png"

func write_to_save(path:String, data:Dictionary):
	var file:File = File.new()
	if file.open_encrypted_with_pass(path, File.WRITE, vn.PASSWORD) == OK:
		file.store_var(data)
		file.close()
	else:
		push_error('Error when loading saves. Probably save data is corrupted.')

#------------------------------------------------------------------------
# Given any sentence with a [dvar] in it, 
# This will prase any dvar into their values and insert back
# to the sentence. Same with special tokens. It doesn't handle nw, and so is different
# from that in GeneralDialog.
func MarkUp(words:String):
	var leng:int = words.length()
	var output:String = ''
	var i:int = 0
	while i < leng:
		var c:String = words[i]
		var inner:String = ""
		if c == '[':
			i += 1
			while words[i] != ']':
				inner += words[i]
				i += 1
				if i >= leng:
					push_error("Please do not use square brackets " +\
					"unless for bbcode or display dvar purposes.")
			if vn.dvar.has(inner):
				output += str(vn.dvar[inner])
			else:
				match inner:
					"sm": output += ";"
					"dc": output += "::"
					"nl": output += "\n"
					"lb": output += "["
					"rb": output += "]"
					_: output += '[' + inner + ']'
		else:
			output += c
		i += 1
	return output
	
#---------------------------------------------------------------------
# read the input and try to understand it
func read(s, json:bool=false):
	if json:
		return
	match typeof(s):
		TYPE_STRING:
			var lower = s.to_lower()
			if lower == "true":
				return true
			elif lower == "false":
				return false
			elif vn.dvar.has(s):
				return vn.dvar[s]
			elif s.is_valid_float():
				return float(s)
			else:
				return false
		TYPE_ARRAY:
			for i in range(s.size()):
				if vn.dvar.has(s[i]):
					s[i] = vn.dvar[s[i]]
			return s
		_:
			return s

#---------------------------------------------------------------------
func eliminate_special_symbols(s:String, pattern_to_kill:String, all:bool=true,
	offset:int = 0) -> String:
	var _e:int = regex.compile(pattern_to_kill) # "(?<!\\\\)_")
	return regex.sub(s, "", all, offset)

#---------------------------------------------------------------------
# Used if you only want your parameters to be between 0 and 1.
func correct_scale(v:Vector2) -> Vector2:
	return Vector2(min(1,abs(v.x)), min(1,abs(v.y)))
	
# No Mouse for control nodes
func no_mouse():
	vn.noMouse = true

func yes_mouse():
	vn.noMouse = false
#---------------------------------------------------------------------
# Global time controller


