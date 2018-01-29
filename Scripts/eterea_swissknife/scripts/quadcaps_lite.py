#python
#quads.py by ylaz 2013
#creates quads for selection (poly or edge)
#usage: select either poly group, nGon, or empty edgering (hole) > run script
#works with both closed or open shapes or any quad strips (flats)
#supports any edge ring or boundary as long as total count is 'even'
#creates a poly seelction set under 'Lists' tab for any further work
#you may want to delete that set if nolonger needed.

import math

pref1 = lx.eval('pref.value application.pasteDeSelection ?')
pref2 = lx.eval('pref.value application.pasteSelection ?')
pref3 = lx.eval('pref.value application.copyDeSelection ?')
if pref1 == 1 and pref2 == 1 and pref3 == 1:
	lx.eval('pref.value application.pasteDeSelection 0')
	lx.eval('pref.value application.pasteSelection 0')
	lx.eval('pref.value application.copyDeSelection 0')
	
subP = lx.eval('query layerservice poly.type ? first')
lx.out(subP)

num_meshes = len(lx.evalN("query sceneservice selection ? mesh"))
lx.out(num_meshes)
if num_meshes == 0:
	sys.exit( '::::::::::::::::::::< YOU NEED TO SELECT THE MESH LAYER FIRST >:::::::::::::::::::' )

mode = lx.eval('query layerservice selmode ?')
if mode == 'edge' :
	lx.eval('poly.make auto')
	lx.eval('select.convert polygon')
	lx.eval('select.typeFrom edge')
	lx.eval('select.drop edge')
	lx.eval('select.typeFrom polygon')
	lx.out(mode)

currentMesh = lx.eval('query sceneservice selection ? mesh')
lx.out(currentMesh)
lx.eval('select.typeFrom edge')
lx.eval('select.drop edge')
lx.eval('select.typeFrom polygon')
#lx.eval('workPlane.fitSelect')
lx.eval('select.boundary')
lx.eval('select.editSet temp_edgering1 add')

lx.eval('query layerservice layer.id ? main')
selected_edge_count = lx.eval('query layerservice edge.N ? selected')
total_length = sum(lx.eval('query layerservice edge.length ? %s' % edge)
                   for edge in lx.evalN('query layerservice edges ? selected'))
average_length = total_length/selected_edge_count
if selected_edge_count % 2 != 0:
	sys.exit( '::::::::::::::::::::< YOU NEED EVEN NUMBER OF EDGES SELECTED >:::::::::::::::::::' )
lx.out('avg', average_length)
edge_count_test_minX = math.floor(selected_edge_count / 4)
edge_count_test_minZ = math.floor(selected_edge_count / 4) + 1
square = total_length/5
lx.out('edge_count_test_minX', edge_count_test_minX)
lx.out('edge_count_test_minZ', edge_count_test_minZ)

lx.eval('select.typeFrom polygon')
lx.eval('workPlane.fitSelect')
lx.eval('delete')
lx.eval('layer.new')
layerQ0 = lx.eval('query sceneservice selection ? mesh')

lx.eval('tool.set prim.cube on')
lx.eval('tool.reset')
lx.eval('tool.attr prim.cube sizeX '+str(average_length))
lx.eval('tool.attr prim.cube sizeZ '+str(average_length))
lx.eval('tool.attr prim.cube sizeY 0')

if (selected_edge_count) % 4 == 0:
	lx.eval('tool.attr prim.cube segmentsX '+str(selected_edge_count * .25))
	lx.eval('tool.attr prim.cube segmentsZ '+str(selected_edge_count * .25))
else:
	lx.eval('tool.attr prim.cube segmentsX '+str(edge_count_test_minX))
	lx.eval('tool.attr prim.cube segmentsZ '+str(edge_count_test_minZ))
	lx.out('not divisible by 4')


lx.eval('tool.attr prim.cube segmentsY 0')
lx.eval('tool.attr prim.cube minX '+str(square * -.5))
lx.eval('tool.attr prim.cube minZ '+str(square * -.5))
lx.eval('tool.attr prim.cube minY 0')
lx.eval('tool.attr prim.cube maxX '+str(square * .5))
lx.eval('tool.attr prim.cube maxZ '+str(square * .5))
lx.eval('tool.attr prim.cube maxY 0')
lx.eval('tool.doApply')
lx.eval('tool.set prim.cube off')
lx.eval('tool.set xfrm.smooth on')
lx.eval('tool.setAttr xfrm.smooth strn 1.0')
lx.eval('tool.setAttr xfrm.smooth iter 10000')
lx.eval('tool.doApply')
lx.eval('tool.set xfrm.smooth off')

lx.eval('select.all')
lx.eval('select.editSet temp_poly1 add')####
lx.eval('select.boundary')
lx.eval('select.editSet temp_edgering2 add')
lx.eval('select.drop edge')
lx.eval('cut')

lx.eval('select.item %s set' %(currentMesh))
lx.eval('paste')
lx.eval('select.typeFrom edge')
lx.eval('select.useSet temp_edgering1 select')
lx.eval('select.useSet temp_edgering2 select')
lx.eval('tool.set edge.bridge on')
lx.eval('tool.reset')
lx.eval('tool.setAttr edge.bridge segments 0')
lx.eval('tool.doApply')
lx.eval('tool.set edge.bridge off')
lx.eval('select.typeFrom polygon')
lx.eval('select.useSet temp_poly1 select')####
lx.eval('tool.set xfrm.smooth on')####
lx.eval('tool.setAttr xfrm.smooth strn 1.0')####
lx.eval('tool.setAttr xfrm.smooth iter 10000')####
lx.eval('tool.doApply')####
lx.eval('tool.set xfrm.smooth off')####
lx.eval('select.expand')####
lx.eval('select.editSet POLYS4TWEAKING add')####

lx.eval('select.item %s set' %(layerQ0))
lx.eval('delete')
lx.eval('select.item %s set' %(currentMesh))
lx.eval('select.typeFrom edge')
lx.eval('select.useSet temp_edgering1 select')
lx.eval('select.deleteSet temp_edgering1')
lx.eval('select.deleteSet temp_edgering2')

lx.eval('select.typeFrom polygon')####
lx.eval('poly.convert face subpatch 0')
if subP == 'subdiv':
	lx.eval('poly.convert face subpatch 1')
lx.eval('select.useSet temp_poly1 select')####
lx.eval('select.expand')####
lx.eval('select.deleteSet temp_poly1')####

lx.eval('workPlane.reset')

if pref1 == 1 and pref2 == 1 and pref3 == 1:
	lx.eval('pref.value application.pasteDeSelection 1')
	lx.eval('pref.value application.pasteSelection 1')
	lx.eval('pref.value application.copyDeSelection 1')
elif pref1 == 0 and pref2 == 0 and pref3 == 0:
	lx.eval('pref.value application.pasteDeSelection 0')
	lx.eval('pref.value application.pasteSelection 0')
	lx.eval('pref.value application.copyDeSelection 0')


