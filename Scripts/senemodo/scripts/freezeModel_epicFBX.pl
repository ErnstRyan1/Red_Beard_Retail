#perl
#author : Seneca Menard
#this script will copy the current layer's contents to a new scene and save as fbx and close. doesn't save original lxo.

#SETUP
my $modoVer = lxq("query platformservice appversion ?");
my $mainlayer = lxq("query layerservice layers ? main");
my $mainlayerID = lxq("query layerservice layer.id ? $mainlayer");
my $layerName = lxq("query layerservice layer.name ? $mainlayer");
my $sceneName = lxq("query sceneservice scene.file ? current");
my @deleteLayers;
my @deleteGroups;
my $filename;

#SCRIPT CVARS
foreach my $arg (@ARGV){
	if		($arg eq "noSave")				{	our $noSave = 1;		}
	elsif	($arg eq "useLayerName")		{	our $useLayerName = 1;	}
	elsif	($arg eq "useSceneName")		{	our $useSceneName = 1;	}
}

#GET FBX NAME
if ($useLayerName == 1){
	$sceneName =~ s/\\/\//g;
	my @path = split(/\//, $sceneName);
	$layerName =~ s/ \([0-9]+\)$//;
	for (my $i=0; $i<$#path; $i++){$filename .= $path[$i] . "\/";}
	$filename .= $layerName . ".fbx";
}elsif ($useSceneName == 1){
	$sceneName =~ s/\\/\//g;
	$filename = $sceneName;
	$filename =~ s/\.lxo/\.fbx/;
}else{
	our @files = fileDialog("save","FBX EXPORT","*.fbx","fbx");
	if (lxres != 0){die("The user pressed the cancel button");}
	$filename = $files[0];
}

#SAVE LXO
if ($noSave == 0){lx("!!scene.save");}

#COPY POLYS TO NEW SCENE
lx("!!item.refSystem {$mainlayerID}");
lx("!!select.drop polygon");
lx("!!unhide");
lx("!!select.copy");
lx("!!scene.new");
lx("!!select.paste");
lx("!!item.name name:{$layerName} type:{mesh}");
lx("!!poly.triple");

#SCALE POLYS TO 1% for unreal bug
lx("!!transform.channel scl.X 0.01");
lx("!!transform.channel scl.Y 0.01");
lx("!!transform.channel scl.Z 0.01");

popup("pause : $filename");

if ($modoVer < 800)	{	lx("scene.saveAs {$filename} FBX false");	}
else				{	lx("scene.saveAs {$filename} fbx false");	}

#CRASH SCRIPT TO UNDO
die("Crashing script to put the file back to how it initially was");




#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#QUERY IF LIGHTMAP VMAP EXISTS SUB
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
sub queryIfLightmapVmapExists{
	my @layerSel = lxq("query layerservice layers ? selected");
	foreach my $id (@layerSel){
		my $layerName = lxq("query layerservice layer.name ? {$id}");
		my $vmapCount = lxq("query layerservice vmap.n ? all");
		for (my $i=0; $i<$vmapCount; $i++){
			if ( (lxq("query layerservice vmap.type ? $i") eq "texture") && (lxq("query layerservice vmap.name ? $i") =~ /lightmap/i) ){
				my @vmapValues = lxq("query layerservice poly.vmapValue ? 0");
				foreach my $val (@vmapValues){
					if ($val != 0){return 1;}
				}
			}
		}
	}
	
	return 0;
}

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

##------------------------------------------------------------------------------------------------------------
##------------------------------------------------------------------------------------------------------------
#FILE DIALOG WINDOW SUB
##------------------------------------------------------------------------------------------------------------
##------------------------------------------------------------------------------------------------------------
##USAGE : my @files = fileDialog("open"|"save","title","*.lxo;*.lwo;*.obj","lxo");
##0=open or save #1=title #2=loadExt #3=saveExt
sub fileDialog{
	if ($_[0] eq "open")	{	lx("dialog.setup fileOpenMulti");	}
	else					{	lx("dialog.setup fileSave");		}

	lx("dialog.title {$_[1]}");
	lx("dialog.fileTypeCustom format:[stp] username:[$_[1]] loadPattern:[$_[2]] saveExtension:[$_[3]]");
	lx("dialog.open");
	my @fileNames = lxq("dialog.result ?") or die("The file saver window was cancelled, so I'm cancelling the script.");
	return (@fileNames);
}
