#!perl
#
#@RhombicDodecahedron.pl (arguments)
#
#--------------------------------------
#A Script By Allan Kiipli (c) 2010 2012
#--------------------------------------
#
#Draws Rhombic Dodecahedron around cube in phi height
#It adds peak vertexes, and joins verts into polygons.
#Then it lays out uv-s.
#Add 'fold' to constrain rhombs to fit honeycomb pattern.
#This means equal measures across edges and diagonal.
#Else it constrains to measures of face itself.
#When 'square' is used, faces lay out as squares,
#and connect into stripe. When 'type1' is used,
#the rhomb stretch is inverted. Polygons are
#sorted by index in order to lay out logic uv-s.
#--- updated vertmap moves to Modo v 501

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

$fold = sqrt((0.5)**2+(0.5)**2);
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

lx("item.name {rhombic dodecahedron}");

$mainLayer = lxq("query layerservice layers ? main");

lxout("mainLayer $mainLayer");

$layerindex = lxq("query layerservice layer.index ? $mainLayer");

lxout("layerindex $layerindex");

$units = lxq("pref.value {units.system} ?");

lx("pref.value units.system si");

lxout("units $units");

lx("vertMap.new {Texture} txuv");

$selectedVmap = lxq("query layerservice vmaps ? selected");

lxout("selectedVmap $selectedVmap");

$vmapName = lxq("query layerservice vmap.name ? $selectedVmap");

lxout("vmapName $vmapName");
lx("select.symmetryState none");
lx("tool.set prim.cube on");
lx("tool.reset prim.cube");
lx("tool.attr prim.cube sizeX [5^.5*.5+.5]");
lx("tool.attr prim.cube sizeY [5^.5*.5+.5]");
lx("tool.attr prim.cube sizeZ [5^.5*.5+.5]");
lx("tool.apply");
lx("tool.set prim.cube off");
lx("vert.new 0.0 [(5^.5*.5+.5)] 0.0");
lx("vert.new 0.0 [-(5^.5*.5+.5)] 0.0");
lx("vert.new [(5^.5*.5+.5)] 0.0 0.0");
lx("vert.new [-(5^.5*.5+.5)] 0.0 0.0");
lx("vert.new 0.0 0.0 [(5^.5*.5+.5)]");
lx("vert.new 0.0 0.0 [-(5^.5*.5+.5)]");
lx("select.type vertex");
lx("select.invert");
lx("select.copy");
lx("select.delete");
lx("select.paste");
#0
lx("select.element $layerindex vertex add 13");
lx("select.element $layerindex vertex add 5");
lx("select.element $layerindex vertex add 10");
lx("select.element $layerindex vertex add 1");
lx("poly.make face");
#1
lx("select.element $layerindex vertex add 13");
lx("select.element $layerindex vertex add 1");
lx("select.element $layerindex vertex add 9");
lx("select.element $layerindex vertex add 0");
lx("poly.make face");
#2
lx("select.element $layerindex vertex add 10");
lx("select.element $layerindex vertex add 2");
lx("select.element $layerindex vertex add 9");
lx("select.element $layerindex vertex add 1");
lx("poly.make face");
#3
lx("select.element $layerindex vertex add 10");
lx("select.element $layerindex vertex add 6");
lx("select.element $layerindex vertex add 12");
lx("select.element $layerindex vertex add 2");
lx("poly.make face");
#4
lx("select.element $layerindex vertex add 12");
lx("select.element $layerindex vertex add 3");
lx("select.element $layerindex vertex add 9");
lx("select.element $layerindex vertex add 2");
lx("poly.make face");
#5
lx("select.element $layerindex vertex add 11");
lx("select.element $layerindex vertex add 0");
lx("select.element $layerindex vertex add 9");
lx("select.element $layerindex vertex add 3");
lx("poly.make face");
#6
lx("select.element $layerindex vertex add 12");
lx("select.element $layerindex vertex add 7");
lx("select.element $layerindex vertex add 11");
lx("select.element $layerindex vertex add 3");
lx("poly.make face");
#7
lx("select.element $layerindex vertex add 12");
lx("select.element $layerindex vertex add 6");
lx("select.element $layerindex vertex add 8");
lx("select.element $layerindex vertex add 7");
lx("poly.make face");
#8
lx("select.element $layerindex vertex add 11");
lx("select.element $layerindex vertex add 7");
lx("select.element $layerindex vertex add 8");
lx("select.element $layerindex vertex add 4");
lx("poly.make face");
#9
lx("select.element $layerindex vertex add 11");
lx("select.element $layerindex vertex add 4");
lx("select.element $layerindex vertex add 13");
lx("select.element $layerindex vertex add 0");
lx("poly.make face");
#10
lx("select.element $layerindex vertex add 13");
lx("select.element $layerindex vertex add 4");
lx("select.element $layerindex vertex add 8");
lx("select.element $layerindex vertex add 5");
lx("poly.make face");
#11
lx("select.element $layerindex vertex add 10");
lx("select.element $layerindex vertex add 5");
lx("select.element $layerindex vertex add 8");
lx("select.element $layerindex vertex add 6");
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
 @{$polygon{0}} = (5,1,10,13);
 @{$polygon{1}} = (0,1,13,9);
 @{$polygon{2}} = (1,2,10,9);
 @{$polygon{3}} = (2,6,10,12);
 @{$polygon{4}} = (2,3,12,9);
 @{$polygon{5}} = (0,3,9,11);
 @{$polygon{6}} = (3,7,12,11);
 @{$polygon{7}} = (7,6,12,8);
 @{$polygon{8}} = (7,4,8,11);
 @{$polygon{9}} = (4,0,13,11);
 @{$polygon{10}} = (4,5,8,13);
 @{$polygon{11}} = (5,6,8,10);
 lx("select.vertexMap {Texture} txuv replace");
 lx("select.drop vertex");
 if($type1)
 {
  $uvalue = -0.5;
  $vvalue = $fold;
  lxout("$uvalue $vvalue");
  for($i = 0; $i < 12; $i ++)
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
 else
 {
  $uvalue = -$fold;
  $vvalue = 0.5;
  lxout("$uvalue $vvalue");
  for($i = 0; $i < 12; $i ++)
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
lx("select.drop polygon");
lx("select.type edge");
lx("select.element $layerindex edge add 1 13 1");
lx("uv.sewMove select 1");
lx("select.element $layerindex edge add 1 9 1");
lx("uv.sewMove select 1");
lx("select.element $layerindex edge add 10 2 2");
lx("uv.sewMove select 1");
lx("select.element $layerindex edge add 12 2 3");
lx("uv.sewMove select 1");
lx("select.element $layerindex edge add 3 9 4");
lx("uv.sewMove select 1");
lx("select.element $layerindex edge add 3 11 5");
lx("uv.sewMove select 1");
lx("select.element $layerindex edge add 7 12 6");
lx("uv.sewMove select 1");
lx("select.element $layerindex edge add 8 7 7");
lx("uv.sewMove select 1");
lx("select.element $layerindex edge add 4 11 8");
lx("uv.sewMove select 1");
lx("select.element $layerindex edge add 4 13 9");
lx("uv.sewMove select 1");
lx("select.element $layerindex edge add 8 5 10");
lx("uv.sewMove select 1");
if($fold1 && !$square && !$type1)
{
 lx("select.element $layerindex edge add 3 12 4");
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