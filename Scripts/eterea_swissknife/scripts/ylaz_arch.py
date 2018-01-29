#python
#arch.py by ylaz 2013
#makes an arch between two selected polys
#works only on geo along world xyz or rotated only in Y
#works only with polys that are flat & mirror images of eachother
#user input: select # of segments you want
#user input: select proper axis using 'axes' popup guide

num_meshes = len(lx.evalN("query sceneservice selection ? mesh"))
lx.out(num_meshes)
if num_meshes == 0:
	sys.exit( '::::::::::::::::::::< YOU NEED TO SELECT THE MESH LAYER FIRST >:::::::::::::::::::' )

mode = lx.eval('query layerservice selmode ?')
current_selE = lx.eval('query layerservice edge.N ? selected')
if mode == 'edge' and current_selE >= 6: 
	lx.eval('poly.make auto')
	lx.eval('select.convert polygon')
elif mode == 'edge' and current_selE < 6:
	sys.exit( '::::::::::::::::::::< NEEDS 6 EDGES MINIMUM >:::::::::::::::::::' )

mode = lx.eval('query layerservice selmode ?')
if mode != 'polygon': 
  sys.exit( '::::::::::::::::::::< RUN SCRIPT IN POLY MODE >:::::::::::::::::::' )

mode = lx.eval('query layerservice selmode ?')
current_selP = lx.eval('query layerservice poly.N ? selected')
if mode == 'polygon' and current_selP < 2: 
  sys.exit( '::::::::::::::::::::< SELECT 2 POLYS MINIMUM >:::::::::::::::::::' )

def popup(input,type,name,init):
	if lx.eval("query scriptsysservice userValue.isDefined ? arch.%s" % input) == 0 :
		lx.eval("user.defNew arch.%s %s momentary" % (input,type))
		lx.eval("user.def arch.%s username \"%s\"" % (input,name))
		lx.eval("user.value arch.%s %s" % (input,init))
	lx.eval("user.value arch.%s" % input)
	return lx.eval("user.value arch.%s ?" % input)

segments=popup('segments','integer','segments','11')

wk = lx.eval('view3d.showWorkPlane ?')
lx.out(wk)
lx.eval('view3d.showWorkPlane false')
subP = lx.eval('query layerservice poly.type ? first')
lx.out(subP)
axes = lx.eval('workPlane.drawAxes ?')
lx.out(axes)
if axes == 'off':
	lx.eval('workPlane.drawAxes on')

currentMesh = lx.eval('query sceneservice selection ? mesh')
lx.eval('select.editSet tempselPq1 add')
lx.eval('select.connect')

lx.eval('cut')
lx.eval('layer.new')
layerQ0 = lx.eval('query sceneservice selection ? mesh')
lx.eval('paste')
lx.eval('poly.convert face subpatch 0')
lx.eval('select.useSet tempselPq1 select')
lx.eval('cut')
lx.eval('layer.new')
lx.eval('paste')
layerQ1 = lx.eval('query sceneservice selection ? mesh')
lx.eval('select.all')
lx.eval('!!poly.merge')
lx.eval('select.less')
lx.eval('select.convert edge')
lx.eval('copy')
lx.eval('select.typeFrom polygon')
lx.eval('select.all')
lx.eval('select.convert vertex')
lx.eval('select.typeFrom polygon')
lx.eval('tool.set poly.spikey on')
lx.eval('tool.setAttr poly.spikey factor 0.0')
lx.eval('tool.doApply')
lx.eval('tool.set poly.spikey off')
lx.eval('select.drop polygon')
lx.eval('select.typeFrom vertex')
lx.eval('select.invert')
lx.eval('poly.make auto')
lx.eval('select.typeFrom polygon')
lx.eval('select.polygonInvert')
lx.eval('delete')
lx.eval('select.typeFrom vertex')
lx.eval('select.all')
lx.eval('select.typeFrom polygon')
lx.eval('poly.subdivide ccsds')
lx.eval('select.typeFrom vertex')
lx.eval('select.all')
lx.eval('select.convert edge')
lx.eval('workPlane.fitSelect')
lx.eval('delete')
lx.eval('paste')
lx.eval('select.all')


if not lx.eval('query scriptsysservice userValue.isDefined ? axis'):
	lx.eval('user.defNew axis integer')
lx.eval('user.def axis list X_clockwise;X_counterClockwise;Y_clockwise;Y_counterClockwise;Z_clockwise;Z_counterClockwise')
lx.eval('user.value axis')
Qaxis = lx.eval('user.value axis ?')
lx.out(Qaxis)

lx.eval('tool.clearTask axis')
lx.eval('tool.set actr.origin on')
lx.eval('tool.set "Radial Sweep" on')
lx.eval('tool.reset')

if Qaxis == 'X_clockwise':
	lx.eval('tool.attr gen.helix axis 0')
	lx.eval('tool.attr gen.helix end -180.0')
elif Qaxis == 'X_counterClockwise':
	lx.eval('tool.attr gen.helix axis 0')
	lx.eval('tool.attr gen.helix end 180.0')
elif Qaxis == 'Y_clockwise':
	lx.eval('tool.attr gen.helix axis 1')
	lx.eval('tool.attr gen.helix end -180.0')
elif Qaxis == 'Y_counterClockwise':
	lx.eval('tool.attr gen.helix axis 1')
	lx.eval('tool.attr gen.helix end 180.0')
elif Qaxis == 'Z_clockwise':
	lx.eval('tool.attr gen.helix axis 2')
	lx.eval('tool.attr gen.helix end -180.0')
elif Qaxis == 'Z_counterClockwise':
	lx.eval('tool.attr gen.helix axis 2')
	lx.eval('tool.attr gen.helix end 180.0')

lx.eval('tool.attr gen.helix sides '+str(segments))
lx.eval('tool.attr effector.sweep cap0 false')
lx.eval('tool.attr effector.sweep cap1 false')
lx.eval('tool.attr gen.helix offset 0.0')
lx.eval('tool.attr center.auto cenX 0')
lx.eval('tool.attr center.auto cenY 0')
lx.eval('tool.attr center.auto cenZ 0')
lx.eval('tool.doApply')
lx.eval('tool.set "Radial Sweep" off')
lx.eval('tool.clearTask axis')
lx.eval('select.drop edge')
lx.eval('cut')

lx.eval('select.item %s set' %(layerQ0))
lx.eval('paste')
lx.eval('!!mesh.cleanup true true true true true true true true true true')
lx.eval('!!vert.merge fixed')
lx.eval('!!poly.align')
lx.eval('cut')
lx.eval('select.item %s set' %(currentMesh))
lx.eval('paste')
lx.eval('select.item %s set' %(layerQ0))
lx.eval('delete')
lx.eval('select.item %s set' %(layerQ1))
lx.eval('delete')
lx.eval('select.item %s set' %(currentMesh))
lx.eval('select.typeFrom polygon')
lx.eval('select.deleteSet tempselPq1')
lx.eval('workPlane.reset')
lx.eval('poly.convert face subpatch 0')
if subP == 'subdiv':
	lx.eval('poly.convert face subpatch 1')

if wk == 1:
	lx.eval('view3d.showWorkPlane 1')
else:
	lx.eval('view3d.showWorkPlane 0')
if axes == 'off':
	lx.eval('workPlane.drawAxes off')