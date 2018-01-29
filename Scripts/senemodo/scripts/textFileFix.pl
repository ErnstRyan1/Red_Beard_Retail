#perl
#author : Seneca Menard
#ver 0.5
#This script is to check a shader/script file for errors and also cleanly format it.

#note : this script only works with { right now because of the god damn syntax bullshit with =~.  All the script does right now is make a shader file look pretty that's it.  It doesn't count chars yet or tell you when you have too many () or "", etc...

my $searchChar = quickDialog("Character you wish to check :",string,"{","","");
if ($searchChar eq "\("){$searchChar = "\\\\\\(";popup("yes");}
checkTextFileForErrors("W:\/Rage\/base\/decls\/m2\/phillip.m2",$searchChar);

sub checkTextFileForErrors{
	open (FILE, "<@_[0]") or die("I couldn't open this text file : @_[0]");
	my @newFile;
	my $lineNumber;
	my $count = 0;
	my $char = @_[1];
	my %matchingCharTable = qw(
		{		}
		(		)
		[		]
		<		>
		"		"
		'		'
	);

	while (<FILE>){
		my $line = $_;
		my $check = 0;

		$line =~ s/^\s+//;
		$line =~ s/^\t+//;
		$line =~ s/\s+/ /g;
		$line =~ s/\t+/ /g;

		#check for the special characters and put in the tabs
		if ($line =~ /$char/){
			$line = "\t" x $count . $line;
			$count += countSpecialCharacters($line,$char);
			$check = 1;
		}
		if ($line =~ /$matchingCharTable{$char}/){
			$count -= countSpecialCharacters($line,$matchingCharTable{$char});
			$line = "\t" x $count . $line;
			$check = 1;
		}
		if ($check == 0){
			if ($count > 0){
				my $where = index($line," ");
				$where += $count*4;
				my $diff = 29 - $where;
				my $tabs = int(0.5+($diff*.25));
				if ($tabs < 1){$tabs = 1;}
				$tabChars = "\t" x $tabs;
				$line =~ s/\s/$tabChars/;
				my $pos = $where+($tabs*4);
			}

			$line = "\t" x $count . $line;
		}
		push(@newFile,$line);

		if ($count < 0){
			popup("There are more closing $matchingCharTable{$char} characters than opening on line $lineNumber");
		}
	}
	close(FILE);

	#remove duplicate enters
	my @removeList;
	for (my $i=0; $i<@newFile; $i++){
		if (@newFile[$i] !~ /[a-zA-Z0-9\{\}]/){
			if (@newFile[$i-1] !~ /[a-zA-Z0-9\{\}]/){
				push(@removeList,$i);
			}
		}
	}
	for (my $i=0; $i<@removeList; $i++){
		splice(@newFile, @removeList[$i]-$i,1);
	}

	#remove all the empty lines
	for (my $i=0; $i<@newFile; $i++){
		lxout("$i = @newFile[$i]");
	}
	my $findCount = @newFile;
	lxout("findCount = $findCount");
	for (my $i=0; $i<$findCount; $i++){
		#swap all slashes
		lxout("newFile[$i] = @newFile[$i]");
		@newFile[$i] =~ s/\\/\//g;

		if (@newFile[$i] !~ /[a-zA-Z0-9\{\}]/){
			lxout("no letters : (@newFile[$i])");
			#if line beforehand is {
			lxout("line beforehand = (@newFile[$i-1])");
			if (@newFile[$i-1] =~ /\{/){
				lxout("yes prev {");
				splice(@newFile, $i,1);
				$i--;
				$findCount--;
			}
			#if next line is } or {
			elsif (@newFile[$i+1] =~ /[\{\}]/){
				lxout("yes next { or }");
				splice(@newFile, $i,1);
				$i--;
				$findCount--;
			}
		}else{
			#if prev line was end of shader but there was no space
			if ((@newFile[$i] !~ /[\{\}]/) && (@newFile[$i-1] =~ /\}/)){
				lxout("it did have text and doesn't have { or } ");
				splice(@newFile, $i,0, "\n");
				$i++;
				$findCount++;
			}
		}
	}

	my $extension = @_[0];
	$extension =~ s/.*\.//;
	my $newFile = "C:\/textFileFix.".$extension;
	open (NEWFILE, ">$newFile") or die("I couldn't open this text file : $newFile");
	foreach my $line (@newFile){
		if ($line !~ /\n/){$line = $line."\n";}
		print NEWFILE $line;
	}
	close(NEWFILE);
	lxout("saved out this file : $newFile");
}


#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#COUNT SPECIAL CHARACTERS
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE : countSpecialCharacters($line,$char);
#returns : the amount of those characters found.
sub countSpecialCharacters{
	$_ = @_[0];
	if 		(@_[1] eq "{"){return tr/\{//;}
	elsif	(@_[1] eq "}"){return tr/\}//;}
	elsif	(@_[1] eq "["){return tr/\[//;}
	elsif	(@_[1] eq "]"){return tr/\]//;}
	elsif	(@_[1] eq "<"){return tr/\<//;}
	elsif	(@_[1] eq ">"){return tr/\>//;}
	elsif	(@_[1] eq "("){return tr/\(//;}
	elsif	(@_[1] eq ")"){return tr/\)//;}
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

