#python
#ground_selected_v2.py by ylaz 2013 
#this script grounds selected components in the selected mesh/layer
#currently works on single mesh
#if components have translations, the bounding box will be used
#usage: select desired component/s in poly mode, select the layer & run script.
#user inputs: check appropriate options to suit your needs
#if nothing i schecked, script grounds all to world Y 0

lx.eval('view3d.showCenters select')
num_meshes = len(lx.evalN("query sceneservice selection ? mesh"))
lx.out(num_meshes)
if num_meshes == 0:
	sys.exit( '::::::::::::::::::::< YOU NEED TO SELECT THE MESH LAYER FIRST >:::::::::::::::::::' )
	
def panel(var,type,dialog):
	if lx.eval("query scriptsysservice userValue.isDefined ? %(var)s" % vars()) == 0 :
		lx.eval("user.defNew %(var)s %(type)s momentary" % vars())
	if dialog != None :
		lx.eval("user.value %(var)s" % vars())
	return lx.eval("user.value %(var)s ?" % vars())
x=panel("x","boolean"," x ?")
x=lx.eval("user.value x ?")
left=panel("left","boolean"," left ?")
left=lx.eval("user.value left ?")
z=panel("z","boolean"," z ?")
z=lx.eval("user.value z ?")
front=panel("front","boolean"," front ?")
front=lx.eval("user.value front ?")
y=panel("y","boolean"," y ?")
y=lx.eval("user.value y ?")


lx.eval('view3d.showCenters select')
lx.eval("select.typeFrom polygon")
mode = lx.eval('query layerservice selmode ?')
current_selP = lx.eval('query layerservice poly.N ? selected')
if mode == 'polygon' and current_selP == 0: 
	lx.eval('select.all')

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
#lx.eval("center.bbox bottom")

if x == 1 and left == 1:
	lx.eval("center.bbox left")
    	lx.eval("item.alignToWorkplane xzy")
elif x == 1 and left == 0:
    lx.eval("center.bbox right")
    lx.eval("item.alignToWorkplane xzy")
elif z == 1 and front == 1: 
	lx.eval("center.bbox front")
    	lx.eval("item.alignToWorkplane zxy")
elif z == 1 and front == 0:
    lx.eval("center.bbox back")
    lx.eval("item.alignToWorkplane zxy")
elif y == 1: 
	lx.eval("center.bbox bottom")
	lx.eval("item.alignToWorkplane yzx")
else:
	lx.eval("center.bbox bottom")
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
lx.eval('view3d.showCenters none')