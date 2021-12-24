extends GeneralDialog


#---------------------------------- Choices ---------------------------------------
var food_choices = [
	{'Sushi': {'dvar': "mo = mo-10"}},
	{'Fried Rice': {'then' : 'block2'}}
]

#---------------------------------- Core Dialog ---------------------------------------
var main_block = [
	
	# start of content
	{"bg": "condo.jpg"},
	{"screen":"fade in", 'time':2},
	{'chara': "female join", "loc": "1600 600", "expression":""},
	{"female": "Let me show you how to do a timed choice in this example."},
	{"female": "Before you want to implement a timed choice, you have to decide whether " +\
	" or not you want the player to rollback your timed choice."},
	{"female":"There will be no problem if rollback is disabled in your game."},
	{"female":"But if you allow rollback in your game, then you should take a look at the comments "+\
	" in the code in /GodetteVN/SpecialScenes/timedChoice.tscn and also in this scene."},
	
	# optional, useful when you want to turn off quickmenu
	{"sys":"auto_save"}, # make an auto_save, this should be used immediately after
	# a dialog only!!!
	
	# optional
	{"sys":"QM off"}, # hide quick menu to prevent player from saving during a timed choice
	# If you don't do this, then the player can save during the timed choice,
	# and when they load back the choice will no longer be timed
	
	# passing a Godot variable like this only works when your sfx scene has a variable 
	# called params
	{'sfx':"/GodetteVN/SpecialScenes/timedChoice.tscn",'params':5},
	{"female": "What should I eat today?", 'choice' : 'food', 'id':0},
	{'sys':'QM on'}, # if sushi is chosen, QM is still on, so turn this on
	# if out of time, then QM is turned on in out_of_time block, same with fried rice.
	{"female": "It's quite easy, right?"},
	{"female": "There are some technical details you need to consider, like whether you should disable save or hide quick menu."},
	{"female":"But otherwise, it is pretty straight forward."},
	{"female":"Thank you."},
	{"screen":"fade out", 'time':2},
	{'bgm': ''},
	{"GDscene": vn.ending_scene_path}
	
	# end of content
]

var block2 = [
	{'sys':'QM on'},
	{"female" : 'This is how you do a branching depending on choices.'},
	{"female" : 'And this is how you go back to the block before.'},
	{"female": "Please check the code for details."},
	{'then' : 'starter', 'target id' : 0}
]

# out of time
var block3 = [
	{'sys':'QM on'},
	{"female" : "It's taking me too much time to decide."},
	{"female" : 'Whatever... ... I will just cook ramen at home.'},
	{'then' : 'starter', 'target id' : 0}
]


#---------------------------------------------------------------------
# If you change the key word 'starter', you will have to go to generalDialog.gd
# and find start_scene, under if == 'new_game', change to blocks['starter'].
# Other key word you can change at will as long as you're refering to them correctly.
var conversation_blocks = {'starter' : main_block, 'block2' : block2, 'out_of_time':block3}

var choice_blocks = {'food': food_choices}


#---------------------------------------------------------------------
func _ready():
	start_scene(conversation_blocks, choice_blocks, {})
	
	
