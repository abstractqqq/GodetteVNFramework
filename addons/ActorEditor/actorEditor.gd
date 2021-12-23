tool
extends PanelContainer

const image_exts:PoolStringArray = PoolStringArray(['png', 'jpg', 'jpeg'])
const chara_dir:String = "res://assets/actors/"
const chara_scdir:String = "res://GodetteVN/Characters/"

var cur_uid:String = ""
var dname:String = ""
var temp_dict:Dictionary = {}
var anim_dict:Dictionary = {}
var sc:Vector2 = Vector2(1,1)
var found:bool = false
var _ready_to_generate:bool = false

var parent # set in actor plugin

func _on_Button_pressed():
	$hbox/editOptions/assetInfo/spriteInfo/spriteOptions.clear()
	$hbox/editOptions/assetInfo/animInfo/animOptions.clear()
	cur_uid = $hbox/editOptions/main/LineEdit.text
	if cur_uid == "":
		found = false
		return
	
	temp_dict.clear()
	anim_dict.clear()
	# Expression data
	var index:int = -1
	var exp_list:Array = _get_chara_sprites(cur_uid)
	for i in range(exp_list.size()):
		var temp:String = exp_list[i].split(".")[0].split("_")[1]
		temp_dict[temp] = exp_list[i]
		$hbox/editOptions/assetInfo/spriteInfo/spriteOptions.add_item(temp)
		if temp == "default":
			index = i
			$hbox/preview.texture = load(chara_dir+temp_dict[temp])

	# There has to be a static sprite called default.
	if index == -1:
		_fail_to_find()
		push_error("Unable to find a default expression for %s." %[cur_uid])
		return
	else: found = true
		
	$hbox/editOptions/assetInfo/spriteInfo/spriteOptions.select(index)
	
	var anim_lists:Array = _get_chara_sprites(cur_uid, "anim")
	for e in anim_lists:
		var t:PoolStringArray = e.split(".")[0].split("_")
		anim_dict[t[1]] = e
		$hbox/editOptions/assetInfo/animInfo/animOptions.add_item(t[1])
		
	$hbox/editOptions/main/LineEdit.release_focus()
		
func _fail_to_find():
	found = false
	$hbox/editOptions/assetInfo/spriteInfo/spriteOptions.clear()
	$hbox/preview.texture = null

func _on_generateButton_pressed():
	if found == false: return
	_ready_to_generate = true
	$charaGenPopup.dialog_text = ("You are about to generate a character scene for uid: {0}" +\
	", which will have the path:\n\n {1}.").format({0:cur_uid,1:(chara_scdir+cur_uid+".tscn")})
	$charaGenPopup.dialog_text += "\n\nYou can pick a name color and do more customization for the "+\
	 "character in the generated scene."
	$charaGenPopup.popup_centered()


func _on_charaGenPopup_confirmed():
	if _ready_to_generate == false: return
	else:
		var packed_scene:PackedScene = PackedScene.new()
		var ch:Character = (load("res://addons/ActorEditor/CharacterTemplate.tscn")).instance()
		var expSheet:SpriteFrames = SpriteFrames.new()
		for ex in temp_dict:
			var t:Resource = load(chara_dir + temp_dict[ex])
			if expSheet.has_animation(ex):
				expSheet.remove_animation(ex)
			expSheet.add_animation(ex)
			expSheet.add_frame(ex, t)
			expSheet.set_animation_loop(ex, false)
			
		for an in anim_dict:
			if expSheet.has_animation(an):
				expSheet.remove_animation(an)
			expSheet.add_animation(an)
			expSheet.set_animation_loop(an, false)
		
		var sheetName:String = chara_scdir+cur_uid+"_expressionSheet.tres"
		if ResourceSaver.save(sheetName, expSheet) == OK:
			print("Expression sheet for %s saved." %[cur_uid])
		else:
			print("Some error occurred when trying to save spriteSheet.")
		
		ch.name = cur_uid
		ch.set_sprite_frames(load(sheetName))
		ch.unique_id = cur_uid
		packed_scene.pack(ch)
		var chara_scene_path:String = chara_scdir+cur_uid+".tscn"
		if ResourceSaver.save(chara_scene_path, packed_scene) == OK:
			print("Character successfully saved to scene.")
		else:
			print("Some error occurred when trying to save as scene.")
		
		_ready_to_generate = false
		parent.get_editor_interface().open_scene_from_path(chara_scene_path)

# -------------------------------------------------------------------------

func _get_chara_sprites(uid, which = "sprite")->Array:
	# This method should only be used in development phase.
	# The exported project won't work with dir calls depending on
	# what kind of paths are passed.
	var sprites:Array = []
	var dir:Directory = Directory.new()
	if which in ['anim','animation','spritesheet']:
		which = "res://assets/actors/spritesheet/"
	else: which = chara_dir
		
	if !dir.dir_exists(which):
		var _e:int = dir.make_dir_recursive(which)
	
	dir.open(which)
	dir.list_dir_begin()
	var pic:String = "1"
	while pic != "":
		pic = dir.get_next()
		if not pic.begins_with("."):
			var temp:PoolStringArray = pic.split(".")
			var ext:String = temp[temp.size()-1]
			if ext in image_exts:
				var pic_id:String = (temp[0].split("_"))[0]
				if pic_id == uid:
					sprites.append(pic)
				
	dir.list_dir_end()
	return sprites

func _on_spriteOptions_item_selected(index):
	if found:
		var expr:String = $hbox/editOptions/assetInfo/spriteInfo/spriteOptions.get_item_text(index)
		$hbox/preview.texture = load(chara_dir+temp_dict[expr])
