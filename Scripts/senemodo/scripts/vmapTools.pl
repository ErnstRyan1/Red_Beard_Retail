#perl
#ver 0.91
#author : Seneca Menard

#(4-21-15 feature) : APPLYVNORMS : new feature to apply vertex normals to each selected poly, where the polys' 4 verts get the same normal it has.
#(4-21-15 feature) : AVG APPLYVNORMS : same as feature above, only it uses selected poly islands average normals and applies it to all their polys.
#(4-23-15 fix) : put in the proper algo for finding selected polygon islands, needed for the vertNormal modifications used in the averaging.
#(6-23-15 feature) : applyRandVmapColorPerMeshIsl and applyRandVmapValPerMeshIsl now works with multiple layers
#(7-29-15 feature) : APPLYVNORMS SETPOLYNORMALGRABAPPLY : this was put in so you can make a selection and hover your mouse over a poly to apply it's poly normal direction to the selected elements' vertex normals.
#(9-28-15 feature) : APPLYLARGESTPOLYNORMALS : applies vertex normals by looking at which polys are connected to each vert and whichever poly is the largest has it's poly normal applied to that vertice's normal.  Does a pretty good job automatically but obviously isn't perfect.
#(10-12-15 fix) : put in automatic vertex normal map selection / creation if not already selected or existing.
#(10-12-15 fix) : for applyLargestPolyNormals, made sure it would always work correctly on ngons with colinear verts


#setup
srand;
my $mainlayer = lxq("query layerservice layers ? main");

#cvars
foreach my $arg (@ARGV){
	if		($arg eq "fixBrokenRGBAMap")			{	fixBrokenRGBAMap();				}	
	elsif	($arg eq "copyPasteColor")				{	copyPasteColor();				}
	elsif	($arg eq "repairPolyVmapData")			{	repairPolyVmapData();			}
	elsif	($arg eq "colorTool")					{	colorTool();					}
	elsif	($arg eq "applyColor")					{	applyColor();					}
	elsif	($arg eq "applyWeight")					{	applyWeight();					}
	elsif	($arg eq "applyVNorms")					{	applyVnorms();					}
	elsif	($arg eq "applyRandVmapValPerMeshIsl")	{	applyRandVmapValPerMeshIsl();	}
	elsif	($arg eq "applyRandVmapColorPerMeshIsl"){	applyRandVmapColorPerMeshIsl();	}
	elsif	($arg eq "applyVnorms_ofSelPolysOnly")	{	applyVnorms_ofSelPolysOnly();	}
	elsif	($arg eq "applyLargestPolyNormals")		{	applyLargestPolyNormals();		}
	elsif	($arg eq "selElemsByVmapValue")			{	selElemsByVmapValue();			}
	elsif	($arg eq "deselAll")					{	deselAll();						}
	elsif	($arg =~ /,/)							{	our $color = $arg;				}
	else											{	our $miscArg = $arg;			}
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#SELECT ELEMENTS BY VMAP VALUE (currently selects a poly if any of it's verts match the value)
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#requires QUICKDIALOG, POPUPMULTCHOICE, ROUNDDECIMAL, GETSELECTEDWEIGHTMAP
#note : verts are disco and so you get conflicting results.  you have to unweld all to get true results
sub selElemsByVmapValue{
	my @vmapNameTypeIndice = getSelectedWeightmap();
	my %vmapValueTable;
	
	#get selection mode
	my $selMode;
	if		(lxq( "select.typeFrom {vertex;edge;polygon;item} ?")){	$selMode = "vert";	}
	elsif	(lxq( "select.typeFrom {edge;polygon;item;vertex} ?")){	$selMode = "edge";	}
	elsif	(lxq( "select.typeFrom {polygon;item;vertex;edge} ?")){	$selMode = "poly";	}
	else	{die("You're not in vert, edge or poly mode so i'm canceling the script");	}
	
	#ask how much decimal rounding there should be?
	my $roundingDigits = quickDialog("Round to how many digits?",integer,4,0,10000000);
	
	if ($selMode eq "vert"){
		#find selected verts' vmap values and build table
		my @verts = lxq("query layerservice verts ? selected");
		foreach my $vert (@verts){
			my @vmapValue = lxq("query layerservice vert.vmapValue ? $vert");
			my $vmapValueString;
			for (my $i=0; $i<@vmapValue; $i++){	$vmapValueString .= roundDecimal($vmapValue[$i],$roundingDigits) . ",";	}
			#lxout("A $vert : vmapValueString = $vmapValueString");
			$vmapValueTable{$vmapValueString} = 1;
		}

		#now go through all visible verts and select them if they have matching vmapvalues
		my @visibleVerts = lxq("query layerservice verts ? visible");
		foreach my $vert (@visibleVerts){
			my @vmapValue = lxq("query layerservice vert.vmapValue ? $vert");
			my $vmapValueString;
			for (my $i=0; $i<@vmapValue; $i++){	$vmapValueString .= roundDecimal($vmapValue[$i],$roundingDigits) . ",";	}
			#lxout("B $vert : vmapValueString = $vmapValueString");

			foreach my $key (keys %vmapValueTable){
				if ($key eq $vmapValueString){
					lx("!!select.element $mainlayer vertex add $vert");
					next;
				}
			}
		}
	}
	
	elsif ($selMode eq "edge"){
		
	}
	
	elsif ($selMode eq "poly"){
		#find selected polys' vmap values and build table
		my @polys = lxq("query layerservice polys ? selected");
		my $arraySize = 1;
		if		($vmapNameTypeIndice[1] eq "rgb")	{	$arraySize = 3;	}
		elsif	($vmapNameTypeIndice[1] eq "rgba")	{	$arraySize = 4;	}
		
		foreach my $poly (@polys){
			my @vmapValues = lxq("query layerservice poly.vmapValue ? $poly");
			for (my $i=0; $i<@vmapValues; $i=$i+$arraySize){
				my $vmapValueString;
				for (my $u=0; $u<$arraySize; $u++){
					$vmapValueString .= roundDecimal($vmapValues[$i+$u],$roundingDigits) . ",";
				}
				$vmapValueTable{$vmapValueString} = 1;
			}
		}
		
		#now go through all visible polys and select them if they have matching vmapvalues
		my @visiblePolys = lxq("query layerservice polys ? visible");
		foreach my $poly (@visiblePolys){
			my @vmapValues = lxq("query layerservice poly.vmapValue ? $poly");
			for (my $i=0; $i<@vmapValues; $i=$i+$arraySize){
				my $vmapValueString;
				for (my $u=0; $u<$arraySize; $u++){
					$vmapValueString .= roundDecimal($vmapValues[$i+$u],$roundingDigits) . ",";
				}
				if ($vmapValueTable{$vmapValueString} == 1){
					lx("!!select.element $mainlayer polygon add $poly");
					last;
				}
			}
		}
	}
}


#GO THROUGH ALL VERTS AND APPLY THE LARGEST TOUCHING POLY NORMAL TO IT'S VERT NORMAL
sub applyLargestPolyNormals{
	selectVmapOfCertainType("normal");

	if( lxq( "select.typeFrom {polygon;item;vertex;edge} ?" ) )	{	lx("!!select.convert vertex");											}
	else														{	die("not in vert or poly selection mode so I'm canceling the script");	}
	my @verts = lxq("query layerservice verts ? selected");
	my %polySizeTable;
	
	foreach my $vert (@verts){
		my $largestPoly = -1;
		my $largestPolySize = -1;
		my @polyList = lxq("query layerservice vert.polyList ? $vert");
		foreach my $poly (@polyList){
			if (!exists $polySizeTable{$poly}){
				$polySizeTable{$poly} = getPolyArea($poly);
			}
			
			if ($polySizeTable{$poly} > $largestPolySize){
				$largestPoly = $poly;
				$largestPolySize = $polySizeTable{$poly};
			}
		}
		
		#lxout("vert = $vert <> $largestPoly");
		
		my @polyNormal = lxq("query layerservice poly.normal ? $largestPoly");
		lx("!!select.element $mainlayer vertex set $vert");
		lx("!!vertMap.setValue normal {0} {$polyNormal[0]}");
		lx("!!vertMap.setValue normal {1} {$polyNormal[1]}");
		lx("!!vertMap.setValue normal {2} {$polyNormal[2]}");
	}
	
	lx("!!select.type polygon");
}

#DESELECT ALL VMAPS
sub deselAll{
	my $vmapCount = lxq("query layerservice vmap.n ? all");
	lxout("vmapCount = $vmapCount");
	for (my $i=0; $i<$vmapCount; $i++){
		my $type = lxq("query layerservice vmap.type ? $i");
		lxout("type = $type");
	}
	
	for (my $i=0; $i<$vmapCount; $i++){
		if (lxq("query layerservice vmap.selected ? $i") == 1){
			my $name = lxq("query layerservice vmap.name ? $i");
			my $tag = lxq("query layerservice vmap.tag ? $i");
			
			#grr.  modo's type queries don't match the actual types. plus some use tags and not types
			if ($tag eq "SUBV"){$tag = "subd";}
			lx("select.vertexMap name:{$name} type:{$tag} mode:{remove}");
		}
	}
}

#APPLY RANDOM VMAP COLOR VALUE PER MESH ISLAND
sub applyRandVmapColorPerMeshIsl{
	selectColorVmap();
	
	my @layers = lxq("query layerservice layers ? fg");
	my %polys;
	foreach my $layer (@layers){
		my $layerName = lxq("query layerservice layer.name ? $layer");
		my @polys = lxq("query layerservice polys ? selected");
		$polys{$layer} = \@polys;
	}
	
	foreach my $layer (keys %polys){
		my $layerName = lxq("query layerservice layer.name ? $layer");
		lx("select.drop polygon");
		lx("select.element $layer polygon add $_") for @{$polys{$layer}};
		getPolyPieces(polyIslandSelected,$polys{$layer});

		foreach my $key (keys %getPolyPiecesGroups){ 
			my @randColor = (rand(1),rand(1),rand(1));

			lx("select.drop polygon");
			lx("select.element $layer polygon add $_") for @{$getPolyPiecesGroups{$key}};

			lx("!!tool.set vertMap.setColor on");
			lx("!!tool.attr vertMap.setColor Color {$randColor[0] $randColor[1] $randColor[2] 1}");
			lx("!!tool.doApply");
			lx("!!tool.set vertMap.setColor off");
		}
	}
}

#APPLY RANDOM VMAP VALUE PER MESH ISLAND
sub applyRandVmapValPerMeshIsl{
	selectWeightVmap();
	
	my @layers = lxq("query layerservice layers ? fg");
	my %polys;
	foreach my $layer (@layers){
		my $layerName = lxq("query layerservice layer.name ? $layer");
		my @polys = lxq("query layerservice polys ? selected");
		$polys{$layer} = \@polys;
	}
	
	foreach my $layer (keys %polys){
		my $layerName = lxq("query layerservice layer.name ? $layer");
		lx("select.drop polygon");
		lx("select.element $layer polygon add $_") for @{$polys{$layer}};
		getPolyPieces(polyIslandSelected,$polys{$layer});

		foreach my $key (keys %getPolyPiecesGroups){ 
			my $randVal = rand(1);

			lx("select.drop polygon");
			lx("select.element $layer polygon add $_") for @{$getPolyPiecesGroups{$key}};

			lx("tool.set vertMap.setWeight on");
			lx("tool.setAttr vertMap.setWeight weight {$randVal}");
			lx("tool.doApply");
			lx("tool.set vertMap.setWeight off");
		}
	}
}

#APPLY VERTEX NORMALS TO POLYGONS (BUT USE THE POLY NORMALS OF THE SELECTED POLYS ONLY)
sub applyVnorms_ofSelPolysOnly{
	selectVmapOfCertainType("normal");

	my @polys = lxq("query layerservice polys ? selected");
	if (@polys == 0){die("You don't have any polys selected and so I'm killing the script");}
	my %polyTable;
	$polyTable{$_} = 1 for @polys;
	lx("!!select.convert vertex");
	my @verts = lxq("query layerservice verts ? selected");
	
	foreach my $vert (@verts){
		my @polyList = lxq("query layerservice vert.polyList ? $vert");
		my @avgNorm = (0,0,0);
		my $counter = 0;
		foreach my $poly (@polyList){
			if ($polyTable{$poly} == 1){
				my @normal = lxq("query layerservice poly.normal ? $poly");
				@avgNorm = ( $avgNorm[0]+$normal[0] , $avgNorm[1]+$normal[1] , $avgNorm[2]+$normal[2] );
				$counter++;
			}
		}
		
		@avgNorm = unitVector(arrMath(@avgNorm,$counter,$counter,$counter,div));
		
		lx("!!select.element $mainlayer vertex set $vert");
		lx("!!vertMap.setValue normal {0} {$avgNorm[0]}");
		lx("!!vertMap.setValue normal {1} {$avgNorm[1]}");
		lx("!!vertMap.setValue normal {2} {$avgNorm[2]}");
	}
	lx("!!select.type polygon");
}

#APPLY VERTEX NORMALS TO POLYGONS
sub applyVnorms{
	selectVmapOfCertainType("normal");
	
	our @polys = lxq("query layerservice polys ? selected");
	
	#remember selection type
	if		(lxq("select.typeFrom {vertex;edge;polygon;item} ?"))		{	our $type = "vertex";	}
	elsif	(lxq("select.typeFrom {edge;polygon;item;vertex} ?"))		{	our $type = "edge";		}
	else																{	our $type = "polygon";	}
	
	#go to vertex sel mode
	if ($miscArg ne "grabApply")		{	lx("!!select.type vertex");		}

	#run sub
	if		($miscArg eq "avg")			{	setPolyNormPerSelIsland();		}
	elsif	($miscArg eq "grabApply")	{	setPolyNormalGrabApply();		}
	else								{	setPolyNormPerPoly();			}
	
	#go back to polygon selection mode
	if ($miscArg ne "grabApply")		{	lx("!!select.type polygon");	}
	
}

#APPLYVNORMS : GRAB APPLY POLY NORMAL
sub setPolyNormalGrabApply{
	selectVmapOfCertainType("normal");

	my $viewport = lxq("query view3dservice mouse.view ?");
	my $poly = lxq("query view3dservice element.over ? POLY");
	if ($poly eq ""){	die("Your mouse appears to not be over a poly, so I'm cancelling the script");	}
	
	my @polyData = split(/,/, $poly);
	$polyData[0]++;
	my $layerName = lxq("query layerservice layer.name ? $polyData[0]");
	my @polyNormal = lxq("query layerservice poly.normal ? $polyData[1]");
	
	lx("!!vertMap.setValue normal {0} {$polyNormal[0]}");
	lx("!!vertMap.setValue normal {1} {$polyNormal[1]}");
	lx("!!vertMap.setValue normal {2} {$polyNormal[2]}");
	
	$layerName = lxq("query layerservice layer.name ? $mainlayer");
}

#APPLYVNORMS : APPLY POLY NORMAL PER POLY
sub setPolyNormPerPoly{
	selectVmapOfCertainType("normal");

	foreach my $poly (@polys){
		my @normal = lxq("query layerservice poly.normal ? $poly");
		my @vertList = lxq("query layerservice poly.vertList ? $poly");
		foreach my $vert (@vertList){
			lx("!!select.element {$mainlayer} vertex set $vert");
			lx("!!vertMap.setValue normal {0} {$normal[0]}");
			lx("!!vertMap.setValue normal {1} {$normal[1]}");
			lx("!!vertMap.setValue normal {2} {$normal[2]}");
		}
	}
}

#APPLYVNORMS : APPLY POLY NORMAL PER SELECTION ISLAND
sub setPolyNormPerSelIsland{
	selectVmapOfCertainType("normal");

	getPolyPieces(polyIslandSelected,\@polys);
	foreach my $key (keys %getPolyPiecesGroups){ 
		my @avgNormal = (0,0,0);
		my %vertList;
		my $polyCount = @{$getPolyPiecesGroups{$key}};
		
		foreach my $poly (@{$getPolyPiecesGroups{$key}}){
			my @verts = lxq("query layerservice poly.vertList ? $poly");
			$vertList{$_} = 1 for @verts;
			my @normal = lxq("query layerservice poly.normal ? $poly");
			@avgNormal = arrMath(@avgNormal,@normal,add);
		}
		
		@avgNormal = unitVector(arrMath(@avgNormal,$polyCount,$polyCount,$polyCount,div));
		
		lx("select.drop vertex");
		lx("select.element $mainlayer vertex add $_") for (keys %vertList);
		lx("!!vertMap.setValue normal {0} {$avgNormal[0]}");
		lx("!!vertMap.setValue normal {1} {$avgNormal[1]}");
		lx("!!vertMap.setValue normal {2} {$avgNormal[2]}");
	}
}

#APPLY COLOR
sub applyColor{
	selectColorVmap();
	my @vmapColor = split(/,/, $color);
	
	lx("!!tool.set vertMap.setColor on");
	lx("!!tool.attr vertMap.setColor Color {$vmapColor[0] $vmapColor[1] $vmapColor[2] $vmapColor[3]}");
	lx("!!tool.doApply");
	lx("!!tool.set vertMap.setColor off");
}

#APPLY WEIGHT
sub applyWeight{
	selectWeightVmap("Subdivision");	
	lx("tool.set vertMap.setWeight on");
	lx("tool.setAttr vertMap.setWeight weight {$miscArg}");
	lx("tool.doApply");
	lx("tool.set vertMap.setWeight off");
}

#COLOR TOOL
sub colorTool{
	selectColorVmap();
	lx("!!tool.set vertMap.setColor on");
}


#REPAIR POLY VMAP DATA (will just rebuild polys and delete the old ones that have locked values)
sub repairPolyVmapData{
	my @polys = lxq("query layerservice polys ? selected");
	my %materialTable;
	$materialTable{$_} = lxq("query layerservice poly.material ? $_") for @polys;

	selectVmap();
	lx("!!select.drop vertex");

	foreach my $poly (@polys){
		my @vertList = lxq("query layerservice poly.vertList ? $poly");
		lx("!!select.drop vertex");
		lx("!!select.element $mainlayer vertex add $_") for @vertList;
		lx("!!poly.make face false");
		my $material = $materialTable{$poly}; 
		lx("select.type polygon");
		lx("!!poly.setMaterial {$material}");
	}

	lx("!!select.drop polygon");
	lx("!!select.element $mainlayer polygon add $_") for @polys;
	lx("!!delete");
	lx("!!poly.align");

	lx("select.drop polygon");
	my $polyCount = lxq("query layerservice poly.n ? all");
	for (my $i=1; $i<=@polys; $i++){
		my $poly = $polyCount - $i;
		lx("!!select.element $mainlayer polygon add $poly");
	}
}

#COPY PASTE COLOR SUB : have some elements selected and hover mouse over poly and it'll grab the poly's first vert's color.
sub copyPasteColor{
	my @rgbaMaps = lxq("query layerservice vmaps ? rgba");
	my $foundVmap;
	my $vmapName;
	
	foreach my $vmap (@rgbaMaps){
		if (lxq("query layerservice vmap.selected ? $vmap") == 1){
			$foundVmap = $vmap;
			$vmapName = lxq("query layerservice vmap.name ? $vmap");
			last;
		}
	}
	if ($vmapName eq ""){die("No RGBA maps could be found so the script is being canceled");}
	
	my $viewport = lxq("query view3dservice mouse.view ?");
	my $vert = lxq("query view3dservice element.over ? VERT");
	my $edge = lxq("query view3dservice element.over ? EDGE");
	my $poly = lxq("query view3dservice element.over ? POLY");
	
	my $foundLayer;
	my $foundVert;
	if ($vert ne ""){
		lxout("vert is under mouse");
		my @data = split(/,/, $vert);
		$foundLayer = $data[0];
		$foundVert = $data[1];
	}elsif	($edge ne ""){
		lxout("edge is under mouse");
		my @data = split(/,/, $edge);
		$foundLayer = $data[0];
		$foundVert = $data[1];
	}elsif	($poly ne ""){
		lxout("poly is under mouse");
		my @data = split(/,/, $poly);
		$foundLayer = $data[0];
		my @polyVertList = lxq("query layerservice poly.vertList ? $data[1]");
		$foundVert = $polyVertList[0];
	}else{
		die("The mouse was not over a vert, edge, or poly and so i'm cancelling the script");
	}
	
	#my $layerName = lxq("query layerservice layer.name ? $foundLayer");
	#$vmapName = lxq("query layerservice vmap.name ? $foundVmap");
	my @vmapValue = lxq("query layerservice vert.vmapValue ? $foundVert");
	lxout("found vert = $foundVert");
	lxout("vmapValue = @vmapValue");
	
	lx("!!tool.set vertMap.setColor on");
	lx("!!tool.attr vertMap.setColor Color {$vmapValue[0] $vmapValue[1] $vmapValue[2] $vmapValue[3]}");
	lx("!!tool.doApply");
	lx("!!tool.set vertMap.setColor off");
}

#FIX BROKEN RGBA MAP : this creates a new RGBA vmap and copies the values in the "Color" vmap to it and then deletes the old one and the new one gets it's name.
sub fixBrokenRGBAMap{
	lx("select.drop polygon");
	lx("unhide");
	lx("select.vertexMap Color rgba replace");
	lx("vertMap.copy rgba");
	lx("vertMap.new Color rgba true {0.5 0.5 0.5}");
	lx("vertMap.paste rgba");
	lx("select.vertexMap Color rgba replace");
	lx("vertMap.delete rgba");
	lx("select.vertexMap {Color (2)} rgba replace");
	lx("vertMap.name Color rgba active");
}












#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#SELECT WEIGHT VMAP
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#selects the first weightmap it finds in this name order : "weight","falloff","*.*","senetemp"
#arguments : any argument you send it will skip allowing that vmap (by name) to be selected.
sub selectWeightVmap{
	my $vmapCount = lxq("query layerservice vmap.n ? all");
	my %vmapTable;
	my %vmapsNotAllowed;

	foreach my $arg (@_){	$vmapsNotAllowed{$arg} = 1; }

	for (my $i=0; $i<$vmapCount; $i++){
		my $name =		lxq("query layerservice vmap.name ? $i");
		my $type =		lxq("query layerservice vmap.type ? $i");
		my $selected =	lxq("query layerservice vmap.selected ? $i");
		
		if		($vmapsNotAllowed{$name} == 1)					{	next;							}
		elsif	(($type eq "weight") && ($selected == 1))		{	return;							}
		elsif	(($type eq "weight") && ($name eq "senetemp"))	{	$vmapTable{"senetemp"} = $name;	}
		elsif	(($type eq "weight") && ($name eq "Weight"))	{	$vmapTable{"weight"} = $name;	}
		elsif	(($type eq "weight") && ($name eq "Falloff"))	{	$vmapTable{"falloff"} = $name;	}
		elsif	($type eq "weight")								{	$vmapTable{"misc"} = $name;		}
	}
	
	if		(exists $vmapTable{"weight"})	{	lx("!!select.vertexMap {$vmapTable{\"weight\"}} wght replace");		}
	elsif	(exists $vmapTable{"falloff"})	{	lx("!!select.vertexMap {$vmapTable{\"falloff\"}} wght replace");	}
	elsif	(exists $vmapTable{"misc"})		{	lx("!!select.vertexMap {$vmapTable{\"misc\"}} wght replace");		}
	elsif	(exists $vmapTable{"senetemp"})	{	lx("!!select.vertexMap {$vmapTable{\"senetemp\"}} wght replace");	}
}


#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#SELECT COLOR VMAP
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
sub selectColorVmap{
	my $vmapCount = lxq("query layerservice vmap.n ? all");
	my %vmapTable;

	for (my $i=0; $i<$vmapCount; $i++){
		my $name =		lxq("query layerservice vmap.name ? $i");
		my $type =		lxq("query layerservice vmap.type ? $i");
		my $selected =	lxq("query layerservice vmap.selected ? $i");
		
		if (($type eq "weight") && ($selected == 1)){
			lx("select.vertexMap type:{wght} name:{$name} mode:{remove}");
		}elsif ($type eq "rgb"){
			${$vmapTable{"rgb"}}[0] = $i;
			${$vmapTable{"rgb"}}[1] = $selected + 1;
			${$vmapTable{"rgb"}}[2] = $name;
		}elsif ($type eq "rgba"){
			${$vmapTable{"rgba"}}[0] = $i;
			${$vmapTable{"rgba"}}[1] = $selected + 1;
			${$vmapTable{"rgba"}}[2] = $name;
		}
	}
	
	if    (${$vmapTable{"rgba"}}[1] == 2)	{																							}
	elsif (${$vmapTable{"rgb"}}[1] == 2)	{																							}
	elsif (${$vmapTable{"rgba"}}[1] == 1)	{	lx("select.vertexMap type:{rgba} name:{${$vmapTable{\"rgba\"}}[2]} mode:{replace}");	}
	elsif (${$vmapTable{"rgb"}}[1] == 1)	{	lx("select.vertexMap type:{rgb} name:{${$vmapTable{\"rgb\"}}[2]} mode:{replace}");		}
}


#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#SELECT THE PROPER VMAP OF A SPECIFIC TYPE SUB (creates if doesn't exist) v2.0
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#usage : selectVmapOfCertainType("rgb");
#note : 
#requires popupMultChoice sub
sub selectVmapOfCertainType{
	my @foundVmaps;
	my $vmapCount = lxq("query layerservice vmap.n ? all");
	
	#translate types to names that modo reads
	my %translateTable;
		$translateTable{"weight"}		= "wght";
		$translateTable{"subvweight"}	= "subd";
		$translateTable{"texture"}		= "txuv";
		$translateTable{"morph"}		= "morf";
		$translateTable{"spot"}			= "spot";
		$translateTable{"rgb"}			= "rgb";
		$translateTable{"rgba"}			= "rgba";
		$translateTable{"pick"}			= "pick";
		$translateTable{"normal"}		= "norm";
		$translateTable{"edgepick"}		= "epck";
		#particlesize, particledissolve, transform, vector, tangentbasis are not showing up in queried vmaps so i'm temporarily giving them the internal names
		$translateTable{"psiz"}			= "psiz";
		$translateTable{"pdis"}			= "pdis";
		$translateTable{"xfrm"}			= "xfrm";
		$translateTable{"vect"}			= "vect";
		$translateTable{"tbas"}			= "tbas";
		
	#look for vmaps of said type
	for (my $i=0; $i<$vmapCount; $i++){
		if (lxq("query layerservice vmap.type ? $i") eq $_[0]){
			if (lxq("query layerservice vmap.selected ? $i") == 1){
				my $name = lxq("query layerservice vmap.name ? $i");
				lxout("[->] SELECTVMAPOFCERTAINTYPE : '$name' was of the type we're looking for and is already selected so i don't need to do anything");
				return;
			}else{
				push(@foundVmaps,lxq("query layerservice vmap.name ? $i"));
			}
		}
	}

	#if only one found, use it.
	if (@foundVmaps == 1){
		lxout("[->] : Only one $_[0] vmap exists, so I'm selecting it : $foundVmaps[0]");
		lx("select.vertexMap name:{$selectedVmap} type:{$translateTable{$_[0]}} mode:{replace}");
	}
	
	#if >1 found, use popup window to pick which one
	elsif (@foundVmaps > 1){
		my $options = "";
		for (my $i=0; $i<@foundVmaps; $i++){	$options .= $foundVmaps[$i] . ";";	}
		my $selectedVmap = popupMultChoice("Which vmap to select? :",$options,0);
		lx("select.vertexMap name:{$selectedVmap} type:{$translateTable{$_[0]}} mode:{replace}");
	}
	
	#no vmaps existed so i'm creating one.
	else{
		lxout("[->] : No $type vmaps existed, so I had to create one");											
		if 		($translateTable{$_[0]} eq "rgb")	{	lx("vertMap.new Color rgb false {0.78 0.78 0.78}");												}
		elsif	($translateTable{$_[0]} eq "rgba")	{	lx("vertMap.new Color rgba false {0.78 0.78 0.78} 1.0");										}
		elsif	($translateTable{$_[0]} eq "wght")	{	lx("vertMap.new Weight wght false {0.78 0.78 0.78}");											}
		elsif	($translateTable{$_[0]} eq "txuv")	{	lx("vertMap.new UVChannel_1 txuv false {0.78 0.78 0.78} 1.0");									}
		elsif	($translateTable{$_[0]} eq "norm")	{	lx("vertMap.new {Vertex Normal} norm false {0.78 0.78 0.78} 1.0");								}
		elsif	($translateTable{$_[0]} eq "morf")	{	lx("vertMap.new Morph morf false {0.78 0.78 0.78} 1.0");										}
		elsif	($translateTable{$_[0]} eq "spot")	{	lx("vertMap.new AMorph spot false {0.78 0.78 0.78} 1.0");										}
		elsif	($translateTable{$_[0]} eq "pick")	{	lx("vertMap.new Pick pick false {0.78 0.78 0.78} 1.0");											}
		elsif	($translateTable{$_[0]} eq "epck")	{	lx("vertMap.new {Edge Pick} epck false {0.78 0.78 0.78} 1.0");									}
		elsif	($translateTable{$_[0]} eq "psiz")	{	lx("vertMap.new {Particle Size} psiz color:{0.78 0.78 0.78}");									}
		elsif	($translateTable{$_[0]} eq "pdis")	{	lx("vertMap.new {Particle Dissolve} pdis true {0.78 0.78 0.78} 1.0");							}
		elsif	($translateTable{$_[0]} eq "xfrm")	{	lx("vertMap.new {Transform} type:xfrm init:true color:{0.78 0.78 0.78} value:1.0");				}
		elsif	($translateTable{$_[0]} eq "vect")	{	lx("vertMap.new name:vect type:xfrm init:true color:{0.78 0.78 0.78} value:1.0");				}
		elsif	($translateTable{$_[0]} eq "tbas")	{	lx("vertMap.new name:{Tangent Basis} type:tbas init:true color:{0.78 0.78 0.78} value:1.0");	}
	}
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
#QUERY AREA OF NGON (ver 1.1)
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#requires DOTPRODUCT, CROSSPRODUCT, UNITVECTOR, DET, GETTHREENONCOLINEARVERTSFROMNGON, and GETPOLYNORMALFROMTRI subs
#usage my $area = getPolyArea($polyIndice);
sub getPolyArea{
	my @vertList = lxq("query layerservice poly.vertList ? $_[0]");
	if (@vertList < 3){	die("area sub : less than 3 verts sent so this is not a legal poly");	}

	my @threeNonColinearVertsFromNgon = getThreeNonColinearVertsFromNgon($_[0]);
	my @vertPos0 = lxq("query layerservice vert.pos ? $threeNonColinearVertsFromNgon[0]");
	my @vertPos1 = lxq("query layerservice vert.pos ? $threeNonColinearVertsFromNgon[1]");
	my @vertPos2 = lxq("query layerservice vert.pos ? $threeNonColinearVertsFromNgon[2]");
	my @total = (0,0,0);
	
	for (my $i=0; $i<@vertList; $i++){
		my @vi1 = lxq("query layerservice vert.pos ? $vertList[$i]");
		my @vi2;
		if ($i == $#vertList)	{	@vi2 = lxq("query layerservice vert.pos ? $vertList[0]");		}
		else					{	@vi2 = lxq("query layerservice vert.pos ? $vertList[$i+1]");	}
		my @prod = crossProduct(\@vi1, \@vi2);
		
		$total[0] += $prod[0];
		$total[1] += $prod[1];
		$total[2] += $prod[2];
	}
	
	my $result = dotProduct(\@total, getPolyNormalFromTri(\@vertPos0, \@vertPos1, \@vertPos2));
	return abs($result * .5);
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#GET THREE NON COLINEAR VERTS FROM NGON
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
sub getThreeNonColinearVertsFromNgon{
	my $foundColinearEdge = 0;

	#return 1 if less than 3 verts
	my @vertList = lxq("query layerservice poly.vertList ? $_[0]");
	if (@vertList < 3){	die("getThreeNonColinearVertsFromNgon : This poly {$_[0]} does not have at least 3 planar verts so I'm cancelling the script");	}
	
	#get check if first 2 edges of ngon are colinear.
	my @vertPos0 = lxq("query layerservice vert.pos ? $vertList[0]");
	my @vertPos1 = lxq("query layerservice vert.pos ? $vertList[1]");
	my @vertPos2 = lxq("query layerservice vert.pos ? $vertList[2]");
	my @vector0 = unitVector(arrMath(@vertPos0,@vertPos1,subt));
	my @vector1 = unitVector(arrMath(@vertPos1,@vertPos2,subt));
	my $dp = dotProduct(\@vector0,\@vector1);
	if ($dp > 0.9999){	$foundColinearEdge = 1;	}
	if ((abs($vector0[0]) == 0) && (abs($vector0[1]) == 0) && (abs($vector0[2]) == 0)){die("getThreeNonColinearVertsFromNgon : This poly {$_[0]} has 2 verts lying on top of each other so I'm cancelling script");}
	if ((abs($vector1[0]) == 0) && (abs($vector1[1]) == 0) && (abs($vector1[2]) == 0)){die("getThreeNonColinearVertsFromNgon : This poly {$_[0]} has 2 verts lying on top of each other so I'm cancelling script");}
	#lxout("foundColinearEdge = $foundColinearEdge <> $_[0]");
	#return first 3 verts if not colinear
	if ($foundColinearEdge == 0){	return ($vertList[0],$vertList[1],$vertList[2]);	lxout("col");}

	#if 1st 2 edges are colinear, find any vert that isn't colinear
	elsif (@vertList > 3){
		for (my $i=3; $i<@vertList; $i++){
			@vertPos2 = lxq("query layerservice vert.pos ? $vertList[$i]");
			@vector1 = unitVector(arrMath(@vertPos1,@vertPos2,subt));
			if ((abs($vector1[0]) == 0) && (abs($vector1[1]) == 0) && (abs($vector1[2]) == 0)){die("getThreeNonColinearVertsFromNgon : This poly {$_[0]} has 2 verts lying on top of each other so I'm cancelling script");}
			my $dp = dotProduct(\@vector0,\@vector1);
			if (abs($dp) < 0.9999){	return($vertList[0],$vertList[1],$vertList[$i]);	}
		}
	}
	
	#return 1 if no noncolinear edge was found.
	else{	die("getThreeNonColinearVertsFromNgon : This poly {$_[0]} does not have at least 3 planar verts so I'm cancelling the script");	}
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#DETERMINANT OF MATRIX A (3x3 matrix)
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
sub det{
	return ${$_[0]}[0][0]*${$_[0]}[1][1]*${$_[0]}[2][2] + ${$_[0]}[0][1]*${$_[0]}[1][2]*${$_[0]}[2][0] + ${$_[0]}[0][2]*${$_[0]}[1][0]*${$_[0]}[2][1] - ${$_[0]}[0][2]*${$_[0]}[1][1]*${$_[0]}[2][0] - ${$_[0]}[0][1]*${$_[0]}[1][0]*${$_[0]}[2][2] - ${$_[0]}[0][0]*${$_[0]}[1][2]*${$_[0]}[2][1];
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#QUERY UNIT NORMAL VECTOR OF PLANE DEFINED BY POINTS A, B, AND C
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
sub getPolyNormalFromTri{  #FIX : can get an illegal divide by zero on polys with verts on colinear edges.. should put in a check to get another tri from that ngon
	my @m0 = (	
		[1,${$_[0]}[1],${$_[0]}[2]],
		[1,${$_[1]}[1],${$_[1]}[2]],
		[1,${$_[2]}[1],${$_[2]}[2]],
	);
	my @m1 = (	
		[${$_[0]}[0],1,${$_[0]}[2]],
		[${$_[1]}[0],1,${$_[1]}[2]],
		[${$_[2]}[0],1,${$_[2]}[2]],
	);
	my @m2 = (
		[${$_[0]}[0],${$_[0]}[1],1],
		[${$_[1]}[0],${$_[1]}[1],1],
		[${$_[2]}[0],${$_[2]}[1],1],
	);
	

	my $x = det(\@m0);
	my $y = det(\@m1);
	my $z = det(\@m2);
	my $magnitude = ($x**2 + $y**2 + $z**2)**.5;
	my @array = ($x/$magnitude, $y/$magnitude, $z/$magnitude);
	return \@array;
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#CROSSPRODUCT SUBROUTINE (ver 1.1)
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE : my @crossProduct = crossProduct(\@vector1,\@vector2);
sub crossProduct{
	return ( (${$_[0]}[1]*${$_[1]}[2])-(${$_[1]}[1]*${$_[0]}[2]) , (${$_[0]}[2]*${$_[1]}[0])-(${$_[1]}[2]*${$_[0]}[0]) , (${$_[0]}[0]*${$_[1]}[1])-(${$_[1]}[0]*${$_[0]}[1]) );
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#DOT PRODUCT subroutine (ver 1.1)
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE : my $dp = dotProduct(\@vector1,\@vector2);
sub dotProduct{
	return (	(${$_[0]}[0]*${$_[1]}[0])+(${$_[0]}[1]*${$_[1]}[1])+(${$_[0]}[2]*${$_[1]}[2])	);
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#GET SELECTED WEIGHT MAP (weight, rgb, and rgba)
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#usage my @vmapNameTypeIndice = getSelectedWeightmap(); #returns weightmap name, type, and indice
#requires popupMultChoice sub
sub getSelectedWeightmap{
	#should i look for WEIGHT, RGB, or RGBA vmap?
	my $vmapCount = lxq("query layerservice vmap.n ? all");
	my %selVmapTable;
	my $key;
	my $vmapName;
	my %vmapIndiceTable;
	my $chosenVmapIndice = -1;
	for (my $i=0; $i<$vmapCount; $i++){
		if (lxq("query layerservice vmap.selected ? $i") == 1){
			my $name = lxq("query layerservice vmap.name ? $i");
			if		(lxq("query layerservice vmap.type ? $i") eq "weight")	{	push(@{$selVmapTable{"weight"}},$name);	$vmapIndiceTable{"weight"}{$name} = $i;	}
			elsif	(lxq("query layerservice vmap.type ? $i") eq "rgb")		{	push(@{$selVmapTable{"rgb"}},$name);	$vmapIndiceTable{"rgb"}{$name} = $i;	}
			elsif	(lxq("query layerservice vmap.type ? $i") eq "rgba")	{	push(@{$selVmapTable{"rgba"}},$name);	$vmapIndiceTable{"rgba"}{$name} = $i;	}
		}
	}
	
	if ((keys %selVmapTable) > 1){
		my $listOfTypes;
		$listOfTypes .= $_ . ";" for (keys %selVmapTable);
		$key = popupMultChoice("Which type of vmap?",$listOfTypes,0);
	}elsif ((keys %selVmapTable) == 1){
		$key = (keys %selVmapTable)[0];
	}else{
		die("You don't have a WEIGHT, RGB, or RGBA map selected so I'm canceling the script");
	}
	
	#find which vmap of that chosen type to use
	if (@{$selVmapTable{$key}} > 1){
		my $whichVmapString;
		$whichVmapString .= $_ . ";" for @{$selVmapTable{$key}};
		$vmapName = popupMultChoice("Which vmap?",$whichVmapString,0);
	}else{
		$vmapName = @{$selVmapTable{$key}}[0];
	}
	
	#get vmap indice of chosen vmap
	$chosenVmapIndice = $vmapIndiceTable{$key}{$vmapName};

	#deselect all weight/rgb/rgba vmaps except chosen indice
	for (my $i=0; $i<$vmapCount; $i++){
		if ($i != $chosenVmapIndice){
			my $name = lxq("query layerservice vmap.name ? $i");
			
			if		(lxq("query layerservice vmap.type ? $i") eq "weight")	{	lx("!!select.vertexMap name:{$name} type:{wght} mode:{remove}");	}
			elsif	(lxq("query layerservice vmap.type ? $i") eq "rgb")		{	lx("!!select.vertexMap name:{$name} type:{rgb} mode:{remove}");		}
			elsif	(lxq("query layerservice vmap.type ? $i") eq "rgba")	{	lx("!!select.vertexMap name:{$name} type:{rgba} mode:{remove}");	}
		}
	}

	#reselect the vmap if it's not selected anymore (modo bug)
	if (lxq("query layerservice vmap.selected ? $chosenVmapIndice") == 0){	lx("!!select.vertexMap name:{$vmapName} type:{$key} mode:{replace}");	}
	
	#get name of chosen vmap again for querying purposes
	my $tempName = lxq("query layerservice vmap.name ? $chosenVmapIndice");
	
	return ($vmapName,$key,$chosenVmapIndice);
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
#QUICK DIALOG SUB v2.1
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE : quickDialog(username,float,initialValue,min,max);
sub quickDialog{
	if (@_[1] eq "yesNo"){
		lx("dialog.setup yesNo");
		lx("dialog.msg {$_[0]}");
		lx("dialog.open");
		if (lxres != 0){	die("The user hit the cancel button");	}
		return (lxq("dialog.result ?"));
	}else{
		if (lxq("query scriptsysservice userValue.isdefined ? seneTempDialog") == 1){
			lx("user.defDelete seneTempDialog");
		}
		lx("user.defNew name:[seneTempDialog] type:{$_[1]} life:[momentary]");		
		lx("user.def seneTempDialog username [$_[0]]");
		if (($_[3] != "") && ($_[4] != "")){
			lx("user.def seneTempDialog min [$_[3]]");
			lx("user.def seneTempDialog max [$_[4]]");
		}
		lx("user.value seneTempDialog [$_[2]]");
		lx("user.value seneTempDialog ?");
		if (lxres != 0){	die("The user hit the cancel button");	}
		return(lxq("user.value seneTempDialog ?"));
	}
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#sub roundDecimal v1.5
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#This will round a number to a certain decimal point (and insert 0s if empty)
#usage : my $roundedNumber = roundDecimal(1.123456789,3);   #returns a string of 1.123
sub roundDecimal{
	my $number = $_[0];
	my $neg = 0;
	
	#hide negative temporarily
	if ($number =~ /^-/){
		$neg = 1;
		$number =~ s/^-//;
	}

	#super low number with e display
	if ($number =~ /e/){
		$number =~ s/\.//;
		my @split = split (/[e-]/, $number);
		my $newString = "0.";
		for (my $i=i; $i<$split[2]; $i++){	$newString .= "0";	}
		$number = $newString . $split[0];
	}
	
	#no period
	if ($number !~ /\./){
		$number .= ".";
		for (my $i=0; $i<$_[1]; $i++){	$number .= "0";	}
	}
	
	#now do decimal truncating
	else{
		my $counter = 0;
		my @split = split (/[.]/, $number);
		my @letters = split(//, $split[1]);
		
		#round up number if the first cut off digit is above 4
		my $poo = @letters;
		my $poo2 = $letters[$_[1]];
		if ( (@letters > $_[1]) && ($letters[$_[1]] > 4) ){
			my $roundUp = 1;
			for (my $i=$_[1]-1; $i>=0; $i--){
				if ($roundUp == 1){
					if ($letters[$i] == 9)	{	
						$letters[$i] = 0;	
					}else{	
						$letters[$i] += 1;
						$roundUp = 0;
						last;
					}
				}
			}
			
			if ($roundUp == 1)	{	$split[0] += 1;	}
		}
		
		$number = $split[0] . ".";
		for (my $i=0; $i<@letters; $i++){
			if ($i >= $_[1]){
				last;
			}else{
				$number .= $letters[$i];
				$counter++;
			}
		}
		
		if ($counter < $_[1]){
			my $diff = $_[1] - $counter;
			for (my $i=0; $i<$diff; $i++){
				$number .= "0";
			}
		}
	}
	
	#now put negative back again
	if ($neg == 1){
		my $allZeroes= "0.";
		for (my $i=0; $i<$_[1]; $i++)	{	$allZeroes .= "0";			}
		if ($number ne $allZeroes)		{	$number = "-" . $number;	}
	}
	
	return $number;
}
