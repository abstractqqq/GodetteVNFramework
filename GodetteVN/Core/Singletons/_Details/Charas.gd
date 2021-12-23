extends Node

var all_chara:Dictionary = {
	# Narrator, the key empty string "" is its UID!
	"":{"uid":'', "display_name":"","name_color":Color(0,0,0,1),'font':false}
}
var chara_pointer:Dictionary = {}
var chara_name_patch:Dictionary = {}

func _ready():
	for ch in $RegisteredCharacters.stage_characters:
		stage_character(ch)
	for ch in $RegisteredCharacters.spriteless_characters:
		spriteless_character(ch)
	# Maybe free, maybe not free?
	$RegisteredCharacters.queue_free()
	vn.BAD_UIDS.clear() # Not used anymore.

# Keep a record of the path to the scene of the stage character
func stage_character(uid:String) -> void:
	if uid in vn.BAD_UIDS:
		print("Uids in the following list are not allowed: %s." % vn.BAD_UIDS)
		push_error("The uid %s is not allowed."% [uid])
	
	var path:String = vn.CHARA_SCDIR+uid+".tscn"
	var c:Character = load(path).instance()
	var info:Dictionary = {"uid":c.unique_id,"display_name":c.display_name,"name_color":c.name_color,"path":path}
	if c.use_character_font:
		info['font'] = true
		info['normal_font'] = c.normal_font
		info['italics_font'] = c.italics_font
		info['bold_font'] = c.bold_font
		info['bold_italics_font'] = c.bold_italics_font
	else:
		info['font'] = false
	
	all_chara[uid] = info
	c.call_deferred('free')

# Difference is that stage character also has a path field.
func spriteless_character(cdata:Dictionary)->void:
	if cdata.has("uid") and cdata.has("display_name"):
		var uid:String = cdata['uid']
		if uid in vn.BAD_UIDS:
			print("Uids in the following list are not allowed: %s." % vn.BAD_UIDS)
			push_error("The uid %s is not allowed."% [uid])
		
		cdata['name_color'] = MyUtils.has_or_default(cdata,'color', Color.black)
		all_chara[uid] = cdata
	else:
		push_error("!!! Wrong spriteless character format. Need at least uid and display_name fields.")

func get_character_info(uid:String):
	if all_chara.has(uid):
		return all_chara[uid]
	else:
		print("No character with this uid %s is found." % uid )
		print("Nothing is done. There may or may not be a bug because of this.")

# Use case of point_uid_to
# Suppose you have prepared a male ver and female ver of your protagonist's
# character. The character scenes are named a.tscn and b.tscn, and male
# has uid a, and female has uid b.
# In your dialog script, you want to only use a.  
# Before the first VN scenes starts, you ask the player to choose
# male or female. Once the choice is given, in that script, you can call
# chara.point_uid_to("a", "b")
# From this point on, if you have a line like 
# a happy: "Hello!"
# It will be interpreted as b happy: "Hello!"
# This works with save system, and will be different depending on the player's
# choice in each save.
# This is not transitive and only works with two uids.
func point_uid_to(uid:String, to:String):
	chara_pointer[uid] = to
	
func forward_uid(uid:String) -> String:
	if chara_pointer.has(uid):
		return chara_pointer[uid]
	else:
		return uid
#------------------------------------------------------------------------

# Hide the name box when the character is speaking. 
func set_noname(uid:String):
	if all_chara.has(uid):
		all_chara[uid]['no_nb'] = true
	else:
		push_error("The uid %s has not been regiestered when this function is called." % [uid])

func set_new_display_name(uid:String, new_dname:String):
	if all_chara.has(uid):
		all_chara[uid]['display_name'] = new_dname
		chara_name_patch[uid] = new_dname
	else:
		push_error("The uid %s has not been regiestered when this function is called." % [uid])
		
func patch_display_names():
	if not chara_name_patch.empty():
		for uid in chara_name_patch:
			set_new_display_name(uid,chara_name_patch[uid])

