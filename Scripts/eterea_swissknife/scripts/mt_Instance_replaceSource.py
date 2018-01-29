#python
#Autor: Muhamed Toromanovic


# XXXXXXXXXXXXX  IMPORTS   XXXXXXXXXXXXX
from math import pi
import time


# XXXXXXXXXXXXX  MAIN VARIABLES   XXXXXXXXXXXXX

items = []
sources = []
instances = []
new_instances = []


# XXXXXXXXXXXXX  SELECT SCENE AND ACTIVE ITEMS   XXXXXXXXXXXXX
active_scene = lx.eval("query sceneservice scene.name ? current")
active_items = lx.evalN("query sceneservice selection ? all")
all_items = lx.eval("query sceneservice item.N ?")
for id in range(all_items):
  if lx.eval("query sceneservice item.type ? %s" % id) == "meshInst":
    selected_instance = lx.eval("query sceneservice item.id ? " + str(id))
    counter = 0
    source = selected_instance      
    while lx.eval("query sceneservice isType ? mesh") != 1:
      source = lx.eval("query sceneservice item.source ? " + source)
      selected_item = lx.eval("query sceneservice item.id ? " + source)
      counter = counter + 1  
    if source == active_items[0]: 
      instances.append(selected_instance)



# XXXXXXXXXXXXX  CREATE NEW INSTANCES AND MATCH POSITION, ROTATION AND SCALE   XXXXXXXXXXXXX
for element in instances:

  lx.eval("select.drop item")

  lx.eval("select.subItem " + active_items[1] + " add mesh")
  lx.eval("item.duplicate true locator false true")
  new_instance = lx.evalN("query sceneservice selection ? all")
  new_instances.append(new_instance[0])
  
  lx.eval("select.subItem " + element + " add mesh")
  lx.eval("matchRot")
  lx.eval("select.subItem " + element + " add mesh")
  lx.eval("item.match item scl")
  lx.eval("select.subItem " + element + " add mesh")
  lx.eval("matchPos")
  

# XXXXXXXXXXXXX  CREATE GROUP LOCATORS AND MOVE EVERYTHING ACCORDINGLY   XXXXXXXXXXXXX
timestamp = str(int(time.time()))

grouplocator_old = "Inst_Source_old_" + timestamp
grouplocator_new = "Inst_Source_new_" + timestamp

lx.eval("item.create groupLocator")
lx.eval("item.name " + grouplocator_old)
group_old = lx.evalN("query sceneservice selection ? all")


lx.eval("item.create groupLocator")
lx.eval("item.name " + grouplocator_new)
group_new = lx.evalN("query sceneservice selection ? all")


for element in instances:
  lx.eval("item.parent %s %s 0 inPlace:1" % (element, group_old[0]))
lx.eval("item.parent %s %s 0 inPlace:1" % (active_items[0], group_old[0]))

for element in new_instances:
  lx.eval("item.parent %s %s 0 inPlace:1" % (element, group_new[0]))
lx.eval("item.parent %s %s 0 inPlace:1" % (active_items[1], group_new[0]))


lx.out("Replace Instance Source finished.") 