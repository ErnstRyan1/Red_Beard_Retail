#perl
#This script is to load a text file, sort it and split each line by tabs and export it to a new text file

my $os = lxq("query platformservice ostype ?");
my @file;

lx("dialog.setup fileOpen");
lx("dialog.fileType config");
lx("dialog.title {CFG to IMPORT}");
lx("dialog.open");
my $originalFile = lxq("dialog.result ?");
if ($os =~ "Win"){	$originalFile =~ s/\//\\\//g;	}


#open the file and add it's lines to the array
open (FILE, "<$originalFile") or die("I couldn't find the original file");
while ($line = <FILE>){	push(@file,$line);	}
close(FILE);


#number the lines
for (my $i=0; $i<@file; $i++){
	my $diff = (4-length($i));
	my $count = "0"x$diff.$i;
	@file[$i] = @file[$i]. "$count";
}


#sort the array, then seperate it
my @sorted = sort { lc($a) cmp lc($b) } @file;
my %finalList;
my $count=0;
foreach my $line (@sorted){
	my $number = substr($line,length($line)-4,4);
	$line =~ s/\d...$//;
	$line =~ s/\n//;
	my @array = split(/\t+/, $line);

	for (my $i=0; $i<5; $i++){	push(@{$finalList{$i}},@array[$i]);	}
	push(@{$finalList{5}},$number);

	$count++;
}


#now create the external file and write it out.
lx("dialog.setup fileSave");
lx("dialog.fileType config");
lx("dialog.title {FILE TO SAVE}");
lx("dialog.open");
my $saveFile = lxq("dialog.result ?");
if ($os =~ "Win"){	$saveFile =~ s/\//\\\//g;	}
open (SAVEFILE, ">$saveFile") or die("You canceled out the file save.");

for (my $i=0; $i<6; $i++){
	print SAVEFILE"[[------------------------------------($i)----------------------------------------]]\n";
	for (my $word=0; $word<$count; $word++){	print SAVEFILE"@{$finalList{$i}}[$word]\n";	}
}

close(SAVEFILE);



