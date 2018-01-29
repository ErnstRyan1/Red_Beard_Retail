#python
#bricks.py by <ylaz 2012>
#usage: select one edge along length, select poly along X axis, run script.
#reminder: use only even numbers for SplitY value.
#for splitX value: enter 9 if you want 10 bricks across since 9 cuts to a poly will result in 10 pieces.
def popup(var,type,dialog):
	if lx.eval("query scriptsysservice userValue.isDefined ? %(var)s" % vars()) == 0 :
		lx.eval("user.defNew %(var)s %(type)s temporary" % vars())
	if dialog != None :
		lx.eval("user.value %(var)s" % vars())
	return lx.eval("user.value %(var)s ?" % vars())

argX=popup("splitX","integer","")
argY=popup("splitY","integer","")

lx.eval("select.type edge")
length = sum(lx.eval('query layerservice edge.length ? %s' % edge)
                 for edge in lx.evalN('query layerservice edges ? selected'))
lx.eval("select.type polygon")
lx.out(length)
correctX = argX+1
Xcount = length/correctX
Xmove = Xcount/2
lx.out(Xmove)

#convert intgr user inputs to str
Xjulienne=argX;
Yjulienne=argY;
    
lx.eval("tool.set poly.julienne on")
lx.eval("tool.attr poly.julienne numX "+str(Xjulienne))
lx.eval("tool.attr poly.julienne numY "+str(Yjulienne))
lx.eval("tool.attr poly.julienne offX 0.0")
lx.eval("tool.attr poly.julienne offY 0.0")
lx.eval("tool.attr poly.julienne offZ 0.0")
lx.eval("tool.doApply")    
lx.eval("tool.set poly.julienne off")

#define custom function
def select_prev_loop():
	lx.eval("select.loop prev")
	lx.eval("select.editSet brick1 add")
	lx.eval("select.loop prev") 
	
#need to go thru only half of Y count (every other row)
y = argY/2;

#call the function
for i in range(y):
    select_prev_loop()	

lx.eval("select.drop polygon")
lx.eval("select.useSet brick1 select")
lx.eval("cut")
lx.eval("paste")
lx.eval("select.useSet brick1 select")
lx.eval("tool.set TransformMove on")
lx.eval("tool.reset")
lx.eval("tool.setAttr xfrm.transform TX "+str(Xmove))
lx.eval("tool.doApply")
lx.eval("select.deleteSet brick1")
lx.eval("select.nextMode")
lx.eval("select.drop polygon")
