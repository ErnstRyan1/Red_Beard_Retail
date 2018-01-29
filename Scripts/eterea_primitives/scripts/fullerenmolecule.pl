#!perl
#
#@Fullerenmolecule.pl
#
#--------------------------------------------
#A Script By Allan Kiipli (c) 11:36 7.10.2010
#--------------------------------------------
#
#Creates fullerenmolecule at origin with edges of length 1.0.
#Creates also uv layout for the body of the primitive.
#Numbers polygon indexes from left to right in uv-space.

$currentScene = lxq("query sceneservice scene.index ? current");

lxout("currentScene $currentScene");

lx("select.drop item");

lx("layer.new");

lx("item.name {fullerenmolecule}");

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
lx("tool.attr prim.cube sizeY [(5^.5*.5+.5)*3]");
lx("tool.attr prim.cube sizeZ 0");
lx("tool.apply");
lx("tool.attr prim.cube cenX 0.0");
lx("tool.attr prim.cube cenY 0.0");
lx("tool.attr prim.cube cenZ [(5^.5*.5+.5)*.5]");
lx("tool.attr prim.cube sizeX 2");
lx("tool.attr prim.cube sizeY [(5^.5*.5+.5)*2+1]");
lx("tool.attr prim.cube sizeZ 0");
lx("tool.apply");
lx("tool.attr prim.cube cenX 0.0");
lx("tool.attr prim.cube cenY 0.0");
lx("tool.attr prim.cube cenZ [5^.5*.5+.5]");
lx("tool.attr prim.cube sizeX 1");
lx("tool.attr prim.cube sizeY [5^.5*.5+2.5]");
lx("tool.attr prim.cube sizeZ 0");
lx("tool.apply");
lx("tool.attr prim.cube cenX 0.0");
lx("tool.attr prim.cube cenY 0.0");
lx("tool.attr prim.cube cenZ [-(5^.5*.5+.5)*.5]");
lx("tool.attr prim.cube sizeX 2");
lx("tool.attr prim.cube sizeY [(5^.5*.5+.5)*2+1]");
lx("tool.attr prim.cube sizeZ 0");
lx("tool.apply");
lx("tool.attr prim.cube cenX 0.0");
lx("tool.attr prim.cube cenY 0.0");
lx("tool.attr prim.cube cenZ [-(5^.5*.5+.5)]");
lx("tool.attr prim.cube sizeX 1");
lx("tool.attr prim.cube sizeY [5^.5*.5+2.5]");
lx("tool.attr prim.cube sizeZ 0");
lx("tool.apply");
lx("tool.attr prim.cube cenY 0.0");
lx("tool.attr prim.cube cenZ 0.0");
lx("tool.attr prim.cube cenX 0.0");
lx("tool.attr prim.cube sizeY 1");
lx("tool.attr prim.cube sizeZ [(5^.5*.5+.5)*3]");
lx("tool.attr prim.cube sizeX 0");
lx("tool.apply");
lx("tool.attr prim.cube cenY 0.0");
lx("tool.attr prim.cube cenZ 0.0");
lx("tool.attr prim.cube cenX [(5^.5*.5+.5)*.5]");
lx("tool.attr prim.cube sizeY 2");
lx("tool.attr prim.cube sizeZ [(5^.5*.5+.5)*2+1]");
lx("tool.attr prim.cube sizeX 0");
lx("tool.apply");
lx("tool.attr prim.cube cenY 0.0");
lx("tool.attr prim.cube cenZ 0.0");
lx("tool.attr prim.cube cenX [5^.5*.5+.5]");
lx("tool.attr prim.cube sizeY 1");
lx("tool.attr prim.cube sizeZ [5^.5*.5+2.5]");
lx("tool.attr prim.cube sizeX 0");
lx("tool.apply");
lx("tool.attr prim.cube cenY 0.0");
lx("tool.attr prim.cube cenZ 0.0");
lx("tool.attr prim.cube cenX [-(5^.5*.5+.5)*.5]");
lx("tool.attr prim.cube sizeY 2");
lx("tool.attr prim.cube sizeZ [(5^.5*.5+.5)*2+1]");
lx("tool.attr prim.cube sizeX 0");
lx("tool.apply");
lx("tool.attr prim.cube cenY 0.0");
lx("tool.attr prim.cube cenZ 0.0");
lx("tool.attr prim.cube cenX [-(5^.5*.5+.5)]");
lx("tool.attr prim.cube sizeY 1");
lx("tool.attr prim.cube sizeZ [5^.5*.5+2.5]");
lx("tool.attr prim.cube sizeX 0");
lx("tool.apply");
lx("tool.attr prim.cube cenZ 0.0");
lx("tool.attr prim.cube cenX 0.0");
lx("tool.attr prim.cube cenY 0.0");
lx("tool.attr prim.cube sizeZ 1");
lx("tool.attr prim.cube sizeX [(5^.5*.5+.5)*3]");
lx("tool.attr prim.cube sizeY 0");
lx("tool.apply");
lx("tool.attr prim.cube cenZ 0.0");
lx("tool.attr prim.cube cenX 0.0");
lx("tool.attr prim.cube cenY [(5^.5*.5+.5)*.5]");
lx("tool.attr prim.cube sizeZ 2");
lx("tool.attr prim.cube sizeX [(5^.5*.5+.5)*2+1]");
lx("tool.attr prim.cube sizeY 0");
lx("tool.apply");
lx("tool.attr prim.cube cenZ 0.0");
lx("tool.attr prim.cube cenX 0.0");
lx("tool.attr prim.cube cenY [5^.5*.5+.5]");
lx("tool.attr prim.cube sizeZ 1");
lx("tool.attr prim.cube sizeX [5^.5*.5+2.5]");
lx("tool.attr prim.cube sizeY 0");
lx("tool.apply");
lx("tool.attr prim.cube cenZ 0.0");
lx("tool.attr prim.cube cenX 0.0");
lx("tool.attr prim.cube cenY [-(5^.5*.5+.5)*.5]");
lx("tool.attr prim.cube sizeZ 2");
lx("tool.attr prim.cube sizeX [(5^.5*.5+.5)*2+1]");
lx("tool.attr prim.cube sizeY 0");
lx("tool.apply");
lx("tool.attr prim.cube cenZ 0.0");
lx("tool.attr prim.cube cenX 0.0");
lx("tool.attr prim.cube cenY [-(5^.5*.5+.5)]");
lx("tool.attr prim.cube sizeZ 1");
lx("tool.attr prim.cube sizeX [5^.5*.5+2.5]");
lx("tool.attr prim.cube sizeY 0");
lx("tool.apply");
lx("tool.set prim.cube off 0");
lx("select.drop vertex");
lx("select.invert");
lx("select.copy");
lx("delete");
lx("select.paste");
#0
lx("select.element $layerindex vertex add 1");
lx("select.element $layerindex vertex add 13");
lx("select.element $layerindex vertex add 48");
lx("select.element $layerindex vertex add 51");
lx("select.element $layerindex vertex add 5");
lx("poly.make face");
#1
lx("select.element $layerindex vertex add 2");
lx("select.element $layerindex vertex add 1");
lx("select.element $layerindex vertex add 5");
lx("select.element $layerindex vertex add 9");
lx("select.element $layerindex vertex add 10");
lx("select.element $layerindex vertex add 6");
lx("poly.make face");
#2
lx("select.element $layerindex vertex add 50");
lx("select.element $layerindex vertex add 6");
lx("select.element $layerindex vertex add 10");
lx("select.element $layerindex vertex add 26");
lx("select.element $layerindex vertex add 30");
lx("select.element $layerindex vertex add 46");
lx("poly.make face");
#3
lx("select.element $layerindex vertex add 42");
lx("select.element $layerindex vertex add 46");
lx("select.element $layerindex vertex add 30");
lx("select.element $layerindex vertex add 29");
lx("select.element $layerindex vertex add 54");
lx("poly.make face");
#4
lx("select.element $layerindex vertex add 40");
lx("select.element $layerindex vertex add 44");
lx("select.element $layerindex vertex add 39");
lx("select.element $layerindex vertex add 36");
lx("select.element $layerindex vertex add 52");
lx("poly.make face");
#5
lx("select.element $layerindex vertex add 13");
lx("select.element $layerindex vertex add 17");
lx("select.element $layerindex vertex add 35");
lx("select.element $layerindex vertex add 39");
lx("select.element $layerindex vertex add 44");
lx("select.element $layerindex vertex add 48");
lx("poly.make face");
#6
lx("select.element $layerindex vertex add 1");
lx("select.element $layerindex vertex add 2");
lx("select.element $layerindex vertex add 14");
lx("select.element $layerindex vertex add 18");
lx("select.element $layerindex vertex add 17");
lx("select.element $layerindex vertex add 13");
lx("poly.make face");
#7
lx("select.element $layerindex vertex add 2");
lx("select.element $layerindex vertex add 6");
lx("select.element $layerindex vertex add 50");
lx("select.element $layerindex vertex add 49");
lx("select.element $layerindex vertex add 14");
lx("poly.make face");
#8
lx("select.element $layerindex vertex add 17");
lx("select.element $layerindex vertex add 18");
lx("select.element $layerindex vertex add 27");
lx("select.element $layerindex vertex add 23");
lx("select.element $layerindex vertex add 35");
lx("poly.make face");
#9
lx("select.element $layerindex vertex add 14");
lx("select.element $layerindex vertex add 49");
lx("select.element $layerindex vertex add 45");
lx("select.element $layerindex vertex add 31");
lx("select.element $layerindex vertex add 27");
lx("select.element $layerindex vertex add 18");
lx("poly.make face");
#10
lx("select.element $layerindex vertex add 50");
lx("select.element $layerindex vertex add 46");
lx("select.element $layerindex vertex add 42");
lx("select.element $layerindex vertex add 41");
lx("select.element $layerindex vertex add 45");
lx("select.element $layerindex vertex add 49");
lx("poly.make face");
#11
lx("select.element $layerindex vertex add 35");
lx("select.element $layerindex vertex add 23");
lx("select.element $layerindex vertex add 20");
lx("select.element $layerindex vertex add 32");
lx("select.element $layerindex vertex add 36");
lx("select.element $layerindex vertex add 39");
lx("poly.make face");
#12
lx("select.element $layerindex vertex add 23");
lx("select.element $layerindex vertex add 27");
lx("select.element $layerindex vertex add 31");
lx("select.element $layerindex vertex add 28");
lx("select.element $layerindex vertex add 24");
lx("select.element $layerindex vertex add 20");
lx("poly.make face");
#13
lx("select.element $layerindex vertex add 45");
lx("select.element $layerindex vertex add 41");
lx("select.element $layerindex vertex add 53");
lx("select.element $layerindex vertex add 28");
lx("select.element $layerindex vertex add 31");
lx("poly.make face");
#14
lx("select.element $layerindex vertex add 20");
lx("select.element $layerindex vertex add 24");
lx("select.element $layerindex vertex add 19");
lx("select.element $layerindex vertex add 16");
lx("select.element $layerindex vertex add 32");
lx("poly.make face");
#15
lx("select.element $layerindex vertex add 28");
lx("select.element $layerindex vertex add 53");
lx("select.element $layerindex vertex add 57");
lx("select.element $layerindex vertex add 15");
lx("select.element $layerindex vertex add 19");
lx("select.element $layerindex vertex add 24");
lx("poly.make face");
#16
lx("select.element $layerindex vertex add 41");
lx("select.element $layerindex vertex add 42");
lx("select.element $layerindex vertex add 54");
lx("select.element $layerindex vertex add 58");
lx("select.element $layerindex vertex add 57");
lx("select.element $layerindex vertex add 53");
lx("poly.make face");
#17
lx("select.element $layerindex vertex add 52");
lx("select.element $layerindex vertex add 36");
lx("select.element $layerindex vertex add 32");
lx("select.element $layerindex vertex add 16");
lx("select.element $layerindex vertex add 12");
lx("select.element $layerindex vertex add 56");
lx("poly.make face");
#18
lx("select.element $layerindex vertex add 0");
lx("select.element $layerindex vertex add 12");
lx("select.element $layerindex vertex add 16");
lx("select.element $layerindex vertex add 19");
lx("select.element $layerindex vertex add 15");
lx("select.element $layerindex vertex add 3");
lx("poly.make face");
#19
lx("select.element $layerindex vertex add 58");
lx("select.element $layerindex vertex add 7");
lx("select.element $layerindex vertex add 3");
lx("select.element $layerindex vertex add 15");
lx("select.element $layerindex vertex add 57");
lx("poly.make face");
#20
lx("select.element $layerindex vertex add 0");
lx("select.element $layerindex vertex add 4");
lx("select.element $layerindex vertex add 59");
lx("select.element $layerindex vertex add 56");
lx("select.element $layerindex vertex add 12");
lx("poly.make face");
#21
lx("select.element $layerindex vertex add 0");
lx("select.element $layerindex vertex add 3");
lx("select.element $layerindex vertex add 7");
lx("select.element $layerindex vertex add 11");
lx("select.element $layerindex vertex add 8");
lx("select.element $layerindex vertex add 4");
lx("poly.make face");
#22
lx("select.element $layerindex vertex add 54");
lx("select.element $layerindex vertex add 29");
lx("select.element $layerindex vertex add 25");
lx("select.element $layerindex vertex add 11");
lx("select.element $layerindex vertex add 7");
lx("select.element $layerindex vertex add 58");
lx("poly.make face");
#23
lx("select.element $layerindex vertex add 43");
lx("select.element $layerindex vertex add 40");
lx("select.element $layerindex vertex add 52");
lx("select.element $layerindex vertex add 56");
lx("select.element $layerindex vertex add 59");
lx("select.element $layerindex vertex add 55");
lx("poly.make face");
#24
lx("select.element $layerindex vertex add 37");
lx("select.element $layerindex vertex add 55");
lx("select.element $layerindex vertex add 59");
lx("select.element $layerindex vertex add 4");
lx("select.element $layerindex vertex add 8");
lx("select.element $layerindex vertex add 33");
lx("poly.make face");
#25
lx("select.element $layerindex vertex add 21");
lx("select.element $layerindex vertex add 33");
lx("select.element $layerindex vertex add 8");
lx("select.element $layerindex vertex add 11");
lx("select.element $layerindex vertex add 25");
lx("poly.make face");
#26
lx("select.element $layerindex vertex add 47");
lx("select.element $layerindex vertex add 43");
lx("select.element $layerindex vertex add 55");
lx("select.element $layerindex vertex add 37");
lx("select.element $layerindex vertex add 38");
lx("poly.make face");
#27
lx("select.element $layerindex vertex add 34");
lx("select.element $layerindex vertex add 38");
lx("select.element $layerindex vertex add 37");
lx("select.element $layerindex vertex add 33");
lx("select.element $layerindex vertex add 21");
lx("select.element $layerindex vertex add 22");
lx("poly.make face");
#28
lx("select.element $layerindex vertex add 30");
lx("select.element $layerindex vertex add 26");
lx("select.element $layerindex vertex add 22");
lx("select.element $layerindex vertex add 21");
lx("select.element $layerindex vertex add 25");
lx("select.element $layerindex vertex add 29");
lx("poly.make face");
#29
lx("select.element $layerindex vertex add 51");
lx("select.element $layerindex vertex add 48");
lx("select.element $layerindex vertex add 44");
lx("select.element $layerindex vertex add 40");
lx("select.element $layerindex vertex add 43");
lx("select.element $layerindex vertex add 47");
lx("poly.make face");
#30
lx("select.element $layerindex vertex add 9");
lx("select.element $layerindex vertex add 5");
lx("select.element $layerindex vertex add 51");
lx("select.element $layerindex vertex add 47");
lx("select.element $layerindex vertex add 38");
lx("select.element $layerindex vertex add 34");
lx("poly.make face");
#31
lx("select.element $layerindex vertex add 10");
lx("select.element $layerindex vertex add 9");
lx("select.element $layerindex vertex add 34");
lx("select.element $layerindex vertex add 22");
lx("select.element $layerindex vertex add 26");
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
lx("select.element $layerindex edge set 10 6 1");
lx("uv.sewMove select 1");
lx("select.element $layerindex edge set 30 46 2");
lx("uv.sewMove select 1");
lx("select.element $layerindex edge set 5 1 1");
lx("uv.sewMove select 1");
lx("select.element $layerindex edge set 1 2 1");
lx("uv.sewMove select 1");
lx("select.element $layerindex edge set 17 13 6");
lx("uv.sewMove select 1");
lx("select.element $layerindex edge set 2 14 6");
lx("uv.sewMove select 1");
lx("select.element $layerindex edge set 44 39 5");
lx("uv.sewMove select 1");
lx("select.element $layerindex edge set 14 18 6");
lx("uv.sewMove select 1");
lx("select.element $layerindex edge set 18 27 9");
lx("uv.sewMove select 1");
lx("select.element $layerindex edge set 49 45 9");
lx("uv.sewMove select 1");
lx("select.element $layerindex edge set 27 31 9");
lx("uv.sewMove select 1");
lx("select.element $layerindex edge set 23 20 12");
lx("uv.sewMove select 1");
lx("select.element $layerindex edge set 31 28 12");
lx("uv.sewMove select 1");
lx("select.element $layerindex edge set 28 24 12");
lx("uv.sewMove select 1");
lx("select.element $layerindex edge set 24 19 15");
lx("uv.sewMove select 1");
lx("select.element $layerindex edge set 53 57 15");
lx("uv.sewMove select 1");
lx("select.element $layerindex edge set 19 15 15");
lx("uv.sewMove select 1");
lx("select.element $layerindex edge set 16 12 18");
lx("uv.sewMove select 1");
lx("select.element $layerindex edge set 3 15 18");
lx("uv.sewMove select 1");
lx("select.element $layerindex edge set 0 3 18");
lx("uv.sewMove select 1");
lx("select.element $layerindex edge set 0 4 21");
lx("uv.sewMove select 1");
lx("select.element $layerindex edge set 7 11 21");
lx("uv.sewMove select 1");
lx("select.element $layerindex edge set 4 8 21");
lx("uv.sewMove select 1");
lx("select.element $layerindex edge set 59 55 24");
lx("uv.sewMove select 1");
lx("select.element $layerindex edge set 8 33 24");
lx("uv.sewMove select 1");
lx("select.element $layerindex edge set 33 37 24");
lx("uv.sewMove select 1");
lx("select.element $layerindex edge set 37 38 27");
lx("uv.sewMove select 1");
lx("select.element $layerindex edge set 21 22 27");
lx("uv.sewMove select 1");
lx("select.element $layerindex edge set 38 34 27");
lx("uv.sewMove select 1");
lx("select.element $layerindex edge set 47 51 30");
lx("uv.sewMove select 1");
lx("select.element $layerindex edge set 34 9 30");
lx("uv.sewMove select 1");
lx("uv.fit false");
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