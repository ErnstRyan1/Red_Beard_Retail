#!perl
#
#@VertexPlacer.pl
#
#---------------------------------------------
#A Script By Allan Kiipli (c) 23:37 27.10.2010
#---------------------------------------------
#
#Select two or more verts on main layer.
#Places vertex in geometric center.
#Handles unique coordinates and joins same
#coordinates to represent one vertex.
#If no verts are selected, at origin vert is placed.

$currentscene = lxq("query sceneservice scene.index ? current");

lxout("currentscene $currentscene");

$mainlayer = lxq("query layerservice layers ? main");

lxout("mainlayer $mainlayer");

$layerindex = lxq("query layerservice layer.index ? $mainlayer");

lxout("layerindex $layerindex");

lx("select.convert vertex");

@selectedVerts = lxq("query layerservice verts ? selected");

lxout("selectedVerts @selectedVerts");

if(!@selectedVerts)
{
 $vertPosx = 0;
 $vertPosy = 0;
 $vertPosz = 0;
 $unique = 1;
}

lx("select.drop vertex");

foreach $selectedVert(@selectedVerts)
{
 @vertPos = lxq("query layerservice vert.pos ? $selectedVert");
 $roundedx = int($vertPos[0]*1000);
 $roundedy = int($vertPos[1]*1000);
 $roundedz = int($vertPos[2]*1000);
 if(!$unique{"$roundedx $roundedy $roundedz"})
 {
  $unique{"$roundedx $roundedy $roundedz"} = 1;
  $vertPosx += $vertPos[0];
  $vertPosy += $vertPos[1];
  $vertPosz += $vertPos[2];
  $unique ++;
 }
}

$vertPosx /= $unique;
$vertPosy /= $unique;
$vertPosz /= $unique;

lx("tool.set prim.makeVertex on 0");
lx("tool.reset prim.makeVertex");
lx("tool.attr prim.makeVertex cenX $vertPosx");
lx("tool.attr prim.makeVertex cenY $vertPosy");
lx("tool.attr prim.makeVertex cenZ $vertPosz");
lx("tool.apply");
lx("tool.set prim.makeVertex off");