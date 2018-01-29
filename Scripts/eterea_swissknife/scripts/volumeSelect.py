#python
#
# VolumeSelect
#
# Author: Mark Rossi
# Version: .2
# Compatibility: Modo 401
#
# Purpose: To select all the vertices in one mesh layer that are enclosed by all the polygons in another mesh layer.
#
# Use: Select the mesh layer whose vertices you want the script to select, then select the item containing the enclosing mesh, then run the script.
#      The script takes no arguments. Results will be most accurate if the enclosing mesh is totally closed and does not self-intersect. Generally the
#      script is a bit slow, but it is useful in various situations, especially when you need to make tedious, multi-axis selections.

import operator as op

def v_add(v1, v2):
	return list(map(op.add, v1, v2))

def v_sub(v1, v2):
	if not v1 or not v2: return [-2] * 3
	return list(map(op.sub, v1, v2))

def v_mul(v1, v2):
	return list(map(op.mul, v1, v2))

def vec(p1, p2):
	return [p2[0] - p1[0], p2[1] - p1[1], p2[2] - p1[2]]

def mag2(v):
	return v[0]**2 + v[1]**2 + v[2]**2

def cp(v1, v2):
	return [v1[1] * v2[2] - v1[2] * v2[1], v1[2] * v2[0] - v1[0] * v2[2], v1[0] * v2[1] - v1[1] * v2[0]]

def dp(v1, v2):
	return v1[0] * v2[0] + v1[1] * v2[1] + v1[2] * v2[2]

def intersect(p1, p2, nr, qv):
	cr = cp(vec(p1, p2), vec(p1, qv))
	return dp(cr, nr) >= -.0000005

def sign(v):
	if v[0] < 0:
		if v[1] < 0:
			if v[2] < 0: return "000"
			else:        return "001"
		else:
			if v[2] < 0: return "010"
			else:        return "011"
	else:
		if v[1] < 0:
			if v[2] < 0: return "100"
			else:        return "101"
		else:
			if v[2] < 0: return "110"
			else:        return "111"

meshes = lx.evalN("query sceneservice selection ? mesh")
if len(meshes) != 2: sys.exit()
sObj, bObj = meshes[0], meshes[1]
ls = lx.Service("layerservice")
m  = lx.Monitor()

sLayer = not ls.select("layer.index", sObj) and ls.query("layer.index")
selV   = [[v, not ls.select("vert.wpos", v) and ls.query("vert.wpos")] for v in
              not ls.select("verts", "visible") and ls.queryN("verts")]
insV   = []

lx.eval("select.item %s set" %bObj)
lx.eval("item.duplicate")
lx.eval("poly.triple")
lx.eval("transform.freeze")
bObj   = lx.eval("query sceneservice selection ? mesh")
bLayer = not ls.select("layer.index", bObj) and ls.query("layer.index")
bndV   = [[v, not ls.select("vert.wpos", v) and ls.query("vert.wpos"), []] for v in
              not ls.select("verts", "visible") and ls.queryN("verts")]
pols   = not ls.select("polys", "visible") and ls.queryN("polys")
bndP   = dict()

if pols: m.init(len(pols))
for p in pols:
	m.step()
	ls.select("poly.wpos", p)
	bndP[int(p)] = dict((("pos", ls.query("poly.wpos")),
						 ("nrm", ls.query("poly.wnormal")),
	                     ("vid", ls.query("poly.vertList"))))
						 
posl = zip(*[v[1] for v in bndV])
bbox = [[min(d) for d in posl], [max(d) for d in posl]]
selV = [v for v in selV if not list(map(op.lt, v[1], bbox[0])).count(True)
                       and not list(map(op.gt, v[1], bbox[1])).count(True)]
prim = len(bndP) > len(selV) * 10
diml = [bbox[1][i] - bbox[0][i] for i in [0, 1, 2]]
axis = diml.index(max(diml))
rayd = [a == axis and 1 or 0 for a in [0, 1, 2]]
perp = [a for a in [0, 1, 2] if a != axis]
if selV: m.init(len(selV))

for sv in selV:
	m.step()
	vpos = sv[1]
	prox = [mag2(vec(vpos, bv[1])) for bv in bndV]
	mndx = prox.index(min(prox))
	if not bndV[mndx][2]:
		bndV[mndx][2] = not ls.select("vert.polyList", bndV[mndx][0]) and ls.queryN("vert.polyList")
	tpol = [bndP[i] for i in bndV[mndx][2]]
	side = [p for p in tpol if dp(vec(p["pos"], vpos), p["nrm"]) < 0]
	if not side: continue
	if len(side) == len(tpol): insV.append(sv[0])
	else:
		hits = 0
		chck = []
		plst = [bndP[i] for i in bndP]
		if prim:
			plst = [p for p in plst if max(zip(*[bndV[p["vid"][i]][1] for i in [0, 1, 2]])[axis]) > vpos[axis]]
		else:
			prp1 = [[bndV[p["vid"][i]][1][perp[0]] for i in [0, 1, 2]] for p in plst]
			prp2 = [[bndV[p["vid"][i]][1][perp[1]] for i in [0, 1, 2]] for p in plst]
			plst = [plst[i] for i in xrange(len(plst)) if min(prp1[i]) <= vpos[perp[0]] and
														  min(prp2[i]) <= vpos[perp[1]] and
														  max(prp1[i]) >= vpos[perp[0]] and
														  max(prp2[i]) >= vpos[perp[1]]]
		for poly in plst:
			ppos = poly["pos"]
			norm = poly["nrm"]
			d3 = dp(norm, rayd)
			if d3:
				d1 = dp(norm, ppos)
				d2 = dp(norm, vpos)
				tr = (d1 - d2) / d3
				ip = v_add(vpos, v_mul(rayd, [tr] * 3))
				if dp(vec(vpos, v_add(vpos, rayd)), vec(vpos, ip)) > 0:
					sigp = sign(ip)
					for c in chck:
						if sigp == c[0] and -.00005 < sum(v_sub(map(abs, ip), c[1])) < .00005: break
					else:
						vA = bndV[poly["vid"][0]][1]
						vB = bndV[poly["vid"][1]][1]
						vC = bndV[poly["vid"][2]][1]
						if intersect(vA, vB, norm, ip) and intersect(vB, vC, norm, ip) and intersect(vC, vA, norm, ip):
							chck.append([sign(ip), map(abs, ip)])
							hits += 1
		if hits % 2:
			insV.append(sv[0])

lx.eval("select.item %s set" %bObj)
lx.eval("item.delete xfrmcore;chanModify")
lx.eval("select.item %s set" %sObj)
lx.eval("select.drop vertex")
ls.select("layer.index", sObj); ls.query("layer.index")
allV = not ls.select("verts", "visible") and ls.queryN("verts")
zero = "0" in insV

if   len(insV) == len(allV): lx.eval("select.vertex add 0 0")
elif len(insV) >  len(allV) / 2 > 1:
	insV = set(allV).difference(insV)
	m.init(len(insV))
	lx.eval("select.elmBatchBegin %s vertex" %sLayer)
	for v in insV:
		m.step()
		lx.eval("select.elmBatchAdd %s" %v)
	lx.eval("select.elmBatchComplete")
	if not zero: lx.eval("select.element %s vertex add 0" %sLayer)
	lx.eval("select.vertexInvert")
elif insV:
	m.init(len(insV))
	lx.eval("select.elmBatchBegin %s vertex" %sLayer)
	for v in insV:
		m.step()
		lx.eval("select.elmBatchAdd %s" %v)
	lx.eval("select.elmBatchComplete")
	if zero: lx.eval("select.element %s vertex add 0" %sLayer)