# python
#slice_betweenVerts.py by ylaz 2013
#select two verts > run script
mode = lx.eval('query layerservice selmode ?')
if mode != 'vertex':
	sys.exit( '::::::::::::::::::::< SCRIPT NEEDS TO RUN IN VERT MODE >:::::::::::::::::::' )
current_selV = lx.eval('query layerservice vert.N ? selected')
if mode == 'vertex' and current_selV == 0: 
	sys.exit( '::::::::::::::::::::< YOU NEED TO SELECT 2 VERTS >:::::::::::::::::::' )
main = lx.eval('query layerservice layers ? main')
verts = lx.eval('query layerservice verts ? selected')
vert_list =[]
for v in verts:
	pos = lx.eval('query layerservice vert.pos ? %s' %v)
	vert_list.append(pos)
vertlistB = vert_list[0] + vert_list[1]
lx.eval('select.drop vertex')
lx.eval('select.typeFrom polygon')
lx.eval('tool.set poly.knife on')
lx.eval('tool.reset')
lx.eval('tool.setAttr poly.knife startX %s' % vertlistB[0])
lx.eval('tool.setAttr poly.knife startY %s' % vertlistB[1])
lx.eval('tool.setAttr poly.knife startZ %s' % vertlistB[2])
lx.eval('tool.setAttr poly.knife endX %s' % vertlistB[3])
lx.eval('tool.setAttr poly.knife endY %s' % vertlistB[4])
lx.eval('tool.setAttr poly.knife endZ %s' % vertlistB[5])
lx.eval('tool.doApply')
lx.eval('tool.set poly.knife off')
lx.eval('select.drop polygon')
lx.eval('select.typeFrom vertex')
