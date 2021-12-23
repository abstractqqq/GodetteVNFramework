extends Camera2D

var shake_amount:float = 250.0
var type : int
const default_offset:Vector2 = Vector2(0,0)

var target_degree:float = self.rotation_degrees
var target_zoom:Vector2 = self.zoom
var target_offset:Vector2 = self.offset

func _ready():
	set_process(false)
	
func _process(delta):
	var shake_vec:Vector2 = Vector2()
	match type: # 0: regular, 1 shake horizontally, 2 shake vertically
		0: shake_vec = vn.Utils.random_vec(Vector2(-shake_amount,shake_amount),\
			Vector2(-shake_amount, shake_amount))
		1: shake_vec = Vector2(0, vn.Utils.random_num(-shake_amount, shake_amount))
		2: shake_vec = Vector2(vn.Utils.random_num(-shake_amount, shake_amount), 0)
		_: shake_vec = Vector2(0,0)
	self.offset = shake_vec * delta + default_offset

func shake_off():
	shake_amount = 250.0
	type = 0
	set_process(false)
	self.offset = default_offset

func camera_shake(ev:Dictionary):
	if ev['camera'] in ["vpunch", "hpunch"]:
		call(ev['camera'], MyUtils.has_or_default(ev,'amount',600), MyUtils.has_or_default(ev,'time',0.9) )
		return 
	var time:float = MyUtils.has_or_default(ev,'time',2.0)
	shake_amount = MyUtils.has_or_default(ev,'amount',250)
	if time < 0.5 and time > 0:
		time = 0.5
	type = 0
	set_process(true and not vn.skipping)
	if time > 0:
		MyUtils.schedule_job(self,"shake_off",time,[])
	
	# Time < 0 means shake until shake_off is called manually.

func vpunch(amount:float=600.0, t:float=0.9):
	shake_amount = amount
	type = 1
	set_process(true and not vn.skipping)
	MyUtils.schedule_job(self,"shake_off",t,[])
	
func hpunch(amount:float=600.0, t:float=0.9):
	shake_amount = amount
	type = 2
	set_process(true and not vn.skipping)
	MyUtils.schedule_job(self,"shake_off",t,[])

func camera_spin(ev:Dictionary):
	var deg:float
	if ev.has('deg'): deg = ev['float']
	else:
		print("!!! Camera spin format error: %s." % ev)
		push_error("Camera spin event must have a 'deg' degree field.")
	var mode:String = MyUtils.has_or_default(ev,'type','linear')
	var sdir:int = MyUtils.has_or_default(ev,'sdir', 1)
	var t:float = MyUtils.has_or_default(ev,'time',1.0) 
	if vn.skipping or mode == "instant":
		rotation_degrees += (sdir*deg)
		target_degree = rotation_degrees
		vn.Pgs.playback_events['camera'] = {'zoom':target_zoom, 'offset':target_offset,\
			'deg':target_degree}
		return 
	
	target_degree = self.rotation_degrees+(sdir*deg)
	vn.Pgs.playback_events['camera'] = {'zoom':target_zoom, 'offset':target_offset,\
		'deg':target_degree}
	var tween:OneShotTween = OneShotTween.new()
	add_child(tween)
	var _e:bool = tween.interpolate_property(self, "rotation_degrees", self.rotation_degrees, target_degree, t,
		vn.Utils.movement_type(mode), Tween.EASE_IN_OUT)
	_e = tween.start()
		
func camera_move(ev:Dictionary) -> void:
	var t:float = MyUtils.has_or_default(ev, 'time', 1)
	var mode:String = MyUtils.has_or_default(ev, 'type', 'linear')
	var off:Vector2
	if ev.has('loc'):
		off = ev['loc']
		vn.Pgs.playback_events['camera'] = {'zoom':target_zoom, 'offset':target_offset,\
			'deg':target_degree}
		if vn.skipping or mode == "instant": 
			self.offset = off
			return 
	else:
		print("!!! Wrong camera event format: " + str(ev))
		push_error("Camera move expects a loc, a time, and type (optional)")
	
	target_offset = off
	var tween:OneShotTween = OneShotTween.new()
	add_child(tween)
	var _e:bool = tween.interpolate_property(self, "offset", self.offset, off, t,
		vn.Utils.movement_type(mode), Tween.EASE_IN_OUT)
	_e = tween.start()
		
func camera_zoom(ev:Dictionary) -> void:
	var mode:String = MyUtils.has_or_default(ev,'type','linear')	
	var off:Vector2 = MyUtils.has_or_default(ev,'loc',Vector2(0,0))
	var t:float = MyUtils.has_or_default(ev,'time',1)
	var zm:Vector2 
	if ev.has('scale'): zm = ev.scale
	else:
		print("!!! Wrong camera zoom format: %s" %ev)
		push_error("Camera zoom must have a scale field.")
	target_zoom = zm
	target_offset = off
	vn.Pgs.playback_events['camera'] = {'zoom':target_zoom, 'offset':target_offset,\
			'deg':target_degree}
	if t < 0.05 or mode == 'instant' or vn.skipping: 
		zoom(zm, off)
		return
	var m:int = vn.Utils.movement_type(mode)
	var tween1:OneShotTween = OneShotTween.new()
	var tween2:OneShotTween = OneShotTween.new()
	add_child(tween1)
	add_child(tween2)
	var _e:bool  = tween1.interpolate_property(self, "offset", self.offset, off, t,
		m, Tween.EASE_IN_OUT)
	_e = tween2.interpolate_property(self, "zoom", self.zoom, zm, t,
		m, Tween.EASE_IN_OUT)
	_e = tween1.start()
	_e = tween2.start()

func zoom(zm:Vector2, off = Vector2(1,1)) -> void:
	# by default, zoom is instant
	self.offset = off
	self.zoom = zm
	target_offset = off
	target_zoom = zm
	
func camera_reset(var _e:Dictionary={}):
	for child in get_children():
		if child.get_class() == "Tween": # base class will be returned
			child.remove_all()
	
	self.offset = default_offset
	self.rotation_degrees = 0
	self.zoom = Vector2(1,1)
	target_degree = 0
	target_zoom = self.zoom
	target_offset = default_offset
	vn.Pgs.playback_events.erase('camera')

func get_camera_data() -> Dictionary:
	return {'offset': target_offset, 'zoom': target_zoom, 'deg':target_degree}
	
func set_camera(d: Dictionary) -> void:
	zoom(d['zoom'], d['offset'])
	if d.has('deg'):
		target_degree = d['deg']
		rotation_degrees = d['deg']
