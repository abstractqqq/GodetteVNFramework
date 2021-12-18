extends ColorRect # or TextureRect

var draggable:bool = false
var resizable:bool = false

var _following:bool = false
var _resizing:bool = false
var _drag_start_pos:Vector2 = Vector2()
var _resize_start_pos:Vector2 = Vector2()

var ratio = Vector2()

func _ready():
	ratio.x = get_node('dialogBoxCore').rect_size.x / self.rect_size.x
	ratio.y = get_node('dialogBoxCore').rect_size.y / self.rect_size.y
	if not resizable:
		$resizeHandler.queue_free()

func _on_dialogBox_mouse_entered():
	if draggable:
		vn.noMouse = true

func _on_dialogBox_mouse_exited():
	if draggable:
		vn.noMouse = false

func _on_dialogBox_gui_input(event):
	if event is InputEventMouseButton and draggable:
		if event.get_button_index() == 1:
			_following = !_following
			_drag_start_pos = get_local_mouse_position()

func _process(_delta):
	if _resizing:
		var mouse_pos:Vector2 = get_global_mouse_position()
		var diff:Vector2 = mouse_pos - _resize_start_pos
		diff.y = -diff.y
		rect_size += diff
		rect_position.y = mouse_pos.y
		$textBox.rect_size= Vector2(rect_size.x * ratio.x, rect_size.y * ratio.y)
		_resize_start_pos = mouse_pos
		get_parent().reset_namebox_pos()
	if _following:
		self.rect_position = (get_global_mouse_position() - _drag_start_pos)
		get_parent().reset_namebox_pos()

func _on_resizeHandler_gui_input(event):
	if event is InputEventMouseButton and resizable:
		if event.get_button_index() == 1:
			_resizing = !_resizing
			_resize_start_pos = get_global_mouse_position()

func hide_resize_handler():
	$resizeHandler.visible = false

func _on_resizeHandler_mouse_entered():
	if resizable:
		vn.noMouse = true

func _on_resizeHandler_mouse_exited():
	if resizable:
		vn.noMouse = false
