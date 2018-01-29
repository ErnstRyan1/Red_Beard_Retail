#python

#Select adjacent polygons that share both Edges and Vertices
#Created by Philip Lawson and shared on the Luxology Beta Forums

#---------------------------------------------------------------------#
#First we make a selection set of the originally selected polygons
lx.eval("select.editSet plTemp add")
#Then we select the adjcent polygons from selection.
lx.eval("select.expand")
#Finally we de-select the original polygons via the selection set.
lx.eval("select.useSet plTemp deselect")
#and then delete the selection set.
lx.eval("select.deleteSet plTemp")