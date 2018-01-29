#perl
#COLLAPSE LAYERS
#AUTHOR: Seneca Menard
#version 1.25
#This script will copy all the current scene's geometry into layer 1 and then delete all the other layers.
#(1-22-09 feature) : The script now has a "selected" argument so that it only collapses the layers that are currently selected

#SCRIPT ARGUMENTS :
# selected : this script argument will collapse only the selected layers.

my $mainlayer = lxq("query layerservice layers ? main");
my $mainlayerID = lxq("query layerservice layer.id ? $mainlayer");
my @bgLayers = lxq("query layerservice layers ? bg");
for (my $i=0; $i<@bgLayers; $i++){
	my $id = lxq("query layerservice layer.id ? @bgLayers[$i]");
	@bgLayers[$i] = $id;
}
if (@ARGV[0] eq "selected"){
	lxout("collapsing selected layers");
	our @layers = lxq("query layerservice layers ? fg");
	shift(@layers);
}else{
	lxout("collapsing all layers");
	our @layers = lxq("query layerservice layers ? all");
	for (my $i=0; $i<@layers; $i++){
		if (@layers[$i] == $mainlayer){
			splice(@layers, $i, 1);
			last;
		}
	}
}
my @layerIDList;
lx("select.drop polygon");


#COPY TO LAYER 1
for (my $i=0; $i<@layers; $i++){
	my $layerID = lxq("query layerservice layer.id ? @layers[$i]");
	push(@layerIDList,$layerID);
	lx("select.subItem [$layerID] set mesh;meshInst;camera;light;txtrLocator;backdrop;groupLocator [0] [1]");
	lx("select.invert");
	if (lxq("select.count polygon ?") > 0){
		lx("select.copy");
		lx("select.subItem [$mainlayerID] set mesh;meshInst;camera;light;txtrLocator;backdrop;groupLocator [0] [1]");
		lx("select.paste");
	}
}

#DELETE ALL THE LAYERS
lx("select.drop item");
foreach my $layerID (@layerIDList){
	lx("select.subItem [$layerID] add mesh;meshInst;camera;light;txtrLocator;backdrop;groupLocator [0] [1]");
}
lx("layer.deleteSelected");
lx("select.type polygon");

#MAKE SURE THE NEW LAYER IS SELECTED
if (@ARGV[0] eq "selected"){
	lx("select.subItem {$mainlayerID} set mesh;meshInst;camera;light;backdrop;groupLocator;locator;deform;locdeform 0 0");
	foreach my $id (@bgLayers){lx("layer.setVisibility {$id} 1");}
}

my $count = $#layerIDList+1;
lxout("There were ($count) layers to be copied to layer 1 and then deleted.");
