extends Node

# Might need some serious re design later. IDK
#------------------------------------------------------------------------------
# BASIC GUIDE

	# Global Dvars. (Non temporary)
	# Use vn.dvar["dvar_name"] = ... to access and modify dvars by code

var mo = 0
var tt = true
var le = 0

var obj1 = false
var obj2 = false


	# Temporary Dvars (Scene specific):

	# 1. Declare scene-specific dvars by using vn.dvar["dvar_name"] = whatever
	# in _ready() before auto_start() / start_scene()

	# 2. Use vn.dvar.erase("dvar_name") in _exit_tree()

# ADVANCED GUIDE (Behavior of dvars in VN script):

	#  1. In script, arithemtic operations involving dvars can only be done
	# for number type.
	
	#  2. If dvar is declared to be a string, then + will default to string 
	# concat.
	
	#  3. Say we have a dvar x, then {dvar : x = true} will set x to boolean
	# true despite its initial type and despite the fact that true is a string.

#----------------------------------------------------------------------------
# TO AVOID UNEXPECTED ERRORS:
# DO NOT PUT ANYTHING OTHER THAN VARIBLES IN THIS SCRIPT.
