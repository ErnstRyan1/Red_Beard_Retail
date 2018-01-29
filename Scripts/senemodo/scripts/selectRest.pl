#perl
#SELECT REST
#ver. 1.5
#by Seneca Menard
#Description:
#If you have some vertex(s) selected, it'll select all the verts in the layer with the same selection sets.
#If you have some edge(s) selected, it'll select all the edges in the layer with the same selection sets.
#If you have some poly(s) selected, it'll select all the other polys in the layer that have the same materials assigned;
#If you have some poly(s) selected, it'll select all the other polys in the layer that have the same parts assigned if you append the word "part" to the end of the line that runs this script..  #ex. @selectRest.pl part

#(9-26-07 bugfix) : cleaned up the really old code, sped the script up a whole lot and fixed a bug with verts that had multiple selection sets.
#(4-7-08 bugfix) : fixed a bug with material names that had multiple words
#(1-9-09 feature) : made it so the script works in all active layers

#SCRIPT ARGUMENTS :
# "part" : If you have some poly(s) selected, it'll select all the other polys in the layer that have the same parts assigned.
# "noDefault" : If you want it to ignore the default part name that's literally called "Default", append that cvar.



my $mainlayer = lxq("query layerservice layers ? main");
my %selectionTable;
my %table;

#------------------------------------------------------------------------------------
#Script arguments
#------------------------------------------------------------------------------------
foreach my $arg (@ARGV){
	if 		($arg =~ /part/i)		{	our $part = 1;		}
	elsif	($arg =~ /noDefault/i)	{	our $noDefault = 1;	}
}

#------------------------------------------------------------------------------------
#Selection modes
#------------------------------------------------------------------------------------
if		( lxq( "select.typeFrom {vertex;edge;polygon;item} ?" ) )	{	our $mode = vert;	our $query = "";}
elsif	( lxq( "select.typeFrom {edge;polygon;item;vertex} ?" ) )	{	our $mode = edge;	}
elsif	( lxq( "select.typeFrom {polygon;item;vertex;edge} ?" ) )	{	our $mode = poly;	}
else																{	die("\\\\n.\\\\n[---------------------------------------------You're not in vert, edge, or polygon mode.--------------------------------------------]\\\\n[--PLEASE TURN OFF THIS WARNING WINDOW by clicking on the (In the future) button and choose (Hide Message)--] \\\\n[-----------------------------------This window is not supposed to come up, but I can't control that.---------------------------]\\\\n.\\\\n");	}

#get selection
selectionFind(\%selectionTable,$mode);

foreach my $key (keys %selectionTable){
	my $layerName = lxq("query layerservice layer.name ? $key");

	foreach my $element (@{$selectionTable{$key}}){
		#poly part
		if (($mode eq "poly") && ($part == 1)){
			my $part = lxq("query layerservice poly.part ? $element");
			$table{$part} = 1;
		}

		#poly material
		elsif ($mode eq "poly"){
			my $material = lxq("query layerservice poly.material ? $element");
			$table{$material} = 1;
		}

		#vert and edge
		else{
			my @selSets = lxq("query layerservice $mode.selSets ? $element");
			foreach my $selSet (@selSets){
				$table{$selSet} = 1;
			}
		}
	}
}

#select the part or material or selection set.
foreach my $key (keys %table){
	#poly part
	if (($mode eq "poly") && ($part == 1)){
		if (($noDefault == 1) && ($key eq "Default")){
			lx("!!select.polygon remove part face {$key}");
		}else{
			lxout("[->] Selecting Polygon Part : $key");
			lx("!!select.polygon add part face {$key}");
		}
	}

	#poly material
	elsif ($mode eq "poly"){
		lxout("[->] Selecting material : $key");
		lx("!!select.polygon add material face {$key}");
	}

	#vert and edge
	else{
		lxout("[->] Selecting Selection Set : $key");
		lx("select.useSet {$key} select");
	}
}




#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#SELECTION FIND SUBROUTINE (return a table of each layer's selection)
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#usage : my %table;  selectionFind(\%table,poly);
sub selectionFind{
	my $hash = @_[0];
	my @selection = lxq("query layerservice selection ? @_[1]");
	for (my $i=0; $i<@selection; $i++){
		my @array = split (/[^0-9]/, @selection[$i]);
		if (@_[1] ne "edge"){
			push(@{$$hash{@array[1]}},@array[2]);
		}else{
			push(@{$$hash{@array[1]}},"(".@array[2].",".@array[3].")");
		}
	}
}




