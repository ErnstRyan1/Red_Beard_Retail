#perl
#version 1.56
#author : Seneca Menard
#This script is to repair the materials in a scene.  It does a number of things :
# 1 : it goes through all ptags and masks and makes them use / instead of \
# 2 : it goes through all ptags and masks and gets rid of duplicates, including upper/lower case variations
# 3 : it goes through all ptags and masks and tries to force them to have the exact case layouts as the original image file's name.
# 4 : it goes through all masks and deletes the ones that aren't being used.

#(6-18-08 fix) : found a small bug with missing brackets that would cause problems with items that had names with more than one word in it.
#(9-12-08 fix) : found a small bug because of a subroutine checking subdirs when it doesn't need to.
#(9-29-08 fature) : The script now deletes all unused images from the shader tree and clips window.
#(3-10-09 fix) : noticed that material.n ? isn't updating properly and so i put a hack fix around that.

lxout("running");
#=========================================================================
# : 0 : SETUP + SHOW ALL LAYERS
#=========================================================================
my $allowMultipleWords = 0;
my $allowCaseVariation = 0;
my $allowNonPtagMask = 0;
my $allowPtagNulls = 0;
my $gameDir = "W:\/Rage\/base\/";
my %dirResult;
my @ignoreDirs = (work,temp);
my @ignoreFilePatterns;


my @layers = lxq("query layerservice layers ? all");
my @fgLayers = lxq("query layerservice layers ? fg");
my @bgLayers = lxq("query layerservice layers ? bg");
$_ = lxq("query layerservice layer.id ? {$_}") for @layers;
$_ = lxq("query layerservice layer.id ? {$_}") for @fgLayers;
$_ = lxq("query layerservice layer.id ? {$_}") for @bgLayers;
lx("select.subItem {$_} add mesh;meshInst;camera;light;txtrLocator;backdrop;groupLocator [0] [1]") for @layers;
lx("select.type polygon");
lx("unhide");

#=========================================================================
# : 1) rename all ptags properly
#=========================================================================
lxout("[->] (1) : RENAMING PTAGS--------------------");
my $materialCount = lxq("query layerservice material.n ? all");
for (my $i=0; $i<$materialCount; $i++){
	my $ptagName = lxq("query layerservice material.name ? $i");
	my $modifiedPtagName = $ptagName;

	# : multiple words
	if (($allowMultipleWords == 0) && ($modifiedPtagName =~ /\s/)){
		lxout("     PTAG : <--$modifiedPtagName--> had multiple words, so converting to:");
		$modifiedPtagName =~ s/\s.*//;
		lxout("         $modifiedPtagName");
	}
	# : ' (2)'
	elsif ($modifiedPtagName =~ /\s\(\d/){
		lxout("     PTAG : <--$modifiedPtagName--> had ' (2)' in it, so converting to:");
		$modifiedPtagName =~ s/\s*\(\d.*//;
		lxout("         $modifiedPtagName");
	}
	# : ' 2'
	elsif ($modifiedPtagName =~ /\s\d/){
		lxout("     PTAG : <--$modifiedPtagName--> had ' 2' in it, so converting to:");
		$modifiedPtagName =~ s/\s*\d*.*//;
		lxout("         $modifiedPtagName");
	}
	# : \
	if ($modifiedPtagName =~ /\\/){
		lxout("     PTAG : <--$modifiedPtagName--> had '/' in it, so converting to:");
		$modifiedPtagName =~ s/\\/\//g;
		lxout("         $modifiedPtagName");
	}
	# : case variation (temp : force everything to be lower case because checking the case structure of every dir would be a mess)
	if (($allowCaseVariation == 0) && ($modifiedPtagName =~ /[A-Z]/)){
		lxout("     PTAG : <--$modifiedPtagName--> has uppercase letters.  Converting to:");
		$modifiedPtagName = lc($modifiedPtagName);
		lxout("         $modifiedPtagName");
	}
	#actually rename the ptag now
	if ($ptagName ne $modifiedPtagName){
		lx("poly.renameMaterial [$ptagName] [$modifiedPtagName]");
	}
}

#=========================================================================
# : 2) remove void masks
#=========================================================================
lxout("[->] (2) : DELETING NULL MASKS--------------------");
my %maskList;
my %ptagList;
my %deleteMasks;
my $txLayerCount = lxq("query sceneservice txLayer.n ? all");
$materialCount = lxq("query layerservice material.n ? all");
for (my $i=0; $i<$materialCount; $i++){$maskList{lxq("query layerservice material.name ? $i")} = 1;}

for (my $i=0; $i<$txLayerCount; $i++){
	if (lxq("query sceneservice txLayer.type ? $i") eq "mask"){
		my $id = lxq("query sceneservice txLayer.id ? $i");
		my $name = lxq("query sceneservice txLayer.name ? $i");
		my $ptag = lxq("query sceneservice channel.value ? ptag");

		# : not using ptag
		if (($allowNonPtagMask == 0) && (lxq("query sceneservice channel.value ? ptyp") ne "Material")){
			lxout("     MASK : $name : is not using a ptag so I'm deleting it.");
			$deleteMasks{$id} = 1;
		}
		# : ptag nulls
		elsif ($allowPtagNulls == 0){
			if ($maskList{$ptag} != 1){
				lxout("     MASK : $name : is using a ptag that no polys are using so I'm deleting it.");
				$deleteMasks{$id} = 1;
			}elsif ($ptag eq ""){
				lxout("     MASK : $name : is not using any ptag so I'm deleting it.");
				$deleteMasks{$id} = 1;
			}
		}
		# : ptag dupe setup
		my $modifiedPtagName = $ptag;
		$modifiedPtagName =~ s/\\/\//g;
		$modifiedPtagName = lc($modifiedPtagName);
		if ($allowMultipleWords == 0)			{$modifiedPtagName =~ s/\s.*//;			}
		elsif ($modifiedPtagName =~ /\s\(\d/)	{$modifiedPtagName =~ s/\s*\(\d.*//;	}
		elsif ($modifiedPtagName =~ /\s\d/)		{$modifiedPtagName =~ s/\s*\d*.*//;		}
		push(@{$ptagList{$modifiedPtagName}},$id);
	}
}
#delete the duplicates
foreach my $key (keys %ptagList){
	if (@{$ptagList{$key}} > 1){
		for (my $i=1; $i<@{$ptagList{$key}}; $i++){
			my $name = lxq("query sceneservice txLayer.name ? @{$ptagList{$key}}[$i]");
			lxout("     MASK : $name : is a duplicate, so I'm deleting it.");
			lx("select.subItem {@{$ptagList{$key}}[$i]} set textureLayer;render;environment;mediaClip;locator");
			#popup("deleting this ptag : $name");
			lx("texture.delete");
			delete $deleteMasks{@{$ptagList{$key}}[$i]};
		}
	}
}
foreach my $material (keys %deleteMasks){
	my $name = lxq("query sceneservice txLayer.name ? $material");
	lxout("     MASK : $name : was either not being used or had no ptag assigned so I'm deleting it.");
	lx("select.subItem {$material} set textureLayer;render;environment;mediaClip;locator");
	#popup("deleting this ptag : $name");
	lx("texture.delete");
}

#=========================================================================
# : 3) find ptags without materials
#=========================================================================
lxout("[->] (3) : CREATING MISSING MATERIALS--------------------");
$materialCount = lxq("query layerservice material.n ? all");
lxout("materialCount = $materialCount");
for (my $i=0; $i<$materialCount; $i++){
	my $name = lxq("query layerservice material.name ? $i");
	if ($name ne ""){
		my $nameMod = $name;
		$nameMod =~ s/\\/\//g;
		$nameMod = lc($nameMod);
		#popup("nameMod=$nameMod <> @{$ptagList{$nameMod}}");
		if (@{$ptagList{$nameMod}} < 1){
			lxout("     MASK : $name : does not exist while the ptag does, so I'm creating it.");
			lx("select.itemType render");
			lx("shader.create mask");
			lx("mask.setPTagType Material");
			lx("item.name {$name}");
			lx("mask.setPTag {$name}");
			lx("shader.create advancedMaterial");
		}
	}
}

#=========================================================================
# : 4) pretty up mask names
#=========================================================================
lxout("[->] (4) : PRETTYING UP THE MASK NAMES--------------------");
$txLayerCount = lxq("query sceneservice txLayer.n ? all");
for (my $i=0; $i<$txLayerCount; $i++){
	if (lxq("query sceneservice txLayer.type ? $i") eq "mask"){
		my $name = lxq("query sceneservice txLayer.name ? $i");
		my $ptag = lxq("query sceneservice channel.value ? ptag");
		if ($name ne $ptag){
			lxout("     MASK : '$name' : does not precisely match it's assigned ptag.  Converting to '$ptag'");
			my $id = lxq("query sceneservice txLayer.id ? $i");
			lx("select.subItem {$id} set textureLayer;render;environment;mediaClip;locator");
			lx("item.name {$ptag}");
		}
	}
}

#=========================================================================
# : 5) delete all unused texture locators in the scene.
#=========================================================================
lxout("[->] (5) : DELETING UNUSED TEXTURE LOCATORS--------------");
my $items = lxq("query sceneservice item.n ? all");
my @foundItems;
for (my $i=0; $i<$items; $i++){
	if (lxq("query sceneservice item.type ? $i") eq "txtrLocator"){
		my $name = lxq("query sceneservice item.name ? $i");
		if ($name =~ /(none)/i){
			push(@foundItems,lxq("query sceneservice item.id ? $i"));
			lxout("     deleting : $name");
		}
	}
}

if (@foundItems > 0){
	lx("select.drop item");
	foreach my $id (@foundItems){lx("select.subItem {$id} add mesh;meshInst;camera;light;txtrLocator;backdrop;groupLocator;locator;deform;locdeform 0 0");}
	lx("item.delete xfrmcore");
}

#=========================================================================
# : 6) delete all unused clips and all unused images in the shader tree.
#=========================================================================
lxout("[->] (4) : DELETING UNUSED CLIPS FROM THE CLIPS LIST-------");
$txLayerCount = lxq("query sceneservice txLayer.n ? all");
my %txLayerClipList;
for (my $i=0; $i<$txLayerCount; $i++){
	if (lxq("query sceneservice txLayer.type ? $i") eq "imageMap"){
		my $name = lxq("query sceneservice txLayer.name ? $i");
		if ($name =~ /Image: \(none\)/){
			my $id = lxq("query sceneservice txLayer.id ? $i");
			lx("select.subItem {$id} set textureLayer;render;environment");
			lxout("     deleting this unused shader tree image : $name");
			lx("!!texture.delete");
			$i--;
		}else{
			$name =~ s/Image: //;
			$txLayerClipList{$name} = 1;
		}
	}
}

my $clipCount = lxq("query layerservice clip.n ? all");
my $selType = "set";
for (my $i=0; $i<$clipCount; $i++){
	my $id = lxq("query sceneservice clip.id ? $i");
	my $name = lxq("query layerservice clip.name ? $i");
	if ($txLayerClipList{$name} != 1){
		lx("select.subItem {$id} $selType mediaClip");
		lxout("     deleting clip : $name");
		$selType = "add";
	}
}
if ($selType eq "add"){lx("!!clip.delete");}

#=========================================================================
# : 7) restore layer visibility
#=========================================================================
#restore layer visibility
for (my $i=0; $i<@fgLayers; $i++){
	if ($i != 0){lx("select.subItem {@fgLayers[$i]} add mesh;meshInst;camera;light;txtrLocator;backdrop;groupLocator [0] [1]");}
	else		{lx("select.subItem {@fgLayers[$i]} set mesh;meshInst;camera;light;txtrLocator;backdrop;groupLocator [0] [1]");}
}
lx("layer.setVisibility [$_] [1] [1]") for @bgLayers;



















#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#DIR SUB (modded to remove subdir checking)
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#requirements 1 : needs BUILDEXCLUSIONLIST sub if you want to use an external exclusion file.  Also, declare %exclusionList as global
#requirements 2 : needs MATCHPATTERN sub
#requirements 3 : Declare %dirResult as global so this routine can be used multiple times and add to that hash table.
#USAGE : dir($checkDir,\@ignoreDirs,\@matchFilePatterns,\@ignoreFilePatterns);
sub dir{
	#get the name of the current dir.
	my $currentDir = @_[0];
	my @tempCurrentDirName = split(/\//, $currentDir);
	my $tempCurrentDirName = @tempCurrentDirName[-1];
	my @directories;

	#open the current dir and sort out it's files and folders.
	opendir($currentDir,$currentDir) || die("Cannot opendir $currentDir");
	my @files = (sort readdir($currentDir));
	shift(@files);
	shift(@files);

	#--------------------------------------------------------------------------------------------
	#SORT THE NAMES TO BE DIRS OR MODELS
	#--------------------------------------------------------------------------------------------
	foreach my $name (@files){
		#LOOK FOR DIRS
		if (-d $currentDir . "\/" . $name){
			if (matchPattern($name,@_[1],-1)){	push (@directories,$currentDir . "\/" . $name);		}
		}

		#LOOK FOR FILES
		elsif ((matchPattern($name,@_[2])) && ($exclusionList{$currentDir . "\/" . $name} != 1) && (matchPattern($name,@_[3],-1))){
			$dirResult{$currentDir . "\/" . $name} = 1;
		}
	}

	#--------------------------------------------------------------------------------------------
	#RUN THE SUBROUTINE ON EACH DIR FOUND. (modded)
	#--------------------------------------------------------------------------------------------
	#foreach my $dir (@directories){
	#	&dir($dir,@_[1],@_[2],@_[3]);
	#}
}

#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#BUILD THE EXCLUSION LIST FOR DIR ROUTINE
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
my %exclusionList;
sub buildExclusionList{
	open (exclusionFile, "<@_[0]") or die("I couldn't find the exclusion file");
	while ($line = <exclusionFile>){
		$line =~ s/\n//;
		$exclusionList{$line} = 1;
	}
	close(exclusionFile);
}

#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#SEE IF ARG0 MATCHES ANY PATTERN IN ARG1ARRAYREF  --MODDED TO INCLUDE WORD BOUNDARIES!!-- TEMP!!
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#USAGE : if (matchPattern(name,\@checkArray,-1)){lxout("yes");}
sub matchPattern{
	if (@_[2] != -1){
		foreach my $name (@{@_[1]}){
			if (@_[0] =~ /\b$name/i){return 1;}
		}
		return 0;
	}else{
		foreach my $name (@{@_[1]}){
			if (@_[0] =~ /\b$name/i){return 0;}
		}
		return 1;
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

