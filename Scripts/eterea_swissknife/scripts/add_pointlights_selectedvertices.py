#python

# add_pointlights_selectedvertices, based on PointLightReplicator by Keith Sheppard
# Author Keith Sheppard aka OOZZEE, modified by Cristobal Vila to select all lights at end
# Jan2013
# http://forums.luxology.com/topic.aspx?f=119&t=74337

import lx

# make lights visible
lx.eval("viewport.3dView showLights:true")

# convert selection to verts
lx.eval("select.convert vertex")

# query how many vertices selected
VertSelected = lx.evalN("query layerservice verts ? selected")

# we will create a bunch of Lights and need to add them to an array
lights = []

for MyEachVert in VertSelected:
    xVertPos = lx.eval("query layerservice vert.wpos ? {%s}" % MyEachVert)[0]
    yVertPos = lx.eval("query layerservice vert.wpos ? {%s}" % MyEachVert)[1]
    zVertPos = lx.eval("query layerservice vert.wpos ? {%s}" % MyEachVert)[2]
    lx.eval("item.create pointLight")
    lx.eval("item.channel locator$size 0.0")
    lx.eval("transform.channel pos.X {%s}" %xVertPos)
    lx.eval("transform.channel pos.Y {%s}" %yVertPos)
    lx.eval("transform.channel pos.Z {%s}" %zVertPos)

    # get id of newly created light
    lightName = lx.eval1("query sceneservice selection ? all")

    # add light to array
    lights.append(lightName)
    
# select lights
lx.eval("select.drop item")
for item in lights:
    lx.eval('select.item {%s} add' % item)