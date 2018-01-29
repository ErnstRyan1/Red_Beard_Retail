#perl
#ver. 1.0
#author : Seneca Menard

#this script is to close all floating windows.  There's no way I know of to query what floating windows exist and so you have to send the script a list of arguments which are the cookies used in each window you've personally created and it'll close only those.  The cookies I'm talking about are used in the layout.createOrClose command.
#so for example : @window_closeAll.pl 2 5893 37 uvSen

my @cookies;
foreach my $arg (@ARGV){
	push(@cookies,$arg);
}

lx("layout.createOrClose cookie:{$_} open:0") for @cookies;
