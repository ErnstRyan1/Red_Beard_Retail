#perl
#freeze instances
#AUTHOR : Seneca Menard
#This script will look at what you have selected and freeze all of the childrens' instance geometry into it.  if what you have selected isn't a mesh, it'll place the frozen geometry into a new layer.


#record layer visibility
my $mainlayer = lxq("query layerservice layers ? main");
my @fgLayers = lxq("query layerservice layers ? fg");
my @bgLayers = lxq("query layerservice layers ? bg");



my @items = lxq("query sceneservice selection ? locator");
foreach my $item (@items){
	if (lxq("query sceneservice item.type ? $item") eq "mesh"){
		our $pasteLayer = $item;
	}

	#find all the children instances
	my @children = lxq("query sceneservice item.children ? $item");
	my @instances;
	foreach my $child (@children){
		if (lxq("query sceneservice item.type ? $child") eq "meshInst"){
			my $id = lxq("query sceneservice item.id ? $child");
			push(@instances,$id);
		}
	}

	#select all the children instances and convert 'em.
	if (@instances > 0){
		lx("select.drop item");
		foreach my $id (@instances){lx("select.subItem [$id] add mesh;meshInst;camera;light;txtrLocator;backdrop;groupLocator [0] [1]");}
		lx("item.setType Mesh");

		#cut/paste the geometry into the layer
		lx("select.type polygon");
		lx("select.cut");
		lx("select.type item");
		lx("delete");
		if ($pasteLayer ne "")	{lx("select.subItem [$pasteLayer] set mesh;meshInst;camera;light;txtrLocator;backdrop;groupLocator [0] [1]");}
		else					{lx("layer.newItem mesh");}
		lx("select.paste");
	}
}



#restore layer visibility
my $mainlayerID = lxq("query layerservice layer.id ? $mainlayer");
lx("select.subItem [$mainlayerID] set mesh;meshInst;camera;light;txtrLocator;backdrop;groupLocator [0] [1]");

foreach my $layer (@fgLayers){
	my $id = lxq("query layerservice layer.id ? $layer");
	lx("select.subItem [$id] add mesh;meshInst;camera;light;txtrLocator;backdrop;groupLocator [0] [1]");
}
foreach my $layer (@bgLayers){
	my $id = lxq("query layerservice layer.id ? $layer");
	lx("layer.setVisibility [$id] [1] [1]");
}