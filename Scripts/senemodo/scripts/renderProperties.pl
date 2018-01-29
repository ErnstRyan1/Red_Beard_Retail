#perl
#BY: Seneca Menard
#version 1.2 (hushed warning)
#This script is to select the material on the poly under your mouse and popup a properties window so you can quickly edit it.
#If your mouse is not over a poly, I will select the render properties instead, so to quickly edit the render properties, just have your mouse anywhere on screen except over a poly when you fire the script. :P
#I can't find the properties form automatically because the generated form numbers are random. :(  To find the form you want to load, just open up the form
#editor and right click on the one you want and choose 'Assign to Key'.  That will give you the command you need.  You could also spawn a layout if you wanted as well.
#Here's two exmaples (which obviously won't work on your machine because forms are randomly numbered and you don't have my imaginary custom render properties layout installed.  :P  )
#"@renderProperties.pl attr.formPopover {49179859555:sheet}"
#"@renderProperties.pl layout.createOrClose cookie:[6] layout:[senRenderProps] title:[Custom Render Properties] x:[400] y:[400] width:[400] height:[400] persistent:[1]"

#(1-29-08 fix) : select.subitem is using the correct item id instead of the incorrect index
#(3-15-09 fix) : it now forces the mainlayer to be visible so it can find the material successfully.
#(3-31-09 bugfix) : found it's possible to have an active layer that's neither selected nor visible and put in a fix.
#(7-8-11 feature) : if you run the script without arguments, it'll pop up my form which is now included in the senemodokit

my $modoVer = lxq("query platformservice appversion ?");
my $mainlayer = lxq("query layerservice layers ? main");
my $mainlayerID = lxq("query layerservice layer.id ? $mainlayer");
if (lxq("query sceneservice item.isSelected ? $mainlayerID") == 0){lx("select.subItem {$mainlayerID} add mesh;triSurf;meshInst;camera;light;backdrop;groupLocator;replicator;locator;deform;locdeform;chanModify;chanEffect 0 0");}
my $txLayers = lxq("query sceneservice txLayer.n ?");
my $groupID;
my $id;
if ($modoVer < 300)	{our $renderName = "render_";}else{our $renderName = "polyRender";}

#remember selection type
if( lxq( "select.typeFrom {vertex;edge;polygon;item} ?" ) ) 		{	our $selType = "vertex";	}
elsif( lxq( "select.typeFrom {edge;polygon;item;vertex} ?" ) )		{	our $selType = "edge";		}
else																{	our $selType = "polygon";	}


#force mainlayer visibility
my @verifyMainlayerVisibilityList = verifyMainlayerVisibility();

#get the poly tags of the poly under the mouse.
lx("!!select.type item");
lx("!!select.3DElementUnderMouse set");
my $poly = lxq("query view3dservice element.over ? POLY");
$poly =~ s/[0-9]+,//;
my $currentlayer = lxq("query layerservice layers ? main");
lx("!!select.subItem [$mainlayerID] set mesh;meshInst;camera;light;txtrLocator;backdrop;groupLocator;locator;deform [0] [0]");
lx("!!select.type $selType");
my $material = lxq("query layerservice poly.material ? $poly");

#find the material in the shader tree
if (defined $poly){
	lxout("[->] Selecting the material");
	for (my $i=0; $i<$txLayers; $i++){
		if (lxq("query sceneservice txLayer.type ? $i") eq "mask"){
			if (lxq("query sceneservice channel.value ? ptag") eq $material){
				$groupID = lxq("query sceneservice txLayer.id ? $i");
				last;
			}
		}
	}

	my @children = lxq("query sceneservice txLayer.children ? $groupID");

	foreach my $child (@children){
		my $name = lxq("query sceneservice txLayer.name ? $child");
		my $type = lxq("query sceneservice txLayer.type ? $child");

		if ($type eq "advancedMaterial"){
			$id = $child;
			last;
		}
	}

	if ($id eq ""){
		lxout("The material you have selected isn't in a group");
		for (my $i=0; $i<$txLayers; $i++){
			if (lxq("query sceneservice txLayer.type ? $i") eq "advancedMaterial"){
				if (lxq("query sceneservice txLayer.parent ? $i") =~ /$renderName/i){
					lxout("I found this material instead because it's in no group so it's the 'Default 'material");
					$id = lxq("query sceneservice txLayer.id ? $i");
					last;
				}
			}
		}
	}
}
#else find the render options
else{
	lxout("[->] Selecting the render output");
	my $items = lxq("query sceneservice item.n ? all");
	for (my $i=0; $i<$items; $i++){
		if (lxq("query sceneservice item.type ? $i") eq "polyRender"){
			$id = lxq("query sceneservice item.id ? $i");
			last;
		}
	}
}

verifyMainlayerVisibility(\@verifyMainlayerVisibilityList);

#select the item and open the window
lx("select.subItem $id set textureLayer;render;environment;light;mediaClip;txtrLocator");
if (@ARGV == 0){
	lxout("[->] Popping up the form with the hardcoded id of this : {89726797053:sheet}");
	lx("layout.createOrClose cookie:[101] title:[render props mini] layout:[clear] style:[popoverRolloff]");
	lx("viewport.restore {} false attrform");
	lx("attr.viewExport {89726797053:sheet} set");
}else{
	lxout("[->] I'm opening the form that you typed in");
	lx("@ARGV");
}



sub popup #(MODO2 FIX)
{
	lx("dialog.setup yesNo");
	lx("dialog.msg {@_}");
	lx("dialog.open");
	my $confirm = lxq("dialog.result ?");
	if($confirm eq "no"){die;}
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#MAINLAYER VISIBILITY ASSURANCE SUBROUTINE (toggles vis of mainlayer and/or parents if any are hidden)
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
# USAGE : (requires mainlayerID)
# my @verifyMainlayerVisibilityList = verifyMainlayerVisibility();	#to collect hidden parents and show them
# verifyMainlayerVisibility(\@verifyMainlayerVisibilityList);		#to hide the hidden parents (and mainlayer) again.
sub verifyMainlayerVisibility{
	my @hiddenParents;

	#hide the items again.
	if (@_ > 0){
		foreach my $id (@{@_[0]}){
			#lxout("[->] : hiding $id");
			lx("layer.setVisibility {$id} 0");
		}
	}

	#show the mainlayer and all the mainlayer parents that are hidden (and retain a list for later use)
	else{
		if( lxq( "select.typeFrom {vertex;edge;polygon;item} ?" ) ){	our $tempSelMode = "vertex";	}
		if( lxq( "select.typeFrom {edge;polygon;item;vertex} ?" ) ){	our $tempSelMode = "edge";		}
		if( lxq( "select.typeFrom {polygon;item;vertex;edge} ?" ) ){	our $tempSelMode = "polygon";	}
		if( lxq( "select.typeFrom {item;vertex;edge;polygon} ?" ) ){	our $tempSelMode = "item";		}
		lx("select.type item");
		if (lxq("layer.setVisibility $mainlayerID ?") == 0){
			#lxout("[->] : showing $mainlayerID");
			lx("layer.setVisibility $mainlayerID 1");
			push(@hiddenParents,$mainlayerID);
		}
		lx("select.type $tempSelMode");

		my $parentFind = 1;
		my $currentID = $mainlayerID;
		while ($parentFind == 1){
			my $parent = lxq("query sceneservice item.parent ? {$currentID}");
			if ($parent ne ""){
				$currentID = $parent;

				if (lxq("layer.setVisibility {$parent} ?") == 0){
					#lxout("[->] : showing $parent");
					lx("layer.setVisibility {$parent} 1");
					push(@hiddenParents,$parent);
				}
			}else{
				$parentFind = 0;
			}
		}

		return(@hiddenParents);
	}
}