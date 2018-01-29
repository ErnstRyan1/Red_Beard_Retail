#perl
#this script is for miscelaneous shader tree commands.  right now there's only the abiliy to tell all the selected images to use the last selected image's txlocator and that's it. (and the txlocators must be selected in the shader tree of course)

#USER VALUES
userValueTools(sene_applyRandSelMtrlType,string,config,"sene_applyRandSelMtrlType","","","",xxx,xxx,"","polyIsland");
userValueTools(sene_applyRandSelRndMode,string,config,"sene_applyRandSelMtrlType","","","",xxx,xxx,"","random");

#SCRIPT ARGUMENTS
foreach my $arg (@ARGV){
	if		($arg =~ /copyPasteTxLocators/i)	{	&copyPasteTxLocators;	}
	elsif	($arg =~ /delUnusedTxLocators/i)	{	&delUnusedTxLocators;	}
	elsif	($arg =~ /st_findReplace/i)			{	&st_findReplace;		}
	elsif	($arg =~ /sel_bySameEffect/i)		{	&sel_bySameEffect;		}
	elsif	($arg =~ /prcBrws/i)				{	&prcBrws;				}
	elsif	($arg =~ /applyRandSelMtrl/i)		{	&applyRandSelMtrl;		}
	elsif	($arg =~ /hideSel/i)				{	hide("hideSel");		}
	elsif	($arg =~ /showSel/i)				{	hide("showSel");		}
	elsif	($arg =~ /showAll/i)				{	hide("showAll");		}
	elsif	($arg =~ /showOnlySel/i)			{	hide("showOnlySel");	}
	elsif	($arg =~ /hideByEffect/i)			{	hideByEffect("hide");	}
	elsif	($arg =~ /showByEffect/i)			{	hideByEffect("show");	}
	elsif	($arg =~ /toggleByEffect/i)			{	hideByEffect("toggle");	}
	elsif	($arg =~ /hideByType/i)				{	hideByType("hide");		}
	elsif	($arg =~ /showByType/i)				{	hideByType("show");		}
	elsif	($arg =~ /toggleByType/i)			{	hideByType("toggle");	}
	elsif	($arg =~ /toggleVisSpecial/i)		{	toggleVisSpecial();		}
	else										{	our $miscArg = $arg;	}
}

#TOGGLE VIS SPECIAL : toggles all layers that start with # in their name.  use a cvar to change the search term.
sub toggleVisSpecial{
	my $searchTerm = "#";
	if ($miscArg ne ""){
		$searchTerm = $miscArg;
		chomp($searchTerm);
	}
	
	my $txLayerCount = lxq("query sceneservice txLayer.n ? all");
	my $enable = -1;
	for (my $i=0; $i<$txLayerCount; $i++){
		my $name = lxq("query sceneservice txLayer.name ? $i");
		if ($name =~ /^\Q$searchTerm\E/){  
			my $id = lxq("query sceneservice txLayer.id ? $i");
			my $visible = lxq("item.channel enable {?} set {$id}");
			if ($enable == -1){
				if ($visible == 0)	{	$enable = 1;	}
				else				{	$enable = 0;	}
			}
			lx("!!shader.setVisible {$id} {$enable}");
		}
	}
}

#APPLY THE SELECTED MATERIALS RANDOMLY TO THE POLYS.
sub applyRandSelMtrl{
	#get polys
	my $mainlayer = lxq("query layerservice layers ? main");
	my @polys = lxq("query layerservice polys ? selected");
	if (@polys == 0){die("You don't have any polys selected and so I'm canceling the script");}

	#get randomization mode
	my $sene_applyRandSelRndMode = lxq("user.value sene_applyRandSelRndMode ?");
	my $randType = popupMultChoice("Randomization Mode:","random;ascending;descending",$sene_applyRandSelRndMode);
	lx("!!user.value sene_applyRandSelRndMode $randType");
	if		($randType eq "random")		{$randType = 0;}
	elsif	($randType eq "ascending")	{$randType = 1;}
	elsif	($randType eq "descending")	{$randType = 2;}

	#get poly groupings
	my $sene_applyRandSelMtrlType = lxq("user.value sene_applyRandSelMtrlType ?");
	my $polyGroupings = popupMultChoice("Apply random material per selected:","poly;polyIsland;polyIslandVisible;uvIsland;part",$sene_applyRandSelMtrlType);
	lx("!!user.value sene_applyRandSelMtrlType {$polyGroupings}");
	getPolyPieces($polyGroupings,\@polys);

	#get selected materials (ptags)
	my @ptagList;
	my @maskSel = lxq("query sceneservice selection ? mask");
	if (@maskSel == 0){die("You don't have any masks selected in the shader tree and so I'm canceling the script");}
	push(@ptagList,lxq("item.channel ptag ? set {$_}")) for @maskSel;

	#apply materials
	srand;
	my $lastUsedIndice = -1;
	my $count = 0;
	my $maxCount = $#ptagList;
	if ($randType == 2){$count = $maxCount;}

	foreach my $key (sort { $getPolyPiecesGroups{$b} <=> $getPolyPiecesGroups{$a} } keys %getPolyPiecesGroups){
		lx("!!select.drop polygon");
		lx("!!select.element $mainlayer polygon add $_") for @{$getPolyPiecesGroups{$key}};

		if ($randType == 0){
			my $indice = int(rand($#ptagList + .5));
			if ($indice == $lastUsedIndice){
				$indice++;
				if ($indice > $maxCount){$indice = 0;}
			}
			$lastUsedIndice = $indice;

			lx("!!poly.setMaterial {$ptagList[$indice]}");
		}
		elsif ($randType == 1){
			lx("!!poly.setMaterial {$ptagList[$count]}");
			if ($count == $maxCount){	$count = 0;			}
			else					{	$count++;			}
		}else{
			lx("!!poly.setMaterial {$ptagList[$count]}");
			if ($count == 0)		{	$count = $maxCount;	}
			else					{	$count--;			}
		}
	}

	#put selection back
	lx("select.drop polygon");
	lx("select.element $mainlayer polygon add $_") for @polys;
}

#PROCEDURAL TEXTURE BROWSER (replaces images if any are selected)
sub prcBrws{
	#if any images are selected, ask if you want to replace with procedural
	my $txLayerCount = lxq("query sceneservice txLayer.n ? all");
	my @imageMaps;
	my $lastSelTxLayer = -1;

	#find selected images
	for (my $i=0; $i<$txLayerCount; $i++){
		if (lxq("query sceneservice txLayer.isSelected ? $i") == 1){
			$lastSelTxLayer = $i;
			my $type = lxq("query sceneservice txLayer.type ? $i");
			if ( ($type !~ /output/i) && ($type !~ /mask/i) && ($type !~ /material/i) && ($type !~ /shader/i)){
				push(@imageMaps,lxq("query sceneservice txLayer.id ? $i"));
			}
		}
	}

	#replace selected images
	if (@imageMaps > 0){
		my $count = $#imageMaps + 1;
		my $replaceImages = quickDialog("(" . $count . ") imageMaps are selected.  Convert these to the selected procedural?",yesNo,1,"","",99);
		if ($replaceImages eq "ok"){
			foreach my $id (@imageMaps){
				lx("item.setType {$miscArg} textureLayer");
			}
		}
	}

	#else add new image
	else{
		if		($miscArg eq "noise_simple")		{	lx("!!shader.create {noise}");		lx("!!item.channel noise\$type simple");		}
		elsif	($miscArg eq "noise_fractal")		{	lx("!!shader.create {noise}");														}
		elsif	($miscArg eq "noise_turbulence")	{	lx("!!shader.create {noise}");		lx("!!item.channel noise\$type turbulence");	}
		elsif	($miscArg eq "cellular_round")		{	lx("!!shader.create cellular");		lx("!!item.channel cellular\$type round");		}
		elsif	($miscArg eq "cellular_angular")	{	lx("!!shader.create cellular");														}
		elsif	($miscArg eq "dots_cube")			{	lx("!!shader.create dots");			lx("!!item.channel type cube");					}
		elsif	($miscArg eq "dots_hexagon")		{	lx("!!shader.create dots");			lx("!!item.channel type hexagon");				}
		else										{	lx("!!shader.create {$miscArg}");													}

		lx("!!texture.autoSize");
	}
}

sub hideByType{
	if		($_[0] eq "hide")				{	our $hideMode = 0;	}
	elsif	($_[0] eq "show")				{	our $hideMode = 1;	}
	elsif	($_[0] eq "toggle")				{	our $hideMode = -1;	}
	else									{	die("no args were submitted, so cancelling script");	}

	my $txLayerCount = lxq("query sceneservice txLayer.n ? all");
	for (my $i=0; $i<$txLayerCount; $i++){
		my $id = lxq("query sceneservice txLayer.id ? $i");
		my $type = lxq("query sceneservice txLayer.type ? $i");
		if ($type eq $miscArg){lx("shader.setVisible {$id} $hideMode");}
	}
}

sub hideByEffect{
	if		($_[0] eq "hide")				{	our $hideMode = 0;	}
	elsif	($_[0] eq "show")				{	our $hideMode = 1;	}
	elsif	($_[0] eq "toggle")				{	our $hideMode = -1;	}
	else									{	die("no args were submitted, so cancelling script");	}

	my $txLayerCount = lxq("query sceneservice txLayer.n ? all");
	for (my $i=0; $i<$txLayerCount; $i++){
		my $id = lxq("query sceneservice txLayer.id ? $i");
		my $effect = lxq("item.channel effect {?} set {$id}");
		if ($effect eq $miscArg){lx("shader.setVisible {$id} $hideMode");}
	}
}

sub hide{
	if		($_[0] eq "hideSel")			{	our $hideVal = 0;	}
	elsif	($_[0] eq "showSel")			{	our $hideVal = 1;	}
	elsif	($_[0] eq "showAll")			{	our $hideVal = 2;	}
	elsif	($_[0] eq "showOnlySel")		{	our $hideVal = 3;	}
	else									{	die("no args were submitted, so cancelling script");	}

	my $txLayerCount = lxq("query sceneservice txLayer.n ? all");
	for (my $i=0; $i<$txLayerCount; $i++){
		if ($hideVal == 2){
			my $id = lxq("query sceneservice txLayer.id ? $i");
			lx("shader.setVisible {$id} {1}");
		}elsif ($hideVal == 3){
			my $id = lxq("query sceneservice txLayer.id ? $i");
			if (lxq("query sceneservice txLayer.isSelected ? $i") == 1){
				lx("shader.setVisible {$id} {1}");
			}else{
				lx("shader.setVisible {$id} {0}");
			}
		}elsif (lxq("query sceneservice txLayer.isSelected ? $i") == 1){
			my $id = lxq("query sceneservice txLayer.id ? $i");
			lx("shader.setVisible {$id} {$hideVal}");
		}
	}
}

sub sel_bySameEffect{
	my %itemTypeTable;
		$itemTypeTable{"BaseShader"} = 1;
		$itemTypeTable{"cellular"} = 1;
		$itemTypeTable{"checker"} = 1;
		$itemTypeTable{"constant"} = 1;
		$itemTypeTable{"dots"} = 1;
		$itemTypeTable{"gradient"} = 1;
		$itemTypeTable{"grid"} = 1;
		$itemTypeTable{"imageMap"} = 1;
		$itemTypeTable{"mask"} = 1;
		$itemTypeTable{"noise"} = 1;
		$itemTypeTable{"renderOutput"} = 1;
		$itemTypeTable{"wood"} = 1;

	my $effect = "";
	my @itemSel = lxq("query sceneservice selection ? all");
	foreach my $id (@itemSel){
		if ($itemTypeTable{lxq("query sceneservice item.type ? {$id}")} == 1){
			$effect = lxq("item.channel effect {?} set {$id}");
			last;
		}
	}
	if ($effect eq ""){die("You don't appear to have any shader tree item selected, so I'm cancelling the script");}

	my $txLayerCount = lxq("query sceneservice txLayer.n ? all");
	for (my $i=0; $i<$txLayerCount; $i++){
		my $id = lxq("query sceneservice txLayer.id ? $i");
		if (lxq("item.channel effect {?} set {$id}") eq $effect){
			lx("select.subItem {$id} add textureLayer;render;environment;light;camera");
		}
	}
}


sub st_findReplace{
	my @masks = lxq("query sceneservice selection ? mask");
	my $initialPtag = lxq("item.channel ptag ? set {$masks[0]}");
	my $text_find = quickDialog("text to replace:",string,$initialPtag,"","");
	my $text_replace = quickDialog("replace with this",string,$text_find,"","");

	foreach my $mask (@masks){
		my $ptag = lxq("item.channel ptag ? set {$mask}");
		my $newPtag = $ptag;
		$newPtag =~ s/$text_find/$text_replace/g;
		lx("material.reassign {$ptag} {$newPtag}");
		lx("select.subItem {$mask} set textureLayer;render;environment;light;camera;mediaClip;txtrLocator");
		lx("!!item.name {} mask");
	}

	lx("select.drop item");
	lx("select.subItem {$_} add textureLayer;render;environment;light;camera;mediaClip;txtrLocator") for @masks;
}

sub copyPasteTxLocators{
	my @txLocators = lxq("query sceneservice selection ? locator");
	if (@txLocators > 1){
		lx("[->] : Assigning all the selected images, the texture locator that the last selected image had");
		my $name = lxq("query sceneservice item.name ? @txLocators[-1]");
		lx("texture.setLocator locator:{$name}");
	}

	#my @selection = lxq("query sceneservice selection ? all");
	#my @foundTextures;
#
	#foreach my $id (@selection){
		#if ((lxq("query sceneservice item.type ? $id") eq "noise")    ||
			#(lxq("query sceneservice item.type ? $id") eq "grid")     ||
			#(lxq("query sceneservice item.type ? $id") eq "gradient") ||
			#(lxq("query sceneservice item.type ? $id") eq "dots")     ||
			#(lxq("query sceneservice item.type ? $id") eq "checker")  ||
			#(lxq("query sceneservice item.type ? $id") eq "imageMap") ||
			#(lxq("query sceneservice item.type ? $id") eq "cellular")){
#
			#push(@foundTextures,$id);
		#}
	#}
#
	#if (@foundTextures < 1){die("You don't have any images or procedural selected, so I can't reassign their texture locators.");}
#
	##lx("select.subItem {@foundTextures[-1]} set textureLayer;render;environment;mediaClip");
	#my $name = lxq("query sceneservice txLayer.name ? @foundTextures[-1]");
	#my $channelCount = lxq("query sceneservice channel.n ?");
	#for (my $i=0; $i<$channelCount; $i++){
		#my $channel = lxq("query sceneservice channel.name ? $i");
		#my $value = lxq("query sceneservice channel.value ? $i");
		#lxout("channel $i = $channel = $value");
	#}
#
	##my $locatorID = lxq("query sceneservice texture.setLocator ? @foundTextures[-1]");
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
#requires listTouchingVisiblePolys sub
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

#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#SET UP THE USER VALUE OR VALIDATE IT #modded to have dontOverride feature
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#userValueTools(name,type,life,username,list,listnames,argtype,min,max,action,value,dontOverride);
sub userValueTools{
	if (lxq("query scriptsysservice userValue.isdefined ? @_[0]") == 0){
		lxout("Setting up @_[0]--------------------------");
		lxout("Setting up @_[0]--------------------------");
		lxout("0=@_[0],1=@_[1],2=@_[2],3=@_[3],4=@_[4],5=@_[6],6=@_[6],7=@_[7],8=@_[8],9=@_[9],10=@_[10],11=@_[11]");
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
			if (@_[10] eq ""){lxout("woah.  there's no value in the userVal sub!");	}		}
		elsif (@_[10] == ""){lxout("woah.  there's no value in the userVal sub!");		}
								lx("user.value [@_[0]] [@_[10]]");		lxout("running user value setup 10");
	}else{
		#STRING-------------
		if ((@_[1] eq "string") && (@_[11] != 1)){
			if (lxq("user.value @_[0] ?") eq ""){
				lxout("user value @_[0] was a blank string");
				lx("user.value [@_[0]] [@_[10]]");
			}
		}
		#BOOLEAN------------
		elsif (@_[1] eq "boolean"){

		}
		#LIST---------------
		elsif ((@_[4] ne "") && (@_[11] != 1)){
			if (lxq("user.value @_[0] ?") == -1){
				lxout("user value @_[0] was a blank list");
				lx("user.value [@_[0]] [@_[10]]");
			}
		}
		#ALL OTHER TYPES----
		elsif ((lxq("user.value @_[0] ?") == "") && (@_[11] != 1)){
			lxout("user value @_[0] was a blank number");
			lx("user.value [@_[0]] [@_[10]]");
		}
	}
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#QUICK DIALOG SUB (modded to not die if issued last argument that equals 99)
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
		if ( (lxres != 0) && ($_[5] != 99) ){	die("The user hit the cancel button");	}
		return(lxq("user.value seneTempDialog ?"));
	}
}

##------------------------------------------------------------------------------------------------------------
##------------------------------------------------------------------------------------------------------------
#POPUP MULTIPLE CHOICE (ver 2)
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
	return(lxq("user.value seneTempDialog2 ?"));
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


