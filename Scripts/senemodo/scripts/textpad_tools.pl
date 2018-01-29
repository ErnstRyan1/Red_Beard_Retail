#perl

BEGIN{
	my $perlDir = "C:\/Perl\/lib";
	my $perlDir2 = "H:\/Home\/Seneca Menard\/artistTools_Modo\/Perl\/lib";
	push(@INC,$perlDir);
	push(@INC,$perlDir2);
}
use Win32::Clipboard;


foreach my $arg (@ARGV){
	if		($arg eq "reverseList")					{	reverseList();			}
	elsif	($arge eq "randomizeList")				{	reverseList(randomize);	}
}


sub reverseList{
	my $text = Win32::Clipboard::GetText();
	my @lines = split(/\n/, $text);

	print("Type character with which to split the text:\n");
	my $char = <STDIN>;
	chomp($char);

	for (my $i=0; $i<@lines; $i++){
		my @list = split(/$char/, $lines[$i]);
		if ($_[0] eq "randomize"){
			randomizeArray(\@list);
			$lines[$i] = "";
			for (my $u=0; $u<@list; $u++){$lines[$i] .= $list[$u];}
			$lines[$i] =~ s/..$//;
		}else{
			my @reverseLines;
			$lines[$i] = "";
			for (my $u=0; $u<@list; $u++){$lines[$i] .= $list[$#list-$u] . ", ";}
			$lines[$i] =~ s/..$//;
		}
	}

	my $newLine;
	$newLine .= $_ . "\n" for @lines;
	Win32::Clipboard::Set($newLine);

}



#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#RANDOMIZE ARRAY SUB (fisher_yates_shuffle)
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE : randomizeArray(\@array);
sub randomizeArray{
    my $array = shift;
    my $i;
    for ($i=@$array; --$i; ){
        my $j = int rand ($i+1);
        next if $i == $j;
        @$array[$i,$j] = @$array[$j,$i];
    }
}
