extends Control

func _ready():
	$musicBox/musicSettings/musicVolume.text = str(vn.Files.system_data['bgm_volume'] + 50)
	$effectBox/effectSettings/effectVolume.text = str(vn.Files.system_data['eff_volume'] + 50)
	$voiceBox/voiceSettings/voiceVolume.text = str(vn.Files.system_data['voice_volume'] + 50)
	$musicBox/musicSettings/volumeSlider.value = vn.Files.system_data['bgm_volume']
	$effectBox/effectSettings/effectVolumeSlider.value = vn.Files.system_data['eff_volume']
	$voiceBox/voiceSettings/voiceSlider.value =vn.Files.system_data['voice_volume']
	if vn.Files.system_data['bgm_volume'] <= $musicBox/musicSettings/volumeSlider.min_value:
		AudioServer.set_bus_mute(1,true)
	else:
		AudioServer.set_bus_volume_db(1, vn.Files.system_data['bgm_volume'])
		
	if vn.Files.system_data['eff_volume'] <= $effectBox/effectSettings/effectVolumeSlider.min_value:
		AudioServer.set_bus_mute(2,true)
	else:
		AudioServer.set_bus_volume_db(2, vn.Files.system_data['eff_volume'])
	
	if vn.Files.system_data['voice_volume'] <= $voiceBox/voiceSettings/voiceSlider.min_value:
		AudioServer.set_bus_mute(3, true)
	else:
		AudioServer.set_bus_volume_db(2, vn.Files.system_data['voice_volume'])
	
	$autoBox/autoSpeed.add_item('Slow')
	$autoBox/autoSpeed.add_item('Normal')
	$autoBox/autoSpeed.add_item('Fast')
	$autoBox/autoSpeed.select(vn.Files.system_data['auto_time'])
	
func _on_volumeSlider_value_changed(value):
	vn.Files.system_data['bgm_volume'] = value
	$musicBox/musicSettings/musicVolume.text = str(value + 50)
	AudioServer.set_bus_volume_db(1, value)
	if value <= $musicBox/musicSettings/volumeSlider.min_value:
		AudioServer.set_bus_mute(1,true)
	else:
		AudioServer.set_bus_mute(1,false)
		
func _on_effectVolumeSlider_value_changed(value):
	vn.Files.system_data['eff_volume'] = value
	$effectBox/effectSettings/effectVolume.text = str(value + 50)
	AudioServer.set_bus_volume_db(2, value)
	if value <= $effectBox/effectSettings/effectVolumeSlider.min_value:
		AudioServer.set_bus_mute(2,true)
	else:
		AudioServer.set_bus_mute(2,false)

func _on_voiceSlider_value_changed(value):
	vn.Files.system_data['voice_volume'] = value
	$voiceBox/voiceSettings/voiceVolume.text = str(value + 50)
	AudioServer.set_bus_volume_db(3, value)
	if value <= $voiceBox/voiceSettings/voiceSlider.min_value:
		AudioServer.set_bus_mute(3,true)
	else:
		AudioServer.set_bus_mute(3,false)

func _on_autoSpeed_item_selected(index):
	vn.Files.system_data['auto_time'] = index
	vn.auto_time = 3 - index # 

func _exit_tree():
	vn.Files.write_to_config()
