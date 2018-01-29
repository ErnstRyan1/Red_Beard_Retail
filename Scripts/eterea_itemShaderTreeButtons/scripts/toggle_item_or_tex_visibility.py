#python
import lx
from lx import eval, eval1, evalN, out, Monitor, args

# toggle_item_or_tex_visibility.py
#
# To toggle visibility both on Items or ShaderTree components.
#
# Created by Cristóbal Vila, based on "duplicate_or_instance.py" script by MonkeybrotherJr
# http://forums.luxology.com/topic.aspx?f=119&t=72024

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
	lx.eval("item.channel textureLayer$enable ?(0|1)")

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
			lx.eval("item.channel locator$visible ?(0|2)")
		
		if len(sitems) > 0 and len(litems) == 0:
			lx.out("shader tree")
			lx.out(sitems)
			lx.eval("item.channel textureLayer$enable ?(0|1)")
			
