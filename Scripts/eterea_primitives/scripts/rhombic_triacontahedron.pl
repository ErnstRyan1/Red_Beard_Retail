#!perl
#
#@RhombicTriacontahedron.pl (square|type1/fold/1.0)
#
#-------------------------------------------
#A Script By Allan Kiipli (c) 2010 2011 2012
#-------------------------------------------
#
#Submit digit or float to scale.
#Modulate final scale $S, if you like;
#Final 7 lines sets new rhombic triacontahedron
#scale to pass setup with stipulated dodecahedrons
#and inbetween edgeplaced icosahedrons
#with edgelength 1. Changed 0:29 18.09.2011
#Creates Rhombic Triacontahedron at
#phi ratio panels and cube.
#Lays out barycentric uv-s and sets the
#proportions in uv space per face.
#(If not 'square' is used). Packs uv-s.
#And sews them into logical strip.
#Indexes polys from left to right in uv-space.
#From left to right goes for strip.
#Add 'square' to force polys into
#square uv-s. Add 'type1' to invert
#polygonal stretch. Add 'fold'
#to force rhombs into 60 degree equilateral triangles
#divided by imaginable edge.
#This results tileable uv honeycomb
#pattern. This pattern is sewn specially.
#If 'square' is used, 'type1' or 'fold'
#have no effect. Progressive indexing
#happens also when square or type1 is
#used, but in vertical direction starting
#from bottom. --- updated vertmap moves
#to Modo v 501

$S = 1;

if("@ARGV" =~ /\b(\d+)(\.?)(\d*)\b/)
{
 $S = $1.$2.$3;
}
else
{
 $S = (sqrt(5)/2+0.5)*2;
}

lxout("S $S");

$square = 0;

if("@ARGV" =~ /\bsquare\b/)
{
 $square = 1;
}

$type1 = 0;

if("@ARGV" =~ /\btype1\b/)
{
 $type1 = 1;
}

$fold = (sqrt(5)/2+0.5)/2;
$fold1 = 0;

if("@ARGV" =~ /\bfold\b/)
{
 $fold = sqrt(1-0.5**2);
 $fold1 = 1;
}

$appversion = lxq("query platformservice appversion ?");

lxout("$appversion");

if($appversion <= 401)
{
 $texture_type = "1";
}
else
{
 $texture_type = "texture";
}

$currentScene = lxq("query sceneservice scene.index ? current");

lxout("currentScene $currentScene");

lx("select.drop item");

lx("layer.new");

lx("item.name {rhombic triacontahedron}");

$mainLayer = lxq("query layerservice layers ? main");

lxout("mainLayer $mainLayer");

$layerindex = lxq("query layerservice layer.index ? $mainLayer");

lxout("layerindex $layerindex");

lx("vertMap.new {Texture} txuv");

$selectedVmap = lxq("query layerservice vmaps ? selected");

lxout("selectedVmap $selectedVmap");

$vmapName = lxq("query layerservice vmap.name ? $selectedVmap");

lxout("vmapName $vmapName");

$units = lxq("pref.value {units.system} ?");

lx("pref.value units.system si");

lxout("units $units");

lx("select.symmetryState none");
lx("tool.set prim.cube on");
lx("tool.reset prim.cube");
lx("tool.attr prim.cube sizeX [5^.5*.5+.5]");
lx("tool.attr prim.cube sizeY [5^.5*.5+1.5]");
lx("tool.attr prim.cube sizeZ 0.0");
lx("tool.apply");
lx("tool.attr prim.cube sizeX 0.0");
lx("tool.attr prim.cube sizeY [5^.5*.5+1.5]");
lx("tool.attr prim.cube sizeZ 1.0");
lx("tool.apply");
lx("tool.attr prim.cube sizeX 1.0");
lx("tool.attr prim.cube sizeY 0.0");
lx("tool.attr prim.cube sizeZ [5^.5*.5+1.5]");
lx("tool.apply");
lx("tool.attr prim.cube sizeY [5^.5*.5+.5]");
lx("tool.attr prim.cube sizeX 0.0");
lx("tool.attr prim.cube sizeZ [5^.5*.5+1.5]");
lx("tool.apply");
lx("tool.attr prim.cube sizeX [5^.5*.5+1.5]");
lx("tool.attr prim.cube sizeY 1.0");
lx("tool.attr prim.cube sizeZ 0.0");
lx("tool.apply");
lx("tool.attr prim.cube sizeY 0.0");
lx("tool.attr prim.cube sizeZ [5^.5*.5+.5]");
lx("tool.apply");
lx("tool.attr prim.cube sizeX [5^.5*.5+.5]");
lx("tool.attr prim.cube sizeY [5^.5*.5+.5]");
lx("tool.attr prim.cube sizeZ [5^.5*.5+.5]");
lx("tool.apply");
lx("tool.set prim.cube off 0");
lx("select.drop vertex");
lx("select.invert");
lx("select.copy");
lx("delete");
lx("select.paste");
#0
lx("select.element $layerindex vertex add 14");
lx("select.element $layerindex vertex add 6");
lx("select.element $layerindex vertex add 1");
lx("select.element $layerindex vertex add 31");
lx("poly.make face");
#1
lx("select.element $layerindex vertex add 2");
lx("select.element $layerindex vertex add 7");
lx("select.element $layerindex vertex add 1");
lx("select.element $layerindex vertex add 6");
lx("poly.make face");
#2
lx("select.element $layerindex vertex add 15");
lx("select.element $layerindex vertex add 28");
lx("select.element $layerindex vertex add 1");
lx("select.element $layerindex vertex add 7");
lx("poly.make face");
#3
lx("select.element $layerindex vertex add 2");
lx("select.element $layerindex vertex add 6");
lx("select.element $layerindex vertex add 14");
lx("select.element $layerindex vertex add 30");
lx("poly.make face");
#4
lx("select.element $layerindex vertex add 22");
lx("select.element $layerindex vertex add 30");
lx("select.element $layerindex vertex add 14");
lx("select.element $layerindex vertex add 10");
lx("poly.make face");
#5
lx("select.element $layerindex vertex add 13");
lx("select.element $layerindex vertex add 10");
lx("select.element $layerindex vertex add 14");
lx("select.element $layerindex vertex add 11");
lx("poly.make face");
#6
lx("select.element $layerindex vertex add 22");
lx("select.element $layerindex vertex add 18");
lx("select.element $layerindex vertex add 2");
lx("select.element $layerindex vertex add 30");
lx("poly.make face");
#7
lx("select.element $layerindex vertex add 21");
lx("select.element $layerindex vertex add 29");
lx("select.element $layerindex vertex add 2");
lx("select.element $layerindex vertex add 18");
lx("poly.make face");
#8
lx("select.element $layerindex vertex add 15");
lx("select.element $layerindex vertex add 7");
lx("select.element $layerindex vertex add 2");
lx("select.element $layerindex vertex add 29");
lx("poly.make face");
#9
lx("select.element $layerindex vertex add 21");
lx("select.element $layerindex vertex add 18");
lx("select.element $layerindex vertex add 22");
lx("select.element $layerindex vertex add 19");
lx("poly.make face");
#10
lx("select.element $layerindex vertex add 3");
lx("select.element $layerindex vertex add 19");
lx("select.element $layerindex vertex add 22");
lx("select.element $layerindex vertex add 26");
lx("poly.make face");
#11
lx("select.element $layerindex vertex add 22");
lx("select.element $layerindex vertex add 10");
lx("select.element $layerindex vertex add 13");
lx("select.element $layerindex vertex add 26");
lx("poly.make face");
#12
lx("select.element $layerindex vertex add 3");
lx("select.element $layerindex vertex add 25");
lx("select.element $layerindex vertex add 21");
lx("select.element $layerindex vertex add 19");
lx("poly.make face");
#13
lx("select.element $layerindex vertex add 12");
lx("select.element $layerindex vertex add 9");
lx("select.element $layerindex vertex add 21");
lx("select.element $layerindex vertex add 25");
lx("poly.make face");
#14
lx("select.element $layerindex vertex add 21");
lx("select.element $layerindex vertex add 9");
lx("select.element $layerindex vertex add 15");
lx("select.element $layerindex vertex add 29");
lx("poly.make face");
#15
lx("select.element $layerindex vertex add 3");
lx("select.element $layerindex vertex add 4");
lx("select.element $layerindex vertex add 12");
lx("select.element $layerindex vertex add 25");
lx("poly.make face");
#16
lx("select.element $layerindex vertex add 3");
lx("select.element $layerindex vertex add 5");
lx("select.element $layerindex vertex add 0");
lx("select.element $layerindex vertex add 4");
lx("poly.make face");
#17
lx("select.element $layerindex vertex add 13");
lx("select.element $layerindex vertex add 5");
lx("select.element $layerindex vertex add 3");
lx("select.element $layerindex vertex add 26");
lx("poly.make face");
#18
lx("select.element $layerindex vertex add 12");
lx("select.element $layerindex vertex add 4");
lx("select.element $layerindex vertex add 0");
lx("select.element $layerindex vertex add 24");
lx("poly.make face");
#19
lx("select.element $layerindex vertex add 20");
lx("select.element $layerindex vertex add 8");
lx("select.element $layerindex vertex add 12");
lx("select.element $layerindex vertex add 24");
lx("poly.make face");
#20
lx("select.element $layerindex vertex add 12");
lx("select.element $layerindex vertex add 8");
lx("select.element $layerindex vertex add 15");
lx("select.element $layerindex vertex add 9");
lx("poly.make face");
#21
lx("select.element $layerindex vertex add 0");
lx("select.element $layerindex vertex add 16");
lx("select.element $layerindex vertex add 20");
lx("select.element $layerindex vertex add 24");
lx("poly.make face");
#22
lx("select.element $layerindex vertex add 23");
lx("select.element $layerindex vertex add 16");
lx("select.element $layerindex vertex add 0");
lx("select.element $layerindex vertex add 27");
lx("poly.make face");
#23
lx("select.element $layerindex vertex add 0");
lx("select.element $layerindex vertex add 5");
lx("select.element $layerindex vertex add 13");
lx("select.element $layerindex vertex add 27");
lx("poly.make face");
#24
lx("select.element $layerindex vertex add 20");
lx("select.element $layerindex vertex add 16");
lx("select.element $layerindex vertex add 23");
lx("select.element $layerindex vertex add 17");
lx("poly.make face");
#25
lx("select.element $layerindex vertex add 20");
lx("select.element $layerindex vertex add 17");
lx("select.element $layerindex vertex add 1");
lx("select.element $layerindex vertex add 28");
lx("poly.make face");
#26
lx("select.element $layerindex vertex add 20");
lx("select.element $layerindex vertex add 28");
lx("select.element $layerindex vertex add 15");
lx("select.element $layerindex vertex add 8");
lx("poly.make face");
#27
lx("select.element $layerindex vertex add 23");
lx("select.element $layerindex vertex add 31");
lx("select.element $layerindex vertex add 1");
lx("select.element $layerindex vertex add 17");
lx("poly.make face");
#28
lx("select.element $layerindex vertex add 23");
lx("select.element $layerindex vertex add 11");
lx("select.element $layerindex vertex add 14");
lx("select.element $layerindex vertex add 31");
lx("poly.make face");
#29
lx("select.element $layerindex vertex add 13");
lx("select.element $layerindex vertex add 11");
lx("select.element $layerindex vertex add 23");
lx("select.element $layerindex vertex add 27");
lx("poly.make face");
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
lx("select.drop polygon");
if(!$square)
{
 @{$polygon{0}} = (31,6,14,1);
 @{$polygon{1}} = (6,7,2,1);
 @{$polygon{2}} = (7,28,15,1);
 @{$polygon{3}} = (6,30,14,2);
 @{$polygon{4}} = (30,10,14,22);
 @{$polygon{5}} = (10,11,14,13);
 @{$polygon{6}} = (30,18,22,2);
 @{$polygon{7}} = (18,29,21,2);
 @{$polygon{8}} = (29,7,15,2);
 @{$polygon{9}} = (18,19,22,21);
 @{$polygon{10}} = (19,26,22,3);
 @{$polygon{11}} = (26,10,22,13);
 @{$polygon{12}} = (19,25,3,21);
 @{$polygon{13}} = (25,9,12,21);
 @{$polygon{14}} = (9,29,15,21);
 @{$polygon{15}} = (25,4,3,12);
 @{$polygon{16}} = (4,5,3,0);
 @{$polygon{17}} = (5,26,3,13);
 @{$polygon{18}} = (4,24,0,12);
 @{$polygon{19}} = (24,8,20,12);
 @{$polygon{20}} = (8,9,15,12);
 @{$polygon{21}} = (24,16,0,20);
 @{$polygon{22}} = (16,27,0,23);
 @{$polygon{23}} = (27,5,0,13);
 @{$polygon{24}} = (16,17,23,20);
 @{$polygon{25}} = (17,28,1,20);
 @{$polygon{26}} = (28,8,15,20);
 @{$polygon{27}} = (17,31,23,1);
 @{$polygon{28}} = (31,11,23,14);
 @{$polygon{29}} = (11,27,23,13);
 lx("select.vertexMap {Texture} txuv replace");
 lx("select.drop vertex");
 if($type1)
 {
  $uvalue = $fold;
  $vvalue = -0.5;
  lxout("$uvalue $vvalue");
  for($i = 0; $i < 30; $i ++)
  {
   @verts = @{$polygon{$i}};
   $uvalue = -$uvalue;
   lx("select.element $layerindex vertex set index:$verts[0] index3:$i");
   lx("vertMap.setValue type:$texture_type comp:0 value:$uvalue");
   lx("vertMap.setValue type:$texture_type comp:1 value:0");
   $uvalue = -$uvalue;
   lx("select.element $layerindex vertex set index:$verts[1] index3:$i");
   lx("vertMap.setValue type:$texture_type comp:0 value:$uvalue");
   lx("vertMap.setValue type:$texture_type comp:1 value:0");
   $vvalue = -$vvalue;
   lx("select.element $layerindex vertex set index:$verts[2] index3:$i");
   lx("vertMap.setValue type:$texture_type comp:0 value:0");
   lx("vertMap.setValue type:$texture_type comp:1 value:$vvalue");
   $vvalue = -$vvalue;
   lx("select.element $layerindex vertex set index:$verts[3] index3:$i");
   lx("vertMap.setValue type:$texture_type comp:0 value:0");
   lx("vertMap.setValue type:$texture_type comp:1 value:$vvalue");
  }
 }
 else
 {
  $uvalue = -$fold;
  $vvalue = 0.5;
  lxout("$uvalue $vvalue");
  for($i = 0; $i < 30; $i ++)
  {
   @verts = @{$polygon{$i}};
   $uvalue = -$uvalue;
   lx("select.element $layerindex vertex set index:$verts[2] index3:$i");
   lx("vertMap.setValue type:$texture_type comp:0 value:$uvalue");
   lx("vertMap.setValue type:$texture_type comp:1 value:0");
   $uvalue = -$uvalue;
   lx("select.element $layerindex vertex set index:$verts[3] index3:$i");
   lx("vertMap.setValue type:$texture_type comp:0 value:$uvalue");
   lx("vertMap.setValue type:$texture_type comp:1 value:0");
   $vvalue = -$vvalue;
   lx("select.element $layerindex vertex set index:$verts[0] index3:$i");
   lx("vertMap.setValue type:$texture_type comp:0 value:0");
   lx("vertMap.setValue type:$texture_type comp:1 value:$vvalue");
   $vvalue = -$vvalue;
   lx("select.element $layerindex vertex set index:$verts[1] index3:$i");
   lx("vertMap.setValue type:$texture_type comp:0 value:0");
   lx("vertMap.setValue type:$texture_type comp:1 value:$vvalue");
  }
 }
 lx("select.drop vertex");
}
lx("uv.pack true false false auto 0.2 false");
lx("select.type edge");
lx("select.element $layerindex edge add 1 6 1");
lx("uv.sewMove select 1");
lx("select.element $layerindex edge add 1 7 1");
lx("uv.sewMove select 1");
lx("select.element $layerindex edge add 6 2 1");
lx("uv.sewMove select 1");
lx("select.element $layerindex edge add 30 14 3");
lx("uv.sewMove select 1");
lx("select.element $layerindex edge add 10 14 4");
lx("uv.sewMove select 1");
lx("select.element $layerindex edge add 22 30 4");
lx("uv.sewMove select 1");
lx("select.element $layerindex edge add 18 2 6");
lx("uv.sewMove select 1");
lx("select.element $layerindex edge add 2 29 7");
lx("uv.sewMove select 1");
lx("select.element $layerindex edge add 21 18 7");
lx("uv.sewMove select 1");
lx("select.element $layerindex edge add 19 22 9");
lx("uv.sewMove select 1");
lx("select.element $layerindex edge add 26 22 10");
lx("uv.sewMove select 1");
lx("select.element $layerindex edge add 3 19 10");
lx("uv.sewMove select 1");
lx("select.element $layerindex edge add 25 21 12");
lx("uv.sewMove select 1");
lx("select.element $layerindex edge add 9 21 13");
lx("uv.sewMove select 1");
lx("select.element $layerindex edge add 25 12 13");
lx("uv.sewMove select 1");
lx("select.element $layerindex edge add 4 3 15");
lx("uv.sewMove select 1");
lx("select.element $layerindex edge add 3 5 16");
lx("uv.sewMove select 1");
lx("select.element $layerindex edge add 4 0 16");
lx("uv.sewMove select 1");
lx("select.element $layerindex edge add 12 24 18");
lx("uv.sewMove select 1");
lx("select.element $layerindex edge add 8 12 19");
lx("uv.sewMove select 1");
lx("select.element $layerindex edge add 20 24 19");
lx("uv.sewMove select 1");
lx("select.element $layerindex edge add 0 16 21");
lx("uv.sewMove select 1");
lx("select.element $layerindex edge add 0 27 22");
lx("uv.sewMove select 1");
lx("select.element $layerindex edge add 16 23 22");
lx("uv.sewMove select 1");
lx("select.element $layerindex edge add 17 20 24");
lx("uv.sewMove select 1");
lx("select.element $layerindex edge add 28 20 25");
lx("uv.sewMove select 1");
lx("select.element $layerindex edge add 17 1 25");
lx("uv.sewMove select 1");
lx("select.element $layerindex edge add 31 23 27");
lx("uv.sewMove select 1");
lx("select.element $layerindex edge add 23 11 28");
lx("uv.sewMove select 1");
if($fold1 && !$square && !$type1)
{
 lx("select.element $layerindex edge add 4 12 15");
 lx("uv.sewMove select 1");
}
lx("uv.fit false true");
lx("select.drop polygon");
lx("tool.set actr.auto on");
lx("tool.attr center.auto cenX 0.0");
lx("tool.attr center.auto cenY 0.0");
lx("tool.attr center.auto cenZ 0.0");
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
lx("tool.set TransformMove off");
lx("select.drop vertex");
lx("tool.set TransformScale on");
lx("tool.viewType xyz");
lx("tool.reset");
lx("tool.attr xfrm.transform SX $S");
lx("tool.attr xfrm.transform SY $S");
lx("tool.attr xfrm.transform SZ $S");
lx("tool.doApply");
lx("tool.set TransformScale off");
lx("tool.set actr.auto off");
lx("pref.value units.system $units");