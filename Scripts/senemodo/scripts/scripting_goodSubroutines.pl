#perl

#if	( lxq( "select.typeFrom {vertex;edge;polygon;item} ?" ) )
#elsif( lxq( "select.typeFrom {edge;polygon;item;vertex} ?" ) )
#elsif( lxq( "select.typeFrom {polygon;item;vertex;edge} ?" ) )
#elsif(lxq("select.typeFrom {ptag;vertex;edge;polygon;item} ?"))
#elsif(lxq("select.typeFrom {item;vertex;edge;polygon;ptag} ?"))








#=====================================================================================================================================================================================================================
#=====================================================================================================================================================================================================================
#=====================================================================================================================================================================================================================
#=====================================================================================================================================================================================================================
#=====================================================================================================================================================================================================================
#=====================================================================================================================================================================================================================
#=====================================================================================================================================================================================================================
#=====================================================================================================================================================================================================================
#===														MODO SUBROUTINES										          ========================================================================================
#=====================================================================================================================================================================================================================
#=====================================================================================================================================================================================================================
#=====================================================================================================================================================================================================================
#=====================================================================================================================================================================================================================
#=====================================================================================================================================================================================================================
#=====================================================================================================================================================================================================================
#=====================================================================================================================================================================================================================
#=====================================================================================================================================================================================================================

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#QUERY WORKPLANE MATRIX (4x4) (will move verts at (2,2,2) in workplane space to (2,2,2) in world space)
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE : my @matrix_4x4 = queryWorkPlaneMatrix_4x4();			#queries current workplane
#USAGE2 : my @matrix_4x4 = queryWorkPlaneMatrix_4x4(@WPmem);	#can send it a stored workplane instead
#requires eulerTo3x3Matrix sub
#requires mtxMult sub
sub queryWorkPlaneMatrix_4x4{
	my @WPmem;
	if (@_ > 0){
		@WPmem = @_;
	}else{
		$WPmem[0] = lxq ("workPlane.edit cenX:? ");
		$WPmem[1] = lxq ("workPlane.edit cenY:? ");
		$WPmem[2] = lxq ("workPlane.edit cenZ:? ");
		$WPmem[3] = lxq ("workPlane.edit rotX:? ");
		$WPmem[4] = lxq ("workPlane.edit rotY:? ");
		$WPmem[5] = lxq ("workPlane.edit rotZ:? ");
	}

	my @m_wp = eulerTo3x3Matrix(-$WPmem[4],-$WPmem[3],-$WPmem[5]);

	my @matrix = (
		[1,0,0,0],
		[0,1,0,0],
		[0,0,1,0],
		[0,0,0,1]
	);

	my @matrix_mov = (
		[1,0,0,-$WPmem[0]],
		[0,1,0,-$WPmem[1]],
		[0,0,1,-$WPmem[2]],
		[0,0,0,1]
	);

	my @matrix_rot = (
		[$m_wp[0][0],$m_wp[0][1],$m_wp[0][2],0],
		[$m_wp[1][0],$m_wp[1][1],$m_wp[1][2],0],
		[$m_wp[2][0],$m_wp[2][1],$m_wp[2][2],0],
		[0,0,0,1]
	);

	@matrix = mtxMult(\@matrix_mov,\@matrix);
	@matrix = mtxMult(\@matrix_rot,\@matrix);
	return @matrix;
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#QUERY ITEM REFERENCE MODE MATRIX (4x4)
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE : my @itemRefMatrix = queryItemRefMatrix();
#if you multiply a vert by this matrix, you'll get the vert pos you see in screenspace
sub queryItemRefMatrix{
	my $itemRef = lxq("item.refSystem ?");
	if ($itemRef eq ""){
		my @matrix = (
			[1,0,0,0],
			[0,1,0,0],
			[0,0,1,0],
			[0,0,0,1]
		);
		return @matrix;
	}else{
		my @itemXfrmMatrix = getItemXfrmMatrix($itemRef);
		@itemXfrmMatrix = inverseMatrix(\@itemXfrmMatrix);

		return @itemXfrmMatrix;
	}
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#QUERY VIEWPORT MATRIX (3x3)
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE : my @3x3Matrix = queryViewportMatrix($heading,$pitch,$bank);
#requires eulerTo3x3Matrix sub
#requires transposeRotMatrix_3x3 sub
sub queryViewportMatrix{
	my $viewport = lxq("query view3dservice mouse.view ?");
	my @viewAngles = lxq("query view3dservice view.angles ? $viewport");

	if (($viewAngles[0] == 0) && ($viewAngles[1] == 0) && ($viewAngles[2] == 0)){
		lxout("[->] : queryViewportMatrix sub : must be in uv window because it returned 0,0,0 and so i'm defaulting the matrix");
		my @matrix = (
			[1,0,0],
			[0,1,0],
			[0,0,1]
		);
		return @matrix;
	}

	@viewAngles = (-$viewAngles[0],-$viewAngles[1],-$viewAngles[2]);
	my @matrix = eulerTo3x3Matrix(@viewAngles);
	@matrix = transposeRotMatrix_3x3(\@matrix);
	return @matrix;
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#APPLY SAME MATERIAL MULTIPLE TIMES WITH DIFFERENT SMOOTHING ANGLES (uses letter case variations to make the mask unique)
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#usage : applySameMaterialMultTimesWDiffSmAngles($materialName);
#requires shaderTreeTools sub
sub applySameMaterialMultTimesWDiffSmAngles{
	my %usedUpperCaseLetterPositions;
	my $materialNameToApply = $_[0];
	$materialNameToApply =~ s/\\/\//g;

	#build list of already existing materials
	my %preexistSmAngleTable;
	my $txLayerCount = lxq("query sceneservice txLayer.n ? all");
	for (my $i=0; $i<$txLayerCount; $i++){
		if (lxq("query sceneservice txLayer.type ? $i") eq "mask"){
			my $id = lxq("query sceneservice txLayer.id ? $i");
			my $ptag = lxq("item.channel ptag ? set {$id}");
			$ptag =~ s/\\/\//g;

			if (lc($ptag) eq lc($materialNameToApply)){
				if ($ptag =~ /([A-Z])/){}
				my $uc_letterPos = index($ptag,$1);
				if ($ptag !~ /([A-Z])/){
					$usedUpperCaseLetterPositions{-1} = 1;
				}else{
					$usedUpperCaseLetterPositions{$uc_letterPos} = 1;
				}

				my @children = lxq("query sceneservice txLayer.children ? $id");
				foreach my $child (@children){
					if (lxq("query sceneservice txLayer.type ? $child") eq "advancedMaterial"){
						my $smoothingAngle = int(lxq("item.channel smAngle ? set {$child}") + 0.5);
						$preexistSmAngleTable{$smoothingAngle} = $ptag;
						last;
					}
				}
			}
		}
	}

	#go through all polys in layer and build a list of the materials' sm angles
	my %smoothingAngles;
	shaderTreeTools(buildDbase);
	my $letterCount = 0;
	my $materialNameLength = length($materialNameToApply);
	my $materialCount = lxq("query layerservice material.n ? all");
	for (my $i=0; $i<$materialCount; $i++){
		my $materialName = lxq("query layerservice material.name ? $i");
		my $materialID = shaderTreeTools(ptag,materialID,$materialName);
		my $smoothingAngle = int(lxq("item.channel smAngle ? set {$materialID}") + 0.5);
		push(@{$smoothingAngles{$smoothingAngle}},$materialName);
	}

	#now apply the materials
	foreach my $smoothingAngle (keys %smoothingAngles){
		lx("select.drop polygon");
		lx("select.polygon add material face {$_}") for @{$smoothingAngles{$smoothingAngle}};
		if (exists $preexistSmAngleTable{$smoothingAngle}){
			lxout("applying this material (already exists) : $preexistSmAngleTable{$smoothingAngle} to these polys' materials : @{$smoothingAngles{$smoothingAngle}}");
			lx("poly.setMaterial {$preexistSmAngleTable{$smoothingAngle}}");
		}else{
			if ( ($letterCount == 0) && ((keys %usedUpperCaseLetterPositions) == 0) ){
				lxout("applying this material : $materialNameToApply to these polys' materials : @{$smoothingAngles{$smoothingAngle}}");
				lx("poly.setMaterial {$materialNameToApply}");
				my @materialSel = lxq("query sceneservice selection ? advancedMaterial");
				lx("item.channel smAngle {$smoothingAngle} set {$materialSel[0]}");

			}else{
				my $loop = 1;
				while ($loop == 1){
					if ($letterCount > $materialNameLength - 1){
						die("There aren't enough characters in this material name to support all the different smoothing angles needed.  You should reduce the number of smoothing angles used in this layer and try again.");
					}

					my $letterToCheck = substr($materialNameToApply,$letterCount,1);
					if ( (!exists $usedUpperCaseLetterPositions{$letterCount}) && ($letterToCheck =~ /[a-z]/) ){
						my $newMaterialName = $materialNameToApply;
						substr($newMaterialName,$letterCount,1) = uc(substr($newMaterialName,$letterCount,1));
						lxout("applying this material : $newMaterialName to these polys' materials : @{$smoothingAngles{$smoothingAngle}}");
						lx("poly.setMaterial {$newMaterialName}");
						my @materialSel = lxq("query sceneservice selection ? advancedMaterial");
						lx("item.channel smAngle {$smoothingAngle} set {$materialSel[0]}");
						$loop = 0;
					}

					$letterCount++;
				}
			}
		}
	}
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#FIND ADVANCED MATERIAL TO PARENT TO (not final, as it can't find select txLocators or layer masks)
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE : my $materialID = findAdvMatToParentTo();
#note : requires findChildrenByType sub
sub findAdvMatToParentTo{
	my $materialID;
	my @selection = lxq("query sceneservice selection ? textureLayer");
	foreach my $id (@selection){
		if (lxq("query sceneservice item.type ? $id") eq "advancedMaterial"){
			$materialID = $id;
			last;
		}elsif (lxq("query sceneservice item.type ? $id") eq "mask"){
			my @children = findChildrenByType($id,advancedMaterial);
			if (@children > 0){
				$materialID = $children[0];
				last;
			}
		}else{
			my $parentID = lxq("query sceneservice item.parent ? $id");
			my @children = findChildrenByType($parentID,advancedMaterial);
			if (@children > 0){
				$materialID = $children[0];
				last;
			}
		}
	}

	if ($materialID eq ""){
		lx("select.itemType defaultShader");
		$materialID = lxq("query sceneservice selection ? defaultShader");
	}

	return $materialID;
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#FIND CHILD BY TYPE
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE : findChildrenByType($parentID,$childType);
sub findChildrenByType{
	my @foundIDs;
	my @children = lxq("query sceneservice item.children ? {@_[0]}");
	foreach my $id (@children){
		if (lxq("query sceneservice item.type ? {$id}") eq @_[1]){
			push(@foundIDs,$id);
		}
	}
	if (@foundIDs == 0){
		lxout("This item ($_[0]) has no children of the type ($_[1])");
	}else{
		return(@foundIDs);
	}
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#FIND PARENT BY TYPE
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE : findParentByType($childID,$parentType);
sub findParentByType{
	my $id = @_[0];
	while (1){
		my $parent = lxq("query sceneservice item.parent ? {$id}");
		if ($parent eq ""){
			lxout("The findParentByType sub couldn't find a parent of the type ($_[1]) from item ($_[0]) because there isn't one");
		}elsif (lxq("query sceneservice item.type ? {$parent}") eq $_[1]){
			return $parent;
		}else{
			$id = $parent;
		}
	}
}




#=====================================================================================================================================================================================================================
#=====================================================================================================================================================================================================================
#=====================================================================================================================================================================================================================
#=====================================================================================================================================================================================================================
#=====================================================================================================================================================================================================================
#=====================================================================================================================================================================================================================
#=====================================================================================================================================================================================================================
#=====================================================================================================================================================================================================================
#===														GENERIC SUBROUTINES											          ====================================================================================
#=====================================================================================================================================================================================================================
#=====================================================================================================================================================================================================================
#=====================================================================================================================================================================================================================
#=====================================================================================================================================================================================================================
#=====================================================================================================================================================================================================================
#=====================================================================================================================================================================================================================
#=====================================================================================================================================================================================================================
#=====================================================================================================================================================================================================================

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#SIMPLE FIND/REPLACE SUB v1 (barebones find/replace sub.  replaces all found instances, not just first found)
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#usage1 : my $newText = "poo_shit"; $newText = findReplace($newText,"_shit,");  #replaces "_shit" for nothing so you get "poo"
#usage2 : my $newText = "poo";      $newText = findReplace($newText,"*,*_shit") #replaces "poo" for "poo_shit"
sub findReplace{
	my @findReplace = split(/,/, $_[1]);
	my $newText = $_[0];
	
	#if findReplace has a * in it, i'm going to just swap the star in the repl section for the input word
	if ($findReplace[1] =~ /\*/){
		$newText = $findReplace[1];
		$newText =~ s/\*/$_[0]/g;
	}
	#if no *, i'm just going to do a find/replace
	else{
		$newText =~ s/$findReplace[0]/$findReplace[1]/g;
	}
	return $newText;
}

##------------------------------------------------------------------------------------------------------------
##------------------------------------------------------------------------------------------------------------
##DOS PROGRESS BAR SETUP
##------------------------------------------------------------------------------------------------------------
##------------------------------------------------------------------------------------------------------------
#usage : progressBarSetup($printLabel,$numSteps,$listSize);
#usage : progressBarIncrement();
#requires progressBarIncrement
sub progressBarSetup{
	$|=1;
	our $progressBarUnitSize = $_[2] / (100/$_[1]);
	our $progressBarCounter = $_[1];
	our $progressBarProgress = 0;
	our $progressBarSteps = $_[1];
	print "$_[0] :\n...$progressBarProgress%";
}

##------------------------------------------------------------------------------------------------------------
##------------------------------------------------------------------------------------------------------------
##DOS PROGRESS BAR INCREMENT
##------------------------------------------------------------------------------------------------------------
##------------------------------------------------------------------------------------------------------------
#usage : progressBarSetup($printLabel,$numSteps,$listSize);
#usage : progressBarIncrement();
#requires progressBarSetup
sub progressBarIncrement{
	$progressBarCounter++;
	if ($progressBarCounter > $progressBarUnitSize){
		$progressBarCounter = 0;
		$progressBarProgress += $progressBarSteps;
		print "...$progressBarProgress%";
	}
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#REMOVE ITEMS OF CERTAIN TYPES FROM ARRAY
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#usage : remItemTypesFromArray(\@itemList,mesh,meshInst,etc);
sub remItemTypesFromArray{
	my @newArray;
	foreach my $id (@{$_[0]}){
		my $keep = 1;
		my $itemType = lxq("query sceneservice item.type ? {$id}");
		for (my $i=1; $i<@_; $i++){
			if ($itemType eq $_[$i]){
				$keep = 0;
				last;
			}
		}
		if ($keep == 1){
			push(@newArray,$id);
		}
	}
	@{$_[0]} = @newArray;
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#SORT ALPHANUMERIC sub : sorts with numbers, so you get 1,2,3,4,11,d1,d2,etc, not 1,11,etc
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE : @sorted = sort sortAlphaNumeric @not_sorted;
#REQUIRES GETNUMBERFROMSTRINGPOS sub
sub sortAlphaNumeric{
	my $lengthA = length($a);
	my $lengthB = length($b);
	my $shorter = 1;
	my $minLength = $lengthB;
	my $maxLength = $lengthA;  if ($lengthB > $lengthA){$maxLength = $lengthB; $minLength = $lengthA; $shorter = -1;}
	
	for (my $i=0; $i<$maxLength; $i++){
		if ($i >= $minLength)			{return $shorter;}
		
		my $charA = lc(substr($a,$i,1));
		my $charB = lc(substr($b,$i,1));
		if (($charA =~ /\d/) && ($charB =~ /\d/)){
			$charA = getNumberFromStringPos($a,$i);
			$charB = getNumberFromStringPos($b,$i);
			if		($charA > $charB)	{return  1;}
			elsif	($charA < $charB)	{return -1;}
		}
		elsif	($charA gt $charB)		{return  1;}
		elsif	($charA lt $charB)		{return -1;}
	}
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#GET NUMBER FROM STRING POS
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE : my $number = getNumberFromStringPos(poop387shit585,$charIndice);  #will return 387 if $charIndice=4
sub getNumberFromStringPos{
	my $number;
	my $strLength = length($_[0]);
	for (my $i=$_[1]; $i<$strLength; $i++){
		my $char = substr($_[0], $i, 1);
		if ($char =~ /\d/)	{	$number .= $char;	}
		else				{	return $number;		}
	}
	return $number;
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#SORT BY NUMBER hack sub. useful when you have filenames and you only want to sort the number part
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#usage : foreach my $file (sort sortByNumber keys %dirResult){}
sub sortByNumber {
  # Extract the digits following the first comma
  my ($number_a) = $a =~ /(\d+)/;
  my ($number_b) = $b =~ /(\d+)/;

  # Compare and return
  return $number_a <=> $number_b;
}

##------------------------------------------------------------------------------------------------------------
##------------------------------------------------------------------------------------------------------------
#SORT TEXT ARRAY THAT HAS NUMBERS IN TEXT (tye_from_perlmonks)
##------------------------------------------------------------------------------------------------------------
##------------------------------------------------------------------------------------------------------------
#usage : sortTextAndNumberArray(\@sortedArray,\@originalArray);
sub sortTextAndNumberArray{
	@{$_[0]} = @{$_[1]}[
		map { unpack "N", substr($_,-4) }
		sort
		map {
			my $key = ${$_[1]}[$_];
			$key =~ s[(\d+)][ pack "N", $1 ]ge;
			$key . pack "N", $_
		} 0..$#{$_[1]}
	];
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#GATHER EVERY X ELEMS FROM ARRAY
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#usage : my @newArray = gatherEveryXElemsFromArray(\@array,10);  #will return 10 evenly spaced elems from the array
sub gatherEveryXElemsFromArray{
	if (@{$_[0]} < $_[1]){
		return @{$_[0]};
	}else{
		my @newArray;
		for (my $i=0; $i<$_[1]; $i++){
			my $index = 0;
			if ($i > 0)	{	$index = int(@{$_[0]} * (1/$_[1])*$i + .5);	}
			my $arrayValue = @{$_[0]}[$index];
			push(@newArray,@{$_[0]}[$index]);
		}
		return @newArray;
	}
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
#POPUP RETURN ANSWER SUB
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE : my $answer = popupReturnAnswer("Do you want to do blah blah blah?");
sub popupReturnAnswer{
	lx("dialog.setup yesNo");
	lx("dialog.msg {@_}");
	lx("dialog.open");
	my $confirm = lxq("dialog.result ?");
	if($confirm eq "yes"){return 1;}else{return 0;}
}

##------------------------------------------------------------------------------------------------------------
##------------------------------------------------------------------------------------------------------------
#POPUP MULTIPLE CHOICE (ver 3) (forces return of your word choice because modo sometimes would return a number instead of word)
##------------------------------------------------------------------------------------------------------------
##------------------------------------------------------------------------------------------------------------
#USAGE : my $answer = popupMultChoice("question name","yes;no;maybe;blahblah",$defaultChoiceInt);
sub popupMultChoice{
	if (lxq("query scriptsysservice userValue.isdefined ? seneTempDialog2") == 1){lx("user.defDelete {seneTempDialog2}");	}
	lx("user.defNew name:[seneTempDialog2] type:[integer] life:[momentary]");
	lx("user.def seneTempDialog2 username [$_[0]]");
	lx("user.def seneTempDialog2 list {$_[1]}");
	lx("user.value seneTempDialog2 {$_[2]}");

	lx("user.value seneTempDialog2");
	if (lxres != 0){	die("The user hit the cancel button");	}
	
	my $answer = lxq("user.value seneTempDialog2 ?");
	if ($answer =~ /[^0-9]/){
		return($answer);
	}else{
		my @guiTextArray = split (/\;/, $_[1]);
		return($guiTextArray[$answer]);
	}
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
#EXTRACT TEXT LINE SUB #this should be rewritten to accept lines such as "234-589" (and maybe not need a forced order)
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#usage : my @lines = readFileLines($filePath,2,3,534);
sub readFileLines{
	open (FILE, "<$_[0]") or die("This file doesn't exist : $_[0]");
	my $line = 0;
	my @returnArray;
	my $argNumber = 1;
	while (<FILE>){
		$line++;
		if ($line == $_[$argNumber]){
			push(@returnArray,$_);
			if ($argNumber == $#ARGV+1){
				last;
			}else{
				$argNumber++;
			}
		}
	}
	close (FILE);
	return(@returnArray);
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#SET UP THE USER VALUE OR VALIDATE IT   (no popups)
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
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
#TRUE TIMER SUB
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE : my $time = trueTimer("moment");
#BEGIN{
	#my $scriptDir = "C:\/Documents and Settings\/seneca.EDEN.000\/Application Data\/Luxology\/Scripts";
	#my $perlDir = "C:\/Perl\/lib";
	#push(@INC,$scriptDir);
	#push(@INC,$perlDir);
#}
#use Time::HiRes qw( usleep gettimeofday tv_interval );
#$start = Time::HiRes::gettimeofday;
sub trueTimer
{
	my $end = Time::HiRes::gettimeofday;
	$time = $end-$start;
	lxout("             (@_ TIMER==>>$time)");
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#CLOCK SUB
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE :
#@clock = localtime();
#clock("name");
sub clock{
	my $name = @_;
	my @currentTime =	localtime();
	my $minutes = 		@currentTime[1] - @clock[1];
	my $seconds = 		@currentTime[0] - @clock[0];
	if (rindex($seconds,/[0-9]/) == 1)	{$seconds = "0" . $seconds;}
	lxout("$name timer = ($minutes:$seconds)");
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#TIMER SUB
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE :
#@start = times;
#timer("name");
sub timer
{
	@end = times;
	lxout("start=@start");
	lxout("end=@end");
	$time = @end[1]-@start[1];
	$time *= 2.5;
	lxout("             (@_ TIMER==>>$time)");
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#CREATE A PER LAYER ELEMENT SELECTION LIST ver 3.0! (retuns first and last elems, and ordered list for all layers)  (THIS VERSION DOES SUPPORT EDGES <and can refine the edge names>!)
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#usage : my @firstLastEdges = createPerLayerElemList(edge,\%edges,edgeSort<optional>);
#also, if you want the edges to be sorted, ie store 12,24 instead of 24,12, then put "edgeSort" as arg3
sub createPerLayerElemList{
	my $hash = @_[1];
	my @totalElements = lxq("query layerservice selection ? @_[0]");
	if (@totalElements == 0){die("\\\\n.\\\\n[---------------------------------------------You don't have any @_[0]s selected and so I'm cancelling the script.--------------------------------------------]\\\\n[--PLEASE TURN OFF THIS WARNING WINDOW by clicking on the (In the future) button and choose (Hide Message)--] \\\\n[-----------------------------------This window is not supposed to come up, but I can't control that.---------------------------]\\\\n.\\\\n");}

	#build the full list
	foreach my $elem (@totalElements){
		$elem =~ s/[\(\)]//g;
		my @split = split/,/,$elem;
		if (@_[0] eq "edge"){
			if (@_[2] eq "edgeSort"){
				if ($split[1] < $split[2]){
					push(@{$$hash{@split[0]}},@split[1].",".@split[2]);
				}else{
					push(@{$$hash{@split[0]}},@split[2].",".@split[1]);
				}
			}else{
				push(@{$$hash{@split[0]}},@split[1].",".@split[2]);
			}
		}else{
			push(@{$$hash{@split[0]}},@split[1]);
		}

	}

	#return the first and last elements
	return(@totalElements[0],@totalElements[-1]);
}


#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#VERIFY ITEM VISIBILITIES SUB (unhides all the item's collective parents)
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#usage : verifyItemVisibities(mesh001,mesh003);
sub verifyItemVisibities{
	my %verifiedAlreadyList;
	foreach my $id (@_){
		my $parent = lxq("query sceneservice item.parent ? {$id}");
		while ($parent ne ""){
			if ($verifiedAlreadyList{$parent} == 1){last;}
			$verifiedAlreadyList{$parent} = 1;
			lx("layer.setVisibility {$parent} 1");
			$parent = lxq("query sceneservice item.parent ? {$parent}");
		}
	}
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#MAINLAYER VISIBILITY ASSURANCE SUBROUTINE (toggles vis of mainlayer and/or parents if any are hidden)
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
# USAGE : (requires mainlayerID)
# WARNING : make sure mainlayer is actually selected!  I add this to the top of my scripts to assure that : if (lxq("query sceneservice item.isSelected ? $mainlayerID") == 0){lx("select.subItem {$mainlayerID} add mesh;triSurf;meshInst;camera;light;backdrop;groupLocator;replicator;locator;deform;locdeform;chanModify;chanEffect 0 0");}
# my @verifyMainlayerVisibilityList = verifyMainlayerVisibility();	#to collect hidden parents and show them
# verifyMainlayerVisibility(\@verifyMainlayerVisibilityList);		#to hide the hidden parents (and mainlayer) again.
sub verifyMainlayerVisibility{
	my @hiddenParents;

	#hide the items again.
	if (@_ > 0){
		foreach my $id (@{@_[0]}){
			lxout("[->] : hiding $id");
			lx("layer.setVisibility {$id} 0");
		}
	}

	#show the mainlayer and all the mainlayer parents that are hidden (and retain a list for later use)
	else{
		if( lxq( "select.typeFrom {vertex;edge;polygon;item} ?" ) ){	our $tempSelMode = "vertex";	}
		if( lxq( "select.typeFrom {edge;polygon;item;vertex} ?" ) ){	our $tempSelMode = "edge";		}
		if( lxq( "select.typeFrom {polygon;item;vertex;edge} ?" ) ){	our $tempSelMode = "polygon";	}
		if( lxq( "select.typeFrom {item;vertex;edge;polygon} ?" ) ){	our $tempSelMode = "item";		}
		lx("select.type item");
		if (lxq("layer.setVisibility $mainlayerID ?") == 0){
			lxout("[->] : showing $mainlayerID");
			lx("layer.setVisibility $mainlayerID 1");
			push(@hiddenParents,$mainlayerID);
		}
		lx("select.type $tempSelMode");

		my $parentFind = 1;
		my $currentID = $mainlayerID;
		while ($parentFind == 1){
			my $parent = lxq("query sceneservice item.parent ? {$currentID}");
			if ($parent ne ""){
				$currentID = $parent;

				if (lxq("layer.setVisibility {$parent} ?") == 0){
					lxout("[->] : showing $parent");
					lx("layer.setVisibility {$parent} 1");
					push(@hiddenParents,$parent);
				}
			}else{
				$parentFind = 0;
			}
		}

		return(@hiddenParents);
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


#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#ROUND A NUMBER TO A GRID SIZE IF WITHIN ACCEPTABLE RANGE
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#my $number = roundNumberIfInRange(24.99,.25,.0101);  #arg1=number.  #arg2=gridSize.  #arg3=acceptableRange
#.0101 was used in the example above to let the script get around floating point inaccuracies
sub roundNumberIfInRange{
	my $flip = 0;
	my $number = $_[0];
	my $roundTo = $_[1];
	if ($roundTo < 0)	{	$roundTo *= -1;				}
	if ($number < 0)	{	$number *= -1;	$flip = 1;	}

	#get rounded result
	my $result = int(($number /$roundTo)+.5) * $roundTo;
	
	#see if within range
	if ($flip == 1){	$result *= -1;	}
	my $diff = $result - $_[0];
	
	#return result
	if (abs($diff) < $_[2])	{	return $result;	}
	else					{	return $_[0];	}
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#THIS WILL ROUND THE CURRENT NUMBER to the amount you define. (VER 2.1)
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE : my $rounded = roundNumber(-1.45,1);
sub roundNumber(){
	my $flip = 0;
	my $number = $_[0];
	my $roundTo = $_[1];
	if ($roundTo < 0)	{	$roundTo *= -1;				}
	if ($number < 0)	{	$number *= -1;	$flip = 1;	}

	#my $result = int(($number * $gridMult /$roundTo)+.5) * $roundTo * $gridDiv;
	my $result = int(($number /$roundTo)+.5) * $roundTo;
	if ($flip == 1)	{	return -$result;	}
	else			{	return $result;		}
}


#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#THIS WILL ROUND THE CURRENT INTEGER to the string length you define (will fill in empty space with 0s)
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE : my $roundedIntegerString = roundIntString(1,3,0|space);  #outputs "001";
#note : arg "0|space" is so you can pad the number with either zeroes or spaces.
sub roundIntString{
	my $padChar = "0";
	if ($_[2] eq "space"){$padChar = " ";}
	my $roundedNumber = int($_[0] + .5);
	$_ = $roundedNumber;
	my $count = s/.//g;

	if  ($count < @_[1]){
		$roundedNumber  = $padChar x ((@_[1]) - $count) . $roundedNumber;
	}
	return($roundedNumber);
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#THIS WILL ROUND THE CURRENT NUMBER to the string length you define (and fill in empty space with 0s as well)
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE : my $roundedNumberString = roundNumberString(0.2565486158,5);
sub roundNumberString{
	$_ = "@_[0]";
	my $count = s/.//g;
	my $roundedNumber = "@_[0]";
	if ($count > @_[1])		{$roundedNumber = substr($roundedNumber, 0, @_[1]);}
	elsif ($count < @_[1])	{
		if ($roundedNumber =~ /\./)	{$roundedNumber .= 0 x (@_[1] - $count);	}
		else						{{$roundedNumber .= "." . 0 x ((@_[1] - 1) - $count);	}	}
	}
	return($roundedNumber);
}


#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#ITEM VISIBILITY QUERY
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE : if (visibleQuery(mesh024) == 1){}
sub visibleQuery{
	my $name = lxq("query sceneservice item.name ? @_[0]");
	my $channelCount = lxq("query sceneservice channel.n ?");
	for (my $i=0; $i<$channelCount; $i++){
		if (lxq("query sceneservice channel.name ? $i") eq "visible"){
			if (lxq("query sceneservice channel.value ? $i") ne "off"){
				return 1;
			}else{
				return 0;
			}
		}
	}
}


#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#LOAD AN IMAGE (clip)
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
sub loadClip{
	lx("dialog.setup fileOpenMulti");
	lx("dialog.fileType image");
	lx("dialog.open");
	my @files = lxq("dialog.result ?");
}


#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#READS TGA AND WRITES TO TEMP BINARY TABLE
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#usage : readTGA($filePath);
sub readTGA{
	open (TGA, "<@_[0]") or die("I can't open this TGA : @_[0]");
	binmode(TGA); #explicitly tells it to be a BINARY file

	#read the TGA header info
	my $buffer;
	my $identSize =			readChar(TGA,1,C);
	my $palette = 			readChar(TGA,1,C);
	my $imageType = 		readChar(TGA,1,C);
	my $colorMapStart = 	readChar(TGA,2,S);
	my $colorMapLength = 	readChar(TGA,2,S);
	my $colorMapBits =		readChar(TGA,1,C);
	my $xStart =			readChar(TGA,2,S);
	my $yStart =			readChar(TGA,2,S);
	my $width =				readChar(TGA,2,S);
	my $height =			readChar(TGA,2,S);
	my $bits =				readChar(TGA,1,C);
	my $descriptor = 		readChar(TGA,1,C);
	my %pixels;
	if ($bits == 24)		{our $readLength=3;}else{our $readLength=4;}
	@currentSize = 			($width,$height);
	$bitMode = 				$bits;

	#read the TGA color info
	for (my $v=$height-1; $v>-1; $v--){ #had to flip the order because the god damn colors are supposed to be in V reverse.
		for (my $u=0; $u<$width; $u++){
			read(TGA, $buffer, $readLength);
			$rawPixels{$u.",".$v} = $buffer;
			#print("pixel($u,$v) = $buffer\n");
		}
	}

	#print the TGA color info
	#print("identSize = $identSize\n");
	#print("palette = $palette\n");
	#print("imageType = $imageType\n");
	#print("colorMapStart = $colorMapStart\n");
	#print("colorMapLength = $colorMapLength\n");
	#print("colorMapBits = $colorMapBits\n");
	#print("xStart = $xStart\n");
	#print("yStart = $yStart\n");
	#print("width = $width\n");
	#print("height = $height\n");
	#print("bits = $bits\n");
	#print("descriptor = $descriptor\n");
	#foreach my $key (keys %pixels){print("key ($key) = @{$pixels{$key}}\n");}

	close(TGA);
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#SHRINK CURRENT TGA
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#usage : shrinkTGA($currentOffsetPosU,$currentOffsetPosV);
sub shrinkTGA{
	my $newUPercentMult = 1/$iconSize;
	my $newVPercentMult = 1/$iconSize;

	for (my $v=$iconSize-1; $v>-1; $v--){  #had to flip the order because the god damn colors are supposed to be in V reverse.
		for (my $u=0; $u<$iconSize; $u++){
			my $pixel = int(($u*$newUPercentMult) * @currentSize[0]+.5) .",". int(($v*$newVPercentMult) * @currentSize[1]+.5);
			my $offsetU = @_[0]+$u;
			my $offsetV = @_[1]+$v;
			my $offsetTotal = $offsetU.",".$offsetV;
			$shrunkPixels{$offsetTotal} = $rawPixels{$pixel};
			#print("pixel($offsetTotal)=$rawPixels{$pixel}        ");
		}
	}
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#QUERY TGA SIZE SUB
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#usage : queryTGASize($filePath);
#requires readChar sub
sub queryTGASize{
	open (TGA, "<@_[0]") or return(0,0);
	binmode(TGA); #explicitly tells it to be a BINARY file

	#read the TGA header info
	my $buffer;
	my $identSize =			readChar(TGA,1,C);
	my $palette = 			readChar(TGA,1,C);
	my $imageType = 		readChar(TGA,1,C);
	my $colorMapStart = 	readChar(TGA,2,S);
	my $colorMapLength = 	readChar(TGA,2,S);
	my $colorMapBits =		readChar(TGA,1,C);
	my $xStart =			readChar(TGA,2,S);
	my $yStart =			readChar(TGA,2,S);
	my $width =				readChar(TGA,2,S);
	my $height =			readChar(TGA,2,S);
	my $bits =				readChar(TGA,1,C);
	my $descriptor = 		readChar(TGA,1,C);
	my %pixels;
	if ($bits == 24)		{our $readLength=3;}else{our $readLength=4;}
	@currentSize = 			($width,$height);
	$bitMode = 				$bits;
	close(TGA);

	return($width,$height);
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#CREATE A NEW TGA TO THE HARD DRIVE
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE : newTGA("C://testImage.tga",512,256,24);
sub newTGA{
	#$buf = pack("C", 255);				#for packing 0-255
	#$buf = pack("A*", "Hello World!");	#for packing strings
	#$buf = pack("S", 666);				#for packing unsigned shorts (higher than 255, but not by that much i guess)
	if (@_[3] == ""){die("You can't run the newTGA sub without arguments!");}

	my $file = @_[0];
	my @size = (@_[1],@_[2]);
	my $bitMode = @_[3];

	lxout("[->] Creating a new TGA here : $file");
	open (TGA, ">$file") or die("I can't open the TGA");
	binmode(TGA); #explicitly tells it to be a RAW file

	my $identSize = 		pack("C", 0);
	my $palette = 			pack("C", 0);
	my $imageType = 		pack("C", 2);
	my $colorMapStart = 	pack("S", 0);
	my $colorMapLength = 	pack("S", 0);
	my $colorMapBits =		pack("C", 0);
	my $xStart =			pack("S", 0);
	my $yStart =			pack("S", 0);
	my $width =				pack("S", @size[0]);
	my $height =			pack("S", @size[1]);
	my $bits =				pack("C", $bitMode);
	my $descriptor =		pack("C", 0);
	if ($bitMode == 32){
		our $black =		pack("C4",1,0,0,0);  #note, C4=CCCC. C*=Cinfinite.  also, the read order is backwards, so alpha comes first. lastly, ("CCC",0,0,0) = ("C",0) run three times
	}else{
		our $black =		pack("CCC",0,0,0);
	}


	print TGA $identSize;
	print TGA $palette;
	print TGA $imageType;
	print TGA $colorMapStart;
	print TGA $colorMapLength;
	print TGA $colorMapBits;
	print TGA $xStart;
	print TGA $yStart;
	print TGA $width;
	print TGA $height;
	print TGA $bits;
	print TGA $descriptor;

	for (my $i=0; $i<(@size[0]*@size[1]); $i++){
		print TGA $black;
	}

	close(TGA);
}


#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#READ BINARY CHARS FROM FILE (there's no offsetting. it's for reading entire file one step at a time)
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#usage : readChar(FILEHANDLE,$howManyBytes,$packCharType);
sub readChar{
	read(@_[0], $buffer, @_[1]);
	return unpack(@_[2],$buffer);
}


#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#ADD THE INSTANCES TO THE BGLAYERS LIST SO THAT YOU CAN UNHIDE THEM WHEN THE SCRIPT'S DONE (ver 1.1)
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE : addInstancesToBGList(\@bgLayers);
sub addInstancesToBGList{
	my $items = lxq("query sceneservice item.n ? all");
	for (my $i=0; $i<$items; $i++){
		if (lxq("query sceneservice item.type ? $i") eq "meshInst"){
			my $id = lxq("query sceneservice item.id ? $i");
			my $visible = lxq("layer.setVisibility {$id} ?");
			if ($visible == 1){push (@{$_[0]},$id);}
		}
	}
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#FIND MESH INSTANCE SOURCE (ver 1.2) (now supports proxies)
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#usage : my $sourceMeshID = findMeshInstSource($item) or die("$item is not a meshInst");
sub findMeshInstSource{
	if ( (lxq("query sceneservice item.type ? {$_[0]}") ne "meshInst") && (lxq("query sceneservice item.type ? {$_[0]}") ne "proxy") ){return 0;}
	my $currentItem = $_[0];

	while (1){
		my $source = 			lxq("query sceneservice item.source ? {$currentItem}");
		if ($source eq "")	{	return $currentItem;													}
		else				{	$currentItem = lxq("query sceneservice item.source ? {$currentItem}");	}
	}
}
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#BUILD THE EXCLUSION LIST FOR DIR ROUTINE
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
my %exclusionList;
sub buildExclusionList{
	open (exclusionFile, "<@_[0]") or die("I couldn't find the exclusion file");
	while ($line = <exclusionFile>){
		$line =~ s/\n//;
		$exclusionList{$line} = 1;
	}
	close(exclusionFile);
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#DIR : MAKE SURE EXISTS sub (send file or dir path and it'll create the dirs if needed)
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#usage : dir_makeSureExists([$fileName|$dir]);
sub dir_makeSureExists{
	$_[0] =~ s/\\/\//g;

	#check for errors
	$_[0] =~ s/\s+/\s/g;
	$_[0] =~ s/\t//g;
	$_[0] =~ s/\n//g;
	if ($_[0] =~ /[(){}]/){
		print("The dir ($_[0]) has some illegal chars in it, so it can't be legit.");
		die;
	}elsif ($_[0] !~ /[a-z]:/i){
		print("The dir doesn't have a drive name specified, so it can't be legit.");
		die;
	}

	my @names = split(/\//,$_[0]);
	if (@names[-1] =~ /\./){pop(@names);}
	if (@names[-1] !~ /[a-zA-Z0-9]/){pop(@names);}
	my $currentDir = shift(@names);
	for (my $i=0; $i<@names; $i++){
		$currentDir .= "\/" . $names[$i];
		if (!-e $currentDir){
			#lxout("dir doesn't exist so I'm creating it : $currentDir");
			mkdir ($currentDir, 0777);
		}
	}
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#DIR SUB (ver 1.2 special char bugfix)
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#requirements 1 : needs buildExclusionList sub if you want to use an external exclusion file.  Also, declare %exclusionList as global
#requirements 2 : needs matchPattern sub
#requirements 3 : Declare %dirResult as global so this routine can be used multiple times and add to that hash table.
#USAGE : dir($checkDir,\@ignoreDirs,\@matchFilePatterns,\@ignoreFilePatterns);
my %dirResult;
sub dir{
	#get the name of the current dir.
	my $currentDir = @_[0];
	my @tempCurrentDirName = split(/\//, $currentDir);
	my $tempCurrentDirName = @tempCurrentDirName[-1];
	my @directories;

	#open the current dir and sort out it's files and folders.
	opendir($currentDir,$currentDir) || die("Cannot opendir $currentDir");
	my @files = (sort readdir($currentDir));

	#--------------------------------------------------------------------------------------------
	#SORT THE NAMES TO BE DIRS OR MODELS
	#--------------------------------------------------------------------------------------------
	foreach my $name (@files){
		#IGNORE . and .. (and i can't del the first two arr chars because '(' comes before .)
		if ($name =~ /^\.+$/){next;}

		#LOOK FOR DIRS
		if (-d $currentDir . "\/" . $name){
			if (matchPattern($name,@_[1],-1)){	push (@directories,$currentDir . "\/" . $name);		}
		}

		#LOOK FOR FILES
		elsif ((matchPattern($name,@_[2])) && ($exclusionList{$currentDir . "\/" . $name} != 1) && (matchPattern($name,@_[3],-1))){
			$dirResult{$currentDir . "\/" . $name} = 1;
		}
	}

	#--------------------------------------------------------------------------------------------
	#RUN THE SUBROUTINE ON EACH DIR FOUND.
	#--------------------------------------------------------------------------------------------
	foreach my $dir (@directories){
		&dir($dir,@_[1],@_[2],@_[3]);
	}
}


#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#SEE IF ARG0 MATCHES ANY PATTERN IN ARG1ARRAYREF
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE : if (matchPattern(name,\@checkArray,-1)){lxout("yes");}
sub matchPattern{
	if (@_[2] != -1){
		foreach my $name (@{@_[1]}){
			if (@_[0] =~ /$name/i){return 1;}
		}
		return 0;
	}else{
		foreach my $name (@{@_[1]}){
			if (@_[0] =~ /$name/i){return 0;}
		}
		return 1;
	}
}


#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#READ OR WRITE SHADER (NEW|OVERWRITE) SUB. (writes out name{data} with tabs)
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#usage : writeNewOrReplaceShader($shaderName,\@shaderText,$textFilePath,read|write);
sub writeNewOrReplaceShader{
	my $shaderName =			@_[0];
	my $shaderTextArrayRef =	@_[1];
	my $textFilePath =			@_[2];
	my $readOrWrite =			@_[3];
	$shaderName =~ s/\\/\//g;
	my $bracketCount = 0;
	my $foundShaderCheck = 0;
	my $currentLine = 0;
	my @shaderLines;
	my @shaderLineNumbers;
	my $lineBump = 1;

	#================================
	#START : the shader text
	#================================
	open (FILE, "<$textFilePath") or popup("This file doesn't exist : $textFilePath");
	while (<FILE>){
		$_ =~ s/\/\/.*//g; #nuke commented text
		my $openingBracketCount = $_ =~ tr/{/{/;
		my $closingBracketCount = $_ =~ tr/}/}/;

		#find the shader start
		if ($bracketCount == 0){
			$_ =~ s/^[\s\t]*//; #nuke beginning spaces
			$_ =~ s/[\t\s]*$//; #nuke trailing spaces
			$_ =~ s/[\{\}]//g;  #nuke brackets
			if (lc($_) eq lc($shaderName)){
				$foundShaderCheck = 1;
				lxout("[->] found ($shaderName) on line # $currentLine");
			}
		}
		$bracketCount += $openingBracketCount;
		$bracketCount -= $closingBracketCount;

		#if shader is found, copy text
		if ($foundShaderCheck == 1){
			if ($bracketCount == 0){
				if ($_ =~ /[a-zA-Z0-9_]/){
					$lineBump = 0;
					$_ =~ s/[\{\}]*//g;
					push(@shaderLines,$_);
					push(@shaderLineNumbers,$currentLine);
				}
				last;
			}else{
				push(@shaderLines,$_);
				push(@shaderLineNumbers,$currentLine);
			}
		}
		$currentLine++;
	}
	close(FILE);

	#================================
	#FINISH : READ : return results
	#================================
	if ($readOrWrite eq "read"){
		if ($foundShaderCheck == 1){
			return (\@shaderLines);
		}else{
			lxout("couldn't find shader : $shaderName ");
			return 0;
		}
	}

	#================================
	#FINISH : WRITE : write out results
	#================================
	elsif ($readOrWrite eq "write"){
		my @newShaderText;

		#write to bottom of file because shader didn't exist
		if ($foundShaderCheck  == 0){
			lxout("[->] : printing new shader");
			open (FILE, ">>$textFilePath") or popup("This file doesn't exist : $textFilePath");
			print FILE "\n" . $shaderName . "{\n";
			print FILE "\t" . $_ . "\n" for @{$shaderTextArrayRef};
			print FILE "}\n";
			close (FILE);
		}

		#overwrite already existing shader.
		else{
			popup("Are you sure you wish to overwrite this shader ?\n$shaderName");
			lxout("[->] : overwriting preexisting shader");
			my @shaderFileText;

			open (FILE, "<$textFilePath") or popup("This file doesn't exist : $textFilePath");
			while (<FILE>){push(@shaderFileText,$_);}
			close (FILE);

			#remove from array
			splice(@shaderFileText, $shaderLineNumbers[0],($shaderLineNumbers[-1] - $shaderLineNumbers[0]) + 1 + $lineBump);
			if (( @shaderFileText[@shaderLineNumbers[0]] !~ /[a-zA-Z0-9_]/ ) && ( @shaderFileText[@shaderLineNumbers[0]-1] !~ /[a-zA-Z0-9_]/ )){
				splice(@shaderFileText, $shaderLineNumbers[0], 1);
			}

			#create new shader text array
			push(@newShaderText,$shaderName . "{\n");
			foreach my $line (@{$shaderTextArrayRef}){
				$line = "\t" . $line . "\n";
				push(@newShaderText,$line);
			}
			push(@newShaderText,"}\n");

			#add to array
			splice(@shaderFileText, $shaderLineNumbers[0],0, @newShaderText);

			#write to file
			open (FILE, ">$textFilePath") or popup("This file doesn't exist : $textFilePath");
			foreach my $line (@shaderFileText){
				print FILE $line;
			}
			close (FILE);
		}
	}
}


#=====================================================================================================================================================================================================================
#=====================================================================================================================================================================================================================
#=====================================================================================================================================================================================================================
#=====================================================================================================================================================================================================================
#=====================================================================================================================================================================================================================
#=====================================================================================================================================================================================================================
#=====================================================================================================================================================================================================================
#=====================================================================================================================================================================================================================
#===													GEOMETRY SUBROUTINES													  ====
#=====================================================================================================================================================================================================================
#=====================================================================================================================================================================================================================
#=====================================================================================================================================================================================================================
#=====================================================================================================================================================================================================================
#=====================================================================================================================================================================================================================
#=====================================================================================================================================================================================================================
#=====================================================================================================================================================================================================================
#=====================================================================================================================================================================================================================


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
	if (abs($dp) > 0.9999){	$foundColinearEdge = 1;	}
	if ((abs($vector0[0]) == 0) && (abs($vector0[1]) == 0) && (abs($vector0[2]) == 0)){die("getThreeNonColinearVertsFromNgon : This poly {$_[0]} has 2 verts lying on top of each other so I'm cancelling script");}
	if ((abs($vector1[0]) == 0) && (abs($vector1[1]) == 0) && (abs($vector1[2]) == 0)){die("getThreeNonColinearVertsFromNgon : This poly {$_[0]} has 2 verts lying on top of each other so I'm cancelling script");}
	
	#return first 3 verts if not colinear
	if ($foundColinearEdge == 0){	return ($vertList[0],$vertList[1],$vertList[2]);	}

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
sub getPolyNormalFromTri{
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
#2D POLY CENTROID (from graphics gems IV)
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE : my $errorCode = polyCentroid(\@x,\@y,$#vertList+1,\$cenX,\$cenY,\$area);
#note : this sub expects the lists of vert positions to be a loop. ie : pos[0] = pos[-1]
#arg0 = array of x positions
#arg1 = array of y positions
#arg2 = number of verts in array
#arg3 = centerX return value
#arg4 = centerY return value
#arg5 = area return value
#error codes : 0=successful 1=failed because poly had less than 3 verts 2=poly is infinitely small
sub 2dPolyCentroid{
	my ($x, $y, $n) = @_;
	my $i = 0;
	my $j = 0;
	my $ai = 0;
	my $atmp = 0;
	my $xtmp = 0;
	my $ytmp = 0;

	if ($n < 3){ return 1; }
	for ($i = $n-1, $j = 0; $j < $n; $i = $j, $j++){
		$ai = $x[$i] * $y[$j] - $x[$j] * $y[$i];
		$atmp += $ai;
		$xtmp += ($x[$j] + $x[$i]) * $ai;
		$ytmp += ($y[$j] + $y[$i]) * $ai;
	}
	$area = $atmp / 2;
	if ($atmp != 0){
		$cenX =	$xtmp / (3 * $atmp);
		$cenY =	$ytmp / (3 * $atmp);
		return 0;
	}
	return 2;
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#FIND DIST TO SPECIFIC VERT ALONG VERT CHAIN
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE : my $dist = findDistToVertInVertChain(\@vertChain,$vertWantToFind);
sub findDistToVertInVertChain{
	my $dist;
	my $foundVert;

	if (@{$_[0]}[0] == $_[1]){
		return 0;
	}

	for (my $i=1; $i<$#{$_[0]}; $i++){
		@pos1 = lxq("query layerservice vert.pos ? @{$_[0]}[$i-1]");
		@pos2 = lxq("query layerservice vert.pos ? @{$_[0]}[$i]");
		my @disp = ( @pos2[0] - @pos1[0] , @pos2[1] - @pos1[1], @pos2[2] - @pos1[2] );
		$dist += sqrt(($disp[0]*$disp[0])+($disp[1]*$disp[1])+($disp[2]*$disp[2]));
		if (@{$_[0]}[$i] == $_[1]){
			$foundVert = 1;
			last;
		}
	}

	if ($foundVert == 0){die("findDistToVertInVertChain sub : couldn't find vert $_[1] in @{$_[0]} so cancelling script");}
	return ($dist);
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#FIND POSITION ON POINT CHAIN (also reverses the array order if the mesh is closer to the end than the start)
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE : my @results = findPosOnPtChain(\@verts,$posX,$posY,$posZ);
#@results = vert1,vert2,intersectDistAlongVector  (and reverses \@verts array if pos is closer to end than start)
sub findPosOnPtChain{
	my $smallestFakeDist = 1000000000000000000000000000;
	my $nearestVertArrayIndice;
	my @objectPos = ($_[1],$_[2],$_[3]);
	my @endResultData;
	my $whichEdgeVert;

	lxout("vertrow start = @{$_[0]}");

	#find nearest vert on chain
	for (my $i=0; $i<@{$_[0]}; $i++){
		my @vertPos = lxq("query layerservice vert.pos ? @{$_[0]}[$i]");
		my @disp = arrMath(@vertPos,$_[1],$_[2],$_[3],subt);
		my $fakeDist = abs($disp[0]) + abs($disp[1]) + abs($disp[2]);
		if ($fakeDist < $smallestFakeDist){
			$smallestFakeDist = $fakeDist;
			$nearestVertArrayIndice = $i;
		}
	}

	#find which touching edge it should be on. (and reverse array if needed)
	if		($nearestVertArrayIndice == 0){
		lxout("[->] : nearest edge is FIRST");
		my $distAlongVector = dotProduct_fromTwoVertsAndOnePos(@{$_[0]}[0],@{$_[0]}[1],\@objectPos,dpDist);
		@endResultData = (@{$_[0]}[0],@{$_[0]}[1],$distAlongVector);
	}elsif	($nearestVertArrayIndice == $#{$_[0]}){
		lxout("[->] : nearest edge is LAST");
		my $distAlongVector = dotProduct_fromTwoVertsAndOnePos(@{$_[0]}[-1],@{$_[0]}[-2],\@objectPos,dpDist);
		@endResultData = (@{$_[0]}[-1],@{$_[0]}[-2],$distAlongVector);
		@{$_[0]} = reverse(@{$_[0]});
	}else{
		lxout("[->] : nearest edge is in MIDDLE");
		my $distAlongVector1 = dotProduct_fromTwoVertsAndOnePos(@{$_[0]}[$nearestVertArrayIndice],@{$_[0]}[$nearestVertArrayIndice+1],\@objectPos,"dpDist");
		my $distAlongVector2 = dotProduct_fromTwoVertsAndOnePos(@{$_[0]}[$nearestVertArrayIndice],@{$_[0]}[$nearestVertArrayIndice-1],\@objectPos,"dpDist");
		my $distAlongVector;
		my $vert1;
		my $vert2;

		if (($distAlongVector1 == 0) && ($distAlongVector1 == 0))	{$distAlongVector1 =.000000000000001;} #get rid of tie.

		my $posOnIndicePtChain = $nearestVertArrayIndice;
		if		($distAlongVector1 < 0)					{	$posOnIndicePtChain -= .25;		$distAlongVector = $distAlongVector2;	}
		elsif	($distAlongVector2 < 0)					{	$posOnIndicePtChain += .25;		$distAlongVector = $distAlongVector1;	}
		elsif	($distAlongVector1 > $distAlongVector2)	{	$posOnIndicePtChain += .25;		$distAlongVector = $distAlongVector1;	}
		else											{	$posOnIndicePtChain -= .25;		$distAlongVector = $distAlongVector2;	}

		if ($posOnIndicePtChain < ($#{$_[0]} * .5)){
			lxout("first half");
			if (@{$_[0]}[$nearestVertArrayIndice] == @{$_[0]}[int($posOnIndicePtChain+1)]){
				my $edge = "(".@{$_[0]}[int($posOnIndicePtChain)].",".@{$_[0]}[int($posOnIndicePtChain + 1)].")";
				my $edgeLength = lxq("query layerservice edge.length ? $edge");
				$distAlongVector = $edgeLength - $distAlongVector;
			}

			@endResultData = (@{$_[0]}[int($posOnIndicePtChain)],@{$_[0]}[int($posOnIndicePtChain + 1)],$distAlongVector);
		}else{
			lxout("second half");
			if (@{$_[0]}[$nearestVertArrayIndice] == @{$_[0]}[int($posOnIndicePtChain)]){
				my $edge = "(".@{$_[0]}[int($posOnIndicePtChain+1)].",".@{$_[0]}[int($posOnIndicePtChain)].")";
				my $edgeLength = lxq("query layerservice edge.length ? $edge");
				$distAlongVector = $edgeLength - $distAlongVector;
			}
			@endResultData = (@{$_[0]}[int($posOnIndicePtChain+1)],@{$_[0]}[int($posOnIndicePtChain)],$distAlongVector);
			@{$_[0]} = reverse(@{$_[0]});
		}
	}

	lxout("vertrow end = @{$_[0]}");
	lxout("endResultData = @endResultData");
	return(@endResultData);
}


#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#BUILD ELEMENT SELECTION TABLE (return a table of each layer's selection)
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE : my ($elems,$mode) = buildElemSelTable();  foreach my $elem (keys %{$elems}){do something};
#NOTE : returns a element mode string ("vert"|"edge"|"poly") and hash table pointer for all the selection
#NOTE : when querying edges, it by default returns a string list like this (23,68).
#ARG1 : "edgeArrays" : use this arg to get an edge list that returns vert array refs, instead of the normal strings with () characters.
#ARG2 : "vert" | "edge" | "poly" : use any of these args to force a specific selection mode because it normally uses whatever mode you're currently in.
sub buildElemSelTable{
	our %elems;
	my $selMode;

	if		(lxq( "select.typeFrom {vertex;edge;polygon;item} ?" ))	{	$selMode = "vert";	}
	elsif	(lxq( "select.typeFrom {edge;polygon;item;vertex} ?" ))	{	$selMode = "edge";	}
	elsif	(lxq( "select.typeFrom {polygon;item;vertex;edge} ?" ))	{	$selMode = "poly";	}
	else{	die("You're not in vertex, edge, or polygon selection mode so I'm cancelling the script");	}
	
	#args
	foreach my $arg (@_){
		if 		($arg eq "vert")		{	$selMode = "vert";	}
		elsif	($arg eq "edge")		{	$selMode = "edge";	}
	 	elsif	($arg eq "poly")		{	$selMode = "poly";	}
		elsif	($arg eq "edgeArrays")	{	our $edgeMode = 1;	}
	}
	
	#build table
	my @elems = lxq("query layerservice selection ? $selMode");
	if ($selMode eq "edge"){
		if ($edgeMode == 1){
			foreach my $elem (@elems){
				my @data = split (/[^0-9]/, $elem);
				my @array = ($data[2],$data[3]);
				push(@{$elems{$data[1]}},\@array);
			}
		}else{
			foreach my $elem (@elems){
				my @data = split (/[^0-9]/, $elem);
				push(@{$elems{$data[1]}},"(".$data[2].",".$data[3].")");
			}
		}
	}else{
		foreach my $elem (@elems){
			my @data = split (/[^0-9]/, $elem);
			push(@{$elems{$data[1]}},$data[2]);
		}
	}
	
	return (\%elems,$selMode);
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#SELECTION FIND SUBROUTINE (return a table of each layer's selection)
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#usage : my %table;  selectionFind(\%table,poly);
sub selectionFind{
	my $hash = @_[0];
	my @selection = lxq("query layerservice selection ? @_[1]");
	for (my $i=0; $i<@selection; $i++){
		my @array = split (/[^0-9]/, @selection[$i]);
		if (@_[1] ne "edge"){
			push(@{$$hash{@array[1]}},@array[2]);
		}else{
			push(@{$$hash{@array[1]}},"(".@array[2].",".@array[3].")");
		}
	}
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

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#SELECT VMAP NEW
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#usage : 		selectVmapNew(0|1,zeroVmapsSelected);
#requirements : (@vmaps = array of uv only vmaps)
#returns : 		(vmap indice of chosen vmap)
#notes :		(0|1 = whether or not to create new or select unused vmap if no used ones found) (zeroVmapsSelected = loop uses this automatically)
sub selectVmapNew{
	my @selectedVmaps;

	#[------------------------------------]
	#[----------no vmaps selected---------]
	#[------------------------------------]
	if (@_[1] eq "zeroVmapsSelected"){
		my $vmapAmount = 0;
		my $winner = -1;

		#desel all vmaps
		foreach my $vmap (@vmaps){
			if (lxq("query layerservice vmap.selected ? $vmap") == 1){
				my $name = lxq("query layerservice vmap.name $vmap");
				lx("select.vertexMap {$name} txuv remove");
			}
		}
		#go thru all vmaps and find the winner
		foreach my $vmap (@vmaps){
			my $name = lxq("query layerservice vmap.name ? $vmap");
			my $amount = lxq("query layerservice uv.N ? visible");
			if ($amount >= $vmapAmount){
				$vmapAmount = $amount;
				$winner = $vmap;
			}
		}
		#if a winner was found, select it and return.
		if ($winner != -1){
			my $name = lxq("query layerservice vmap.name ? $winner");
			lx("select.vertexMap {$name} txuv replace");
			lxout("[->] SELECTVMAP SUB : No vmaps were selected, so I selected the one with the most polys being used : ($name)");
			return $winner;
		}
		#if no winner was found, that means we need to create a new vmap or cancel script depending on case.
		else{
			#don't create new vmap
			if (@_[0] == 0){
				die("I'm cancelling the script because the current layer doesn't have any usable uvs.");
			}
			#select or create new vmap
			else{
				foreach my $vmap (@vmaps){
					if (lxq("query layerservice vmap.name ? $vmap") eq "Texture"){
						lxout("I'm selecting the (Texture) vmap because no vmaps were selected or being used and it's the default");
						lx("select.vertexMap Texture txuv replace");
						return $vmap;
					}
				}
				lx("vertMap.new Texture txuv false {0.78 0.78 0.78} 1.0");
				lxout("[->] SELECTVMAP SUB : No vmaps were selected or being used, so I created (Texture)");
				my @currentVmaps = lx("query layerservice vmaps ? texture");
				return @currentVmaps[-1];
			}
		}
	}

	#[------------------------------------]
	#[---------some vmaps selected--------]
	#[------------------------------------]
	else{
		foreach my $vmap (@vmaps){	if (lxq("query layerservice vmap.selected ? $vmap") == 1){push(@selectedVmaps,$vmap);}}

		#[									  ]
		#[-------multiple vmaps selected------]
		#[									  ]
		if (@selectedVmaps > 1){
			my $vmapAmount = 0;
			my $winner = -1;

			#go thru all vmaps and find the winner
			foreach my $vmap (@selectedVmaps){
				my $vmapName = lxq("query layerservice vmap.name ? $vmap");
				my $amount = lxq("query layerservice uv.N ? visible");
				if ($amount >= $vmapAmount){
					$winner = $vmap;
					$vmapAmount = $amount;
				}
			}
			#if a winner was found, deselect all the losers
			if ($winner != -1){
				my $name = lxq("query layerservice vmap.name ? $winner");
				lx("select.vertexMap {$name} txuv replace");
				lxout("[->] SELECTVMAP SUB : There were multiple vmaps selected, so I deselected all but ($name) because it had the most uvs");
				return $winner;
			}
			#if a winner was NOT found, deselect all vmaps and run this sub again.
			else{
				lxout("[->] SELECTVMAP SUB : looping sub because more than one vmap (@selectedVmaps) was selected, but they're not being used");
				selectVmapNew(@_[0],zeroVmapsSelected);
			}
		}

		#[									  ]
		#[----------one vmap selected---------]
		#[									  ]
		elsif (@selectedVmaps == 1){
			my $name = lxq("query layerservice vmap.name ? @selectedVmaps[0]");
			if (lxq("query layerservice uv.N ? visible") > 0){
				lxout("[->] SELECTVMAP SUB : ($name) vmap already selected");
				return @selectedVmaps[0];
			}else{
				lxout("[->] SELECTVMAP SUB : looping sub because one vmap ($name) was selected, but it's not being used by this layer");
				selectVmapNew(@_[0],zeroVmapsSelected);
			}
		}

		#[									  ]
		#[-----------no vmap selected---------]
		#[									  ]
		else{
			selectVmapNew(@_[0],zeroVmapsSelected);
		}
	}
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#QUERY IF ANY UV MAP IS SELECTED sub
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#return 1 if a uvmap is selected, 0 if there isn't.
sub queryIfAnyUvmapIsSelected{
	my $vmapCount = lxq("query layerservice vmap.n ? all");
	for (my $i=0; $i<$vmapCount; $i++){
		if ((lxq("query layerservice vmap.type ? $i") eq "texture") && (lxq("query layerservice vmap.selected ? $i") == 1)){
			return 1;
		}
	}
	return 0;
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#PRINT ALL THE ELEMENTS IN A HASH TABLE FULL OF ARRAYS
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
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

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#GET OR SET THE PIVOT POINT FOR AN OBJECT (ver 1.2)
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE : m3PivPos(set,lxq("query layerservice layer.id ? $mainlayer"),34,22.5,37);
#USAGE : my @pos = m3PivPos(get,lxq("query layerservice layer.id ? $mainlayer"));
sub m3PivPos{
	#find out if pivot "translation" exists and if not, create it.
	if (@_[0] eq "set"){lx("select.subItem {@_[1]} set mesh;meshInst;camera;light;backdrop;groupLocator;locator;deform;locdeform 0 0");}
	my $pivotID = lxq("query sceneservice item.xfrmPiv ? @_[1]");
	if ($pivotID eq ""){
		lx("transform.add type:piv");
		$pivotID = lxq("query sceneservice item.xfrmPiv ? @_[1]");
	}
	#get the pivot point
	if (@_[0] eq "get"){
		lxout("[->] Getting pivot position");
		my $xPos = lxq("item.channel pos.X {?} set {$pivotID}");
		my $yPos = lxq("item.channel pos.Y {?} set {$pivotID}");
		my $zPos = lxq("item.channel pos.Z {?} set {$pivotID}");
		return($xPos,$yPos,$zPos);
	}
	#set the pivot point
	elsif (@_[0] eq "set"){
		lxout("[->] Setting pivot position");
		lx("item.channel pos.X {@_[2]} set {$pivotID}");
		lx("item.channel pos.Y {@_[3]} set {$pivotID}");
		lx("item.channel pos.Z {@_[4]} set {$pivotID}");
	}else{
		popup("[m3PivPos sub] : You didn't tell me whether to GET or SET the pivot point!");
	}
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#CREATE TEXTLOCATORs MATRIX (works on 3x3 and 4x4)
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE(3x3) : createDebugMatrix(\@matrix_3x3,$scaleAmt,\@center);
#USAGE(4x4) : createDebugMatrix(\@matrix_4x4,$scaleAmt);
#requires arrMath and createTextLoc subs
sub createTextLocMatrix{
	my @center;
	my @xPos;
	my @yPos;
	my @zPos;

	if ($#_ == 2)	{	@center = @{$_[2]};											}
	else			{	@center = (${$_[0]}[0][3],${$_[0]}[1][3],${$_[0]}[2][3]);	}

	@xPos = arrMath(	arrMath(	${$_[0]}[0][0],${$_[0]}[0][1],${$_[0]}[0][2],		$_[1],$_[1],$_[1],mult),		@center,add);
	@yPos = arrMath(	arrMath(	${$_[0]}[1][0],${$_[0]}[1][1],${$_[0]}[1][2],		$_[1],$_[1],$_[1],mult),		@center,add);
	@zPos = arrMath(	arrMath(	${$_[0]}[2][0],${$_[0]}[2][1],${$_[0]}[2][2],		$_[1],$_[1],$_[1],mult),		@center,add);

	createTextLoc($center[0],$center[1],$center[2],"O",.01);
	createTextLoc($xPos[0],$xPos[1],$xPos[2],"X",.01);
	createTextLoc($yPos[0],$yPos[1],$yPos[2],"Y",.01);
	createTextLoc($zPos[0],$zPos[1],$zPos[2],"Z",.01);
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#CREATE AXIS WEDGE FROM MATRIX (works on 3x3 and 4x4)
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE : createAxisWedge(\@matrix);
sub createAxisWedge{
	my $matrix = $_[0];
	my @offset = (0,0,0);
	if (@$matrix == 4){	@offset = ($$matrix[0][3] , $$matrix[1][3] , $$matrix[2][3]);	}
	my @pos1 = ($$matrix[0][0]+$offset[0] , $$matrix[0][1]+$offset[1] , $$matrix[0][2]+$offset[2]);
	my @pos2 = ($$matrix[1][0]+$offset[0] , $$matrix[1][1]+$offset[1] , $$matrix[1][2]+$offset[2]);
	my @pos3 = ($$matrix[2][0]+$offset[0] , $$matrix[2][1]+$offset[1] , $$matrix[2][2]+$offset[2]);

	lx("!!vert.new $offset[0] $offset[1] $offset[2]");
	lx("!!vert.new $pos1[0] $pos1[1] $pos1[2]");
	lx("!!vert.new $pos2[0] $pos2[1] $pos2[2]");
	lx("!!vert.new $pos3[0] $pos3[1] $pos3[2]");

	my $vertCount = lxq("query layerservice vert.n ? all");
	my $vert1 = $vertCount - 4;
	my $vert2 = $vertCount - 3;
	my $vert3 = $vertCount - 2;
	my $vert4 = $vertCount - 1;

	lx("select.type vertex");
	lx("select.element $mainlayer vertex set $vert1");
	lx("select.element $mainlayer vertex add $vert2");
	lx("select.element $mainlayer vertex add $vert3");
	lx("poly.makeFace");
	lx("select.element $mainlayer vertex set $vert1");
	lx("select.element $mainlayer vertex add $vert3");
	lx("select.element $mainlayer vertex add $vert4");
	lx("poly.makeFace");
	lx("select.element $mainlayer vertex set $vert1");
	lx("select.element $mainlayer vertex add $vert4");
	lx("select.element $mainlayer vertex add $vert2");
	lx("poly.makeFace");
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#CREATE TEXT LOCATOR ITEM (v2)
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE : createTextLoc($x,$y,$z,$text,$locSize);
sub createTextLoc{
	lx("item.create locator");
	my @locatorSelection = lxq("query sceneservice selection ? locator");
	lx("transform.channel pos.X {$_[0]}");
	lx("transform.channel pos.Y {$_[1]}");
	lx("transform.channel pos.Z {$_[2]}");

	lx("!!item.name item:{$locatorSelection[-1]} name:{$_[3]}");
	lx("!!item.help add label {$_[3]}");
	lx("!!item.channel size {$_[4]} set {$locatorSelection[-1]}");
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#CREATE A SPHERE AT THE SPECIFIED PLACE/SCALE
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
sub createSphere{
	if (@_[3] eq undef){@_[3] = 5;}
	lx("tool.set prim.sphere on");
	lx("tool.reset");
	lx("tool.setAttr prim.sphere cenX {@_[0]}");
	lx("tool.setAttr prim.sphere cenY {@_[1]}");
	lx("tool.setAttr prim.sphere cenZ {@_[2]}");
	lx("tool.setAttr prim.sphere sizeX {@_[3]}");
	lx("tool.setAttr prim.sphere sizeY {@_[3]}");
	lx("tool.setAttr prim.sphere sizeZ {@_[3]}");
	lx("tool.doApply");
	lx("tool.set prim.sphere off");
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#CREATE A CUBE AT THE SPECIFIED PLACE/SCALE
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
sub createCube{
	if (@_[3] eq undef){@_[3] = 5;}
	lx("tool.set prim.cube on");
	lx("tool.reset");
	lx("tool.setAttr prim.cube cenX {@_[0]}");
	lx("tool.setAttr prim.cube cenY {@_[1]}");
	lx("tool.setAttr prim.cube cenZ {@_[2]}");
	lx("tool.setAttr prim.cube sizeX {@_[3]}");
	lx("tool.setAttr prim.cube sizeY {@_[3]}");
	lx("tool.setAttr prim.cube sizeZ {@_[3]}");
	lx("tool.doApply");
	lx("tool.set prim.cube off");
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#CREATE A POLY FROM THE POS ARRAY REFS YOU SEND
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#usage : createPoly(\@pos1,\@pos2,\@pos3);
sub createPoly{
	my $vertCount = lxq("query layerservice vert.n ? all");
	foreach my $pos (@_)							{	lx("!!vert.new ${$pos}[0] ${$pos}[1] ${$pos}[2]");		}
	lx("select.drop vertex");
	for (my $i=$vertCount; $i<$vertCount+@_; $i++)	{	lx("!!select.element {$mainlayer} vertex add {$i}");	}
	lx("!!poly.make auto false");
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#SORT THE ELEMENTS INTO SYMMETRICAL HALVES (requires $symmAxis)
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
sub sortSymm{
	my $selType = shift(@_);
	my @positive;
	my @negative;

	foreach my $elem (@_){
		my @pos = lxq("query layerservice $selType.pos ? $elem");
		if (@pos[$symmAxis] > 0 )	{  push(@positive,$elem);	}
		else						{  push(@negative,$elem);	}

	}
	return(\@positive,\@negative);
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#INTERSECT RAY AND PLANE MATH subroutine
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE : @intersectPoint = intersectRayPlaneMath(\@mousePos1,\@mousePos2,\@viewAxis,\@planePos);  #mousePos2 = @mousePos1+@viewAxis to create a "ray"
#requires arrMath and dotProduct subroutines.
sub intersectRayPlaneMath{
	my @pos1 = @{$_[0]};
	my @pos2 = @{$_[1]};
	my @normal = @{$_[2]};
	my @polyPos = @{$_[3]};
	my @disp = arrMath(@pos2,@pos1,subt);
	my $planeDist = -1 * dotProduct(\@normal,\@polyPos);
	my $test1 = -1 * (dotProduct(\@pos1,\@normal)+$planeDist);
	my $test2 = dotProduct(\@disp,\@normal);
	my $time = $test1/$test2;
	#my $time;
	#if ( ($test1 != 0) && ($test2 != 0) ){
	#	$time = $test1/$test2;
	#}else{
	#	return("fail");
	#}
	my @intersectPoint = arrMath(@pos1,arrMath(@disp,$time,$time,$time,mult),add);
	return(@intersectPoint);
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#INTERSECT RAY AND PLANE subroutine  (not good for tons of edits because it queries the normal every time)
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE : my @newVertPos = intersectRayPlane($vert1,$vert2,$poly);
#USAGE : my @newVertPos = intersectRayPlane($vert1,$vert1,$poly,x);  #arg4 is to overwrite vert 2 for axis
#requires arrMath and dotProduct subroutines.
sub intersectRayPlane{
	my $vert1 =	@_[0];
	my $vert2 =	@_[1];
	my $poly =	@_[2];
	my @pos1 = lxq("query layerservice vert.pos ? $vert1");
	my @pos2;
	if (@_[3] =~ /[a-z]/i){
		if		(@_[3] =~ /x/i)	{ @pos2 = (0,@pos1[1],@pos1[2]); }
		elsif	(@_[3] =~ /y/i)	{ @pos2 = (@pos1[0],0,@pos1[2]); }
		else					{ @pos2 = (@pos1[0],@pos1[1],0); }
	}else{
		@pos2 = lxq("query layerservice vert.pos ? $vert2");
	}
	my @normal = lxq("query layerservice poly.normal ? $poly");
	my @polyPos = lxq("query layerservice poly.pos ? $poly");
	my @disp = arrMath(@pos2,@pos1,subt);
	my $planeDist = -1 * dotProduct(\@normal,\@polyPos);
	my $test1 = -1 * (dotProduct(\@pos1,\@normal)+$planeDist);
	my $test2 = dotProduct(\@disp,\@normal);
	my $time;
	if ( ($test1 != 0) && ($test2 != 0) ){
		$time = $test1/$test2;
	}else{
		return("fail");
	}
	my @intersectPoint = arrMath(@pos1,arrMath(@disp,$time,$time,$time,mult),add);
	return(@intersectPoint);
}


#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#GET THE EDGE NORMAL
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE : my @normal = edgeNormal(@edge);
sub edgeNormal{
	my @polys = lxq("query layerservice edge.polyList ? @_");
	my @normal;

	if (@polys == 1){
		@normal = lxq("query layerservice poly.normal ? @polys[0]");
	}
	else{
		@normal1 = lxq("query layerservice poly.normal ? @polys[0]");
		@normal2 = lxq("query layerservice poly.normal ? @polys[1]");
		@normal = ((@normal1[0]+@normal2[0])*0.5,(@normal1[1]+@normal2[1])*0.5,(@normal1[2]+@normal2[2])*0.5);
	}
	return(@normal);
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
#SELECT TOUCHING POLYGONS (ONLY PRE-APPROVED) sub
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE : my @connectedPolys = listTouchingPolys_onlyApproved($poly);
#requires %approvedPolys table; #ie : $approvedPolys{$poly} = 1;
sub listTouchingPolys_onlyApproved{
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
			if ($approvedPolys{$poly} == 1){
				$totalPolyList{$poly} = 1;
			}
		}
	}

	return (keys %totalPolyList);
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
#OPTIMIZED SELECT TOUCHING POLYGONS THAT IGNORES HIDDEN POLYS sub
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE : my @connectedPolys = listTouchingVisiblePolys(@polys[-$i]);
sub listTouchingVisiblePolys{
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
		foreach my $poly (@polys){
			if (lxq("query layerservice poly.hidden ? $poly") == 0){
				$totalPolyList{$poly} = 1;
			}
		}
	}

	return (keys %totalPolyList);
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
#LIST TOUCHING POLYS AND VERTS
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE : my @polysAndVertTableRef = listTouchingPolysAndVerts($poly);
sub listTouchingPolysAndVerts{
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

	return (\%totalPolyList,\%vertList);
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#RETURN BORDER EDGES FROM POLY LIST
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE : my @borderEdges = returnBorderEdges(\@polys);
sub returnBorderEdges{
	my %edgeList;
	foreach my $poly (@{$_[0]}){
		my @verts = lxq("query layerservice poly.vertList ? $poly");
		for (my $i=-1; $i<$#verts; $i++){
			my $edge;
			if (@verts[$i]<@verts[$i+1])	{	$edge = @verts[$i].",".@verts[$i+1];	}
			else							{	$edge = @verts[$i+1].",".@verts[$i];	}
			$edgeList{$edge} += 1;
		}
	}

	foreach my $key (keys %edgeList)	{	if ($edgeList{$key} != 1)	{	delete $edgeList{$key};	}	}
	return (keys %edgeList);
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#THIS WILL LIST ALL THE BORDER EDGES ON THE SELECTED POLYS
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE :
#&listBorderEdges;
#foreach my $edge (keys %edgeList){
#	lxout("This edge($edge) is used this many times ($edgeList{$edge})");
#}
sub listBorderEdges{
	my @polys = @_;
	our %edgeList;

	foreach my $poly (@polys){
		my @verts = lxq("query layerservice poly.vertList ? $poly");
		for (my $i=-1; $i<$#verts; $i++){
			my $edge;
			if (@verts[$i]<@verts[$i+1])	{	$edge = @verts[$i].",".@verts[$i+1];	}
			else							{	$edge = @verts[$i+1].",".@verts[$i];	}
			lxout("edge=$edge");
			$edgeList{$edge} = $edgeList{$edge}+1;
		}
	}
}


#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#REMOVE VERTS THAT HAVE SAME VERT POSITIONS subroutine
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE :
#will query verts ? selected
#my @importantVerts = remDupeAxVerts(Y);
sub remDupeAxVerts
{
	lxout("[->] Using remDupeAxVerts subroutine-------------------------------------");

	#GO thru the args and see which disp axes we wanna check.
	my $alignX = 1;
	my $alignY = 1;
	my $alignZ = 1;
	foreach my $var (@_)
	{
		if ($var eq "X")	{$alignX=0;}
		if ($var eq "Y")	{$alignY=0;}
		if ($var eq "Z")	{$alignZ=0;}
	}

	#Begin script
	my @verts = lxq("query layerservice verts ? selected");
	my @nonDupeVerts;
	my $vertPositions;
	my $i = 0;

	foreach my $vert (@verts)
	{
		$i++;
		my @vertPos = lxq("query layerservice vert.pos ? $vert");
		if ($alignX == 0) { @vertPos[0] = 0; }
		if ($alignY == 0) { @vertPos[1] = 0; }
		if ($alignZ == 0) { @vertPos[2] = 0; }
		my  $vertPos = "(@vertPos[0],@vertPos[1],@vertPos[2])";

		if ($vertPositions =~ /$vertPos/)
		{
			lxout("DO NOTHING");
		}
		else
		{
			$vertPositions = $vertPositions . "," . $vertPos;
			push(@nonDupeVerts,$vert);
		}
	}
	return(@nonDupeVerts);
}


#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#CHECK FOR FARTHEST (axes) DISPLACED VERTS subroutine
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE :
#uses verts ? selected query
#@importantVerts = pointDispSort(X,Y,Z);
sub pointDispSort
{
	lxout("[->] Using pointDispSort subroutine-------------------------------------");

	#GO thru the args and see which disp axes we wanna check.
	our ($alignX , $alignY , $alignZ) = 0;
	foreach my $var (@_)
	{
		if ($var eq "X")	{$alignX=1;}
		if ($var eq "Y")	{$alignY=1;}
		if ($var eq "Z")	{$alignZ=1;}
	}


	#Begin script
	my @verts = lxq("query layerservice verts ? selected");
	my $firstVert = @verts[0];
	my @firstVertPos = lxq("query layerservice vert.pos ? $firstVert");
	my @disp;
	my $greatestDisp = 0;
	my $farthestVert;

	for (my $i = 1; $i < ($#verts + 1) ; $i++)
	{
		#lxout("[ROUND $i] <>verts = $firstVert , @verts[$i]");
		my @vertPos = lxq("query layerservice vert.pos ? @verts[$i]");
		my @disp = (@vertPos[0]- @firstVertPos[0], @vertPos[1]-@firstVertPos[1], @vertPos[2]-@firstVertPos[2]);
		if ($alignX != 1) { @disp[0] = 0; }
		if ($alignY != 1) { @disp[1] = 0; }
		if ($alignZ != 1) { @disp[2] = 0; }
		my $addedDisp = (abs(@disp[0]) + abs(@disp[1]) + abs(@disp[2]));
		#lxout("GD = $greatestDisp <> addedDisp = $addedDisp");

		if ($addedDisp > $greatestDisp)
		{
			$greatestDisp = $addedDisp;
			$farthestVert = @verts[$i];
		}
	}
	return($firstVert,$farthestVert);
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#BBOX AND BBOX CENTER : ([0]-[5]=bbox [6]-[8]=center)
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE : my @bboxAndBboxCenter = bboxAndCenter_polys(\@polys);
sub bboxAndCenter_polys{
	my @firstPolyPos = lxq("query layerservice poly.pos ? @{$_[0]}[0]");
	my @bbox = ($firstPolyPos[0],$firstPolyPos[1],$firstPolyPos[2],$firstPolyPos[0],$firstPolyPos[1],$firstPolyPos[2]);

	foreach my $poly (@{$_[0]}){
		my @pos = lxq("query layerservice poly.pos ? $poly");
		if ($pos[0] < $bbox[0])	{	$bbox[0] = $pos[0];	}
		if ($pos[1] < $bbox[1])	{	$bbox[1] = $pos[1];	}
		if ($pos[2] < $bbox[2])	{	$bbox[2] = $pos[2];	}
		if ($pos[0] > $bbox[3])	{	$bbox[3] = $pos[0];	}
		if ($pos[1] > $bbox[4])	{	$bbox[4] = $pos[1];	}
		if ($pos[2] > $bbox[5])	{	$bbox[5] = $pos[2];	}
	}

	$bbox[6] = ($bbox[0] + $bbox[3]) * .5;
	$bbox[7] = ($bbox[1] + $bbox[4]) * .5;
	$bbox[8] = ($bbox[2] + $bbox[5]) * .5;

	return @bbox;
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
#FIX A REORDERED POLY ARRAY  (note, it destroys selection order)
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE : @polys = fixReorderedArray(@polys);
sub fixReorderedArray{
	my $arrayCount = $#_;
	my $polyCount  = lxq("query layerservice poly.n ? all") - 1;
	my @array = (($polyCount-$arrayCount)..$polyCount);
	return @array;
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#REMOVE INDEX LIST2 FROM INDEX LIST1 (so if you delete polys, you can keep your array)
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE : &fixReorderedElements(\@list1,\@list2);
sub fixReorderedElements{
	my @compareList = sort {$a <=> $b} @{$_[1]};

	for (my $i=0; $i<@{$_[0]}; $i++){
		my $subtract = 0;
		foreach my $subt (@compareList){
			if ($subt <= @{$_[0]}[$i])		{	$subtract++;		}
			else						{	last;			}
		}
		@{$_[0]}[$i] -= $subtract;
	}
}









#=====================================================================================================================================================================================================================
#=====================================================================================================================================================================================================================
#=====================================================================================================================================================================================================================
#=====================================================================================================================================================================================================================
#=====================================================================================================================================================================================================================
#=====================================================================================================================================================================================================================
#=====================================================================================================================================================================================================================
#=====================================================================================================================================================================================================================
#===														MATH SUBROUTINES													  ====================================================================================
#=====================================================================================================================================================================================================================
#=====================================================================================================================================================================================================================
#=====================================================================================================================================================================================================================
#=====================================================================================================================================================================================================================
#=====================================================================================================================================================================================================================
#=====================================================================================================================================================================================================================
#=====================================================================================================================================================================================================================
#=====================================================================================================================================================================================================================

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#FIND CLOSEST POWER OF 2 NUMBER (for the modo grid)
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE : my $closestPowerOf2 = findClosestPowerOf2(34.9); (returns 32)
#note : only works on positive numbers and only checks the numbers between (0.0000152879 and 65,536) and ignores 0 because modo doesn't have a grid size of 0
sub findClosestPowerOf2{
	my $closestPowerOf2 = 1;
	my $currentPowerOf2 = 1;
	my $closestDifference = abs($_[0] - 1);
	my $lastDiff = 99999999999999;
	my $result = 0;
	
	if ($_[0] > 0.75){
		if ($_[0] < 1.5){
			$result = 1;
		}else{
			for (my $i=0; $i<16; $i++){
				$currentPowerOf2 *= 2;
				my $diff = abs($currentPowerOf2 - $_[0]);
				if ($diff < $closestDifference){
					$closestPowerOf2 = $i;
					$closestDifference = $diff;
					$result = $currentPowerOf2;
					$lastDiff = $diff;
				}
				if ($diff > $lastDiff){
					last;
				}
			}
		}
	}elsif ($_[0] <= 0.75){
		if ($_[0] > 0.375){
			$result = 0.5;
		}else{
			for (my $i=0; $i<16; $i++){
				$currentPowerOf2 *= 0.5;
				my $diff = abs($currentPowerOf2 - $_[0]);
				if ($diff < $closestDifference){
					$closestPowerOf2 = $i;
					$closestDifference = $diff;
					$result = $currentPowerOf2;
					$lastDiff = $diff;
				}
				if ($diff > $lastDiff){
					last;
				}
			}
		}
	}
	
	return $result;
}


#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#DISTANCE sub
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE : my $dist = dist(@vector);
sub dist{
	my $dist = sqrt(($_[0]*$_[0])+($_[1]*$_[1])+($_[2]*$_[2]));
	return($dist);
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#FIND PERCENTAGE AVG BETWEEN TWO POSITIONS
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#usage : findPercAvg_twoArrays(\@array1,\@array2,$percentage);
sub findPercAvg_twoArrays{
	my ($array1,$array2,$percentage) = @_;
	my @disp = ( @$array2[0] - @$array1[0] , @$array2[1] - @$array1[1] , @$array2[2] - @$array1[2] );
	my @dispPercent = ( $disp[0]*$percentage , $disp[1]*$percentage , $disp[2]*$percentage );
	my @finalPos = ( @$array1[0] + $dispPercent[0] , @$array1[1] + $dispPercent[1] , @$array1[2] + $dispPercent[2] );
	return (@finalPos);
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#FIND PERCENTAGE AVG BETWEEN TWO FLOATS
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#usage : findPercAvg_twoFloats($float1,$float2,$percentage);
sub findPercAvg_twoFloats{
	my ($float1,$float2,$percentage) = @_;
	my $diff = $float2 - $float1;
	return $float1 + ($diff * $percentage);
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
#DOT PRODUCT DETERMINED FROM 2 VERTS AND 1 POS (vector1vert1,vector1vert2,\@pos);
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE : my $dp = dotProduct_fromTwoVertsAndOnePos($vectorVert1,$vectorVert2,\@pos);
#REQUIRES unitVector subroutine
sub dotProduct_fromTwoVertsAndOnePos{
	my @pos1 = lxq("query layerservice vert.pos ? $_[0]");
	my @pos2 = lxq("query layerservice vert.pos ? $_[1]");
	my @vec1 = unitVector($pos2[0]-$pos1[0],$pos2[1]-$pos1[1],$pos2[2]-$pos1[2]);
	my @vec2 = unitVector(@{$_[2]}[0]-$pos1[0],@{$_[2]}[1]-$pos1[1],@{$_[2]}[2]-$pos1[2]);

	my $dp = (	($vec1[0]*$vec2[0])+($vec1[1]*$vec2[1])+($vec1[2]*$vec2[2])	);
	return $dp;
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#DOT PRODUCT DETERMINED FROM 3 VERTS (vector1vert1,vector1vert2,vert);
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE : my $dp = dotProduct_fromThreeVerts($vectorVert1,$vectorVert2,$vertToQueryDPTo);
#REQUIRES unitVector subroutine
sub dotProduct_fromThreeVerts{
	my @pos1 = lxq("query layerservice vert.pos ? $_[0]");
	my @pos2 = lxq("query layerservice vert.pos ? $_[1]");
	my @pos3 = lxq("query layerservice vert.pos ? $_[2]");
	my @vec1 = unitVector($pos2[0]-$pos1[0],$pos2[1]-$pos1[1],$pos2[2]-$pos1[2]);
	my @vec2 = unitVector($pos3[0]-$pos1[0],$pos3[1]-$pos1[1],$pos3[2]-$pos1[2]);

	my $dp = (	($vec1[0]*$vec2[0])+($vec1[1]*$vec2[1])+($vec1[2]*$vec2[2])	);
	return $dp;
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#2 CROSSPRODUCT VECTORS FROM 1 VECTOR (in=1vec+2returnVecs) (v.2)
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE :
#requires UNITVECTOR
#requires CROSSPRODUCT
#getTwoCPVecsFromOneVec(\@inputVec,\@outputVec1,\@outputVec2);
sub getTwoCPVecsFromOneVec{
	my @vector1 = unitVector(@{$_[0]});

	#create the fake vector
	my @vector2 = (0,1,0);
	if (abs(@vector1[0]*@vector2[0] + @vector1[1]*@vector2[1] + @vector1[2]*@vector2[2]) > .95){	@vector2 = (1,0,0);	}

	#create the first and second crossProduct
	@{$_[1]} = unitVector(crossProduct(\@vector1,\@vector2));
	@{$_[2]} = crossProduct(\@vector1,\@{$_[1]});
	@{$_[1]} = crossProduct(\@vector1,\@{$_[2]});
}


#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#2 CROSSPRODUCT VECTORS FROM 1 VECTOR (old) (in=2pos out=2vec)
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE :
#requires UNITVECTOR
#requires CROSSPRODUCT
#my @twoVectors = twoVertCPSetup(\@pos1,\@pos2);
sub twoVertCPSetup{
	my @pos1 = @{$_[0]};
	my @pos2 = @{$_[1]};

	#create the real vector
	my @vector1 = ((@pos2[0]-@pos1[0]),(@pos2[1]-@pos1[1]),(@pos2[2]-@pos1[2]));
	@vector1 = unitVector(@vector1);

	#create the fake vector
	my @vector2 = (0,1,0);
	my $dp = (@vector1[0]*@vector2[0] + @vector1[1]*@vector2[1] + @vector1[2]*@vector2[2]);
	if ($dp > .95){	@vector2 = (1,0,0);	}

	#create the first and second crossProduct
	my @crossProduct = crossProduct(\@vector1,\@vector2);
	@crossProduct = unitVector(@crossProduct);
	my @secondCrossProduct = crossProduct(\@vector1,\@crossProduct);
	return(@crossProduct,@secondCrossProduct);
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
#UNIT VECTOR 2D
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE : my @unitVector2d = unitVector2d(@vector);
sub unitVector2d{
	my $dist1 = sqrt((@_[0]*@_[0])+(@_[1]*@_[1]));
	@_ = ((@_[0]/$dist1),(@_[1]/$dist1));
	return @_;
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#THIS GETS A HEADING AND PITCH FROM A UNIT VECTOR subroutine
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE :
#requires ACOS sub
#my @angles = headingPitch(@unitVector);
sub headingPitch  #use this with a unit vector.  #NEEDS acos subroutine
{
	my @unitVector = @_;
	my $pi=3.14159265358979323;

	#heading=theta <><> pitch=phi
	my $heading = atan2(@unitVector[2],@unitVector[0]);
	my $pitch = acos(@unitVector[1]);
	#convert radians to euler angles.
	$heading = ($heading*180)/$pi;
	$pitch = ($pitch*180)/$pi;

	lxout("heading = $heading");
	lxout("pitch = $pitch");
	return ($heading,$pitch);
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#ASIN subroutine (haven't tested it to make sure it works tho)
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE :
#my $ydeg =  &rad2deg(&asin($axis[1]/$yhyp));
sub asin{
	atan2($_[0], sqrt(1 - $_[0] * $_[0]));
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#ACOS subroutine (radians)
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE :
##heading=theta <><> pitch=phi <><> Also, by default, (heading 0 = X+) <><> (pitch0 = Y+)
#my $heading = atan2(@disp[2],@disp[0]);
#my $pitch = acos(@disp[1]);
#$heading = ($heading*180)/$pi;
#$pitch= ($pitch*180)/$pi;
sub acos {
	atan2(sqrt(1 - $_[0] * $_[0]), $_[0]);
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#GET ANGLE FROM THREE 2D POSITIONS (start,middle,end) (middle is the angle being measured)
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE : getAngleFrom3Pos2D(\@start,\@middle,\@end);
sub getAngleFrom3Pos2D{
	my $pi=3.1415926535897932384626433832795;
	my @disp1 = unitVector2d(arrMath2D(@{$_[0]},@{$_[1]},subt));
	my @disp2 = unitVector2d(arrMath2D(@{$_[2]},@{$_[1]},subt));

	my $radian = atan2($disp1[0],$disp1[1]);
	my $angle = ($radian*180)/$pi;

	my $radian2 = atan2($disp2[0],$disp2[1]);
	my $angle2 = ($radian2*180)/$pi;

	my $finalAngle = $angle2 - $angle;
	if ($finalAngle < 360){$finaleAngle += 360;}
	return $finalAngle;
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#2D ANGLE CHECK SUBROUTINE 2
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE : my $angle = angleCheck2d(\@pos1,\@pos2);
#requires $pi
sub angleCheck2d{
	my @disp = ( (${$_[1]}[0] - ${$_[0]}[0]) , (${$_[1]}[1] - ${$_[0]}[1]) );
	my $radian = atan2($disp[1],$disp[0]);
	my $angle = ($radian*180)/$pi;
	return $angle;
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#2D ANGLE CHECK SUBROUTINE
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE : my $angle = angleCheck($vert1,$vert2,$axis);
sub angleCheck
{
	my ($vert1,$vert2,$axis) = @_;
	my $pi=3.1415926535897932384626433832795;
	my $disp1;
	my $disp2;
	my @vertPos1 = lxq("query layerservice vert.pos ? $vert1");
	my @vertPos2 = lxq("query layerservice vert.pos ? $vert2");


	my @displacement = (@vertPos2[0]-@vertPos1[0],@vertPos2[1]-@vertPos1[1],@vertPos2[2]-@vertPos1[2]);
	if ($axis == 0)
	{
		lxout("x");
		$disp1= @displacement[1];
		$disp2= @displacement[2];
	}
	elsif ($axis == 1)
	{
		lxout("y");
		$disp1 = @displacement[2];
		$disp2 = @displacement[0];
	}
 	elsif ($axis == 2)
	{
		lxout("z");
		$disp1 = @displacement[0];
		$disp2 = @displacement[1];
	}
	my $radian = atan2($disp2,$disp1);
	my $angle = ($radian*180)/$pi;
	return $angle;
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#CORRECT THE 3D VECTOR DIRECTION SUBROUTINE
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE : @vector = correct3DVectorDir(@vector[0],@vector[1],@vector[2]);
sub correct3DVectorDir{
	my @vector = @_;

	#find important axis
	if ((abs(@vector[0]) > abs(@vector[1])) && (abs(@vector[0]) > abs(@vector[2])))		{	our $importantAxis = 0;	}
	elsif ((abs(@vector[1]) > abs(@vector[0])) && (abs(@vector[1]) > abs(@vector[2])))	{	our $importantAxis = 1;	}
	else																				{	our $importantAxis = 2;	}

	#special check for vectors at 45 degree angles (if X=Y or X=Z, and X is neg, then flip)
	if ((int(abs(@vector[0]*1000000)+.5) == int(abs(@vector[1]*1000000)+.5)) || (int(abs(@vector[0]*1000000)+.5) == int(abs(@vector[2]*1000000)+.5))){
		if (@vector[0] < 0){
			@vector[0] *= -1;
			@vector[1] *= -1;
			@vector[2] *= -1;
		}
	}

	#else if the important axis is negative, flip it.
	elsif (@vector[$importantAxis]<0){
		@vector[0] *= -1;
		@vector[1] *= -1;
		@vector[2] *= -1;
	}

	return @vector;
}


#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#CORRECT THE 2D VECTOR DIRECTION SUBROUTINE
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE : @vector = correctVectorDir(@vector[0],@vector[1]);
sub correctVectorDir{
	my @vector = @_;

	#find important axis
	if (abs(@vector[0]) > abs(@vector[1]))	{	our $importantAxis = 0;	}
	else									{	our $importantAxis = 1;	}

	#if both rounded axes are equal and U is negative, flip it.
	if (int(abs(@vector[0]*1000000)+.5) == int(abs(@vector[1]*1000000)+.5)){
		if (@vector[0] < 0){
			@vector[0] *= -1;
			@vector[1] *= -1;
		}
	}

	#else if the important axis is negative, flip it.
	elsif (@vector[$importantAxis]<0){
		@vector[0] *= -1;
		@vector[1] *= -1;
	}

	return @vector;
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#ROUND OUT AN ANGLE SUBROUTINE
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE : my $angle = roundAngle($angle);
sub roundAngle{
	my $angle = @_;
	if		($angle > 315)	{	$angle = 360 - $angle;	}
	elsif	($angle > 270)	{	$angle = 270 - $angle;	}
	elsif	($angle > 225)	{	$angle = 270 - $angle;	}
	elsif	($angle > 180)	{	$angle = 180 - $angle;	}
	elsif	($angle > 135)	{	$angle = 180 - $angle;	}
	elsif	($angle > 90)	{	$angle = 90 - $angle;	}
	elsif	($angle > 45)	{	$angle = 90 - $angle;	}
	else					{	$angle = 360 - $angle;	}
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
#PERFORM MATH FROM ONE ARRAY TO ANOTHER 2D subroutine
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE : my @disp = arrMath(@pos2,@pos1,subt);
sub arrMath2D{
	my @array1 = (@_[0],@_[1]);
	my @array2 = (@_[2],@_[3]);
	my $math = @_[4];

	my @newArray;
	if		($math eq "add")	{	@newArray = (@array1[0]+@array2[0],@array1[1]+@array2[1]);	}
	elsif	($math eq "subt")	{	@newArray = (@array1[0]-@array2[0],@array1[1]-@array2[1]);	}
	elsif	($math eq "mult")	{	@newArray = (@array1[0]*@array2[0],@array1[1]*@array2[1]);	}
	elsif	($math eq "div")	{	@newArray = (@array1[0]/@array2[0],@array1[1]/@array2[1]);	}
	return @newArray;
}

#=====================================================================================================================================================================================================================
#=====================================================================================================================================================================================================================
#=====================================================================================================================================================================================================================
#=====================================================================================================================================================================================================================
#=====================================================================================================================================================================================================================
#=====================================================================================================================================================================================================================
#=====================================================================================================================================================================================================================
#=====================================================================================================================================================================================================================
#===													3X3	MATRIX SUBROUTINES													  ====================================================================================
#=====================================================================================================================================================================================================================
#=====================================================================================================================================================================================================================
#=====================================================================================================================================================================================================================
#=====================================================================================================================================================================================================================
#=====================================================================================================================================================================================================================
#=====================================================================================================================================================================================================================
#=====================================================================================================================================================================================================================
#=====================================================================================================================================================================================================================

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#CONVERT 3X3 MATRIX TO EULERS (in any rotation order)
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE : my @angles = Eul_FromMatrix(\@3x3matrix,"XYZs",degrees|radians);
# - the output will be radians unless the third argument is "degrees" in which case the sub will convert it to degrees for you.
# - returns XrotAmt, YrotAmt, ZrotAmt, rotOrder;
# - resulting matrix must be inversed or transposed for it to be correct in modo.
sub Eul_FromMatrix{
	my ($m, $order) = @_;
	my @ea = (0,0,0,0);
	my $orderBackup = $order;

	my $pi = 3.14159265358979323;
	my $FLT_EPSILON = 0.00000000000000000001;
	my $EulFrmS = 0;
	my $EulFrmR = 1;
	my $EulRepNo = 0;
	my $EulRepYes = 1;
	my $EulParEven = 0;
	my $EulParOdd = 1;
	my @EulSafe = (0,1,2,0);
	my @EulNext = (1,2,0,1);

	#convert order text to indice
	my %rotOrderSetup = (
		"XYZs" , 0,		"XYXs" , 2,		"XZYs" , 4,		"XZXs" , 6,
		"YZXs" , 8,		"YZYs" , 10,	"YXZs" , 12,	"YXYs" , 14,
		"ZXYs" , 16,	"ZXZs" , 18,	"ZYXs" , 20,	"ZYZs" , 22,
		"ZYXr" , 1,		"XYXr" , 3,		"YZXr" , 5,		"XZXr" , 7,
		"XZYr" , 9,		"YZYr" , 11,	"ZXYr" , 13,	"YXYr" , 15,
		"YXZr" , 17,	"ZXZr" , 19,	"XYZr" , 21,	"ZYZr" , 23
	);
	$order = $rotOrderSetup{$order};


	$o=$order&31;
	$f=$o&1;
	$o>>=1;
	$s=$o&1;
	$o>>=1;
	$n=$o&1;
	$o>>=1;
	$i=@EulSafe[$o&3];
	$j=@EulNext[$i+$n];
	$k=@EulNext[$i+1-$n];
	$h=$s?$k:$i;

	if ($s == $EulRepYes) {
		$sy = sqrt($$m[$i][$j]*$$m[$i][$j] + $$m[$i][$k]*$$m[$i][$k]);
		if ($sy > 16*$FLT_EPSILON) {
			$ea[0] = atan2($$m[$i][$j], $$m[$i][$k]);
			$ea[1] = atan2($sy, $$m[$i][$i]);
			$ea[2] = atan2($$m[$j][$i], -$$m[$k][$i]);
		}else{
			$ea[0] = atan2(-$$m[$j][$k], $$m[$j][$j]);
			$ea[1] = atan2($sy, $$m[$i][$i]);
			$ea[2] = 0;
		}
	}else{
		$cy = sqrt($$m[$i][$i]*$$m[$i][$i] + $$m[$j][$i]*$$m[$j][$i]);
		if ($cy > 16*$FLT_EPSILON) {
			$ea[0] = atan2($$m[$k][$j], $$m[$k][$k]);
			$ea[1] = atan2(-$$m[$k][$i], $cy);
			$ea[2] = atan2($$m[$j][$i], $$m[$i][$i]);
		}else{
			$ea[0] = atan2(-$$m[$j][$k], $$m[$j][$j]);
			$ea[1] = atan2(-$$m[$k][$i], $cy);
			$ea[2] = 0;
		}
	}
	if ($n == $EulParOdd)	{	$ea[0] = -$ea[0]; $ea[1] = -$ea[1]; $ea[2] = -$ea[2];	}
	if ($f == $EulFrmR)		{	$t = $ea[0]; $ea[0] = $ea[2]; $ea[2] = $t;				}
	$ea[3] = $order;

	#convert radians to degrees if user wanted
	if ($_[2] eq "degrees"){
		$ea[0] *= 180/$pi;
		$ea[1] *= 180/$pi;
		$ea[2] *= 180/$pi;
	}

	#convert rot order back to lowercase text
	$ea[3] = lc($orderBackup);
	$ea[3] =~ s/[sr]//;

	#reorder rotations so they're always in X, Y, Z display order.
	my @eularOrder;
	$eularOrder[0] = substr($ea[3], 0, 1);
	$eularOrder[1] = substr($ea[3], 1, 1);
	$eularOrder[2] = substr($ea[3], 2, 1);
	my @eaBackup = @ea;
	for (my $i=0; $i<@eularOrder; $i++){
		if ($eularOrder[$i] =~ /x/i){$ea[0] = $eaBackup[$i];}
		if ($eularOrder[$i] =~ /y/i){$ea[1] = $eaBackup[$i];}
		if ($eularOrder[$i] =~ /z/i){$ea[2] = $eaBackup[$i];}
	}

	return @ea;
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#CONVERT EULER ANGLES TO (3 X 3) MATRIX (in any rotation order)
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE : my @3x3Matrix = Eul_ToMatrix($xRot,$yRot,$zRot,"ZXYs",degrees|radians);
# - the angles must be radians unless the fifth argument is "degrees" in which case the sub will convert it to radians for you.
# - must insert the X,Y,Z rotation values in the listed order.  the script will rearrange them internally.
# - as for the rotation order cvar, the last character is "s" or "r".  Here's what they mean:
#	"s" : "static axes"		: use this as default
#	"r" : "rotating axes"	: for body rotation axes?
# - resulting matrix must be inversed or transposed for it to be correct in modo.
sub Eul_ToMatrix{
	my $pi = 3.14159265358979323;
	my $FLT_EPSILON = 0.00000000000000000001;
	my $EulFrmS = 0;
	my $EulFrmR = 1;
	my $EulRepNo = 0;
	my $EulRepYes = 1;
	my $EulParEven = 0;
	my $EulParOdd = 1;
	my @EulSafe = (0,1,2,0);
	my @EulNext = (1,2,0,1);
	my @ea = @_;
	my @m = ([0,0,0],[0,0,0],[0,0,0]);

	#convert degrees to radians if user specified
	if ($_[4] eq "degrees"){
		$ea[0] *= $pi/180;
		$ea[1] *= $pi/180;
		$ea[2] *= $pi/180;
	}

	#reorder rotation value args to match same order as rotation order.
	my $rotOrderCopy = $ea[3];
	$rotOrderCopy =~ s/X/$ea[0],/g;
	$rotOrderCopy =~ s/Y/$ea[1],/g;
	$rotOrderCopy =~ s/Z/$ea[2],/g;
	my @eaCopy = split(/,/, $rotOrderCopy);
	$ea[0] = $eaCopy[0];
	$ea[1] = $eaCopy[1];
	$ea[2] = $eaCopy[2];

	my %rotOrderSetup = (
		"XYZs" , 0,		"XYXs" , 2,		"XZYs" , 4,		"XZXs" , 6,
		"YZXs" , 8,		"YZYs" , 10,	"YXZs" , 12,	"YXYs" , 14,
		"ZXYs" , 16,	"ZXZs" , 18,	"ZYXs" , 20,	"ZYZs" , 22,
		"ZYXr" , 1,		"XYXr" , 3,		"YZXr" , 5,		"XZXr" , 7,
		"XZYr" , 9,		"YZYr" , 11,	"ZXYr" , 13,	"YXYr" , 15,
		"YXZr" , 17,	"ZXZr" , 19,	"XYZr" , 21,	"ZYZr" , 23
	);
	$ea[3] = $rotOrderSetup{$ea[3]};

	#initial code
	$o=$ea[3]&31;
	$f=$o&1;
	$o>>=1;
	$s=$o&1;
	$o>>=1;
	$n=$o&1;
	$o>>=1;
	$i=$EulSafe[$o&3];
	$j=$EulNext[$i+$n];
	$k=$EulNext[$i+1-$n];
	$h=$s?$k:$i;

	if ($f == $EulFrmR)		{	$t = $ea[0]; $ea[0] = $ea[2]; $ea[2] = $t;				}
	if ($n == $EulParOdd)	{	$ea[0] = -$ea[0]; $ea[1] = -$ea[1]; $ea[2] = -$ea[2];	}
	$ti = $ea[0];
	$tj = $ea[1];
	$th = $ea[2];

	$ci = cos($ti); $cj = cos($tj); $ch = cos($th);
	$si = sin($ti); $sj = sin($tj); $sh = sin($th);
	$cc = $ci*$ch; $cs = $ci*$sh; $sc = $si*$ch; $ss = $si*$sh;

	if ($s == $EulRepYes) {
		$m[$i][$i] = $cj;		$m[$i][$j] =  $sj*$si;			$m[$i][$k] =  $sj*$ci;
		$m[$j][$i] = $sj*$sh;	$m[$j][$j] = -$cj*$ss+$cc;		$m[$j][$k] = -$cj*$cs-$sc;
		$m[$k][$i] = -$sj*$ch;	$m[$k][$j] =  $cj*$sc+$cs;		$m[$k][$k] =  $cj*$cc-$ss;
	}else{
		$m[$i][$i] = $cj*$ch;	$m[$i][$j] = $sj*$sc-$cs;		$m[$i][$k] = $sj*$cc+$ss;
		$m[$j][$i] = $cj*$sh;	$m[$j][$j] = $sj*$ss+$cc;		$m[$j][$k] = $sj*$cs-$sc;
		$m[$k][$i] = -$sj;		$m[$k][$j] = $cj*$si;			$m[$k][$k] = $cj*$ci;
    }

    return @m;
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#EULER TO 3X3 MATRIX (only works in one rot order. use the other sub for full rot orders)
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE : my @3x3Matrix = eulerTo3x3Matrix($heading,$pitch,$bank);
sub eulerTo3x3Matrix{
	my $pi = 3.14159265358979323;
	my $heading = $_[0] * ($pi/180);
	my $pitch = $_[1] * ($pi/180);
	my $bank = $_[2] * ($pi/180);

    my $ch = cos($heading);
    my $sh = sin($heading);
    my $cp = cos($pitch);
    my $sp = sin($pitch);
    my $cb = cos($bank);
    my $sb = sin($bank);

	my $m00 = $ch*$cb + $sh*$sp*$sb;
	my $m01 = -$ch*$sb + $sh*$sp*$cb;
	my $m02 = $sh*$cp;

	my $m10 = $sb*$cp;
	my $m11 = $cb*$cp;
	my $m12 = -$sp;

	my $m20 = -$sh*$cb + $ch*$sp*$sb;
	my $m21 = $sb*$sh + $ch*$sp*$cb;
	my $m22 = $ch*$cp;

    my @matrix = (
		[$m00,$m01,$m02],
		[$m10,$m11,$m12],
		[$m20,$m21,$m22],
	);

	return @matrix;
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#CONVERT MATRIX TO EULER (9char matrix) (only works in one rot order. use the other sub for full rot orders)
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE : my @rotations = matrixToEuler(\@vector1,\@vector2,\@vector3);
sub matrixToEuler{
	my @x = @{$_[0]};
	my @y = @{$_[1]};
	my @z = @{$_[2]};

	##TEMP : BUILD THE VERTS for the vector matrix
	#my @vert1 = arrMath(@x,30,30,30,mult);
	#my @vert2 = arrMath(@y,30,30,30,mult);
	#my @vert3 = arrMath(@z,30,30,30,mult);
	#@vert1 = arrMath(@objectBottom,@vert1,add);
	#@vert2 = arrMath(@objectBottom,@vert2,add);
	#@vert3 = arrMath(@objectBottom,@vert3,add);
	#lx("vert.new @objectBottom");
	#createSphere(@vert1);
	#createCube(@vert2);
	#lx("vert.new @vert3");

	my ($heading,$altitude,$bank);
	my $pi = 3.14159265358979323;

	if (@y[0] > 0.998){						#except when M10=1 (north pole)
		$heading = atan2(@x[2],@z[2]);		#heading = atan2(M02,M22)
		$altitude = asin(@y[0]);		 		#
		$bank = 0;							#bank = 0
	}elsif (@y[0] < -0.998){					#except when M10=-1 (south pole)
		$heading = atan2(@x[2],@z[2]);		#heading = atan2(M02,M22)
		$altitude = asin(@y[0]);				#
		$bank = 0;							#bank = 0
	}else{
		$heading = atan2(-@z[0],@x[0]);		#heading = atan2(-m20,m00)
		$altitude = asin(@y[0]);		  		#attitude = asin(m10)
		$bank = atan2(-@y[2],@y[1]);			#bank = atan2(-m12,m11)
	}

	return ($heading,$altitude,$bank);
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#3 X 3 ROTATION MATRIX FLIP (only works on rotation-only matrices though)
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#usage @matrix = transposeRotMatrix_3x3(\@matrix);
sub transposeRotMatrix_3x3{
	my @matrix = (
		[ @{$_[0][0]}[0],@{$_[0][1]}[0],@{$_[0][2]}[0] ],	#[a00,a10,a20,a03],
		[ @{$_[0][0]}[1],@{$_[0][1]}[1],@{$_[0][2]}[1] ],	#[a01,a11,a21,a13],
		[ @{$_[0][0]}[2],@{$_[0][1]}[2],@{$_[0][2]}[2] ],	#[a02,a12,a22,a23],
	);
	return @matrix;
}


#=====================================================================================================================================================================================================================
#=====================================================================================================================================================================================================================
#=====================================================================================================================================================================================================================
#=====================================================================================================================================================================================================================
#=====================================================================================================================================================================================================================
#=====================================================================================================================================================================================================================
#=====================================================================================================================================================================================================================
#=====================================================================================================================================================================================================================
#===													4x4	MATRIX SUBROUTINES													  ====================================================================================
#=====================================================================================================================================================================================================================
#=====================================================================================================================================================================================================================
#=====================================================================================================================================================================================================================
#=====================================================================================================================================================================================================================
#=====================================================================================================================================================================================================================
#=====================================================================================================================================================================================================================
#=====================================================================================================================================================================================================================
#=====================================================================================================================================================================================================================

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#CONVERT 3X3 MATRIX TO 4X4 MATRIX
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#my @4x4Matrix = convert3x3M_4x4M(\@3x3Matrix);
sub convert3x3M_4x4M{
	my ($m) = $_[0];
	my @matrix = (
		[$$m[0][0],$$m[0][1],$$m[0][2],0],
		[$$m[1][0],$$m[1][1],$$m[1][2],0],
		[$$m[2][0],$$m[2][1],$$m[2][2],0],
		[0,0,0,1]
	);

	return @matrix;
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#GET ITEM XFRM MATRIX (of the item and all it's parents and pivots)
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE : my @itemXfrmMatrix = getItemXfrmMatrix($itemID);
#if you multiply the verts by it's matrix, it gives their world positions.
sub getItemXfrmMatrix{
	my ($id) = $_[0];

	my @matrix = (
		[1,0,0,0],
		[0,1,0,0],
		[0,0,1,0],
		[0,0,0,1]
	);

	while ($id ne ""){
		my @transformIDs = lxq("query sceneservice item.xfrmItems ? {$id}");
		my @pivotTransformIDs;
		my @pivotRotationIDs;

		#find any pivot move or pivot rotate transforms
		foreach my $transID (@transformIDs){
			my $name = lxq("query sceneservice item.name ? $transID");
			$name =~ s/\s\([0-9]+\)$//;
			if ($name eq "Pivot Position"){
				push(@pivotTransformIDs,$transID);
			}elsif ($name eq "Pivot Rotation"){
				push(@pivotRotationIDs,$transID);
			}
		}

		#go through transforms
		foreach my $transID (@transformIDs){
			my $name = lxq("query sceneservice item.name ? $transID");
			my $type = lxq("query sceneservice item.type ? $transID");
			my $channelCount = lxq("query sceneservice channel.n ?");

			#rotation
			if ($type eq "rotation"){
				my $rotX = lxq("item.channel rot.X {?} set {$transID}");
				my $rotY = lxq("item.channel rot.Y {?} set {$transID}");
				my $rotZ = lxq("item.channel rot.Z {?} set {$transID}");
				my $rotOrder = uc(lxq("item.channel order {?} set {$transID}")) . "s";
				my @rotMatrix = Eul_ToMatrix($rotX,$rotY,$rotZ,$rotOrder,"degrees");
				@rotMatrix = convert3x3M_4x4M(\@rotMatrix);
				@matrix = mtxMult(\@rotMatrix,\@matrix);
			}

			#translation
			elsif ($type eq "translation"){
				my $posX = lxq("item.channel pos.X {?} set {$transID}");
				my $posY = lxq("item.channel pos.Y {?} set {$transID}");
				my $posZ = lxq("item.channel pos.Z {?} set {$transID}");
				my @posMatrix = (
					[1,0,0,$posX],
					[0,1,0,$posY],
					[0,0,1,$posZ],
					[0,0,0,1]
				);
				@matrix = mtxMult(\@posMatrix,\@matrix);
			}

			#scale
			elsif ($type eq "scale"){
				my $sclX = lxq("item.channel scl.X {?} set {$transID}");
				my $sclY = lxq("item.channel scl.Y {?} set {$transID}");
				my $sclZ = lxq("item.channel scl.Z {?} set {$transID}");
				my @sclMatrix = (
					[$sclX,0,0,0],
					[0,$sclY,0,0],
					[0,0,$sclZ,0],
					[0,0,0,1]
				);
				@matrix = mtxMult(\@sclMatrix,\@matrix);
			}

			#transform
			elsif ($type eq "transform"){
				#transform : piv pos
				if ($name =~ /pivot position inverse/i){
					my $posX = lxq("item.channel pos.X {?} set {$pivotTransformIDs[0]}");
					my $posY = lxq("item.channel pos.Y {?} set {$pivotTransformIDs[0]}");
					my $posZ = lxq("item.channel pos.Z {?} set {$pivotTransformIDs[0]}");
					my @posMatrix = (
						[1,0,0,$posX],
						[0,1,0,$posY],
						[0,0,1,$posZ],
						[0,0,0,1]
					);
					@posMatrix = inverseMatrix(\@posMatrix);
					@matrix = mtxMult(\@posMatrix,\@matrix);
				}

				#transform : piv rot
				elsif ($name =~ /pivot rotation inverse/i){
					my $rotX = lxq("item.channel rot.X {?} set {$pivotRotationIDs[0]}");
					my $rotY = lxq("item.channel rot.Y {?} set {$pivotRotationIDs[0]}");
					my $rotZ = lxq("item.channel rot.Z {?} set {$pivotRotationIDs[0]}");
					my $rotOrder = uc(lxq("item.channel order {?} set {$pivotRotationIDs[0]}")) . "s";
					my @rotMatrix = Eul_ToMatrix($rotX,$rotY,$rotZ,$rotOrder,"degrees");
					@rotMatrix = convert3x3M_4x4M(\@rotMatrix);
					@rotMatrix = transposeRotMatrix(\@rotMatrix);
					@matrix = mtxMult(\@rotMatrix,\@matrix);
				}

				else{
					lxout("type is a transform, but not a PIVPOSINV or PIVROTINV! : $type");
				}
			}

			#other?!
			else{
				lxout("type is neither rotation or translation! : $type");
			}
		}
		$id = lxq("query sceneservice item.parent ? $id");
	}
	return @matrix;
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#MATRIX DETERMINANT sub
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE : my $determinant = matrix_determinant(\@matrix);
sub matrix_determinant{
	my ($m) = $_[0];
	my $val =	$$m[0][0] * ($$m[1][1]*$$m[2][2] - $$m[1][2]*$$m[2][1]) +
				$$m[0][1] * ($$m[1][2]*$$m[2][0] - $$m[1][0]*$$m[2][2]) +
				$$m[0][2] * ($$m[1][0]*$$m[2][1] - $$m[1][1]*$$m[2][0]);
				lxout("val = $val");
	return $val;
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#FIND PERCENTAGE AVG BETWEEN TWO MATRICES #doesn't work with scales because of unitVec for rots.
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#usage : findPercAvg_twoMatxs(\@matrix1,\@matrix2,$percentage);
sub findPercAvg_twoMatxs{
	my ($m1,$m2,$percentage) = @_;
	my @matx = (
		[ $$m1[0][0]+($$m2[0][0]-$$m1[0][0])*$percentage , $$m1[0][1]+($$m2[0][1]-$$m1[0][1])*$percentage , $$m1[0][2]+($$m2[0][2]-$$m1[0][2])*$percentage , $$m1[0][3]+($$m2[0][3]-$$m1[0][3])*$percentage ],
		[ $$m1[1][0]+($$m2[1][0]-$$m1[1][0])*$percentage , $$m1[1][1]+($$m2[1][1]-$$m1[1][1])*$percentage , $$m1[1][2]+($$m2[1][2]-$$m1[1][2])*$percentage , $$m1[1][3]+($$m2[1][3]-$$m1[1][3])*$percentage ],
		[ $$m1[2][0]+($$m2[2][0]-$$m1[2][0])*$percentage , $$m1[2][1]+($$m2[2][1]-$$m1[2][1])*$percentage , $$m1[2][2]+($$m2[2][2]-$$m1[2][2])*$percentage , $$m1[2][3]+($$m2[2][3]-$$m1[2][3])*$percentage ],
		[ $$m1[3][0]+($$m2[3][0]-$$m1[3][0])*$percentage , $$m1[3][1]+($$m2[3][1]-$$m1[3][1])*$percentage , $$m1[3][2]+($$m2[3][2]-$$m1[3][2])*$percentage , $$m1[3][3]+($$m2[3][3]-$$m1[3][3])*$percentage ]
	);

	@matx = ( #make unitvector again to prevent rotational squishing.
		[unitVector($matx[0][0],$matx[0][1],$matx[0][2]),$matx[0][3]],
		[unitVector($matx[1][0],$matx[1][1],$matx[1][2]),$matx[1][3]],
		[unitVector($matx[2][0],$matx[2][1],$matx[2][2]),$matx[2][3]],
		[$matx[3][0],$matx[3][1],$matx[3][2],$matx[3][3]]
	);

	return(@matx);
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#4 X 4 MATRIX INVERSION sub
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE : @inverseMatrix = inverseMatrix(\@matrix);
sub inverseMatrix{
	my ($m) = $_[0];
	my @matrix = (
		[$$m[0][0],$$m[0][1],$$m[0][2],$$m[0][3]],
		[$$m[1][0],$$m[1][1],$$m[1][2],$$m[1][3]],
		[$$m[2][0],$$m[2][1],$$m[2][2],$$m[2][3]],
		[$$m[3][0],$$m[3][1],$$m[3][2],$$m[3][3]]
	);

	$matrix[0][0] =  $$m[1][1]*$$m[2][2]*$$m[3][3] - $$m[1][1]*$$m[2][3]*$$m[3][2] - $$m[2][1]*$$m[1][2]*$$m[3][3] + $$m[2][1]*$$m[1][3]*$$m[3][2] + $$m[3][1]*$$m[1][2]*$$m[2][3] - $$m[3][1]*$$m[1][3]*$$m[2][2];
	$matrix[1][0] = -$$m[1][0]*$$m[2][2]*$$m[3][3] + $$m[1][0]*$$m[2][3]*$$m[3][2] + $$m[2][0]*$$m[1][2]*$$m[3][3] - $$m[2][0]*$$m[1][3]*$$m[3][2] - $$m[3][0]*$$m[1][2]*$$m[2][3] + $$m[3][0]*$$m[1][3]*$$m[2][2];
	$matrix[2][0] =  $$m[1][0]*$$m[2][1]*$$m[3][3] - $$m[1][0]*$$m[2][3]*$$m[3][1] - $$m[2][0]*$$m[1][1]*$$m[3][3] + $$m[2][0]*$$m[1][3]*$$m[3][1] + $$m[3][0]*$$m[1][1]*$$m[2][3] - $$m[3][0]*$$m[1][3]*$$m[2][1];
	$matrix[3][0] = -$$m[1][0]*$$m[2][1]*$$m[3][2] + $$m[1][0]*$$m[2][2]*$$m[3][1] + $$m[2][0]*$$m[1][1]*$$m[3][2] - $$m[2][0]*$$m[1][2]*$$m[3][1] - $$m[3][0]*$$m[1][1]*$$m[2][2] + $$m[3][0]*$$m[1][2]*$$m[2][1];
	$matrix[0][1] = -$$m[0][1]*$$m[2][2]*$$m[3][3] + $$m[0][1]*$$m[2][3]*$$m[3][2] + $$m[2][1]*$$m[0][2]*$$m[3][3] - $$m[2][1]*$$m[0][3]*$$m[3][2] - $$m[3][1]*$$m[0][2]*$$m[2][3] + $$m[3][1]*$$m[0][3]*$$m[2][2];
	$matrix[1][1] =  $$m[0][0]*$$m[2][2]*$$m[3][3] - $$m[0][0]*$$m[2][3]*$$m[3][2] - $$m[2][0]*$$m[0][2]*$$m[3][3] + $$m[2][0]*$$m[0][3]*$$m[3][2] + $$m[3][0]*$$m[0][2]*$$m[2][3] - $$m[3][0]*$$m[0][3]*$$m[2][2];
	$matrix[2][1] = -$$m[0][0]*$$m[2][1]*$$m[3][3] + $$m[0][0]*$$m[2][3]*$$m[3][1] + $$m[2][0]*$$m[0][1]*$$m[3][3] - $$m[2][0]*$$m[0][3]*$$m[3][1] - $$m[3][0]*$$m[0][1]*$$m[2][3] + $$m[3][0]*$$m[0][3]*$$m[2][1];
	$matrix[3][1] =  $$m[0][0]*$$m[2][1]*$$m[3][2] - $$m[0][0]*$$m[2][2]*$$m[3][1] - $$m[2][0]*$$m[0][1]*$$m[3][2] + $$m[2][0]*$$m[0][2]*$$m[3][1] + $$m[3][0]*$$m[0][1]*$$m[2][2] - $$m[3][0]*$$m[0][2]*$$m[2][1];
	$matrix[0][2] =  $$m[0][1]*$$m[1][2]*$$m[3][3] - $$m[0][1]*$$m[1][3]*$$m[3][2] - $$m[1][1]*$$m[0][2]*$$m[3][3] + $$m[1][1]*$$m[0][3]*$$m[3][2] + $$m[3][1]*$$m[0][2]*$$m[1][3] - $$m[3][1]*$$m[0][3]*$$m[1][2];
	$matrix[1][2] = -$$m[0][0]*$$m[1][2]*$$m[3][3] + $$m[0][0]*$$m[1][3]*$$m[3][2] + $$m[1][0]*$$m[0][2]*$$m[3][3] - $$m[1][0]*$$m[0][3]*$$m[3][2] - $$m[3][0]*$$m[0][2]*$$m[1][3] + $$m[3][0]*$$m[0][3]*$$m[1][2];
	$matrix[2][2] =  $$m[0][0]*$$m[1][1]*$$m[3][3] - $$m[0][0]*$$m[1][3]*$$m[3][1] - $$m[1][0]*$$m[0][1]*$$m[3][3] + $$m[1][0]*$$m[0][3]*$$m[3][1] + $$m[3][0]*$$m[0][1]*$$m[1][3] - $$m[3][0]*$$m[0][3]*$$m[1][1];
	$matrix[3][2] = -$$m[0][0]*$$m[1][1]*$$m[3][2] + $$m[0][0]*$$m[1][2]*$$m[3][1] + $$m[1][0]*$$m[0][1]*$$m[3][2] - $$m[1][0]*$$m[0][2]*$$m[3][1] - $$m[3][0]*$$m[0][1]*$$m[1][2] + $$m[3][0]*$$m[0][2]*$$m[1][1];
	$matrix[0][3] = -$$m[0][1]*$$m[1][2]*$$m[2][3] + $$m[0][1]*$$m[1][3]*$$m[2][2] + $$m[1][1]*$$m[0][2]*$$m[2][3] - $$m[1][1]*$$m[0][3]*$$m[2][2] - $$m[2][1]*$$m[0][2]*$$m[1][3] + $$m[2][1]*$$m[0][3]*$$m[1][2];
	$matrix[1][3] =  $$m[0][0]*$$m[1][2]*$$m[2][3] - $$m[0][0]*$$m[1][3]*$$m[2][2] - $$m[1][0]*$$m[0][2]*$$m[2][3] + $$m[1][0]*$$m[0][3]*$$m[2][2] + $$m[2][0]*$$m[0][2]*$$m[1][3] - $$m[2][0]*$$m[0][3]*$$m[1][2];
	$matrix[2][3] = -$$m[0][0]*$$m[1][1]*$$m[2][3] + $$m[0][0]*$$m[1][3]*$$m[2][1] + $$m[1][0]*$$m[0][1]*$$m[2][3] - $$m[1][0]*$$m[0][3]*$$m[2][1] - $$m[2][0]*$$m[0][1]*$$m[1][3] + $$m[2][0]*$$m[0][3]*$$m[1][1];
	$matrix[3][3] =  $$m[0][0]*$$m[1][1]*$$m[2][2] - $$m[0][0]*$$m[1][2]*$$m[2][1] - $$m[1][0]*$$m[0][1]*$$m[2][2] + $$m[1][0]*$$m[0][2]*$$m[2][1] + $$m[2][0]*$$m[0][1]*$$m[1][2] - $$m[2][0]*$$m[0][2]*$$m[1][1];

	return @matrix;
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#4 X 4 ROTATION MATRIX FLIP (only works on rotation-only matrices though)
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#usage @matrix = transposeRotMatrix(\@matrix);
sub transposeRotMatrix{
	my @matrix = (
		[ @{$_[0][0]}[0],@{$_[0][1]}[0],@{$_[0][2]}[0],@{$_[0][0]}[3] ],	#[a00,a10,a20,a03],
		[ @{$_[0][0]}[1],@{$_[0][1]}[1],@{$_[0][2]}[1],@{$_[0][1]}[3] ],	#[a01,a11,a21,a13],
		[ @{$_[0][0]}[2],@{$_[0][1]}[2],@{$_[0][2]}[2],@{$_[0][2]}[3] ],	#[a02,a12,a22,a23],
		[ @{$_[0][3]}[0],@{$_[0][3]}[1],@{$_[0][3]}[2],@{$_[0][3]}[3] ]		#[a30,a31,a32,a33],
	);
	return @matrix;
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#4X4 x 1x3 MATRIX MULTIPLY (move vert by 4x4 matrix)
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE : @vertPos = vec_mtxMult(\@matrix,\@vertPos);
#arg0 = transform matrix.  arg1 = vertPos to multiply to that then sends the results to the cvar.
sub vec_mtxMult{
	my @pos = (
		@{$_[0][0]}[0]*@{$_[1]}[0] + @{$_[0][0]}[1]*@{$_[1]}[1] + @{$_[0][0]}[2]*@{$_[1]}[2] + @{$_[0][0]}[3],	#a1*x_old + a2*y_old + a3*z_old + a4
		@{$_[0][1]}[0]*@{$_[1]}[0] + @{$_[0][1]}[1]*@{$_[1]}[1] + @{$_[0][1]}[2]*@{$_[1]}[2] + @{$_[0][1]}[3],	#b1*x_old + b2*y_old + b3*z_old + b4
		@{$_[0][2]}[0]*@{$_[1]}[0] + @{$_[0][2]}[1]*@{$_[1]}[1] + @{$_[0][2]}[2]*@{$_[1]}[2] + @{$_[0][2]}[3]	#c1*x_old + c2*y_old + c3*z_old + c4
	);

	#dividing @pos by (matrix's 4,4) to correct "projective space"
	$pos[0] = $pos[0] / @{$_[0][3]}[3];
	$pos[1] = $pos[1] / @{$_[0][3]}[3];
	$pos[2] = $pos[2] / @{$_[0][3]}[3];

	return @pos;
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#4X4 x 4X4 MATRIX MULTIPLY
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE : @matrix = mtxMult(\@matrixMult,\@matrix);
#arg0 = transform matrix.  arg1 = matrix to multiply to that then sends the results to the cvar.
sub mtxMult{
	my @matrix = (
		[ @{$_[0][0]}[0]*@{$_[1][0]}[0] + @{$_[0][0]}[1]*@{$_[1][1]}[0] + @{$_[0][0]}[2]*@{$_[1][2]}[0] + @{$_[0][0]}[3]*@{$_[1][3]}[0] , @{$_[0][0]}[0]*@{$_[1][0]}[1] + @{$_[0][0]}[1]*@{$_[1][1]}[1] + @{$_[0][0]}[2]*@{$_[1][2]}[1] + @{$_[0][0]}[3]*@{$_[1][3]}[1] , @{$_[0][0]}[0]*@{$_[1][0]}[2] + @{$_[0][0]}[1]*@{$_[1][1]}[2] + @{$_[0][0]}[2]*@{$_[1][2]}[2] + @{$_[0][0]}[3]*@{$_[1][3]}[2] , @{$_[0][0]}[0]*@{$_[1][0]}[3] + @{$_[0][0]}[1]*@{$_[1][1]}[3] + @{$_[0][0]}[2]*@{$_[1][2]}[3] + @{$_[0][0]}[3]*@{$_[1][3]}[3] ],	#a11b11+a12b21+a13b31+a14b41,a11b12+a12b22+a13b32+a14b42,a11b13+a12b23+a13b33+a14b43,a11b14+a12b24+a13b34+a14b44
		[ @{$_[0][1]}[0]*@{$_[1][0]}[0] + @{$_[0][1]}[1]*@{$_[1][1]}[0] + @{$_[0][1]}[2]*@{$_[1][2]}[0] + @{$_[0][1]}[3]*@{$_[1][3]}[0] , @{$_[0][1]}[0]*@{$_[1][0]}[1] + @{$_[0][1]}[1]*@{$_[1][1]}[1] + @{$_[0][1]}[2]*@{$_[1][2]}[1] + @{$_[0][1]}[3]*@{$_[1][3]}[1] , @{$_[0][1]}[0]*@{$_[1][0]}[2] + @{$_[0][1]}[1]*@{$_[1][1]}[2] + @{$_[0][1]}[2]*@{$_[1][2]}[2] + @{$_[0][1]}[3]*@{$_[1][3]}[2] , @{$_[0][1]}[0]*@{$_[1][0]}[3] + @{$_[0][1]}[1]*@{$_[1][1]}[3] + @{$_[0][1]}[2]*@{$_[1][2]}[3] + @{$_[0][1]}[3]*@{$_[1][3]}[3] ],	#a21b11+a22b21+a23b31+a24b41,a21b12+a22b22+a23b32+a24b42,a21b13+a22b23+a23b33+a24b43,a21b14+a22b24+a23b34+a24b44
		[ @{$_[0][2]}[0]*@{$_[1][0]}[0] + @{$_[0][2]}[1]*@{$_[1][1]}[0] + @{$_[0][2]}[2]*@{$_[1][2]}[0] + @{$_[0][2]}[3]*@{$_[1][3]}[0] , @{$_[0][2]}[0]*@{$_[1][0]}[1] + @{$_[0][2]}[1]*@{$_[1][1]}[1] + @{$_[0][2]}[2]*@{$_[1][2]}[1] + @{$_[0][2]}[3]*@{$_[1][3]}[1] , @{$_[0][2]}[0]*@{$_[1][0]}[2] + @{$_[0][2]}[1]*@{$_[1][1]}[2] + @{$_[0][2]}[2]*@{$_[1][2]}[2] + @{$_[0][2]}[3]*@{$_[1][3]}[2] , @{$_[0][2]}[0]*@{$_[1][0]}[3] + @{$_[0][2]}[1]*@{$_[1][1]}[3] + @{$_[0][2]}[2]*@{$_[1][2]}[3] + @{$_[0][2]}[3]*@{$_[1][3]}[3] ],	#a31b11+a32b21+a33b31+a34b41,a31b12+a32b22+a33b32+a34b42,a31b13+a32b23+a33b33+a34b43,a31b14+a32b24+a33b34+a34b44
		[ @{$_[0][3]}[0]*@{$_[1][0]}[0] + @{$_[0][3]}[1]*@{$_[1][1]}[0] + @{$_[0][3]}[2]*@{$_[1][2]}[0] + @{$_[0][3]}[3]*@{$_[1][3]}[0] , @{$_[0][3]}[0]*@{$_[1][0]}[1] + @{$_[0][3]}[1]*@{$_[1][1]}[1] + @{$_[0][3]}[2]*@{$_[1][2]}[1] + @{$_[0][3]}[3]*@{$_[1][3]}[1] , @{$_[0][3]}[0]*@{$_[1][0]}[2] + @{$_[0][3]}[1]*@{$_[1][1]}[2] + @{$_[0][3]}[2]*@{$_[1][2]}[2] + @{$_[0][3]}[3]*@{$_[1][3]}[2] , @{$_[0][3]}[0]*@{$_[1][0]}[3] + @{$_[0][3]}[1]*@{$_[1][1]}[3] + @{$_[0][3]}[2]*@{$_[1][2]}[3] + @{$_[0][3]}[3]*@{$_[1][3]}[3] ]	#a41b11+a42b21+a43b31+a44b41,a41b12+a42b22+a43b32+a44b42,a41b13+a42b23+a43b33+a44b43,a41b14+a42b24+a43b34+a44b44
	);

	return @matrix;
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#PRINT MATRIX v2 (4x4) and (3x3)
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#usage : printMatrix(\@matrix);
sub printMatrix{
	lxout("==========");
	my $matrix = $_[0];
	if (@$matrix == 4){	our $dimensions = 4; } else { our $dimensions = 3; }
	for (my $i=0; $i<$dimensions; $i++){
		for (my $u=0; $u<$dimensions; $u++){
			lxout("[$i][$u] = @{$_[0][$i]}[$u]");
		}
		lxout("\n");
	}
}
