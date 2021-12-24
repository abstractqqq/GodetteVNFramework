extends TextureButton
class_name ClickableObject

# Should be in a node2d, which is a subnode of the VN scene.
# Otherwise, dialog_node will be the wrong node

export(String) var change_to_on_click = ''

func _ready():
	var _e : int = self.connect('pressed', self, '_on_pressed')
	
func _on_pressed():
	# This will give us the root of the vn scene.
	var dialog_node = get_parent().get_parent()
	if dialog_node.allow_rollback:
		vn.Pgs.makeSnapshot()
	if dialog_node.waiting_acc or dialog_node.idle:
		dialog_node.generate_nullify()
		dialog_node.change_block_to(change_to_on_click, 0)

