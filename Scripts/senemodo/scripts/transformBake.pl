#perl
#TEMP!

my $mainlayer = lxq("query layerservice layers ? main");
my @fgLayers = lxq("query layerservice layers ? fg");
my @bgLayers = lxq("query layerservice layers ? bg");
my $itemCount = lxq("query sceneservice item.n ?");



for (my $i=0; $i<$itemCount; $i++){
	lxq("query sceneservice item.isSelected ? $i");
	my $name = lxq("query sceneservice item.name ? $i");
	my $type = lxq("query sceneservice item.type ? $i");

	if ( ($type eq "mesh") || ($type eq "groupLocator") ){
		my @children = lxq("query sceneservice item.children ? $i");
		if ($#children != -1){
			popup("this item ($i) is a ($type) and has ($#children+1) children");

			#now memorize and reset the translations for this item.
			my $id = lxq("query sceneservice item.id ? $i");
			lx("select.subItem [$id] set mesh;meshInst;camera;light;txtrLocator;backdrop;groupLocator [0] [1]");
			my @pos = lxq("query sceneservice item.pos ? $id");
			my @rot = lxq("query sceneservice item.rot ? $id");
			my @scale = lxq("query sceneservice item.scale ? $id");
			lx("item.transformReset");

			foreach my $child (@children){
				lx("select.subItem [$child] set mesh;meshInst;camera;light;txtrLocator;backdrop;groupLocator [0] [1]");

				lx("item.channel locator\$pos.X {@pos[0]}");
				lx("item.channel locator\$pos.Y {@pos[1]}");
				lx("item.channel locator\$pos.Z {@pos[2]}");

				lx("item.channel locator\$rot.X {@rot[0]}");
				lx("item.channel locator\$rot.Y {@rot[1]}");
				lx("item.channel locator\$rot.Z {@rot[2]}");

				lx("item.channel locator\$scl.X {@scale[0]}");
				lx("item.channel locator\$scl.Y {@scale[1]}");
				lx("item.channel locator\$scl.Z {@scale[2]}");
			}
		}
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