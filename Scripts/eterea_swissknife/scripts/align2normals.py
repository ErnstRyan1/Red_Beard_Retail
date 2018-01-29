#python
#align2normals.py by ylaz 2013
#aligns center to poly normal
#usage: select all the meshes > run script
def aligner ():
	currentMesh = lx.eval('query sceneservice selection ? mesh')
	lx.eval('select.typeFrom polygon')
	lx.eval('workPlane.fitSelect')
	lx.eval('select.center %s' %(currentMesh))
	lx.eval('matchWorkplanePos')
	lx.eval('matchWorkplaneRot')
	lx.eval('workPlane.reset')
meshes = lx.eval('query sceneservice selection ? mesh')
for j in meshes:
	lx.eval('select.item %s set' %(j))
	aligner()
for m in meshes:
	lx.eval('select.item %s add' %(m))
lx.eval('select.typeFrom item')

	

