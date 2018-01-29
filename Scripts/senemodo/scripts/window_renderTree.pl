#perl
#BY: Seneca Menard
#version 1.01
#This script is to open up the render window and select the material on the last selected element.

#(2-10-15 fix) : fixed a possible syntax error with queries and reference items.

#----------------------------------------------------------
#setup for each element
#----------------------------------------------------------
my $mainlayer = lxq("query layerservice layers ? main");
if( lxq( "select.typeFrom {vertex;edge;polygon;item} ?" ) ){
	my @verts = lxq("query layerservice verts ? selected");
	our @polys = lxq("query layerservice vert.polyList ? @verts[-1]");
}
elsif( lxq( "select.typeFrom {edge;polygon;item;vertex} ?" ) ){
	my @edges = lxq("query layerservice edges ? selected");
	our @polys = lxq("query layerservice edge.polyList ? @edges[-1]");
}
elsif( lxq( "select.typeFrom {polygon;item;vertex;edge} ?" ) ){
	our @polys = lxq("query layerservice polys ? selected");
}
elsif( lxq( "select.typeFrom {ptag;polygon;item;vertex;edge} ?" ) ){
	lx("select.convert polygon");
	our @polys = lxq("query layerservice polys ? selected");
	lx("select.type ptag");
}
else{
	our @polys = lxq("query layerservice polys ? all");
}
my $material = lxq("query layerservice poly.material ? @polys[-1]");


#----------------------------------------------------------
#try to load the material window up
#----------------------------------------------------------
my $layoutCount1 = lxq("layout.count ?");
lx("layout.createOrClose 8 seneRenderSettings x:[0] y:[30] width:[800] height:[1370]");
my $layoutCount2 = lxq("layout.count ?");


#----------------------------------------------------------
#determine whether or not to select the material
#----------------------------------------------------------
if ($layoutCount2 > $layoutCount1){
	#find the group that has the material I want.
	my $txLayers = lxq("query sceneservice txLayer.n ?");
	my $groupID;
	for (my $i=0; $i<$txLayers; $i++){
		if (lxq("query sceneservice txLayer.type ? $i") eq "mask"){
			if (lxq("query sceneservice channel.value ? ptag") eq $material){
				$groupID = lxq("query sceneservice txLayer.id ? $i");
			}
		}
	}

	#find the material in that group
	my $materialChild;
	my @children = lxq("query sceneservice txLayer.children ? {$groupID}");
	foreach my $child (@children){
		my $name = lxq("query sceneservice txLayer.name ? {$child}");
		my $type = lxq("query sceneservice txLayer.type ? {$child}");
		lxout("layer ($name) = ($type)");

		if ($type eq "advancedMaterial"){
			$materialChild = $child;
			last;
		}
	}

	#if there was no group found, select the base material instead
	if ($materialChild eq ""){
		for (my $i=0; $i<$txLayers; $i++){
			my $type = lxq("query sceneservice txLayer.type ? $i");
			if ($type eq "advancedMaterial"){
				$materialChild = lxq("query sceneservice txLayer.id ? $i");
				last;
			}
		}
	}

	#select the material
	lx("select.subItem {$materialChild} set textureLayer;render;environment;light;mediaClip;txtrLocator");
}










sub popup #(MODO2 FIX)
{
	lx("dialog.setup yesNo");
	lx("dialog.msg {@_}");
	lx("dialog.open");
	my $confirm = lxq("dialog.result ?");
	if($confirm eq "no"){die;}
}
