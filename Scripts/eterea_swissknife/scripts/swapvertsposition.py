#python

# swapvertsposition.py by ylaz 2013
# swaps one vert's postion w the other's

# To remember what is your initial selection type (edge or vertex)
mode = lx.eval('query layerservice selmode ?')

# Just in case you have an edge selected, and not a couple of vertex
if mode == 'edge': 
    lx.eval('select.convert vertex')

# Query how many vertices are selected
vertNum = lx.eval('query layerservice vert.N ? selected')

# Stop execution if you have more or less than 2 vertices selected
if vertNum != 2: 
    sys.exit( ':< SELECT ONLY 2 VERTS >:' )

# Query selected vertices
verts = lx.eval('query layerservice verts ? selected')

# Store positions for each vertice
pos1 = lx.eval('query layerservice vert.pos ? %s' % verts[0])
pos2 = lx.eval('query layerservice vert.pos ? %s' % verts[1])

# Swap potitions
lx.eval('vertMap.setVertex position position 0 %s %s' % (verts[0], pos2[0]))
lx.eval('vertMap.setVertex position position 1 %s %s' % (verts[0], pos2[1]))
lx.eval('vertMap.setVertex position position 2 %s %s' % (verts[0], pos2[2]))
lx.eval('vertMap.setVertex position position 0 %s %s' % (verts[1], pos1[0]))
lx.eval('vertMap.setVertex position position 1 %s %s' % (verts[1], pos1[1]))
lx.eval('vertMap.setVertex position position 2 %s %s' % (verts[1], pos1[2]))

# Revert to initial selection type
lx.eval('select.typeFrom %s' % mode)