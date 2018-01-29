#perl
#ver 1.0
#author : Seneca Menard

#hack tube scalar script.  It wouldn't work if the tube were closed off or connected to other geometry.

if     ((lxq("select.typeFrom {edge;polygon;item;vertex} ?")) && (lxq("select.count edge ?") > 0)){
	lx("select.loop");
	lx("select.ring");
	lx("tool.set center.local on");
	lx("tool.set axis.auto on");
	lx("tool.set xfrm.scale on");
}elsif ((lxq("select.typeFrom {polygon;item;vertex;edge} ?")) && (lxq("select.count polygon ?") > 0)){
	lx("select.connect");
	lx("select.drop edge");
	lx("select.type polygon");
	lx("select.boundary");
	lx("select.ring");
	lx("tool.set center.local on");
	lx("tool.set axis.auto on");
	lx("tool.set xfrm.scale on");
}
