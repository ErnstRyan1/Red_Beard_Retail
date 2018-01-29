#python

# group_or_add_grouplocator.py
#
# If nothing is selected, add Group Locator
# If Items are selected, group them under a Group Locator
#
# Created an kindly shared by MonkeybrotherJr in the Luxology Forums
# http://forums.luxology.com/topic.aspx?f=119&t=72024

import lx

selmesh = lx.eval1("query sceneservice selection ? all")

lx.out(selmesh)

if selmesh:
    lx.eval("layer.groupSelected")
else:
    lx.eval("item.create groupLocator")