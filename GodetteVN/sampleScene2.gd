extends GeneralDialog


#---------------------------------- Choices ---------------------------------------
var food_choices = [
	{'Sushi': {'dvar': "mo = mo-10"}},
	{'Ramen': {'then' : 'block2'}}
]

#---------------------------------- Dialogs ---------------------------------------
var main_block = [
	# start of content
	{"bg": "condo.jpg"},
	{"dvar":'mo += 50*2-mo'},
	{'screen':'pixelate in'},
	{'call': 'simple_print', 'params':['test ', 123]},
	{"vo": "[color=#0000FF]This[/color] is vo %talking.%", 'speed': 10.0},
	{"bg": "condo.jpg", 'diagonal':2, 'color':Color.blueviolet},
	{"vo": "If you haven't noticed, I am a character without a namebox._________________ You can set this "+\
	"attribute for any talking characters in characterManager.gd."},
	{'wait':2},
	{"bg": "condo.jpg", 'sweep_down':2, 'color':Color.pink},
	{'female':'Hello, hello,_________ %is it time for me to show up?'},
	{'chara': "female fadein", "loc": "1600 600",'time':0.5, 'expr':'smile1'},
	{'chara':'female move', 'time':3, 'loc': Vector2(500,600),'expr':'wink'},
	{'extend': 'This is an extend statement~', 'speed':'slower'},
	{'wait':1},
	{'ext':'As you can see, extend works for anything in between.'},
	{'extend':'There are two %imperfections% :1. the statements are saved separately in history.', 'speed':25.0},
	{'extend':'2. If you rollback, then the speed of dialog will be default speed, regardless of your speed input.'},
	{"female flip": "When you're switching scenes, many things disappear, and need to be reset. Music persists."},
	{"chara":"female fadeout", 'time':0.5},
	{"screen": "curtain_left out", 'time':1},
	{'chara': "female fadein", "loc": "R", 'type':'quad', 'time':0.4},
	{"screen": "curtain_left in", 'time':1},
	{"female":"In case you haven't noticed, I am joining at location R, which stands for random."},
	{"female":"This is a new feature. For all events with the field loc, you can put R for a random position."},
	{"chara":"female fadeout", 'time':0.5},
	{"bg": "condo.jpg", "fade": 1.5},
	{"chara":"female fadein", "loc": "500 600",'time':0.5},
	{"female":"This is certainly not ideal for character's joining location, but this is just an example."},
	{'chara':'female move', 'loc':"1400 600", 'expression':'smile2'},
	{'female': 'Let me show you a cool new feature.'},
	{'female': "Suppose I am very confused now."},
	{'chara':'female add', 'path':'/GodetteVN/SpecialScenes/questionMark.tscn','at':'head'},
	{'female':"If you look at the code, it says the special effect question mark should show up "+\
	"at 'head'."},
	{'female':'That means you can define points on your character and show special '+\
	"effects at those points."},
	{"female":"Currently, there is no way to save these effects, so the special effect should be "+\
	"temporary, like question marks, or blood bleeding, or other short flashy stuff."},
	{'female':'The special uid "all" can also be used here provided that all characters have the '+\
	"point defined."},
	{'female':"(Technical side: if for some characters the point head is defined, and some not "+\
	" then this will be applied to all character with that point and with in_all = true)"},
	{'female': "To see how this point 'head' is defined, you can go to female.tscn and see."},
	{'female': 'The idea is to create Node2D as subnodes, and rename it beginning with a _ .'},
	{'female': 'I believe that will add a lot room for customization, provided you know how to make these '+\
	"special effects in Godot. (And don't forget to queuefree them.)"},
	{"female": "What should I eat today?", 'choice' : 'food'},
	{'id':0},
	{"female":"Ok, let me show you how to put an image on the side."},
	{'side':'female_smile.png'},
	{'female':'Lastly, I want show you how to use centered text!'},
	{'center':"Center text can be called like this", "who":'female','font':'/fonts/ARegular.tres', 'wait':2},
	{"female":"Notice that although my name is not displayed in the centered text, in history," +\
	" my name is still displayed."},
	{"female":"This is because it looks visually awkward to display a name for a centered text."},
	{"female": "By default, the narrator will be the one who says the centered text, but you can "+\
	" change this by adding an optional who field. If you have voice for that line, you can add an "+\
	"optional voice field too."},
	{'female':'You can even add in a custom font for centered text.'},
	{"female":"But remember that the name is not going to be displayed in centered text. (only in history)"},
	{"female": "When your game ends, do the following."},
	{"female": "Use a GDscene change to go back to your designated ending scene. In this demo, the ending "+\
	"scene will be the title screen. But don't forget to change it to your actual ending if you "+\
	"have one!"},
	{"female": "Okay, thank you so much for bearing with me!"},
	{"screen":"fade out", 'time':2},
	{'bgm': ''},
	{"GDscene": vn.ending_scene_path}
	
	# end of content
]

var block2 = [
	{"female" : 'This is how you do a branching depending on choices.'},
	{"female" : 'And this is how you go back to the block before.'},
	{"female": "Please check the code for sample2."},
	{'then' : 'starter', 'target id' : 0}
]


#---------------------------------------------------------------------
# If you change the key word 'starter', you will have to go to generalDialog.gd
# and find start_scene, under if == 'new_game', change to blocks['starter'].
# Other key word you can change at will as long as you're refering to them correctly.
var dialog_blocks = {'starter' : main_block, 'block2' : block2}

var choice_blocks = {'food': food_choices}


#---------------------------------------------------------------------
func _ready():
	start_scene(dialog_blocks, choice_blocks, {}, vn.Pgs.load_instruction)

#---------------------------------------------------------------------

func simple_print(a,b):
	# test function for the {call:.. } event
	print(a,b)
