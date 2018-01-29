#perl
#ver 1.0
#author : Seneca Menard
#this script will delete a bunch of stuff in the scene (lights, groups, cameras, static meshes, unselected meshes, etc) 
#and save as fbx and crash the script to undo it.  i tried doing it the nonhack way but the skinning was be lost when 
#you transfer the animated mesh to a new scene and save to fbx.

#save scene.
lx("scene.save");

#get scene info
my $mainlayerID = lxq("query layerservice layer.id ? main");
my $mainlayerName = lxq("query layerservice layer.name ? main");
my $timeStart = lxq("time.range range:{scene} in:{?}");
my $timeEnd = lxq("time.range range:{scene} out:{?}");

#get new file name
my $FBXName = lxq("query sceneservice scene.file ? current");
$FBXName =~ s/\\/\//g;
$FBXName =~ s/\/work\//\//;
$FBXName =~ s/\.lxo//i;
$FBXName .= ".fbx";

#delete all meshes except the selected one.
lx("!!select.itemType type:{mesh} mode:{set}");
lx("select.subItem {$mainlayerID} remove mesh;triSurf;camera;light;backdrop;groupLocator;replicator;surfGen;locator;deform;locdeform;deformGroup;deformMDD2;morphDeform;itemInfluence;genInfluence;softDeform;ABCdeform.sample;chanModify;chanEffect 0 0");
lx("select.itemType type:{camera} mode:{add}");
lx("select.itemType type:{sunLight} mode:{add}");
lx("select.itemType type:{groupLocator} mode:{add}");
lx("select.itemType type:{triSurf} mode:{add}");
lx("select.itemType type:{meshInst} mode:{add}");
lx("item.delete");

#freeze anims
my $frameStart = $timeStart * 24;
my $frameEnd = $timeStart * 24;
lx("select.itemType type:{locator} mode:{set}");
lx("item.bake frameS:{$frameStart} frameE:{$frameEnd} remConstraints:{true}");

#save scene
lx("!!scene.saveAs [$FBXName] {FBX} [True]");
die("Crashing script to revert changes");





















#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#POPUP SUB
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE : popup("What I wanna print");
sub popup #(MODO2 FIX)
{
	lx("dialog.setup yesNo");
	lx("dialog.msg {@_}");
	lx("dialog.open");
	my $confirm = lxq("dialog.result ?");
	if($confirm eq "no"){die;}
}
