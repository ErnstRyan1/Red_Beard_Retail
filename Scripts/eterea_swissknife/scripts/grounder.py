#python
#small modification from ground_selected.py (to avoid intermediate dialogs) by ylaz 2013 
#this script grounds selected components in the selected mesh/layer
#currently works on single mesh
#if components have translations, the bounding box will be used
#usage: select desired component/s in poly mode, select the layer & run script.
#partial poly selection is okay.
#arguments: use'1' to ground to work plane and use '0' world Y 0

num_meshes = len(lx.evalN("query sceneservice selection ? mesh"))
lx.out(num_meshes)
if num_meshes == 0:
	sys.exit( '::::::::::::::::::::< YOU NEED TO SELECT THE MESH LAYER FIRST >:::::::::::::::::::' )

wkp = lx.args()[0]
lx.out(wkp)
wkpF = float(wkp)

#move the selected components to new mesh
original_mesh = lx.eval("query sceneservice selection ? mesh")
lx.out('original mesh = ', original_mesh)
lx.eval("select.connect")
lx.eval("cut")
lx.eval("layer.new")
lx.eval("item.name layerQ1 mesh")#
lx.eval("paste")
	
lx.eval("select.typeFrom item")
lx.eval("layer.swap")

current_meshes = lx.evalN("query sceneservice selection ? mesh")
lx.out('2nd = ', current_meshes)
lx.eval("select.drop item")

for item in current_meshes:
	lx.eval("select.item {%s} add" % item)
	lx.eval("layer.setVisibility {%s}" % item)

lx.eval("item.channel locator$lock on")
lx.eval("layer.swap")
lx.eval("layer.unmergeMeshes")
lx.eval("select.all")
lx.eval("center.bbox bottom")

if wkpF == 1:
    lx.eval("item.alignToWorkplane yxz")
else:
    lx.eval("transform.channel pos.Y 0.0")

lx.eval("!!layer.mergeMeshes true")
lx.eval("select.drop item")

for item in current_meshes:
	lx.eval("select.item {%s} add" % item)
	lx.eval("item.channel locator$lock off")

for item in current_meshes:
	lx.eval("select.item {%s} add" % item)
	lx.eval("layer.setVisibility {%s}" % item)

lx.eval("layer.swap")
lx.eval("select.drop item")
lx.eval("select.typeFrom polygon")

#put them back in the original mesh
lx.eval("select.item {layerQ1} set mesh")
lx.eval("cut")
lx.eval("item.delete")
lx.eval('select.item %s set' %(original_mesh))
lx.eval("paste")
lx.eval("select.typeFrom polygon")