#python

lx.eval('texture.copy')

#create user value to be used for name of material tag
try:
	#Create a user value.
	lx.eval('user.defNew name:{userval} type:string life:momentary')
	#Set the title name for the dialog
	lx.eval('user.def {userval} dialogname {PP Duplicate Material}')
	#Set the name for the input field that the users will see
	lx.eval('user.def {userval} username {Material Name}')
	#The '?' before the user.value calls a popup to have the user set the value3
	lx.eval('?user.value {userval}')
	#Now that the user set the value, we can query it
	user_input = lx.eval('user.value {userval} ?')
	lx.out('Name:: ', user_input)
except:
	sys.exit()

#create new material
lx.eval('poly.setMaterial {%s} {0.6 0.6 0.6} 0.8 0.04 true false false' % user_input)


#get mask and material id
lx.eval('query sceneservice scene.index ? current')
selmasks = lx.evalN('query sceneservice selection ? mask')
for mask in selmasks:
    mask_children = lx.evalN('query sceneservice mask.children ? {%s}' %mask)
    lx.out(mask, mask_children)

#deselect all items	
lx.eval('select.drop item')


#delete new material layer
lx.eval('select.subItem {%s} set'%mask_children)
lx.eval('delete')

#add the selected materials to the new material group
lx.eval('select.subItem {%s} set'%mask)
lx.eval('texture.paste')