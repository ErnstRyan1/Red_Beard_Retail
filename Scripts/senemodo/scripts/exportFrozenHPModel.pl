#perl
#ver 1.982
#author : Seneca Menard
#This script will take your currently selected items (and instances), freeze 'em, triple 'em, and export it as a new model.

#SCRIPT ARGUMENTS :
# "guessFilePathHP" : (USE ON HP LAYERS) This argument will tell the script that the layer(s) you have selected will theoretically be a high poly model and will save out your model as an LWO with the same name as the current scene, only it will swap "_base.lxo" or "_work.lxo" for "_hp.lwo"
# "guessFilePathLP" : (USE ON LP LAYERS) This argument will tell the script that the layer(s) you have selected will theoretically be a low poly model and will save out your model as an LWO with the same name as the current scene, only it will swap "_base.lxo" or "_work.lxo" for "_render.lwo"
# "guessFilePathInGame" : (USE ON LP LAYERS) What it's for is to export the currently selected layers using the first selected layer's name in the filepath : So if you run it on a layer called "car" in this scene : W:/rage/base/bunker/city.lxo, it'll save out W:/rage/base/bunker/city_car.lwo
# "forceTextureVmap" : tells the script to NOT ask you which vmap to keep. it'll force it to only accept the vmap called "Texture"

#(1-6-09 fix) : I made it save out LWOs instead of LXOs and I also told it not to save the scene if it wasn't previously saved.
#(1-30-09 feature) : I added a vert merge to HP models.
#(2-9-09 feature) : I added "guessFilePathInGame" cvar.  What it's for is to export the currently selected layers using the first selected layer's name in the filepath : So if you run it on a layer called "car" in this scene : W:/rage/base/bunker/city.lxo, it'll save out W:/rage/base/bunker/city_car.lwo
#(9-15-09 fix) : If models were flipped, I'd have to flip their polys when I froze their transforms, but that appears fixed in 401b, so I removed that if you're running that version of modo.
#(9-17-09 fix) : The script now retains transforms from the selected items' parents.
#(10-7-09 fix) : There's no layer referencing anymore.  I'm not sure why I had that in there.... heh.
#(11-3-09 fix) : The layer visibility is now forced on to get around a modo bug.
#(2-24-10 feature) : it now checks out the files if needed.
#(2-25-10 fix) : forces a poly unhide and makes sure the proper item selection is restored when script is done.
#(8-27-10 feature) : now supports static items
#(9-14-10 feature) : can now export children items.  (so you can group all your items under one group, right click on the group and export and it'll export all the children items at once.  Of course, it'll use the group name as the file name suffix)
#(10-1-10 fix) : added more {} to stop query fails on multi word cvar values
#(10-26-10 fix) : I now move all instances' uvs whole units to stop any uv mirror issues when exporting to idtech5.  I also fixed an issue with item scales and flipped polys for 401.  Also, vert merges are occurring again for HP models.
#(11-2-10 fix) : fixed a syntax change for 501
#(3-20-11 fix) : now works on invisible layers and features the "skipLXOSave" feature that freezemodel2.pl has
#(3-25-11 fix) : 501 sp2 had an annoying syntax change.  grrr.
#(2-28-11 fix) : fixed problem with hidden source meshes.
#(3-2-12 feature) : "forceTextureVmap" : tells the script to NOT ask you which vmap to keep. it'll force it to only accept the vmap called "Texture"
#(3-2-12 fix) : 601 changed item.duplicate syntax so it's now updated
#(3-2-12 fix) : fixed mesh selection error that wasn't causing any problems.
#(2-1-13 fix) : findMeshInstSource sub had an infinite loop with trisurfs.
#(4-2-15 feature) : findMeshInstSource now supports proxy meshes.


#script cvars (have to run twice because other ones need to find filename first)
foreach my $arg (@ARGV){
	if		($arg eq "skipLXOSave")			{	our $skipLXOSave = 1;		}
	elsif	($arg eq "applyOneMatrMulti")	{	our $applyOneMatrMulti = 1;	}
	elsif	($arg eq "forceTextureVmap")	{	our $forceTextureVmap = 1;	}

}

#script setup
my $modoBuild = lxq("query platformservice appbuild ?");
my $modoVer = lxq("query platformservice appversion ?");
my $mainlayer = lxq("query layerservice layers ? main");
my $exportName = "";
my $mainlayerID = lxq("query layerservice layer.id ? main");
my $scene = lxq("query sceneservice scene.index ? current");
my $sceneFile = lxq("query sceneservice scene.file ? current");
my $currentItemRef = lxq("item.refSystem ?");
if ($currentItemRef ne ""){lx("!!item.refSystem {}");}
if ($modoVer > 500){our $lwoType = "\$NLWO2";} else {our $lwoType = "\$LWO2";}
if ($modoBuild > 41320){our $selectPolygonArg = "psubdiv";}else{our $selectPolygonArg = "curve";}

#save the selection mode
if    (lxq( "select.typeFrom {vertex;edge;polygon;item} ?" ))	{our $selMode = "vertex";}
elsif (lxq( "select.typeFrom {edge;polygon;item;vertex} ?" ))	{our $selMode = "edge";}
elsif (lxq( "select.typeFrom {polygon;item;vertex;edge} ?" ))	{our $selMode = "polygon";}
elsif (lxq( "select.typeFrom {item;vertex;edge;polygon} ?" ))	{our $selMode = "item";}

#save the uv map.
my @vmaps =  lxq("query layerservice vmaps ? selected");

#save the scene
if (($skipLXOSave != 1) && ($sceneFile ne "")){lx("scene.save");}
my $symmetryState = lxq("select.symmetryState ?");
if ($symmetryState ne "none"){lx("select.symmetryState none");}

#find meshes and instances
my @meshes;
my @meshInstances;
my @deleteMeshes;
my @staticMeshes;
my @selection = lxq("query sceneservice selection ? all");

foreach my $id (@selection){
	my $type = lxq("query sceneservice item.type ? {$id}");
	if (($type eq "mesh") || ($type eq "meshInst") || ($type eq "triSurf") || ($type eq "groupLocator")){
		lx("layer.setVisibility {$id} 1");
		if ($exportName eq ""){
			$exportName = lxq("query sceneservice item.name ? {$id}");
			$exportName =~ s/\s\([0-9]+\)//;
		}
		my @children = lxq("query sceneservice item.children ? {$id}");
		foreach my $childID (@children){
			if (($type eq "mesh") || ($type eq "meshInst") || ($type eq "triSurf") || ($type eq "groupLocator")){
				push(@selection,$childID);
			}
		}
	}
}

foreach my $id (@selection){
	my $type = lxq("query sceneservice item.type ? {$id}");
	if		($type eq "mesh"){
		lx("layer.setVisibility {$id} 1");
		push(@meshes,$id);
	}elsif	($type eq "meshInst"){
		lx("layer.setVisibility {$id} 1");
		push(@meshInstances,$id);
	}elsif	($type eq "triSurf"){
		lx("layer.setVisibility {$id} 1");
		push(@staticMeshes,$id);
	}
}

#unhide parents
verifyItemVisibities(@selection);

#determine export file name (script arguments)
foreach my $arg (@ARGV){
	if		($arg =~ /guessFilePathHP/i)	{	our $guessFilePath = 1;		our $fileSuffix = "_hp";											}
	elsif	($arg =~ /guessFilePathLP/i)	{	our $guessFilePath = 1;		our $fileSuffix = "_render";										}
	elsif	($arg =~ /guessFilePathInGame/i){	our $guessFilePath = 1;		our $fileSuffix = "_".$exportName;	our $guessFilePathInGame = 1;	}
}

#convert instances to meshes (and avoid the flipping bug)
if (@meshInstances > 0){
	my $moveUVAmountCount = 0;
	lx("select.drop item");
	foreach my $item (@meshInstances){

		#find parent of instance
		my $parent = lxq("query sceneservice item.parent ? {$item}");

		#find transform of instance
		lx("select.subItem {$item} set mesh;meshInst;camera;light;backdrop;groupLocator;locator;deform;locdeform 0 0");
		my @transform;
		if ($modoVer > 400){
		   @transform[0] = lxq("transform.channel scl.X ?");
		   @transform[1] = lxq("transform.channel scl.Y ?");
		   @transform[2] = lxq("transform.channel scl.Z ?");

		   @transform[3] = lxq("transform.channel pos.X ?");
		   @transform[4] = lxq("transform.channel pos.Y ?");
		   @transform[5] = lxq("transform.channel pos.Z ?");

		   @transform[6] = lxq("transform.channel rot.X ?");
		   @transform[7] = lxq("transform.channel rot.Y ?");
		   @transform[8] = lxq("transform.channel rot.Z ?");
	   }else{
		   @transform[0] = lxq("item.channel locator(scale)\$scl.X ?");
		   @transform[1] = lxq("item.channel locator(scale)\$scl.Y ?");
		   @transform[2] = lxq("item.channel locator(scale)\$scl.Z ?");

		   @transform[3] = lxq("item.channel locator(translation)\$pos.X ?");
		   @transform[4] = lxq("item.channel locator(translation)\$pos.Y ?");
		   @transform[5] = lxq("item.channel locator(translation)\$pos.Z ?");

		   @transform[6] = lxq("item.channel locator(rotation)\$rot.X ?");
		   @transform[7] = lxq("item.channel locator(rotation)\$rot.Y ?");
		   @transform[8] = lxq("item.channel locator(rotation)\$rot.Z ?");
	   }

		#select the original mesh and duplicate it.
		my $sourceMeshID = findMeshInstSource($item) or die("$item is not a meshInst");
		lx("select.subItem [$sourceMeshID] set mesh;meshInst;camera;light;backdrop;groupLocator;locator;deform;locdeform 0 0");
		lx("item.duplicate instance:[0]");

		#now move the uvs a random distance to get around the uv symmetry issue in our game
		if ( ($guessFilePath == 0) || ($guessFilePathInGame == 1) ){
			$moveUVAmountCount++;
			lx("select.type polygon");
			lx("!!select.vertexMap Texture txuv replace");
			lx("!!tool.viewType UV");
			lx("!!tool.set actr.auto on");
			lx("!!tool.set xfrm.move on");
			lx("!!tool.reset");
			lx("!!tool.xfrmDisco {1}");
			lx("!!tool.setAttr axis.auto axis {2}");
			lx("!!tool.setAttr center.auto cenU {0}");
			lx("!!tool.setAttr center.auto cenV {0}");
			lx("!!tool.setAttr xfrm.move U {$moveUVAmountCount}");
			lx("!!tool.setAttr xfrm.move V {0}");
			lx("!!tool.doApply");
			lx("!!tool.set xfrm.move off");
		}

		#now apply the transform to the duplicate.
		if ($modoVer > 400){
			lx("transform.channel scl.X {@transform[0]}");
			lx("transform.channel scl.Y {@transform[1]}");
			lx("transform.channel scl.Z {@transform[2]}");

			lx("transform.channel pos.X {@transform[3]}");
			lx("transform.channel pos.Y {@transform[4]}");
			lx("transform.channel pos.Z {@transform[5]}");

			lx("transform.channel rot.X {@transform[6]}");
			lx("transform.channel rot.Y {@transform[7]}");
			lx("transform.channel rot.Z {@transform[8]}");

		}else{
			lx("!!item.channel locator(scale)\$scl.X {@transform[0]}");
			lx("!!item.channel locator(scale)\$scl.Y {@transform[1]}");
			lx("!!item.channel locator(scale)\$scl.Z {@transform[2]}");
			lx("!!item.channel locator(translation)\$pos.X {@transform[3]}");
			lx("!!item.channel locator(translation)\$pos.Y {@transform[4]}");
			lx("!!item.channel locator(translation)\$pos.Z {@transform[5]}");
			lx("!!item.channel locator(rotation)\$rot.X {@transform[6]}");
			lx("!!item.channel locator(rotation)\$rot.Y {@transform[7]}");
			lx("!!item.channel locator(rotation)\$rot.Z {@transform[8]}");
		}

		#parent this duplicate item if the original had a parent
		my @meshSelection = lxq("query sceneservice selection ? mesh");
		$currentLayerID = $meshSelection[-1];
		if ($parent ne ""){lx("item.parent {$currentLayerID} {$parent} -1 inPlace:0");}

		my $negativeScaleCount = 0;
		if (@transform[0] < -0){$negativeScaleCount++;}
		if (@transform[1] < -0){$negativeScaleCount++;}
		if (@transform[2] < -0){$negativeScaleCount++;}
		lx("layer.setVisibility {$currentLayerID} 1");
		lx("!!transform.freeze");

		if ($modoBuild < 32456){
			if (($negativeScaleCount == 1) || ($negativeScaleCount == 3)){
				lx("!!poly.flip");
			}
		}else{
			if ($negativeScaleCount == 2){
				lx("!!poly.flip");
			}
		}

		push(@deleteMeshes, $currentLayerID);
	}
}

#convert static meshes to meshes
if (@staticMeshes > 0){
	foreach my $id (@staticMeshes){
		lx("select.subItem {$id} set mesh;triSurf;meshInst;camera;light;backdrop;groupLocator;replicator;deform;locdeform;chanModify;chanEffect 0 0");
		lx("item.duplicate instance:[0] type:[locator]");
		lx("item.setType mesh locator");
		my $id = lxq("query sceneservice selection ? mesh");
		push(@deleteMeshes, $id);
	}
}

#copy/paste all the geometry to a new scene.
lx("!!select.drop item");
lx("select.subItem {$_} add mesh;meshInst;camera;light;backdrop;groupLocator;locator;deform;locdeform 0 0") for @meshes;
lx("select.subItem {$_} add mesh;meshInst;camera;light;backdrop;groupLocator;locator;deform;locdeform 0 0") for @deleteMeshes;
lx("!!select.drop polygon");
lx("!!unhide");
lx("!!select.copy");
lx("!!scene.new");
lx("!!select.paste");
if (1){lx("!!vert.merge auto {0} {1 um}");} #TEMP : it's merging verts every time now.  not sure if i should do this though.
lx("!!poly.freeze false");
lx("!!poly.triple");
lx("!!select.drop polygon");
lx("!!select.polygon add vertex {$selectPolygonArg} 1");
lx("!!select.polygon add vertex {$selectPolygonArg} 2");
if (lxq("select.count ? polygon") > 0){lx("!!delete}");}

#apply one material multiple times with differing letter cases if needed
if ($applyOneMatrMulti == 1){
	my $materialName = quickDialog("Material you wish to apply:",string,"models\/mapobjects\/test\/megatexture_bake1","","");
	applySameMaterialMultTimesWDiffSmAngles($materialName);
}

#delete multiple vmaps
my $newMainlayer = lxq("query layerservice layers ? main");
my $vmapCount = lxq("query layerservice vmap.n ? all");
my $uvMapCount = 0;
my $multipleChoiceText = "all";
my @vmaps;
for (my $i=0; $i<$vmapCount; $i++){
	if (lxq("query layerservice vmap.type ? $i") eq "texture"){
		my $vmapName = lxq("query layerservice vmap.name ? $i");
		$multipleChoiceText .= ";".$vmapName;
		push(@vmaps,$i);
		$uvMapCount++;
	}
}

if ( ($uvMapCount > 1) && ($fileSuffix ne "_hp") ){
	if ($forceTextureVmap == 1)	{	our $answer = "Texture";														}
	else						{	our $answer = popupMultChoice("Keep which uv map?","$multipleChoiceText",1);	}
	if ($answer ne "all"){
		for (my $i=0; $i<$vmapCount; $i++){
			my $type = lxq("query layerservice vmap.type ? $i");
			my $name = lxq("query layerservice vmap.name ? $i");
			if ( ($type eq "texture") && ($name ne $answer) ){
				lx("!!select.vertexMap {$name} txuv replace");
				lx("!!vertMap.delete txuv");
			}
		}
	}
}



#save scene
if ($guessFilePath == 1){
	if 		($sceneFile eq "(none)")		{lxout("The scene hasn't been saved yet, so I can't 'guess' the filename to save it to.");   lx("scene.save") or die("The user canceled the scene save, so I'm cancelling the layer export");}
	if 		($sceneFile =~ /_base\./i)		{$sceneFile =~ s/_base\.[a-z]+/$fileSuffix\.lwo/i;}
	elsif	($sceneFile =~ /_work\./i)		{$sceneFile =~ s/_work\.[a-z]+/$fileSuffix\.lwo/i;}
	else									{$sceneFile =~ s/\.[a-z]+/$fileSuffix\.lwo/i;}
	if		($applyOneMatrMulti == 1)		{$sceneFile =~ s/\.lwo/_clean\.lwo/;}
	if ((-e $sceneFile) && (!-w $sceneFile)){system("p4 edit \"$sceneFile\"");}
	lx("scene.saveAs {$sceneFile} {$lwoType} false");
}else{
	lx("dialog.setup fileSave");
	lx("dialog.title [Export active layer(s)]");
	lx("dialog.fileTypeCustom format:[slwo] username:[LWO] loadPattern:[*.lwo] saveExtension:[lwo]");
	lx("dialog.open");
	my $filename = lxq("dialog.result ?") or die("The file saver window was cancelled, so I'm cancelling the script.");
	if ((-e $filename) && (!-w $filename)){system("p4 edit \"$filename\"");}
	lx("scene.saveAs {$filename} {$lwoType} false");
}

lx("!!scene.close");

#now delete those new items in the old scene.
lx("!!scene.set $scene");
lx("!!select.drop item");
foreach my $id (@deleteMeshes){lx("!!select.subItem {$id} add mesh;meshInst;camera;light;backdrop;groupLocator;locator;deform;locdeform 0 0");}
lx("!!delete");


#now restore the original visibility and selection
lx("select.drop item");
foreach my $id (@meshes){
	lx("layer.setVisibility {$id} 1");
	lx("!!select.subItem {$id} add mesh;meshInst;camera;light;backdrop;groupLocator;locator;deform;locdeform 0 0");
}
foreach my $id (@meshInstances){
	lx("layer.setVisibility {$id} 1");
	lx("!!select.subItem {$id} add mesh;meshInst;camera;light;backdrop;groupLocator;locator;deform;locdeform 0 0");
}

#now restore the originally visible reference layer.
if ($currentItemRef ne ""){lx("!!item.refSystem {$currentItemRef}");}

#now restore the selection mode and selected vmaps
lx("!!select.type {$selMode}");

#now restore symmetry
if ($symmetryState ne "none"){lx("select.symmetryState $symmetryState");}

foreach my $vmap (@vmaps){
	if (lxq("query layerservice vmap.type ? {$vmap}") eq "texture"){
		my $vmapName = lxq("query layerservice vmap.name ? {$vmap}");
		lx("!!select.vertexMap {$vmapName} txuv add");
	}
}





#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#---------------------------------------------SUBROUTINES----------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#APPLY SAME MATERIAL MULTIPLE TIMES WITH DIFFERENT SMOOTHING ANGLES (uses letter case variations to make the mask unique)
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#usage : applySameMaterialMultTimesWDiffSmAngles($materialName);
#requires shaderTreeTools sub
sub applySameMaterialMultTimesWDiffSmAngles{
	my %usedUpperCaseLetterPositions;
	my $materialNameToApply = $_[0];
	$materialNameToApply =~ s/\\/\//g;

	#build list of already existing materials
	my %preexistSmAngleTable;
	my $txLayerCount = lxq("query sceneservice txLayer.n ? all");
	for (my $i=0; $i<$txLayerCount; $i++){
		if (lxq("query sceneservice txLayer.type ? $i") eq "mask"){
			my $id = lxq("query sceneservice txLayer.id ? $i");
			my $ptag = lxq("item.channel ptag ? set {$id}");
			$ptag =~ s/\\/\//g;

			if (lc($ptag) eq lc($materialNameToApply)){
				if ($ptag =~ /([A-Z])/){}
				my $uc_letterPos = index($ptag,$1);
				if ($ptag !~ /([A-Z])/){
					$usedUpperCaseLetterPositions{-1} = 1;
				}else{
					$usedUpperCaseLetterPositions{$uc_letterPos} = 1;
				}

				my @children = lxq("query sceneservice txLayer.children ? $id");
				foreach my $child (@children){
					if (lxq("query sceneservice txLayer.type ? $child") eq "advancedMaterial"){
						my $smoothingAngle = int(lxq("item.channel smAngle ? set {$child}") + 0.5);
						$preexistSmAngleTable{$smoothingAngle} = $ptag;
						last;
					}
				}
			}
		}
	}

	#go through all polys in layer and build a list of the materials' sm angles
	my %smoothingAngles;
	shaderTreeTools(buildDbase);

	my $letterCount = 0;
	my $materialNameLength = length($materialNameToApply);
	my $materialCount = lxq("query layerservice material.n ? all");
	for (my $i=0; $i<$materialCount; $i++){
		my $materialName = lxq("query layerservice material.name ? $i");
		my $materialID = shaderTreeTools(ptag,materialID,$materialName);
		my $smoothingAngle = int(lxq("item.channel smAngle ? set {$materialID}") + 0.5);
		push(@{$smoothingAngles{$smoothingAngle}},$materialName);
	}

	#now apply the materials
	foreach my $smoothingAngle (keys %smoothingAngles){
		lx("select.drop polygon");
		lx("select.polygon add material face {$_}") for @{$smoothingAngles{$smoothingAngle}};
		if (exists $preexistSmAngleTable{$smoothingAngle}){
			lxout("applying this material (already exists) : $preexistSmAngleTable{$smoothingAngle} to these polys' materials : @{$smoothingAngles{$smoothingAngle}}");
			lx("poly.setMaterial {$preexistSmAngleTable{$smoothingAngle}}");
		}else{
			if ( ($letterCount == 0) && ((keys %usedUpperCaseLetterPositions) == 0) ){
				lxout("applying this material : $materialNameToApply to these polys' materials : @{$smoothingAngles{$smoothingAngle}}");
				lx("poly.setMaterial {$materialNameToApply}");
				my @materialSel = lxq("query sceneservice selection ? advancedMaterial");
				lx("!!item.channel smAngle {$smoothingAngle} set {$materialSel[0]}");
				$letterCount++;
			}else{
				my $loop = 1;
				while ($loop == 1){
					if ($letterCount > $materialNameLength - 1){
						die("There aren't enough characters in this material name to support all the different smoothing angles needed.  You should reduce the number of smoothing angles used in this layer and try again.");
					}

					my $letterToCheck = substr($materialNameToApply,$letterCount,1);
					if ( (!exists $usedUpperCaseLetterPositions{$letterCount}) && ($letterToCheck =~ /[a-z]/) ){
						my $newMaterialName = $materialNameToApply;
						substr($newMaterialName,$letterCount,1) = uc(substr($newMaterialName,$letterCount,1));
						lxout("applying this material : $newMaterialName to these polys' materials : @{$smoothingAngles{$smoothingAngle}}");
						lx("poly.setMaterial {$newMaterialName}");
						my @materialSel = lxq("query sceneservice selection ? advancedMaterial");
						lx("!!item.channel smAngle {$smoothingAngle} set {$materialSel[0]}");
						$loop = 0;
					}

					$letterCount++;
				}
			}
		}
	}
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#VERIFY ITEM VISIBILITIES SUB (unhides all the item's collective parents)
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#usage : verifyItemVisibities(mesh001,mesh003);
sub verifyItemVisibities{
	my %verifiedAlreadyList;
	foreach my $id (@_){
		my $parent = lxq("query sceneservice item.parent ? {$id}");
		while ($parent ne ""){
			if ($verifiedAlreadyList{$parent} == 1){last;}
			$verifiedAlreadyList{$parent} = 1;
			lx("layer.setVisibility {$parent} 1");
			$parent = lxq("query sceneservice item.parent ? {$parent}");
		}
	}
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#QUICK DIALOG SUB v2.1
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE : quickDialog(username,float,initialValue,min,max);
sub quickDialog{
	if (@_[1] eq "yesNo"){
		lx("dialog.setup yesNo");
		lx("dialog.msg {$_[0]}");
		lx("dialog.open");
		if (lxres != 0){	die("The user hit the cancel button");	}
		return (lxq("dialog.result ?"));
	}else{
		if (lxq("query scriptsysservice userValue.isdefined ? seneTempDialog") == 1){
			lx("user.defDelete seneTempDialog");
		}
		lx("user.defNew name:[seneTempDialog] type:{$_[1]} life:[momentary]");		
		lx("user.def seneTempDialog username [$_[0]]");
		if (($_[3] != "") && ($_[4] != "")){
			lx("user.def seneTempDialog min [$_[3]]");
			lx("user.def seneTempDialog max [$_[4]]");
		}
		lx("user.value seneTempDialog [$_[2]]");
		lx("user.value seneTempDialog ?");
		if (lxres != 0){	die("The user hit the cancel button");	}
		return(lxq("user.value seneTempDialog ?"));
	}
}

#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#SHADER TREE TOOLS SUB (modded to use $sene_matRepairPath instead of $gameDir) (also modded to assume the correct ptyp)
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#HASH TABLE : 0=MASKID 1=MATERIALID   if $shaderTreeIDs{(all)} exists, that means there's some materials that effect all and should be nuked.
#PTAG : MASKID : (PTAG , MASKID , $PTAG) : returns the ptag mask group ID.
#PTAG : MATERIALID : (PTAG , MATERIALID , $PTAG) : returns the first materialID found in the ptag mask group.
#PTAG : MASKEXISTS : (PTAG , MASKEXISTS , $PTAG) : finds out if a ptag mask group exists or not.  0=NO 1=YES 2=YES,BUTNOMATERIALINIT
#PTAG : ADDIMAGE : (0=PTAG , 1=ADDIMAGE , 2=$PTAG , 3=IMAGEPATH , 4=EFFECT , 5=BLENDMODE , 6=UVMAP , 7=BRIGHTNESS , 8=INVERTGREEN , 9=AA) : adds an image to the ptag mask group w/ options.
#PTAG : DELCHILDTYPE : (PTAG , DELCHILDTYPE , $PTAG , TYPE) : deletes all the TYPE items in this ptag's mask group.
#PTAG : CREATEMASK : (PTAG , CREATEMASK , $PTAG) : create a material if it didn't exist before.
#PTAG : CHILDREN : (PTAG , CHILDREN , $PTAG , TYPE) : returns all the children from the ptag mask group.  Only returns children of a certain type if TYPE appended.
#GLOBAL : BUILDDBASE : (BUILDDBASE , ?FORCEUPDATE?) : creates the database to find a ptag's mask or material.  skips routine if the database isn't empty.  use forceupdate to force it again.
#GLOBAL : FINDPTAGFROMID : (FINDPTAGFROMID , ARRAYVALNAME , ARRAYNUMBER) : returns the hash key of the element you sent it and the pos in the array.
#GLOBAL : FINDALLOFTYPE : (FINDALLOFTYPE , TYPE) : returns all IDs that match the type.
#GLOBAL : TOGGLEALLOFTYPE : (TOGGLEALLOFTYPE , ONOFF , TYPE1 , TYPE2, ETC) : will turn everything of a type on or off
#GLOBAL : DELETEALLOFTYPE : (DELETEALLOFTYPE , TYPE) : deletes all of the selected type in the shader tree and updates database
#GLOBAL : DELETEALLALL : (DELETEALLALL) : deletes all the materials in the scene that effect ALL in the scene.
#NOTE : it's forcing all materials to have / and not \, so this isn't 100% legit if you have dupes.
sub shaderTreeTools{
	#lxout("[->] Running ShaderTreeTools sub <@_[0]> <@_[1]>");
	our %shaderTreeIDs;

	#----------------------------------------------------------
	#PTAG SPECIFIC :
	#----------------------------------------------------------
	if (@_[0] eq "ptag"){
		#MASK ID-------------------------
		if (@_[1] eq "maskID"){
			lxout("[->] Running maskID sub");
			shaderTreeTools(buildDbase);

			my $ptag = @_[2];
			$ptag =~ s/\\/\//g;
			return($shaderTreeIDs{$ptag}[0]);
		}
		#MATERIAL ID---------------------
		elsif (@_[1] eq "materialID"){
			lxout("[->] Running materialID sub");
			shaderTreeTools(buildDbase);

			my $ptag = @_[2];
			$ptag =~ s/\\/\//g;
			return($shaderTreeIDs{$ptag}[1]);
		}
		#MASK EXISTS---------------------
		elsif (@_[1] eq "maskExists"){
			lxout("[->] Running maskExists sub");
			shaderTreeTools(buildDbase);

			my $ptag = @_[2];
			$ptag =~ s/\\/\//g;
			if (exists $shaderTreeIDs{$ptag}){
				if (@{$shaderTreeIDs{$ptag}}[1] =~ /advancedMaterial/){
					return 1;
				}else{
					return 2;
				}
			}else{
				return 0;
			}
		}
		#ADD IMAGE-----------------------
		elsif (@_[1] eq "addImage"){
			lxout("[->] Running addImage sub");
			shaderTreeTools(buildDbase);

			if (@_[6] ne ""){lx("select.vertexMap @_[6] txuv replace");}

			my $ptag = @_[2];
			$ptag =~ s/\\/\//g;
			my $id = $shaderTreeIDs{$ptag}[0];
			lx("texture.new [@_[3]]");
			lx("texture.parent [$id] [-1]");

			if (@_[4] ne ""){lx("shader.setEffect @_[4]");}
			if (@_[7] ne ""){lx("item.channel imageMap\$max @_[7]");}
			if (@_[8] ne ""){lx("item.channel imageMap\$greenInv @_[8]");}
			if (@_[9] ne ""){lx("item.channel imageMap\$aa 0");  lx("item.channel imageMap\$pixBlend $pixBlend");}
		}
		#DEL CHILD TYPE-------------------
		elsif (@_[1] eq "delChildType"){
			lxout("[->] Running delChildType sub (deleting all @_[3]s)");
			shaderTreeTools(buildDbase);

			my $ptag = @_[2];
			$ptag =~ s/\\/\//g;
			my $id = $shaderTreeIDs{$ptag}[0];
			my @children = shaderTreeTools(ptag,children,$ptag,@_[3]);

			if (@children > 0){
				for (my $i=0; $i<@children; $i++){
					if ($i > 0)	{lx("select.subItem [@children[$i]] add textureLayer;render;environment;mediaClip;locator");}
					else		{lx("select.subItem [@children[$i]] set textureLayer;render;environment;mediaClip;locator");}
				}
				lx("texture.delete");
			}
		}
		#CREATE MASK---------------------
		elsif (@_[1] eq "createMask"){
			lxout("[->] Running createMask sub");
			shaderTreeTools(buildDbase);

			lx("select.subItem [@{$shaderTreeIDs{polyRender}}[0]] set textureLayer;render;environment;mediaClip;locator");
			lx("shader.create mask");
			my @masks = lxq("query sceneservice selection ? mask");
			lx("mask.setPTagType Material");
			lx("mask.setPTag {@_[2]}");
			lx("shader.create advancedMaterial");
			my @materials = lxq("query sceneservice selection ? advancedMaterial");
			@{$shaderTreeIDs{@_[2]}} = (@masks[0],@materials[0]);
		}
		#CHILDREN------------------------
		elsif (@_[1] eq "children"){
			lxout("[->] Running children sub");
			shaderTreeTools(buildDbase);

			my $ptag = @_[2];
			$ptag =~ s/\\/\//g;
			if (@_[3] eq ""){
				return (lxq("query sceneservice item.children ? $shaderTreeIDs{$ptag}[0]"));
			}else{
				my @children = lxq("query sceneservice item.children ? $shaderTreeIDs{$ptag}[0]");
				my @prunedChildren;
				foreach my $child (@children){
					if (lxq("query sceneservice item.type ? $child") eq @_[3]){
						push(@prunedChildren,$child);
					}
				}
				return (@prunedChildren);
			}
		}
	}

	#----------------------------------------------------------
	#GENERAL EDITING :
	#----------------------------------------------------------
	else{
		#BUILD DATABASE------------------
		if (@_[0] eq "buildDbase"){
			if (((keys %shaderTreeIDs) > 1) && ($_[1] ne "forceUpdate")){return;}
			if ($_[1] eq "forceUpdate"){%shaderTreeIDs = ();}

			lxout("[->] Running buildDbase sub");
			my $itemCount = lxq("query sceneservice item.n ? all");
			for (my $i=0; $i<$itemCount; $i++){
				my $type = lxq("query sceneservice item.type ? $i");

				#masks
				if ($type eq "mask"){
					if ((lxq("query sceneservice channel.value ? ptyp") eq "Material") || (lxq("query sceneservice channel.value ? ptyp") eq "")){
						my $id = lxq("query sceneservice item.id ? $i");
						my $ptag = lxq("query sceneservice channel.value ? ptag");
						$ptag =~ s/\\/\//g;

						if ($ptag eq "(all)"){
							push(@{$shaderTreeIDs{"(all)"}},$id);
						}else{
							my @children = lxq("query sceneservice item.children ? $i");
							@{$shaderTreeIDs{$ptag}}[0] = $id;
							foreach my $child (@children){
								if (lxq("query sceneservice item.type ? $child") eq "advancedMaterial"){
									@{$shaderTreeIDs{$ptag}}[1] = $child;
								}else{
								}
							}
						}
					}else{
						@{$shaderTreeIDs{$ptag}}[0] = "noPtag";
						push(@{$shaderTreeIDs{$ptag}},$id);
					}
				}

				#outputs
				elsif ($type eq "renderOutput"){
					my $id = lxq("query sceneservice item.id ? $i");
					push(@{$shaderTreeIDs{renderOutput}},$id);
				}

				#shaders
				elsif ($type eq "defaultShader"){
					my $id = lxq("query sceneservice item.id ? $i");
					push(@{$shaderTreeIDs{defaultShader}},$id);
				}

				#render output
				elsif ($type eq "polyRender"){
					my $id = lxq("query sceneservice item.id ? $i");
					push(@{$shaderTreeIDs{polyRender}},$id);
				}
			}
		}
		#FIND PTAG FROM ID---------------
		elsif (@_[0] eq "findPtag"){
			foreach my $key (keys %shaderTreeIDs){
				if (@{$shaderTreeIDs{$key}}[1] eq @_[@_[2]]){
					return $key;
				}
			}
		}
		#FIND ALL OF TYPE----------------
		elsif (@_[0] eq "findAllOfType"){
			my @list;
			for (my $i=0; $i<lxq("query sceneservice txLayer.n ? all"); $i++){
				if (lxq("query sceneservice txLayer.type ? $i") eq @_[1]){
					push(@list,lxq("query sceneservice txLayer.id ? $i"));
				}
			}
			return @list;
		}
		#TOGGLE ALL OF TYPE--------------
		elsif (@_[0] eq "toggleAllOfType"){
			for (my $i=0; $i<lxq("query sceneservice item.n ? all"); $i++){
				my $type = lxq("query sceneservice item.type ? $i");
				for (my $u=2; $u<$#_+1; $u++){
					if ($type eq @_[$u]){
						my $id = lxq("query sceneservice item.id ? $i");
						lx("select.subItem [$id] set textureLayer;render;environment");
						lx("item.channel textureLayer\$enable @_[1]");
					}
				}
			}
		}
		#DELETE ALL OF TYPE--------------
		elsif (@_[0] eq "delAllOfType"){
			my @deleteList;

			for (my $i=0; $i<lxq("query sceneservice txLayer.n ? all"); $i++){
				if (lxq("query sceneservice txLayer.type ? $i") eq @_[1]){
					my $id = lxq("query sceneservice txLayer.id ? $i");
					push(@deleteList,$id);

					if (@_[1] eq "mask"){
						my $ptag = shaderTreeTools(findPtag,$id,1);
						$ptag =~ s/\\/\//g;
						delete $shaderTreeIDs{$ptag};
					}elsif  (@_[1] eq "advancedMaterial"){
						my $ptag = shaderTreeTools(findPtag,$id,1);
						$ptag =~ s/\\/\//g;
						if ($ptag ne ""){delete @{$shaderTreeIDs{$ptag}}[1];}
					}
				}
			}
			foreach my $id (@deleteList){
				lx("select.subItem [$id] set textureLayer;render;environment");
				lx("texture.delete");
			}

		}
		#DELETE ALL (ALL) MATERIALS------
		elsif (@_[0] eq "deleteAllALL"){
			shaderTreeTools(buildDbase);
			my @deleteList;

			if (exists $shaderTreeIDs{"(all)"}){
				foreach my $id (@{$shaderTreeIDs{"(all)"}}){push(@deleteList,$id);}
				delete $shaderTreeIDs{"(all)"};
			}
			foreach my $key (keys %shaderTreeIDs){
				if (@{$shaderTreeIDs{$key}}[0] eq "noPtag"){
					for (my $i=1; $i<@{$shaderTreeIDs{$key}}; $i++){
						push(@deleteList,@{$shaderTreeIDs{$key}}[$i]);
					}
					delete $shaderTreeIDs{$key};
				}
			}

			if (@deleteList > 0){
				lxout("[->] : Deleting these materials because they're not assigned to one ptag :\n@deleteList");
				for (my $i=0; $i<@deleteList; $i++){
					if ($i > 0)	{	lx("select.subItem [@deleteList[$i]] add textureLayer;render;environment");}
					else		{	lx("select.subItem [@deleteList[$i]] set textureLayer;render;environment");}
				}
				lx("texture.delete");
			}
		}
	}
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#FIND MESH INSTANCE SOURCE (ver 1.2) (now supports proxies)
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#usage : my $sourceMeshID = findMeshInstSource($item) or die("$item is not a meshInst");
sub findMeshInstSource{
	if ( (lxq("query sceneservice item.type ? {$_[0]}") ne "meshInst") && (lxq("query sceneservice item.type ? {$_[0]}") ne "proxy") ){return 0;}
	my $currentItem = $_[0];

	while (1){
		my $source = 			lxq("query sceneservice item.source ? {$currentItem}");
		if ($source eq "")	{	return $currentItem;													}
		else				{	$currentItem = lxq("query sceneservice item.source ? {$currentItem}");	}
	}
}

##------------------------------------------------------------------------------------------------------------
##------------------------------------------------------------------------------------------------------------
#POPUP MULTIPLE CHOICE (ver 3) (forces return of your word choice because modo sometimes would return a number instead of word)
##------------------------------------------------------------------------------------------------------------
##------------------------------------------------------------------------------------------------------------
#USAGE : my $answer = popupMultChoice("question name","yes;no;maybe;blahblah",$defaultChoiceInt);
sub popupMultChoice{
	if (lxq("query scriptsysservice userValue.isdefined ? seneTempDialog2") == 1){lx("user.defDelete {seneTempDialog2}");	}
	lx("user.defNew name:[seneTempDialog2] type:[integer] life:[momentary]");
	lx("user.def seneTempDialog2 username [$_[0]]");
	lx("user.def seneTempDialog2 list {$_[1]}");
	lx("user.value seneTempDialog2 {$_[2]}");

	lx("user.value seneTempDialog2");
	if (lxres != 0){	die("The user hit the cancel button");	}
	
	my $answer = lxq("user.value seneTempDialog2 ?");
	if ($answer =~ /[^0-9]/){
		return($answer);
	}else{
		my @guiTextArray = split (/\;/, $_[1]);
		return($guiTextArray[$answer]);
	}
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

