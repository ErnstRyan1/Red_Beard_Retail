#python

# add_locators_selectedvertices.py, based on PointLightReplicator by Keith Sheppard
# Author Keith Sheppard aka OOZZEE, modified by Cristobal Vila to select all lights at end
# Jan2013
# http://forums.luxology.com/topic.aspx?f=119&t=74337

import lx

# make locators visible
lx.eval("viewport.3dView showLocators:true")

# convert selection to verts
lx.eval("select.convert vertex")

# query how many vertices selected
VertSelected = lx.evalN("query layerservice verts ? selected")

# we will create a bunch of Locators and need to add them to an array
locators = []

for MyEachVert in VertSelected:
    xVertPos = lx.eval("query layerservice vert.wpos ? {%s}" % MyEachVert)[0]
    yVertPos = lx.eval("query layerservice vert.wpos ? {%s}" % MyEachVert)[1]
    zVertPos = lx.eval("query layerservice vert.wpos ? {%s}" % MyEachVert)[2]
    lx.eval("item.create locator")
    lx.eval("item.channel locator$size 0.0")
    lx.eval("transform.channel pos.X {%s}" %xVertPos)
    lx.eval("transform.channel pos.Y {%s}" %yVertPos)
    lx.eval("transform.channel pos.Z {%s}" %zVertPos)

    # get id of newly created locator
    locatorName = lx.eval1("query sceneservice selection ? all")

    # add locator to array
    locators.append(locatorName)
    
# select locators
lx.eval("select.drop item")
for item in locators:
    lx.eval('select.item {%s} add' % item)