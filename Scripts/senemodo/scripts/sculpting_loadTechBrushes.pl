#perl
#ver 0.52
#hack brush loader.  This script will load all the brushes from the C:\Users\smenard\AppData\Roaming\Luxology\Brushes\tech folder.

my %dirResult;
my $modoVer = lxq("query platformservice appversion ?");
my $checkDir = "C:\/Users\/seneca\/AppData\/Roaming\/Luxology\/Brushes\/tech";
my @ignoreDirs;
my @matchFilePatterns = ("\\\.tif","\\\.exr");
my @ignoreFilePatterns;
dir($checkDir,\@ignoreDirs,\@matchFilePatterns,\@ignoreFilePatterns,"skipSubDirs");

lx("!!tool.set seneSculpt on");
lx("!!tool.attr brush.preset type {}");
lx("!!tool.set seneSculpt off");
lx("!!uiimage.clear");
lx("!!tool.set seneSculpt on");

foreach my $file (sort sortAlphaNumeric keys %dirResult){
	my @path = split(/\//, $file);
	my $brushPath;
	if ($modoVer > 900) {	$brushPath = "brush:logs:Brushes\/tech\/" . $path[-1];	}	#901
	else				{	$brushPath = "brush:user:Brushes\/tech\/" . $path[-1];	}	#601
	lx("tool.attr brush.preset type {$brushPath}");
	popup("brushPath = $brushPath");
}






#----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#------------------------------------------------SUBROUTINES-----------------------------------------------------------------------------------------------------------------------------------------------------------
#----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#SORT ALPHANUMERIC sub : sorts with numbers, so you get 1,2,3,4,11,d1,d2,etc, not 1,11,etc
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE : @sorted = sort sortAlphaNumeric @not_sorted;
#REQUIRES GETNUMBERFROMSTRINGPOS sub
sub sortAlphaNumeric{
	my $lengthA = length($a);
	my $lengthB = length($b);
	my $shorter = 1;
	my $minLength = $lengthB;
	my $maxLength = $lengthA;  if ($lengthB > $lengthA){$maxLength = $lengthB; $minLength = $lengthA; $shorter = -1;}
	
	for (my $i=0; $i<$maxLength; $i++){
		if ($i >= $minLength)			{return $shorter;}
		
		my $charA = lc(substr($a,$i,1));
		my $charB = lc(substr($b,$i,1));
		if (($charA =~ /\d/) && ($charB =~ /\d/)){
			$charA = getNumberFromStringPos($a,$i);
			$charB = getNumberFromStringPos($b,$i);
			if		($charA > $charB)	{return  1;}
			elsif	($charA < $charB)	{return -1;}
		}
		elsif	($charA gt $charB)		{return  1;}
		elsif	($charA lt $charB)		{return -1;}
	}
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#GET NUMBER FROM STRING POS
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE : my $number = getNumberFromStringPos(poop387shit585,$charIndice);  #will return 387 if $charIndice=4
sub getNumberFromStringPos{
	my $number;
	my $strLength = length($_[0]);
	for (my $i=$_[1]; $i<$strLength; $i++){
		my $char = substr($_[0], $i, 1);
		if ($char =~ /\d/)	{	$number .= $char;	}
		else				{	return $number;		}
	}
	return $number;
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
#DIR SUB (ver 1.3 added skipSubDirs)
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#requirements 1 : needs buildExclusionList sub if you want to use an external exclusion file.  Also, declare %exclusionList as global
#requirements 2 : needs matchPattern sub
#requirements 3 : Declare %dirResult as global so this routine can be used multiple times and add to that hash table.
#USAGE : dir($checkDir,\@ignoreDirs,\@matchFilePatterns,\@ignoreFilePatterns,"skipSubDirs"); #if last arg is "skipSubDirs", then it'll skip subdirs.
sub dir{
	#get the name of the current dir.
	my $currentDir = $_[0];
	my @tempCurrentDirName = split(/\//, $currentDir);
	my $tempCurrentDirName = @tempCurrentDirName[-1];
	my @directories;
	my $skipSubDirs =  0;
	if ($_[4] eq "skipSubDirs"){$skipSubDirs = 1;}
	lxout("skipSubDirs = $skipSubDirs");

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
		if (($skipSubDirs == 0) && (-d $currentDir . "\/" . $name)){
			if (matchPattern($name,$_[1],-1)){	push (@directories,$currentDir . "\/" . $name);		}
		}

		#LOOK FOR FILES
		elsif ((matchPattern($name,$_[2])) && ($exclusionList{$currentDir . "\/" . $name} != 1) && (matchPattern($name,$_[3],-1))){
			$dirResult{$currentDir . "\/" . $name} = 1;
		}
	}

	#--------------------------------------------------------------------------------------------
	#RUN THE SUBROUTINE ON EACH DIR FOUND.
	#--------------------------------------------------------------------------------------------
	foreach my $dir (@directories){
		&dir($dir,$_[1],$_[2],$_[3],$_[4]);
	}
}
