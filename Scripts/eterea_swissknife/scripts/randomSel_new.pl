#perl
#AUTHOR: Seneca Menard
#version 1.1 (M3 temp)
#This script is to randomly select or deselect VERT, EDGES, or POLYS using the percentage you enter.
#-it selects by default.
#-if you want to deselect, append "deselect" to the script.  ie, bind a hotkey to this : "@randomSelNew.pl deselect"

my $mainlayer = lxq("query layerservice layers ? main");
srand;

#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#SCRIPT ARGUMENTS
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
foreach my $arg (@ARGV){
	if		($arg =~ /deselect/i)	{	our $deselect = 1;		}
	elsif	($arg =~ /mesh/i)		{	our $mesh = 1;			}
	elsif	($arg =~ /part/i)		{	our $part = 1;			}
	elsif	($arg =~ /uvIsland/i)	{	our $uvIsland = 1;		}
}

#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#USER VALUES
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#create the sene_randomSel variable if it didn't already exist.
if (lxq("query scriptsysservice userValue.isdefined ? sene_randomSel") == 0)
{
	lxout("-The sene_randomSel cvar didn't exist so I just created one");
	lx( "user.defNew sene_randomSel type:[float] life:[temporary]");
	lx("user.def sene_randomSel username [% of elems to select?]");
	lx("user.value sene_randomSel [50]");
}

#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#MAIN ROUTINE
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
lx("user.value sene_randomSel ?");
my $random = lxq("user.value sene_randomSel ?")/100;

if( lxq( "select.typeFrom {vertex;edge;polygon;item} ?" ) ) {
	our $elem = "verts";
	our $elemName = "vertex";
}
elsif( lxq( "select.typeFrom {edge;polygon;item;vertex} ?" ) ) {
	our $elem = "edges";
	our $elemName = "edge";
}
elsif( lxq( "select.typeFrom {polygon;item;vertex;edge} ?" ) ) {
	our $elem = "polys";
	our $elemName = "polygon";
}
else{
	die("You must be in VERT, EDGE, or POLY MODE");
}

if ($deselect == 1)		{	our $selMode = "remove";	}
else					{	our $selMode = "add";		}


#--------------------------------------------
#MESH ROUTINE
#--------------------------------------------
if ($mesh == 1){
	my @groupedPolysArray;
	my @polys;

	if ($selMode eq "add"){
		@polys = lxq("query layerservice polys ? visible");
	}else{
		if ($elemName ne "polygon"){lx("!!select.convert polygon");}
		@polys = lxq("query layerservice polys ? selected");
	}

	while (@polys > 0){
		my @connectedPolys = listTouchingPolys2($polys[0]);
		push(@groupedPolysArray,\@connectedPolys);
		@polys = removeListFromArray(\@polys,\@connectedPolys);
	}

	randomizeArray(\@groupedPolysArray);

	for (my $i=0; $i<@groupedPolysArray; $i++){
		my $chance = rand;
		if ($chance < $random){
			#polys
			if ($elemName eq "polygon"){
				lx("select.element $mainlayer polygon $selMode $_") for @{$groupedPolysArray[$i]};
			}
			#edges
			elsif ($elemName eq "edge"){
				getOrSelectPolyElems(\@{$groupedPolysArray[$i]},"edge",$selMode);
			}
			#verts
			elsif ($elemName eq "vertex"){
				getOrSelectPolyElems(\@{$groupedPolysArray[$i]},"vertex",$selMode);
			}
		}
	}

	if ($elemName ne "polygon"){
		lx("select.type $elemName");
	}
}

#--------------------------------------------
#PART ROUTINE
#--------------------------------------------
elsif ($part == 1){
	my @polys;
	my %partTable;
	my @partTableKeysList;

	if ($selMode eq "add"){
		@polys = lxq("query layerservice polys ? visible");
	}else{
		if ($elemName ne "polygon"){lx("!!select.convert polygon");}
		@polys = lxq("query layerservice polys ? selected");
	}

	push(@{$partTable{lxq("query layerservice poly.part ? $_")}},$_) for @polys;

	@partTableKeysList = (keys %partTable);
	randomizeArray(\@partTableKeysList);

	foreach my $key (@partTableKeysList){
		my $chance = rand;
		if ($chance < $random){
			#polys
			if ($elemName eq "polygon"){
				lx("select.element $mainlayer polygon $selMode $_") for @{$partTable{$key}};
			}
			#edges
			elsif ($elemName eq "edge"){
				getOrSelectPolyElems(\@{$partTable{$key}},"edge",$selMode);
			}
			#verts
			elsif ($elemName eq "vertex"){
				getOrSelectPolyElems(\@{$partTable{$key}},"vertex",$selMode);
			}
		}
	}

	if ($elemName ne "polygon"){
		lx("select.type $elemName");
	}
}


#--------------------------------------------
#UV ISLAND ROUTINE
#--------------------------------------------
elsif ($uvIsland == 1){
	our @polys;
	my @touchingUVKeyList;
	selectVmap();

	if ($selMode eq "add"){
		@polys = lxq("query layerservice polys ? visible");
	}else{
		if ($elemName ne "polygon"){lx("!!select.convert polygon");}
		@polys = lxq("query layerservice polys ? selected");
	}

	splitUVGroups();
	@touchingUVKeyList = (keys %touchingUVList);
	randomizeArray(\@touchingUVKeyList);

	foreach my $key (@touchingUVKeyList){
		my $chance = rand;
		if ($chance < $random){
			#polys
			if ($elemName eq "polygon"){
				lx("select.element $mainlayer polygon $selMode $_") for @{$touchingUVList{$key}};
			}
			#edges
			elsif ($elemName eq "edge"){
				getOrSelectPolyElems(\@{$touchingUVList{$key}},"uvEdge",$selMode);
			}
			#verts
			elsif ($elemName eq "vertex"){
				getOrSelectPolyElems(\@{$touchingUVList{$key}},"uvVertex",$selMode);
			}
		}
	}

	if ($elemName ne "polygon"){
		lx("select.type $elemName");
	}
}


#--------------------------------------------
#ELEMENTS ROUTINE
#--------------------------------------------
else{
	my @elems;
	if ($selMode eq "remove")	{	@elems = lxq("query layerservice $elem ? selected");	}
	else						{	@elems = lxq("query layerservice $elem ? visible");		}

	foreach my $elem (@elems){
		my $chance = rand;
		if ($chance < $random){
			if ($elemName eq "edge"){
				my @verts = split (/[^0-9]/, $elem);
				lx("select.element $mainlayer $elemName $selMode index:[@verts[1]] index2:[@verts[2]]");
				#lx("select.element $mainlayer $elemName $selMode index:[@verts[2]] index2:[@verts[1]]");  #might need this because of the edgesel fail, but let's keep it out for now.
			}else{
				lx("select.element $mainlayer $elemName $selMode $elem");
			}
		}
	}
}











#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#GET OR SELECT POLY ELEMS
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE : getOrSelectPolyElems(\@polys,vertex|edge|uvVertex|uvEdge,add|remove|justReturnList);
#EXAMPLE1 : my @verts = getOrSelectPolyElems(\@polys,vertex,justReturnList);
#EXAMPLE2 : getOrSelectPolyElems(\@polys,edge,add);
#NOTE : if you query uvVerts, the list you get back is in this format : $vert,$poly
#NOTE : if you query uvEdges, the list you get back is in this format : $edgeVert1,$edgeVert2,$poly
#NOTE : if you want to desel uvVerts or uvEdges, you have to query the vmapName first.
sub getOrSelectPolyElems{
	my ($polys,$selType,$mode) = @_;

	#--------------------------------------------
	#vertex
	#--------------------------------------------
	if		($selType eq "vertex"){
		my %verts;
		foreach my $poly (@$polys){
			my @vertList = lxq("query layerservice poly.vertList ? $poly");
			$verts{$_} = 1 for @vertList;
		}

		if ($mode eq "justReturnList"){
			return (keys %verts);
		}else{
			lx("select.element $mainlayer vertex $mode $_") for (keys %verts);
		}
	}

	#--------------------------------------------
	#edge
	#--------------------------------------------
	elsif	($selType eq "edge"){
		my %edges;
		foreach my $poly (@$polys){
			my @vertList = lxq("query layerservice poly.vertList ? $poly");
			for (my $i=-1; $i<@vertList; $i++){
				my @edge;
				my $edgeName;
				if ($vertList[$i-1] < $vertList[$i]){
					@edge = ($vertList[$i-1] , $vertList[$i]);
					$edgeName = $vertList[$i-1] . "," . $vertList[$i];
				}else{
					@edge = ($vertList[$i] , $vertList[$i-1]);
					$edgeName = $vertList[$i] . "," . $vertList[$i-1];
				}
				$edges{$edgeName} = \@edge;
			}
		}

		if ($mode eq "justReturnList"){
			return (keys %edges);
		}else{
			foreach my $key (keys %edges){
				lx("select.element $mainlayer edge $mode ${$edges{$key}}[0] ${$edges{$key}}[1]");
			}
		}
	}

	#--------------------------------------------
	#uvVertex
	#--------------------------------------------
	elsif	($selType eq "uvVertex"){
		if ($mode eq "justReturnList"){
			my @uvVertList;
			foreach my $poly (@$polys){
				my @vertList = lxq("query layerservice poly.vertList ? $poly");
				foreach my $vert (@vertList){
					push(@uvVertList,$vert . "," . $poly);
				}
			}
			return @uvVertList;
		}else{
			foreach my $poly (@$polys){
				my @vertList = lxq("query layerservice poly.vertList ? $poly");
				foreach my $vert (@vertList){
					lx("select.element layer:{$mainlayer} type:{vertex} mode:{$mode} index:{$vert} index3:{$poly}");
				}
			}
		}
	}

	#--------------------------------------------
	#uvEdge
	#--------------------------------------------
	elsif	($selType eq "uvEdge"){
		if ($mode eq "justReturnList"){
			my @uvEdgeList;
			foreach my $poly (@$polys){
				my @vertList = lxq("query layerservice poly.vertList ? $poly");
				for (my $i=-1; $i<@vertList; $i++){
					push(@uvEdgeList,$vertList[$i-1] . "," . $vertList[$i] . "," . $poly);
				}
			}
			return @uvEdgeList;
		}else{
			foreach my $poly (@$polys){
				my @vertList = lxq("query layerservice poly.vertList ? $poly");
				for (my $i=-1; $i<@vertList; $i++){
					lx("select.element layer:{$mainlayer} type:{edge} mode:{$mode} index:{$vertList[$i-1]} index2:{$vertList[$i]} index3:{$poly}");
				}
			}
		}
	}

	#--------------------------------------------
	#error
	#--------------------------------------------
	else{
		die("getOrSelectPolyElems sub wasn't sent a proper arg#1");
	}
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#REMOVE ARRAY2 FROM ARRAY1 SUBROUTINE
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE : my @newArray = removeListFromArray(\@full_list,\@small_list);
sub removeListFromArray{
	my $array1Copy = @_[0];
	my $array2Copy = @_[1];
	my @fullList = @$array1Copy;
	my @removeList = @$array2Copy;
	for (my $i=0; $i<@removeList; $i++){
		for (my $u=0; $u<@fullList; $u++){
			if (@fullList[$u] eq @removeList[$i]	){
				splice(@fullList, $u,1);
				last;
			}
		}
	}
	return @fullList;
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

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#RANDOMIZE ARRAY SUB (fisher_yates_shuffle)
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE : randomizeArray(\@array);
sub randomizeArray{
    my $array = shift;
    my $i;
    for ($i=@$array; --$i; ){
        my $j = int rand ($i+1);
        next if $i == $j;
        @$array[$i,$j] = @$array[$j,$i];
    }
}

#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#SPLIT THE POLYGONS INTO TOUCHING UV GROUPS (and build the uvBBOX)
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
sub splitUVGroups{
	lxout("[->] Running splitUVGroups subroutine");
	our %touchingUVList = ();
	our %uvBBOXList = ();
	my %originalPolys;
	my %vmapTable;
	my @scalePolys = @polys;
	my $round = 0;
	foreach my $poly (@scalePolys){
		$originalPolys{$poly} = 1;
	}

	#---------------------------------------------------------------------------------------
	#LOOP1
	#---------------------------------------------------------------------------------------
	#[1] :	(create a current uvgroup array) : (add the first poly to it) : (set 1stpoly to 1 in originalpolylist) : (build uv list for it)
	while (@scalePolys != 0){
		#setup
		my %ignorePolys = ();
		my %totalPolyList;
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
