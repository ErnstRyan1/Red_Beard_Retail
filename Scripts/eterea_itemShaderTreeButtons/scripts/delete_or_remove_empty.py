#python

# delete_or_remove_empty.py
#
# If nothing is selected, delete empty meshes using "deleteEmptyLayers.py" script by Mark Rossi aka Onim
# If Items OR Shader Tree Components are selected, delete them
#
# Created by Cristóbal Vila, based on "group_or_add_grouplocator.py" script by MonkeybrotherJr
# http://forums.luxology.com/topic.aspx?f=119&t=72024

import lx

selmesh = lx.eval1("query sceneservice selection ? all")

lx.out(selmesh)

if selmesh:
    lx.eval("delete")
else:
    lx.eval("@deleteEmptyLayers.py")