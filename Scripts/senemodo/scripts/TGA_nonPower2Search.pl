#perl
#ver 1.0
#author : Seneca Menard

#this script is to look for non power of 2 TGAs in the dirs specified.

foreach my $arg (@ARGV){
	if ($arg eq "dirBrowser")	{our $dirBrowser = 1;	}
}

my %dirResult;
my %exclusionList;
my @checkDirs;
if ($dirBrowser == 1){
	@checkDirs = dirDialog();
}else{
	@checkDirs = ("W:\/Rage\/base\/models" , "W:\/Rage\/base\/textures" , "W:\/Rage\/base\/stamps");
}

my @ignoreDirs = (work);
my @matchFilePatterns = ("\\\.tga");
my @ignoreFilePatterns = ();
foreach my $dir (@checkDirs){
	dir($dir,\@ignoreDirs,\@matchFilePatterns,\@ignoreFilePatterns);
}

foreach my $key (keys %dirResult){
	#lxout("key=$key");
	my @imageSize = queryTGASize($key);
	if ( ($imageSize[0] != 4) && ($imageSize[0] != 8) && ($imageSize[0] != 16) && ($imageSize[0] != 32) && ($imageSize[0] != 64) && ($imageSize[0] != 128) && ($imageSize[0] != 256) && ($imageSize[0] != 512) && ($imageSize[0] != 1024) && ($imageSize[0] != 2048) && ($imageSize[0] != 4096) ){
		lxout("imageSize = @imageSize");
		lxout("This image is not power of 2 : $key");
	}elsif ( ($imageSize[1] != 4) && ($imageSize[1] != 8) && ($imageSize[1] != 16) && ($imageSize[1] != 32) && ($imageSize[1] != 64) && ($imageSize[1] != 128) && ($imageSize[1] != 256) && ($imageSize[1] != 512) && ($imageSize[1] != 1024) && ($imageSize[1] != 2048) && ($imageSize[1] != 4096) ){
		lxout("imageSize = @imageSize");
		lxout("This image is not power of 2 : $key");
	}
}


#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#QUERY TGA SIZE SUB
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#usage : queryTGASize($filePath);
#requires readChar sub
sub queryTGASize{
	open (TGA, "<@_[0]") or return(0,0);
	binmode(TGA); #explicitly tells it to be a BINARY file

	#read the TGA header info
	my $buffer;
	my $identSize =			readChar(TGA,1,C);
	my $palette = 			readChar(TGA,1,C);
	my $imageType = 		readChar(TGA,1,C);
	my $colorMapStart = 	readChar(TGA,2,S);
	my $colorMapLength = 	readChar(TGA,2,S);
	my $colorMapBits =		readChar(TGA,1,C);
	my $xStart =			readChar(TGA,2,S);
	my $yStart =			readChar(TGA,2,S);
	my $width =				readChar(TGA,2,S);
	my $height =			readChar(TGA,2,S);
	my $bits =				readChar(TGA,1,C);
	my $descriptor = 		readChar(TGA,1,C);
	my %pixels;
	if ($bits == 24)		{our $readLength=3;}else{our $readLength=4;}
	@currentSize = 			($width,$height);
	$bitMode = 				$bits;
	close(TGA);

	return($width,$height);
}


#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#READ BINARY CHARS FROM FILE (there's no offsetting. it's for reading entire file one step at a time)
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#usage : readChar(FILEHANDLE,$howManyBytes,$packCharType);
sub readChar{
	read(@_[0], $buffer, @_[1]);
	return unpack(@_[2],$buffer);
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


sub dirDialog{
	lx("dialog.setup dir");
	lx("dialog.open");
	if (lxres != 0){	die("The user hit the cancel button");	}
	return (lxq("dialog.result ?"));
}