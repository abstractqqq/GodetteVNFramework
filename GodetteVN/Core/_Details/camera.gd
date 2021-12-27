extends Camera2D

var _shake_amount:float = 250.0
var _stype : int
const default_offset:Vector2 = Vector2(0,0)

var target_deg:float = self.rotation_degrees
var target_zoom:Vector2 = self.zoom
var target_offset:Vector2 = self.offset

func _ready():
	set_process(false)
	
func _process(delta):
	var shake_vec:Vector2 = Vector2()
	match _stype: # 0: regular, 1 shake horizontally, 2 shake vertically
		0: shake_vec = vn.Utils.random_vec(Vector2(-_shake_amount,_shake_amount),\
			Vector2(-_shake_amount, _shake_amount))
		1: shake_vec = Vector2(0, vn.Utils.random_num(-_shake_amount, _shake_amount))
		2: shake_vec = Vector2(vn.Utils.random_num(-_shake_amount, _shake_amount), 0)
		_: shake_vec = Vector2(0,0)
	self.offset = shake_vec * delta + default_offset

func shake_off():
	_shake_amount = 250.0
	_stype = 0
	set_process(false)
	self.offset = default_offset

func camera_shake(ev:Dictionary):
	if ev['camera'] in ["vpunch", "hpunch"]:
		call(ev['camera'], MyUtils.has_or_default(ev,'amount',600), MyUtils.has_or_default(ev,'time',0.9) )
		return 
	var time:float = MyUtils.has_or_default(ev,'time',2.0)
	_shake_amount = MyUtils.has_or_default(ev,'amount',250)
	if time < 0.5 and time > 0:
		time = 0.5
	_stype = 0
	self.offset = default_offset
	set_process(true and not vn.skipping)
	if time > 0:
		MyUtils.schedule_job(self,"shake_off",time,[])
	
	# Time < 0 means shake until shake_off is called manually.

func vpunch(amount:float=600.0, t:float=0.9):
	_shake_amount = amount
	_stype = 1
	set_process(true and not vn.skipping)
	MyUtils.schedule_job(self,"shake_off",t,[])
	
func hpunch(amount:float=600.0, t:float=0.9):
	_shake_amount = amount
	_stype = 2
	set_process(true and not vn.skipping)
	MyUtils.schedule_job(self,"shake_off",t,[])

func camera_spin(ev:Dictionary):
	for c in get_children():
		if c is OneShotTween and c.name == "spin":
			c.queue_free()
			rotation_degrees = target_deg
			break
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
		target_deg = rotation_degrees
		if vn.Scene:
			vn.Pgs.playback_events['camera'] = {'zoom':target_zoom, 'offset':target_offset,\
				'deg':target_deg}
		return 
	target_deg = self.rotation_degrees+(sdir*deg)
	if vn.Scene:
		vn.Pgs.playback_events['camera'] = {'zoom':target_zoom, 'offset':target_offset,\
			'deg':target_deg}
	var tween:OneShotTween = OneShotTween.new()
	tween.name = "spin"
	add_child(tween)
	var _e:bool = tween.interpolate_property(self, "rotation_degrees", self.rotation_degrees, target_deg, t,
		vn.Utils.movement_type(mode), Tween.EASE_IN_OUT)
	_e = tween.start()
		
func camera_move(ev:Dictionary) -> void:
	for c in get_children():
		if c is OneShotTween and c.name == "mv":
			c.queue_free()
			offset = target_offset
			break
	var t:float = MyUtils.has_or_default(ev, 'time', 1)
	var mode:String = MyUtils.has_or_default(ev, 'type', 'linear')
	var off:Vector2
	if ev.has('loc'):
		off = ev['loc']
		target_offset = off
		if vn.Scene:
			vn.Pgs.playback_events['camera'] = {'zoom':target_zoom, 'offset': off, 'deg':target_deg}
		if vn.skipping or mode == "instant": 
			self.offset = off
			return 
	else:
		print("!!! Wrong camera event format: " + str(ev))
		push_error("Camera move expects a loc, a time, and type (optional)")
	
	target_offset = off
	var tween:OneShotTween = OneShotTween.new()
	tween.name = "mv"
	add_child(tween)
	var _e:bool = tween.interpolate_property(self, "offset", self.offset, off, t,
		vn.Utils.movement_type(mode), Tween.EASE_IN_OUT)
	_e = tween.start()
		
func camera_zoom(ev:Dictionary) -> void:
	for c in get_children():
		if c is OneShotTween and c.name == "zm":
			c.queue_free()
			self.zoom = target_zoom
			break
	var mode:String = MyUtils.has_or_default(ev,'type','linear')
	var t:float = MyUtils.has_or_default(ev,'time',1)
	var zm:Vector2 
	if ev.has('scale'): zm = ev.scale
	else:
		print("!!! Wrong camera zoom format: %s" %ev)
		push_error("Camera zoom must have a scale field.")
	target_zoom = zm
	if vn.Scene:
		vn.Pgs.playback_events['camera'] = {'zoom':target_zoom, 'offset':target_offset,\
			'deg':target_deg}
	if t < 0.05 or mode == 'instant' or vn.skipping: 
		zoom(zm, target_offset)
	else:
		var m:int = vn.Utils.movement_type(mode)
		var tween:OneShotTween = OneShotTween.new()
		tween.name = 'zm'
		add_child(tween)
		var _e:int = tween.interpolate_property(self, "zoom", self.zoom, zm, t,
			m, Tween.EASE_IN_OUT)
		_e = tween.start()

func zoom(zm:Vector2, off = Vector2(1,1)) -> void:
	# by default, zoom is instant
	self.offset = off
	self.zoom = zm
	target_offset = off
	target_zoom = zm
	
func camera_reset(var _e:Dictionary={}):
	for c in get_children():
		if c.get_class() == "Tween": # base class will be returned
			c.queue_free()
	
	self.offset = default_offset
	self.rotation_degrees = 0
	self.zoom = Vector2(1,1)
	target_deg = 0
	target_zoom = self.zoom
	target_offset = default_offset
	vn.Pgs.playback_events.erase('camera')

func get_camera_data() -> Dictionary:
	return {'offset': target_offset, 'zoom': target_zoom, 'deg':target_deg}
	
func set_camera(d: Dictionary) -> void:
	zoom(d['zoom'], d['offset'])
	if d.has('deg'):
		target_deg = d['deg']
		rotation_degrees = d['deg']
