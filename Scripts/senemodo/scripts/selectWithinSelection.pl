#perl
#BY: Seneca Menard
#version 1.0
#this script is to select within your current selection..  Unfortunately, the way you use it is kinda lame, but that's because you can't write
#new selection functions through script.  You also can't do any waits or listens or whatnot, so the way it works right now is the only way possible.

#To use, make your first selection and then fire the script with the variable "createList" appended.  That will write out your current selection to a text file.
#Then, make your next selection and fire teh script again but without any variables appended.  That will deselect all the elements that aren't in that text file.

#SCRIPT ARGUMENTS :
# "createList" : This argument tells the script to create the text file list that will be used later.




#------------------------------------------------------------
#SCRIPT ARGS
#------------------------------------------------------------
foreach my $arg (@ARGV){
	if ($arg =~ /createList/i)	{	our $createList = 1;	}
}


#------------------------------------------------------------
#SETUP
#------------------------------------------------------------
my $mainlayer = lxq("query layerservice layers ? main");
my $file = "C://selWithinSel.txt";


#------------------------------------------------------------
#MAIN
#------------------------------------------------------------
if( lxq( "select.typeFrom {vertex;edge;polygon;item} ?" ) ){
	my @verts = lxq("query layerservice selection ? vert");
	if ($createList == 1){
		createFile(v,@verts);
	}else{
		readFile(v,@verts);
	}
}
elsif( lxq( "select.typeFrom {edge;polygon;item;vertex} ?" ) ){
	my @edges = lxq("query layerservice selection ? edge");
	if ($createList == 1){
		createFile(e,@edges);
	}else{
		readFile(e,@edges);
	}
}
elsif( lxq( "select.typeFrom {polygon;item;vertex;edge} ?" ) ){
	my @polys = lxq("query layerservice selection ? poly");
	if ($createList == 1){
		createFile(p,@polys);
	}else{
		readFile(p,@polys);
	}
}


#------------------------------------------------------------
#CREATE FILE SUB
#------------------------------------------------------------
sub createFile{
	open (FILE, ">$file") or die("I couldn't open the file.");
	foreach my $elem (@_){
		print FILE"$elem ";
	}
	close(FILE);
}


#------------------------------------------------------------
#READ FILE SUB
#------------------------------------------------------------
sub readFile{
	my $elemList;

	open (FILE, "<$file") or die("I couldn't open the file.");
	while ($line = <FILE>){	$elemList .= $line;	}
	close(FILE);
	my @oldList = split(/\s/, $elemList);

	if 		(@_[0] eq "v")	{	our $type = "vertex";		}
	elsif 	(@_[0] eq "e")	{	our $type = "edge";			}
	elsif	(@_[0] eq "p")	{	our $type = "polygon";		}
	else					{	die("readFile sub error");	}

	if (@_[0] ne @oldList[0]){
		die("You're not in the same selection mode as when you wrote the selection to the cfg");
	}

	shift(@_);
	shift(@oldList);

	my @removeList = removeListFromArray(\@_,\@oldList);
	lxout("removeList = @removeList");
	foreach my $elem (@removeList){
		my @elemInfo = split (/[^0-9]/, $elem);
		if ($type eq "edge"){@elemInfo[2] .= " ".@elemInfo[3];}
		lx("select.element @elemInfo[1] $type remove @elemInfo[2]");
	}
}



#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#REMOVE ARRAY2 FROM ARRAY1 SUBROUTINE v1.1
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE : my @newArray = removeListFromArray(\@full_list,\@small_list);
sub removeListFromArray{
	my @fullList = @{$_[0]};
	for (my $i=0; $i<@{$_[1]}; $i++){
		for (my $u=0; $u<@fullList; $u++){
			if ($fullList[$u] eq ${$_[1]}[$i]){
				splice(@fullList, $u,1);
				last;
			}
		}
	}
	return @fullList;
}
