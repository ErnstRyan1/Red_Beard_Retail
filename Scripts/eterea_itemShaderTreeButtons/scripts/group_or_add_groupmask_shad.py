#python
import lx
from lx import eval, eval1, evalN, out, Monitor, args

# Quick hack
# group_or_add_groupmask_shad.py
#
# If nothing is selected, add a Group Maks in the ShaderTree
# If ShaderTree components are selected, group them under a Group Mask
#
# Created an kindly shared by MonkeybrotherJr in the Luxology Forums
# http://forums.luxology.com/topic.aspx?f=119&t=72024


selmesh = evalN("query sceneservice selection ? all")

seltypes = []

for i in selmesh:
	dummy=eval("query sceneservice item.name ? \"%s\"" %i)

	if eval("query sceneservice isType ? textureLayer"):
		seltypes.append("textureLayer")
			
if len(seltypes) > 0 :
	out("shader tree")
	out(seltypes)
	eval("shader.group")
else:
	eval("shader.create mask")