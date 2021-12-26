extends Node

var bgm:String = ''

func play_bgm(path:String, vol:float = 0.0):
	finish_anim()
	$bgm1.stop()
	$bgm1.volume_db = vol
	$bgm1.stream = load(path)
	$bgm1.play()
	
func fadeout(time:float):
	finish_anim()
	bgm = ''
	var vol:float = $bgm1.volume_db
	var animation:Animation = Animation.new()
	var track_index:int = animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(track_index, "bgm1:volume_db")
	animation.set_length(time)
	animation.track_insert_key(track_index, 0, vol)
	animation.track_insert_key(track_index, time, -80)
	$AnimationPlayer.add_animation("fadeout", animation)
	$AnimationPlayer.play("fadeout")

func fadein(path:String, time:float, vol:float = 0.0):
	finish_anim()
	$bgm1.stop()
	$bgm1.stream = load(path)
	var animation:Animation = Animation.new()
	var track_index:int = animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(track_index, "bgm1:volume_db")
	animation.set_length(time)
	animation.track_insert_key(track_index, 0, -80)
	animation.track_insert_key(track_index, time, vol)
	$AnimationPlayer.add_animation("fadein", animation)
	$AnimationPlayer.play("fadein")
	$bgm1.play()
	
	
func play_sound(path, vol = 0):
	$sound.volume_db = vol
	$sound.stream = load(path)
	$sound.play()
	
func play_voice(path, vol = 0):
	$voice.stop()
	$voice.volume_db = vol
	$voice.stream = load(path)
	$voice.play()
	
func stop_voice():
	$voice.stop()

func stop_bgm():
	bgm = ''
	$bgm1.stop()
	
func pause_bgm():
	$bgm1.set_stream_paused(true)
	
func resume_bgm():
	$bgm1.set_stream_paused(false)

func finish_anim():
	var cur_anim:String = $AnimationPlayer.current_animation
	if cur_anim == "fadein":
		$AnimationPlayer.stop()
		$AnimationPlayer.remove_animation(cur_anim)
	elif cur_anim != '':
		var delta:float = $AnimationPlayer.current_animation_length - $AnimationPlayer.current_animation_position
		$AnimationPlayer.advance(delta+1)

func _on_AnimationPlayer_animation_finished(anim_name):
	$AnimationPlayer.remove_animation(anim_name)
