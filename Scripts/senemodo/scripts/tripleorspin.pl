#perl
#TRIPLE OR SPLIT OR SPIN
#AUTHOR: Seneca Menard
#version 1.66
#This tool merges POLYGON TRIPLING, POLYGON SPLITTING, and EDGE SPINNING into one tool.
#
#-If you have VERTS selected, it will split the polygons(s)
#-If you have EDGES selected, it will spin those edge(s)
#-If you have only 3pt POLYGONS selected, it will spin those tris.
#-If nothing's selected, it will triple.
#-5-15-06 (new feature) if you have only 1 vert selected, it'll triple the connected polygons to that vert.  (some people call that a "poly fan" triple)
#-8-12-06 (bugfix) The 5-15-06 feature is improved.  It's now does a number of poly splits instead of a sloppy bevelittle hack and thus the UVs are retained.  Plus it works properly in symmetry now.
#-8-07-07 (bugfix) When you're doing a poly fan triple, it doesn't try to do that on hidden polys.  heh.  oops.
#-8-1-09 (bugfix) Fixed a bug with the poly fan triple code

my $mainlayer = lxq("query layerservice layers ? main");

#CONVERT THE SYMM AXIS TO MY OLDSCHOOL NUMBER
our $symmAxis = lxq("select.symmetryState ?");
if 		($symmAxis eq "none")	{	$symmAxis = 3;	}
elsif	($symmAxis eq "x")		{	$symmAxis = 0;	}
elsif	($symmAxis eq "y")		{	$symmAxis = 1;	}
elsif	($symmAxis eq "z")		{	$symmAxis = 2;	}



#-------------------------------------------------------------------------------------------------------------------
#if you're in EDGE mode and have some selected, it'll spin the edges
#-------------------------------------------------------------------------------------------------------------------
if( lxq( "select.typeFrom {edge;polygon;item;vertex} ?" ) ){
	if (lxq("select.count edge ?")){
			lx("!!edge.spinQuads");
	}else{ #otherwise it'll just triple ALL polygons
			lx("!!poly.triple");
	}
}

#-------------------------------------------------------------------------------------------------------------------
#if you're in VERTEX mode and have some selected, it'll split the edges
#-------------------------------------------------------------------------------------------------------------------
elsif( lxq( "select.typeFrom {vertex;edge;polygon;item} ?" ) ){
	our @verts = lxq("query layerservice verts ? selected");

	#--------------------------------------------------
	# fan triple the vert's polys' verts
	#--------------------------------------------------
	if ((lxq("select.symmetryState ?") ne "none") && (@verts == 2)){
		lxout("[->] symm poly fan split");
		lx("select.symmetryState none");

		my @firstVertPos = lxq("query layerservice vert.pos ? @verts[0]");
		my @secondVertPos = lxq("query layerservice vert.pos ? @verts[1]");
		if (@firstVertPos[$symmAxis] == (@secondVertPos[$symmAxis]*-1) && (@firstVertPos[$symmAxis] != 0) && (@secondVertPos[$symmAxis] != 0)){
			&polyFanTriple(@verts[0]);
			&polyFanTriple(@verts[1]);
		}
		else{
			lxout("[->] symm polyfan fail, so doing a split");
			lx("!!select.drop polygon");
			lx("!!poly.split");
			lx("!!select.drop vertex");
		}
	}
	elsif (@verts == 1){
		lxout("[->] poly fan split");
		&polyFanTriple(@verts[0]);
	}

	#--------------------------------------------------
	#otherwise SPLIT the edges
	#--------------------------------------------------
	elsif (@verts != 0){
		lx("!!select.drop polygon");
		lx("!!poly.split");
		lx("!!select.drop vertex");
	}
	#--------------------------------------------------
	#otherwise it'll just triple ALL polygons
	#--------------------------------------------------
	else{
		lx("!!poly.triple");
	}
}

#-------------------------------------------------------------------------------------------------------------------
#if you're in POLYGON mode, it'll triple or spinquads
#-------------------------------------------------------------------------------------------------------------------
else{
	if( lxq( "select.count polygon ?") ){
		my $verxCount;
		my $triple = 0;
		lxq("query layerservice layers ? main");
		my @selectedPolys = lxq("query layerservice polys ? selected");

		#this will check to see if there are 3+ poly verts selected.
		foreach my $selectedPoly (@selectedPolys){
			$verxCount = lxq( "query layerservice poly.numVerts ? $selectedPoly");
			if ($verxCount > 3){
				($triple = 1); #if there are 3+ sided polygons, only triple
				last;
			}
		}

		if ($triple == 1){
			lxout("only triple");
			lx("!!poly.triple");
		}else{ #if there are only 3 sided polygons, spin edge
			lxout("only spin edge"); #
			lx("select.convert edge");
			lx("!!select.contract");
			lx("!!select.edge remove poly equal 1");

			#---------------------------------------------------------------------------------------------------
			#deselect any edges on the symmetry axis
			if ($symmAxis != 3){
				lxout("-SYMMETRY is on");
				my @edges = lxq("query layerservice edges ? selected");
				foreach my $edge (@edges){
					my @verts = split (/[^0-9]/, $edge);
					my @vert1Pos = lxq("query layerservice vert.pos ? @verts[1]");
					my @vert2Pos = lxq("query layerservice vert.pos ? @verts[2]");
					if ((@vert1Pos[$symmAxis] == 0) && (@vert2Pos[$symmAxis] == 0)){
						lxout("-Deselecting this SYMMETRY border edge ($edge)");
						lx("select.element $mainlayer edge remove @verts[1] @verts[2]");
					}
				}
			}
			#---------------------------------------------------------------------------------------------------
			lx("!!edge.spinQuads");
			lx("!!select.drop edge");
			lx("!!select.typeFrom {polygon;edge;vertex;item} [1]");
		}
	}
	else{  #if there's no poly selection, it'll triple everything
		lxout("no polys were selected.  only triple");
		lx("!!poly.triple");
	}
}





sub polyFanTriple{
	my %vertList;
	#create the hash of verts on the connected polys
	my @polys = lxq("query layerservice vert.polyList ? @_[0]");
	foreach my $poly (@polys){
		if (lxq("query layerservice poly.hidden ? $poly") == 0){
			my @verts = lxq("query layerservice poly.vertList ? $poly");
			foreach my $vert (@verts){
				$vertList{$vert} = 1;
			}
		}
	}

	#prune the hash of the connected edge verts
	my @connectedVertList = lxq("query layerservice vert.vertList ? @_[0]");
	foreach my $vert (@connectedVertList){	delete $vertList{$vert};}
	delete $vertList{@_[0]};
	my $keyCount = keys %vertList;
	lxout("number of cuts  = $keyCount");
	my $i = 0;
	#assign the vert selsets
	foreach my $vert (keys %vertList){
		lx("select.element $mainlayer vert set @_[0]");
		lx("select.element $mainlayer vert add $vert");
		lx("poly.split");
	}

	#drop vert selection
	lx("select.drop vertex");
}




sub popup #(MODO2 FIX)
{
	lx("dialog.setup yesNo");
	lx("dialog.msg {@_}");
	lx("dialog.open");
	my $confirm = lxq("dialog.result ?");
	if($confirm eq "no"){die;}
}

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
