#perl
#BY: Seneca Menard
#version 1.2

#This script is to floodfill the the selection area underneath the mouse.  If your mouse is over unselected geometry, it will select it.  If it's over selected geometry, it will deselect it.
#The script works with verts, edges, and polys, and also with symmetry.
#The script has ONE argument and it's optional.  When you deselect polys, it will also deselect diagonally touching polys.  It's good for the majority of deselection cases, but if you
#want to have it only deselect the edge-adjacent polys, just append "noDiagonal" to the script.
#(5-4-07) : I put in a progress bar just so you can cancel the script if your mouse was over something else on accident.
#(8-18-07) : now won't select or deselect hidden elements anymore..
#script arguments = "noDiagonal"





lxmonInit(3);
my $mainlayer = lxq("query layerservice layers ? main");
my $selectMode = 0;
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#SCRIPT ARGUMENTS
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
foreach my $arg (@ARGV){
	if ($arg =~ /noDiagonal/i)		{	our $noDiagonal = 1;	}
}


#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#VERT MODE
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
if( lxq( "select.typeFrom {vertex;edge;polygon;item} ?" ) == 1){
	my @selectVerts;
	our %ignoreVerts;

	my $vertCount1 = lxq("query layerservice vert.n ? selected");
	lx("select.3DElementUnderMouse remove");
	my $vertCount3 = lxq("query layerservice vert.n ? selected");  #this is for deselect, so it knows how many verts is under the mouse.
	lx("select.3DElementUnderMouse add");
	my @verts = lxq("query layerservice verts ? selected");
	my $vertCount2 = lxq("query layerservice vert.n ? selected");

	if (($vertCount1 == $vertCount2) && ($vertCount1 == $vertCount3))	{	die("\n.\n[-----------------------------------------Your mouse is over no verts, so I'm killing the script--------------------------------------]\n[--PLEASE TURN OFF THIS WARNING WINDOW by clicking on the (In the future) button and choose (Hide Message)--] \n[-----------------------------------This window is not supposed to come up, but I can't control that.---------------------------]\n.\n");	}
	elsif ($vertCount3 == $vertCount1)									{	our $diff = $vertCount2-$vertCount1;	}
	else																{	our $diff = $vertCount1-$vertCount3;	}
	lxout("Your mouse is over ($diff) verts");
	for (my $i=0; $i<@verts-($vertCount2-$vertCount1); $i++){ $ignoreVerts{@verts[$i]} = 1; }


	if ($vertCount2 > $vertCount1){
		lxout("[->] Selecting a Vert island");
		$selectMode = 1;

		for (my $i=1; $i<$diff+1; $i++){
			my @connectedverts = listVertIsland(@verts[-$i]);
			push(@selectverts,@connectedverts);
		}

		foreach my $vert (@selectverts){
			if (!lxmonStep){die("User aborted");}
			lxmonStep;
			lx("select.element $mainlayer vertgon add $vert");
		}
	}else{
		lxout("[->] Deselecting a Vert island");
		$selectMode = 0;

		for (my $i=1; $i<$diff+1; $i++){
			my @connectedverts = listVertIsland(@verts[-$i]);
			push(@selectverts,@connectedverts);
		}

		foreach my $vert (@selectverts){
			if (!lxmonStep){die("User aborted");}
			lxmonStep;
			lx("select.element $mainlayer vertgon remove $vert");
		}
	}
}


#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#EDGE MODE
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
elsif( lxq( "select.typeFrom {edge;polygon;item;vertex} ?" ) == 1){
	my @selectEdges;
	our %ignoreEdges;
	our %originalVerts;
	our %originalEdges;

	my $edgeCount1 = lxq("query layerservice edge.n ? selected");
	lx("select.3DElementUnderMouse remove");
	my $edgeCount3 = lxq("query layerservice edge.n ? selected");  #this is for deselect, so it knows how many edges is under the mouse.
	lx("select.3DElementUnderMouse add");
	my @edges = lxq("query layerservice selection ? edge");
	&formatEdges(\@edges);
	my $edgeCount2 = lxq("query layerservice edge.n ? selected");

	if (($edgeCount1 == $edgeCount2) && ($edgeCount1 == $edgeCount3))	{	die("\n.\n[-----------------------------------------Your mouse is over no edges, so I'm killing the script--------------------------------------]\n[--PLEASE TURN OFF THIS WARNING WINDOW by clicking on the (In the future) button and choose (Hide Message)--] \n[-----------------------------------This window is not supposed to come up, but I can't control that.---------------------------]\n.\n");	}
	elsif ($edgeCount3 == $edgeCount1)									{	our $diff = $edgeCount2-$edgeCount1;	}
	else																{	our $diff = $edgeCount1-$edgeCount3;	}
	lxout("Your mouse is over ($diff) edges");
	for (my $i=0; $i<@edges-($edgeCount2-$edgeCount1); $i++){
		#add every vert to the ignore list so bleeding doesn't occur.
		my @verts = split(/[^0-9]/, @edges[$i]);
		$originalVerts{@verts[0]} = 1;
		$originalVerts{@verts[1]} = 1;
		$originalEdges{@edges[$i]} = 1;
	}


	if ($edgeCount2 > $edgeCount1){
		lxout("[->] Selecting an edge island");
		$selectMode = 1;

		for (my $i=1; $i<$diff+1; $i++){
			my @connectedEdges = listEdgeIsland(@edges[-$i]);
			push(@selectEdges,@connectedEdges);
		}

		foreach my $edge (@selectEdges){
			if (!lxmonStep){die("User aborted");}
			lxmonStep;
			my @verts = split(/[^0-9]/, $edge);
			lx("select.element $mainlayer edge add @verts[0] @verts[1]");
		}
	}else{
		lxout("[->] Deselecting an edge island");
		$selectMode = 0;

		for (my $i=1; $i<$diff+1; $i++){
			my @connectedEdges = listEdgeIsland(@edges[-$i]);
			push(@selectEdges,@connectedEdges);
		}

		foreach my $edge (@selectEdges){
			if (!lxmonStep){die("User aborted");}
			lxmonStep;
			my @verts = split(/[^0-9]/, $edge);
			lx("select.element $mainlayer edge remove @verts[0] @verts[1]");
			lx("select.element $mainlayer edge remove @verts[1] @verts[0]");
		}
	}
}


#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#POLY MODE
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
elsif( lxq( "select.typeFrom {polygon;item;vertex;edge} ?" ) == 1){
	my @selectPolys;
	our %ignorePolys;

	my $polyCount1 = lxq("query layerservice poly.n ? selected");
	lx("select.3DElementUnderMouse remove");
	my $polyCount3 = lxq("query layerservice poly.n ? selected");  #this is for deselect, so it knows how many polys is under the mouse.
	lx("select.3DElementUnderMouse add");
	my @polys = lxq("query layerservice polys ? selected");
	my $polyCount2 = lxq("query layerservice poly.n ? selected");

	if (($polyCount1 == $polyCount2) && ($polyCount1 == $polyCount3))	{	die("\n.\n[-----------------------------------------Your mouse is over no polys, so I'm killing the script--------------------------------------]\n[--PLEASE TURN OFF THIS WARNING WINDOW by clicking on the (In the future) button and choose (Hide Message)--] \n[-----------------------------------This window is not supposed to come up, but I can't control that.---------------------------]\n.\n");	}
	elsif ($polyCount3 == $polyCount1)									{	our $diff = $polyCount2-$polyCount1;	}
	else																{	our $diff = $polyCount1-$polyCount3;	}
	lxout("Your mouse is over ($diff) polys");
	for (my $i=0; $i<@polys-($polyCount2-$polyCount1); $i++){ $ignorePolys{@polys[$i]} = 1; }


	if ($polyCount2 > $polyCount1){
		lxout("[->] Selecting a poly island");
		$selectMode = 1;

		for (my $i=1; $i<$diff+1; $i++){
			my @connectedPolys = listPolyIsland_edge(@polys[-$i]);
			push(@selectPolys,@connectedPolys);
		}

		foreach my $poly (@selectPolys){
			if (!lxmonStep){die("User aborted");}
			lxmonStep;
			lx("select.element $mainlayer polygon add $poly");
		}
	}else{
		lxout("[->] Deselecting a poly island");
		$selectMode = 0;

		for (my $i=1; $i<$diff+1; $i++){
			if ($noDiagonal == 1){
				our @connectedPolys = listPolyIsland_edge(@polys[-$i]);
			}else{
				our @connectedPolys = listPolyIsland_vert(@polys[-$i]);
			}
			push(@selectPolys,@connectedPolys);
		}

		foreach my $poly (@selectPolys){
			if (!lxmonStep){die("User aborted");}
			lxmonStep;
			lx("select.element $mainlayer polygon remove $poly");
		}
	}
}




#=====================================================================================================================================
#=====================================================================================================================================
#=====================================================================================================================================
#=====================================================================================================================================
#===																GENERIC SUBROUTINES															====
#=====================================================================================================================================
#=====================================================================================================================================
#=====================================================================================================================================
#=====================================================================================================================================



#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#FIND REGULAR EDGES
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
sub findEdges_regular{
	if ($ignoreVerts{@_[0]} != 1){
		#lxout("find regular edges for @_[0]");

		$ignoreVerts{@_[0]} = 1;
		my @verts = lxq("query layerservice vert.vertList ? @_[0]");

		foreach my $vert (@verts){
			my $edge = sortEdgeVerts(@_[0],$vert);

			#lxout("edge = $edge <> ignore=$ignoreEdges{$edge} <> selectMode=$selectMode");
			if ($ignoreEdges{$edge} != 1){
				$currentEdgeList{$edge} = 1;
			}
		}
	}
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#FIND IGNORE EDGES
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
sub findEdges_ignore{
	if ($ignoreVerts{@_[0]} != 1){
		#lxout("find ignore edges for @_[0]");

		$ignoreVerts{@_[0]} = 1;
		my @verts = lxq("query layerservice vert.vertList ? @_[0]");

		foreach my $vert (@verts){
			if ($originalVerts{$vert} == 1){
				my $edge = sortEdgeVerts(@_[0],$vert);

				#lxout("edge = $edge <> ignore=$ignoreEdges{$edge} <> selectMode=$selectMode");
				if ($selectMode == 1){
					if ($ignoreEdges{$edge} != 1){
						$currentEdgeList{$edge} = 1;
					}
				}else{
					if (($originalEdges{$edge} == 1) && ($ignoreEdges{$edge} != 1)){
						$currentEdgeList{$edge} = 1;
					}
				}
			}
		}
	}
}


#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#FORMAT EDGES SUB
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
sub formatEdges{
	for (my $i=0; $i<@{$_[0]}; $i++){
		@{$_[0]}[$i] =~ s/\(\d{0,},//;
		my @verts = split(/[^0-9]/, @{$_[0]}[$i]);
		if (@verts[0] < @verts[1])	{	@{$_[0]}[$i] = @verts[0].",".@verts[1];	}
		else					{	@{$_[0]}[$i] = @verts[1].",".@verts[0];	}
	}
}


#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#SORT EDGE VERTS SUB
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
sub sortEdgeVerts{
	if (@_[0] < @_[1]){
		return @_[0].",".@_[1];
	}else{
		return @_[1].",".@_[0];
	}
}




#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#LIST VERT ISLAND SUB
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
sub listVertIsland{
	lxout("[->] LIST VERT ISLAND subroutine");
	my %currentVertList;	$currentVertList{@_[0]} = 1;
	our %totalVertList;		$totalVertList{@_[0]} = 1;
	my $stopScript = 0;
	my $i = 0;


	#--------------------------------------------------------
	#SIMILAR vert FIND+SELECT LOOP------
	#--------------------------------------------------------
	while ($stopScript == 0)
	{
		#[1] : LOOK at verts of current vert list and convert 'em into previously unselected verts.
		my %vertList=();

		#my @printCurrentVerts = (keys %currentVertList);
		#popup("printCurrentVerts = @printCurrentVerts");

		foreach my $vert (keys %currentVertList){
			$ignoreVerts{$vert} = $selectMode;
			my @vertList = lxq("query layerservice vert.vertList ? $vert ");
			foreach my $vert (@vertList){
				if (lxq("query layerservice vert.hidden ? $vert") == 0){
					$vertList{$vert} = 1;
				}
			}
		}

		#clear the vert table for this round
		%currentVertList = ();

		#[2] : FIND the verts on this round's verts.
		foreach my $vert (keys %vertList)
		{
			#popup("vert=$vert<>ignore=$ignoreVerts{$vert}<>selectMode=$selectMode");
			if ($ignoreVerts{$vert} != $selectMode){
				$currentVertList{$vert} = 1;
				$ignoreVerts{$vert} = 1;
			}
		}

		#convert the currentVertList to the totalVertList
		foreach my $vert (keys %currentVertList){	$totalVertList{$vert} = 1;	}

		#decide whether to keep looping or not.
		if (keys %currentVertList == 0){
			$stopScript = 1;
		}
	}

	return (keys %totalVertList);
}




#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#LIST EDGE ISLAND SUB
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
sub listEdgeIsland{
	lxout("[->] LIST EDGE ISLAND subroutine");
	our %currentEdgeList;		$currentEdgeList{@_[0]} = 1;
	our %totalEdgetList;		$totalEdgeList{@_[0]} = 1;
	our %ignoreEdges;
	our %ignoreVerts;
	our %ignoreVerts_temp;
	my $stopScript = 0;

	#--------------------------------------------------------
	#SIMILAR vert FIND+SELECT LOOP------
	#--------------------------------------------------------
	while ($stopScript == 0)
	{
		#[1] : LOOK at verts of current vert list and convert 'em into previously unselected verts.
		my %vertList=();

		#backup and clear the currentEdgeList
		my @currentEdges = (keys %currentEdgeList);
		%currentEdgeList = ();
		%ignoreVerts_temp = ();

		#update the ignore edges list
		foreach my $edge (@currentEdges){
			$ignoreEdges{$edge} = 1;
		}

		#go thru the current edges.
		foreach my $edge (@currentEdges){
			my @verts = split(/[^0-9]/, $edge);

			foreach my $vert (@verts){
				if ($originalVerts{$vert} == 1){
					&findEdges_ignore($vert);
				}else{
					&findEdges_regular($vert);
				}
			}
		}

		#convert the currentEdgeList to the totalEdgeList
		foreach my $edge (keys %currentEdgeList){
			#find out if the edge is hidden by seeing if it's polys are hidden.
			my @polys = lxq("query layerservice edge.polyList ? ($edge)");
			my $hidden = 0;
			foreach my $poly (@polys){
				my $check = lxq("query layerservice poly.hidden ? $poly");
				$hidden += $check;
			}
			if (($hidden/@polys) != 1){
				$totalEdgeList{$edge} = 1;
			}else{
				delete $currentEdgeList{$edge};
			}
		}

		#update the ignoreVerts list.
		foreach my $vert (keys %ignoreVerts_temp){	$ignoreVerts{$vert} = 1;		}

		#decide whether to keep looping or not.
		if (keys %currentEdgeList == 0){
			$stopScript = 1;
		}
	}

	return (keys %totalEdgeList);
}




#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#LIST POLY ISLAND THROUGH VERTS sub
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
sub listPolyIsland_vert{
	lxout("[->] LIST POLY ISLAND VERTS subroutine");
	my %currentPolyList;	$currentPolyList{@_[0]} = 1;
	our %totalPolyList;		$totalPolyList{@_[0]} = 1;
	my %ignoreVerts;
	my $stopScript = 0;
	my $i = 0;


	#--------------------------------------------------------
	#SIMILAR POLY FIND+SELECT LOOP------
	#--------------------------------------------------------
	while ($stopScript == 0)
	{
		#[1] : LOOK at verts of current poly list and convert 'em into previously unselected polys.
		my %vertList=();

		foreach my $poly (keys %currentPolyList){
			$ignorePolys{$poly} = $selectMode;
			my @vertList = lxq("query layerservice poly.vertList ? $poly ");
			foreach my $vert (@vertList){
				$vertList{$vert} = 1;
			}
		}

		#clear the poly table for this round
		%currentPolyList = ();

		#[2] : FIND the polys on this round's verts.
		foreach my $vert (keys %vertList)
		{
			if ($ignoreVerts{$vert} != 1){
				my @polys = lxq("query layerservice vert.polyList ? $vert");
				foreach my $poly (@polys){ $currentPolyList{$poly} = 1; }
				$ignoreVerts{$vert} = 1;
			}
		}

		#[3] : GO THROUGH each poly in this round and see if it should be added to the array or not.
		foreach my $poly (keys %currentPolyList){
			if ($ignorePolys{$poly} == $selectMode){
				delete $currentPolyList{$poly};
			}elsif (lxq("query layerservice poly.hidden ? $poly") == 1){
				$ignorePolys{$poly} = $selectMode;
				delete $currentPolyList{$poly};
			}
		}

		#convert the currentPolyList to the totalPolyList
		foreach my $poly (keys %currentPolyList){	$totalPolyList{$poly} = 1;	}

		#decide whether to keep looping or not.
		if (keys %currentPolyList == 0){
			$stopScript = 1;
		}
	}

	return (keys %totalPolyList);
}



#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#LIST POLY ISLAND THROUGH EDGES sub
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
sub listPolyIsland_edge{
	lxout("[->] LIST POLY ISLAND EDGES subroutine");
	my %currentPolyList;	$currentPolyList{@_[0]} = 1;
	our %totalPolyList;		$totalPolyList{@_[0]} = 1;
	my %ignoreEdges;
	my $stopScript = 0;
	my $i = 0;


	#--------------------------------------------------------
	#SIMILAR POLY FIND+SELECT LOOP------
	#--------------------------------------------------------
	while ($stopScript == 0)
	{
		#[1] : LOOK at verts of current poly list and convert 'em into previously unselected polys.
		my %edgeList=();
		#my @polyListDisplay = keys(%currentPolyList);
		#popup("polyListDisplay = @polyListDisplay");


		foreach my $poly (keys %currentPolyList){
			$ignorePolys{$poly} = $selectMode;
			#lxout("poly ($poly) ignore poly list ? = $ignorePolys{$poly}");

			my @vertList = lxq("query layerservice poly.vertList ? $poly ");
			for (my $i=0; $i<@vertList; $i++){
				#fix the edge vert order to stop duplicate edges from being created.
				if (@vertList[$i-1] < @vertList[$i])	{$edgeList{@vertList[$i-1].",".@vertList[$i]} = 1;}
				else									{$edgeList{@vertList[$i].",".@vertList[$i-1]} = 1;}
			}
		}

		#clear the poly table for this round
		%currentPolyList = ();

		#[2] : FIND the polys on this round's verts.
		foreach my $edge (keys %edgeList)
		{
			if ($ignoreEdges{$edge} != 1){
				#lxout("keeping $edge");
				my @polys = lxq("query layerservice edge.polyList ? ($edge)");
				foreach my $poly (@polys){ $currentPolyList{$poly} = 1; }
				$ignoreEdges{$edge} = 1;
			}
		}

		#[3] : GO THROUGH each poly in this round and see if it should be added to the array or not.
		foreach my $poly (keys %currentPolyList){
			if ($ignorePolys{$poly} == $selectMode){
				delete $currentPolyList{$poly};
			}elsif (lxq("query layerservice poly.hidden ? $poly") == 1){
				$ignorePolys{$poly} = $selectMode;
				delete $currentPolyList{$poly};
			}
		}

		#convert the currentPolyList to the totalPolyList
		foreach my $poly (keys %currentPolyList){	$totalPolyList{$poly} = 1;	}

		#decide whether to keep looping or not.
		if (keys %currentPolyList == 0){
			#popup("it says currentPolyList is zero, so I've hit the end of the loop");
			$stopScript = 1;
		}
	}

	return (keys %totalPolyList);
}


#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#POPUP SUB
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
sub popup #(MODO2 FIX)
{
	lx("dialog.setup yesNo");
	lx("dialog.msg {@_}");
	lx("dialog.open");
	my $confirm = lxq("dialog.result ?");
	if($confirm eq "no"){die;}
}
