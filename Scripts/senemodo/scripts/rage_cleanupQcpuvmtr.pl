#perl
#ver 1.0
#author : Seneca Menard
#This script is hardcoded to free up 15GB from the Q:/base/generated/cloud/cpuvmtrs dir.


my $checkDir = "Q:\/base\/generated\/cloud\/cpuVmtrs";
my @matchFilePatterns = ("\\\.cpuvmtr");
my @ignoreFilePatterns = ();
dir($checkDir,\@ignoreDirs,\@matchFilePatterns,\@ignoreFilePatterns);
my %dirResult;
my %fileDateTable;
my $totalDirSize;
foreach my $file (keys %dirResult){
	my $time = -M $file;
	$totalDirSize += -s $file;
	push(@{$fileDateTable{$time}} , $file);
}

my $gigsUsed = $totalDirSize / 1073741824;
my $gigsFree = 139 - $gigsUsed;
my $bytesToDelete = 15*1073741824 - $gigsFree*1073741824;
print "gigsUsed = $gigsUsed\n";
print "gigsFree = $gigsFree\n";

my @filesToDelete;
my $fileDeleteCounter;
my $deletedBytes;
my $counter = 0;
my $stopLoop = 0;
foreach my $keyTime (sort { $b <=> $a } keys %fileDateTable){
	foreach my $file (@{$fileDateTable{$keyTime}}){
		$file =~ s/\//\\/g;
		push(@filesToDelete,$file);
		my $size = -s $file;
		print "$file\n";
		$deletedBytes += $size;
		$counter++;
		if ($deletedBytes >= $bytesToDelete){	$stopLoop = 1;	last;	}
	}
	if ($stopLoop == 1){	last;	}
}

print "=============================================================\nWill have to delete $counter files to have 15GB free.  Is that ok?  (yes/no)\n=============================================================\n";
my $response = <STDIN>;
if ($response =~ /y/i){	system "del \/F \"$_\"" for @filesToDelete;	}








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
