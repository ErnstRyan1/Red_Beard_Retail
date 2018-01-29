#!/usr/bin/env python

# Assign a Part to every Item with the same name than item

num_meshlayers = lx.eval('query sceneservice mesh.N ?')
for x in xrange(num_meshlayers):
    meshname = lx.eval('query sceneservice mesh.name ? %s' % x)
    partname = '%s' % meshname
    lx.eval('select.drop item')
    lx.eval('select.item {%s} set mesh' % meshname)
    lx.eval('poly.setPart {%s}' % partname)