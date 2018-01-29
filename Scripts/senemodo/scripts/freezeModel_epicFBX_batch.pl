#perl
#author : Seneca Menard
#this script will copy the current layer's contents to a new scene and save as fbx and close. doesn't save original lxo.

#SETUP
my $modoVer = lxq("query platformservice appversion ?");
my $scene = lxq("query sceneservice scene.index ? current");
my @layers = lxq("query sceneservice selection ? mesh");
my @deleteLayers;
my @deleteGroups;
my $layerName;

#SCRIPT CVARS
foreach my $arg (@ARGV){
	if		($arg eq "noSave")				{	our $noSave = 1;		}
	elsif	($arg eq "useLayerName")		{	our $useLayerName = 1;	}
}

#SAVE LXO
if ($noSave == 0){lx("!!scene.save");}

#EXPORT FBX FILES
foreach my $id (@layers){
	my $filename;

	#GET FBX NAME
	if ($useLayerName == 1){
		my $layer = lxq("query layerservice layer.index ? {$id}");
		$layerName = lxq("query layerservice layer.name ? $layer");
		my $sceneName = lxq("query sceneservice scene.file ? current");
		$sceneName =~ s/\\/\//g;
		my @path = split(/\//, $sceneName);
		$layerName =~ s/ \([0-9]+\)$//;
		for (my $i=0; $i<$#path; $i++){$filename .= $path[$i] . "\/";}
		$filename .= $layerName . ".fbx";
	}else{
		our @files = fileDialog("save","FBX EXPORT","*.fbx","fbx");
		if (lxres != 0){die("The user pressed the cancel button");}
		$filename = $files[0];
	}

	#SELECT ITEM
	lx("!!select.subItem {$id} set mesh;meshInst;camera;light;txtrLocator;backdrop;groupLocator;replicator;surfGen;locator;deform;locdeform;deformGroup;deformMDD2;morphDeform;itemInfluence;genInfluence;deform.wrap;softLag;ABCdeform.sample;chanModify;chanEffect;defaultShader;defaultShader 0 0");

	#COPY POLYS TO NEW SCENE AND TRIPLE
	lx("!!item.refSystem {$id}");
	lx("!!select.drop polygon");
	lx("!!unhide");
	lx("!!select.copy");
	lx("!!scene.new");
	lx("!!select.paste");
	lx("!!item.name name:{$layerName} type:{mesh}");
	lx("!!poly.freeze twoPoints");
	lx("!!poly.triple");
	
	#SCALE POLYS TO 1% for unreal bug
	lx("!!transform.channel scl.X 0.01");
	lx("!!transform.channel scl.Y 0.01");
	lx("!!transform.channel scl.Z 0.01");
	
	#APPLY GRADIENT REMAP MATERIALS
	my $newMainlayer = lxq("query layerservice layers ? main");
	my $materialCount = lxq("query layerservice material.n ? all");
	my $trueMaterialName = "";
	my $rgbVmapIndex = -1;
	my $vmapCount = lxq("query layerservice vmap.n ? all");
	
	for (my $i=0; $i<$vmapCount; $i++){
		if (lxq("query layerservice vmap.type ? $i") eq "rgba"){
			$rgbVmapIndex = $i;
		}
	}
	if ($rgbVmapIndex == -1)	{	lx("!!vertMap.new Color rgba");	}
	
	
	for (my $i=-10; $i<10; $i++){
		my $materialName = lxq("query layerservice material.name ? $i");
		lxout("materialName $i = $materialName");
	}
	
	for (my $i=0; $i<$materialCount; $i++){
		my $materialName = lxq("query layerservice material.name ? $i");
		if ($materialName =~ /gradRemap/i){
			if ($trueMaterialName eq ""){
				$trueMaterialName = $materialName;
				$trueMaterialName =~ s/_gradRemap[0-9]+//;
			}
			my @numbers = split(/[^0-9]/, $materialName);
			my $weightValue = (0.03125 * $numbers[-1]) + 0.015625;
			lxout("weightValue = $weightValue");

			lx("!!select.drop polygon");
			lx("!!select.polygon add material face {$materialName}");
			lx("!!select.cut");
			lx("!!select.all");
			lx("!!select.paste");
			lx("!!select.invert");
			lx("!!poly.setMaterial {$trueMaterialName}");
			lx("select.convert vertex");
			
			my @verts = lxq("query layerservice verts ? selected");
			foreach my $vert (@verts){
				my @vmapValue = lxq("query layerservice vert.vmapValue ? $vert");
				
				lx("!!select.element $newMainlayer vertex set $vert");
				lx("!!tool.set vertMap.setColor on");
				lx("!!tool.set vertMap.setColor on");
				lx("!!tool.attr vertMap.setColor Color {$weightValue 0 0 1}");
				lx("!!tool.doApply");
				lx("!!tool.set vertMap.setColor off");
			}
			
			$i -= 1;
		}
	}	

	#PAUSE SCRIPT SO FACETING WON'T GET CORRUPTED
	popup("pause : $filename");

	if ($modoVer < 800)	{	lx("scene.saveAs {$filename} FBX false");	}
	else				{	lx("scene.saveAs {$filename} fbx false");	}

	#SELECT ORIGINAL SCENE AGAIN
	lx("!!scene.set $scene");
}

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
