#python
#REVISED FOR 701 april 2013.
#quadcaps_univ_wHoldingEdges.py by ylaz sept 2012
#this version adds 2 holding edges
#update: now works on both cylinders and spherical meshes
#usage: select 4 verts that represent the 2 axies (eg, z & x)
#when using on spherical shapes, be sure to select 4 verts at
#the widest part of the poly selection
#then select the polys where u want the cap, run script
#also be sure to not have any holes in the object

#making the temp guide plane for workplane alignment
currentMesh = lx.eval("query sceneservice selection ? mesh")
lx.out(currentMesh)

lx.eval("select.editSet temp_set add")

lx.eval("select.typeFrom vertex true")
lx.eval("copy")
lx.eval("layer.new")
lx.eval("item.name layerQ0 mesh")#
lx.eval("select.paste")
lx.eval("select.typeFrom vertex true")#diagnostic
lx.eval("select.vertex add 0 all 0")#diagnostic
lx.eval("poly.make auto")
lx.eval("select.typeFrom polygon true")
lx.eval("workPlane.fitSelect")
#below omitted for 701 sp2 8/13
#lx.eval("workPlane.rotate 1 45.0") 
lx.eval("select.item {layerQ0} set mesh")
lx.eval("item.delete")

#prepping polys for quads
lx.eval('select.item %s set' %(currentMesh))
lx.eval("select.type polygon")
lx.eval("select.useSet temp_set select")
lx.eval("select.connect")
lx.eval("cut")
lx.eval("layer.new")
lx.eval("item.name layerQ1 mesh")#
lx.eval("paste")
lx.eval("poly.convert face subpatch flase")
lx.eval("select.drop polygon")#diagnostic
lx.eval("select.useSet temp_set select")
lx.eval('!!poly.merge')
lx.eval('select.convert edge')

lx.eval("query layerservice layer.id ? main")
selected_poly_count = lx.eval("query layerservice poly.N ? selected")
selected_edge_count = lx.eval("query layerservice edge.N ? selected")
total_length = sum(lx.eval('query layerservice edge.length ? %s' % edge)
                   for edge in lx.evalN('query layerservice edges ? selected'))
average_length = total_length/selected_edge_count
square = total_length/7 

#lx.eval("workPlane.reset")
lx.eval("select.type polygon")
lx.eval("tool.set poly.bevel on")
#add small bevel
lx.eval("tool.setAttr poly.bevel inset "+str(average_length * .05))
lx.eval("tool.setAttr poly.bevel shift 0")
lx.eval("tool.doApply")
#bevel #2
lx.eval("tool.setAttr poly.bevel inset "+str(average_length * 0.75))
lx.eval("tool.setAttr poly.bevel shift 0")
lx.eval("tool.doApply")

lx.eval("select.delete")

lx.eval("tool.set prim.cube on")
lx.eval("tool.reset")
lx.eval("tool.attr prim.cube sizeX "+str(square))
lx.eval("tool.attr prim.cube sizeZ "+str(square))
lx.eval("tool.attr prim.cube sizeY 0")
lx.eval("tool.attr prim.cube segmentsX "+str(selected_edge_count * .25))
lx.eval("tool.attr prim.cube segmentsZ "+str(selected_edge_count * .25))
lx.eval("tool.attr prim.cube segmentsY 0")
lx.eval("tool.attr prim.cube minX "+str(square * -.5))
lx.eval("tool.attr prim.cube minZ "+str(square * -.5))
lx.eval("tool.attr prim.cube minY 0")
lx.eval("tool.attr prim.cube maxX "+str(square * .5))
lx.eval("tool.attr prim.cube maxZ "+str(square * .5))
lx.eval("tool.attr prim.cube maxY 0")
lx.eval("tool.doApply")

lx.eval('script.run "macro.scriptservice:92663570022:macro"')
lx.eval("tool.set edge.bridge on")
lx.eval("tool.reset")
lx.eval("tool.doApply")
lx.eval("tool.set edge.bridge off")

lx.eval("tool.set xfrm.smooth on")
lx.eval("tool.attr xfrm.smooth strn 1.0")
lx.eval("tool.attr xfrm.smooth iter 10000")
lx.eval("tool.doApply")
lx.eval("tool.set xfrm.smooth off")
lx.eval("select.drop edge")

lx.eval("select.type polygon")
lx.eval("!!poly.align")
lx.eval('select.polygon add type face 0')
#march 2013 edit: disabled the subD
#lx.eval('poly.convert face subpatch true')
lx.eval("cut")
lx.eval('select.item %s set' %(currentMesh))
lx.eval("paste")

lx.eval("select.item {layerQ1} set mesh")
lx.eval("item.delete")
lx.eval('select.item %s set' %(currentMesh))
lx.eval("select.type polygon")
lx.eval("select.deleteSet temp_set")
lx.eval("workPlane.reset")
