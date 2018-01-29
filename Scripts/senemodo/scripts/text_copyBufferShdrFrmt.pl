#perl
#ver 1.0
#author : Seneca Menard

#This script is to take the text that's currently in the clipboard and format so it so the lines are all spaced all nice and pretty.  It's basically for making shaders that look ugly look clean.


BEGIN{
	my $perlDir = "C:\/Perl\/lib";
	my $perlDir2 = "H:\/Home\/Seneca Menard\/artistTools_Modo\/Perl\/lib";
	push(@INC,$perlDir);
	push(@INC,$perlDir2);
}
use Win32::Clipboard;
$CLIP = Win32::Clipboard();
my $text = Win32::Clipboard::GetText();


print "How many spaces?  (29=default)";
my $spaces = <STDIN>;
if ($spaces == 0){$spaces = 29;}
$CLIP->Set(checkTextFileForErrors($text,string));

sub checkTextFileForErrors{
	my @newFile;
	my $lineNumber;
	my $count = 0;
	my $char = "{";
	my %matchingCharTable = qw(
		{		}
		(		)
		[		]
		<		>
		"		"
		'		'
	);


	#if the input is a string, break it into an array  	#else an array
	if (@_[1] =~ /string/i){	our @array = split(/\n/, @_[0]);}
	else{						our @array = @{$_[0]};			}

	foreach my $line (@array){
		#lxout("line=$line");
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
				my $diff = $spaces - $where;
				my $tabs = int(0.5+($diff*.25));
				if ($tabs < 1){$tabs = 1;}
				$tabChars = "\t" x $tabs;
				$line =~ s/\s/$tabChars/;
				my $pos = $where+($tabs*4);
			}

			$line = "\t" x $count . $line;
		}
		push(@newFile,$line);

		#if ($count < 0){
		#	popup("There are more closing $matchingCharTable{$char} characters than opening on line $lineNumber");
		#}
	}

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
	my $findCount = @newFile;
	for (my $i=0; $i<$findCount; $i++){
		#swap all slashes
		@newFile[$i] =~ s/\\/\//g;

		if (@newFile[$i] !~ /[a-zA-Z0-9\{\}]/){
			#if line beforehand is {
			if (@newFile[$i-1] =~ /\{/){
				splice(@newFile, $i,1);
				$i--;
				$findCount--;
			}
			#if next line is } or {
			elsif (@newFile[$i+1] =~ /[\{\}]/){
				splice(@newFile, $i,1);
				$i--;
				$findCount--;
			}
		}else{
			#if prev line was end of shader but there was no space
			if ((@newFile[$i] !~ /[\{\}]/) && (@newFile[$i-1] =~ /\}/)){
				splice(@newFile, $i,0, "\n");
				$i++;
				$findCount++;
			}
		}
	}

	if (@_[1] eq "string"){
		my $string;
		foreach my $line (@newFile){$string .= $line."\n";}
		return($string);
	}else{
		return(@newFile);
	}
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


