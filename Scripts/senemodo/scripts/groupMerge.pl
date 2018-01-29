#perl
#ver 1.0
#author : Seneca Menard

#This script is to transfer the children of the first selected group(s) to the last selected group and then delete the first groups.

my @fgLayers = lxq("query layerservice layers ? fg");
for (my $i=0; $i<@fgLayers; $i++){@fgLayers[$i] = lxq("query layerservice layer.id ? @fgLayers[$i]");}

my @groups = lxq("query sceneservice selection ? groupLocator");
if (@groups > 1){
	lx("select.drop item");

	for (my $i=0; $i<$#groups; $i++){
		my @children = lxq("query sceneservice item.children ? {@groups[$i]}");
		lx("item.parent item:{$_} parent:{$groups[-1]}") for @children;
	}

	for (my $i=0; $i<$#groups; $i++){lx("select.subItem {$groups[$i]} add mesh;triSurf;meshInst;camera;light;txtrLocator;backdrop;groupLocator;replicator;locator;deform;locdeform;chanModify;chanEffect 0 0");}
	lx("item.delete mask:groupLocator");

	lx("select.subItem {$_} add mesh;triSurf;meshInst;camera;light;txtrLocator;backdrop;groupLocator;replicator;locator;deform;locdeform;chanModify;chanEffect 0 0") for @fgLayers;

}else{
	die("You don't have more than 2 groupLocators selected, so I can't move the children from from the selected groupLocators to the last selected groupLocator");
}
