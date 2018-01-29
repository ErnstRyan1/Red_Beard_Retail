#!perl
#
#@Dodecahedron_1.pl ribbon
#
#--------------------------------------
#A Script By Allan Kiipli (c) 2010 2012
#--------------------------------------
#
#2:39 2.12.2011 Add 'ribbon' to have ribbon type uv.
#Creates dodecahedron at origin with edges of length 1.0.
#Creates also uv layout for the body of the primitive.
#When creating uv-s, polys come in in topological manner.
#So when you check uv-s in ZBrush, you should have
#nice picture. Also it is important for subdivided
#variants, because subdivisions maintain this order
#inside polygons per polygon.

$ribbon = 0;

if("@ARGV" =~ /\bribbon\b/)
{
 $ribbon = 1;
}

lxout("ribbon $ribbon");

$currentScene = lxq("query sceneservice scene.index ? current");

lxout("currentScene $currentScene");

lx("select.drop item");

lx("layer.new");

lx("item.name {dodecahedron}");

$mainLayer = lxq("query layerservice layers ? main");

lxout("mainLayer $mainLayer");

$layerindex = lxq("query layerservice layer.index ? $mainLayer");

lxout("layerindex $layerindex");

$units = lxq("pref.value {units.system} ?");

lx("pref.value units.system si");

lxout("units $units");

lx("select.symmetryState none");
lx("tool.set prim.cube on");
lx("tool.reset prim.cube");
lx("tool.attr prim.cube cenX 0.0");
lx("tool.attr prim.cube cenY 0.0");
lx("tool.attr prim.cube cenZ 0.0");
lx("tool.attr prim.cube sizeX [5^.5*.5+.5]");
lx("tool.attr prim.cube sizeY [5^.5*.5+.5]");
lx("tool.attr prim.cube sizeZ [5^.5*.5+.5]");
lx("tool.apply");
lx("tool.attr prim.cube sizeX 1");
lx("tool.attr prim.cube sizeY 0.0");
lx("tool.attr prim.cube sizeZ [5^.5*.5+1.5]");
lx("tool.apply");
lx("tool.attr prim.cube sizeX 0.0");
lx("tool.attr prim.cube sizeY [5^.5*.5+1.5]");
lx("tool.attr prim.cube sizeZ 1");
lx("tool.apply");
lx("tool.attr prim.cube sizeX [5^.5*.5+1.5]");
lx("tool.attr prim.cube sizeY 1");
lx("tool.attr prim.cube sizeZ 0.0");
lx("tool.apply");
lx("tool.set prim.cube off 0");
lx("select.drop vertex");
lx("select.invert");
lx("select.copy");
lx("delete");
lx("select.paste");
#0
lx("select.element $layerindex vertex add 5");
lx("select.element $layerindex vertex add 18");
lx("select.element $layerindex vertex add 19");
lx("select.element $layerindex vertex add 1");
lx("select.element $layerindex vertex add 9");
lx("poly.make face");
#1
lx("select.element $layerindex vertex add 19");
lx("select.element $layerindex vertex add 18");
lx("select.element $layerindex vertex add 6");
lx("select.element $layerindex vertex add 10");
lx("select.element $layerindex vertex add 2");
lx("poly.make face");
#2
lx("select.element $layerindex vertex add 14");
lx("select.element $layerindex vertex add 7");
lx("select.element $layerindex vertex add 11");
lx("select.element $layerindex vertex add 10");
lx("select.element $layerindex vertex add 6");
lx("poly.make face");
#3
lx("select.element $layerindex vertex add 14");
lx("select.element $layerindex vertex add 15");
lx("select.element $layerindex vertex add 4");
lx("select.element $layerindex vertex add 17");
lx("select.element $layerindex vertex add 7");
lx("poly.make face");
#4
lx("select.element $layerindex vertex add 6");
lx("select.element $layerindex vertex add 18");
lx("select.element $layerindex vertex add 5");
lx("select.element $layerindex vertex add 15");
lx("select.element $layerindex vertex add 14");
lx("poly.make face");
#5
lx("select.element $layerindex vertex add 15");
lx("select.element $layerindex vertex add 5");
lx("select.element $layerindex vertex add 9");
lx("select.element $layerindex vertex add 8");
lx("select.element $layerindex vertex add 4");
lx("poly.make face");
#6
lx("select.element $layerindex vertex add 4");
lx("select.element $layerindex vertex add 8");
lx("select.element $layerindex vertex add 0");
lx("select.element $layerindex vertex add 16");
lx("select.element $layerindex vertex add 17");
lx("poly.make face");
#7
lx("select.element $layerindex vertex add 12");
lx("select.element $layerindex vertex add 13");
lx("select.element $layerindex vertex add 3");
lx("select.element $layerindex vertex add 16");
lx("select.element $layerindex vertex add 0");
lx("poly.make face");
#8
lx("select.element $layerindex vertex add 17");
lx("select.element $layerindex vertex add 16");
lx("select.element $layerindex vertex add 3");
lx("select.element $layerindex vertex add 11");
lx("select.element $layerindex vertex add 7");
lx("poly.make face");
#9
lx("select.element $layerindex vertex add 10");
lx("select.element $layerindex vertex add 11");
lx("select.element $layerindex vertex add 3");
lx("select.element $layerindex vertex add 13");
lx("select.element $layerindex vertex add 2");
lx("poly.make face");
#10
lx("select.element $layerindex vertex add 19");
lx("select.element $layerindex vertex add 2");
lx("select.element $layerindex vertex add 13");
lx("select.element $layerindex vertex add 12");
lx("select.element $layerindex vertex add 1");
lx("poly.make face");
#11
lx("select.element $layerindex vertex add 9");
lx("select.element $layerindex vertex add 1");
lx("select.element $layerindex vertex add 12");
lx("select.element $layerindex vertex add 0");
lx("select.element $layerindex vertex add 8");
lx("poly.make face");
lx("tool.set uv.create on");
lx("tool.attr uv.create proj barycentric");
lx("tool.setAttr uv.create cenX 0.0");
lx("tool.setAttr uv.create cenY 0.0");
lx("tool.setAttr uv.create cenZ 0.0");
lx("tool.setAttr uv.create sizX [5^.5*.5+.5]");
lx("tool.setAttr uv.create sizY [5^.5*.5+.5]");
lx("tool.setAttr uv.create sizZ [5^.5*.5+.5]");
lx("tool.setAttr uv.create seam 0.0");
lx("tool.setAttr uv.create axis 2");
lx("tool.doApply");
lx("tool.set uv.create off 0");
lx("uv.pack true false false auto 0.2 false");
lx("select.type edge");
lx("select.element $layerindex edge set 18 5 4");
lx("uv.sewMove select 1");
lx("select.element $layerindex edge set 18 6 4");
lx("uv.sewMove select 1");

if($ribbon)
{
 lx("select.element $layerindex edge set 6 10 1");
 lx("uv.sewMove select 1");
 lx("select.element $layerindex edge set 5 9 0");
 lx("uv.sewMove select 1");
 lx("select.element $layerindex edge set 9 8 5");
 lx("uv.sewMove select 1");
 lx("select.element $layerindex edge set 10 11 2");
 lx("uv.sewMove select 1");
 lx("select.element $layerindex edge set 3 11 9");
 lx("uv.sewMove select 1");
 lx("select.element $layerindex edge set 0 8 11");
 lx("uv.sewMove select 1");
 lx("select.element $layerindex edge set 0 16 6");
 lx("uv.sewMove select 1");
 lx("select.element $layerindex edge set 7 14 2");
 lx("uv.sewMove select 1");
 lx("select.element $layerindex edge set 1 12 11");
 lx("uv.sewMove select 1");
}
else
{
 lx("select.element $layerindex edge set 14 6 4");
 lx("uv.sewMove select 1");
 lx("select.element $layerindex edge set 15 14 4");
 lx("uv.sewMove select 1");
 lx("select.element $layerindex edge set 15 5 4");
 lx("uv.sewMove select 1");
 lx("select.element $layerindex edge set 16 0 7");
 lx("uv.sewMove select 1");
 lx("select.element $layerindex edge set 16 3 7");
 lx("uv.sewMove select 1");
 lx("select.element $layerindex edge set 13 3 7");
 lx("uv.sewMove select 1");
 lx("select.element $layerindex edge set 13 12 7");
 lx("uv.sewMove select 1");
 lx("select.element $layerindex edge set 12 0 7");
 lx("uv.sewMove select 1");
 lx("select.element $layerindex edge set 8 4 5");
 lx("uv.sewMove select 1");
}

lx("uv.fit false true");
lx("select.drop polygon");
lx("tool.set actr.auto on");
lx("tool.set TransformScale on");
lx("tool.reset");
lx("tool.viewType uv");
lx("tool.setAttr xfrm.transform SX .99");
lx("tool.setAttr xfrm.transform SY .99");
lx("tool.doApply");
lx("tool.set TransformScale off");
lx("tool.set TransformMove on");
lx("tool.reset");
lx("tool.viewType uv");
lx("tool.setAttr xfrm.transform U .005");
lx("tool.setAttr xfrm.transform V .005");
lx("tool.doApply");
lx("tool.viewType xyz");
lx("tool.set TransformMove off");
lx("tool.set actr.auto off");
lx("select.drop vertex");

lx("pref.value units.system $units");