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

#get new fbx file path that's not in source dir, but in game dir.
my @words = split(/\//,$sceneName);
$words[-1] =~ s/\.lxo//i;
$sceneName = "E:\/senFiles\/seneProjects\/simulation\/Assets\/Resources\/World\/Arena1\/" . $words[-2] . "\/" . $words[-1] . "_" . $mainlayerName . ".fbx";

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
my $layerCount = lxq("query layerservice layer.n ? all");
for (my $i=1; $i<$layerCount+1; $i++){
	my $id = lxq("query layerservice layer.id ? $i");
	if ($id ne $mainlayerID){	push(@deleteItems,$id);	}
}

#if any "delete items" exist, select and delete them.
lx("select.drop item");
lx("select.subItem [$_] add mesh;meshInst;camera;light;txtrLocator;backdrop;groupLocator [0] [1]") for @deleteItems;
lx("!!select.itemType mode:{add} type:{sunLight}");
lx("!!select.itemType mode:{add} type:{camera}");
if (lxq("select.count item ?") > 0){	lx("!!delete");	}



#-----------------------------------------------------------------------------------------------------------
#TRIPLE THE POLYS AND EXPORT THE SCENE
#-----------------------------------------------------------------------------------------------------------
lx("!!select.subItem [$mainlayerID] set mesh;meshInst;camera;light;txtrLocator;backdrop;groupLocator [0] [1]");
lx("!!select.drop polygon");
lx("!!unhide");
#lx("!!poly.triple");
lx("!!poly.freeze false");

#export the scene
lx("!!scene.saveAs [$sceneName] {FBX} [True]");

#now delete the extra uv maps from the FBX.
if ($skipLXOSave != 1){
	removeBlankUVDataFromFBX($sceneName);
}

#-----------------------------------------------------------------------------------------------------------
#UNDO THE TRIPLING AND LAYER DELETION
#-----------------------------------------------------------------------------------------------------------

die("\n-\n-\n-\nTHIS SCRIPT IS NOT BROKEN!  THE ERROR MSG IS JUNK!\nTo stop this msg from coming up, click on the (In the future) button and choose (Hide Message)\n-\n-\n-\n");








#-----------------------------------------------------------------------------------------------------------
#OPEN THE FBX TEXT FILE AND DELETE TEH JUNK UV MAPS. (note, it'll have incorrect uv indices but i'm not bothering fixing that because i don't see it breaking anything yet. heh)
#-----------------------------------------------------------------------------------------------------------
sub removeBlankUVDataFromFBX{
	open (FBXFile, "<$_[0]") or die("I couldn't find this FBX : $_[0]");
	my @fbxData;
	my @tempData;
	my $useData = 1; #0=ignore.  1=use.  2=tempUse.
	
	while (<FBXFile>){
		#if paying attention to data.
		if ($useData == 1){
			if ($_ =~ /LayerElementUV: /){
				push(@tempData,$_);
				$useData = 2;
			}else{
				push(@fbxData,$_);
			}
		}
		
		#if ignoring data.
		elsif ($useData == 0){
			if ($_ eq "        }\n"){
				$useData = 1;
			}
		
		}
		
		#if on temporary hold
		else{
			push(@tempData,$_);
			
			if ($_ eq "            Name: \"\"\n"){
				$useData = 0;
				@tempData = "";
			}
			
			elsif ($_ =~ /            Name: \"Texture/){
				$useData = 1;
				for (my $i=0; $i<@tempData; $i++){
					push(@fbxData,$tempData[$i]);
				}
			}
		}
	}
	close(FBXFile);

	#write out new fbx
	open (FBXFile, ">$_[0]") or die("I couldn't find this FBX : $_[0]");
	print FBXFile $_ for @fbxData;
	close(FBXFile);
}









sub popup #(MODO2 FIX)
{
	lx("dialog.setup yesNo");
	lx("dialog.msg {@_}");
	lx("dialog.open");
	my $confirm = lxq("dialog.result ?");
	if($confirm eq "no"){die;}
}

