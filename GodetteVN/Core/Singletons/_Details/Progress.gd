extends Node

#-------------Game Control State---------------------------
var control_state:Dictionary = {
	'right_click': true,
	'quick_menu':true,
	'boxes': true,
	'scroll':true
}
#----------------------------------------------------------
# 
var currentNodePath:String

# Current block name
var currentBlock:String 

# Current index in the block
var currentIndex:int 

# Current save description, if there is one
var currentSaveDesc:String = ""

# Playback/lasting events are defined as events that should be remembered when loading
# back from a save. Example: weather effects. If it's raining and player saves, then when
# loading back, the player should see the rain too.

# If player saves in the middle of nvl mode,
# then when loading back, we need to restore all the nvl text.
var nvl_text:String = ''

var playback_events:Dictionary = {'bg':'', 'bgm':{'bgm':''}, 'charas':[], 'nvl': ''\
	,'speech':'', 'control_state': control_state}

func get_latest_onstage():
	playback_events['charas'] = stage.all_on_stage()

func get_latest_nvl():
	playback_events['nvl'] = nvl_text

func update_playback():
	playback_events['nvl'] = nvl_text
	playback_events['charas'] = stage.all_on_stage()

#-------------------------------------------------------------------------------
# "new_game" = start from new
# "load_game" = start from given dialog block and index.
var load_instruction:String = "new_game"
#-------------------------------------------------------------------------------

#------------------------------------------------------
# List of history entries
var history:Array = []


#-------------Rollback Helper---------------------------
# List of rollback records
var rollback_records:Array = []

#------------------------------------------------------
# Utility functions

# hist_data is an array [uid, text, voice(optional)]
func updateHistory(hist_data:PoolStringArray):
	if (history.size() > vn.max_history_size):
		history.remove(0)
		
	hist_data[1] = hist_data[1].strip_edges()
	history.push_back(hist_data)
	
func updateRollback():
	get_latest_nvl() # get current nvl text.
	get_latest_onstage() # get current on stage characters.
	if rollback_records.size() > vn.max_rollback_steps:
		rollback_records.remove(0)
	
	var cur_playback:Dictionary = playback_events.duplicate(true)
	var rollback_data:Dictionary = {'currentBlock': currentBlock, 'currentIndex': currentIndex, \
	'currentSaveDesc': currentSaveDesc, 'playback': cur_playback, 'dvar':vn.dvar.duplicate(),
	'name_patches':vn.Chs.chara_name_patch.duplicate()}
	rollback_records.push_back(rollback_data)
	
func remove_nonmatch_records(): # Read the comments carefully if you want to use this function.
	# remove all rollback records that are not in current block.
	# Will check from the end, and remove everything before the last entry
	# to the current block. This means if we went from block A to block B and then
	# to block A and then to block B, only records that happened from the second A to
	# the second B will be kept. 
	var j:int = rollback_records.size()
	var constant:int = j
	for i in range(j):
		if rollback_records[j-i-1]['currentBlock'] != currentBlock:
			j = j - i - 1
			break
	if j < constant:
		for _i in range(j):
			rollback_records.remove(0)

func checkSkippable()->bool:
	if vn.Files.system_data.has(currentNodePath):
		if currentIndex > vn.Files.system_data[currentNodePath][currentBlock]:
			return false
	elif vn.Scene.dialog_json != '' and vn.Files.system_data.has(vn.Scene.dialog_json):
		if currentIndex > vn.Files.system_data[vn.Scene.dialog_json][currentBlock]:
			return false
	return true

func makeSnapshot():
	updateRollback()
	if checkSkippable() == false:
		vn.Files.system_data[currentNodePath][currentBlock] = currentIndex

func resetControlStates(to:bool=true):
	# By default, resets everything back to true
	for k in control_state:
		control_state[k] = to

# Suppose player A returns to main without saving, then the state of playback events should be
# refreshed.
func resetPlayback():
	resetControlStates()
	rollback_records.clear()
	playback_events = {'bg':'', 'bgm':{'bgm':''}, 'charas':[], 'nvl': '','speech':'', 'control_state': control_state}
