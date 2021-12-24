extends Node2D

# You can use the original Godot timer. The object timer will save you a few 
# lines of code though, but it is harder to understand. 
# It is a helper class I made to assist me with some other stuff.
# It turns out we can use it here too

# If your interested, you can go to character.gd to see more usage of the 
# objectTimer



# I know that params is going to be an integer which is time
var params = 0


# This scene should be put immediately before a choice (*)
var initialInd:int = 0
var initialBname:String = ""

func _ready():
	initialInd = vn.Pgs.currentIndex
	initialBname = vn.Pgs.currentBlock
	$Label.text = str(params)
	var obj_timer:ObjectTimer = ObjectTimer.new(self,params,1,"_do")
	add_child(obj_timer)

func _process(_delta):
	# if the player made a choice in time, then are two cases
	# 1. The choice leads to another dialog block (branching)
	# 2. The choice leads to the next event in your current block
	# which means |currentInd - game.currentIndex | > 1
	
	if initialBname != vn.Pgs.currentBlock:
		# player has reached another block, the choice must have been made
		
		# To prevent rollback, you can add this line
		# Note: if it is rolled back, the choice will no longer be timed
		# vn.Pgs.rollback_records = []
		
		# always needed 
		self.queue_free()
	else:
		# initialInd is initialized when the sfx line is run.

		if vn.Pgs.currentIndex - initialInd > 1 or  initialInd - vn.Pgs.currentIndex >= 1:
			# The first is the case when the player makes a choice and the 
			# choice goes down the same dialog block.
			# The second case is when the player rolls back.
			# vn.Pgs.rollback_records = []
			self.queue_free()


# This function will be called by obj_timer, and that means
# 1 sec has been passed. The argument will not be used. (It's an argument
# passed in by objectTimer.)
func _do(_params):
	params -= 1
	$Label.text = str(params)
	if params <= 0:
		# I know that this scene will be a direct subnode of the root node
		# in my VN scene
		var par:Node = get_parent()
		
		# false is needed if you do not want your choice to be rolled back
		par.on_choice_made({'then':'out_of_time'} , false)
		# If you want to go to another scene, like YOU FAILED SCENE, you can use directly
		# get_tree().change_scene_to() here
		
		# The 'out_of_time' name here can be part of the params, (if you're using
		# GDScript, then params can be an array. See how is params passed in
		# from GeneralDialog in sfx_player.) 
		# That will make this example scene reusable for many different
		# timed choices leading to different blocks.
		
		
		# Don't forget to clear itself
		self.queue_free()
