#perl
#author : Seneca Menard
#ver 0.5
# TEMP : I need to make small tweaks to the exportForm sub so that it can export anything..  forms,hotkeys, etc.  that'd be faster/cleaner than copying/pasting it 4 times...

#This script is does many things.  You can either :
# - export hotkeys to a new file
# - export all forms to a new file
# - export one form to a new file
# - export tool presets to a new file

lxout("Running cfg_Export.pl");

foreach my $arg (@ARGV){
	if		($arg =~ /exportForm/i)			{&exportForm;		}
	elsif	($arg =~ /exportAllForms/i)		{&exportAllForms;	}
	elsif	($arg =~ /exportHotkeys/i)		{&exportHotkeys;	}
	elsif	($arg =~ /exportToolPresets/i)	{exportToolPresets;	}
}


#------------------------------------------------------------------------------------------------------------
#EXPORT ONE FORM SUB
#------------------------------------------------------------------------------------------------------------
sub exportForm{
	my $cfgFile = lxq("query platformservice path.path ? configname");
	my @text;
	my @keys;

	#FIND FIRST KEY.
	my $formName = quickDialog("Form name:",string,"sen_Super UVs Mini","","");
	if (lxres != 0){	die("The user hit the cancel button");	}
	my $count = 0;
	my $foundForm = 0;
	open (FILE, "<$cfgFile") or popup("This file doesn't exist : $cfgFile");
	while (<FILE>){
		$count++;
		if ($_ =~ /<atom type=\"Label\">$formName<\/atom>/i){
			lxout("found it on line $count");
			$foundForm = 1;
			last;
		}
	}
	close (FILE);
	if ($foundForm == 1){
		my @lines = readFileLines($cfgFile,$count-1);
		$lines[0] =~ s/[^0-9]//g;
		push(@keys,$lines[0]);
	}else{
		die("This form ($formName) could not be found in this config : $cfgFile");
	}


	#READ LINES
	while (@keys > 0){
		my $key = @keys[0];
		shift(@keys);
		open (FILE, "<$cfgFile") or popup("This file doesn't exist : $cfgFile");
		my $recording = 0;
		while (<FILE>){
			if ($recording == 1){
				push(@text,$_);
				if ($_ =~ /\"sub [0-9]+:sheet\"/){
					$_ =~ s/[^0-9]//g;
					push(@keys,$_);
				}
				if ($_ =~ /<\/hash>/){
					$recording = 0;
					last;
				}
			}else{
				if ($_ =~ /<hash type=\"Sheet\" key=\"$key:sheet\">/){
					$recording = 1;
					push(@text,$_);
				}
			}
		}
		close (FILE);
	}

	#EXPORT FILE
	lx("dialog.setup fileSave");
	lx("dialog.fileType config");
	lx("dialog.title {CFG to EXPORT}");
	lx("dialog.open");
	my $outputFile = lxq("dialog.result ?");
	if ($os =~ "Win"){	$outputFile =~ s/\//\\\//g;	}

	open (OUTPUTFILE, ">$outputFile");
	print OUTPUTFILE ("<?xml version=\"1.0\"?>");
	print OUTPUTFILE ("<configuration>\n");
	print OUTPUTFILE ("  <atom type=\"Attributes\">\n");
	print OUTPUTFILE ("$_") for @text;
	print OUTPUTFILE ("  </atom>\n");
	print OUTPUTFILE ("</configuration>");
	close (OUTPUTFILE);
}













#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#EXTRACT TEXT LINE SUB #this should be rewritten to accept lines such as "234-589" (and maybe not need a forced order)
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#usage : my @lines = readFileLines($filePath,2,3,534);
sub readFileLines{
	open (FILE, "<$_[0]") or die("This file doesn't exist : $_[0]");
	my $line = 0;
	my @returnArray;
	my $argNumber = 1;
	while (<FILE>){
		$line++;
		if ($line == $_[$argNumber]){
			push(@returnArray,$_);
			if ($argNumber == $#ARGV+1){
				last;
			}else{
				$argNumber++;
			}
		}
	}
	close (FILE);
	return(@returnArray);
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
