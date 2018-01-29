#python

#Select adjacent polygons that share only Edges
#Created by Philip Lawson and shared on the Luxology Beta Forums

#---------------------------------------------------------------------#
#First we make a selection set of the originally selected polygons
lx.eval("select.editSet plTemp add")
#Changes Selection into vertices
lx.eval("select.convert vertex")
#Expands vertex selection
lx.eval("select.vertexExpand")
#Convertes back to polygons
lx.eval("select.convert polygon")
#Finally we de-select the original polygons via the selection set.
lx.eval("select.useSet plTemp deselect")
#and then delete the selection set.
lx.eval("select.deleteSet plTemp")