#python

# =============================================================================
# Script: funk_Part2Mat.py v1.03 (2013-07-26)
# Author: funk
# 
# Converts parts to materials
# =============================================================================

import lx

layer_id = lx.eval('query layerservice layer.index ? current')
num_parts = lx.eval('query layerservice part.N ?')

for x in range(num_parts):
    part_name = lx.eval('query layerservice part.name ? {%s}' % x)
    lx.eval('select.drop polygon')
    lx.eval('select.polygon add part face {%s}' % part_name)
    lx.eval('poly.setMaterial {%s}' % part_name)

lx.eval('select.drop polygon')