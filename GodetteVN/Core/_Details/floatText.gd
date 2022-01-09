extends RichTextLabel
class_name FloatText

var speed:float = 30.0
var dir:Vector2 = Vector2()
var move:bool = false

func set_movement(d:Vector2, sp:float = 30.0):
	dir = d.normalized()
	speed = sp
	move = true
	
func _process(delta):
	if move:
		rect_position += speed*delta*dir

func set_font(font:String):
	self.add_font_override("normal_font", load(font))

func display(tx:String, t:float, in_t:float, loc:Vector2, font:String = ''):
	if font != '':
		self.add_font_override("normal_font", load(font))
	self.rect_position = loc
	self.bbcode_text = tx
	var tw:Tween = Tween.new()
	var _e:bool = tw.interpolate_property(self,'modulate',Color(1,1,1,0), Color(1,1,1,1), in_t, 
		Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	_e = tw.interpolate_property(self,'modulate',Color(1,1,1,1), Color(1,1,1,0), t, 
		Tween.TRANS_LINEAR, Tween.EASE_IN_OUT, in_t)
	var _err:int = tw.connect("tween_all_completed", self, "queue_free")
	add_child(tw)
	_e = tw.start()
