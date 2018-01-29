#perl
#author : Seneca Menard
#ver 4.13

#==============================
#NEW DOCS :
#==============================
#This script has been rewritten to a new way of working.  You just take your model and split it up into different layers and each layer is now a moving part.  If any part has more than 16 "planes" in it,then you'll have to manually create a collision model for that piece.  The way you do that is to just create a convex mesh with less than 16 planes to it and apply "textures/common/collision" to those polys and those will be treated as the collision for that piece.   Also, if you look in the event log window, it'll tell you how many collision planes each layer has.  Lastly, if your layer is called "base", it'll ignore any errors about how much collision data it might have.

#==============================
#OLD DOCS :
#==============================
#This script is to apply unique material numbers to each poly mesh or poly part for creating exploding brick walls or cars or whatever.
#There's now a new feature that will let you hide all the parts of the model that have collision models.
#You can now select both the clip polys and regular polys and apply unique numbers and it'll update both.
#The script now works with models that have multiple materials
#The script now has a debug feature that does 3 things : reports any missing indices.  reports indices without both col+noncol.  manually shows you the polys using each indice so you can make sure they look correct.
#The script now has the Print Explosion Info tool that does 3 things depending on whether you're in vert, edge, or poly mode.  VERTMODE = print that vert pos in rage units so it's easy to type in an explosion origin.  POLYMODE = print the poly selection's radius and origin so it's easy to type in an explosion's radius and origin.  EDGEMODE = prints which collision models are touching the edges  you have selected so it's easy to select some edges and find out which collision numbers they have.

#FIXES + CHANGES :
#2-2-10 bugfix : it now won't complain about materials that don't have a number in them.
#6-22-12 bugfix : oops.  i was pasting the geometry into the first layer and you shouldn't do that because it'll dupe the contents of the first layer.
#6-25-12 : the script now ignores all errors if your layer's name is "base".
#7-9-12 : fixed a collision poly setup bug

my $modoVer = lxq("query platformservice appversion ?");
if ($modoVer > 500){our $lwoType = "\$NLWO2";} else {our $lwoType = "\$LWO2";}
my $mainlayer = lxq("query layerservice layers ? main");
my %alreadyChecked;
my %sameNormalTable;
my $totalPolyCount = lxq("query layerservice poly.n ? all");

#SCRIPT ARGUMENTS :
foreach my $arg (@ARGV){
	if 		($arg =~ /\bhide\b/i)					{	our $hide = 1;						}
	elsif	($arg =~ /applyUniqueClip/i)			{	our $applyUniqueClip = 1;			}
	elsif	($arg =~ /hideClippedPolys/i)			{	our $hideClippedPolys = 1;			}
	elsif	($arg =~ /countClipPolys/i)				{	our $countClipPolys = 1;			}
	elsif	($arg =~ /debugCollision/i)				{	our $debugCollision = 1;			}
	elsif	($arg =~ /printSelPosRadius/i)			{	our $printSelPosRadius = 1;			}
	elsif	($arg =~ /exportCollisionByLayers/i)	{	our $exportCollisionByLayers = 1;	}
}

#DETERMINE WHICH SUBROUTINE TO RUN :
if 		($applyUniqueClip == 1)						{	&applyUniqueClip;					}
elsif	($hideClippedPolys == 1)					{	&hideClippedPolys;					}
elsif	($countClipPolys == 1)						{	&countClipPolys;					}
elsif	($debugCollision == 1)						{	&debugCollision;					}
elsif	($printSelPosRadius == 1)					{	&printSelPosRadius;					}
elsif	($printSelPosRadius == 1)					{	&printSelPosRadius;					}
elsif	($exportCollisionByLayers == 1)				{	&exportCollisionByLayers;			}
else												{	&applyUniqueMaterials;				}

#------------------------------------------------------------------------------------------------------------
#EXPORT COLLISION MODEL FROM LAYERS
#------------------------------------------------------------------------------------------------------------
sub exportCollisionByLayers{
	#lx("scene.save");
	my @fileSaveNames = fileDialog("save","Export LWO","*.lwo","lwo");
	my $layerCount = lxq("query layerservice layer.n ? all");
	my $currentRound = 0;

	#gather smoothing angles into table
	my %smAngleTable;
	my $txLayerCount = lxq("query sceneservice txLayer.n ? all");
	for (my $i=0; $i<$txLayerCount; $i++){
		my $type = lxq("query sceneservice txLayer.type ? $i");
		if (lxq("query sceneservice txLayer.type ? $i") eq "mask"){
			my $id = lxq("query sceneservice txLayer.id ? $i");
			my $ptag = 	lxq("item.channel ptag {?} set {$id}");
			my @children = lxq("query sceneservice item.children ? $id");

			foreach my $child (@children){
				if (lxq("query sceneservice txLayer.type ? $child") eq "advancedMaterial"){
					my $smAngle = lxq("item.channel smAngle {?} set {$child}");
					$smAngleTable{$ptag} = $smAngle;
					last;
				}
			}
		}
	}

	for (my $i=1; $i<$layerCount+1; $i++){
		my $layerName = lxq("query layerservice layer.name ? $i");
		my $layerID = lxq("query layerservice layer.id ? $i");
		lx("select.subItem {$layerID} set mesh;camera;light;backdrop;groupLocator;replicator;locator;deform;locdeform;chanModify;chanEffect 0 0");
		my %materialTable = ();
		my @changedPolys = ();
		$currentRound++;

		#skip if empty layer
		my $startingPolyCount = lxq("query layerservice poly.n ? all");
		if ($startingPolyCount == 0){
			$currentRound--;
			next;
		}

		#triple polys
		lx("select.drop polygon");
		lx("poly.triple");

		#query material names
		my $polyCount = lxq("query layerservice poly.n ? all");
		for (my $i=0; $i<$polyCount; $i++){
			my $material = lxq("query layerservice poly.material ? $i");
			if ($material =~ /collision$/i){
				$material = lc($material);
				$material =~ s/\\/\//g;
			}
			push(@{$materialTable{$material}},$i);
		}

		#debug/create collision
		#if collision polys already exist
		if (exists $materialTable{"textures\/common\/collision"}){
			my @touchingPolys = listTouchingPolys2(@{$materialTable{"textures\/common\/collision"}}[0]);
			my @collisionPolysThatArentTouching = removeListFromArray(\@{$materialTable{"textures\/common\/collision"}},\@touchingPolys);

			if ($layerName !~ /^base$/i){
				if (@collisionPolysThatArentTouching > 0){
					popup("layer ($layerName) has multiple collision poly meshes and so I'm cancelling the script!  Please fix!");
					die;
				}
			}

			my $collisionPlanes = countClipPlanesOnThisMesh(@touchingPolys);
			lxout("layer ($layerName) has ($collisionPlanes) collision planes");
			if ($layerName !~ /^base$/i){
				if ($collisionPlanes > 16){
					popup("layer ($layerName) has more than 16 collision planes!  Please fix!");
					die;
				}
			}
		}
		#if no collision polys exist
		else{
			lxout("This layer ($layerName) doesn't have any collision polys and so I'm attempting to use the other polys");
			my @touchingPolys;
			if ($layerName =~ /^base$/i){	@touchingPolys = lxq("query layerservice polys ? all");	}
			else						{	@touchingPolys = listTouchingPolys2(0);					}

			if (@touchingPolys == $polyCount){
				my $collisionPlanes = countClipPlanesOnThisMesh(@touchingPolys);
				lxout("layer ($layerName) has ($collisionPlanes) collision planes");
				if (($layerName !~ /^base$/i) && ($collisionPlanes > 16)){
					popup("layer ($layerName) has no collision so I attempted to use the polys that were already there, but there's more than 16 planes!  Please fix!");
					die;
				}else{
					lx("select.copy");
					lx("select.invert");
					lx("select.paste");
					lx("select.invert");
					lx("poly.setMaterial {textures/common/collision}");
					for (my $i=0; $i<@touchingPolys; $i++){
						my $polyIndice = @touchingPolys + $i;
						push(@{$materialTable{"textures/common/collision"}},$polyIndice);
					}
				}
			}else{
				popup("layer ($layerName) has more than one mesh in it and so I couldn't autocreate the collision");
				die;
			}
		}

		#apply new materials
		foreach my $key (keys %materialTable){
			if ($modoVer < 500){
				my @currentPolys = @{$materialTable{$key}};
				returnCorrectIndice(\@currentPolys,\@changedPolys);
				lx("select.drop polygon");
				lx("select.element {$i} polygon add {$_}") for @currentPolys;
			}else{
				lx("select.drop polygon");
				lx("select.element {$i} polygon add {$_}") for @{$materialTable{$key}};
			}

			my $material = $key . "&" . $currentRound;
			lx("poly.setMaterial {$material}");

			#set smoothing angle
			my $materialID = lxq("query sceneservice selection ? advancedMaterial");
			lx("item.channel smAngle {$smAngleTable{$key}} set {$materialID}");
		}
	}

	#export : copy polys
	for (my $i=1; $i<$layerCount+1; $i++){
		my $id = lxq("query layerservice layer.id ? $i");
		lx("select.subItem {$id} add mesh;triSurf;meshInst;camera;light;txtrLocator;backdrop;groupLocator;replicator;deform;locdeform;chanModify;chanEffect 0 0");
	}
	lx("select.drop polygon");
	lx("select.copy");

	#export : paste polys in new layer
	lx("layer.new");
	my $layerId = lxq("query layerservice layer.id ? main");
	lx("select.paste");

	#export : delete all layers except newest
	lx("select.drop item");
	for (my $i=1; $i<$layerCount+1; $i++){
		my $id = lxq("query layerservice layer.id ? $i");
		lx("select.subItem {$id} add mesh;triSurf;meshInst;camera;light;txtrLocator;backdrop;groupLocator;replicator;deform;locdeform;chanModify;chanEffect 0 0");
	}
	lx("item.delete mesh");

	#export save scene and crash script
	lx("scene.saveAs {@fileSaveNames[0]} {$lwoType} {false}");
	dieProper();
}

#------------------------------------------------------------------------------------------------------------
#PRINT COLLISION MODEL SELECTION / POSITION / RADIUS : vert mode = print vert pos in rage units.  edge mode = print selected coll models. poly mode = print the selection bbox radius and origin in rage units.
#------------------------------------------------------------------------------------------------------------
sub printSelPosRadius{
	if		( lxq( "select.typeFrom {vertex;edge;polygon;item} ?" ) ){
		lxout("[->] : You're in vert mode so I'm printing the last selected vertice's pos in rage units so it's easy for you to type in an explosion origin in the .break file");
		my @verts = lxq("query layerservice verts ? selected");
		my @pos = lxq("query layerservice vert.pos ? @verts[-1]");
		my @newVertPos = (@pos[0] , -1 * @pos[2] , @pos[1]);
		popup("position = @newVertPos");
	}elsif	( lxq( "select.typeFrom {polygon;item;vertex;edge} ?" ) ){
		lxout("[->] : You're in edge mode so I'm printing all the collision model numbers connected to the edges you have selected so it's easy for you to type in which collision models you want in which groups into the .break file");
		lx("select.convert vertex");
		my @verts = lxq("query layerservice verts ? selected");
		my @bbox = boundingbox(@verts);
		my @bboxCenter = ((@bbox[0]+@bbox[3])*.5 , (@bbox[1]+@bbox[4])*.5 , (@bbox[2]+@bbox[5])*.5);
		my @newVertPos = (int(@bboxCenter[0]) , int(-1 * @bboxCenter[2]) , int(@bboxCenter[1]));
		my $length = int((@bbox[3]-@bbox[0]) * .5);
		lx("select.type polygon");
		popup("position = @newVertPos\nradius = $length");
	}elsif	( lxq( "select.typeFrom {edge;polygon;item;vertex} ?" ) ){
		lxout("[->] : You're in poly mode so I'm printing out your poly selection's radius and origin in rage units so it's easy to type in a .break file's explosion's radius and origin.");
		my @edges = lxq("query layerservice edges ? selected");
		my %materialTable;
		foreach my $edge (@edges){
			my @polys = lxq("query layerservice edge.polyList ? $edge");
			foreach my $poly (@polys){
				my $material = lxq("query layerservice poly.material ? $poly");
				$material =~ s/.*&//;
				$materialTable{$material} = 1;
			}
		}

		my @keys = sort { $a <=> $b } (keys %materialTable);
		foreach my $key (@keys){lxout("collision number = $key");}
	}
}

#------------------------------------------------------------------------------------------------------------
#DEBUG COLLISION MODELS + CLIP MODELS : reports any missing indices.  reports indices without both col+noncol.  manually shows you the polys using each indice.
#------------------------------------------------------------------------------------------------------------
sub debugCollision{
	my %ptagTable;
	my $txLayerCount = lxq("query sceneservice txLayer.n ?");
	for (my $i=0; $i<$txLayerCount; $i++){
		if (lxq("query sceneservice txLayer.type ? $i") eq "mask"){
			my $ptag = lxq("query sceneservice channel.value ? ptag");
			if ($ptag !~ /&/){next;}
			my $number = $ptag;
			$number =~ s/.*&//;
			push(@{$ptagTable{$number}},$ptag);
		}
	}

	my @array = sort { $a <=> $b } keys %ptagTable;
	my $lastKey=0;
	foreach my $key (@array){
		lxout("key=$key");
		if ($lastKey != $key-1){die("There's a gap in the collision model indices. I'm at $key and the last key was $lastKey");}
		$lastKey = $key;


		my $collisonMaterial = "";
		my $nonCollisionMaterial = "";
		foreach my $ptag (@{$ptagTable{$key}}){
			lx("!!select.polygon add material face {$ptag}");
			$printName .= $ptag . "\n";
			if ($ptag =~ /collision/i){$collisonMaterial = $ptag;}
			elsif ($ptag !~ /collision/i){$nonCollisionMaterial = $ptag;}
		}
		#popup("collisonMaterial = $collisonMaterial\nnonCollisionMaterial = $nonCollisionMaterial");
		if (($collisonMaterial eq "") || ($nonCollisionMaterial eq "")){
			popup("wtf : apparently $key doesn't have both a collision material and a noncollision material");
		}
	}

	foreach my $key (@array){
		lx("unhide");
		lx("select.drop polygon");
		my $printName = "";

		my $collisonMaterial = "";
		my $nonCollisionMaterial = "";
		foreach my $ptag (@{$ptagTable{$key}}){
			lx("!!select.polygon add material face {$ptag}");
			$printName .= $ptag . "\n";
			if ($ptag =~ /collision/i){$collisonMaterial = $ptag;}
			elsif ($ptag !~ /collision/i){$nonCollisionMaterial = $ptag;}
		}
		if (($collisonMaterial eq "") || ($nonCollisionMaterial eq "")){
			die("Apparently $key doesn't have both a collision material and a noncollision material");
		}

		lx("hide.unsel");
		#lx("viewport.fitSelected");
		popup("key = $key \n$printName");
	}
}

#------------------------------------------------------------------------------------------------------------
#COUNT CLIP PLANES ON THIS MESH (poly list)
#------------------------------------------------------------------------------------------------------------
#USAGE : my $collisionPlanes = countClipPlanesOnThisMesh(@polyList);
sub countClipPlanesOnThisMesh{
	%alreadyChecked = ();
	%sameNormalTable = ();
	our %polyCheckList;
	$polyCheckList{$_} = 1 for @_;

	while ((keys %polyCheckList) > 0){
		my $poly = (keys %polyCheckList)[0];
		delete $polyCheckList{$poly};
		%alreadyChecked = ();  	$alreadyChecked{$poly} = 1;

		my @currentNormal = lxq("query layerservice poly.normal ? $poly");
		push(@{$sameNormalTable{$poly}},$poly);
		findTouchingPolysWithSameNormal($poly,\@currentNormal,$poly);
	}

	my $planeCount = (keys %sameNormalTable);
	return $planeCount;
}

#------------------------------------------------------------------------------------------------------------
#COUNT CLIP POLYS SUB
#------------------------------------------------------------------------------------------------------------
sub countClipPolys{
	lxout("[->] : COUNT COLLISION POLYS PER COLLISION MODEL SUB");
	if (lxq("query layerservice poly.n ? selected") > 0){lx("select.connect"); our @polys = lxq("query layerservice polys ? selected");}else{our @polys = lxq("query layerservice polys ? all");}
	my %collisionPolys;
	my %touchingPolyTable;
	my $totalPlaneCount;
	my %printList;

	#find collision polys
	foreach my $poly (@polys){
		if (lxq("query layerservice poly.material ? $poly") =~ /textures[\\\/]common[\\\/]collision/i){
			$collisionPolys{$poly} = 1;
		}
	}

	#build touchingPolyTable
	while ((keys %collisionPolys) > 0){
		my $poly = (keys %collisionPolys)[0];
		my @touchingPolys = listTouchingPolys2($poly);
		$touchingPolyTable{$poly} = \@touchingPolys;
		delete $collisionPolys{$_} for @touchingPolys;
	}

	#go through each poly group and make sure they're using the same material
	foreach my $key (keys %touchingPolyTable){
		my $chosenMaterial = lxq("query layerservice poly.material ? $key");
		foreach my $poly (@{$touchingPolyTable{$key}}){
			if (lxq("query layerservice poly.material ? $poly") ne $chosenMaterial){
				die("This poly ($poly) is not using the same material as the other polygons on it's collision model.");
			}
		}
	}
	lxout("\n\n\n");

	#go through each poly group and count it's unique poly normals
	foreach my $key (keys %touchingPolyTable){
		our %polyCheckList;
		$polyCheckList{$_} = 1 for @{$touchingPolyTable{$key}};
		%sameNormalTable = ();

		while ((keys %polyCheckList) > 0){
			my $poly = (keys %polyCheckList)[0];
			delete $polyCheckList{(keys %polyCheckList)[0]};
			%alreadyChecked = ();  	$alreadyChecked{$poly} = 1;

			my @currentNormal = lxq("query layerservice poly.normal ? $poly");
			findTouchingPolysWithSameNormal($poly,\@currentNormal,$poly);
		}

		#print the results
		#printHashTableArray(\%sameNormalTable,sameNormalTable);
		my %countList;
		$countList{$_} = 1 for @{$touchingPolyTable{$key}};
		foreach my $newKey (keys %sameNormalTable){
			foreach my $poly (@{$sameNormalTable{$newKey}}){
				delete $countList{$poly};
			}
		}

		my $count = (keys %countList);
		$totalPlaneCount += $count;
		my $firstPoly = (keys %countList)[0];

		if ($count > 16){popup("WARNING : --($count)-- planes in this collision mesh.\nFirst poly in this collision model=$firstPoly");}
		$printList{$firstPoly} = $count;
	}

	foreach my $key (sort {$printList{$b} <=> $printList{$a}} keys %printList){
		lxout("--($printList{$key})-- planes in this collision mesh with this poly : ($key)");
	}

	if ((keys %touchingPolyTable) > 1){
		my $totalCount = (keys %touchingPolyTable);
		lxout("    =======================================================================");
		lxout("      There are ($totalCount) collsion models in this selection.");
		lxout("      There are ($totalPlaneCount) planes total in this selection.");
		lxout("    =======================================================================");
	}
}

#------------------------------------------------------------------------------------------------------------
#FIND TOUCHING POLYS WITH SAME NORMAL SUB
#------------------------------------------------------------------------------------------------------------
#USAGE : findTouchingPolysWithSameNormal($poly,\@currentNormal,$tableKeyName);
#requires %sameNormalTable
#requires %polyCheckList
#requires %alreadyChecked
sub findTouchingPolysWithSameNormal{
	my %touchingPolys;
	my @matchingList = ();
	my @verts = lxq("query layerservice poly.vertList ? @_[0]");
	foreach my $vert (@verts){
		my @polys = lxq("query layerservice vert.polyList ? $vert");
		$touchingPolys{$_} = 1 for @polys;
	}

	foreach my $poly (keys %touchingPolys){
		delete $touchingPolys{$poly};

		if (($poly != @_[0]) && ($alreadyChecked{$poly} != 1)){
			$alreadyChecked{$poly} = 1;
			my @normal = lxq("query layerservice poly.normal ? $poly");
			my $dp = dotProduct(@_[1],\@normal);
			#lxout("    dp=$dp <> @_[0] <> $poly <> @{$_[1]} <> @normal"); #TEMP
			if ($dp > 0.9999){
				push(@{$sameNormalTable{@_[2]}},$poly);
				push(@matchingList,$poly);
				delete $polyCheckList{$poly};
			}
		}
	}

	my $originalPoly = @_[0];
	my @originalArray = @{$_[1]};
	foreach my $poly (@matchingList){
		findTouchingPolysWithSameNormal($poly,\@originalArray,$originalPoly);
	}
}


#------------------------------------------------------------------------------------------------------------
#HIDE CLIPPED POLY GROUPS SUB
#------------------------------------------------------------------------------------------------------------
sub hideClippedPolys{
	my @polys = lxq("query layerservice polys ? all");

	#build table for clipped polys
	my %polyTable;
	my %clipTable;
	foreach my $poly (@polys){
		my $material = lxq("query layerservice poly.material ? $poly");
		my @split = split(/&/, $material);
		if ($material =~ /textures[\\\/]common[\\\/]collision/i){
			$clipTable{@split[-1]} = $material;
		}else{
			push (@{$polyTable{@split[-1]}},$poly);
		}
	}

	lx("unhide");
	foreach my $key (keys %clipTable){
		if (($clipTable{$key} ne "") && (@{$polyTable{$key}}[0] ne "")){
			lx("select.drop polygon");
			lx("select.polygon add material face {$clipTable{$key}}");
			lx("select.element $mainlayer polygon add $_") for @{$polyTable{$key}};
			lx("hide.sel");
		}elsif (($clipTable{$key} ne "") && (@{$polyTable{$key}}[0] eq "")){
			popup("ERROR : This collision material exists, but there's no matching regular material : $clipTable{$key}");
		}
	}

	my $totalCount = (keys %clipTable);
	lxout("There are ($totalCount) collision poly sets");
}

#------------------------------------------------------------------------------------------------------------
#APPLY UNIQUE CLIP MATERIAL TO SELECTED POLYS SUB
#------------------------------------------------------------------------------------------------------------
sub applyUniqueClip{
	my @polys = lxq("query layerservice polys ? selected");
	my @nonClipList;
	my @polyReorder;

	foreach my $poly (@polys){
		my $material = lxq("query layerservice poly.material ? $poly");
		if (($material !~ /textures[\\\/]common[\\\/]collision/) && ($material ne "Default")){
			our $nonClipMaterial = $material;
			lx("select.element $mainlayer polygon remove $poly");
			push(@nonClipList,$poly);
		}else{
			our $findClipPolySuccess = 1;
			push(@polyReorder,$poly);
		}
	}

	if ($findClipPolySuccess == 0){
		die("You don't have any 'textures/common/collision' or 'Default' polys selected!\nYou must select some of those so I know what to assign the unique clip texture to.");
	}

	if ($nonClipMaterial ne ""){
		my @color = findMaterialColor($nonClipMaterial);

		if ($nonClipMaterial !~ /&/){
			die("This material ($nonClipMaterial) doesn't have a '&#' in it, so that means you're running the script on some polys that haven't been assigned a collision group yet!");
		}else{
			lxout("this nonClipMaterial has an & in it, so i'm going to increment : $nonClipMaterial");
			my @split = split(/&/, $nonClipMaterial);
			my $clipName = "textures/common/collision&".@split[-1];
			lx("poly.setMaterial {$clipName} {@color[0] @color[1] @color[2]} 0.8 0.2 true false");
			lx("item.channel advancedMaterial\$tranAmt 0.5");

			#hide the polys again. (temp!)
			foreach my $poly (@nonClipList){
				my $count = 0;
				foreach my $polyReorder (@polyReorder){
					if ($polyReorder < $poly){$count++;}
				}
				$poly -= $count;
				lx("select.element $mainlayer polygon add $poly");
			}
		}
	}else{
		die("You didn't have any polys selected without a clip material assigned.");
	}
}

#------------------------------------------------------------------------------------------------------------
#APPLY UNIQUE MATERIALS TO SELECTED POLYS SUB
#------------------------------------------------------------------------------------------------------------
sub applyUniqueMaterials{
	my $loop = 1;
	my $counter = 1;
	my %changedTable;
	my @clipList;

	lx("select.type polygon");
	lx("hide.unsel");

	while ($loop == 1){
		my %materials;
		my @reorderedPolys;
		my @polys = lxq("query layerservice polys ? visible");
		if (@polys == 0){last;}
		my $part = lxq("query layerservice poly.part ? @polys[-1]");
		my $material = lxq("query layerservice poly.material ? @polys[-1]");

		#ignore clip materials
		if ($material =~ /textures[\\\/]common[\\\/]collision/i){
			push(@clipList,$material);
			lx("select.element $mainlayer polygon set @polys[-1]");
			lx("select.connect");
			lx("poly.setPart $material");
			lx("hide.sel");
			next;
		}


		#select the rest of the polys
		if (($part ne "Default") && ($part ne "")){
			lx("select.polygon add part face {$part}");  #TEMP!  this needs to work with both multi material parts and uni material parts..
			lxout("[->] : Using this poly part to define a new material set : $part");
		}else{
			lx("select.element $mainlayer polygon set @polys[-1]");
			lx("select.connect");
		}

		#now sort the polys into the different materials and apply them
		my @currentPolys = lxq("query layerservice polys ? selected");
		my %materialTable=();

		foreach my $poly (@currentPolys){
			my $material = lxq("query layerservice poly.material ? $poly");
			push(@{$materialTable{$material}},$poly);
		}

		#printHashTableArray(\%materialTable,materialTable);

		foreach my $key (keys %materialTable){
			my @currentReorderedPolys;
			lx("select.drop polygon");
			foreach my $poly (@{$materialTable{$key}}){
				my $count=0;
				foreach my $reorderedPoly (@reorderedPolys){
					if ($reorderedPoly < $poly){
						$count++;
					}
				}
				my $newPoly = $poly - $count;
				lx("select.element $mainlayer polygon add $newPoly");
				push(@currentReorderedPolys,$poly);
			}


			my @split = split(/&/, $key);
			my $material = @split[0] . "&" . $counter;
			$material =~ s/\\/\//g;
			lx("poly.setMaterial {$material} {1.0 1.0 1.0} 0.8 0.2 true false");

			if ($key =~ /&/){$changedTable{@split[-1]} = $counter;}
			push(@reorderedPolys,@currentReorderedPolys);
		}


		#now hide the current polys and UP the timer
		for (my $i=0; $i<@currentPolys; $i++){
			my $poly = $totalPolyCount-1-$i;
			lx("select.element $mainlayer polygon add $poly");
		}
		lx("hide.sel");
		$counter++;
	}

	lx("unhide");

	#update the changed numbers for the clips
	foreach my $material (@clipList){
		lx("select.drop polygon");
		lx("select.polygon add part face {$material}");
		lx("poly.setPart Default");
		my @split = split(/&/, $material);
		my $materialName = "textures\/common\/collision&".$changedTable{@split[-1]};
		lx("poly.setMaterial {$materialName}");
	}
}


#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#SELECT MATERIAL SUB
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
sub selectMaterial{
	my $txLayerCount = lxq("query sceneservice txLayer.n ?");
	for (my $i=0; $i<$txLayerCount; $i++){
		if (lxq("query sceneservice txLayer.type ? $i") eq "mask"){
			my $id = lxq("query sceneservice txLayer.id ? $i");
			if (lxq("query sceneservice channel.value ? ptag") eq "@_[0]"){
				my @children = lxq("query sceneservice txLayer.children ? $i");
				foreach my $child (@children){
					my $name = lxq("query sceneservice txLayer.name ? $child");
					if (lxq("query sceneservice txLayer.type ?") eq "advancedMaterial"){
						lx("select.subItem {$child} set textureLayer;render;environment;mediaClip;locator");
						#popup("selecting this child : $child");
						last;
					}
				}
			}
		}
	}
}



#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#FIND MATERIAL COLOR SUB
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
sub findMaterialColor{
	my $txLayerCount = lxq("query sceneservice txLayer.n ?");
	for (my $i=0; $i<$txLayerCount; $i++){
		if (lxq("query sceneservice txLayer.type ? $i") eq "mask"){
			my $id = lxq("query sceneservice txLayer.id ? $i");
			if (lxq("query sceneservice channel.value ? ptag") eq "@_[0]"){
				my @children = lxq("query sceneservice txLayer.children ? $i");
				foreach my $child (@children){
					my $name = lxq("query sceneservice txLayer.name ? $child");
					if (lxq("query sceneservice txLayer.type ?") eq "advancedMaterial"){
						my $name = lxq("query sceneservice txLayer.name ? $child");
						my @color = (lxq("query sceneservice channel.value ? diffCol.R") , lxq("query sceneservice channel.value ? diffCol.G") , lxq("query sceneservice channel.value ? diffCol.B"));
						return(@color);
					}
				}
			}
		}
	}
}


#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#OPTIMIZED SELECT TOUCHING POLYGONS sub  (if only visible polys, you put a "hidden" check before vert.polyList point)
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE : my @connectedPolys = listTouchingPolys2(@polys[-$i]);
sub listTouchingPolys2{
	#lxout("[->] LIST TOUCHING subroutine");
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
#DOT PRODUCT subroutine (ver 1.1)
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE : my $dp = dotProduct(\@vector1,\@vector2);
sub dotProduct{
	return (	(${$_[0]}[0]*${$_[1]}[0])+(${$_[0]}[1]*${$_[1]}[1])+(${$_[0]}[2]*${$_[1]}[2])	);
}


#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#PRINT ALL THE ELEMENTS IN A HASH TABLE FULL OF ARRAYS
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#usage : printHashTableArray(\%table,table);
sub printHashTableArray{
	lxout("          ------------------------------------Printing @_[1] list------------------------------------");
	my $hash = @_[0];
	foreach my $key (sort keys %{$hash}){
		lxout("          KEY = $key");
		for (my $i=0; $i<@{$$hash{$key}}; $i++){
			lxout("             $i = @{$$hash{$key}}[$i]");
		}
	}
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

##------------------------------------------------------------------------------------------------------------
##------------------------------------------------------------------------------------------------------------
#FILE DIALOG WINDOW SUB
##------------------------------------------------------------------------------------------------------------
##------------------------------------------------------------------------------------------------------------
##USAGE : my @files = fileDialog("open"|"save","title","*.lxo;*.lwo;*.obj","lxo");
##0=open or save #1=title #2=loadExt #3=saveExt
sub fileDialog{
	if ($_[0] eq "open")	{	lx("dialog.setup fileOpenMulti");	}
	else					{	lx("dialog.setup fileSave");		}

	lx("dialog.title {$_[1]}");
	lx("dialog.fileTypeCustom format:[stp] username:[$_[1]] loadPattern:[$_[2]] saveExtension:[$_[3]]");
	lx("dialog.open");
	my @fileNames = lxq("dialog.result ?") or die("The file saver window was cancelled, so I'm cancelling the script.");
	return (@fileNames);
}

#-----------------------------------------------------------------------------------------------------------
#UNDO THE TRIPLING AND LAYER DELETION
#-----------------------------------------------------------------------------------------------------------
#system "start /min sndrec32 /play /close C:\\\\WINDOWS\\\\Media\\\\Windows Information Bar.wav";
sub dieProper{
	die("\n-\n-\n-\nTHIS SCRIPT IS NOT BROKEN!  THE ERROR MSG IS JUNK!\nTo stop this msg from coming up, click on the (In the future) button and choose (Hide Message)\n-\n-\n-\n");
}
