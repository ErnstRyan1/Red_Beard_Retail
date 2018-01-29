#perl
#ver 0.951
#author : Seneca Menard

use P4;
my $p4 = new P4;
$p4->Connect() or print( "Failed to connect to Perforce Server" );
my $p4_connected = $p4->IsConnected();
if ($p4_connected == 0){
	print("You're not logged into perforce, so I'm cancelling the script.\n");
	my $response = <STDIN>;
	return;
}

my %exclusionList;
my %dirResult;
my $clientName = $p4->GetClient();
my $clientPathName = lc($p4->GetClient());

my @p4InfoTablePointer = $p4->RunInfo();
my $workspaceRoot = ${$p4InfoTablePointer[0]}{"clientRoot"};
$workspaceRoot =~ s/\\/\//g;
$workspaceRoot =~ s/\/$//;

#--------------------------------------------------------------------------
#SCRIPT ARGUMENTS
#--------------------------------------------------------------------------
foreach my $arg (@ARGV){
	if 		($arg =~ /revertMissingFiles/i)			{	our $revertMissingFiles = 1;											}
	elsif	($arg =~ /searchForNewFiles/i)			{	our $searchForNewFiles = 1;												}
	elsif	($arg =~ /ignoreDirs:/i)				{	our @ignoreDirs = prepIgnoreDirTextCvar($arg);							}
	elsif	($arg =~ /howManyDaysAgo/i)				{	our $daysAgoMax = prepHowManyDaysAgoCvar($arg);							}
	elsif	(($arg =~ /^-help$/i) || ($arg =~ /^help$/i) || ($arg =~ /^-h$/i) || ($arg =~ /^-?$/i))	{	&printHelpInfo;			}
	elsif	($arg =~ /delDeleteChangeList/i)		{	our $delDeleteChangeList = 1;											}
	elsif	($arg =~ /revertServerDeletedFiles/i)	{	our $revertServerDeletedFiles = 1;										}
	elsif	($arg =~ /backupFiles/i)				{	our $backupFiles = 1;													}
	elsif	($arg =~ /searchTool/i)					{	our $searchTool = 1;														}
	elsif	($arg =~ /dir=/i)						{	our $backupDirPath = $arg;												}
	else											{	our $mainDir = $arg;													}
}

#--------------------------------------------------------------------------
#NOW RUN THE ROUTINES
#--------------------------------------------------------------------------
if ($revertMissingFiles == 1){
	&revertMissingFiles;
}elsif ($searchForNewFiles == 1){
	&searchForNewFiles;
}elsif ($delDeleteChangeList == 1){
	&delDeleteChangeList;
}elsif ($revertServerDeletedFiles == 1){
	&revertServerDeletedFiles;
}elsif ($backupFiles == 1){
	&backupFiles;
}elsif ($searchTool == 1){
	&searchTool;
}

#end script
$p4->Disconnect();













#----------------------------------------------------------------------------------------------------------------------------------------------------
#----------------------------------------------------------------------------------------------------------------------------------------------------
#---------------------------------------------------------------------SUBROUTINES--------------------------------------------------------------------
#----------------------------------------------------------------------------------------------------------------------------------------------------
#----------------------------------------------------------------------------------------------------------------------------------------------------

#--------------------------------------------------------------------------
#DELETE ALL NETWORK FILES IN THE DELETE CHANGELIST
#--------------------------------------------------------------------------
sub searchTool{
	print("\n=============================================\nType in the dir you wish to do a search in: \n=============================================\nDir : ");
	my $dir = <STDIN>;
	chomp($dir);
	$dir =~ s/\\/\//g;
	if (!-d $dir){die("The dir you typed in doesn't exist, so I'm cancelling the script\n");my $blah = <STDIN>;}

	print("\n=============================================\nType in the search filter you'd like to use: \n=============================================\nFilter : ");
	my $filter = <STDIN>;
	chomp($filter);
	if ($filter eq ""){die("The filter you typed in is blank and so I'm cancelling the script\n");my $blah = <STDIN>;}

	print("\n=============================================\nDo you wish to recurse dirs: \n=============================================\nYes/No : ");
	my $recurse = <STDIN>;
	chomp($recurse);
	if ($recurse eq ""){die("The recurse option you typed in is blank and so I'm cancelling the script\n");my $blah = <STDIN>;}
	if (($recurse =~ /y/i) || ($recurse =~ /1/i)){$recurse = "recurseDirs";}else{$recurse = "dontRecurseDirs";}

	print("\n=============================================\nWhat do you wish to perform: (type in number)\n=============================================\n1 : checkout\n2 : mark for add\n3 : mark for delete\n4 : revert\n\nOperation # : ");
	my $operation = <STDIN>;
	chomp($operation);
	if ($operation !~ /[1-4]/){die("The operation you typed in is not between 1 and for so i'm cancelling the script\n");my $blah = <STDIN>;}
	if		($operation == 1)	{	$operation = "edit";		}
	elsif	($operation == 2)	{	$operation = "add";		}
	elsif	($operation == 3)	{	$operation = "delete";	}
	elsif	($operation == 4)	{	$operation = "revert";	}

	my @ignoreDirs = ();
	my @matchFilePatterns = ($filter);
	my @ignoreFilePatterns = ();
	dir2($dir,\@ignoreDirs,\@matchFilePatterns,\@ignoreFilePatterns,$recurse);
	print("sdlikfgdslkfj");

	foreach my $file (keys %dirResult){
		print("$file\n");
	}

	if ((keys %dirResult) > 0){
		print "\n=============================================\nAre you sure you wish to $operation these files?\n=============================================\nYes/No : ";
		my $response = <STDIN>;
		if ($response =~ /y/i){
			print "$operation ing files.\n";
			if		($operation eq "edit")		{	foreach my $file (keys %dirResult){$p4->RunEdit($file);}	}
			elsif	($operation eq "add")		{	foreach my $file (keys %dirResult){$p4->RunAdd($file);}		}
			elsif	($operation eq "delete")	{	foreach my $file (keys %dirResult){$p4->RunDelete($file);}	}
			elsif	($operation eq "revert")	{	foreach my $file (keys %dirResult){$p4->RunRevert($file);}	}
		}
	}
}


#--------------------------------------------------------------------------
#BACKUP CHECKED OUT FILES TO SPECIFIED DIR
#--------------------------------------------------------------------------
sub backupFiles{
	my @openedFilesRefs = $p4->RunOpened();
	my @filesToBackup;

	#find the dir to save it to.
	if (@ARGV[1] !~ /[a-z]/i){
		print "============================================================\n";
		print "============================================================\n";
		print "ERROR a dir is supposed to be specified. ie : 'dir=C:/p4_backup'\nIs it ok to use the default directory? : C:/p4_backup\n";
		print "============================================================\n";
		print "============================================================\n";
		print "Type yes or no :";

		my $response = <STDIN>;
		if ($response !~ /y/i){die;}
		$backupDirPath = "C:\/p4_backup";
	}
	$backupDirPath =~ s/dir=//i;
	dir_makeSureExists($backupDirPath);

	#find which was the last backup dir used :
	my @directories;
	opendir($backupDirPath,$backupDirPath) || die("Cannot opendir $backupDirPath");
	my @files = (sort readdir($backupDirPath));
	my $foundDir = 0;
	my $finalDir;
	shift(@files);
	shift(@files);

	for (my $i=$#files; $i>-1; $i--){
		if ( (-d $backupDirPath . "\/" . $files[$i]) && ($files[$i] =~ /backup_[0-9]+/i) ){
			my $dirNumber = $files[$i];
			$dirNumber =~ s/[^0-9]//g;
			$dirNumber = $dirNumber + 1;
			$_ = $dirNumber;
			my $count = s/.//g;
			if ($count == 1){$dirNumber = "0" . $dirNumber;}
			$finalDir = $backupDirPath . "\/backup_" . $dirNumber;
			dir_makeSureExists($finalDir);
			$foundDir = 1;
			last;
		}
	}

	if ($foundDir == 0){
		$finalDir = $backupDirPath . "\/backup_01";
		dir_makeSureExists($finalDir);
	}

	#find default changelist files
	foreach my $hashRef (@openedFilesRefs){
		my $file = lc($$hashRef{clientFile});
		if ($$hashRef{change} eq "default"){
			$file =~ s/\/\/$clientPathName/$workspaceRoot/;
			$file =~ s/\//\\/g;
			push(@filesToBackup,$file);
			print "$file\n";
		}
	}

	#copy the files
	foreach my $file (@filesToBackup){
		system("xcopy /c /q /d /r \"$file\" \"$finalDir\"");
	}
}


#--------------------------------------------------------------------------
#REVERT SERVER DELETED FILES THAT ARE MARKED AS ADD IN DEFAULT CHANGELIST
#--------------------------------------------------------------------------
sub revertServerDeletedFiles{
	my @openedFilesRefs = $p4->RunOpened();
	my @filesToRevert;

	foreach my $hashRef (@openedFilesRefs){
		if (($$hashRef{haveRev} ne "none") && ($$hashRef{action} eq "add")){
			my $file = lc($$hashRef{clientFile});
			$file =~ s/\/\/$clientPathName/$workspaceRoot/;
			$file =~ s/\//\\/g;
			push(@filesToRevert,$file);
			print "$file\n";
		}
	}

	if (@filesToRevert > 0){
		print "Are you sure you wish to revert these server-deleted files that are marked for add?";
		my $response = <STDIN>;
		if ($response =~ /y/i){
			print "Deleting files.\n";
			$p4->RunRevert($_) for @filesToRevert;
			system "del \/F \"$_\"" for @filesToRevert;
		}
	}else{
		print "There were no files marked for add that didn't exist on the server found in a changelist with the word 'default' in it.\n";
	}
}

#--------------------------------------------------------------------------
#DELETE ALL LOCAL FILES IN THE DELETE CHANGELIST
#--------------------------------------------------------------------------
sub delDeleteChangeList{
	my @changeLists = $p4->RunChangelists("-c", "$clientName", "-s", "pending");
	foreach my $hashRef (@changeLists){
		my @localFilesToDelete;
		if ($$hashRef{desc} =~ /delete/i){
			my @openedFilesRefs = $p4->RunOpened("-c", $$hashRef{change});
			my @filesToRevert;
			foreach my $hashRef (@openedFilesRefs){
				my $file = lc($$hashRef{clientFile});
				$file =~ s/\/\/$clientPathName/$workspaceRoot/;
				$file =~ s/\//\\/g;
				push(@filesToRevert,$file);
				print "$file\n";
			}
			if (@filesToRevert > 0){
				print "Are you sure you wish to locally delete these files?";
				my $response = <STDIN>;
				if ($response =~ /y/i){
					print "Deleting files.\n";
					$p4->RunRevert($_) for @filesToRevert;
					system "del \/F \"$_\"" for @filesToRevert;
				}
			}else{
				print "There were no files found in a changelist with the word 'delete' in it.\n";
			}
		}
	}
}

#--------------------------------------------------------------------------
#PREP IGNOREDIRTEXT CVAR SUB
#--------------------------------------------------------------------------
sub prepIgnoreDirTextCvar{
	my $ignoreDirText = @_[0];
	$ignoreDirText =~ s/ignoreDirs://i;
	my @tempDirs = split/,/,$ignoreDirText;
	for (my $i=0; $i<@tempDirs; $i++){
		@tempDirs[$i] =~ s/\\/\//g;
		if (@tempDirs[$i] =~ /\/$/){chop(@tempDirs[$i]);}
	}
	return(@tempDirs);
}

#--------------------------------------------------------------------------
#PREP HOWMANYDAYSAGO CVAR SUB
#--------------------------------------------------------------------------
sub prepHowManyDaysAgoCvar{
	my $howManyDaysAgo = $_[0];
	$howManyDaysAgo =~ m/([0-9.]+)/;
	print "daysAgoMax = $1\n";
	return $1;
}


#--------------------------------------------------------------------------
#SEARCH FOR NEW FILES SUB
#--------------------------------------------------------------------------
sub searchForNewFiles{
	if ($mainDir ne ""){our @checkDirs = $mainDir;}else{our @checkDirs = $workspaceRoot;}
	my @matchFilePatterns = (".");
	my @ignoreFilePatterns = ();
	my @dateSearchArgs = ($daysAgoMax,"newer","creationTime");

	print "ignoreDirs = @ignoreDirs\n";
	foreach my $dir (@checkDirs){dir($dir,\@ignoreDirs,\@matchFilePatterns,\@ignoreFilePatterns,\@dateSearchArgs);}
	foreach my $key (sort keys %dirResult){
		my @return = $p4->RunFstat($key);
		#foreach my $table (@return[0]){
			if (exists ${$return[0]}{depotFile}){ #TEMP : needs to see if it's in the add section or not (whether or not it's in the submission list already, basically)
				#print "yes, it exists : $$return[0]{depotFile} : ($key)\n";
				$p4->RunEdit($key);
			}else{
				#print "no, it doesn't exist : ($key)\n";
				$p4->RunAdd($key);
			}


			#print "table = $table\n";
			#foreach my $subKey (keys %{$table}){
			#	my $bleh = $$table{$subKey};
			#	print "key($subKey) = $bleh\n";
			#}
		#}

		#print "key $key = $dirResult{$key}\n";
		#$p4->RunAdd($key);
	}
}


#--------------------------------------------------------------------------
#REVERT MISSING FILES SUB
#--------------------------------------------------------------------------
sub revertMissingFiles{
	my @openedFilesRefs = $p4->RunOpened();
	my @filesToRevert;
	foreach my $hashRef (@openedFilesRefs){
		my $file = lc($$hashRef{clientFile});
		$file =~ s/\/\/$clientPathName/$workspaceRoot/;
		if (!-e $file){
			print "($file) doesn't exist.\n";
			push(@filesToRevert,$file);
		}
	}

	if (@filesToRevert > 0){
		print "Do you wish to revert all these files? :\n";
		my $response = <STDIN>;
		if ($response =~ /y/i){$p4->RunRevert($_) for @filesToRevert;}
	}else{
		print "No files were found that were checked out but didn't exist.";
	}
}

#--------------------------------------------------------------------------
#PRINT DOS HELP INFO
#--------------------------------------------------------------------------
sub printHelpInfo{
	print "This is how you use the script :\n";
}

#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#DIR : MAKE SURE EXISTS sub (send file or dir path and it'll create the dirs if needed)
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#usage : dir_makeSureExists([$fileName|$dir]);
sub dir_makeSureExists{
	$_[0] =~ s/\\/\//g;

	#check for errors
	$_[0] =~ s/\s+/\s/g;
	$_[0] =~ s/\t//g;
	$_[0] =~ s/\n//g;
	if ($_[0] =~ /[(){}]/){
		print("The dir ($_[0]) has some illegal chars in it, so it can't be legit.");
		die;
	}elsif ($_[0] !~ /[a-z]:/i){
		print("The dir doesn't have a drive name specified, so it can't be legit.");
		die;
	}

	my @names = split(/\//,$_[0]);
	if (@names[-1] =~ /\./){pop(@names);}
	if (@names[-1] !~ /[a-zA-Z0-9]/){pop(@names);}
	my $currentDir = shift(@names);
	for (my $i=0; $i<@names; $i++){
		$currentDir .= "\/" . $names[$i];
		if (!-e $currentDir){
			#lxout("dir doesn't exist so I'm creating it : $currentDir");
			mkdir ($currentDir, 0777);
		}
	}
}

#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#BUILD THE EXCLUSION LIST FOR DIR ROUTINE
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
sub buildExclusionList{
	open (exclusionFile, "<@_[0]") or die("I couldn't find the exclusion file");
	while ($line = <exclusionFile>){
		$line =~ s/\n//;
		$exclusionList{$line} = 1;
	}
	close(exclusionFile);
}


#--------------------------------------------------------------------------
#LOOP PAUSE BUTTON SUB
#--------------------------------------------------------------------------
#usage : loopPause(50);  #will make you hit enter after the sub is called 50 times, then resets and starts again.
sub loopPause{
	if ($loopCount > @_[0]){
		print "PAUSE! : stop script by entering 0 or no :\n";
		my $result = <STDIN>;
		if (($result =~ /0/) || ($result =~ /no/i)){die("script was cancelled through user input");}
		$loopCount = 1;
	}elsif ($loopCount == 0){
		our $loopCount = @_[0];
	}
	$loopCount++;
}

#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#DIR SUB (ver ?.? proper dir find) (modded to turn on/off dir recursing)
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#requirements 1 : needs buildExclusionList sub if you want to use an external exclusion file.  Also, declare %exclusionList as global
#requirements 2 : needs matchPattern sub
#requirements 3 : Declare %dirResult as global so this routine can be used multiple times and add to that hash table.
#USAGE : dir($checkDir,\@ignoreDirs,\@matchFilePatterns,\@ignoreFilePatterns,recurseDirs|dontRecurseDirs);
sub dir2{
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
			if ($_[4] ne "dontRecurseDirs"){
				if (matchPattern($name,@_[1],-1)){	push (@directories,$currentDir . "\/" . $name);		}
			}
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
		dir2($dir,@_[1],@_[2],@_[3],@_4);
	}
}


#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#DIR SUB (ver 2 : modded to let you search for only writeable files that are newer than a certain date)
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#requirements 1 : needs buildExclusionList sub if you want to use an external exclusion file.  Also, declare %exclusionList as global
#requirements 2 : needs matchPattern sub
#requirements 3 : needs matchDate sub
#requirements 4 : Declare %dirResult as global so this routine can be used multiple times and add to that hash table.
#USAGE : dir($checkDir,\@ignoreDirs,\@matchFilePatterns,\@ignoreFilePatterns,\@dateSearchArgs);
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
			if (matchPattern($name,@_[1],-1))	{	push (@directories,$currentDir . "\/" . $name);		}
			else								{	print "skipping this dir : $currentDir/$name\n";	}
		}

		#LOOK FOR FILES
		elsif ((-W $currentDir . "\/" . $name) && (matchPattern($name,@_[2])) && ($exclusionList{$currentDir . "\/" . $name} != 1) && (matchPattern($name,@_[3],-1)) && (matchDate($currentDir."\/".$name,@{$_[4]}))){
			$dirResult{$currentDir . "\/" . $name} = 1;
		}
	}

	#--------------------------------------------------------------------------------------------
	#RUN THE SUBROUTINE ON EACH DIR FOUND.
	#--------------------------------------------------------------------------------------------
	foreach my $dir (@directories){
		&dir($dir,@_[1],@_[2],@_[3],@_[4]);
	}
}


#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#SEE IF ARG0 MATCHES ANY PATTERN IN ARG1ARRAYREF
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
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


#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#SEE IF THE FILE IS NEWER OR OLDER THAN SPECIFIED
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#USAGE : if (matchDate($file,$daysFromNow,newer|older,creationTime|accessTime)){lxout("yes");}
sub matchDate{
	if (@_[3] eq "creationTime"){
		if (@_[2] eq "newer"){
			if (-C @_[0] < @_[1]){
				#print "(@_[0]) creation date is newer than specified date\n";
				my $bleh = -C @_[0];  #print "bleh = $bleh\n";
				return(1);
			}else{
				#print "(@_[0]) creation date is older than specified date\n";
				my $bleh = -C @_[0];  #print "bleh = $bleh\n";
				return(0);
			}
		}else{
			if (-C @_[0] > @_[1]){
				#print "(@_[0]) creation date is older than specified date\n";
				my $bleh = -C @_[0];  #print "bleh = $bleh\n";
				return(1);
			}else{
				#print "(@_[0]) creation date is newer than specified date\n";
				my $bleh = -C @_[0];  #print "bleh = $bleh\n";
				return(0);
			}
		}
	}else{
		if (@_[2] eq "newer"){
			if (-A @_[0] < @_[1]){
				#print "(@_[0]) modified date is newer than specified date\n";
				my $bleh = -C @_[0];  #print "bleh = $bleh\n";
				return(1);
			}else{
				#print "(@_[0]) modified date is older than specified date\n";
				my $bleh = -C @_[0];  #print "bleh = $bleh\n";
				return(0);
			}
		}else{
			if (-A @_[0] > @_[1]){
				#print "(@_[0]) modified date is older than specified date\n";
				my $bleh = -C @_[0];  #print "bleh = $bleh\n";
				return(1);
			}else{
				#print "(@_[0]) modified date is newer than specified date\n";
				my $bleh = -C @_[0];  #print "bleh = $bleh\n";
				return(0);
			}
		}
	}
}