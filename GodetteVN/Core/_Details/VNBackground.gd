extends TextureRect
signal bg_changed(path)

func bg_change(path: String):
	if path == '':
		texture = null
	else:
		texture = load(vn.BG_DIR + path)
		emit_signal("bg_changed", path)
