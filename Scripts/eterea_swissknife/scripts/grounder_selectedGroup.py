#python
#small modification from ground_selectedGroup.py (to allow workplane use) by ylaz 2013 
#this script grounds selected components as a group in the selected mesh/layer
#currently works on single mesh
#if components have translations, the bounding box will be used
#usage: select desired component/s in poly mode, select the layer & run script.
#if no polys are selected, everything in the layer will be grounded

num_meshes = len(lx.evalN("query sceneservice selection ? mesh"))
lx.out(num_meshes)
if num_meshes == 0:
	sys.exit( '::::::::::::::::::::< YOU NEED TO SELECT THE MESH LAYER FIRST >:::::::::::::::::::' )

wkp = lx.args()[0]
lx.out(wkp)
wkpF = float(wkp)

lx.eval("select.typeFrom polygon")
mode = lx.eval('query layerservice selmode ?')
current_selP = lx.eval('query layerservice poly.N ? selected')
if mode == 'polygon' and current_selP == 0: 
	lx.eval("select.all")
original_mesh = lx.eval('query sceneservice selection ? mesh')
lx.out('original mesh = ', original_mesh)
lx.eval('select.connect')
lx.eval("cut")
lx.eval('layer.new')
lx.eval('paste')
temp_mesh = lx.eval('query sceneservice selection ? mesh')
lx.eval('select.typeFrom item')
lx.eval('center.bbox bottom')

if wkpF == 1:
    lx.eval("item.alignToWorkplane yxz")
else:
    lx.eval("transform.channel pos.Y 0.0")

lx.eval('cut')
lx.eval('item.delete')
lx.eval('select.item %s set' %(original_mesh))
lx.eval('paste')
lx.eval('select.typeFrom polygon')