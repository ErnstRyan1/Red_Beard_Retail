#python

# mkvertbydivide.py - Created by Take-Z [http://blog.livedoor.jp/take_z_ultima] and freely available here
# [http://park7.wakwak.com/~oxygen/lib/script/modo/category.html]

import lx

def panel(var,val,type,mes,lst):
	if lx.eval("query scriptsysservice userValue.isDefined ? %(var)s" % vars()) == 0 :
		lx.eval("user.defNew %(var)s %(type)s temporary" % vars())
	if val!=None :
		lx.eval("user.value %(var)s %(val)s" % vars())
	if mes != None :
		lx.eval("user.def %(var)s username \"%(mes)s\"" % vars())
	if lst!=None :
		lx.eval("user.def %(var)s list %(lst)s" % vars())
	if mes != None :
		lx.eval("user.value %(var)s" % vars())
	return lx.eval("user.value %(var)s ?" % vars())

main=lx.eval("query layerservice layers ? main")
verts=lx.evalN("query layerservice verts ? selected")
if len(verts)>=2 :
	pos1=lx.eval("query layerservice vert.pos ? " + verts[0])
	pos2=lx.eval("query layerservice vert.pos ? " + verts[1])
	n = panel("makepointbydivide.n",None,"integer","How many",None)
	if n>0 :
		dx=(pos2[0]-pos1[0])/(n+1)
		dy=(pos2[1]-pos1[1])/(n+1)
		dz=(pos2[2]-pos1[2])/(n+1)
		sx=pos1[0]+dx
		sy=pos1[1]+dy
		sz=pos1[2]+dz
		
		for i in range(n):
			lx.command("vert.new",x=sx,y=sy,z=sz)
			sx=sx+dx
			sy=sy+dy
			sz=sz+dz
		v = int(lx.eval("query layerservice vert.index ? last"))
		for i in range(n):
			lx.command("select.element",layer=main,type="vertex",mode="add",index=v-i)
