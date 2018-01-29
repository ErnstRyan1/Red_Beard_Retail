#perl
#BATCH MATERIAL RENAMER
#VERSION : 1.2
#AUTHOR : Seneca Menard
#This script is for loading up a number of models and doing a batch material rename on all of them.  It'll then save and close them as well.

#(11-17-09 fix) : now uses the material.reassign command instead of the manual group/ptag swaps.  Also, it makes the file readable if it wasn't already.  I should probably make it so perforce can check out the file, but i'll do that later.
#(11-2-10 fix) : fixed a syntax change for 501



#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#SETUP
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
foreach my $arg (@ARGV){
	if ($arg =~ /newFiles/i)	{our $newFiles = 1;}
}


my $modoVer = lxq("query platformservice appversion ?");
if ($modoVer > 500){our $lwoType = "\$NLWO2";} else {our $lwoType = "\$LWO2";}
my $runOnce = 0;
my $textRemove;
my $textAdd;

#file dialog window
lx("dialog.setup fileOpenMulti");
if ($modoVer > 300){lx("dialog.fileTypeCustom format:[sml] username:[Model to load] loadPattern:[*.lxo;*.lwo;*.obj] saveExtension:[lxo]");}
else{				lx("dialog.fileType scene");}
lx("dialog.title [Select some models to replace material names on...]");
lx("dialog.open");
my @files = lxq("dialog.result ?");
if (@files < 1){die("You didn't pick any files so I'm canceling the script");}

#user input for the FIND/REPLACE
my $oldName = quickDialog("type in the OLD text\nyou want to replace:",string,"","","");
my $newName = quickDialog("type in the NEW text\nyou want to use:",string,"","","");
$oldName =~ s/\\/\//g;
$newName =~ s/\\/\//g;
$oldName =~ s/\/\B//g;
$newName =~ s/\/\B//g;
lxout("oldName = $oldName");
lxout("newName = $newName");


#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#go through all the files and perform the batch renaming
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
foreach my $file (@files){
	$file =~ s/\\/\//g;
	if (-e $file){
		#temp: make the file readable. (i need to put in a p4 checkout as well)
		unless (-w $file){system qx/attrib -r $file/;}

		my @printName1;
		my @printName2;

		#open the file
		lx("!!scene.open {$file};") or die("Could not open file : $file");
		my $sceneName = lxq("query sceneservice scene.name ? main");
		my $mainlayer = lxq("query layerservice layers ? main");
		my $txLayers = lxq("query sceneservice txLayer.n ? all");
		my @renameList;

		#rename all the materials
		for (my $i=0; $i<$txLayers; $i++){
			if (lxq("query sceneservice txLayer.type ? $i") eq "mask"){
				my $ptag = lxq("query sceneservice channel.value ? ptag");
				my $ptagModSlashes = $ptag;
				$ptagModSlashes =~ s/\\/\//g;
				if ($ptagModSlashes =~ /$oldName/i){
					my $newPtag = $ptag;
					$newPtag =~ s/\\/\//g;
					$newPtag =~ s/$oldName/$newName/gi;
					lx("material.reassign {$ptag} {$newPtag}");
					push(@printName1,$ptag);
					push(@printName2,$newPtag);
				}
			}
		}

		#print what's been changed
		lxout("============================================\nfile = $file\n============================================");
		for (my $i=0; $i<@printName1; $i++){
			lxout("      renamed @printName1[$i] to @printName2[$i]");
		}

		#save and close the scene
		if ($newFiles == 0){
			lx("scene.save");
			lx("!!scene.close");
		}else{
			my $sceneFileName = lxq("query sceneservice scene.file ? current");
			my $fileName = "";
			my @dirs = split(/[\/\\]/, $sceneFileName);
			if ($runOnce == 0){$textRemove = quickDialog("Filename text you'd\nlike to replace:",string,@dirs[-1],"","");}
			if ($runOnce == 0){$textAdd = quickDialog("Text you'd like \nto replace it with:",string,"","","");}
			@dirs[-1] =~ s/$textRemove/$textAdd/;
			for (my $i=0; $i<$#dirs; $i++){$fileName .= @dirs[$i] . "\\";}
			$fileName .= @dirs[-1];
			if ($runOnce == 0){popup("Does this look correct ?\n$fileName");}
			$runOnce = 1;

			lx("!!scene.saveAs [$fileName] {$lwoType} [True]");
			lx("!!scene.close");
		}
	}else{
		lxout("file doesn't exist : $file");
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
