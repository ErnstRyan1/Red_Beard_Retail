#python

###########################################
#
# Reset Pivot
#   v1.1
#
# Author Bjoern Siegert (aka nicelife)
#
# Last edited: 17.12.2013
#
#
#   You can reset a pivot of a selected item.
#   If no argument is given everything is reseted.
#   These other two arguments work as follows:
#     - "trans" resets only the translation of the pivot
#     - "rot"  resets only the rotation of the pivot
#
###########################################


### VARS ###
arg = lx.arg()
scene_name = lx.eval("query sceneservice scene.name ? main") # Select the scene
layer_name = lx.eval("query layerservice layer.name ? main") # Select the layer might be not necessary for this script
item_name = lx.eval("query sceneservice item.name ? %s" %layer_name) # Select mesh item in scene
channel_list = lx.evalN("query sceneservice item.xfrmItems ?")

piv_trans_channels = [] # List to store the pivot translation channels
piv_rot_channels = [] # List to store the pivot rotation channels

# Walk through the channel_list and the pivot items in it
for item in channel_list:
    lx.eval("query sceneservice item.name ? %s" %item) # Select the channel
    channel_num = lx.eval("query sceneservice channel.N ?")
    #name = lx.eval("query sceneservice item.name ? %s" %item) # Get the name of the selected channel
    item_type = lx.eval("query sceneservice channel.value ? 1") # Get the channel type
    
    # Save only the piv translation and rotation in the two lists.
    # Uses the channel value:
    #       "piv" for pivot translation
    #       "sys" for pivot rotation
    if item_type == "piv" and channel_num > 2:
        piv_trans_channels.append(item)

    elif item_type == "sys" and channel_num > 2:
        piv_rot_channels.append(item)
        
    else:
        pass
    
    lx.out(item_type)
    
# Testing Output in Log
lx.out("Item Channel names: ", channel_list)
lx.out("Pivot Translation Channels: ", piv_trans_channels)
lx.out("Pivot Rotation Channels: ", piv_rot_channels)


# Parsing arguments and do the stuff
if "trans" in arg:
    for item in piv_trans_channels:
        lx.eval("select.item %s set translation" %item)
        lx.eval("item.delete")

elif "rot" in arg:
    for item in piv_rot_channels:
        lx.eval("select.item %s set rotation" %item)
        lx.eval("item.delete")

# Reseting translation and rotation if no argument is given
else:
    for item in piv_trans_channels:
        lx.eval("select.item %s set translation" %item)
        lx.eval("item.delete")
        
    for item in piv_rot_channels:
        lx.eval("select.item %s set rotation" %item)
        lx.eval("item.delete")