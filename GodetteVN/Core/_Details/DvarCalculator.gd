extends Object
class_name DvarCalculator

# converts evaluates string of arithmetic expression

const prec:Dictionary = {"(":0 , "+":1, "-": 1, "*":2, "/":2, "^":3}
const left:String = "("
const right:String = ")"
var expr:String 

func calculate(expression:String):
	expr = expression
	return _eval_a(_infix_postfix(expression))

func _paren_check(st : String) -> bool:
	var stack:Array = []
	for s in st:
		if s == left:
			stack.push_back(s)
		if s == right:
			var t:String = stack.pop_back()
			if t != left:
				return false
	
	if stack.size() == 0: return true
	else: return false
		
func _format_expression(ex:Array)->Array:
	var output:Array = []
	for e in ex:
		if e.is_valid_float() or vn.dvar.has(e):
			output.push_back(e)
		else: 
			# not number
			e = e.replace(" ", "") # remove all whitespace
			for a in e:
				output.push_back(a)
	return output

func _infix_postfix(ex:String):
	if _paren_check(ex):
		var regexMatch:String = "(\\d+\\.?\\d*)|(\\+)|(-)|(\\*)|(\\^)|(\\()|(\\))|(/)"
		for v in vn.dvar:
			if typeof(vn.dvar[v]) in [TYPE_INT, TYPE_REAL]:
				if v in ex:
					regexMatch += "|("+v+")"
				
		var regex:RegEx = RegEx.new()
		var _e:int = regex.compile(regexMatch)
		var results:Array = []
		for result in regex.search_all(ex):
			results.push_back(result.get_string())
		
		results = _format_expression(results)
		var output:Array = []
		var stack:Array = []
		for le in results:
			if le.is_valid_float() or vn.dvar.has(le):
				output.push_back(le)
			elif le == left:
				stack.push_back(le)
			elif le == right:
				var top:String = stack.pop_back()
				while top != left:
					output.push_back(top)
					top = stack.pop_back()
					
			elif le in prec:
				while (stack.size()!=0) and prec[stack[stack.size()-1]]>=prec[le]:
					output.push_back(stack.pop_back())
				stack.push_back(le)
				
		while stack.size() > 0:
			output.push_back(stack.pop_back())
		return output
	else:
		push_error("Parenthesis!")
		
func _eval_a(ex_arr:Array) -> float:
	var stack:Array = []
	for e in ex_arr:
		if e.is_valid_float():
			stack.push_back(float(e))
		elif vn.dvar.has(e):
			if typeof(vn.dvar[e]) in [TYPE_REAL, TYPE_INT]:
				stack.push_back(vn.dvar[e])
			else:
				push_error("The type of dvar {0} is not number. Cannot evaluate.".format({0:e}))
		else:
			var second:float = stack.pop_back()
			var first: float 
			if stack.empty(): first = 0.0
			else: first = stack.pop_back()
			match e:
				"+": stack.push_back(first+second)
				"-": stack.push_back(first-second)
				"*": stack.push_back(first*second)
				"^": stack.push_back(pow(first,second))
				"/": 
					if second == 0:push_error("Division by 0 encountered in %s." %expr)
					else:stack.push_back(first/second)
				_: push_error("Unrecognized operator %s in expression %s." % [e,expr])

	return stack.pop_back()
