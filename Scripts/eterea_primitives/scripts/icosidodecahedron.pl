#!perl
#
#@Icosidodecahedron.pl
#
#--------------------------------------
#A Script By Allan Kiipli (c) 2010 2012
#--------------------------------------
#
#Draws Icosidodecahedron with edgelength one.
#Creates uv layout for new polygons.

$currentScene = lxq("query sceneservice scene.index ? current");

lxout("currentScene $currentScene");

lx("select.drop item");

lx("layer.new");

lx("item.name {icosidodecahedron}");

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
lx("tool.attr prim.cube sizeX 1");
lx("tool.attr prim.cube sizeY [5^.5*.5+1.5]");
lx("tool.attr prim.cube sizeZ [5^.5*.5+.5]");
lx("tool.apply");
lx("tool.attr prim.cube sizeY 1");
lx("tool.attr prim.cube sizeZ [5^.5*.5+1.5]");
lx("tool.attr prim.cube sizeX [5^.5*.5+.5]");
lx("tool.apply");
lx("tool.attr prim.cube sizeZ 1");
lx("tool.attr prim.cube sizeX [5^.5*.5+1.5]");
lx("tool.attr prim.cube sizeY [5^.5*.5+.5]");
lx("tool.apply");
lx("tool.set prim.cube off");

lx("tool.set prim.makeVertex on 0");
lx("tool.reset prim.makeVertex");
lx("tool.attr prim.makeVertex cenY [5^.5*.5+.5]");
lx("tool.apply");
lx("tool.attr prim.makeVertex cenY [-(5^.5*.5+.5)]");
lx("tool.apply");
lx("tool.attr prim.makeVertex cenY 0");
lx("tool.attr prim.makeVertex cenZ [5^.5*.5+.5]");
lx("tool.apply");
lx("tool.attr prim.makeVertex cenZ [-(5^.5*.5+.5)]");
lx("tool.apply");
lx("tool.attr prim.makeVertex cenZ 0");
lx("tool.attr prim.makeVertex cenX [5^.5*.5+.5]");
lx("tool.apply");
lx("tool.attr prim.makeVertex cenX [-(5^.5*.5+.5)]");
lx("tool.apply");
lx("tool.set prim.makeVertex off 0");
lx("select.drop vertex");
lx("select.invert");
lx("select.copy");
lx("select.delete");
lx("select.paste");
#0
lx("select.element $layerindex vertex add 24");
lx("select.element $layerindex vertex add 4");
lx("select.element $layerindex vertex add 20");
lx("select.element $layerindex vertex add 23");
lx("select.element $layerindex vertex add 7");
lx("poly.make face");
#1
lx("select.element $layerindex vertex add 5");
lx("select.element $layerindex vertex add 24");
lx("select.element $layerindex vertex add 6");
lx("select.element $layerindex vertex add 22");
lx("select.element $layerindex vertex add 21");
lx("poly.make face");
#2
lx("select.element $layerindex vertex add 6");
lx("select.element $layerindex vertex add 24");
lx("select.element $layerindex vertex add 7");
lx("poly.make face");
#3
lx("select.element $layerindex vertex add 7");
lx("select.element $layerindex vertex add 15");
lx("select.element $layerindex vertex add 26");
lx("select.element $layerindex vertex add 14");
lx("select.element $layerindex vertex add 6");
lx("poly.make face");
#4
lx("select.element $layerindex vertex add 11");
lx("select.element $layerindex vertex add 3");
lx("select.element $layerindex vertex add 2");
lx("select.element $layerindex vertex add 10");
lx("select.element $layerindex vertex add 26");
lx("poly.make face");
#5
lx("select.element $layerindex vertex add 11");
lx("select.element $layerindex vertex add 26");
lx("select.element $layerindex vertex add 15");
lx("poly.make face");
#6
lx("select.element $layerindex vertex add 10");
lx("select.element $layerindex vertex add 14");
lx("select.element $layerindex vertex add 26");
lx("poly.make face");
#7
lx("select.element $layerindex vertex add 23");
lx("select.element $layerindex vertex add 29");
lx("select.element $layerindex vertex add 19");
lx("select.element $layerindex vertex add 11");
lx("select.element $layerindex vertex add 15");
lx("poly.make face");
#8
lx("select.element $layerindex vertex add 15");
lx("select.element $layerindex vertex add 7");
lx("select.element $layerindex vertex add 23");
lx("poly.make face");
#9
lx("select.element $layerindex vertex add 3");
lx("select.element $layerindex vertex add 11");
lx("select.element $layerindex vertex add 19");
lx("poly.make face");
#10
lx("select.element $layerindex vertex add 29");
lx("select.element $layerindex vertex add 23");
lx("select.element $layerindex vertex add 20");
lx("poly.make face");
#11
lx("select.element $layerindex vertex add 16");
lx("select.element $layerindex vertex add 19");
lx("select.element $layerindex vertex add 29");
lx("poly.make face");
#12
lx("select.element $layerindex vertex add 16");
lx("select.element $layerindex vertex add 0");
lx("select.element $layerindex vertex add 25");
lx("select.element $layerindex vertex add 3");
lx("select.element $layerindex vertex add 19");
lx("poly.make face");
#13
lx("select.element $layerindex vertex add 25");
lx("select.element $layerindex vertex add 1");
lx("select.element $layerindex vertex add 17");
lx("select.element $layerindex vertex add 18");
lx("select.element $layerindex vertex add 2");
lx("poly.make face");
#14
lx("select.element $layerindex vertex add 25");
lx("select.element $layerindex vertex add 2");
lx("select.element $layerindex vertex add 3");
lx("poly.make face");
#15
lx("select.element $layerindex vertex add 14");
lx("select.element $layerindex vertex add 10");
lx("select.element $layerindex vertex add 18");
lx("select.element $layerindex vertex add 28");
lx("select.element $layerindex vertex add 22");
lx("poly.make face");
#16
lx("select.element $layerindex vertex add 14");
lx("select.element $layerindex vertex add 22");
lx("select.element $layerindex vertex add 6");
lx("poly.make face");
#17
lx("select.element $layerindex vertex add 2");
lx("select.element $layerindex vertex add 18");
lx("select.element $layerindex vertex add 10");
lx("poly.make face");
#18
lx("select.element $layerindex vertex add 28");
lx("select.element $layerindex vertex add 21");
lx("select.element $layerindex vertex add 22");
lx("poly.make face");
#19
lx("select.element $layerindex vertex add 28");
lx("select.element $layerindex vertex add 17");
lx("select.element $layerindex vertex add 9");
lx("select.element $layerindex vertex add 13");
lx("select.element $layerindex vertex add 21");
lx("poly.make face");
#20
lx("select.element $layerindex vertex add 21");
lx("select.element $layerindex vertex add 13");
lx("select.element $layerindex vertex add 5");
lx("poly.make face");
#21
lx("select.element $layerindex vertex add 1");
lx("select.element $layerindex vertex add 9");
lx("select.element $layerindex vertex add 17");
lx("poly.make face");
#22
lx("select.element $layerindex vertex add 9");
lx("select.element $layerindex vertex add 1");
lx("select.element $layerindex vertex add 0");
lx("select.element $layerindex vertex add 8");
lx("select.element $layerindex vertex add 27");
lx("poly.make face");
#23
lx("select.element $layerindex vertex add 25");
lx("select.element $layerindex vertex add 0");
lx("select.element $layerindex vertex add 1");
lx("poly.make face");
#24
lx("select.element $layerindex vertex add 9");
lx("select.element $layerindex vertex add 27");
lx("select.element $layerindex vertex add 13");
lx("poly.make face");
#25
lx("select.element $layerindex vertex add 5");
lx("select.element $layerindex vertex add 13");
lx("select.element $layerindex vertex add 27");
lx("select.element $layerindex vertex add 12");
lx("select.element $layerindex vertex add 4");
lx("poly.make face");
#26
lx("select.element $layerindex vertex add 8");
lx("select.element $layerindex vertex add 12");
lx("select.element $layerindex vertex add 27");
lx("poly.make face");
#27
lx("select.element $layerindex vertex add 12");
lx("select.element $layerindex vertex add 20");
lx("select.element $layerindex vertex add 4");
lx("poly.make face");
#28
lx("select.element $layerindex vertex add 12");
lx("select.element $layerindex vertex add 8");
lx("select.element $layerindex vertex add 16");
lx("select.element $layerindex vertex add 29");
lx("select.element $layerindex vertex add 20");
lx("poly.make face");
#29
lx("select.element $layerindex vertex add 0");
lx("select.element $layerindex vertex add 16");
lx("select.element $layerindex vertex add 8");
lx("poly.make face");
#30
lx("select.element $layerindex vertex add 4");
lx("select.element $layerindex vertex add 24");
lx("select.element $layerindex vertex add 5");
lx("poly.make face");
#31
lx("select.element $layerindex vertex add 18");
lx("select.element $layerindex vertex add 17");
lx("select.element $layerindex vertex add 28");
lx("poly.make face");
lx("select.drop polygon");
lx("tool.set uv.create on");
lx("tool.attr uv.create proj barycentric");
lx("tool.setAttr uv.create cenX 0.0");
lx("tool.setAttr uv.create cenY 0.0");
lx("tool.setAttr uv.create cenZ 0.0");
lx("tool.setAttr uv.create sizX 1.0");
lx("tool.setAttr uv.create sizY 1.0");
lx("tool.setAttr uv.create sizZ 1.0");
lx("tool.setAttr uv.create seam 0.0");
lx("tool.setAttr uv.create axis 2");
lx("tool.doApply");
lx("tool.set uv.create off 0");
lx("uv.pack true false false auto 0.2 false");
lx("select.type edge");
lx("select.element $layerindex edge set 7 24 0");
lx("uv.sewMove select 1");
lx("select.element $layerindex edge set 24 4 0");
lx("uv.sewMove select 1");
lx("select.element $layerindex edge set 4 20 0");
lx("uv.sewMove select 1");
lx("select.element $layerindex edge set 20 23 0");
lx("uv.sewMove select 1");
lx("select.element $layerindex edge set 23 7 0");
lx("uv.sewMove select 1");
lx("select.element $layerindex edge set 7 15 8");
lx("uv.sewMove select 1");
lx("select.element $layerindex edge set 6 24 2");
lx("uv.sewMove select 1");
lx("select.element $layerindex edge set 4 5 30");
lx("uv.sewMove select 1");
lx("select.element $layerindex edge set 20 12 27");
lx("uv.sewMove select 1");
lx("select.element $layerindex edge set 23 29 10");
lx("uv.sewMove select 1");
lx("select.element $layerindex edge set 14 6 3");
lx("uv.sewMove select 1");
lx("select.element $layerindex edge set 5 21 1");
lx("uv.sewMove select 1");
lx("select.element $layerindex edge set 12 27 26");
lx("uv.sewMove select 1");
lx("select.element $layerindex edge set 29 16 28");
lx("uv.sewMove select 1");
lx("select.element $layerindex edge set 15 11 7");
lx("uv.sewMove select 1");
lx("select.element $layerindex edge set 1 25 13");
lx("uv.sewMove select 1");
lx("select.element $layerindex edge set 25 2 13");
lx("uv.sewMove select 1");
lx("select.element $layerindex edge set 2 18 13");
lx("uv.sewMove select 1");
lx("select.element $layerindex edge set 18 17 13");
lx("uv.sewMove select 1");
lx("select.element $layerindex edge set 17 1 13");
lx("uv.sewMove select 1");
lx("select.element $layerindex edge set 17 9 21");
lx("uv.sewMove select 1");
lx("select.element $layerindex edge set 28 18 31");
lx("uv.sewMove select 1");
lx("select.element $layerindex edge set 10 2 17");
lx("uv.sewMove select 1");
lx("select.element $layerindex edge set 3 25 14");
lx("uv.sewMove select 1");
lx("select.element $layerindex edge set 0 1 23");
lx("uv.sewMove select 1");
lx("select.element $layerindex edge set 9 27 24");
lx("uv.sewMove select 1");
lx("select.element $layerindex edge set 21 28 19");
lx("uv.sewMove select 1");
lx("select.element $layerindex edge set 10 14 15");
lx("uv.sewMove select 1");
lx("select.element $layerindex edge set 11 3 4");
lx("uv.sewMove select 1");
lx("select.element $layerindex edge set 0 16 12");
lx("uv.sewMove select 1");
lx("select.element $layerindex edge set 27 9 22");
lx("uv.sewMove select 1");
lx("select.element $layerindex edge set 13 27 24");
lx("uv.sewMove select 1");

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