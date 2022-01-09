extends Node

var bgm:String = ''

func play_bgm(path:String, vol:float = 0.0):
	bgm = path
	$bgm1.stop()
	$bgm1.volume_db = vol
	$bgm1.stream = load(vn.BGM_DIR + path)
	$bgm1.play()
	
func fadeout(time:float, type:String="linear"):
	for c in $bgm1.get_children():
		if c is OneShotTween:
			c.queue_free()
	bgm = ''
	var vol:float = $bgm1.volume_db
	var tw:OneShotTween = OneShotTween.new()
	var _e:bool = tw.interpolate_property($bgm1,"volume_db",vol, -80.0,time,
		vn.Utils.movement_type(type), Tween.EASE_OUT)
	add_child(tw)
	_e = tw.start()

func fadein(path:String, time:float, vol:float = 0.0, type:String="linear"):
	for c in $bgm1.get_children():
		if c is OneShotTween:
			c.queue_free()
	
	$bgm1.stop()
	$bgm1.stream = load(vn.BGM_DIR + path)
	$bgm1.play()
	var tw:OneShotTween = OneShotTween.new()
	var _e:bool = tw.interpolate_property($bgm1,"volume_db",-80.0,vol,time,
		vn.Utils.movement_type(type), Tween.EASE_IN)
	$bgm1.add_child(tw)
	_e = tw.start()
	
func play_sound(path:String, vol:float = 0.0, b:String="Effects", dir:String=vn.AUDIO_DIR):
	var v:AudioStreamPlayer = AudioStreamPlayer.new()
	v.volume_db = vol
	v.bus = b
	v.stream = load(dir + path)
	var _e:int = v.connect("finished",v,"queue_free")
	add_child(v)
	v.play()

func stop_bgm():
	bgm = ''
	$bgm1.stop()
