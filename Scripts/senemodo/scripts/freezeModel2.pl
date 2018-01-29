#perl
#BY: Seneca Menard
#version 0.995
#This script will delete all layers but the main one, triple the mesh, and save it out the same name with "_froze.lwo" appended
#The reason why I wrote this script is because the first freezemodel script would crash modo when you assign materials, because closing scenes corrupts it somehow.
#(9-12-06 fix) : I went and swapped the name from being "_froze" to "_whatever the layer name is"
#(6-24-08 feature) : This script now works properly with continuous terrain meshes, so if you're working on a continuous terrain that has a terrain uv map, it'll delete that terrain uv map before the export so it doesn't confuse rage.
#(7-25-09 bugfix) : fixed a bug where morph indices could legally be zero and would thus accidentally be skipped.
#(2-09-10 feature) : added the skipLXOSave argument, so you can export the LWO without saving the LXO if you want.  (only handy when you have to do a ton of exports in a row)
#(11-2-10 fix) : fixed a syntax change for 501
#(1-29-11 fix) : now unparenting the main layer if it has a parent because i delete all other meshes in teh scene and if it had a parent it, it would get deleted as well.
#(6-19-11 fix) : commented out the morph map support as it was causing problems in some legacy LXOs..
#(6-7-12 feature) : put in p4 auto checkouts of files.
#(6-10-12 fix) : my test to see if a p4 checkout succeeds is not working so i removed it.
#(7-12-12 fix) : deletes instances and static meshes now.

#SCRIPT ARGUMENTS :
# skipLXOSave : if you use this argument,  that means the script will only save the LWO and will NOT save the LXO.  You should only use this when you have to export a bunch of layers in a row, and it's fine to skip the LXO save part.
# ignoreMorphWarning : This arg will not have modo spawn the warning popup menu when the script found that you do have a morph map in the mesh.



#script arguments
foreach my $arg (@ARGV){
	if 		($arg eq "ignoreMorphWarning")	{our $ignoreMorphWarning = 1;	}
	elsif	($arg eq "skipLXOSave")			{our $skipLXOSave = 1;			}
}


#-----------------------------------------------------------------------------------------------------------
#DELETE ALL LAYERS BUT THE ONE YOU'RE IN.
#-----------------------------------------------------------------------------------------------------------
#find the main layer ID so the script won't fail
my $modoVer = lxq("query platformservice appversion ?");
if ($modoVer > 500){our $lwoType = "\$NLWO2";} else {our $lwoType = "\$LWO2";}
my $mainlayer = lxq("query layerservice layers ? main");
my $mainlayerID = lxq("query layerservice layer.id ? $mainlayer");
my $mainlayerName = lxq("query layerservice layer.name ? $mainlayer");
my $LXOName = lxq("query sceneservice scene.file ? current");
$LXOName =~ s/\\/\//g;
my $sceneName = $LXOName;
if ($sceneName =~ ".lwo")	{$sceneName =~ s/.lwo/_$mainlayerName.lwo/;}
elsif($sceneName =~ ".lxo")	{$sceneName =~ s/.lxo/_$mainlayerName.lwo/;}

#cancel the script if the file you're writing to is write protected.
if ((-e $sceneName) && (!-w $sceneName))	{	system("p4 edit \"$sceneName\"");	}

#first, save the original scene
if ($skipLXOSave != 1){
	if (!-w $LXOName)	{	system("p4 edit \"$LXOName\"");		}
	lx("!!scene.save");
}

#unparent mainlayer so that it won't get deleted
my $parentID = lxq("query sceneservice item.parent ? $mainlayerID");
if ($parentID ne ""){
	lx("item.parent {$mainlayerID} {} -1 inPlace:1");
}


#find the items to delete
my @deleteItems;
my $items = lxq("query sceneservice item.n ?");
for (my $i=0; $i<$items; $i++){
	my $type = lxq("query sceneservice item.type ? $i");
	if (($type eq "mesh") || ($type eq "meshInst") || ($type eq "triSurf")){
		my $id = lxq("query sceneservice item.id ? $i");
		my $name = lxq("query sceneservice item.name ? $i");
		if ($id eq $mainlayerID){
			lxout("This layer ($name) is the main layer, so it'll get exported.");
		}else{
			lxout("This layer ($name) is going to get deleted");
			push(@deleteItems,$id);
		}
	}
}

#if any "delete items" exist, select and delete them.
if (@deleteItems != 0){
	lx("select.type item");
	for (my $i=0; $i<@deleteItems; $i++){
		my $name = lxq("query sceneservice item.name ? @deleteItems[$i]");
		if($i == 0)	{lx("select.subItem [@deleteItems[$i]] set mesh;meshInst;camera;light;txtrLocator;backdrop;groupLocator [0] [1]");}
		else		{lx("select.subItem [@deleteItems[$i]] add mesh;meshInst;camera;light;txtrLocator;backdrop;groupLocator [0] [1]");}
	}
	lx("!!delete");
}

#delete any "terrain" uv maps if they exist.
lx("!!select.subItem {$mainlayerID} set mesh;meshInst;camera;light;backdrop;groupLocator;locator;deform;locdeform 0 1");
my $vmapCount = lxq("query layerservice vmap.n ?");
my $deleteVmaps = 0;
for (my $i=0; $i<$vmapCount; $i++){
	if (lxq("query layerservice vmap.type ? $i") eq "texture"){
		my $name = lxq("query layerservice vmap.name ? $i");
		if ($name =~ /terrain/i){
			lxout("[->] : Deleting vmap : ($name)");
			lx("!!select.vertexMap {$name} txuv add");
			$deleteVmaps++;
		}else{
			lx("!!select.vertexMap {$name} txuv remove");
		}
	}
}
if ($deleteVmaps > 0){
	lx("!!vertMap.delete txuv");
}


#-----------------------------------------------------------------------------------------------------------
#APPLY THE MORPH IF THERE IS ONE
#-----------------------------------------------------------------------------------------------------------
#my @vmaps = lxq("query layerservice vmaps ? all");
#my $morphMap;
#my $morphMapName;
#foreach my $vmap (@vmaps){
	#if (lxq("query layerservice vmap.type ? $vmap") eq "morph"){
		#$morphMap = $vmap;
		#$morphMapName = lxq("query layerservice vmap.name ? $vmap");
		#last;
	#}
#}
#if ($morphMapName ne ""){
	#if ($ignoreMorphWarning != 1){popup("WARNING : This layer has a morph map.  If you didn't intend \nfor it to have a morph map, go into the vmap list window \nand delete all the morph maps from the morph maps section\n \nClick yes to continue or no to cancel script");}
	#lxout("[->] Applying the morphmap");
	#lx("select.vertexMap {$morphMapName} morf remove");
	#lx("vertMap.applyMorph {$morphMapName} [100.0 %]");
#}
#


#-----------------------------------------------------------------------------------------------------------
#TRIPLE THE POLYS AND EXPORT THE SCENE
#-----------------------------------------------------------------------------------------------------------
lx("!!select.subItem [$mainlayerID] set mesh;meshInst;camera;light;txtrLocator;backdrop;groupLocator [0] [1]");
lx("!!select.drop polygon");
lx("!!unhide");
lx("!!poly.triple");


#-----------------------------------------------------------------------------------------------------------
#DELETE ANY "DELETE" FLAGGED POLYS IF THERE ARE ANY (for the floating models in a terrain mesh)
#-----------------------------------------------------------------------------------------------------------
my $layerName = lxq("query layerservice layer.name ? $mainlayer");
lx("!!select.useSet delete select");
if (lxq("query layerservice poly.n ? selected") > 0){lxout("[->] : Deleting the 'delete' flagged polys"); lx("delete");}


#export the scene
lxout("lwoType = $lwoType");
lx("!!scene.saveAs [$sceneName] {$lwoType} [True]");


#-----------------------------------------------------------------------------------------------------------
#UNDO THE TRIPLING AND LAYER DELETION
#-----------------------------------------------------------------------------------------------------------
#system "start /min sndrec32 /play /close C:\\\\WINDOWS\\\\Media\\\\Windows Information Bar.wav";
die("\n-\n-\n-\nTHIS SCRIPT IS NOT BROKEN!  THE ERROR MSG IS JUNK!\nTo stop this msg from coming up, click on the (In the future) button and choose (Hide Message)\n-\n-\n-\n");








sub popup #(MODO2 FIX)
{
	lx("dialog.setup yesNo");
	lx("dialog.msg {@_}");
	lx("dialog.open");
	my $confirm = lxq("dialog.result ?");
	if($confirm eq "no"){die;}
}