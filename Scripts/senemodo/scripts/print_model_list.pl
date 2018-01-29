#perl
#BY: Seneca Menard
#version 1.91 (modo2)
#This script will go through all the subdirs in the mapobjects folder and print out a list of all the proper models.  The models that have icons created for them will have "** " appended to their names.
lxout("bleh");

my %models;
my %exclusionList;
my %dirResult;

my @checkDirs = ("W:\/Rage\/base\/models\/mapobjects" , "W:\/Rage\/base\/models\/mapobjects\/buildings\/fragments");
my @ignoreDirs = (work,_test,temp,bentpanel,buildings,deven_temp,erectoset,foliage,jerry_test,mal_temp,matt,mausoleums,prop,rocks,steve_temp,terrain,test,umdeco,plateau_bridge);
my @matchFilePatterns = ("\\\.lwo","\\\.ase");
my @ignoreFilePatterns = ("work\\\.lwo","work\\\.ase","_base","base\\\.lwo","_render","_hi","_high","_hp");

&buildExclusionList("C:\\printModelList_exclusions.txt");
foreach my $dir (@checkDirs){dir($dir,\@ignoreDirs,\@matchFilePatterns,\@ignoreFilePatterns);}


foreach my $model (keys %dirResult){
	my $imageName = $model;
	$imageName =~ s/\.[a-zA-Z0-9_]*//;
	$imageName .= "_senIcon.tga";

	if (-e $imageName)	{our $iconCreatedYet = "\t\t\t\t\t";	}
	else				{our $iconCreatedYet = "";				}

	$fileAge = -M $model;
	$fileAge = int($fileAge+0.5);
	$_ = $fileAge;
	$count = 5 - tr/0-9//;
	$fileAge = "0" x $count . $fileAge;

	push (@{$models{$fileAge}}, $iconCreatedYet.$model);
}


&createTextFile;
system "C:\\printModelList.txt &";  #the & part tells the script to NOT wait for the reply whether it was successful or not.







#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#PRINT THE MODEL LIST.
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#foreach my $key (sort keys %models){
	#my $date = date($key*86400);
	#lxout("$date");
	##my @modelArray = @{$models{$key}};
	#foreach my $model (@{$models{$key}}){
		#lxout("            $model");
	#}
#}

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


#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#DIR SUB (ver 1.1 proper dir find)
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
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
	#RUN THE SUBROUTINE ON EACH DIR FOUND.
	#--------------------------------------------------------------------------------------------
	foreach my $dir (@directories){
		&dir($dir,@_[1],@_[2],@_[3]);
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
#CREATE THE MODEL LIST TEXT FILE SUB
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
sub createTextFile{
	my $saveFile  = "C:\/printModelList.txt";
	my $count = 0;
	open (OUTFILE, ">$saveFile") or die("File Export Failed");
	foreach my $key (sort keys %models){
		my $date = numberDate($key*86400);
		print OUTFILE "$date\n";
		foreach my $model (@{$models{$key}}){
			print OUTFILE "            $model\n";
			$count++;
		}
	}
	print OUTFILE "There are ($count) models total\n";
	lxout("ALL DONE");
	close(OUTFILE);
}

#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#CHECK THE NUMERIC DATE SUB
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
sub numberDate{
	my @now = localtime(time-@_[0]);
	my $month = 1+@now[4];
	my $day = @now[3];
	my $year = 1900+@now[5];
	my $date = "($month-$day-$year)";
	return $date;
}

#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#CHECK THE DATE SUB
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
sub date{
	my @Weekdays = ('Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday');
	my @Months = ('January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December');
	my @Now = localtime(time-@_[0]);
	popup("now = @Now");
	my $Month = $Months[$Now[4]];
	my $Weekday = $Weekdays[$Now[6]];
	my $Hour = $Now[2];
	if ($Hour > 12) {
		$Hour = $Hour - 12;
		$AMPM = "PM";
	} else {
		$Hour = 12 if $Hour == 0;
		$AMPM ="AM";
	}
	my $Minute = $Now[1];
	       $Minute = "0$Minute" if $Minute < 10;
	my $Year = $Now[5]+1900;
	#lxout("$Weekday, $Month $Now[3], $Year $Hour:$Minute $AMPM");
	my $date = "$Weekday, $Month $Now[3], $Year $Hour:$Minute $AMPM";
	return $date;
}

#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#POPUP SUB
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
sub popup #(MODO2 FIX)
{
	lx("dialog.setup yesNo");
	lx("dialog.msg {@_}");
	lx("dialog.open");
	my $confirm = lxq("dialog.result ?");
	if($confirm eq "no"){die;}
}