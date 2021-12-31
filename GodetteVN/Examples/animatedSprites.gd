extends GeneralDialog


#---------------------------------- Choices ---------------------------------------

#---------------------------------- Core Dialog ---------------------------------------
var main_block = [
	
	# start of content
	{"screen":"fade in", 'time':1},
	{'chara': "gt join", "loc": "800 650"},
	{"gt": "Hello Everyone!"},
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
	{"chara":"gt spin", "sdir": -1, "time":2, "deg": 720, "type":"expo"},
	{"chara":"gt move", "loc": Vector2(200,650), "time":2, 'type': "expo"},
	{"chara": "gt jump", "amount":800, "time":2},
	{'wait':3},
	{'gt':"Today let's go over some advanced dialog dynamics."},
	{'gt':"You can now d_____e__________l________________a____________________y "+\
	"printing any letter or __________%word% by any amount of time easily."},
	{"gt":"What's even better is that now you can %10%change the speed of dialog "+\
	"with absolute ease! %40.12%That's right! With absolute ease!"},
	{'chara':'gt scale', 'scale':Vector2(3,3)},
	{'chara':'gt move', 'loc':'700 1200'},
	{'chara':'gt spin', 'sdir':1, 'deg':20},
	{'gt':'I said [font=res://fonts/ABigger.tres]____________%ANY% _________________%WORD%[/font] '+\
	"can be delayed for any time. And %10%text speed can be changed at any point!!!"},
	{'chara':'gt spin', 'sdir':-1, 'deg':40},
	{'gt':'Do you hear that???'},
	{'chara':'gt spin', 'sdir':1, 'deg':20},
	{'chara':'gt scale', 'scale':Vector2(1,1)},
	{'chara':'gt move', 'loc': Vector2(800, 650)},
	{'gt':'Thank you for your %attention%.'},
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
	start_scene(conversation_blocks, choice_blocks, {}, vn.Pgs.load_instruction)
	
