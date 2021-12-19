extends Node

var rng = RandomNumberGenerator.new()

# Related to randomness

func random_num(lower:float, upper:float):
	rng.randomize()
	return rng.randf_range(lower, upper)

func random_vec(x:Vector2, y:Vector2):
	return Vector2(random_num(x.x,x.y),random_num(y.x,y.y))
	
func random_int(lower:int=0, upper:int=100):
	rng.randomize()
	return rng.randi_range(lower, upper)
	
func randval_from_list(list:Array):
	return list[random_int(0,list.size()-1)]
	
func bounded(v:float, b:Vector2, lower_incl:bool=true, upper_incl:bool=true)->bool:
	var truth: bool
	if lower_incl: truth = (v <= b.x)
	else: truth = (v < b.x)
	if upper_incl: truth = truth and (v <= b.y)
	else: truth = truth and (v < b.y)
	return truth
	
#------------------------------------------------------------
# Free Children
func free_children(n:Node):
	for c in n.get_children():
		c.call_deferred('free')

#------------------------------------------------------------
# OneShot Job Scheduler
func schedule_job(n:Node, method:String, wtime:float, params:Array, jname:String=''):
	var timer:Timer = Timer.new()
	timer.one_shot = true
	timer.wait_time = wtime
	if jname != '':
		timer.name = jname
	var _e:bool = timer.connect('timeout',self,'_run_job',[timer,n,method,params])
	add_child(timer)
	timer.start()
	
func has_job(jname:String)->bool:
	for c in get_children():
		if c is Timer and c.name == jname:
			return true
	return false

func kill_job(jname:String):
	for c in get_children():
		if c is Timer and c.name == jname:
			c.queue_free()

func _run_job(t:Timer, n:Node, m:String, params:Array):
	t.queue_free()
	if is_instance_valid(n):
		n.callv(m, params)
#------------------------------------------------------------
# Dictionary manipulation
func has_or_default(ev:Dictionary, fname:String , default):
	if ev.has(fname): return ev[fname]
	else: return default
