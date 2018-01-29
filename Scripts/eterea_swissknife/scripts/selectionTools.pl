#perl
#ver 0.61
#author : Seneca Menard

#this script is for various selection subroutines to be used from macros.
# cutCubePipeIntoSides : this is for unwelding the sides of a 4 sided pipe plus endcaps.  handy for metal beams that are bent, because you can use the auto peeler on the resulting geometry.
# deselAllButThisMesh : this will deselect all the elements except for the ones that are on the mesh under the mouse.
# selUVIsland : will select uv island under mouse in 3d view.
# deselDiscoUVEdges : will deselect all border edges and all disco uv edges. (handy for edge removal) (only pays attention to the selected uv map. not all uv maps)
# deselEdgesWithTwoMatrls : will deselect all edges where the two polys they touch don't share the same material.
# selEdgesByUVFlatness : selects or deselects edges based off of how closely aligned to the horizontal or vertical axis they are.  Note that it's slightly out of alignment on 45 degree angle edges because of dotproduct math errors.
# selectFacesInSamePlane : selects or deselects polys whether or not they're in the same plane with teh last selected poly. The gui for this is called "sen_selectFacesInPlane"
# selConcaveConvexEdges : (uses the sen_selectConcavevexEdges gui) : this is for selecting or deselecting concave or convex edges.

#(3-6-11 bugfix) : deselecting edges had a small bug where it was off by one indice and would thus not reselect about 1% of edges.
#(3-17-12 feature) : a new gui called "sen_selectFacesInPlane" that's for selecting or deselecting polys that are in the same 3 dimensional plane as the last selected poly.


#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#setup
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
my $pi=3.14159265358979323;
my $modoVer = lxq("query platformservice appversion ?");
my $mainlayer = lxq("query layerservice layers ? main");


#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#user values :
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
userValueTools(sene_selEdgesByUvFlatAmt,float,config,"UV edge variance angle","","","",0,90,"",10);
userValueTools(sene_selFacesInSamePlaneDist,float,config,"Max distance","","","",-0,9999999999999999,"",.01);
userValueTools(sene_selFacesInSamePlaneAngle,float,config,"Max angle","","","",0,180,"",.1);
userValueTools(sene_selFacesInSamePlaneBackFace,boolean,config,"Select Backfaces Too","","","",xxx,xxx,"",1);


#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#script args :
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
foreach my $arg (@ARGV){
	if		($arg =~ /cutCubePipeIntoSides/i)		{	cutCubePipeIntoSides();			}
	elsif	($arg =~ /deselAllButThisMesh/i)		{	deselAllButThisMesh();			}
	elsif	($arg =~ /selUVIsland/i)				{	selUVIsland();					}
	elsif	($arg =~ /deselDiscoUVEdges/i)			{	deselDiscoUVEdges();			}
	elsif	($arg =~ /deselEdgesWithTwoMatrls/i)	{	deselEdgesWithTwoMatrls();		}
	elsif	($arg =~ /selEdgesByUVFlatness/i)		{	selEdgesByUVFlatness();			}
	elsif	($arg =~ /selEdgesToUnwrapOnCube/i)		{	selEdgesToUnwrapOnCube();		}
	elsif	($arg =~ /selectFacesInSamePlane/i)		{	selectFacesInSamePlane();		}
	elsif	($arg =~ /selColinearVertsOnEdgeLoop/i)	{	selColinearVertsOnEdgeLoop();	}
	elsif	($arg =~ /selConcaveConvexEdges/i)		{	selConcaveConvexEdges();		}
	elsif	($arg eq "concave")						{	our $edgeType = "concave";		}
	elsif	($arg eq "select")						{	our $selMode = "select";		}
	elsif	($arg eq "deselect")					{	our $selMode = "deselect";		}
	elsif	($arg eq "horizontal")					{	our $horizontal = 1;			}
	elsif	($arg eq "vertical")					{	our $vertical = 1;				}
	elsif	($arg eq "diagonal")					{	our $diagonal = 1;				}
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#SELECT CONCAVE OR CONVEX EDGES
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
sub selConcaveConvexEdges{
	my $selAction = "add";
	if ($selMode eq "deselect")	{	$selAction = "remove";									}

	my @edges;
	if ($selMode eq "deselect")	{	@edges = lxq("query layerservice edges ? selected");	}
	else						{	@edges = lxq("query layerservice edges ? visible");		}

	lx("select.type edge");

	foreach my $edge (@edges){
		my @polys = lxq("query layerservice edge.polyList ? $edge");
		if ( (@polys < 2) || (lxq("query layerservice poly.hidden ? $polys[0]") == 1) || (lxq("query layerservice poly.hidden ? $polys[1]") == 1) ){next;}
		my @normal1 = lxq("query layerservice poly.normal ? $polys[0]");
		my @polyPos1 = lxq("query layerservice poly.pos ? $polys[0]");
		my @polyPos2 = lxq("query layerservice poly.pos ? $polys[1]");
		my @polyToPolyVector = arrMath(@polyPos2,@polyPos1,subt);
		my $dp = dotProduct(\@normal1,\@polyToPolyVector);
		if ( ($edgeType eq "concave") && ($dp > 0.01) ){
			my @verts = split (/[^0-9]/, $edge);
			lx("select.element $mainlayer edge $selAction index:[$verts[1]] index2:[$verts[2]]");
		}elsif ( ($edgeType ne "concave") && ($dp < -0.01) ){
			my @verts = split (/[^0-9]/, $edge);
			lx("select.element $mainlayer edge $selAction index:[$verts[1]] index2:[$verts[2]]");
		}
	}
}


#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#SELECT COLINEAR VERTS ON EDGE LOOP
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
sub selColinearVertsOnEdgeLoop{
	my @edges = lxq("query layerservice edges ? selected");
	sortRowStartup(edgesSelected,@edges);
	my @verts = split (/[^0-9]/, $vertRowList[0]);
	if ($verts[-1] == $verts[0]){pop(@verts);}
	my @vertsToSel;

	for (my $i=0; $i<@verts; $i++){
		my @vertPos1 = lxq("query layerservice vert.pos ? $verts[$i-2]");
		my @vertPos2 = lxq("query layerservice vert.pos ? $verts[$i-1]");
		my @vertPos3 = lxq("query layerservice vert.pos ? $verts[$i]");
		my @vec1 = unitVector(arrMath(@vertPos2,@vertPos1,subt));
		my @vec2 = unitVector(arrMath(@vertPos2,@vertPos3,subt));
		my $dp = dotProduct(\@vec1,\@vec2);
		if ($dp < -0.999){
			push(@vertsToSel,$verts[$i-1]);
		}
	}

	lx("select.drop vertex");
	lx("select.element $mainlayer vertex add $_") for @vertsToSel;

}


#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#SELECT FACES IN SAME PLANE AS LAST SELECTED POLY
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
sub selectFacesInSamePlane{
	my $distCutoffPoint = lxq("user.value sene_selFacesInSamePlaneDist ?");
	my $dpCutoffPoint = lxq("user.value sene_selFacesInSamePlaneAngle ?");
	my $absolute = lxq("user.value sene_selFacesInSamePlaneBackFace ?");
	$dpCutoffPoint = $dpCutoffPoint*($pi/180);	#convert angle to radian.
	$dpCutoffPoint = cos($dpCutoffPoint);		#convert radian to DP.

	lxout("distCutoffPoint = $distCutoffPoint");
	lxout("dpCutoffPoint = $dpCutoffPoint");
	lxout("absolute = $absolute");

	my @polys = lxq("query layerservice polys ? selected");
	my @testPolyNormal = lxq("query layerservice poly.normal ? $polys[-1]");
	my @testPolyPos = lxq("query layerservice poly.pos ? $polys[-1]");
	my @testPolyPosUnitVector = unitVector(@testPolyPos);
	if ($selMode ne "deselect"){@polys = lxq("query layerservice polys ? visible");}
	my @polysToDeselect;
	my @polysToSelect;

	for (my $i=0; $i<@polys; $i++){
		my @polyNormal = lxq("query layerservice poly.normal ? $polys[$i]");
		my @polyPos = arrMath(lxq("query layerservice poly.pos ? $polys[$i]"),@testPolyPos,subt);
		my $planeItsctDist = dotProduct(\@testPolyNormal,\@polyPos);
		my $planarFacingDP = dotProduct(\@testPolyNormal,\@polyNormal);
		lxout("poly=$polys[$i] planeItsctDist=$planeItsctDist planarFacingDP=$planarFacingDP");

		#deselect
		if ($selMode eq "deselect"){
			if ($absolute == 1){
				if ( (abs($planeItsctDist) > $distCutoffPoint) || (abs($planarFacingDP) < $dpCutoffPoint) ){
					push(@polysToDeselect,$polys[$i]);
				}
			}else{
				if ( (abs($planeItsctDist) > $distCutoffPoint) || ($planarFacingDP < $dpCutoffPoint) ){
					push(@polysToDeselect,$polys[$i]);
				}
			}
		}
		#select
		else{
			lxout("yes");
			if ($absolute == 1){
				if ( (abs($planeItsctDist) < $distCutoffPoint) && (abs($planarFacingDP) > $dpCutoffPoint) ){
					push(@polysToSelect,$polys[$i]);
				}
			}else{
				if ( (abs($planeItsctDist) < $distCutoffPoint) && ($planarFacingDP > $dpCutoffPoint) ){
					push(@polysToSelect,$polys[$i]);
				}
			}
		}
	}

	lx("select.element $mainlayer polygon remove $_") for @polysToDeselect;
	lx("select.element $mainlayer polygon add $_") for @polysToSelect;
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#SELECT OR DESELECT EDGES BY UV FLATNESS (note does not work on disco edges)
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
sub selEdgesToUnwrapOnCube{
	my $polySelectCount = lxq("select.count polygon ?");
	my @polysToSelect;
	if ($polySelectCount > 0){
		our @polys = lxq("query layerservice polys ? selected");
	}else{
		our @polys = lxq("query layerservice polys ? visible");
	}

	my %todoPolyList;
	$todoPolyList{$_} = 1 for @polys;

	lx("!!select.drop edge");

	while ((keys %todoPolyList) > 0){
		my @connectedPolys = listTouchingPolys2((keys %todoPolyList)[0]);
		my %edgeTable;
		my $foundLongEdge = 0;

		if ( (@connectedPolys == 5) || (@connectedPolys == 6) ){
			push(@polysToSelect,$connectedPolys[0]);

			foreach my $poly (@connectedPolys){
				my @vertList = lxq("query layerservice poly.vertList ? $poly");
				my @vertPos0 = lxq("query layerservice vert.pos ? $vertList[0]");
				my @vertPos1 = lxq("query layerservice vert.pos ? $vertList[1]");
				my @vertPos2 = lxq("query layerservice vert.pos ? $vertList[2]");

				my @vec1 = arrMath(@vertPos1,@vertPos0,subt);
				my @vec2 = arrMath(@vertPos2,@vertPos1,subt);

				my $dist1 = abs(sqrt(($vec1[0]*$vec1[0])+($vec1[1]*$vec1[1])+($vec1[2]*$vec1[2])));
				my $dist2 = abs(sqrt(($vec2[0]*$vec2[0])+($vec2[1]*$vec2[1])+($vec2[2]*$vec2[2])));
				my $div;

				if ($dist1 > $dist2)	{	$div = $dist1 / $dist2	}
				else					{	$div = $dist2 / $dist1;	}

				if ($div < 8){
					if ($dist1 > $dist2){
						lx("!!select.element $mainlayer edge add $vertList[-1] $vertList[0]");
						lx("!!select.element $mainlayer edge add $vertList[1] $vertList[2]");
						lx("!!select.element $mainlayer edge add $vertList[2] $vertList[3]");
					}else{
						lx("!!select.element $mainlayer edge add $vertList[0] $vertList[1]");
						lx("!!select.element $mainlayer edge add $vertList[1] $vertList[2]");
						lx("!!select.element $mainlayer edge add $vertList[2] $vertList[3]");
					}
				}

				elsif ($foundLongEdge == 0){
					if ($dist1 > $dist2){
						lx("!!select.element $mainlayer edge add $vertList[0] $vertList[1]");
					}else{
						lx("!!select.element $mainlayer edge add $vertList[1] $vertList[2]");
					}
					$foundLongEdge = 1;
				}
			}
		}
		delete $todoPolyList{$_} for @connectedPolys;
	}

	if (@polysToSelect > 0){
		lx("select.drop polygon");
		lx("select.element $mainlayer polygon add $_") for @polysToSelect;
		lx("select.connect");
		lx("hide.unsel");
	}
}


#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#SELECT OR DESELECT EDGES BY UV FLATNESS (note does not work on disco edges)
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#note : should convert math from dotproducts to angles because dotproducts are shifted to the right when you're in the 45 degree angle zone.
sub selEdgesByUVFlatness{
	lx("select.type edge");

	if ($selMode eq "deselect")	{	our $selMethod = "remove";		}
	else						{	our $selMethod = "add";			}

	my @vecToMatch = (1,0);
	my $vecDir =							   "horizAndVertical";
	if		($horizontal == 1)	{	$vecDir = "horizontal";			}
	elsif	($vertical == 1)	{	$vecDir = "vertical";			}
	elsif	($diagonal == 1)	{	$vecDir = "diagonal";			}
	selectVmap();

	lx("user.value sene_selEdgesByUvFlatAmt");
	if (lxres != 0){	die("The user hit the cancel button");	}
	my $varianceAngle = lxq("user.value sene_selEdgesByUvFlatAmt ?");
	my $dp_facingRatio = $varianceAngle*($pi/180);	#convert angle to radian.
	$dp_facingRatio = cos($dp_facingRatio);			#convert radian to DP.
	my $inverseDP = 1 - $dp_facingRatio;

	if ($selMode ne "deselect"){
		our @edges = lxq("query layerservice edges ? visible");
	}else{
		our @edges = lxq("query layerservice edges ? selected");
	}

	foreach my $edge (@edges){
		my @polyList = lxq("query layerservice edge.polyList ? $edge");
		my @edgeUVValues = findEdgeUVValues($polyList[0],$edge);
		my @uvVec = (@edgeUVValues[2] - @edgeUVValues[0] , @edgeUVValues[3] - @edgeUVValues[1]);
		if ((@uvVec[0] == 0) && (@uvVec[1] == 0)){lxout("$edge is 0");}
		@uvVec = unitVector2d(@uvVec);
		my $dp = abs(dotProduct2d(\@uvVec,\@vecToMatch));

		if		($vecDir eq "horizAndVertical"){
			if (($dp >= $dp_facingRatio) || ($dp <= $inverseDP)){
				my @verts = split (/[^0-9]/, $edge);
				lx("select.element $mainlayer edge $selMethod $verts[1] $verts[2]");
			}
		}elsif	($vecDir eq "horizontal"){
			if ($dp >= $dp_facingRatio){
				my @verts = split (/[^0-9]/, $edge);
				lx("select.element $mainlayer edge $selMethod $verts[1] $verts[2]");
			}
		}elsif	($vecDir eq "vertical"){
			if ($dp <= $inverseDP){
				my @verts = split (/[^0-9]/, $edge);
				lx("select.element $mainlayer edge $selMethod $verts[1] $verts[2]");
			}
		}elsif	($vecDir eq "diagonal"){
			if (($dp <= .707 + $inverseDP) && ($dp >= .707 - $inverseDP)){
				my @verts = split (/[^0-9]/, $edge);
				lx("select.element $mainlayer edge $selMethod $verts[1] $verts[2]");
			}
		}else{
			die("vecDir cvar isn't correct so I'm cancelling the script.");
		}
	}
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#DESELECT DISCO UV EDGES (also desels border edges)
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
sub deselDiscoUVEdges{
	selectVmap();
	lx("select.edge remove bond equal (none)");
	my @edgeSel = lxq("query layerservice edges ? selected");

	foreach my $edge (@edgeSel){
		my @polyList = lxq("query layerservice edge.polyList ? $edge");
		my @edgeUVValues1 = findEdgeUVValues($polyList[0],$edge);
		my @edgeUVValues2 = findEdgeUVValues($polyList[1],$edge);

		if ( ($edgeUVValues1[0] != $edgeUVValues2[0]) || ($edgeUVValues1[1] != $edgeUVValues2[1]) || ($edgeUVValues1[2] != $edgeUVValues2[2]) || ($edgeUVValues1[3] != $edgeUVValues2[3])){
			my @verts = split (/[^0-9]/, $edge);
			lx("select.element $mainlayer edge remove @verts[1] @verts[2]");
		}
	}
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#DESELECT EDGES TOUCHING TWO DIFFERENT MATERIALS
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
sub deselEdgesWithTwoMatrls{
	my @edges = lxq("query layerservice edges ? selected");
	foreach my $edge (@edges){
		my @polyList = lxq("query layerservice edge.polyList ? $edge");
		my $material1 = lxq("query layerservice poly.material ? $polyList[0]");
		my $material2 = lxq("query layerservice poly.material ? $polyList[1]");
		if ($material1 ne $material2){
			my @verts = my @verts = split (/[^0-9]/, $edge);
			lx("select.element $mainlayer edge remove @verts[1] @verts[2]");
		}
	}
}


#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#SELECT UV ISLAND UNDER MOUSE
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
sub selUVIsland{
	lx("select.3DElementUnderMouse set");
	lx("select.connect uv");
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#DESELECT ELEMENTS ON ALL MESHES BUT ONE UNDER MOUSE
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
sub deselAllButThisMesh{
	my $view = lxq("query view3dservice mouse.view ?");
	my $poly = lxq("query view3dservice element.over ? POLY");
	my @layerPoly = split(/,/, $poly);

	#VERTS
	if		(lxq( "select.typeFrom {vertex;edge;polygon;item} ?" )){
		my %selVertTable;
		my %vertTable;
		my @verts = lxq("query layerservice verts ? selected");
		$selVertTable{$_} = 1 for @verts;

		my @connectedPolys = listTouchingPolys2($layerPoly[1]);
		foreach my $poly (@connectedPolys){
			my @polyVertList = lxq("query layerservice poly.vertList ? $poly");
			$vertTable{$_} = 1 for @polyVertList;
		}

		lx("select.drop vertex");
		lx("select.elmBatchBegin layer:$mainlayer type:vertex");
		foreach my $vert (keys %vertTable){
			if ($selVertTable{$vert} == 1)	{	lx("select.elmBatchAdd $vert");	}
		}
		lx("select.elmBatchComplete");
	}

	#EDGES
	elsif	(lxq( "select.typeFrom {edge;polygon;item;vertex} ?" )){
		my %selEdgeTable;
		my %edgeTable;
		my @edges = lxq("query layerservice edges ? selected");
		foreach my $edge (@edges){
			my @verts = split(/[^0-9]/,$edge);
			if ($verts[1] < $verts[2]){
				$selEdgeTable{$verts[1] . "," . $verts[2]} = 1;
			}else{
				$selEdgeTable{$verts[2] . "," . $verts[1]} = 1;
			}
		}

		my @connectedPolys = listTouchingPolys2($layerPoly[1]);
		foreach my $poly (@connectedPolys){
			my @polyVertList = lxq("query layerservice poly.vertList ? $poly");
			for (my $i=-1; $i<$#polyVertList; $i++){
				if ($polyVertList[$i] < $polyVertList[$i+1]){
					$edgeTable{$polyVertList[$i] . "," . $polyVertList[$i+1]} = 1;
				}else{
					$edgeTable{$polyVertList[$i+1] . "," . $polyVertList[$i]} = 1;
				}
			}
		}

		lx("select.drop edge");
		#lx("select.elmBatchBegin layer:$mainlayer type:edge");
		foreach my $edge (keys %edgeTable){
			if ($selEdgeTable{$edge} == 1)	{
				my @verts = split(/,/, $edge);
				lx("select.element $mainlayer edge add index:$verts[0] index2:$verts[1]");
				#lx("select.elmBatchAdd index:{$verts[0]} index2:{$verts[1]}");
			}
		}
		#lx("select.elmBatchComplete");
	}

	#POLYS
	elsif	(lxq( "select.typeFrom {polygon;item;vertex;edge} ?" )){
		my %selPolyTable;
		my %polyTable;
		my @polys = lxq("query layerservice polys ? selected");
		$selPolyTable{$_} = 1 for @polys;

		my @connectedPolys = listTouchingPolys2($layerPoly[1]);
		$polyTable{$_} = 1 for @connectedPolys;

		lx("select.drop polygon");
		lx("select.elmBatchBegin layer:$mainlayer type:polygon");
		foreach my $poly (keys %polyTable){
			if ($selPolyTable{$poly} == 1)	{	lx("select.elmBatchAdd $poly");	}
		}
		lx("select.elmBatchComplete");
	}

	else{
		die("You're not in VERT, EDGE, or POLY mode and so I'm cancelling the script");
	}
}


#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#CUT CUBE PIPE INTO SIDES (and assigns senetemp sel set)
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
sub cutCubePipeIntoSides{
	#set senetemp selection set
	lx("select.connect");
	lx("select.editSet senetempBeam add");

	#setup
	my @polys = lxq("query layerservice polys ? selected");
	my $polyCount = lxq("query layerservice poly.n ? all");
	my %todoPolyTable;	$todoPolyTable{$_} = 1 for @polys;
	my %polyGroupTable;
	my @changedPolys;

	#determine poly groups
	my $count = 0;
	while ((keys %todoPolyTable) > 0){
		my @connectedPolys = listTouchingPolys2((keys %todoPolyTable)[0]);
		delete $todoPolyTable{$_} for @connectedPolys;
		$polyGroupTable{$count} = \@connectedPolys;
		$count++;
	}

	#go thru each poly group
	foreach my $key (keys %polyGroupTable){
		my @endCapPolys;
		my @newlyChangedPolys = sort { $a <=> $b } @{$polyGroupTable{$key}};
		returnCorrectIndice(\@newlyChangedPolys,\@changedPolys);

		#find end cap polys
		foreach my $poly (@newlyChangedPolys){
			my @verts = lxq("query layerservice poly.vertList ? $poly");
			my $threePolyVertCounter = 0;

			foreach my $vert (@verts){
				my $numPolys = lxq("query layerservice vert.numPolys ? $vert");
				if ($numPolys == 3){
					$threePolyVertCounter++;
				}else{
					last;
				}

				if ($threePolyVertCounter > 2)	{
					push(@endCapPolys,$poly);
					last;
				}
			}

			if (@endCapPolys == 2){	last;	}
		}

		#assign selset to end cap polys
		if (@endCapPolys != 0){
			lx("select.drop polygon");
			lx("select.element $mainlayer polygon add $_") for @endCapPolys;
			lx("select.editSet senetempCap add");
		}else{
			die("canceling this script because at least one of the rails doesn't have an end cap");
		}


		#assign selset to entire tube
		lx("select.connect");
		lx("select.editSet senetempTube add");

		if ($modoVer < 500){
			lx("select.drop polygon");
			lx("select.useSet senetempCap select");
			@endCapPolys = lxq("query layerservice polys ? selected");
		}

		#select poly loop
		my @polyVertList = lxq("query layerservice poly.vertList ? {$endCapPolys[0]}");
		my $edge = "(" . $polyVertList[0] . "," . $polyVertList[1] . ")";
		my @edgePolyList = lxq("query layerservice edge.polyList ? {$edge}");
		my $polyToSelect;
		if ($edgePolyList[0] != $endCapPolys[0])	{	$polyToSelect = $edgePolyList[0];	}
		else										{	$polyToSelect = $edgePolyList[1];	}
		lx("select.element {$mainlayer} polygon set {$endCapPolys[0]}");
		lx("select.element {$mainlayer} polygon add {$polyToSelect}");
		lx("select.loop");

		#cut/paste loop
		lx("select.cut");
		lx("select.paste");

		#cut/paste caps
		lx("select.drop polygon");
		lx("select.useSet senetempCap select");
		lx("select.editSet senetempCap remove");
		lx("select.cut");
		lx("select.paste");

		#cut/paste entire tube
		lx("select.useSet senetempTube select");
		lx("select.editSet senetempTube remove");
		lx("select.cut");
		lx("select.paste");
	}
}










#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#RETURN CORRECT INDICES SUB : (this is for finding the new poly indices when they've been corrupted because of earlier poly indice changes)
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE : returnCorrectIndice(\@currentPolys,\@changedPolys);
#notes : both arrays must be numerically sorted first.  Also, it'll modify both arrays with the new numbers
sub returnCorrectIndice{
	my @firstElems;
	my @lastElems;
	my %inbetweenElems;
	my @newList;

	#1 : find where the elements go in the old array
	foreach my $elem (@{@_[0]}){
		my $loop = 1;
		my $start = 0;
		my $end = $#{@_[1]};

		#less than the array
		if (($elem == 0) || ($elem < @{@_[1]}[0])){
			push(@firstElems,$elem);
		}
		#greater than the array
		elsif ($elem > @{@_[1]}[-1]){
			push(@lastElems,$elem);
		}
		#in the array
		else{
			while($loop == 1){
				my $currentPoint = int((($start + $end) * .5 ) + .5);

				if ($end == $start + 1){
					$inbetweenElems{$elem} = $currentPoint;
					$loop = 0;
				}elsif ($elem > @{@_[1]}[$currentPoint]){
					$start = $currentPoint;
				}elsif ($elem < @{@_[1]}[$currentPoint]){
					$end = $currentPoint;
				}else{
					popup("Oops.  The returnCorrectIndice sub is failing with this element : ($elem)!");
				}
			}
		}
	}

	#2 : now get the new list of elements with their new names
	#inbetween elements
	for (my $i=@firstElems; $i<@{@_[0]} - @lastElems; $i++){
		@{@_[0]}[$i] = @{@_[0]}[$i] - ($inbetweenElems{@{@_[0]}[$i]});
	}
	#last elements
	for (my $i=@{@_[0]}-@lastElems; $i<@{@_[0]}; $i++){
		@{@_[0]}[$i] = @{@_[0]}[$i] - @{@_[1]};
	}

	#3 : now update the used element list
	my $count = 0;
	foreach my $elem (sort { $a <=> $b } keys %inbetweenElems){
		splice(@{@_[1]}, $inbetweenElems{$elem}+$count,0, $elem);
		$count++;
	}
	unshift(@{@_[1]},@firstElems);
	push(@{@_[1]},@lastElems);
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#OPTIMIZED SELECT TOUCHING POLYGONS sub  (if only visible polys, you put a "hidden" check before vert.polyList point)
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE : my @connectedPolys = listTouchingPolys2(@polys[-$i]);
sub listTouchingPolys2{
	lxout("[->] LIST TOUCHING subroutine");
	my @lastPolyList = @_;
	my $stopScript = 0;
	our %totalPolyList = ();
	my %vertList;
	my %vertWorkList;
	my $vertCount;
	my $i = 0;

	#create temp vertList
	foreach my $poly (@lastPolyList){
		my @verts = lxq("query layerservice poly.vertList ? $poly");
		foreach my $vert (@verts){
			if ($vertList{$vert} == ""){
				$vertList{$vert} = 1;
				$vertWorkList{$vert}=1;
			}
		}
	}

	#--------------------------------------------------------
	#FIND CONNECTED VERTS LOOP
	#--------------------------------------------------------
	while ($stopScript == 0)
	{
		my @currentList = keys(%vertWorkList);
		%vertWorkList=();

		foreach my $vert (@currentList){
			my @verts = lxq("query layerservice vert.vertList ? $vert");
			foreach my $vert(@verts){
				if ($vertList{$vert} == ""){
					$vertList{$vert} = 1;
					$vertWorkList{$vert}=1;
				}
			}
		}

		$i++;

		#stop script when done.
		if (keys(%vertWorkList) == 0){
			#popup("round ($i) : it says there's no more verts in the hash table <><> I've hit the end of the loop");
			$stopScript = 1;
		}
	}

	#--------------------------------------------------------
	#CREATE CONNECTED POLY LIST
	#--------------------------------------------------------
	foreach my $vert (keys %vertList){
		my @polys = lxq("query layerservice vert.polyList ? $vert");
		foreach my $poly(@polys){
			$totalPolyList{$poly} = 1;
		}
	}

	return (keys %totalPolyList);
}

#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#FIND EDGE UV VALUES
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#usage : my @edgeUVValues = findEdgeUVValues($poly,$edge);
#note : (selectVmap has to have been run first)
#note : $edge has to be in this text format : (123,234);
sub findEdgeUVValues{
	my @vertList = lxq("query layerservice poly.vertList ? $_[0]");
	my @vmapValues = lxq("query layerservice poly.vmapValue ? $_[0]");
	my @edgeVerts = split(/[^0-9]/,$_[1]); #1,2 are the verts
	my $vmapValuesVertIndice1;
	my $vmapValuesVertIndice2;

	for (my $i=0; $i<@vertList; $i++){
		if ($vertList[$i] == $edgeVerts[1]){
			$vmapValuesVertIndice1 = $i;
		}elsif ($vertList[$i] == $edgeVerts[2]){
			$vmapValuesVertIndice2 = $i;
		}
	}

	return($vmapValues[$vmapValuesVertIndice1*2],$vmapValues[$vmapValuesVertIndice1*2+1],$vmapValues[$vmapValuesVertIndice2*2],$vmapValues[$vmapValuesVertIndice2*2+1]);
}

#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#UNIT VECTOR 2D
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#USAGE : my @unitVector2d = unitVector2d(@vector);
sub unitVector2d{
	my $dist1 = sqrt((@_[0]*@_[0])+(@_[1]*@_[1]));
	@_ = ((@_[0]/$dist1),(@_[1]/$dist1));
	return @_;
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#DOT PRODUCT 2D subroutine
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE : my $dp = dotProduct2d(\@vector1,\@vector2);
sub dotProduct2d{
	my @array1 = @{$_[0]};
	my @array2 = @{$_[1]};
	my $dp = (	(@array1[0]*@array2[0])+(@array1[1]*@array2[1]) );
	return $dp;
}

#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#SELECT THE PROPER VMAP  #MODO301
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
sub selectVmap{
	my $vmaps = lxq("query layerservice vmap.n ? all");
	my %uvMaps;
	my @selectedUVmaps;
	my $finalVmap;

	lxout("-Checking which uv maps to select or deselect");

	for (my $i=0; $i<$vmaps; $i++){
		if (lxq("query layerservice vmap.type ? $i") eq "texture"){
			if (lxq("query layerservice vmap.selected ? $i") == 1){push(@selectedUVmaps,$i);}
			my $name = lxq("query layerservice vmap.name ? $i");
			$uvMaps{$i} = $name;
		}
	}

	#ONE SELECTED UV MAP
	if (@selectedUVmaps == 1){
		lxout("     -There's only one uv map selected <> $uvMaps{@selectedUVmaps[0]}");
		$finalVmap = @selectedUVmaps[0];
	}

	#MULTIPLE SELECTED UV MAPS  (try to select "Texture")
	elsif (@selectedUVmaps > 1){
		my $foundVmap;
		foreach my $vmap (@selectedUVmaps){
			if ($uvMaps{$vmap} eq "Texture"){
				$foundVmap = $vmap;
				last;
			}
		}
		if ($foundVmap != "")	{
			lx("!!select.vertexMap $uvMaps{$foundVmap} txuv replace");
			lxout("     -There's more than one uv map selected, so I'm deselecting all but this one <><> $uvMaps{$foundVmap}");
			$finalVmap = $foundVmap;
		}
		else{
			lx("!!select.vertexMap $uvMaps{@selectedUVmaps[0]} txuv replace");
			lxout("     -There's more than one uv map selected, so I'm deselecting all but this one <><> $uvMaps{@selectedUVmaps[0]}");
			$finalVmap = @selectedUVmaps[0];
		}
	}

	#NO SELECTED UV MAPS (try to select "Texture" or create it)
	elsif (@selectedUVmaps == 0){
		lx("!!select.vertexMap Texture txuv replace") or $fail = 1;
		if ($fail == 1){
			lx("!!vertMap.new Texture txuv {0} {0.78 0.78 0.78} {1.0}");
			lxout("     -There were no uv maps selected and 'Texture' didn't exist so I created this one. <><> Texture");
		}else{
			lxout("     -There were no uv maps selected, but 'Texture' existed and so I selected this one. <><> Texture");
		}

		my $vmaps = lxq("query layerservice vmap.n ? all");
		for (my $i=0; $i<$vmaps; $i++){
			if (lxq("query layerservice vmap.name ? $i") eq "Texture"){
				$finalVmap = $i;
			}
		}
	}

	#ask the name of the vmap just so modo knows which to query.
	my $name = lxq("query layerservice vmap.name ? $finalVmap");
}

#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#SET UP THE USER VALUE OR VALIDATE IT   (no popups)
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#userValueTools(name,type,life,username,list,listnames,argtype,min,max,action,value);
sub userValueTools{
	if (lxq("query scriptsysservice userValue.isdefined ? @_[0]") == 0){
		lxout("Setting up @_[0]--------------------------");
		lxout("Setting up @_[0]--------------------------");
		lxout("0=@_[0],1=@_[1],2=@_[2],3=@_[3],4=@_[4],5=@_[6],6=@_[6],7=@_[7],8=@_[8],9=@_[9],10=@_[10]");
		lxout("@_[0] didn't exist yet so I'm creating it.");
		lx( "user.defNew name:[@_[0]] type:[@_[1]] life:[@_[2]]");
		if (@_[3] ne "")	{	lxout("running user value setup 3");	lx("user.def [@_[0]] username [@_[3]]");	}
		if (@_[4] ne "")	{	lxout("running user value setup 4");	lx("user.def [@_[0]] list [@_[4]]");		}
		if (@_[5] ne "")	{	lxout("running user value setup 5");	lx("user.def [@_[0]] listnames [@_[5]]");	}
		if (@_[6] ne "")	{	lxout("running user value setup 6");	lx("user.def [@_[0]] argtype [@_[6]]");		}
		if (@_[7] ne "xxx")	{	lxout("running user value setup 7");	lx("user.def [@_[0]] min @_[7]");			}
		if (@_[8] ne "xxx")	{	lxout("running user value setup 8");	lx("user.def [@_[0]] max @_[8]");			}
		if (@_[9] ne "")	{	lxout("running user value setup 9");	lx("user.def [@_[0]] action [@_[9]]");		}
		if (@_[1] eq "string"){
			if (@_[10] eq ""){lxout("woah.  there's no value in the userVal sub!");							}		}
		elsif (@_[10] == ""){lxout("woah.  there's no value in the userVal sub!");									}
								lx("user.value [@_[0]] [@_[10]]");		lxout("running user value setup 10");
	}else{
		#STRING-------------
		if (@_[1] eq "string"){
			if (lxq("user.value @_[0] ?") eq ""){
				lxout("user value @_[0] was a blank string");
				lx("user.value [@_[0]] [@_[10]]");
			}
		}
		#BOOLEAN------------
		elsif (@_[1] eq "boolean"){

		}
		#LIST---------------
		elsif (@_[4] ne ""){
			if (lxq("user.value @_[0] ?") == -1){
				lxout("user value @_[0] was a blank list");
				lx("user.value [@_[0]] [@_[10]]");
			}
		}
		#ALL OTHER TYPES----
		elsif (lxq("user.value @_[0] ?") == ""){
			lxout("user value @_[0] was a blank number");
			lx("user.value [@_[0]] [@_[10]]");
		}
	}
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#QUICK DIALOG SUB
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE : quickDialog(username,float,initialValue,min,max);
sub quickDialog{
	if (@_[1] eq "yesNo"){
		lx("dialog.setup yesNo");
		lx("dialog.msg {@_[0]}");
		lx("dialog.open");
		if (lxres != 0){	die("The user hit the cancel button");	}
		return (lxq("dialog.result ?"));
	}else{
		if (lxq("query scriptsysservice userValue.isdefined ? seneTempDialog") == 0){
			lxout("-The seneTempDialog cvar didn't exist so I just created one");
			lx("user.defNew name:[seneTempDialog] life:[temporary]");
		}
		lx("user.def seneTempDialog username [@_[0]]");
		lx("user.def seneTempDialog type [@_[1]]");
		if ((@_[3] != "") && (@_[4] != "")){
			lx("user.def seneTempDialog min [@_[3]]");
			lx("user.def seneTempDialog max [@_[4]]");
		}
		lx("user.value seneTempDialog [@_[2]]");
		lx("user.value seneTempDialog ?");
		if (lxres != 0){	die("The user hit the cancel button");	}
		return(lxq("user.value seneTempDialog ?"));
	}
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#PERFORM MATH FROM ONE ARRAY TO ANOTHER subroutine
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE : my @disp = arrMath(@pos2,@pos1,subt);
sub arrMath{
	my @array1 = (@_[0],@_[1],@_[2]);
	my @array2 = (@_[3],@_[4],@_[5]);
	my $math = @_[6];

	my @newArray;
	if		($math eq "add")	{	@newArray = (@array1[0]+@array2[0],@array1[1]+@array2[1],@array1[2]+@array2[2]);	}
	elsif	($math eq "subt")	{	@newArray = (@array1[0]-@array2[0],@array1[1]-@array2[1],@array1[2]-@array2[2]);	}
	elsif	($math eq "mult")	{	@newArray = (@array1[0]*@array2[0],@array1[1]*@array2[1],@array1[2]*@array2[2]);	}
	elsif	($math eq "div")	{	@newArray = (@array1[0]/@array2[0],@array1[1]/@array2[1],@array1[2]/@array2[2]);	}
	return @newArray;
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#UNIT VECTOR SUBROUTINE
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE : my @unitVector = unitVector(@vector);
sub unitVector{
	my $dist1 = sqrt((@_[0]*@_[0])+(@_[1]*@_[1])+(@_[2]*@_[2]));
	@_ = ((@_[0]/$dist1),(@_[1]/$dist1),(@_[2]/$dist1));
	return @_;
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#DOT PRODUCT subroutine
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE : my $dp = dotProduct(\@vector1,\@vector2);
sub dotProduct{
	my @array1 = @{$_[0]};
	my @array2 = @{$_[1]};
	my $dp = (	(@array1[0]*@array2[0])+(@array1[1]*@array2[1])+(@array1[2]*@array2[2])	);
	return $dp;
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#SORT ROWS SETUP subroutine  (0 and -1 are dupes if it's a loop)
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE :
#requires SORTROW sub
#sortRowStartup(dontFormat,@edges);			#NO FORMAT
#sortRowStartup(edgesSelected,@edges);		#EDGES SELECTED
#sortRowStartup(@edges);					#SELECTION ? EDGE
sub sortRowStartup{

	#------------------------------------------------------------
	#Import the edge list and format it.
	#------------------------------------------------------------
	my @origEdgeList = @_;
	my $edgeQueryMode = shift(@origEdgeList);
	#------------------------------------------------------------
	#(NO) formatting
	#------------------------------------------------------------
	if ($edgeQueryMode eq "dontFormat"){
		#don't format!
	}
	#------------------------------------------------------------
	#(edges ? selected) formatting
	#------------------------------------------------------------
	elsif ($edgeQueryMode eq "edgesSelected"){
		tr/()//d for @origEdgeList;
	}
	#------------------------------------------------------------
	#(selection ? edge) formatting
	#------------------------------------------------------------
	else{
		my @tempEdgeList;
		foreach my $edge (@origEdgeList){	if ($edge =~ /\($mainlayer/){	push(@tempEdgeList,$edge);		}	}
		#[remove layer info] [remove ( ) ]
		@origEdgeList = @tempEdgeList;
		s/\(\d{0,},/\(/  for @origEdgeList;
		tr/()//d for @origEdgeList;
	}


	#------------------------------------------------------------
	#array creation (after the formatting)
	#------------------------------------------------------------
	our @origEdgeList_edit = @origEdgeList;
	our @vertRow=();
	our @vertRowList=();

	our @vertList=();
	our %vertPosTable=();
	our %endPointVectors=();

	our @vertMergeOrder=();
	our @edgesToRemove=();
	our $removeEdges = 0;


	#------------------------------------------------------------
	#Begin sorting the [edge list] into different [vert rows].
	#------------------------------------------------------------
	while (($#origEdgeList_edit + 1) != 0)
	{
		#this is a loop to go thru and sort the edge loops
		@vertRow = split(/,/, @origEdgeList_edit[0]);
		shift(@origEdgeList_edit);
		&sortRow;

		#take the new edgesort array and add it to the big list of edges.
		push(@vertRowList, "@vertRow");
	}


	#Print out the DONE list   [this should normally go in the sorting sub]
	#lxout("- - -DONE: There are ($#vertRowList+1) edge rows total");
	#for ($i = 0; $i < @vertRowList; $i++) {	lxout("- - -vertRow # ($i) = @vertRowList[$i]"); }
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#SORT ROWS subroutine
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE :
#requires sortRowStartup sub.
sub sortRow
{
	#this first part is stupid.  I need it to loop thru one more time than it will:
	my @loopCount = @origEdgeList_edit;
	unshift (@loopCount,1);

	foreach(@loopCount)
	{
		#lxout("[->] USING sortRow subroutine----------------------------------------------");
		#lxout("original edge list = @origEdgeList");
		#lxout("edited edge list =  @origEdgeList_edit");
		#lxout("vertRow = @vertRow");
		my $i=0;
		foreach my $thisEdge(@origEdgeList_edit)
		{
			#break edge into an array  and remove () chars from array
			@thisEdgeVerts = split(/,/, $thisEdge);
			#lxout("-        origEdgeList_edit[$i] Verts: @thisEdgeVerts");

			if (@vertRow[0] == @thisEdgeVerts[0])
			{
				#lxout("edge $i is touching the vertRow");
				unshift(@vertRow,@thisEdgeVerts[1]);
				splice(@origEdgeList_edit, $i,1);
				last;
			}
			elsif (@vertRow[0] == @thisEdgeVerts[1])
			{
				#lxout("edge $i is touching the vertRow");
				unshift(@vertRow,@thisEdgeVerts[0]);
				splice(@origEdgeList_edit, $i,1);
				last;
			}
			elsif (@vertRow[-1] == @thisEdgeVerts[0])
			{
				#lxout("edge $i is touching the vertRow");
				push(@vertRow,@thisEdgeVerts[1]);
				splice(@origEdgeList_edit, $i,1);
				last;
			}
			elsif (@vertRow[-1] == @thisEdgeVerts[1])
			{
				#lxout("edge $i is touching the vertRow");
				push(@vertRow,@thisEdgeVerts[0]);
				splice(@origEdgeList_edit, $i,1);
				last;
			}
			else
			{
				$i++;
			}
		}
	}
}


#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#POPUP SUB
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE : popup("What I wanna print");
sub popup #(MODO2 FIX)
{
	lx("dialog.setup yesNo");
	lx("dialog.msg {@_}");
	lx("dialog.open");
	my $confirm = lxq("dialog.result ?");
	if($confirm eq "no"){die;}
}

