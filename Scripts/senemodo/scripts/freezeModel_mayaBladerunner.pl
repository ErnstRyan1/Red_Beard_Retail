#perl
#author : Seneca Menard
#this script will copy the current layer's contents to a new scene and save as fbx and close. doesn't save original lxo.

#save scene
lx("!!scene.save");

#get fbx filename
my $sceneName = lxq("query sceneservice scene.file ? current");
$sceneName =~ s/\\/\//g;
$sceneName =~ s/\.lxo/\.fbx/;

#save fbx
lx("scene.saveAs {$sceneName} fbx false");	

#CRASH SCRIPT TO UNDO
die("Crashing script to put the file back to how it initially was");


#what ctrl alt shift s was bound to beforehand
#@freezeModel_epicFBX.pl useLayerName







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