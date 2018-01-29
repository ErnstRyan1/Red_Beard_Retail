#python

# lineselect.py - Created by Take-Z [http://blog.livedoor.jp/take_z_ultima] and freely available here
# [http://park7.wakwak.com/~oxygen/lib/script/modo/category.html]


import lx

def whichmode():
	if lx.eval("select.typeFrom vertex;edge;polygon;item;ptag ?") :
		return "vertex"
	elif lx.eval("select.typeFrom edge;vertex;polygon;item;ptag ?") :
		return "edge"
	elif lx.eval("select.typeFrom polygon;vertex;edge;item;ptag ?") :
		return "polygon"
	elif lx.eval("select.typeFrom item;vertex;edge;polygon;ptag ?") :
		return "item"
	else:
		return "ptag"

def nextedge(v,plist,loopedge): 
	find=False
	for e in list(loopedge):     
		vid=e.strip("()").split(",")
		if str(v) in vid: 
			find=True
			break     
	if not find : return None
	loopedge.remove(e)  
	p=set(lx.evalN("query layerservice edge.polyList ? %s" % e))
	if len(p.intersection(plist))!=0: 
		return None
	else:
		return e         

mode=whichmode()
if mode=="edge":
	result=[]
	main=lx.eval("query layerservice layers ? main")
	edges=[(v.strip("()").split(",")) for v in lx.evalN("query layerservice selection ? edge")]
	seledge=[]
	for e in edges:
		if int(e[1])<int(e[2]):
			seledge.append("(%s,%s)" % (e[1],e[2]))
		else:
			seledge.append("(%s,%s)" % (e[2],e[1]))
	if len(seledge)!=0:
		seededge=seledge[-1]
		plist=set(lx.evalN("query layerservice edge.polyList ? %s" % seededge))
		lx.eval("select.drop edge")                                                                       
		vid=seededge.strip("()").split(",")
		lx.command("select.element",layer=main,type="edge",mode="set",index=int(vid[0]),index2=int(vid[1]))
		lx.eval("select.loop")
		edges=[(v.strip("()").split(",")) for v in lx.evalN("query layerservice selection ? edge")]
		loopedge=set()
		for e in edges:
			if int(e[1])<int(e[2]):
				loopedge.add("(%s,%s)" % (e[1],e[2]))
			else:
				loopedge.add("(%s,%s)" % (e[2],e[1]))
		result.append(seededge)
		seed=seededge.strip("()").split(",")
		loopedge.remove(seededge)
		v=seed[0]
		while True:
			edge=nextedge(v,plist,loopedge)
			if edge==None: break
			plist=set(lx.evalN("query layerservice edge.polyList ? %s" % edge))
			result.append(edge)
			vp=edge.strip("()").split(",")
			if vp[0]==v : 
				v=vp[1]
			else:
				v=vp[0]
		v=seed[1]
		while True:
			edge=nextedge(v,plist,loopedge)
			if edge==None: break
			plist=set(lx.evalN("query layerservice edge.polyList ? %s" % edge))
			result.append(edge)  
			vp=edge.strip("()").split(",")
			if vp[0]==v : 
				v=vp[1]
			else:
				v=vp[0]    
		lx.eval("select.drop edge")                                                                       
		result=result+seledge
		for e in result:                                        
			vid=e.strip("()").split(",")
			lx.command("select.element",layer=main,type="edge",mode="add",index=int(vid[0]),index2=int(vid[1]))
