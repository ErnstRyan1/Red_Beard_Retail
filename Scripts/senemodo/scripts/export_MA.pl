#perl
#this script will:
# - Copy the current layer's geometry to a new layer,
# - Turn off any subDs,
# - merg verts
# - cut/paste each material group to keep maya from joining them.
# - Save it to desktop/temp.ma
# - close new scene.

#remember scene and current layer.
my $mainscene = lxq("query sceneservice scene.index ? current");
my $sceneName = lxq("query sceneservice scene.file ?");
my $mainlayer = lxq("query layerservice layers ? main");
my $layerID = lxq("query layerservice layer.id ? current");

lx("select.drop polygon");
lx("select.copy");
lx("scene.new");
lx("select.paste");
lx("!!vert.merge fixed dist:[1 um]");
lx("select.polygon add type subdiv 1");
if (lxq("query layerservice polys ? selected") > 0){	lx("poly.convert face subpatch [1]");	}
lx("select.drop polygon");

#find all the group masks
my $txLayers = lxq("query sceneservice txLayer.n ?");
my @groupNames;
for (my $i=0; $i<$txLayers; $i++){
	if (lxq("query sceneservice txLayer.type ? $i") eq "mask"){
		my $name = lxq("query sceneservice txLayer.name ? $i");
		push (@groupNames,$name);
	}
}

#cut / paste each material's polys
foreach my $name (@groupNames){
	lx("select.drop polygon");
	lx("select.polygon add material face $name");
	lx("select.cut");
	lx("select.paste");
}

#save and close scene
if (@ARGV[0] eq "dialog"){
	lx("scene.save rename format:mayaAscii");
}else{
	lx("scene.saveAs [C:\\Documents and Settings\\seneca.EDEN.000\\Desktop\\temp.ma] mayaAscii [False]");
}
lx("scene.close");


#set the original scene back
lx("scene.set $mainscene");
lx("select.subItem [$layerID] set mesh;meshInst;camera;light;txtrLocator;backdrop;groupLocator [0] [1]");




sub popup #(MODO2 FIX)
{
	lx("dialog.setup yesNo");
	lx("dialog.msg {@_}");
	lx("dialog.open");
	my $confirm = lxq("dialog.result ?");
	if($confirm eq "no"){die;}
}
