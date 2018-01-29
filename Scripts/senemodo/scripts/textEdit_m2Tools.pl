#perl
#ver 0.5
#author : Seneca Menard

#this script is going to be setup to do a number of batch map file edits, but right now it only deletes entities of a certain type.
#when done, it saves the map to the C: drive.

foreach my $arg (@ARGV){
	if		($arg eq "deleteEntities")			{	&deleteEntityTypes;	}
	else										{	our $text = $arg;	}
}


sub deleteEntityTypes{
	my @filesToOpen = fileDialog("open","Select a MAP File","*.map","map");
	my $textToFind = quickDialog("Text to find","string","particleSystem","","");

	foreach my $file (@filesToOpen){
		my @mapFileText = ();
		my @entityText = ();
		my $skipCopy = 0;
		my $bracketCount = 0;
		my $entityTypeTest = 0;

		#read the map file, skipping entities we don't want
		open (MAP, "<$file") or die("I can't open the map : $file");
		while (<MAP>){
			if ($_ =~ /entity \{/){
				$skipCopy = 1;
				@entityText = ();
			}

			if ($skipCopy == 1){
				if 	($_ =~ /\{/)			{	$bracketCount++;		}
				if	($_ =~ /\}/)			{	$bracketCount--;		}
				if 	($_ =~ /$textToFind/)	{	$entityTypeTest = 1;	}
				push(@entityText,$_);

				if ($bracketCount == 0){
					$skipCopy = 0;
					if ($entityTypeTest == 0){push(@mapFileText,@entityText);}
					$entityTypeTest = 0;
				}
				next;
			}

			push(@mapFileText,$_);

		}
		close (MAP);

		#print out to new map file
		my $fileName = $file;
		$fileName =~ s/\\/\//g;
		$fileName =~ s/.*\///;
		$fileName = "C:\/".$fileName;
		open (MAP2, ">$fileName") or die("I can't open the map : $file");
		print MAP2 $_ for @mapFileText;
		close (MAP2);
	}
}





##------------------------------------------------------------------------------------------------------------
##------------------------------------------------------------------------------------------------------------
#FILE DIALOG WINDOW SUB
##------------------------------------------------------------------------------------------------------------
##------------------------------------------------------------------------------------------------------------
##USAGE : my @files = fileDialog("open"|"save","title","*.lxo;*.lwo;*.obj","lxo");
##0=open or save #1=title #2=loadExt #3=saveExt
sub fileDialog{
	if ($_[0] eq "open")	{	lx("dialog.setup fileOpenMulti");	}
	else					{	lx("dialog.setup fileSave");		}

	lx("dialog.title {$_[1]}");
	lx("dialog.fileTypeCustom format:[stp] username:[$_[1]] loadPattern:[$_[2]] saveExtension:[$_[3]]");
	lx("dialog.open");
	my @fileNames = lxq("dialog.result ?") or die("The file saver window was cancelled, so I'm cancelling the script.");
	return (@fileNames);
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
