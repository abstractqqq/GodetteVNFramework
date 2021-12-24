tool
extends MarginContainer

var in_timeline:bool = false
var dialog_block:PackedScene = preload("res://addons/VNScriptEditor/dialogBlock.tscn")
var choice_block:PackedScene = preload("res://addons/VNScriptEditor/choiceBlock.tscn")
var comment_block:PackedScene = preload("res://addons/VNScriptEditor/commentBlock.tscn")
var condition_block:PackedScene = preload("res://addons/VNScriptEditor/conditionBlock.tscn")

onready var organizer:VBoxContainer = $hbox/vbox/hsplit/notebook/notebookOrganizer

func _new_notebook():
	in_timeline = true
	_clear()
	_new_dialog_block("starter", "#Your story begins here.")
	_new_condition_block()
	
func _new_condition_block(content:String = ""):
	var cond = condition_block.instance()
	organizer.add_child(cond)
	cond.set_content(content)
	cond.disable_delete_button()
	cond.int_type = 2

func _on_newDialogButton_pressed():
	if in_timeline == false: return
	var d = dialog_block.instance()
	d.int_type = 0
	organizer.add_child(d)
	return d
	
func _new_dialog_block(dname:String, content:String):
	var d = _on_newDialogButton_pressed()
	d.set_block_name(dname)
	d.set_content(content)
	if dname == "starter":
		d.disable_name_edit()
		d.disable_delete_button()

func _on_newChoiceButton_pressed():
	if in_timeline == false: return
	var c = choice_block.instance()
	c.int_type = 1
	organizer.add_child(c)
	return c
	
func _new_choice_block(cname:String, content:String):
	var c = _on_newChoiceButton_pressed()
	c.set_block_name(cname)
	c.set_content(content)

func _fname_standardize(t:String)->String:
	t = t.replace('.', '_')
	t = t.replace(' ', '_')
	return t

func _on_saveButton_pressed():
	if in_timeline == false: return
	var file_name:String = _fname_standardize($hbox/vbox/headLayers/head/tlname.text)
	if file_name == '':
		$AcceptDialog.dialog_text = "Please Enter a Timeline Name."
		$AcceptDialog.popup_centered()
	else:
		var file:File = File.new()
		var _e:int = file.open("res://VNScript/" + file_name + '.txt', File.WRITE)
		if _e == OK:
			var all_blocks:Array = organizer.get_children()
			var type_names:Dictionary = {0:'DIALOG',1:'CHOICE',2:'CONDITIONS',-1:'COMMENT'}
			for block in all_blocks:
				var bname:String = block.get_name()
				bname = bname.strip_edges()
				if bname == "": bname = "NAMELESS"
				var btype:int = block.int_type
				var s:String
				match block.int_type:
					0: s = "$--%s--%s" % [type_names[0], bname]
					1: s = "$--%s--%s" % [type_names[1], bname]
					2: s = "$--%s" % [type_names[2]]
					-1: s = "$--%COMMENT"
				
				file.store_line(s)
				var bcontent:String = block.get_plain_text()
				file.store_line(bcontent)
				file.store_line("$--END")
			
			$AcceptDialog.dialog_text = "Saved as .txt successfully. You can find " + file_name + ".txt in "+\
			"the VNscript folder."
			$AcceptDialog.popup_centered()
			file.close()
		else:
			push_error('Error %s when saving.' %_e)

func _on_loadButton_pressed():
	$FileDialog.popup_centered()

func _on_newNBButton_pressed():
	# ask to save before creating new
	_new_notebook()

func _on_newCommentButton_pressed():
	if in_timeline == false: return
	var d = comment_block.instance()
	d.int_type = -1
	organizer.add_child(d)
	return d
	
func _new_comment_block(content:String):
	var d = _on_newCommentButton_pressed()
	d.set_content(content)
	
func _clear():
	$hbox/vbox/headLayers/head/tlname.text=''
	for c in organizer.get_children():
		c.queue_free()
	
func _load_new_text(path):
	var has_starter:bool = false
	var has_cond:bool = false
	var textFile:File = File.new()
	var _e = textFile.open(path, File.READ)
	if _e == OK:
		in_timeline = true
		var blocks:PoolStringArray = textFile.get_as_text().split("$--END")
		for content in blocks:
			content = content.strip_edges()
			if content == "": continue
			var temp:PoolStringArray = content.split("\n", true, 1)
			var t:String = temp[0].strip_edges()
			var text_content:String = ""
			if temp.size()>=2: text_content = temp[1].strip_edges()
			if t.begins_with("$--DIALOG"):
				var dname:String = t.split("--")[2]
				if dname == "starter":
					has_starter = true
					
				_new_dialog_block(dname, text_content)
				
			elif t.begins_with("$--COMMENT"):
				_new_comment_block(text_content)
			elif t.begins_with("$--CONDITIONS"):
				has_cond = true
				_new_condition_block(text_content)
			elif t.begins_with("$--CHOICE"): # $--CHOICE--CHOICE_NAME
				_new_choice_block(t.split("--")[2], text_content)
		if has_starter == false:
			_new_dialog_block("starter", "")
		if has_cond == false:
			_new_condition_block()
		
		textFile.close()
		print("Finished Loading.")
	else:
		push_error("Failed to load text file with error %s."%_e)

func _on_FileDialog_file_selected(path):
	_clear()
	var temp:PoolStringArray = path.split('/')
	var fname:String = temp[temp.size()-1].split('.')[0]
	$hbox/vbox/headLayers/head/tlname.text = fname
	_load_new_text(path)

func _on_jsonButton_pressed():
	if in_timeline == false: return
	_on_saveButton_pressed()
	var dialog_blocks:Dictionary = {}
	var choice_blocks:Dictionary = {}
	var cond_blocks:Dictionary = {}
	for block in organizer.get_children():
		if block.int_type == 0:
			dialog_blocks[block.get_name()] = block.block_to_json()
		elif block.int_type == 1:
			choice_blocks[block.get_name()] = block.block_to_json()
		elif block.int_type == 2:
			cond_blocks = block.block_to_cond()
			
	var output:Dictionary = {"Dialogs":dialog_blocks,"Choices": choice_blocks, "Conditions": cond_blocks}
	var fname:String = $hbox/vbox/headLayers/head/tlname.text
	var file:File = File.new()
	var _e:int = file.open("res://VNScript/" + fname + '.json', File.WRITE)
	if _e == OK:
		print("TO JSON SUCCESS.")
		file.store_line(JSON.print(output,'\t'))
		$AcceptDialog.dialog_text = "To Json success! You can find " + fname + ".json in the VNScript folder."
		$AcceptDialog.popup_centered()
		file.close()
	else:
		push_error("Error with error number %s"%_e)

