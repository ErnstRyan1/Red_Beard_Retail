#perl
#ver 1.1
#author : Seneca Menard
#This script is to read the text in your windows clipboard and multiply the numbers it finds in the lines with the word you're specifying by the number or numbers you type in.  Note that if your shader has four numbers in it, the script will ignore the fourth number (because that's for alpha)
#for example, say your shader line reads this :		"diffusemap constantcolor( 0.5, 0.5, 0.5, 1.0)"
# - if you type this : "2" : you'll get this :		"diffusemap constantcolor( 1.0, 1.0, 1.0, 1.0)"
# - if you type this : "2 2 2" : you'll get this :	"diffusemap constantcolor( 1.0, 1.0, 1.0, 1.0)"
# - if you type this : "1 2 3" : you'll get this :	"diffusemap constantcolor( 0.5, 1.0, 1.5, 1.0)"
# - if you type this : "1,2,3" : you'll get this :	"diffusemap constantcolor( 0.5, 1.0, 1.5, 1.0)"
# - if you type this : "1, 2, 3" : you'll get this :"diffusemap constantcolor( 0.5, 1.0, 1.5, 1.0)"

#note : you must have perl installed to run this script.



BEGIN{
	my $perlDir = "C:\/Perl\/lib";
	my $perlDir2 = "H:\/Home\/Seneca Menard\/artistTools_Modo\/Perl\/lib";
	push(@INC,$perlDir);
	push(@INC,$perlDir2);
}
#win32 clipboard
use Win32::Clipboard;
my $text = Win32::Clipboard::GetText();
my @lines = split(/\n/, $text);

print "Edit the lines with which text :";
my $findWord = <STDIN>;
chomp $findWord;
if ($findWord eq ""){die;}
print "Multiply the colors by this amount :";
my $scalar = <STDIN>;
my @scalar;
chomp $scalar;
if ($scalar =~ /\s/){
	@scalar = split(/\s/, $scalar);
}
elsif ($scalar =~ /,/){
	$scalar =~ s/\s//;
	@scalar = split(/,/, $scalar);
}
else{
	@scalar = ($scalar,$scalar,$scalar);
}


for (my $i=0; $i<@lines; $i++){
	if (@lines[$i] =~ /$findWord/){
		my @split1 = split (/[^0-9\.]+/, @lines[$i]);
		my @split2 = split (/[0-9\.]+/, @lines[$i]);
		shift(@split1);

		my $currentLine;
		my $splitCount1 = @split1;
		if ($splitCount1 == 4){$splitCount1--;}
		for (my $i=0; $i<$splitCount1; $i++){@split1[$i] *= $scalar[$i];}  #ignores the last number if there are 4
		for (my $i=0; $i<@split2; $i++){
			$currentLine .= @split2[$i];
			if (@split1 > $i){$currentLine .= @split1[$i];}
		}
		#lxout("currentLine = $currentLine");
		@lines[$i] = $currentLine
	}
}

my $newLine;
foreach my $line (@lines){
	$newLine = $newLine . $line . "\n";
}
Win32::Clipboard::Set($newLine);

