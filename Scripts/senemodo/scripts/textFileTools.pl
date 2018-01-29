#perl
#author : Seneca Menard
#ver : 1.0

#script arguments
#conDumpTextureSort 	: this is for when you run "listImages sorted" in rage and want to purge the junk lines from it and have it spit out two files (clean and junk).  The textfile has to be "C:/condump.txt" and goes to "C:/condump_clean.txt" and "C:/condump_junk.txt"

lxout("eh");
foreach my $arg (@ARGV){
	if ($arg eq "conDumpTextureSort")	{	&conDumpTextureSort;	}

}

sub conDumpTextureSort{
	my $file_source_path = "C:\/condump.txt";
	my $file_clean_path = "C:\/condump_clean.txt";
	my $file_junk_path = "C:\/condump_junk.txt";

	my @file_clean;
	my @file_junk;

	open (FILE_SOURCE, "<$file_source_path") or die("I couldn't find this file : $fileSource");
	while ($line = <FILE_SOURCE>){
		if		($line =~ / _/)					{	push(@file_junk,$line);		}
		elsif	($line =~ /swf\//)				{	push(@file_junk,$line);		}
		elsif	($line =~ /env\//)				{	push(@file_junk,$line);		}
		elsif	($line =~ /\.pages/)			{	push(@file_junk,$line);		}
		elsif	($line =~ / megs /)				{	push(@file_junk,$line);		}
		elsif	($line =~ / lights\//)			{	push(@file_junk,$line);		}
		elsif	($line =~ /\/particles\//)		{	push(@file_junk,$line);		}
		elsif	($line =~ / fonts\//)			{	push(@file_junk,$line);		}
		elsif	($line =~ /textures\/common\//)	{	push(@file_junk,$line);		}
		elsif	($line =~ /lights_blended\//)	{	push(@file_junk,$line);		}
		elsif	($line =~ /\/guis\//)			{	push(@file_junk,$line);		}
		else									{	push(@file_clean,$line);	}
	}

	open (FILE_JUNK, ">$file_junk_path") or die("Failed to open the junk condump file : $file_junk_path");
	foreach my $line (@file_junk){print FILE_JUNK "$line";}
	close (FILE_JUNK);

	open (FILE_CLEAN, ">$file_clean_path") or die("Failed to open the clean condump file : $file_clean_path");
	foreach my $line (@file_clean){print FILE_CLEAN "$line";}
	close (FILE_CLEAN);
}


