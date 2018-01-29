#!perl
#
#@SplitVert.pl
#
#---------------------------------
#A Script By Allan Kiipli (c) 2012
#---------------------------------
#
#Now vertex selection is selected again after
#triangulation is made complete.
#
#Triangulate surrounding polys around
#selected vertexes.

sub triangulate($)
{
 $vert = shift(@_);
 lxout("vert $vert");
 @vertList = lxq("query layerservice vert.vertList ? $vert");
 lxout("vertList @vertList");
 @polyList = lxq("query layerservice vert.polyList ? $vert");
 lxout("polyList @polyList");
 @select = ();
 foreach $p(@polyList)
 {
  lxout("p $p");
  @polyverts = lxq("query layerservice poly.vertList ? $p");
  lxout("polyverts @polyverts");
  foreach $v(@polyverts)
  {
   if($v ne $vert)
   {
    if("@vertList" !~ /\b$v\b/)
    {
     push(@select, $v);
    }
   }
  }
 }
 foreach $v(@select)
 {
  lx("select.element $layerindex vertex set $vert");
  lx("select.element $layerindex vertex add $v");
  lx("poly.split");
  lxout("v $v");
 }
}

$currentscene = lxq("query sceneservice scene.index ? current");

lxout("currentscene $currentscene");

$mainlayer = lxq("query layerservice layer.index ? main");

lxout("mainlayer $mainlayer");

$layerindex = lxq("query layerservice layer.index ? $mainlayer");

lxout("layerindex $layerindex");

@selectedVerts = lxq("query layerservice verts ? selected");

lxout("selectedVerts @selectedVerts");

lx("select.symmetryState none");

lx("select.type vertex");

for($i = 0; $i < @selectedVerts; $i ++)
{
 lx("select.drop vertex");
 $selectedVert = $selectedVerts[$i];
 triangulate($selectedVert);
}

lx("select.drop vertex");

foreach $v(@selectedVerts)
{
 lx("select.element $layerindex vertex add $v");
}