extends GeneralDialog


#---------------------------------- Choices ---------------------------------------

#---------------------------------- Core Dialog ---------------------------------------
var main_block = [
	
	# start of content
	{"screen":"fade in", 'time':1},
	{'chara': "gt join", "loc": "800 650"},
	{'dvar':'mo = 1*2'},
	{"gt": "Hello Everyone!"},
	{"gt":"Let's check how much money we have: [mo]."},
	{'gt':"Today let's go over some advanced dialog dynamics."},
	{'gt':"You can \\_ now d_____e__________l________________a____________________y "+\
	"printing any letter or __________%word% by any amount of time easily."},
	{"gt":"[color=#123F01]What's even ______________better is that[/color] now you can %10%change the speed of dialog "+\
	"with absolute ease! %40.13%That's right! With absolute ease!"},
	{'chara':'gt scale', 'scale':Vector2(3,3)},
	{'chara':'gt move', 'loc':'700 1200'},
	{'chara':'gt spin', 'sdir':1, 'deg':20},
	{'gt':'I said [font=res://fonts/ABigger.tres]____________%ANY% _________________%WORD%[/font] '+\
	"can be delayed for any time. And %10%text speed can be changed at any point!!!"},
	{'chara':'gt spin', 'sdir':-1, 'deg':40},
	{'gt':'Did you hear that???'},
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
	
