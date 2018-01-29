#python

import lx

selection = lx.evalN('query sceneservice selection ? mesh')
for mesh in selection:
    meshName = lx.eval('query sceneservice item.name ? {%s}'%mesh)
    lx.eval('select.item {%s} set'%mesh)
    numMat = lx.eval1('query layerservice material.N ?')
    for i in range(0,numMat):
        matID = lx.eval('query layerservice material.id ? {%s}'%i)
        matParent = lx.eval('query sceneservice item.parent ? {%s}'% matID)
        if i == 0:
            lx.eval('select.item {%s} set'%matParent)
        else:
            lx.eval('select.item {%s} add'%matParent)
    lx.eval('shader.group')
    lx.eval('item.name {%s (Materials)} mask'%meshName)
    lx.eval('select.drop item')