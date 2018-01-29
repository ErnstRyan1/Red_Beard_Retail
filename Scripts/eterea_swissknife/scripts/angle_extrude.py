#python
#angle_extrude.py by <ylaz 2012>
def popup(var,type,dialog):
	if lx.eval("query scriptsysservice userValue.isDefined ? %(var)s" % vars()) == 0 :
		lx.eval("user.defNew %(var)s %(type)s temporary" % vars())
	if dialog != None :
		lx.eval("user.value %(var)s" % vars())
	return lx.eval("user.value %(var)s ?" % vars())

segments=popup("segments","integer","")
angle=popup("angle","integer","")

segmentsNum = segments;
angleNum = angle;

lx.eval("select.type edge")
lx.eval("workPlane.fitSelect")
lx.eval("select.type polygon")
lx.eval('tool.set "Radial Sweep" on')
lx.eval("tool.attr gen.helix sides "+str(segmentsNum))
lx.eval("tool.attr gen.helix axis 0")
lx.eval("tool.attr gen.helix start 0.0")
lx.eval("tool.attr gen.helix end "+str(angleNum))
lx.eval("tool.attr gen.helix offset 0.0")
lx.eval("tool.attr effector.sweep flip true")
lx.eval("tool.attr effector.sweep cap0 false")
lx.eval("tool.attr effector.sweep cap1 true")
lx.eval("tool.attr center.auto cenX 0.0")
lx.eval("tool.attr center.auto cenY 0.0")
lx.eval("tool.attr center.auto cenZ 0.0")
lx.eval("tool.apply")
lx.eval('tool.set "Radial Sweep" off')
lx.eval("workPlane.reset")

