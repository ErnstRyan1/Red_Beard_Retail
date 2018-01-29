#perl
#ver 1.0
#author : Seneca Menard
#This script will compare two script dirs and an exemption list and print out a list of scripts that aren't in the old dir or the exemption list.
#It's handy to get a "to do list" when publishing new scripts.




my $dirNew = "C:\/Documents and Settings\/seneca\/Application Data\/Luxology\/Scripts";
my $dirOld = "C:\/Documents and Settings\/Seneca\/Desktop\/script extraction";

my %scriptsNew = findFileVersions($dirNew);
my %scriptsOld = findFileVersions($dirOld);
my %ignoreList;
my @newScriptsList;
my @updatedScriptsList;

my @ignoreList = copyTextSections("C:\/scriptFileHostExemptions.txt","=======================not going to release these : =======================\n","\n");
push(@ignoreList,copyTextSections("C:\/scriptFileHostExemptions.txt","=======================maybe I should release these : =======================\n","\n"));
chomp(@ignoreList[$_]) for @ignoreList;
$ignoreList{$_} = 1 for @ignoreList;

foreach my $key (keys %scriptsNew){
	if (($ignoreList{$key} != 1) && ($scriptsNew{$key} != $scriptsOld{$key})){
		if ($scriptsOld{$key} == ""){
			lxout("NEW SCRIPT : $key");
			push(@newScriptsList,$key);
		}else{
			lxout("UPDATED SCRIPT : $key old=$scriptsOld{$key} <> new=$scriptsNew{$key}");
			push(@updatedScriptsList,$key);
		}
	}
}

findNewScriptsNotInExemptionList($dirNew,$dirOld);
sub findNewScriptsNotInExemptionList{
	my $exemptList = "C:\/scriptFileHostExemptions.txt";
	my %exemptFiles;
	open (FILE, "<$exemptList") or die("I couldn't find the original file");
	while (<FILE>){
		chomp($_);
		$exemptFiles{$_} = 1;
	}
	close(FILE);


	opendir(@_[0],@_[0]) || die("Cannot opendir @_[0]");
	my @files = (sort readdir(@_[0]));
	shift(@files);
	shift(@files);

	opendir(@_[1],@_[1]) || die("Cannot opendir @_[1]");
	my %oldFiles;
	my @oldFiles = (sort readdir(@_[1]));
	shift(@oldFiles);
	shift(@oldFiles);
	foreach my $file (@oldFiles){$oldFiles{$file} = 1;}

	foreach my $file (@files){
		if (($file =~ /\.pl/) && ($exemptFiles{$file} != 1) && ($oldFiles{$file} != 1)){
			lxout("not in exclusion list : $file");
		}
	}
}


#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#FIND SCRIPT FILE VERSIONS SUB
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE : findFileVersions($fullDirPath,printResults?=1|0);
#returns hash table of files with version
sub findFileVersions{
	my %filesWithVer;
	my @filesWithVer;
	my @filesWithoutVer;
	opendir(@_[0],@_[0]) || die("Cannot opendir @_[0]");
	my @files = (sort readdir(@_[0]));
	shift(@files);
	shift(@files);

	foreach my $file (@files){
		if ($file =~ /\.pl/){
			my $fullFileName = @_[0]."\/".$file;
			my $successCheck = 0;
			my $count = 0;
			open (FILE, "<$fullFileName") or die("I couldn't find the original file");
			while (<FILE>){
				if ($count > 10){last;}
				if (($_ =~ /\#ver\s/i) || ($_ =~ /\#ver\./i) || ($_ =~ /\#version/i)){
					my @numbers = split(/[^0-9]+\.?[^0-9]+/, $_);
					chomp(@numbers[1]);
					$filesWithVer{$file} = @numbers[1];
					push(@filesWithVer,$file);
					$successCheck = 1;
					last;
				}
				$count++;
			}

			if ($successCheck == 0){push(@filesWithoutVer,$file);}
			close(FILE);
		}
	}

	if (@_[1] == 1){
		lxout("--------------------------------");
		lxout("--------------------------------");
		lxout("files with VER = $#filesWithVer+1");
		lxout("--------------------------------");
		lxout("--------------------------------");
		foreach my $file (@filesWithVer){lxout("$file");}

		lxout("--------------------------------");
		lxout("--------------------------------");
		lxout("files without VER = $#filesWithoutVer+1");
		lxout("--------------------------------");
		lxout("--------------------------------");
		foreach my $file (@filesWithoutVer){lxout("$file");}
	}

	return %filesWithVer;
}



#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#COPY SECTIONS FROM A TEXT FILE SUB
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE : copyTextSections("C:\scriptFileHostExemptions.txt","startHere\n","endHere\n");
#notes : This subroutine returns an array that's a segment of a text file.  It doesn't return the start line or end line btw.
sub copyTextSections{
	my @copiedLines = ();
	my $copyOnOff = 0;

	open (FILE, "<@_[0]") or die("I couldn't open this text file : @_[0]");
	while (<FILE>){
		if ($copyOnOff == 1){
			if ($_ eq @_[2]){
				lxout("closing file \n \n \n ");
				close(FILE);
				last;
			}

			chomp($_);
			push(@copiedLines,$_);
		}
		if ($_ eq @_[1]){$copyOnOff = 1;}
	}
	return(@copiedLines);
}


