#perl
#ver 0.5
#author : Seneca Menard
#This script will cut the polys from the "main" layer and paste them into a layer called "temp" and select the boundary edges.
#It's currently hardcoded for the layers and I need to fix that..


my $mainlayer = lxq("query layerservice layers ? main");
my $mainlayerName = lxq("query layerservice layer.name ? $mainlayer");

if ($mainlayerName eq "CJ2"){
	lx("select.type polygon");
	lx("select.connect");
	lx("select.cut");
	lx("select.subItem mesh003 set mesh;meshInst;camera;light;backdrop;groupLocator;locator;deform;locdeform 0 1");
	lx("select.paste");
	lx("select.drop edge");
	lx("select.boundary");
}else{
	lx("select.type polygon");
	lx("select.connect");
	lx("select.cut");
	lx("select.subItem mesh004 set mesh;meshInst;camera;light;backdrop;groupLocator;locator;deform;locdeform 0 1");
	lx("select.paste");
	lx("select.drop polygon");
	lx("select.boundary");
}

