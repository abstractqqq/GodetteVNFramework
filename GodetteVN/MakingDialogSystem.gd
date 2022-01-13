extends DialogSkeleton

# This shows how you can build a bare minumum dialog system with the given
# Dialog Skeleton Class.


var chara_data:Dictionary = {
	"Godette": ["res://assets/actors/gt_default.png"]
}

var main_dialog:Dictionary = {
	"starter": [
		{"bg":"condo.jpg","diagonal":2, "color":Color.purple},
		{"chara":"Godette", "loc":Vector2(1000,600)},
		{"who":"Godette", "speech":"Hello World!"},
		{"choice":"c1"},
		{"who":"Godette", "speech":"Hello World again!"}]
	
	,"branch1":[
		{"who":"Godette", "speech":"Goodbye World!"},
		{}
	]
}

var choices:Dictionary = {
	"c1":[{"choice_text":"1","choice_event":{"then":"branch1"}}
		,{"choice_text":"2","choice_event":{"who":"???","speech":"What is the meaning of life?"}}
		,{"choice_text":"3","choice_event":{}}]
}

# Customizable

func interpret_events(ev:Dictionary) -> void:
	match ev:
		{}:
			auto_load_next()
		{"speech", "who"}:
			say(ev['who'], ev['speech'], vn.cps)
		{"chara","loc"}:
			character_enter(ev['chara'], ev['loc'])
		{"choice"}:
			generate_chocies(ev)
		{"then"}:
			.then(ev)
		{"bg",..}:
			var need_2_yield:bool = .change_background(ev)
			if need_2_yield:
				yield(screen, "transition_finished")
			auto_load_next()


func say(uid:String, words:String, cps:float=0.0, _args:Dictionary={}) -> void:
	speaker.bbcode_text = uid
	cur_db.set_dialog(words, cps)
	waiting_acc = true
	
func generate_chocies(ev:Dictionary) -> void:
	var cname:String = ev['choice']
	choiceContainer.visible = true
	for c in all_choices[cname]:
		var cbar:TextureButton = load(choice_bar).instance()
		cbar.connect("choice_made", self, "_choice_signal_receiver")
		cbar.setup_choice(c['choice_text'], c['choice_event'])
		choiceContainer.add_child(cbar)
	
func load_event_at_index(idx:int) -> void:
	interpret_events(current_block[idx]) 

func auto_load_next(_forw:bool=true) -> void:
	if check_end_of_block(current_index+1):
		print("End of Dialog.")
	else:
		current_index += 1
		load_event_at_index(current_index)
	
#--------------------------------------------------------------------------------
func character_enter(uid:String, loc:Vector2):
	var s:Sprite = Sprite.new()
	s.position = loc
	s.name = uid
	s.texture = load(chara_data[uid][0])
	$CharacterGroup.add_child(s)
	auto_load_next()

#--------------------------------------------------------------------------------
func _ready():
	vn.Scene = self
	all_choices = choices
	all_blocks = main_dialog
	current_index = 0
	current_bname = "starter"
	current_block = main_dialog[current_bname]
	load_event_at_index(current_index)
	
#--------------------------------------------------------------------------------
func _input(ev:InputEvent):
	if ev.is_action_pressed("ui_accept"):
		if waiting_acc:
			waiting_acc = false
			auto_load_next()

func _choice_signal_receiver(ev:Dictionary):
	interpret_events(ev)
	for c in choiceContainer.get_children():
		c.queue_free()
	choiceContainer.visible = false
