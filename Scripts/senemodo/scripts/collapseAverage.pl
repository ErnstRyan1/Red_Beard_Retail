#perl
#ver 1.5 #note : needs symmetry code still.
#author : Seneca Menard
#(10-9-08 fix) : if you're in poly mode, don't have anything selected and accidentally run the script, it won't collapse the entire scene.
#(10-10-08 feature) : there's now a "leaveUVs" feature that will collapse your selection, but not join their uvs.  To use that, run the script with the "leaveUVs" cvar.  ie : "@collapseAverage.pl leaveUVs"
#(12-18-08 fix) : I went and removed the square brackets so that the numbers will always be read as metric units and also because my prior safety check would leave the unit system set to metric system if the script was canceled because changing that preference doesn't get undone if a script is cancelled.
#(10-9-15 feature) : localCollapse : will do a stretch to zero for each local edge or poly island with the transform tool with SLIP UVS on

#=================================================
#script arguments :
#=================================================
#leaveUVs : will collapse your selection, but not join their uvs.

#====================================
#ARGS
#====================================
foreach my $arg (@ARGV){
	if ($arg eq "leaveUVs")			{	our $leaveUVs = 1;		}
	elsif ($arg eq "localCollapse")	{	our $localCollapse = 1;	}
}


#====================================
#SETUP
#====================================
my $mainlayer = lxq("query layerservice layers ? main");


#====================================
#RUN ROUTINES
#====================================
if( lxq("select.typeFrom {vertex;edge;polygon;item} ?") )	{	our $selType = "vert";	}
elsif( lxq("select.typeFrom {edge;polygon;item;vertex} ?") ){	our $selType = "edge";	}
elsif( lxq("select.typeFrom {polygon;item;vertex;edge} ?") ){	our $selType = "poly";	}
else														{	die("You're not in vert, edge, or polygon mode so I'm cancelling the script");	}

if ($localCollapse == 1){
	localCollapse($selType);
}else{
	if ($leaveUVs == 1){
		collapse($selType);
	}

	elsif( lxq("select.typeFrom {vertex;edge;polygon;item} ?") ){
			lx("!!vert.join [1]");
	}

	elsif ( lxq("select.typeFrom {polygon;item;vertex;edge} ?") ){
		if (lxq("select.count polygon ?") > 0){lx("!!collapse");}
	}

	else{
		lx("!!collapse");
	}
}


#====================================
#LOCAL COLLAPSE SUB
#====================================
sub localCollapse{
	safetyChecks();

	if ($_[0] eq "vert"){
		collapse($selType);
	}
	
	elsif ($_[0] eq "edge"){
		#build database of edge islands (in verts)
		my @edges = lxq("query layerservice edges ? selected");
		my $touchingEdgeIslandsPtr = getSelEdgeIslands("verts",\@edges);
		
		#go through each vert list and find bbox center and then scale to zero
		foreach my $key (keys %$touchingEdgeIslandsPtr){
			my @bbox = boundingbox(@{$$touchingEdgeIslandsPtr{$key}});
			my @bboxCenter = ( ($bbox[0] + $bbox[3]) * .5 , ($bbox[1] + $bbox[4]) * .5 , ($bbox[2] + $bbox[5]) * .5 );
			
			#move verts to center
			if ($leaveUVs == 1)	{	scaleToZeroIgnoreUVs($$touchingEdgeIslandsPtr{$key},\@bboxCenter);		}
			else				{	scaleToZeroPreserveUVs($$touchingEdgeIslandsPtr{$key},\@bboxCenter);	}
			
		}
		
		#merge verts
		lx("!!select.drop vertex");
		lx("!!vert.merge auto {0} {1 um}");
		lx("!!select.type edge");
	}
	
	elsif ($_[0] eq "poly"){
		#get list of poly islands
		my @polys = lxq("query layerservice polys ? selected");
		getPolyPieces(polyIslandSelected,\@polys);
	
		#go through each poly list and find bbox and then scale to center
		foreach my $key (keys %getPolyPiecesGroups){ 
			my %vertList;
			foreach my $poly (@{$getPolyPiecesGroups{$key}}){
				my @polyVerts = lxq("query layerservice poly.vertList ? $poly");
				$vertList{$_} = 1 for @polyVerts;
			}
			
			my @vertsToEdit = (keys %vertList);
			my @bbox = boundingbox(@vertsToEdit);
			my @bboxCenter = ( ($bbox[0] + $bbox[3]) * .5 , ($bbox[1] + $bbox[4]) * .5 , ($bbox[2] + $bbox[5]) * .5 );

			#move verts to center
			if ($leaveUVs == 1)	{	scaleToZeroIgnoreUVs(\@vertsToEdit,\@bboxCenter);	}
			else				{	scaleToZeroPreserveUVs(\@vertsToEdit,\@bboxCenter);	}
		}
		
		#merge verts
		lx("select.drop vertex");
		lx("!!vert.merge auto {0} {1 um}");
		lx("!!select.type polygon");
	}
	
	cleanup();
}

#====================================
#SCALE TO ZERO with preserve uvs SUB : 
#====================================
#usage : scaleToZeroIgnoreUVs(\@verts,\@scalePos);
sub scaleToZeroIgnoreUVs{
	lx("!!vert.move vertIndex:{$_} posX:{${$_[1]}[0]} posY:{${$_[1]}[1]} posZ:{${$_[1]}[2]}") for @{$_[0]};
}


#====================================
#SCALE TO ZERO with preserve uvs SUB : 
#====================================
#usage : scaleToZeroPreserveUVs(\@verts,\@scalePos);
sub scaleToZeroPreserveUVs{
	lx("select.drop vertex");
	lx("select.element $mainlayer vertex add $_") for (@{$_[0]});

	lx("tool.set TransformUScale on");
	lx("tool.set actr.auto on");
	lx("tool.attr center.auto cenX {${$_[1]}[0]}");
	lx("tool.attr center.auto cenY {${$_[1]}[1]}");
	lx("tool.attr center.auto cenZ {${$_[1]}[2]}");

	lx("tool.attr xfrm.transform lockUV true");
	lx("tool.attr xfrm.transform SX 0.0");
	lx("tool.attr xfrm.transform SY 0.0");
	lx("tool.attr xfrm.transform SZ 0.0");
	lx("tool.doApply");
	lx("tool.set TransformUScale off");
}



#====================================
#COLLAPSE SUBROUTINE : WILL COLLAPSE SELECTION, BUT NOT MERGE THEIR UVS.
#====================================
#usage : collapse("poly");
sub collapse{
	my @elems = lxq("query layerservice @_[0]s ? selected");
	lxout("elems = @elems");
	my @avgPos;
	if (@elems > 0){
		foreach my $elem (@elems){
			my @pos = lxq("query layerservice @_[0].pos ? $elem");
			@avgPos[0] += @pos[0];
			@avgPos[1] += @pos[1];
			@avgPos[2] += @pos[2];
		}
		@avgPos[0] /= @elems;
		@avgPos[1] /= @elems;
		@avgPos[2] /= @elems;

		lx("!!vert.move posX:{@avgPos[0]} posY:{@avgPos[1]} posZ:{@avgPos[2]}");
		lx("!!vert.merge auto {0} {1 um}");
	}
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#QUERY SELECTED EDGE ISLANDS (returns either a VERTLIST or a list of EDGEARRAYS)
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#usageBuild		: my $touchingEdgeIslandsPtr = getSelEdgeIslands("verts"|"edges",\@edges);
#usageUseVerts  : foreach my $key (keys %$touchingEdgeIslandsPtr){lxout("key=$key verts = @{$$touchingEdgeIslandsPtr{$key}}");}
#usageUseEdges	: foreach my $key (keys %$touchingEdgeIslandsPtr){foreach my $edgePtr (@{$$touchingEdgeIslandsPtr{$key}}){lxout("edge = @{$edgePtr}");}}
#"verts|edges" lets you pick what type of list it returns
sub getSelEdgeIslands{
	my %edgeIslands;
	my %vertSelTable;
	my $counter = 0;
	my $returnType = 0;
	
	#setup whether to build list of verts or edges
	if ($_[0] eq "edges"){	$returnType = 1;	}
	
	#build list of verts edges compose
	foreach my $edge (@{$_[1]}){
		my @verts = split (/[^0-9]/, $edge);
		$vertSelTable{$verts[1]} = 1;
		$vertSelTable{$verts[2]} = 1;
	}
	
	#go through each vert in the vert table and find all the touching edgeChains
	foreach my $key (keys %vertSelTable){
		if ($vertSelTable{$key} == 2){next;}
		
		my @vertsToCheck = ($key);
		my @touchingVerts;
		
		while (@vertsToCheck > 0){
			my $vertBackup = $vertsToCheck[-1];
			my @vertList = lxq("query layerservice vert.vertList ? $vertsToCheck[-1]");
			$vertSelTable{$vertsToCheck[-1]} = 2;
			if ($returnType == 0)	{	push(@touchingVerts,$vertsToCheck[-1]);	}
			pop(@vertsToCheck);
			
			foreach my $vert (@vertList){
				if ($vertSelTable{$vert} == 1){
					my $edge = "(" . $vertBackup . "," . $vert . ")";
					if (lxq("query layerservice edge.selected ? $edge") == 1){
						if ($returnType == 1){	
							my @edge = ($vertBackup,$vert);
							push(@touchingVerts,\@edge);	
						}
						push(@vertsToCheck,$vert);						
					}
				}
			}
		}

		$edgeIslands{$counter} = \@touchingVerts;
		$counter++;
	}
	
	return \%edgeIslands;
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


#-----------------------------------------------------------------------------------
#BOUNDING BOX subroutine (ver 1.5)
#-----------------------------------------------------------------------------------
sub boundingbox  #minX-Y-Z-then-maxX-Y-Z
{
	lxout("[->] Using boundingbox (math) subroutine");
	my @firstVertPos = lxq("query layerservice vert.pos ? $_[0]");
	my $minX = $firstVertPos[0];
	my $minY = $firstVertPos[1];
	my $minZ = $firstVertPos[2];
	my $maxX = $firstVertPos[0];
	my $maxY = $firstVertPos[1];
	my $maxZ = $firstVertPos[2];
	my @bbVertPos;

	foreach my $bbVert (@_){
		@bbVertPos = lxq("query layerservice vert.pos ? $bbVert");
		if ($bbVertPos[0] < $minX)	{	$minX = $bbVertPos[0];	}
		if ($bbVertPos[0] > $maxX)	{	$maxX = $bbVertPos[0];	}
		if ($bbVertPos[1] < $minY)	{	$minY = $bbVertPos[1];	}
		if ($bbVertPos[1] > $maxY)	{	$maxY = $bbVertPos[1];	}
		if ($bbVertPos[2] < $minZ)	{	$minZ = $bbVertPos[2];	}
		if ($bbVertPos[2] > $maxZ)	{	$maxZ = $bbVertPos[2];	}
	}
	return ($minX,$minY,$minZ,$maxX,$maxY,$maxZ);
}


#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#LIST TOUCHING POLYS SELECTED ()
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
sub listTouchingPolysSel{
	my %todoList;
	my %alreadyChecked;
	my @result;
	$todoList{$_[0]} = 1;
	$alreadyChecked{$_[0]} = 1;
	push(@result,$_[0]);
	my $counter = 0;
	
	while ((keys %todoList) > 0){
		$counter++;
		my @blah = (keys %todoList);
		my %vertList = ();
		my %polyList = ();
		foreach my $poly (keys %todoList){
			my @verts = lxq("query layerservice poly.vertList ? $poly");
			$vertList{$_} = 1 for @verts;
			delete $todoList{$poly};
		}
		
		foreach my $vert (keys %vertList){
			my @polys = lxq("query layerservice vert.polyList ? $vert");
			$polyList{$_} = 1 for @polys;
		}
		foreach my $poly (keys %polyList){
			if ((!exists $alreadyChecked{$poly}) && (lxq("query layerservice poly.selected ? $poly") == 1)){
				$todoList{$poly} = 1;
				$alreadyChecked{$poly} = 1;
				push(@result,$poly);
			}
		}
	}
	
	return(@result);
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
#SELECT THE PROPER VMAP  v2.01 (unreal)
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
sub selectVmap{
	my $defaultVmapName = lxq("pref.value application.defaultTexture ?");
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
	lxout("selectedUVmaps = @selectedUVmaps");

	#ONE SELECTED UV MAP
	if (@selectedUVmaps == 1){
		lxout("     -There's only one uv map selected <> $uvMaps{@selectedUVmaps[0]}");
		$finalVmap = @selectedUVmaps[0];
	}

	#MULTIPLE SELECTED UV MAPS  (try to select "$defaultVmapName")
	elsif (@selectedUVmaps > 1){
		my $foundVmap;
		foreach my $vmap (@selectedUVmaps){
			if ($uvMaps{$vmap} eq $defaultVmapName){
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

	#NO SELECTED UV MAPS (try to select "$defaultVmapName" or create it)
	elsif (@selectedUVmaps == 0){
		lx("!!select.vertexMap {$defaultVmapName} txuv replace") or $fail = 1;
		if ($fail == 1){
			lx("!!vertMap.new {$defaultVmapName} txuv {0} {0.78 0.78 0.78} {1.0}");
			lxout("     -There were no uv maps selected and '$defaultVmapName' didn't exist so I created this one. <><> $defaultVmapName");
		}else{
			lxout("     -There were no uv maps selected, but '$defaultVmapName' existed and so I selected this one. <><> $defaultVmapName");
		}

		my $vmaps = lxq("query layerservice vmap.n ? all");
		for (my $i=0; $i<$vmaps; $i++){
			if (lxq("query layerservice vmap.name ? $i") eq $defaultVmapName){
				$finalVmap = $i;
			}
		}
	}

	#ask the name of the vmap just so modo knows which to query.
	my $name = lxq("query layerservice vmap.name ? $finalVmap");
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#SPLIT THE POLYGONS INTO TOUCHING UV GROUPS (and build the uvBBOX) modded to make sure all variables are blank and also queries vmap name.
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
sub splitUVGroups{
	lxout("[->] Running splitUVGroups subroutine");
	our %touchingUVList = ();
	our %uvBBOXList = ();
	my %originalPolys = ();
	my %vmapTable = ();
	my @scalePolys = @polys;
	my $round = 0;
	foreach my $poly (@scalePolys){$originalPolys{$poly} = 1;}
	my $vmapName = lxq("query layerservice vmap.name ? $finalVmap");

	#---------------------------------------------------------------------------------------
	#LOOP1
	#---------------------------------------------------------------------------------------
	#[1] :	(create a current uvgroup array) : (add the first poly to it) : (set 1stpoly to 1 in originalpolylist) : (build uv list for it)
	while (@scalePolys != 0){
		#setup
		my %ignorePolys = ();
		my %totalPolyList = ();
		my @uvGroup = @scalePolys[0];
		my @nextList = @scalePolys[0];
		my $loop = 1;
		my @verts = lxq("query layerservice poly.vertList ? @scalePolys[0]");
		my @vmapValues = lxq("query layerservice poly.vmapValue ? @scalePolys[0]");
		my %vmapDiscoTable = ();
		$totalPolyList{@scalePolys[0]} = 1;
		$ignorePolys{@scalePolys[0]} = 1;

		#clear the vmapTable for every round and start it from scratch
		%vmapTable = ();
		for (my $i=0; $i<@verts; $i++){
			$vmapTable{@verts[$i]}[0] = @vmapValues[$i*2];
			$vmapTable{@verts[$i]}[1] = @vmapValues[($i*2)+1];
		}

		#build the temp uvBBOX
		my @tempUVBBOX = (999999999,999999999,-999999999,-999999999); #I'm pretty sure this'll never be capped.
		$uvBBOXList{$round} = \@tempUVBBOX;

		#put the first poly's uvs into the bounding box.
		for (my $i=0; $i<@verts; $i++){
			if ( @vmapValues[$i*2] 		< 	$uvBBOXList{$round}[0] )	{	$uvBBOXList{$round}[0] = @vmapValues[$i*2];		}
			if ( @vmapValues[($i*2)+1]	< 	$uvBBOXList{$round}[1] )	{	$uvBBOXList{$round}[1] = @vmapValues[($i*2)+1];	}
			if ( @vmapValues[$i*2] 		> 	$uvBBOXList{$round}[2] )	{	$uvBBOXList{$round}[2] = @vmapValues[$i*2];		}
			if ( @vmapValues[($i*2)+1]	> 	$uvBBOXList{$round}[3] )	{	$uvBBOXList{$round}[3] = @vmapValues[($i*2)+1];	}
		}



		#---------------------------------------------------------------------------------------
		#LOOP2
		#---------------------------------------------------------------------------------------
		while ($loop == 1){
			#[1] :	(make a list of the verts on nextlist's polys) :
			my %vertList;
			my %newPolyList;
			foreach my $poly (@nextList){
				my @verts = lxq("query layerservice poly.vertList ? $poly");
				$vertList{$_} = 1 for @verts;
			}

			#clear nextlist for next round
			@nextList = ();


			#[2] :	(make a newlist of the polys connected to the verts) :
			foreach my $vert (keys %vertList){
				my @vertListPolys = lxq("query layerservice vert.polyList ? $vert");

				#(ignore the ones that are [1] in the originalpolyList or not in the list)
				foreach my $poly (@vertListPolys){
					if (($originalPolys{$poly} == 1) && ($ignorePolys{$poly} != 1)){
						$newPolyList{$poly} = 1;
						$totalPolyList{$poly} = 1;
					}
				}
			}


			#[3] :	(go thru all the polys in the new newlist and see if their uvs are touching the newlist's uv list) : (if they are, add 'em to the uvgroup and nextlist) :
			#(build the uv list for the newlist) : (add 'em to current uvgroup array)
			foreach my $poly (keys %newPolyList){
				my @verts = lxq("query layerservice poly.vertList ? $poly");
				my @vmapValues = lxq("query layerservice poly.vmapValue ? $poly");
				my $last;

				for (my $i=0; $i<@verts; $i++){
					if ($last == 1){last;}

					for (my $j=0; $j<@{$vmapTable{@verts[$i]}}; $j=$j+2){
						#if this poly's matching so add it to the poly lists.
						if ("(@vmapValues[$i*2],@vmapValues[($i*2)+1])" eq "(@{$vmapTable{@verts[$i]}}[$j],@{$vmapTable{@verts[$i]}}[$j+1])"){
							push(@uvGroup,$poly);
							push(@nextList,$poly);
							$ignorePolys{$poly} = 1;

							#this poly's matching so i'm adding it's uvs to the uv list
							for (my $u=0; $u<@verts; $u++){
								if ($vmapDiscoTable{@verts[$u].",".@vmapValues[$u*2].",".@vmapValues[($u*2)+1]} != 1){
									push(@{$vmapTable{@verts[$u]}} , @vmapValues[$u*2]);
									push(@{$vmapTable{@verts[$u]}} , @vmapValues[($u*2)+1]);
									$vmapDiscoTable{@verts[$u].",".@vmapValues[$u*2].",".@vmapValues[($u*2)+1]} = 1;
								}
							}

							#this poly's matching, so I'll create the uvBBOX right now.
							for (my $i=0; $i<@verts; $i++){
								if ( @vmapValues[$i*2] 		< 	$uvBBOXList{$round}[0] )	{	$uvBBOXList{$round}[0] = @vmapValues[$i*2];		}
								if ( @vmapValues[($i*2)+1]	< 	$uvBBOXList{$round}[1] )	{	$uvBBOXList{$round}[1] = @vmapValues[($i*2)+1];	}
								if ( @vmapValues[$i*2] 		> 	$uvBBOXList{$round}[2] )	{	$uvBBOXList{$round}[2] = @vmapValues[$i*2];		}
								if ( @vmapValues[($i*2)+1]	> 	$uvBBOXList{$round}[3] )	{	$uvBBOXList{$round}[3] = @vmapValues[($i*2)+1];	}
							}
							$last = 1;
							last;
						}
					}
				}
			}

			#This round of UV grouping is done.  Time for the next round.
			if (@nextList == 0){
				$touchingUVList{$round} = \@uvGroup;
				$round++;
				$loop = 0;
				@scalePolys = removeListFromArray(\@scalePolys, \@uvGroup);
			}
		}
	}

	my $keyCount = (keys %touchingUVList);
	lxout("     -There are ($keyCount) uv groups");
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

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#GETPOLYPIECES SUB v3.1 (get a list of poly groups under different search criteria)
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE1 : getPolyPieces(poly,\@polys);  #setup
#USAGE1 : getPolyPieces(polyIsland,\@polys);  #setup
#USAGE1 : getPolyPieces(polyIslandVisible,\@polys);  #setup
#USAGE1 : getPolyPieces(polyIslandSelected,\@polys);  #setup
#USAGE1 : getPolyPieces(uvIsland,\@polys);  #setup
#USAGE1 : getPolyPieces(part,\@polys);  #setup
#USAGE2 : foreach my $key (keys %getPolyPiecesGroups){ #blah }
#requires listTouchingPolys2 sub
#requires listTouchingPolysSel sub
#requires selectVmap sub
#requires splitUVGroups sub
#requires removeListFromArray sub
sub getPolyPieces{
	our %getPolyPiecesGroups = ();
	our %getPolyPiecesUvBboxes = ();
	our $piecesCount = "";
	our $currentPiece = "";

	if ($_[0] eq "poly"){
		for (my $i=0; $i<@{$_[1]}; $i++){
			@{$getPolyPiecesGroups{$i}} = ${$_[1]}[$i];
		}
	}

	elsif ($_[0] eq "polyIsland"){
		my %polysLeft;
		my $count = 0;

		for (my $i=0; $i<@{$_[1]}; $i++){	$polysLeft{@{$_[1]}[$i]} = 1;	}

		while (keys %polysLeft > 0){
			my @polyList = listTouchingPolys2((keys %polysLeft)[0]);
			delete $polysLeft{$_} for @polyList;
			$getPolyPiecesGroups{$count++} = \@polyList;
		}
	}

	elsif ($_[0] eq "polyIslandVisible"){
		my %polysLeft;
		my $count = 0;

		for (my $i=0; $i<@{$_[1]}; $i++){	$polysLeft{@{$_[1]}[$i]} = 1;	}

		while (keys %polysLeft > 0){
			my @polyList = listTouchingVisiblePolys((keys %polysLeft)[0]);
			delete $polysLeft{$_} for @polyList;
			$getPolyPiecesGroups{$count++} = \@polyList;
		}
	}
	
	elsif ($_[0] eq "polyIslandSelected"){
		my %polysLeft;
		my $count = 0;

		for (my $i=0; $i<@{$_[1]}; $i++){	$polysLeft{@{$_[1]}[$i]} = 1;	}

		while (keys %polysLeft > 0){
			my @polyList = listTouchingPolysSel((keys %polysLeft)[0]);
			delete $polysLeft{$_} for @polyList;
			$getPolyPiecesGroups{$count++} = \@polyList;
		}
	}

	elsif ($_[0] eq "uvIsland"){
		selectVmap();
		splitUVGroups();
		my $count = 0;

		foreach my $key (keys %touchingUVList){
			$getPolyPiecesGroups{$count++} = \@{$touchingUVList{$key}};
			$getPolyPiecesUvBboxes{$count} = \@{$uvBBOXList{$key}};
		}
	}

	elsif ($_[0] eq "part"){
		my %partTable;
		my $count = 0;

		foreach my $poly (@{$_[1]}){
			push(@{$partTable{lxq("query layerservice poly.part ? $poly")}},$poly);
		}

		foreach my $key (keys %partTable){
			$getPolyPiecesGroups{$count++} = $partTable{$key};
		}
	}

	else{
		die("GETPOLYPIECES SUB ERROR : the first argument wasn't legit so script is being canceled");
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


##------------------------------------------------------------------------------------------------------------
##------------------------------------------------------------------------------------------------------------
##SAFETY CHECKS SUB
##------------------------------------------------------------------------------------------------------------
##------------------------------------------------------------------------------------------------------------
sub safetyChecks{
	#symmetry
	our $symmAxis = lxq("select.symmetryState ?");
	if ($skipSymm != 1){
		if ($symmAxis ne "none"){
			lx("select.symmetryState none");
		}
	}

	#Remember what the workplane was and turn it off
	our @WPmem;
	if ($skipWorkplane != 1){
		@WPmem[0] = lxq ("workPlane.edit cenX:? ");
		@WPmem[1] = lxq ("workPlane.edit cenY:? ");
		@WPmem[2] = lxq ("workPlane.edit cenZ:? ");
		@WPmem[3] = lxq ("workPlane.edit rotX:? ");
		@WPmem[4] = lxq ("workPlane.edit rotY:? ");
		@WPmem[5] = lxq ("workPlane.edit rotZ:? ");
		lx("workPlane.reset ");
	}


	#-----------------------------------------------------------------------------------
	#REMEMBER SELECTION SETTINGS and then set it to selectauto  ((MODO6 FIX))
	#-----------------------------------------------------------------------------------
	#sets the ACTR preset
	our $seltype;
	our $selAxis;
	our $selCenter;
	our $actr = 1;

	if ($skipActr != 1){
		if   ( lxq( "tool.set actr.auto ?") eq "on")			{	$seltype = "actr.auto";			}
		elsif( lxq( "tool.set actr.select ?") eq "on")			{	$seltype = "actr.select";		}
		elsif( lxq( "tool.set actr.border ?") eq "on")			{	$seltype = "actr.border";		}
		elsif( lxq( "tool.set actr.selectauto ?") eq "on")		{	$seltype = "actr.selectauto";	}
		elsif( lxq( "tool.set actr.element ?") eq "on")			{	$seltype = "actr.element";		}
		elsif( lxq( "tool.set actr.screen ?") eq "on")			{	$seltype = "actr.screen";		}
		elsif( lxq( "tool.set actr.origin ?") eq "on")			{	$seltype = "actr.origin";		}
		elsif( lxq( "tool.set actr.parent ?") eq "on")			{	$seltype = "actr.parent";		}
		elsif( lxq( "tool.set actr.local ?") eq "on")			{	$seltype = "actr.local";		}
		elsif( lxq( "tool.set actr.pivot ?") eq "on")			{	$seltype = "actr.pivot";		}
		elsif( lxq( "tool.set actr.pivotparent ?") eq "on")		{	$seltype = "actr.pivotparent";	}

		elsif( lxq( "tool.set actr.worldAxis ?") eq "on")		{	$seltype = "actr.worldAxis";	}
		elsif( lxq( "tool.set actr.localAxis ?") eq "on")		{	$seltype = "actr.localAxis";	}
		elsif( lxq( "tool.set actr.parentAxis ?") eq "on")		{	$seltype = "actr.parentAxis";	}

		else
		{
			$actr = 0;
			lxout("custom Action Center");
	
			if   ( lxq( "tool.set axis.auto ?") eq "on")		{	 $selAxis = "auto";				}
			elsif( lxq( "tool.set axis.select ?") eq "on")		{	 $selAxis = "select";			}
			elsif( lxq( "tool.set axis.element ?") eq "on")		{	 $selAxis = "element";			}
			elsif( lxq( "tool.set axis.view ?") eq "on")		{	 $selAxis = "view";				}
			elsif( lxq( "tool.set axis.origin ?") eq "on")		{	 $selAxis = "origin";			}
			elsif( lxq( "tool.set axis.parent ?") eq "on")		{	 $selAxis = "parent";			}
			elsif( lxq( "tool.set axis.local ?") eq "on")		{	 $selAxis = "local";			}
			elsif( lxq( "tool.set axis.pivot ?") eq "on")		{	 $selAxis = "pivot";			}
			else												{	 $actr = 1;  $seltype = "actr.auto"; lxout("You were using an action AXIS that I couldn't read");}

			if   ( lxq( "tool.set center.auto ?") eq "on")		{	 $selCenter = "auto";			}
			elsif( lxq( "tool.set center.select ?") eq "on")	{	 $selCenter = "select";			}
			elsif( lxq( "tool.set center.border ?") eq "on")	{	 $selCenter = "border";			}
			elsif( lxq( "tool.set center.element ?") eq "on")	{	 $selCenter = "element";		}
			elsif( lxq( "tool.set center.view ?") eq "on")		{	 $selCenter = "view";			}
			elsif( lxq( "tool.set center.origin ?") eq "on")	{	 $selCenter = "origin";			}
			elsif( lxq( "tool.set center.parent ?") eq "on")	{	 $selCenter = "parent";			}
			elsif( lxq( "tool.set center.local ?") eq "on")		{	 $selCenter = "local";			}
			elsif( lxq( "tool.set center.pivot ?") eq "on")		{	 $selCenter = "pivot";			}
			else												{ 	 $actr = 1;  $seltype = "actr.auto"; lxout("You were using an action CENTER that I couldn't read");}
		}
		lx("tool.set actr.auto on");
	}
}

##------------------------------------------------------------------------------------------------------------
##------------------------------------------------------------------------------------------------------------
##CLEANUP SUB
##------------------------------------------------------------------------------------------------------------
##------------------------------------------------------------------------------------------------------------
sub cleanup{
	#symmetry restore
	if ($skipSymm != 1){
		if ($symmAxis ne "none"){
			lxout("turning symm back on ($symmAxis)"); lx("select.symmetryState $symmAxis");
		}
	}

	#Put the workplane back
	if ($skipWorkplane != 1){
		lx("workPlane.edit {@WPmem[0]} {@WPmem[1]} {@WPmem[2]} {@WPmem[3]} {@WPmem[4]} {@WPmem[5]}");
	}

	#Set the action center settings back
	if ($skipActr != 1){
		if ($actr == 1) {	lx( "tool.set {$seltype} on" ); }
		else { lx("tool.set center.$selCenter on"); lx("tool.set axis.$selAxis on"); }
	}

	#restore the last used tool
	#if ($restoreTool == 1) {lx("tool.set $tool on");}

	#restore selection mode (if any)
	if ($selectionMode ne ""){lx("select.type $selectionMode");}
}
