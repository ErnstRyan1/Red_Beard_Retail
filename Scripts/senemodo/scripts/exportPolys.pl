#perl
#ver 1.2
#author : Seneca Menard
#This script is to export the selected polys to a new scene and triple them and delete all 1pt and 2pt polys as well.
#(11-2-10 fix) : fixed a syntax change for 501
#(3-25-11 fix) : 501 sp2 had an annoying syntax change.  grrr.

my $scene = lxq("query sceneservice scene.index ? current");
my $sceneFile = lxq("query sceneservice scene.file ? current");
my $modoVer = lxq("query platformservice appversion ?");
my $modoBuild = lxq("query platformservice appbuild ?");
if ($modoVer > 500){our $lwoType = "\$NLWO2";} else {our $lwoType = "\$LWO2";}
if ($modoBuild > 41320){our $selectPolygonArg = "psubdiv";}else{our $selectPolygonArg = "curve";}

my @fgLayers = lxq("query layerservice layers ? fg");
my $mainlayer = lxq("query layerservice layers ? main");
for (my $i=0; $i<@fgLayers; $i++){@fgLayers[$i] = lxq("query layerservice layer.id ? @fgLayers[$i]");}
#save the selection mode
if    (lxq( "select.typeFrom {vertex;edge;polygon;item} ?" ))	{our $selMode = "vertex";}
elsif (lxq( "select.typeFrom {edge;polygon;item;vertex} ?" ))	{our $selMode = "edge";}
elsif (lxq( "select.typeFrom {polygon;item;vertex;edge} ?" ))	{our $selMode = "polygon";}
elsif (lxq( "select.typeFrom {item;vertex;edge;polygon} ?" ))	{our $selMode = "item";}

#save the uv map.
my @vmaps =  lxq("query layerservice vmaps ? selected");

if (lxq("select.count polygon ?") > 0){
	lx("select.copy");
	lx("scene.new");
	lx("select.paste");
	lx("!!poly.triple");
	lx("select.polygon add vertex {$selectPolygonArg} 1");
	lx("select.polygon add vertex {$selectPolygonArg} 1");
	if (lxq("select.count polygon ?") > 0){	lx("delete");}
}

#save the scene
lx("dialog.setup fileSave");
lx("dialog.title [Export active layer(s)]");
lx("dialog.fileTypeCustom format:[slwo] username:[LWO] loadPattern:[*.lwo] saveExtension:[lwo]");
lx("dialog.open");
my $filename = lxq("dialog.result ?") or die("The file saver window was cancelled, so I'm cancelling the script.");
lx("scene.saveAs {$filename} {$lwoType} false");

lx("!!scene.close");


#===========================================================
#CLEANUP
#===========================================================
#now restore the original visibility and selection
for (my $i=0; $i<@fgLayers; $i++){
	if ($i == 0){
		lx("select.subItem {@fgLayers[$i]} set mesh;meshInst;camera;light;backdrop;groupLocator;locator;deform;locdeform 0 0");
	}else{
		lx("select.subItem {@fgLayers[$i]} add mesh;meshInst;camera;light;backdrop;groupLocator;locator;deform;locdeform 0 0");
	}
}

#now restore the selection mode and selected vmaps
lx("select.type $selMode");

foreach my $vmap (@vmaps){
	if (lxq("query layerservice vmap.type ? $vmap") eq "texture"){
		my $vmapName = lxq("query layerservice vmap.name ? $vmap");
		lx("select.vertexMap {$vmapName} txuv add");
	}
}
