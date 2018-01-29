#perl
#ver 1.0
#author : Seneca Menard

#This script will clean up the C:/Rage/base/landscape dir and delete all the megatexture files that have newer versions existing already.

my %dirResult;
my %megatextureDB;
my @filesToDelete;
my @matchFilePatterns = ("\\\.cpuimage","\\\.pages","\\\.jpg");
my @ignoreFilePatterns = ("_vmtr","_C.pages");
my $checkDir = "C:\/Rage\/base\/landscape";
dir($checkDir,\@ignoreDirs,\@matchFilePatterns,\@ignoreFilePatterns);

foreach my $file (keys %dirResult){
	my $fileName1 = $file;
	my $fileName2 = $file;
	$fileName1 =~ s/$checkDir\///;
	$fileName2 =~ s/$checkDir\///;
	$fileName1 =~ s/_v.*//;
	$fileName2 =~ s/.*_v//;
	my $version = $fileName2;
	$version =~ s/[^0-9]//g;
	$version = int($version);

	push(@{$megatextureDB{$fileName1}{$version}},$file);
}

foreach my $megatexture (keys %megatextureDB){
	my @versionArray = (sort { $a <=> $b } keys %{$megatextureDB{$megatexture}});

	for (my $i=0; $i<$#versionArray; $i++){
		foreach my $file (@{$megatextureDB{$megatexture}{$versionArray[$i]}}){
			$file =~ s/\//\\/g;
			push(@filesToDelete,$file);
		}
	}
}

print "$_\n" for @filesToDelete;
print "\nDo you wish to delete these files? (y\\n)\n";
my $answer = <STDIN>;
if ($answer =~ /y/i){
	system "del \/F \"$_\"" for @filesToDelete;
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
#DIR SUB (ver 1.2 special char bugfix)
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

