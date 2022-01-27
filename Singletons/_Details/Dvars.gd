extends Node

func dvar_initialization():
	var temp_node:Node = Node.new()
	var ban_list:Dictionary = {"Script Variables":false}
	for p in temp_node.get_property_list():
		ban_list[p['name']] = false
	temp_node.queue_free()
	for dv in $RegisteredDvars.get_property_list():
		var n:String = dv['name']
		if ban_list.has(n):
			continue
		
		if not n.is_valid_identifier():
			push_error("A valid dvar name should only contain letters, digits, and underscores and the "+\
		"first character should not be a digit.")
		
		if n in vn.BAD_NAMES:
			push_error("The name %s cannot be used as a dvar name." % [n])
			
		var val = $RegisteredDvars.get(n)
		if typeof(val) in [TYPE_ARRAY, TYPE_DICTIONARY]:
			vn.dvar[n] = val.duplicate(true)
		else:
			vn.dvar[n] = $RegisteredDvars.get(n)
	
	vn.BAD_NAMES.clear() # Not used anymore
	print("Intialized all dvars.")
