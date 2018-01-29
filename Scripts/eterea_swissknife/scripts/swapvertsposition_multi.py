#python
#swapvertsposition_multi.py
#concept by Jeegrobot
#based on swapvertsposition.py by ylaz 2013
#swaps positions of selected points one pair after the other 
#ver1.1 Dec2013. Modified by Jeegrobot for multiple verts selection.

# Warning if nothing selected
vertNum = lx.eval('query layerservice vert.N ? selected')
if vertNum == 0: 
    lx.eval("dialog.setup info")
    lx.eval("dialog.title \"Swap Verts\"")
    lx.eval("dialog.msg \"NOTHING SELECTED. SELECT A PAIR NUMBER OF VERTICES\"")
    lx.eval("dialog.open")
    sys.exit()

# Warning if an odd number of verts are selected
if vertNum%2 != 0:
    lx.out("numero dispari")
    lx.eval("dialog.setup info")
    lx.eval("dialog.title \"Swap Verts\"")
    lx.eval("dialog.msg \"SELECT A PAIR NUMBER OF VERTICES\"")
    lx.eval("dialog.open")
    sys.exit()

# Query for the list of selected verts.
verts = lx.eval('query layerservice verts ? selected')
# lx.out(verts)

# Maths for finding the current index in the selected verts list
for i in range(vertNum/2):
    A = i*2
    B = i*2 + 1
#    lx.out(A,B)

# Query position for the current pair of verts
    posA = lx.eval('query layerservice vert.pos ? %s' % verts[A])
    posB = lx.eval('query layerservice vert.pos ? %s' % verts[B])

# Swap position of the current pair of verts
    lx.eval('vertMap.setVertex position position 0 %s %s' % (verts[A], posB[0]))
    lx.eval('vertMap.setVertex position position 1 %s %s' % (verts[A], posB[1]))
    lx.eval('vertMap.setVertex position position 2 %s %s' % (verts[A], posB[2]))
    lx.eval('vertMap.setVertex position position 0 %s %s' % (verts[B], posA[0]))
    lx.eval('vertMap.setVertex position position 1 %s %s' % (verts[B], posA[1]))
    lx.eval('vertMap.setVertex position position 2 %s %s' % (verts[B], posA[2]))