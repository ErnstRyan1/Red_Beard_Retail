#python

# circle3p.py - Created by Take-Z [http://blog.livedoor.jp/take_z_ultima] and freely available here
# [http://park7.wakwak.com/~oxygen/lib/script/modo/category.html]

import math
import lx

def Rn(n,th):
	c=math.cos(th)
	s=math.sin(th)
	x=n[0]
	y=n[1]
	z=n[2]
	return [
		c+(1-c)*x**2,(1-c)*x*y+s*z,(1-c)*x*z-s*y,
		(1-c)*x*y-s*z,c+(1-c)*y**2,(1-c)*y*z+s*x,
		(1-c)*x*z+s*y,(1-c)*y*z-s*x,c+(1-c)*z**2 ]

def crossplanes(n1,n2):
	global redundancy
	a=n1[0]
	b=n1[1]
	c=n1[2]
	d=n2[0]
	e=n2[1]
	f=n2[2]
	if a==0.0:
		if d==0.0:
			vx=1.0
			vy=0.0
			vz=0.0
		elif b==0.0:
			if e==0.0:
				vx=0.0
				vy=1.0
				vz=0.0
			else:
				vy=-d/e
				vz=0.0
				vx=1.0
		else:
			vy=-c/b
			vz=1.0
			vx=(c*e/b-f)/d
	else:
		if abs(e-b*d/a)<redundancy:
			if b==0.0:
				vx=0.0
				vy=1.0
				vz=0.0
			else:
				vz=0.0
				vx=1.0
				vy=-a/b
		else:
			vy=(c*d/a-f)/(e-b*d/a)
			vz=1.0
			vx=-b/a*vy-c/a*vz
	return normalize([vx,vy,vz])

def normalize(n):
	lgth=(n[0]**2.0+n[1]**2.0+n[2]**2.0)**0.5
	return [n[0]/lgth,n[1]/lgth,n[2]/lgth]

def vector(v2,v1):
	return [v2[0]-v1[0],v2[1]-v1[1],v2[2]-v1[2]]

def outer(a,b):
	n=[a[1]*b[2]-a[2]*b[1],-(a[0]*b[2]-a[2]*b[0]),a[0]*b[1]-a[1]*b[0]]
	l=(n[0]**2+n[1]**2+n[2]**2)**0.5
	return [n[0]/l,n[1]/l,n[2]/l]

def mulm(a,b):
	if len(b)==3:
		return [
			a[0]*b[0]+a[1]*b[1]+a[2]*b[2],
			a[3]*b[0]+a[4]*b[1]+a[5]*b[2],
			a[6]*b[0]+a[7]*b[1]+a[8]*b[2]
		]
	else:
		return [
			a[0]*b[0]+a[1]*b[3]+a[2]*b[6],a[0]*b[1]+a[1]*b[4]+a[2]*b[7],a[0]*b[2]+a[1]*b[5]+a[2]*b[8],
			a[3]*b[0]+a[4]*b[3]+a[5]*b[6],a[3]*b[1]+a[4]*b[4]+a[5]*b[7],a[3]*b[2]+a[4]*b[5]+a[5]*b[8],
			a[6]*b[0]+a[7]*b[3]+a[8]*b[6],a[6]*b[1]+a[7]*b[4]+a[8]*b[7],a[6]*b[2]+a[7]*b[5]+a[8]*b[8]
		]

if lx.eval("query scriptsysservice userValue.isDefined ? circle3p.divide") == 0 :
	lx.eval("user.defNew circle3p.divide integer temporary")
	lx.eval("user.def circle3p.divide username \"side\"")
	lx.eval("user.value circle3p.divide 36")
lx.eval("user.value circle3p.divide")
divide=lx.eval("user.value circle3p.divide ?")
redundancy=0.00001
lx.eval("select.type vertex")
main=lx.eval("query layerservice layers ? main")
verts=[ int(v) for v in lx.evalN("query layerservice verts ? selected")]
spos=set()
for v in verts:
	spos.add(lx.eval("query layerservice vert.pos ? %s" % v))
pos=list(spos)
if len(pos)>=3:
	pos1=pos[0]
	pos2=pos[1]
	pos3=pos[2]
	normal=outer(vector(pos2,pos1),vector(pos3,pos1))
	v1=crossplanes(normal,[pos2[0]-pos1[0],pos2[1]-pos1[1],pos2[2]-pos1[2]])
	p1=[(pos1[0]+pos2[0])/2.0,(pos1[1]+pos2[1])/2.0,(pos1[2]+pos2[2])/2.0]
	v2=crossplanes(normal,[pos3[0]-pos1[0],pos3[1]-pos1[1],pos3[2]-pos1[2]])
	p2=[(pos1[0]+pos3[0])/2.0,(pos1[1]+pos3[1])/2.0,(pos1[2]+pos3[2])/2.0]
	if v1[0]!=0.0:
		if abs(v2[2]-v1[2]*v2[0]/v1[0])<redundancy:
			t=(v1[1]/v1[0]*(p2[0]-p1[0])-(p2[1]-p1[1]))/(v2[1]-v1[1]*v2[0]/v1[0])
		else:
			t=(v1[2]/v1[0]*(p2[0]-p1[0])-(p2[2]-p1[2]))/(v2[2]-v1[2]*v2[0]/v1[0])
	elif v1[1]!=0.0:
		if abs(v2[0]-v1[0]*v2[1]/v1[1])<redundancy:
			t=(v1[2]/v1[1]*(p2[1]-p1[1])-(p2[2]-p1[2]))/(v2[2]-v1[2]*v2[1]/v1[1])
		else:
			t=(v1[0]/v1[1]*(p2[1]-p1[1])-(p2[0]-p1[0]))/(v2[0]-v1[0]*v2[1]/v1[1])
	else:
		if abs(v2[0]-v1[0]*v2[2]/v1[2])<redundancy:
			t=(v1[1]/v1[2]*(p2[2]-p1[2])-(p2[1]-p1[1]))/(v2[1]-v1[1]*v2[2]/v1[2])
		else:
			t=(v1[0]/v1[2]*(p2[2]-p1[2])-(p2[0]-p1[0]))/(v2[0]-v1[0]*v2[2]/v1[2])
	center=[v2[0]*t+p2[0],v2[1]*t+p2[1],v2[2]*t+p2[2]]
	for t in range(divide):
		th=t*360.0/divide*math.pi/180
		R=Rn(normal,th)
		v=mulm(R,vector(pos1,center))
		lx.command("vert.new",x=v[0]+center[0],y=v[1]+center[1],z=v[2]+center[2])
	lx.eval("select.drop vertex")
	n=lx.eval("query layerservice vert.N ? all")
	for i in range(n-divide,n):
		lx.command("select.element",layer=main,type="vertex",mode="add",index=i)
	lx.eval("poly.makeFace")
	lx.eval("select.type polygon")
