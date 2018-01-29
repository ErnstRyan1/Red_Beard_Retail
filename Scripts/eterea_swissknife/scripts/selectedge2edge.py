#python

# selectedge2edge.py - Created by Take-Z [http://blog.livedoor.jp/take_z_ultima] and freely available here
# [http://park7.wakwak.com/~oxygen/lib/script/modo/category.html]

import lx

def otherv(edge,vert):
	vid=edge.strip("()").split(",")
	if vid[0]==str(vert):
		return vid[1]
	else:
		return vid[0]

def searchconnect(seedv,crosspoints,loopedge):
	seede=[]
	for e in loopedge:
		vid=e.strip("()").split(",")
		if seedv in vid:
			seede.append(e)
	for e in seede:
		loopedge.remove(e)

	which=[]
	for se in seede:
		seqv=[seedv]
		sv=otherv(se,seedv)
		seqv.append(sv)
		term=False
		i=0
		while (not sv in crosspoints) and (term!=True):
			i=i+1
			if i>50: break
			term=True
			for e in loopedge:
				vid=e.strip("()").split(",")
				if sv in vid:
					term=False
					sv=otherv(e,sv)
					seqv.append(sv)
					loopedge.remove(e)
					break
		if not term :
			which.append(seqv)
	if len(which)==2:
		if len(which[0])<len(which[1]):
			return which[0]
		else:
			return which[1]
	else:
		return which[0]

mon=lx.Monitor()
main=lx.eval("query layerservice layers ? main")
lx.eval("select.convert vertex")
everts=list(lx.evalN("query layerservice verts ? selected"))
selverts=set(everts*1)
lx.eval("select.drop edge")
lx.eval("select.drop vertex")
vs=lx.evalN("query layerservice vert.vertList ? %s" % everts[0])
for v in vs:
	if str(v) in selverts:
		lx.eval("select.type edge")
		lx.command("select.element",layer=main,type="edge",mode="set",index=int(everts[0]),index2=int(v))
		lx.eval("@lineselect.py")
		lx.eval("select.convert vertex")
		lx.eval("select.type vertex")
		loop0=set(lx.evalN("query layerservice verts ? selected"))
		edge1=selverts.intersection(loop0)
		edge2=selverts.difference(edge1)
		break
mon.init(len(edge1))
vseq=[]
while len(edge1)!=0:
	mon.step(1)
	seedv=edge1.pop()
	nextv=lx.evalN("query layerservice vert.vertList ? %s" % seedv)
	find=False
	for v in nextv:
		if not str(v) in selverts:
			lx.eval("select.type vertex")
			lx.command("select.element",layer=main,type="vert",mode="set",index=int(seedv))
			lx.command("select.element",layer=main,type="vert",mode="add",index=int(v))
			lx.eval("select.loop")
			loopverts=set(lx.evalN("query layerservice verts ? selected"))
			lx.eval("select.convert edge")
			lx.eval("select.type edge")
			loopedge=list(lx.evalN("query layerservice edges ? selected"))
			lx.eval("select.type vertex")
			crosspoints=loopverts.intersection(edge2)
			n=len(crosspoints)
			if n!=0:
				vseq.append(searchconnect(seedv,crosspoints,loopedge))
lx.eval("select.type edge")
lx.eval("select.drop edge")
for s in vseq:
	for i in range(len(s)-1):
		lx.command("select.element",layer=main,type="edge",mode="add",index=int(s[i]),index2=int(s[i+1]))

