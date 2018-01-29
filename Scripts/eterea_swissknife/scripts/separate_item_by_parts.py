#python
#Separate OBJ parts
#Author: Erik Karlsson
#ver: 1.00
#Sep 9, 2008

#Description
#This script splits your imported object into separate layers. It uses the polygon parts name to split the object.
#Select the item you want to split into layers and run the script!
#You will now have your model separated as supposed to.

import lx

layerID = lx.eval('query layerservice layer.ID ? selected')
numParts = lx.eval('query layerservice parts ? all')

for currPart in numParts:
	lx.eval('select.item %s' % (layerID))
	partName = lx.eval('query layerservice part.name ? %s' % currPart)
	lx.eval('select.polygon add part face %s' % partName)
	lx.eval('select.cut')
	lx.eval('item.create mesh')
	lx.eval('item.name %s mesh'%partName)
	lx.eval('select.paste')
	lx.eval('select.drop polygon')

lx.eval('select.item %s' % (layerID))
lx.eval('item.delete')
