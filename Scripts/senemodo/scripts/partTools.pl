#perl
#ver 1.0
#author : Seneca Menard

#this script is for grouping various parts together so you can create a heirarchy, basically.

#script cvars
foreach my $arg (@ARGV){
	lxout("arg = $arg");
	if		($arg =~ /select/i)				{	our $select = 1;				}
	elsif	($arg =~ /^group/i)				{	our $group = 1;					}
	elsif	($arg =~ /ungroup/i)			{	our $ungroup = 1;				}
	elsif	($arg =~ /applyPartPerIsland/i)	{	our $applyPartPerIsland = 1;	}
}

my @alphabet = (0,1,2,3,4,5,6,7,8,9,0,"a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z");
my $mainlayer = lxq("query layerservice layers ? main");
my @polys = lxq("query layerservice polys ? selected");
my %partList;

#determine which subroutine to run
if		($select == 1)				{	&select;				}
elsif	($group == 1)				{	&group;					}
elsif	($ungroup == 1)				{	&ungroup;				}
elsif	($applyPartPerIsland == 1)	{	&applyPartPerIsland;	}




#===============================================
#APPLY PART PER MESH ISLAND
#===============================================
sub applyPartPerIsland{
	my @alphabet = (0,1,2,3,4,5,6,7,8,9,0,"a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z");
	my @polys = lxq("query layerservice polys ? selected");
	getPolyPieces(polyIsland,\@polys); 
	
	foreach my $key (keys %getPolyPiecesGroups){ 
		lx("!!select.drop polygon");
		lx("!!select.element $mainlayer polygon add $_") for @{$getPolyPiecesGroups{$key}};
		lx("!!poly.setPart {}");

		my $partName;
		for (my $i=0; $i<12; $i++){$partName .= @alphabet[rand(35)];}
		lx("!!poly.setPart {$partName}");
	}
	
	lx("!!select.drop polygon");
	lx("!!select.element $mainlayer polygon add $_") for @polys;
}


#===============================================
#SELECT SUBROUTINE
#===============================================
sub select{
	lxout("[->] : select");
	push(@{$partList{lxq("query layerservice poly.part ? $_")}},$_) for @polys;
	my @prefixList;

	foreach my $part (keys %partList){
		if ($part =~ /_/){
			my $partPrefix = $part;
			$partPrefix =~ s/_.*//;
			push(@prefixList,$partPrefix);
		}
	}

	my $partCount = lxq("query layerservice part.n ? all");
	for (my $i=0; $i<$partCount; $i++){
		my $partName = lxq("query layerservice part.name ? $i");
		foreach my $partPrefix (@prefixList){
			my $match = $partPrefix . "_";
			if ($partName =~ $match){
				lxout("yes : $partName");
				lx("!!select.polygon add part face {$partName}");
				last;
			}
		}
	}
}

#===============================================
#UNGROUP SUBROUTINE
#===============================================
sub ungroup{
	lxout("[->] : ungroup");
	push(@{$partList{lxq("query layerservice poly.part ? $_")}},$_) for @polys;

	foreach my $part (keys %partList){
		if ($part !~ /_/){next;}

		my $newPart = $part;
		if ($newPart =~ /_/){$newPart =~ s/.*_//;}
		lx("select.drop polygon");
		lx("select.element $mainlayer polygon add {$_}") for @{$partList{$part}};
		lx("poly.setPart {$newPart}");
	}

	selectOrigPolys();
}

#===============================================
#GROUP SUBROUTINE
#===============================================
sub group{
	lxout("[->] : group");
	my $partPrefix;
	for (my $i=0; $i<6; $i++){$partPrefix .= @alphabet[rand(35)];}
	push(@{$partList{lxq("query layerservice poly.part ? $_")}},$_) for @polys;

	foreach my $part (keys %partList){
		my $newPart = $part;
		lxout("1newPart = $newPart");
		if ($newPart =~ /_/){$newPart =~ s/.*_//;}
		lxout("2newPart = $newPart");
		$newPart = $partPrefix . "_" . $newPart;
		lxout("3newPart = $newPart");

		lx("select.drop polygon");
		lx("select.element $mainlayer polygon add $_") for @{$partList{$part}};
		lx("poly.setPart {$newPart}");
	}

	selectOrigPolys();
}

#===============================================
#SELECT ORIGINAL POLYS SUBROUTINE
#===============================================
sub selectOrigPolys{
	lx("select.drop polygon");
	lx("select.element $mainlayer polygon add $_") for @polys;
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
#GETPOLYPIECES SUB (get a list of poly groups under different search criteria)
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE1 : getPolyPieces(poly,\@polys);  #setup
#USAGE1 : getPolyPieces(polyIsland,\@polys);  #setup
#USAGE1 : getPolyPieces(polyIslandVisible,\@polys);  #setup
#USAGE1 : getPolyPieces(uvIsland,\@polys);  #setup
#USAGE1 : getPolyPieces(part,\@polys);  #setup
#USAGE2 : foreach my $key (keys %getPolyPiecesGroups){ #blah }
#requires listTouchingPolys2 sub
#requires selectVmap sub
#requires splitUVGroups sub
#requires removeListFromArray sub
sub getPolyPieces{
	our %getPolyPiecesGroups;
	our %getPolyPiecesUvBboxes;
	our $piecesCount;
	our $currentPiece;

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
