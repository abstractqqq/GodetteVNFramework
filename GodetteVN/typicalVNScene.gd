extends GeneralDialog
# Notice for any scene to be a VN scene, you must extend
# GeneralDialog. (In the future, more options will be given.)

#---------------------------------------------------------------------
# To start using a json, do this
func _ready():
	if auto_start():
		pass
	else:
		print("Start scene failed due to problems with dialog json file.")

