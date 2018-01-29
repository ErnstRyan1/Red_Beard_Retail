#perl
#AUTHOR: Seneca Menard
#version 1.75
#This script is for edge slicing or adding a vert at the center of the edge.
# - If you have multiple edges selected, I'll do an edge slice.
# - If you have one edge selected, I'll add a point at the center of the edge, do a poly fan triple to all it's connected verts, and put you in the move tool because that's generally what I want to use next.
# - If you have verts selected, it'll select the loop of edges touching that vert and then turn on loop slice
# - (8-7-07 feature) : if you wanna add a vert to your selected edge and don't want to have it split the polys from that vert, just append "noSplit" to the script line.  ie : "@edgeSliceorAddVert.pl noSplit"
# - (8-7-07 bugfix) : it won't perform a poly fan triple on polys that are hidden.
# - (7-20-09 bugfix) : was using selection sets to retain vert info, but modo's got a bug with that, so i'm skipping that now.

#TEMP : vert mode needs to determine the edge order itself, as vert.vertList won't return an accurate result 100% of the time.


#---------------------------------------------------------------------------------------------------------------------------------
#SETUP-----------------------------------------------------------------------------------------------------------------------
#---------------------------------------------------------------------------------------------------------------------------------
my $mainlayer = lxq("query layerservice layers ? main");
my @edges = lxq("query layerservice edges ? selected");
my $singleEdge = 0;

#CHECK IF SYMMETRY IS ON or OFF, CONVERT THE SYMM AXIS TO MY OLDSCHOOL NUMBER, TURN IT OFF.
our $symmAxis = lxq("select.symmetryState ?");
if 		($symmAxis eq "none")	{	$symmAxis = 3;	}
elsif	($symmAxis eq "x")		{	$symmAxis = 0;	lx("select.symmetryState none");}
elsif	($symmAxis eq "y")		{	$symmAxis = 1;	lx("select.symmetryState none");}
elsif	($symmAxis eq "z")		{	$symmAxis = 2;	lx("select.symmetryState none");}

#CVARS
foreach my $arg (@ARGV){
	if ($arg =~ /noSplit/i)			{	our $noSplit = 1;	}
}


#-----------------------------------------------------------
#POLY MODE-----------------------------------------
#-----------------------------------------------------------
if( lxq( "select.typeFrom {polygon;item;vertex;edge} ?" ) ){
	lxout("[->] POLY MODE");
	&edgeSlice;
}

#-----------------------------------------------------------
#EDGE MODE-----------------------------------------
#-----------------------------------------------------------
elsif( lxq( "select.typeFrom {edge;polygon;item;vertex} ?" ) ){
	lxout("[->] EDGE MODE");
	lx("select.drop polygon");
	lx("select.type edge");

	#-----------------------------------------------------------
	#EXECUTE SCRIPT WITH SYMMETRY OFF
	#-----------------------------------------------------------
	if ($symmAxis ==  3){
		if (@edges == 1){
			&polyFanTripleSetup;
		}elsif (@edges > 1){
			lxout("edge slice");
			&edgeSlice;
		}
	}

	#-----------------------------------------------------------
	#EXECUTE SCRIPT WITH SYMMETRY ON
	#-----------------------------------------------------------
	else{
		if (@edges == 2){
			lxout("[->] symmetrical edges selected");
			my @pos0 = lxq("query layerservice edge.pos ? @edges[0]");
			my @pos1 = lxq("query layerservice edge.pos ? @edges[1]");

			#edges are on opposite sides of the symmaxis, so I should poly fan triple both
			if ((@pos0[$symmAxis] > 0)&&(@pos1[$symmAxis] < 0) || (@pos0[$symmAxis] < 0)&&(@pos1[$symmAxis] > 0)){
				lxout("edges opposite, so doing poly fan triple");
				$singleEdge = 0;
				my @backupEdges = @edges;
				@edges = @backupEdges[0];
				&polyFanTripleSetup;
				@edges = @backupEdges[1];
				&polyFanTripleSetup;
			}
			#edges are both on the same side of the symmaxis, so I should run edge slice.
			else{
				lxout("edges on same side, so doing edge slice");
				&edgeSlice;
			}

		#one edge, so do polyfan.
		}elsif (@edges == 1){
			lxout("[->] only one asymmetrial edge selected");
			$singleEdge = 1;
			&polyFanTripleSetup;
		}
		#more than one edge, so do edge slice.
		elsif (@edges > 2){
			&edgeSlice;
		}
	}
}

#-----------------------------------------------------------
#VERT MODE-----------------------------------------
#-----------------------------------------------------------
elsif( lxq( "select.typeFrom {vertex;edge;polygon;item} ?" ) ){
	lxout("[->] VERT MODE");
	my @verts = lxq("query layerservice verts ? selected");
	lx("select.drop edge");
	foreach my $vert (@verts){
		my @vertList = lxq("query layerservice vert.vertList ? $vert");
		for (my $i=0; $i<@vertList; $i++){
			lx("select.element $mainlayer edge add $vert $vertList[$i]");
		}
	}

	lx("tool.set poly.loopSlice on");
}




#---------------------------------------------------------------------------------------------------------------------------------
#POLY FAN TRIPLE SETUP SUBROUTINE------------------------------------------------------------------------
#---------------------------------------------------------------------------------------------------------------------------------
sub polyFanTripleSetup{
	lxout("[->] Performing a poly fan triple.");

	#find edge and it's verts
	tr/()//d for @edges;
	my @verts = split(/,/, @edges[0]);
	my $poo1 = $mainlayer-1 . "," . @verts[0];
	my $poo2 = $mainlayer-1 . "," . @verts[1];

	#add the point with edge knife
	lx("tool.set edge.knife on");
	lx("tool.reset");
	lx("tool.attr edge.knife split 0");
	lx("tool.setAttr edge.knife count 1");
	lx("tool.setAttr edge.knife vert0 $poo1");
	lx("tool.setAttr edge.knife vert1 $poo2");
	lx("tool.setAttr edge.knife pos [50.0 %]");
	lx("tool.doApply");
	lx("tool.set edge.knife off");

	#get info on last vert
	our @verts = lxq("query layerservice verts ? all");
	@verts = @verts[-1];
	lx("select.type vertex");
	if ($noSplit != 1){
		&polyFanTriple;
	}

	#drop edges and select the last vert(s)
	lx("select.drop edge");
	lx("select.drop vertex");
	lx("select.element $mainlayer vert add @verts[-1]");
	my $symmVert = @verts[-1]-1;
	if (($symmAxis != 3) && ($singleEdge == 0)){ lx("select.element {$mainlayer} vert add $symmVert");}

	#set move tool on
	lx("tool.set xfrm.move on");
}


#---------------------------------------------------------------------------------------------------------------------------------
#POLY FAN TRIPLE SUBROUTINE-----------------------------------------------------------------------------------
#---------------------------------------------------------------------------------------------------------------------------------
sub polyFanTriple{
	my %vertList;
	#create the hash of verts on the connected polys
	my @polys = lxq("query layerservice vert.polyList ? @verts[0]");
	foreach my $poly (@polys){
		my $hidden = lxq("query layerservice poly.hidden ? $poly");
		lxout("poly $poly hidden = $hidden");

		if (lxq("query layerservice poly.hidden ? $poly") == 0){
			#lxout("doing this poly $poly");
			my @verts = lxq("query layerservice poly.vertList ? $poly");
			foreach my $vert (@verts){
				$vertList{$vert} = 1;
				#lxout("$vert");
			}
		}
	}
	#prune the hash of the connected edge verts
	my @connectedVertList = lxq("query layerservice vert.vertList ? @verts[0]");
	foreach my $vert (@connectedVertList){	delete $vertList{$vert};}
	delete $vertList{@verts[0]};
	my $keyCount = keys %vertList;
	#lxout("number of cuts  = $keyCount");

	#select the verts and split the polys
	foreach my $vert (keys %vertList){
		#lxout("$vert");
		lx("select.drop vertex");
		lx("select.element $mainlayer vert add @verts[0]");
		lx("select.element $mainlayer vert add $vert");
		lx("poly.split");
	}

	#drop vert selection
	lx("select.drop vertex");
}



#---------------------------------------------------------------------------------------------------------------------------------
#EDGE SLICE SUBROUTINE------------------------------------------------------------------------------------------
#---------------------------------------------------------------------------------------------------------------------------------
sub edgeSlice{
	lxout("[->] Performing a normal edge slice.");
	lx("tool.set poly.loopSlice on");
	lx("tool.attr poly.loopSlice edit [0]");
	lx("tool.attr poly.loopSlice mode [0]");
	lx("tool.attr poly.loopSlice curr [0]");
	lx("tool.attr poly.loopSlice count [1]");
	lx("tool.attr poly.loopSlice select 1");
}




#---------------------------------------------------------------------------------------------------------------------------------
#POPUP SUBROUTINE--------------------------------------------------------------------------------------------------
#---------------------------------------------------------------------------------------------------------------------------------
sub popup #(MODO2 FIX)
{
	lx("dialog.setup yesNo");
	lx("dialog.msg {@_}");
	lx("dialog.open");
	my $confirm = lxq("dialog.result ?");
	if($confirm eq "no"){die;}
}




#---------------------------------------------------------------------------------------------------------------------------------
#SYMMETRY CLEANUP--------------------------------------------------------------------------------------------------
#---------------------------------------------------------------------------------------------------------------------------------
#Set Symmetry back
if ($symmAxis != 3)
{
	#CONVERT MY OLDSCHOOL SYMM AXIS TO MODO's NEWSCHOOL NAME
	if 		($symmAxis == "3")	{	$symmAxis = "none";	}
	elsif	($symmAxis == "0")	{	$symmAxis = "x";		}
	elsif	($symmAxis == "1")	{	$symmAxis = "y";		}
	elsif	($symmAxis == "2")	{	$symmAxis = "z";		}
	lxout("turning symm back on ($symmAxis)"); lx("!!select.symmetryState $symmAxis");
}


