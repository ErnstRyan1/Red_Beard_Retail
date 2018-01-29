#perl
#COLLAPSE SCENES
#AUTHOR: Seneca Menard
#version 1.0
#This script will copy all the polygons in all the currently open scenes and paste them in a new scene.


lx("scene.new");

#========================================
#BUILD THE SCENE INDEX ARRAY
#========================================
my @scenes;
my $scenes = lxq("query sceneservice scene.n ?");
for (my $i=0; $i<$scenes; $i++){
	my $sceneID = lxq("query sceneservice scene.index ? $i");
	push(@scenes,$sceneID);
}

#========================================
#GO THROUGH EACH SCENE AND COPY ITS CONTENTS TO THE NEW SCENE
#========================================
for (my $i=0; $i<$#scenes; $i++){
	#set the scene
	lx("scene.set @scenes[$i]");

	#select all layers
	my @layers = lxq("query layerservice layers ? all");
	foreach my $layer (@layers){
		my $layerID =  lxq("query layerservice layer.id ? $layer");
		lx("select.subItem [$layerID] add mesh;meshInst;camera;light;txtrLocator;backdrop;groupLocator [0] [1]");
	}

	#copy and paste the polys
	lx("select.drop polygon");
	lx("select.invert");
	if (lxq("select.count polygon ?") > 0){
		lx("!!select.copy");
		lx("scene.set @scenes[-1]");
		lx("!!select.paste");
	}
	else{
		lxout("there are no polys in this scene");
	}
}


#========================================
#POPUP SUB
#========================================
sub popup #(MODO2 FIX)
{
	lx("dialog.setup yesNo");
	lx("dialog.msg {@_}");
	lx("dialog.open");
	my $confirm = lxq("dialog.result ?");
	if($confirm eq "no"){die;}
}
