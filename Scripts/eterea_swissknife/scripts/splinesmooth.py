#python

# splinesmooth.py - Created by Take-Z [http://blog.livedoor.jp/take_z_ultima] and freely available here
# [http://park7.wakwak.com/~oxygen/lib/script/modo/category.html]

import lx

class Spline:
	num=0
	def __init__(self,sp):
		self.a=[]
		for v in sp:
			self.a.append(v)
		self.c=[0.0]
		for i in range(1,len(sp)-1):
			self.c.append(3.0*(self.a[i-1] - 2.0 * self.a[i] + self.a[i+1]))
		self.c.append(0.0)
		w=[0.0]
		for i in range(1,len(sp)-1):
			tmp=4.0-w[i-1]
			self.c[i]=(self.c[i]-self.c[i-1])/tmp
			w.append(1.0/tmp)
		for i in range(len(sp)-2,0,-1):
			self.c[i]=self.c[i]-self.c[i+1]*w[i]
		self.b=[]
		self.d=[]
		for i in range(len(sp)-1):
			self.d.append((self.c[i+1]-self.c[i])/3.0)
			self.b.append(self.a[i+1]-self.a[i]-self.c[i]-self.d[i])
		self.b.append(0.0)
		self.d.append(0.0)
		self.num=len(sp)-1
	def culc(self,t):
		j=int(t)
		if j<0:
			j=0
		elif j >= self.num:
			j=self.num-1
		dt=t-j
		return self.a[j]+(self.b[j]+(self.c[j]+self.d[j]*dt)*dt)*dt

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

def panel(var,val,type,mes,lst):
	if lx.eval("query scriptsysservice userValue.isDefined ? %(var)s" % vars()) == 0 :
		lx.eval("user.defNew %(var)s %(type)s temporary" % vars())
	if val!=None :
		lx.eval("user.value %(var)s %(val)s" % vars())
	if mes != None :
		lx.eval("user.def %(var)s username \"%(mes)s\"" % vars())
	if lst!=None :
		lx.eval("user.def %(var)s list \"%(lst)s\"" % vars())
	if mes != None :
		lx.eval("user.value %(var)s" % vars())
	return lx.eval("user.value %(var)s ?" % vars())

def subvec(a,b):
	c=[]
	for i in range(len(a)):
		c.append(a[i]-b[i])
	return c

def invec(a,b):
	sum=0.0
	for i in range(len(a)):
		sum=sum+a[i]*b[i]
	return sum

def distancePtoL(p,v,q):#
	a=subvec(q,p)
	b=invec(v,v)
	c=invec(a,v)
	t=c/b
	if t<0.0:
		t=0.0
	elif t>1.0:
		t=1.0
	return [t,(invec(a,a)-c*t)**0.5]

def edge2vertsequence(edges):
	seqs=[]
	seqv=edges.pop()
	find=True
	while find and len(edges):
		find=False
		v1=seqv[0]
		v2=seqv[-1]
		for i,e in enumerate(edges):
			if v1 in e:
				find=True
				fe=edges.pop(i)
				if fe[0]==v1:
					seqv.insert(0,fe[1])
				else:
					seqv.insert(0,fe[0])
				break
		for i,e in enumerate(edges):
			if v2 in e:
				find=True
				fe=edges.pop(i)
				if fe[0]==v2:
					seqv.append(fe[1])
				else:
					seqv.append(fe[0])
				break
		if not find or len(edges)==0:
			seqs.append(seqv)
			if len(edges)!=0:
				find=True
				seqv=edges.pop()
	return seqs

mode=whichmode()
args=lx.args()
if len(args)==0:
	amode=panel("splinesmooth.alignmode",None,"integer","Align Mode","fit near spline;even divide")
else:
	if args[0]=="0":
		amode="fit near spline"
	else:
		amode="even divide"
main=lx.eval("query layerservice layers ? main")
lx.eval("select.type vertex")
selverts=[ int(v) for v in lx.evalN("query layerservice verts ? selected")]
lx.eval("select.type edge")
seledges=[[int(v) for v in e.strip("()").split(",")] for e in lx.evalN("query layerservice edges ? selected")]
lx.eval("select.type vertex")
seqs=edge2vertsequence(seledges)
for seqv in seqs:
	priod=[]
	ctrvs=[seqv[0]]
	div=0.0
	divmax=0.0
	for i in range(1,len(seqv)-1):
		if seqv[i] in selverts:
			ctrvs.append(seqv[i])
			if divmax<div:
				divmax=div
			div=0
			priod.append(i)
			continue
		div=div+1
	priod.append(len(seqv)-1)
	if divmax<div:
		divmax=div
	ctrvs.append(seqv[-1])
	pos=[]
	for v in ctrvs:
		pos.append(lx.eval("query layerservice vert.pos ? %s" % v))
	vx=[]
	vy=[]
	vz=[]
	for vpos in pos:
		vx.append(vpos[0])
		vy.append(vpos[1])
		vz.append(vpos[2])
	xs=Spline(vx)
	ys=Spline(vy)
	zs=Spline(vz)
	if amode=="fit near spline":
		t=0.0
		step=1/(divmax+1.0)/4.0
		
		edv=1
		for bt in range(len(priod)):
			spline=[]
			for i in range(int(1/step)+1):
				spline.append([xs.culc(t),ys.culc(t),zs.culc(t)])
				t=t+step
			t=t-step
			while edv<priod[bt]:
				if not seqv[edv] in selverts:
					pos=lx.eval("query layerservice vert.pos ? %s" % seqv[edv])
					near=None
					for i in range(len(spline)-1):
						d=distancePtoL(spline[i],subvec(spline[i+1],spline[i]),pos)
						if near==None:
							near=[i,d]
						else:
							if near[1][1]>d[1]:
								near=[i,d]
					tt=near[1][0]
					ptr=near[0]
					px=spline[ptr][0]+(spline[ptr+1][0]-spline[ptr][0])*tt
					py=spline[ptr][1]+(spline[ptr+1][1]-spline[ptr][1])*tt
					pz=spline[ptr][2]+(spline[ptr+1][2]-spline[ptr][2])*tt
					lx.command("select.element",layer=main,type="vertex",mode="set",index=seqv[edv])
					lx.eval("vert.set x %s" % px) 
					lx.eval("vert.set y %s" % py) 
					lx.eval("vert.set z %s" % pz) 
				edv=edv+1
			edv=edv+1
	elif amode=="even divide":
		edv=1
		for bt in range(len(priod)):
			step=1.0/(priod[bt]-edv+1)
			t=bt+step
			spline=[]
			while edv<priod[bt]:
				lx.command("select.element",layer=main,type="vertex",mode="set",index=seqv[edv])
				lx.eval("vert.set x %s" % (xs.culc(t))) 
				lx.eval("vert.set y %s" % (ys.culc(t))) 
				lx.eval("vert.set z %s" % (zs.culc(t))) 
				t=t+step
				edv=edv+1
			edv=edv+1
lx.eval("select.drop vertex")
for v in selverts:
	lx.command("select.element",layer=main,type="vertex",mode="add",index=v)
lx.eval("select.type "+mode)
