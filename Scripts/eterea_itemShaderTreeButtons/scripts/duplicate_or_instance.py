#python
import lx
from lx import eval, eval1, evalN, out, Monitor, args

# duplicate_or_instance.py
#
# To duplicate or instance Items or ShaderTree components.
#
# Created an kindly shared by MonkeybrotherJr in the Luxology Forums
# http://forums.luxology.com/topic.aspx?f=119&t=72024
#
# Quick hack
# Default is duplicate. Use "instance" as an argument if you want to instance instead of duplicating.
# Like this:
# DuplicateorInstance.py instance


arg = lx.args()

if len(arg) > 0 : arg = arg[0]

lx.out(arg)

# arg = "instance"

def whichType(id): 
	try:
	
		layer_types=[]
		shader_types=[]

		itemtypes=["locator", "light","camera","mesh"]
		shadertreetypes=["textureLayer","advancedMaterial","defaultShader","renderOutput","render","polyRender","lightMaterial","envMaterial","environment"]
		# alltypes=["locator","light","camera","transform","translation","rotation","xfrmcore","scene","textureLayer","advancedMaterial","defaultShader","renderOutput","render","polyRender","lightMaterial","envMaterial","mesh","sunLight","environment"]
		
		for i in id:
			lx_item_Name=lx.eval("query sceneservice item.name ? \"%s\"" %i)
			
			for type_member in itemtypes:
				if lx.eval("query sceneservice isType ? %s" %type_member):
					layer_types.append(type_member)
					
			for type_member in shadertreetypes:
				if lx.eval("query sceneservice isType ? %s" %type_member):
					shader_types.append(type_member)
					
		return layer_types, shader_types
	except:
		lx.out('Exception "%s" on line: %d' % (sys.exc_value, sys.exc_traceback.tb_lineno))

		
def makeunique(seq):
    seen = set()
    seen_add = seen.add
    return [ x for x in seq if x not in seen and not seen_add(x)]

	
selmesh = lx.evalN("query sceneservice selection ? all")

types = whichType(selmesh)

litems = makeunique(types[0])
sitems = makeunique(types[1])


if len(litems) == 1 and any("locator" in s for s in litems) and any("textureLayer" in s for s in sitems) :
	lx.out("locator only")
	lx.out(litems)
	lx.out(sitems)
	if arg == "instance":
		lx.eval("texture.instance")
	else:
		lx.eval("texture.duplicate")

else:
	if len(litems) > 0 and len(sitems) > 0:
		eval('dialog.setup "info"')
		eval('dialog.title "Error"')
		eval('dialog.msg "You have both layer items and shader tree items selected. Please select only one type."')
		eval('dialog.open')

		lx.out("bork")
	else:
		if len(litems) > 0 and len(sitems) == 0:
			lx.out("item")
			lx.out(litems)
			if arg == "instance":
				lx.eval("item.duplicate true locator true true")
			else:
				lx.eval("item.duplicate false locator true true")
		
		if len(sitems) > 0 and len(litems) == 0:
			lx.out("shader tree")
			lx.out(sitems)
			if arg == "instance":
				lx.eval("texture.instance")
			else:
				lx.eval("texture.duplicate")
			
