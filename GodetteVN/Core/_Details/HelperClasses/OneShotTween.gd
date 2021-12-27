extends Tween
class_name OneShotTween

var call_back_node: Node
var call_method: String
var call_arg: Array
var free_cb : bool # free the call_back_node or not?

func _init(node:Node=null, method:String="", arg:Array=[], free:bool=false):
	self.call_back_node = node
	self.call_method = method
	self.call_arg = arg
	self.free_cb = free
	var _e:int = self.connect("tween_all_completed", self, "queue_free")
	
func queue_free():
	if is_instance_valid(call_back_node) and call_method != "":
		call_back_node.callv(call_method, call_arg)
		.queue_free()
	elif is_instance_valid(call_back_node) and call_back_node.is_a_parent_of(self):
		if free_cb:
			call_back_node.queue_free()
		else:
			.queue_free()
	else:
		if free_cb:
			call_back_node.queue_free()
		.queue_free()
