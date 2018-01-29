#perl

#This script looks at the name of the currently loaded scene and then checks the autosave dir to see if there are any in there that are newer. if so, it'll load it.
srand;
my %dirResult;
my @matchFilePatterns = ("\\\.lxo");
my @ignoreFilePatterns = ();
my @ignoreDirs = ();

my $file = lxq("query sceneservice scene.file ? selected");
my $autosaveDir = lxq("pref.value autosave.directory ?");
lxout("autosaveDir = $autosaveDir");
my @fileStats = stat($file); #         ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks)
my $modTime = $fileStats[9];
lxout("modTime = $modTime");

#get file name 
$file =~ s/\\/\//g;
my @path = split(/\//,$file);
my $name = $path[-1];
$name =~ s/\..*//;
lxout("name = $name");

#get list of LXO files in autosave dir
dir($autosaveDir,\@ignoreDirs,\@matchFilePatterns,\@ignoreFilePatterns);

foreach my $filename (keys %dirResult){
	if ($filename =~ /[0-9]_$name\./){
		my @currFileStats = stat($filename);
		my $currModTime = $currFileStats[9];
		lxout("currModTime = $currModTime <> $filename");
		if ($currModTime > $modTime){
			popup("This file is newer than the one you have open so I'm loading it : $filename");

			#close scene, back up to temp dir, delete it, then load up backup and save over original name
			lx("scene.close");
			$file =~ s/\//\\/g;
			my $newName = $autosaveDir . "\\" . $name . "_autosave_" . int(rand(10000000000)) . ".lxo";
			system("copy \"$file\" \"$newName\"");
			unlink $file;
			lx("scene.open {$filename}");
			lx("scene.saveAs {$file} \$LXOB false");
			return;
		}else{
			lxout("older");
		}
	}
	
	
}
popup("There were no files found that are newer than this one");








#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#BUILD THE EXCLUSION LIST FOR DIR ROUTINE
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
my %exclusionList;
sub buildExclusionList{
	open (exclusionFile, "<@_[0]") or die("I couldn't find the exclusion file");
	while ($line = <exclusionFile>){
		$line =~ s/\n//;
		$exclusionList{$line} = 1;
	}
	close(exclusionFile);
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#SEE IF ARG0 MATCHES ANY PATTERN IN ARG1ARRAYREF
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE : if (matchPattern(name,\@checkArray,-1)){lxout("yes");}
sub matchPattern{
	if (@_[2] != -1){
		foreach my $name (@{@_[1]}){
			if (@_[0] =~ /$name/i){return 1;}
		}
		return 0;
	}else{
		foreach my $name (@{@_[1]}){
			if (@_[0] =~ /$name/i){return 0;}
		}
		return 1;
	}
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#DIR SUB (ver 1.2 special char bugfix)
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#requirements 1 : needs buildExclusionList sub if you want to use an external exclusion file.  Also, declare %exclusionList as global
#requirements 2 : needs matchPattern sub
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

	#--------------------------------------------------------------------------------------------
	#SORT THE NAMES TO BE DIRS OR MODELS
	#--------------------------------------------------------------------------------------------
	foreach my $name (@files){
		#IGNORE . and .. (and i can't del the first two arr chars because '(' comes before .)
		if ($name =~ /^\.+$/){next;}

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
	#RUN THE SUBROUTINE ON EACH DIR FOUND.
	#--------------------------------------------------------------------------------------------
	foreach my $dir (@directories){
		&dir($dir,@_[1],@_[2],@_[3]);
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
