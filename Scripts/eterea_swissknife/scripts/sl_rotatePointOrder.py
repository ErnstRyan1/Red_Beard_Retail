#python

# sl_rotatePointOrder.py by Simon Lundberg aka Captain Obvious
# Shared here: http://forums.luxology.com/topic.aspx?f=33&t=79202

layers = {}
lx.eval('select.typeFrom polygon')

for layer in lx.evalN('query layerservice layer.index ? fg'):
    layerIndex = lx.eval('query layerservice layer.index ? main')
    polys = lx.evalN('query layerservice polys ? selected')
    polyVerts = {}
    for poly in polys:
        vertList = [int(n) for n in lx.evalN('query layerservice poly.vertList ? %s' % poly)]
        polyVerts[int(poly)] = vertList
    layers[layer] = polyVerts

lx.eval('remove')

for layer in layers:
    polyVerts = layers[layer]
    for poly in polyVerts:
        vertList = polyVerts[poly]
        lx.eval('select.typeFrom vertex')
        lx.eval('select.drop vertex')
        for vert in vertList:
            lx.eval('select.element %s vertex add %s' % (layer, vert))
        lx.eval('poly.make auto')

lx.eval('select.typeFrom polygon')