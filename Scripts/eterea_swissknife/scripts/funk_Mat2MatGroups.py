#python

# =============================================================================
# Script: funk_Mat2MatGroups.py v1.03 (2013-07-26)
# Author: funk
# 
# Converts materials to correct material groups. Used to fix some OBJ imports
# where materials are shown in the mesh statistics, but no materials groups
# are imported into the shader tree
# =============================================================================

import lx

layer_id = lx.eval('query layerservice layer.index ? current')
num_mats = lx.eval('query layerservice material.N ?')

for x in range(num_mats):
    mat_name = lx.eval('query layerservice material.name ? {%s}' % x)
    lx.eval('select.drop polygon')
    lx.eval('select.polygon add material face {%s}' % mat_name)
    lx.eval('poly.setMaterial {%s}' % mat_name)

lx.eval('select.drop polygon')