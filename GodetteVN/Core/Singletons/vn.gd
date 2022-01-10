extends Node

#-------------------------------------------------------------------

# Constants
const max_history_size:int = 300 # Max number of history entries
const max_rollback_steps:int = 50 # Max steps of rollback to keep
const max_save_count:int = 50 # Max number of saves a player can make
# It is recommended that max_rollback_steps is kept to a small number, 
# except in testing.
const voice_to_history:bool = true # Should voice be replayable in history?

# Do you want to use a different color for chosen choices? Only works
# if the scene is made spoilerproof.
const show_chosen_choices:bool = true
const chosen_color:Color = Color("#535252")

#-----------------
const GAME_VERSION:String = "0.0"

# size of thumbnail on save slot. Has to manually adjust the TextureRect's size 
# in textBoxInHistory as well
const THUMBNAIL_WIDTH = 175
const THUMBNAIL_HEIGHT = 110
const ThumbnailFormat:int = Image.FORMAT_RGB8
# Want better quality? Ctrl+left click on Image and look for a higher quality
# constant. The result is a much bigger save file for a tiny quality gain.

# Encryption password used for saves
const PASSWORD:String = "nanithefuck!"

#Skip speed, multiple of 0.05
export(int, 2, 5, 1) var SKIP_SPEED = 3 # 3 means 1 left-click per 3 * 0.05 = 0.15 s

# Transitions
const TRANSITIONS_DIR:String = "res://GodetteVN/Core/_Details/Transition_Data/"
const TRANSITIONS:Array = ['fade','sweep_left','sweep_right','sweep_up','sweep_down',
	'curtain_left','curtain_right','pixelate','diagonal']
const PHYSICAL_TRANSITIONS:Array = []

# Other constants used throughout the engine
const DIRECTION:Dictionary = {'up': Vector2.UP, 'down': Vector2.DOWN, 'left': Vector2.LEFT, 'right': Vector2.RIGHT}
# Bad names for dvar
var BAD_NAMES:Dictionary = {"nl":true, "sm":true, 'dc':true,'color':true, 'true':true, 'false':true}
# Bad uids for characters
var BAD_UIDS:Dictionary = {'all':true, '':true, 'voice':true, 'speed':true,'_':true, 'wait':true}

# --------------------------- Other Game Variables ------------------------

# Default CPS
export(float, 5.0, 80.0, 1.0) var cps = 36.0
var cps_map:Dictionary = {'fast':50.0, 'normal':cps, 'slow':20.0, 'instant':0.0, 'slower':10.0}
# Auto Forward
var auto_on:bool = false # Auto forward or not
var auto_time:int = 1 # default val is 1 because in setting screen
# normal has index 1, which means 2s. Slow has index 0, which means 3 seconds
# and fast has index 2 which means 1s.

# ---------------------------- Dvar Varibles ----------------------------

var dvar:Dictionary = {}
onready var Chs:Node = get_node_or_null("Charas")
onready var Notifs:Node = get_node_or_null("Notifs/Notification")
onready var Files:Node = get_node_or_null("Files")
onready var Utils:Node = get_node_or_null("Utils")
onready var Pgs:Node = get_node_or_null("Progress")
onready var Pre:Node = get_node_or_null("Pre")
var Scene = null
#
# ------------------------ Paths ------------------------------
# Paths, should be constants
const title_screen_path:String = "/GodetteVN/titleScreen.tscn"
const start_scene_path:String = '/GodetteVN/typicalVNScene.tscn'
const credit_scene_path:String = "" # if you have one
const ending_scene_path:String = "/GodetteVN/titleScreen.tscn" 

# Important screen paths
const SETTING_PATH:String = "res://GodetteVN/Core/SettingsScreen/settings.tscn"
const LOAD_PATH:String = "res://GodetteVN/Core/SNL/loadScreen.tscn"
const SAVE_PATH:String = "res://GodetteVN/Core/SNL/saveScreen.tscn"
const HIST_PATH:String = "res://GodetteVN/Core/HistoryScreen/historyScreen.tscn"

# Predefined directories
const ROOT_DIR:String = "res:/"
const VOICE_DIR:String = "res://voice/"
const BGM_DIR:String = "res://bgm/"
const AUDIO_DIR:String = "res://audio/"
const BG_DIR:String = "res://assets/backgrounds/"
const CHARA_DIR:String = "res://assets/actors/"
const CHARA_SCDIR:String = "res://GodetteVN/Characters/"
const CHARA_ANIM:String = "res://assets/actors/spritesheet/"
const SIDE_IMAGE:String = "res://assets/sideImages/"
const SAVE_DIR:String = "user://save/"
const SCRIPT_DIR:String = "res://VNScript/"
const THUMBNAIL_DIR:String = "user://temp/"
const FONT_DIR:String = "res://fonts/"

# Will remove these three.


# ------------------------- Game State Variables--------------------------------
# Maybe I should move these variables to somewhere else?

# Special game state variables
var inLoading:bool = false # Is the game being loaded from the save now? (Only used
# in the load system and in the rollback system.)

var inNotif:bool = false # Is there a notification?

var inSetting:bool = false # Is the player in an external menu? Setting/history/save/load
# / your menu

var noMouse:bool = false # Used when your mouse hovers over buttons on quickmenu
# When you click the quickmenu button, because noMouse is turned on, the same
# click will not register as 'continue dialog'.
# This is important when you do scenes like an investigation where players will
# click different objects.

var skipping:bool = false # Is the player skipping right now?

func reset_states():
	inLoading = false
	inNotif = false
	inSetting = false
	noMouse = false
	skipping = false
	auto_on = false
	
#--------------------------------------------------------------------------------
func event_reader(ev:Dictionary)->int:
	var m:int = -1
	match ev:
		{"condition", "then", "else",..}: m = 0
		{"condition",..}: m = 1
		{"screen",..}: m = 2
		{"bg",..}: m = 3
		{"chara",..}: m = 4
		{"weather"}: m = 5
		{"camera", ..}: m = 6
		{"express"}: m = 7
		{"bgm",..}: m = 8
		{'audio',..}: m = 9
		{'dvar'}: m = 10
		{'sfx',..}: m = 11
		{'then',..}: m = 12
		{'extend', ..}, {'ext', ..}: m = 13
		{'premade'}: m = 14
		{"system"},{"sys"}: m = 15
		{'side'}: m = 16
		{'choice',..}: m = 17
		{'wait'}: m = 18
		{'nvl'}: m = 19
		{'GDscene'}: m = 20
		{'history', ..}: m = 21
		{'float', 'wait',..}: m = 22
		{'voice'}: m = 23
		{'id'}, {}: m = 24
		{'call', ..}: m = 25
		{'center',..}: m = 26
		_: m = -1
	
	return m
	
func dvar_initialization():
	$Dvars.dvar_initialization()

func _ready():
	dvar_initialization()

