#!/usr/bin/env python

# edge_angle_between2polys.py
# Created by James O'Hare aka Farfarer
# Just to give you the angle angle between the two polys connected to an edge

# Need these for converting the dot product to angle in radians, then converting that to degrees.
from math import acos, degrees

selected_edges = lx.evalN('query layerservice edges ? selected')

if len(selected_edges) > 0:
    edge_polys = lx.evalN('query layerservice edge.polyList ? %s' % selected_edges[0])

    if len(edge_polys) > 1:
        poly_1_normal = lx.evalN('query layerservice poly.normal ? %s' % edge_polys[0])
        poly_2_normal = lx.evalN('query layerservice poly.normal ? %s' % edge_polys[1])

        dot = poly_1_normal[0]*poly_2_normal[0] + poly_1_normal[1]*poly_2_normal[1] + poly_1_normal[2]*poly_2_normal[2] # Dot product.
        dot = max(-1.0, min(dot, 1.0))    # Clamp it -1.0 - 1.0 just in case floating point gets a bit flaky. Values outside of that range will cause issues.
        dot = acos(dot) # Convert from dot product to angle in radians.
        angle = degrees(dot) # Convert from radians to degrees.

        lx.out('Angle of edge is: %s' % angle)

        lx.eval('dialog.setup info')
        lx.eval('dialog.title {Angle between polys}')
        lx.eval('dialog.msg {Angle is %s}' % angle) 
        lx.eval('dialog.open')
