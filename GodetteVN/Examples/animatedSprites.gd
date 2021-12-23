extends GeneralDialog


#---------------------------------- Choices ---------------------------------------

#---------------------------------- Core Dialog ---------------------------------------
var main_block = [
	
	# start of content
	{"screen":"fade in", 'time':1},
	{'chara': "gt join", "loc": "1600 650"},
	{"gt": "Here we demonstrate how to do animations (spritesheet)."},
	{"chara": "gt add", "at":"head", "path":"/GodetteVN/sfxScenes/questionMark.tscn"},
	{"gt cry": "As long as you have the spritesheet ready, animation is as easy as drag and drop."},
	{"express": "gt crya"},
	{"gt": "This baka is making me cry... ..."},
	{'gt': "Yes, animation is compatible with all other character actions likes shake and move."},
	{"chara": "gt shake"},
	{'wait': 2},
	{'gt default': "I see someone!"},
	{"express": "gt wavea"},
	{"chara": "gt jump"},
	{"chara": "gt move", "loc": "1000 650"},
	{'gt': "So you see that some animations are repeating and some are not. This can be set in "+\
	"the scene of this character (In my case gt.tscn)."},
	{"gt": "Hey!"},
	{"gt stara": "Ahha isn't that my favorite... ..."},
	{'gt': "I want to try something fancy"},
	{"chara": "gt jump", "amount":800, "time":2},
	{"chara":"gt spin", "sdir": -1, "time":2, "deg": 720, "type":"expo"},
	{"chara":"gt move", "loc": Vector2(200,650), "time":2, 'type': "expo"},
	{'wait':3},
	{"screen":"fade out", 'time':1},
	{"GDscene": vn.ending_scene_path}
	# end of content
]



#---------------------------------------------------------------------
# If you change the key word 'starter', you will have to go to generalDialog.gd
# and find start_scene, under if == 'new_game', change to blocks['starter'].
# Other key word you can change at will as long as you're refering to them correctly.
var conversation_blocks = {'starter' : main_block}

var choice_blocks = {}


#---------------------------------------------------------------------
func _ready():
	start_scene(conversation_blocks, choice_blocks, {})
	
