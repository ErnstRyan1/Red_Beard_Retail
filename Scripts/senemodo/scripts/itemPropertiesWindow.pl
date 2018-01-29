#perl
#ver 0.5
#author : Seneca Menard

#This script is to be fired when loading up the properties window.  It will do the following things beforehand :
# 1 - if any lights are selected, it will select the light materials as well.



my @lightSelection = lxq("query sceneservice selection ? light");
my @lightMaterialSelection = lxq("query sceneservice selection ? lightMaterial");

#deselect any preselected light materials
if ((@lightSelection  > 0) && (@lightMaterialSelection > 0)){
	lx("select.subItem {$_} remove textureLayer;render;environment;light;camera;mediaClip;txtrLocator") for @lightMaterialSelection;
}

#select the new light materials
for (my $i=0; $i<@lightSelection; $i++){
	my @children = lxq("query sceneservice item.children ? {$lightSelection[$i]}");
	lx("select.subItem {$_} add textureLayer;render;environment;light;camera;mediaClip;txtrLocator") for @children;
}

#force a light to be selected last again in order to have the right tab show up when i spawn the window.
if (@lightSelection > 0){
	lx("select.subItem {$lightSelection[0]} remove textureLayer;render;environment;light;camera;mediaClip;txtrLocator");
	lx("select.subItem {$lightSelection[0]} add textureLayer;render;environment;light;camera;mediaClip;txtrLocator");
}
lx("attr.formPopover {itemprops:general}");