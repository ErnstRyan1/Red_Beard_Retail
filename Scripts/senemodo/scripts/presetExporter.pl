#perl
#ver 1.01
#author : Seneca Menard
#This script is to take your current polygons and save them out to a new mesh preset.

my $sceneIndex = lxq("query sceneservice scene.index ? fg");
my $sceneName = lxq("query sceneservice scene.name ? fg");
my $sceneFile = lxq("query sceneservice scene.file ? fg");
my $prefixAlreadyAsked = 0;
my $prefix;

#open the dialog for the end filename
lx("dialog.setup fileSave");
lx("dialog.fileTypeCustom format:[sLXL] username:[LXL] loadPattern:[*.lxl] saveExtension:[lxl]");
lx("dialog.title {Preset to save}");
lx("dialog.open");
my $filePath = lxq("dialog.result ?");
if ($filePath eq ""){die("The user cancelled the save dialog window, so the script is being cancelled.");}

#copy the selection
if (lxq("select.typeFrom {polygon;item;vertex;edge} ?")){
	lx("select.copy");
}elsif( lxq( "select.typeFrom {item;vertex;edge;polygon} ?" )){
	my @meshCount = lxq("query sceneservice selection ? mesh");
	if (@meshCount < 1){die("There aren't any mesh items selected, so I'm cancelling the script.");}
	lx("transform.reset all");
	lx("select.drop polygon");
	lx("select.copy");
}else{
	lx("select.drop polygon");
	lx("select.copy");
}

#new scene
lx("scene.new");
lx("select.paste");
my $currentSceneIndex = lxq("query sceneservice scene.index ? fg");

#copy the images
my $dir;
my @dirNames = split(/\\/,$filePath);
my $fileName = pop(@dirNames);
$dir .= $_."\\" for @dirNames;
$prefix = $fileName;
$prefix =~ s/\..*//;

my $clipCount = lxq("query sceneservice clip.N ? fg");
for (my $i=0; $i<$clipCount; $i++){
	my $clipID = lxq("query sceneservice clip.id ? $i");
	my $clipFilePath = lxq("query sceneservice clip.refPath ? {$clipID}");
	my @clipDirNames = split(/\\/,$clipFilePath);
	my $clipFileName = pop(@clipDirNames);
	my $newFilePath = $dir.$clipFileName;
	#popup("clipFilePath = $clipFilePath\nnewFilePath = $newFilePath");
	if (-e $newFilePath){
		lxout("[->] : The image ($clipFileName) already exists in the preset dir : $dir");
		my $oldFileSize = -s $clipFilePath;
		my $oldFileDate = -M $clipFilePath;
		my $newFileSize = -s $newFilePath;
		my $newFileDate = -M $newFilePath;
		#lxout("oldFileSize = $oldFileSize");
		#lxout("newFileSize = $newFileSize");
		#lxout("=====================================");
		#lxout("oldFileDate = $oldFileDate");
		#lxout("newFileDate = $newFileDate\n\n");

		if (($oldFileSize == $newFileSize) && ($oldFileDate == $newFileDate)){
			lxout("[->] : The old file and new file are identical so I'm skipping the file copy\nold=$clipFilePath\nnew=$newFilePath");
		}elsif (($oldFileSize != $newFileSize) && ($oldFileDate == $newFileDate)){
			lxout("The old file and new file share the same modified date, but not the same file size.\nold=$clipFilePath\nnew=$newFilePath");
			my $answer = quickDialog("old = $clipFilePath\nnew = $newFilePath\n============================\nThe old file and new file share the same modified date, but not the same file size.\nDo you wish to save the file with a '$prefix' prefix?",yesNo);
			if ($answer eq "ok"){saveClipAs($clipID,$dir,$clipFileName);}
		}elsif (($oldFileSize == $newFileSize) && ($oldFileDate != $newFileDate)){
			lxout("[->] : The old file and new file share the same file size, but not the same modified date.\nold=$clipFilePath\nnew=$newFilePath");
			my $answer = quickDialog("old = $clipFilePath\nnew = $newFilePath\n============================\nThe old file and new file share the same file size, but not the same modified date.\nDo you wish to save the file with a '$prefix' prefix?",yesNo);
			if ($answer eq "ok"){saveClipAs($clipID,$dir,$clipFileName);}
		}else{
			lxout("[->] : The old file and new file don't share file size or date.\nold=$clipFilePath\nnew=$newFilePath");
			my $answer = quickDialog("old = $clipFilePath\nnew = $newFilePath\n============================\nThe old file and new file are totally different from one another.\nDo you wish to save the file with a '$prefix' prefix?",yesNo);
			if ($answer eq "ok"){saveClipAs($clipID,$dir,$clipFileName);}
		}
	}else{
		lxout("[->] : The image ($clipFileName) doesn't exist here : $dir");
		system "copy $clipFilePath $newFilePath";
	}
}


#save the LXL and close the current scene.
#lx("select.type item");
#lx("mesh.presetSave filename:{$filePath}");
#lx("scene.close");









#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#SAVE CLIP AS (with prefix) SUB
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE : saveClipAs($clipID,$dir,$file,);
sub saveClipAs{
	my $format = @_[2];
	my $fileName = @_[1] . $prefix . "_" . @_[2];
	$format =~ s/.*\.//;
	$format = uc($format);

	lx("select.subItem [@_[0]] set mediaClip");
	lx("clip.saveAs fileName:{$fileName}");
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#QUICK DIALOG SUB v2.1 (modded to not die if user press no to yesno)
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE : quickDialog(username,float,initialValue,min,max);
sub quickDialog{
	if ($_[1] eq "yesNo"){
		lx("dialog.setup yesNo");
		lx("dialog.msg {$_[0]}");
		lx("dialog.open");
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
