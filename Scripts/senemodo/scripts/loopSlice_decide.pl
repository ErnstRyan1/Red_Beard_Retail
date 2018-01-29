#perl
#Author : Seneca Menard
#ver 1.0

#This script is just a small modification of loop slicing.
#If you have only one edge selected, SLICE SELECTED turns OFF.
#If you have multiple edges selected, SLICE SELECTED turns ON.
#If you are not in edge mode, it doesn't bother with that option.



if( lxq( "select.typeFrom {edge;polygon;item;vertex} ?" ) ) {
	my @edges = lxq("query layerservice selection ? edge");
	if (@edges == 0){ die("You don't have any edges selected so I'm killing the script");}
	my @layerIndex = split (/[^0-9]/, @edges[0]);
	my $mainlayerName = lxq("query layerservice layer.name ? @layerIndex[0]");
	my $sliceSelected = 1;

	#CONVERT THE SYMM AXIS TO MY OLDSCHOOL NUMBER AND TURN IT OFF
	our $symmAxis = lxq("select.symmetryState ?");
	if 		($symmAxis eq "none")	{	$symmAxis = 3;	}
	elsif	($symmAxis eq "x")		{	$symmAxis = 0;	}
	elsif	($symmAxis eq "y")		{	$symmAxis = 1;	}
	elsif	($symmAxis eq "z")		{	$symmAxis = 2;	}

	if ($symmAxis != 3){
		if (@edges == 2){
			s/\(\d{0,},/\(/  for @edges;
			my @pos1 = lxq("query layerservice edge.pos ? @edges[0]");
			my @pos2 = lxq("query layerservice edge.pos ? @edges[1]");

			lxout("pos1 = @pos1");
			lxout("pos2 = @pos2");
			if ($symmAxis == 0){
				if ((@pos1[0]==-@pos2[0]) && (@pos1[1]==@pos2[1]) && (@pos1[2]==@pos2[2]))	{	$sliceSelected=0;	}
			}elsif	($symmAxis == 1){
				if ((@pos1[0]==@pos2[0]) && (@pos1[1]==-@pos2[1]) && (@pos1[2]==@pos2[2]))	{	$sliceSelected=0;	}
			}else{
				if ((@pos1[0]==@pos2[0]) && (@pos1[1]==@pos2[1]) && (@pos1[2]==-@pos2[2]))	{	$sliceSelected=0;	}
			}
		}elsif (@edges == 1){
			$sliceSelected=0;
		}
	}else{
		if (@edges == 1){
			$sliceSelected=0;
		}
	}

	lx("tool.set poly.loopSlice on");
	lx("tool.attr poly.loopSlice select $sliceSelected");
}else{
	lx("tool.set poly.loopSlice on");
}
