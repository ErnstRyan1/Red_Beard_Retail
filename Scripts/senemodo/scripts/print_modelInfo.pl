#perl
#This script is to print info
#ver 1.21

my $mainlayer = lxq("query layerservice layers ? main");
my $pi=3.1415926535897932384626433832795;
userValueTools(senePrintModelInfoBbox,string,config,senePrintModelInfoBbox," ","","",xxx,xxx,"","");

#=====================================================================================================================================
#=====================================================================================================================================
#=====================================================================================================================================
#=====================================================================================================================================
#===																SCRIPT ARGUMENTS																====
#=====================================================================================================================================
#=====================================================================================================================================
#=====================================================================================================================================
#=====================================================================================================================================
foreach my $arg (@ARGV){
	if		($arg eq "edgeAngle")				{	printEdgeAngle();			}
	elsif	($arg eq "edgeLength")				{	printEdgeLength();			}
	elsif	($arg eq "material")				{	printMaterial();			}
	elsif	($arg eq "popupMaterial")			{	printPopupMaterial();		}
	elsif	($arg eq "printScene")				{	printSceneInfo();			}
	elsif	($arg eq "children")				{	printChildren();			}
	elsif	($arg eq "vertCenter")				{	printVertPos();				}
	elsif	($arg eq "edgeCenter")				{	printEdgePos();				}
	elsif	($arg eq "polyCenter")				{	printPolyPos();				}
	elsif	($arg eq "itemID")					{	printItemIDs();				}
	elsif	($arg eq "bboxSize")				{	printBBOXSize();			}
	elsif	($arg eq "renamePolyTags")			{	renamePolyTags();			}
	elsif	($arg eq "imgParents")				{	imgParents();				}
	elsif	($arg eq "nonExstMats")				{	nonExstMats();				}
	elsif	($arg eq "whichPolyMats")			{	whichPolyMats();			}
	elsif	($arg eq "selTheseMasks")			{	selTheseMasks();			}
	elsif	($arg eq "clipNamesSort")			{	clipNamesSort();			}
	elsif	($arg eq "sortedMaterialNames")		{	sortedMaterialNames();		}
	elsif	($arg eq "sortedPtagMasks")			{	sortedPtagMasks();			}
	elsif	($arg eq "sortedPtags")				{	sortedPtags();				}
	elsif	($arg eq "sortedMasksWNoPtag")		{	sortedMasksWNoPtag();		}
	elsif	($arg eq "clipFiles")				{	printClipFiles();			}
	elsif	($arg eq "printAvgEdgeLength")		{	printAvgEdgeLength();		}
	elsif	($arg eq "printAvgEdgeRowLength")	{	printAvgEdgeRowLength();	}
	elsif	($arg eq "printEdgeDP")				{	printEdgeDP();				}
	elsif	($arg eq "renamePolyMaterial")		{	renamePolyMaterial();		}
	elsif	($arg eq "printUVBBOX")				{	printUVBBOX();				}
	elsif	($arg eq "listChannels")			{	listChannels();				}
	elsif	($arg eq "listXfrmChannels")		{	listXfrmChannels();			}
	elsif	($arg eq "listAllItems")			{	listAllItems();				}
	elsif	($arg eq "listAllTxLayers")			{	listAllTxLayers();			}
	elsif	($arg eq "listVmaps")				{	listVmaps();				}
	elsif	($arg eq "printVmapValues")			{	printVmapValues();			}
	elsif	($arg eq "printPolySel")			{	printPolySel();				}
	elsif	($arg eq "printAllItemPolyTypes")	{	printAllItemPolyTypes();	}
	elsif	($arg eq "printTotalImageSize")		{	printTotalImageSize();		}
	elsif	($arg eq "polyNrml_DP_fromCamPos")	{	polyNrml_DP_fromCamPos();	}
	elsif	($arg eq "printSelParents")			{	printSelParents();			}
	elsif	($arg eq "printSelChildren")		{	printSelChildren();			}
	elsif	($arg eq "printPolyArea")			{	printPolyArea();			}
	elsif	($arg eq "printRotOrder")			{	printRotOrder();			}
}






#=====================================================================================================================================
#=====================================================================================================================================
#=====================================================================================================================================
#=====================================================================================================================================
#===																MAIN ROUTINES																		====
#=====================================================================================================================================
#=====================================================================================================================================
#=====================================================================================================================================
#=====================================================================================================================================

sub printAllItemPolyTypes{
	my $layerCount = lxq("query layerservice layer.n ? all");
	for (my $i=1; $i<$layerCount+1; $i++){
		my $layerName = lxq("query layerservice layer.name ? $i");
		my $polyCount = lxq("query layerservice poly.n ? all");
		my %polyTypeTable;
		for (my $u=0; $u<$polyCount; $u++){
			my $type = lxq("query layerservice poly.type ? $u");
			$polyTypeTable{$type} = 1;
		}
		
		my $string;
		foreach my $key (keys %polyTypeTable){
			$string .= " " . $key;
		}
		#lxout("$string : $layerName");
		
		if (($string =~ /face/i) && ($string =~ /sub/i)){
			my $id = lxq("query layerservice layer.id ? $i");
			lxout("yes : $layerName : $id");
			lx("select.subItem {$id} add mesh;meshInst;camera;light;txtrLocator;backdrop;groupLocator;replicator;surfGen;locator;deform;locdeform;deformGroup;deformMDD2;morphDeform;itemInfluence;genInfluence;deform.wrap;softLag;modSculpt;ABCCurvesDeform.sample;ABCdeform.sample;meshInst;defaultShader;defaultShader 0 0");
		}
	}
}


sub printRotOrder{
	my %rotOrderTable;
	my @selection = lxq("query sceneservice selection ? locator");
	foreach my $id (@selection){
		my $name = lxq("query sceneservice item.name ? {$id}");
		my $xfrmID = lxq("query sceneservice item.xfrmRot ? {$id}");
		my $xfrmName = lxq("query sceneservice item.name ? {$xfrmID}");
		if ($xfrmID ne ""){
			my $order = lxq("item.channel order {?} set {$xfrmID}");
			push(@{$rotOrderTable{$order}}, "$order ; $id ; $name");
		}else{
			push(@{$rotOrderTable{noOrder}}, "$order ; $id ; $name");
		
		}
	}
	
	foreach my $order (keys %rotOrderTable){
		lxout("=====================================");
		lxout("order = $order");
		lxout("=====================================");
		
		for (my $i=0; $i<@{$rotOrderTable{$order}}; $i++){
			lxout("${$rotOrderTable{$order}}[$i]");
		}
	}
	
	my $string;
	$string .= $_ . ";" for (keys %rotOrderTable);
	
	my $answer = popupMultChoice("Select any of these items?",$string,0);
	if ($answer ne ""){
		lx("!!select.drop item");
		
		for (my $i=0; $i<@{$rotOrderTable{$answer}}; $i++){
			my @data = split(/ ; /, ${$rotOrderTable{$answer}}[$i]);
			lx("!!select.item {$data[1]} add");
		}
	}
}


sub printPolyArea{
	my @polys = lxq("query layerservice polys ? selected");
	foreach my $poly (@polys){
		my $area = getPolyArea($poly);
		lxout("$poly area = $area");
	}
}

sub printEdgeDP{
	my @edges = lxq("query layerservice edges ? selected");
	foreach my $edge (@edges){
		my @polyList = lxq("query layerservice edge.polyList ? $edge");
		my @normal1 = lxq("query layerservice poly.normal ? $polyList[0]");
		my @normal2 = lxq("query layerservice poly.normal ? $polyList[1]");
		my $dp = dotProduct(\@normal1,\@normal2);
		
		lxout("edge=$edge <> dp=$dp");
	}
}

sub printSelParents{
	my @items = lxq("query sceneservice selection ? all");
	lxout("============================");
	lxout("Printing Parents:");
	lxout("============================");
	foreach my $id (@items){
		my $name = lxq("query sceneservice item.name ? {$id}");
		my @children = lxq("query sceneservice item.parent ? {$id}");
		lxout("$name parent = @children");
	}
}

sub printSelChildren{
	my @items = lxq("query sceneservice selection ? all");
	lxout("============================");
	lxout("Printing Children:");
	lxout("============================");
	foreach my $id (@items){
		my $name = lxq("query sceneservice item.name ? {$id}");
		my @children = lxq("query sceneservice item.children ? {$id}");
		lxout("$name children = @children");
	}
}

sub listVmaps{
	my @layerSel = lxq("query layerservice layers ? selected");
	foreach my $layerIndice (@layerSel){
		my $layerName = lxq("query layerservice layer.name ? {$layerIndice}");
		my $vmapCount = lxq("query layerservice vmap.n ? all");
		
		lxout("====================================");
		lxout("layer = $layerName");
		lxout("====================================");
		for (my $i=0; $i<$vmapCount; $i++){
			my $name = lxq("query layerservice vmap.name ? $i");
			my $type = lxq("query layerservice vmap.type ? $i");
			lxout("$i <> name = $name <> type = $type");
		}
	}
}

sub printVmapValues{
	my @layerSel = lxq("query layerservice layers ? selected");
	foreach my $layerIndice (@layerSel){
		my $layerName = lxq("query layerservice layer.name ? {$layerIndice}");
		my $vmapCount = lxq("query layerservice vmap.n ? all");
		
		lxout("====================================");
		lxout("layer = $layerName");
		lxout("====================================");
		for (my $i=0; $i<$vmapCount; $i++){
			my $name = lxq("query layerservice vmap.name ? $i");
			my $type = lxq("query layerservice vmap.type ? $i");
			lxout("$i <> name = $name <> type = $type");
			
			if (lxq("select.typeFrom {vertex;edge;polygon;item} ?")){
				my @verts = lxq("query layerservice verts ? selected");
				foreach my $vert (@verts){
					my @vmapValue = lxq("query layerservice vert.vmapValue ? $vert");
					lxout("    vert=$vert : vmapValue=@vmapValue");
				}
			}elsif (lxq("select.typeFrom {polygon;item;vertex;edge} ?")){
				my @polys = lxq("query layerservice polys ? selected");
				foreach my $poly (@polys){
					my @vmapValues = lxq("query layerservice poly.vmapValue ? $poly");
					lxout("    poly=$poly : vmapValues=@vmapValues");
				}
			}
		}
	}
}

sub polyNrml_DP_fromCamPos{
	lx("!!select.itemType polyRender");
	my $cameraID = lxq("render.camera ?");
	my @camWorldPos = lxq("query sceneservice item.worldPos ? {$cameraID}");
	
	my $mainlayer = lxq("query layerservice layers ? main");
	my @polys = lxq("query layerservice polys ? selected");
	foreach my $poly (@polys){
		my @pos = lxq("query layerservice poly.pos ? $poly");
		my @normal = lxq("query layerservice poly.normal ? $poly");
		my @camToPolyVec = unitVector(arrMath(@camWorldPos,@pos,subt));
		my $dp = dotProduct(\@normal,\@camToPolyVec);
		lxout("poly ($poly) : dp = $dp");
	}
}


sub printTotalImageSize{
	my $clipCount = lxq("query layerservice clip.n ? all");
	my $totalSize;
	my %clipSizeTable;
	for (my $i=0; $i<$clipCount; $i++){
		my $clipInfo = lxq("query layerservice clip.info ? $i");
		my $clipName = lxq("query layerservice clip.name ? $i");
		my @clipSize = split(/\D+/, $clipInfo);
		my $width = @clipSize[1];
		my $height = @clipSize[2];

		my $size = $width * $height;
		$totalSize += $size;

		my $key;
		if ($height > $width)	{	$key = $height . "," . $width;	}
		else					{	$key = $width . "," . $height;	}
		push(@{$clipSizeTable{$key}},$clipName);
	}

	foreach my $key (sort { $a <=> $b } keys %clipSizeTable){
		foreach my $name (sort @{$clipSizeTable{$key}}){
			lxout("$key : $name");
		}
	}

	lxout("========================================================");
	lxout("There are $totalSize pixels total");
	lxout("========================================================");
	my $count_2048 = int($totalSize / 4194304);
	my $count_1024 = int($totalSize / 1048576);
	my $count_512 = int($totalSize / 262144);
	my $count_256 = int($totalSize / 65536);
	my $count_128 = int($totalSize / 16384);
	$totalSize = int(sqrt($totalSize));
	lxout("That equates to having one ($totalSize x $totalSize) image loaded");
	lxout("or $count_2048 (2048 x 2048)s");
	lxout("or $count_1024 (1024 x 1024)s");
	lxout("or $count_512 (512 x 512)s");
	lxout("or $count_256 (256 x 256)s");
	lxout("or $count_128 (128 x 128)s");
}

sub listAllTxLayers{
	my $txLayerCount = lxq("query sceneservice txLayer.n ? all");
	for (my $i=0; $i<$txLayerCount; $i++){
		my $name = lxq("query sceneservice txLayer.name ? $i");
		my $type = lxq("query sceneservice txLayer.type ? $i");
		my $id = lxq("query sceneservice txLayer.id ? $i");
		my $effect = lxq("item.channel effect {?} set {$id}");
		lxout("$i : $name ($id) = $type ($effect)");
	}
}

sub listAllItems{
	my $itemCount = lxq("query sceneservice item.n ? all");
	for (my $i=0; $i<$itemCount; $i++){
		my $name = lxq("query sceneservice item.name ? $i");
		my $type = lxq("query sceneservice item.type ? $i");
		my $id = lxq("query sceneservice item.id ? $i");
		lxout("$name ($id) = $type");
	}
}

sub listXfrmChannels{
	my @selection = lxq("query sceneservice selection ? all");
	foreach my $id (@selection){
		my $name = lxq("query sceneservice item.name ? {$id}");
		lxout("----------------------------------------");
		lxout("name = $name");
		lxout("----------------------------------------");
		my $xfrmPos = lxq("query sceneservice item.xfrmPos ? {$id}");
		my $xfrmRot = lxq("query sceneservice item.xfrmRot ? {$id}");
		my $xfrmScl = lxq("query sceneservice item.xfrmScl ? {$id}");
		my @xfrms = ($xfrmPos,$xfrmRot,$xfrmScl);
		foreach my $xid (@xfrms){
			my $xfrmName = lxq("query sceneservice item.name ? {$xid}");
			lxout("    transform = $xfrmName");
			my $channelCount = lxq("query sceneservice channel.n ?");
			for (my $i=0; $i<$channelCount; $i++){
				my $channelName = lxq("query sceneservice channel.name ? $i");
				my $value = lxq("query sceneservice channel.value ? $i");
				lxout("        $channelName = $value");
			}
		}
	}
}

sub listChannels{
	my @selection = lxq("query sceneservice selection ? all");
	foreach my $id (@selection){
		my $name = lxq("query sceneservice item.name ? {$id}");
		my $channelCount = lxq("query sceneservice channel.n ?");
		my $type = lxq("query sceneservice item.type ? $i");
		lxout("========================================");
		lxout("---name=$name <> type=$type---");
		lxout("========================================");
		for (my $i=0; $i<$channelCount; $i++){
			my $channelName = lxq("query sceneservice channel.name ? $i");
			my $channelValue = lxq("query sceneservice channel.value ? $i");
			lxout("$channelName = $channelValue");
		}
	}
}


sub printUVBBOX{
	our @polys = lxq("query layerservice polys ? selected");
	&selectVmap;
	&splitUVGroups;
	foreach my $key (keys %touchingUVList){
		my $width = ${$uvBBOXList{$key}}[2] - ${$uvBBOXList{$key}}[0];
		my $height = ${$uvBBOXList{$key}}[3] - ${$uvBBOXList{$key}}[1];
		lxout("===============================================");
		lxout("bbox = @{$uvBBOXList{$key}}");
		lxout("w = $width");
		lxout("h = $height");
	}
}

sub renamePolyMaterial{
	my @polys = lxq("query layerservice polys ? selected");
	my $material = lxq("query layerservice poly.material ? @polys[-1]");
	my $newName = quickDialog($material,string);
	if ($newName eq ""){die;}
	lx("poly.renameMaterial {$material} {$newName}");
	#lx("scene.save");
	#lx("scene.close");
}

sub printAvgEdgeRowLength{
	my $avgLength;
	my @edges = lxq("query layerservice edges ? selected");
	sortRowStartup(edgesSelected,@edges);

	for (my $i = 0; $i < @vertRowList; $i++) {
		lxout("vertRow = @vertRowList[$i]");
		my $vertRowLength = 0;
		my @verts = split (/[^0-9]/, @vertRowList[$i]);
		for ($u = 0; $u < $#verts ; $u++){
			my $edge = "(".@verts[$u].",".@verts[$u+1].")";
			my $length = lxq("query layerservice edge.length ? $edge");
			$vertRowLength += lxq("query layerservice edge.length ? $edge");
		}
		$avgLength += $vertRowLength;
	}

	$avgLength /= @vertRowList;
	popup("avgLength = $avgLength");
}

sub printAvgEdgeLength{
	my @edges = lxq("query layerservice edges ? selected");
	my $avg;
	foreach my $edge (@edges){
		my $length = lxq("query layerservice edge.length ? $edge");
		$avg += $length;
	}
	$avg = $avg/@edges;

	popup("Average length = $avg");
}

sub printClipFiles{
	my $clips = lxq("query layerservice clip.n ?");
	my $message;
	for (my $i=0; $i<$clips; $i++){
		if (lxq("query sceneservice clip.isSelected ? $i") == 1){
			my $file = lxq("query layerservice clip.file ? $i");
			$message .= $i." : ".$file."\n";
		}
	}
	if ($message ne ""){popup("$message");}
}

sub printItemIDs{
	my $items = lxq("query sceneservice item.n ? all");
	for (my $i=0; $i<$items; $i++){
		my $name = lxq("query sceneservice item.name ? $i");
		my $type = lxq("query sceneservice item.type ? $i");
		my $id = lxq("query sceneservice item.id ? $i");
		lxout("($i) $id              $name          $type");
		if ($id eq $name){
			popup("woah.  item $i's name is the same as it's item id ($name)");
		}
	}
}

sub printVertPos{
	my @verts = lxq("query layerservice verts ? selected");
	for (my $i=0; $i<@verts; $i++){
		my @pos = lxq("query layerservice vert.pos ? $verts[$i]");
		lxout("vert $i pos = @pos");
	}
}

sub printEdgePos{
	my @edges = lxq("query layerservice edges ? selected");
	for (my $i=0; $i<@edges; $i++){
		my @pos = lxq("query layerservice edge.pos ? $edges[$i]");
		lxout("edge $i pos = @pos");
	}
}

sub printPolyPos{
	my @polys = lxq("query layerservice polys ? selected");
	for (my $i=0; $i<@polys; $i++){
		my @pos = lxq("query layerservice poly.pos ? $polys[$i]");
		lxout("poly $i pos = @pos");
	}
}

sub printChildren{
	my $items = lxq("query sceneservice item.n ? all");

	for (my $i=0; $i<$items; $i++){
		my $name = lxq("query sceneservice item.name ? $i");
		my $type = lxq("query sceneservice item.type ? $i");
		my $parent = lxq("query sceneservice item.parent ? $i");
		my @children = lxq("query sceneservice item.children ? $i");
		lxout("($i) ($type) = $name ");
		if ($parent ne ""){lxout("   parent = $parent");}
		for (my $i=0; $i<@children; $i++){
			my $name = lxq("query sceneservice item.name ? $i");
			lxout("    child = $name");
		}
	}
}

sub printPopupMaterial{
	my %materials;
	my @polys = lxq("query layerservice polys ? selected");
	my $materialString;
	foreach my $poly (@polys){
		my $material = lxq("query layerservice poly.material ? $poly");
		$materials{$material} = 1;
	}
	foreach my $key (keys %materials){$materialString .= "\n" . $key;}
	popup("materials = $materialString");
}

sub printMaterial{
	my @polys = lxq("query layerservice polys ? selected");
	foreach my $poly (@polys){
		my @tags = lxq("query layerservice poly.tags ? $poly");
		my @types = lxq("query layerservice poly.tagTypes ? $poly");
		lxout("poly = $poly\n");
		for (my $i=0; $i<@tags; $i++){
			lxout("          @types[$i] = @tags[$i]");
		}
	}
}

sub printEdgeAngle{
	my @edges;
	my @tempEdgeList = lxq("query layerservice selection ? edge");
	foreach my $edge (@tempEdgeList){	if ($edge =~ /\($mainlayer/){push(@edges,$edge);}	}
	s/\(\d{0,},/\(/  for @edges;

	foreach my $edge (@edges){
		my @polys = lxq("query layerservice edge.polyList ? $edge");
		if (@polys < 2){next;}
		my @normal1 = lxq("query layerservice poly.normal ? @polys[0]");
		my @normal2 = lxq("query layerservice poly.normal ? @polys[1]");
		my $dotProduct = (@normal1[0]*@normal2[0]+@normal1[1]*@normal2[1]+@normal1[2]*@normal2[2]);
		my $radian = acos($dotProduct);
		my $angle = ($radian*180)/$pi;

		lxout("edge=$edge <> DP = $dotProduct <> angle=$angle");
	}
}

sub printEdgeLength{
	my @edges;
	my @tempEdgeList = lxq("query layerservice selection ? edge");
	foreach my $edge (@tempEdgeList){	if ($edge =~ /\($mainlayer/){push(@edges,$edge);}	}
	s/\(\d{0,},/\(/  for @edges;

	foreach my $edge (@edges){
		my $length = lxq("query layerservice edge.length ? $edge");
		lxout("$edge = $length");
	}
}

sub printPolySel{
	my %layerTable;
	my $layerCount = lxq("query layerservice layer.n ? all");
	for (my $i=1; $i<$layerCount+1; $i++){
		my $layerName = lxq("query layerservice layer.name ? $i");
		$layerTable{$i}{"name"} = $layerName;
	}

	my @selection = lxq("query layerservice selection ? poly");
	foreach my $elem (@selection){
		my @selInfo = split(/[^0-9]/, $elem);
		push(@{$layerTable{$selInfo[1]}{"elemList"}},$selInfo[2]);
	}


	foreach my $key (keys %layerTable){
		if (@{$layerTable{$key}{"elemList"}} > 0){
			my $name = $layerTable{$key}{"name"};
			for (my $i=0; $i<@{$layerTable{$key}{"elemList"}}; $i++){
				lxout("$name : @{$layerTable{$key}{\"elemList\"}}[$i]");
			}
		}
	}

	lxout("=============================================");
	lxout("selected polys are in these layers :");
	lxout("=============================================");
	foreach my $key (keys %layerTable){
		if (@{$layerTable{$key}{"elemList"}} > 0){
			my $name = $layerTable{$key}{"name"};
			lxout("$name");
		}
	}
}

sub printSceneInfo{
	my %list;
	my $items = lxq("query sceneservice item.n ?");
	for (my $i=0; $i<$items; $i++){
		my $type = lxq("query sceneservice item.type ? $i");
		$list{$type}++;
	}

	#meshes
	lxout("----------------------MESHES----------------------");
	if ($list{mesh} > 0)			{	lxout("Meshes         = $list{mesh}");				}
	if ($list{meshInst} > 0)		{	lxout("Instances      =	$list{meshInst}");			}

	#groups
	lxout("----------------------GROUPS----------------------");
	if ($list{groupLocator} > 0)	{	lxout("Groups          = $list{groupLocator}");		}
	if ($list{locator} > 0)			{	lxout("Locators        = $list{locator}");			}

	#lights
	my $allLights = $list{areaLight} + $list{cylinderLight} + $list{domeLight} + $list{photometryLight}+ $list{pointLight}+ $list{spotLight}+ $list{sunLight};
	lxout("----------------------LIGHTS----------------------");
	if ($allLights > 0)				{	lxout("ALL Lights     = $allLights");				}
	if ($list{areaLight} > 0)		{	lxout("Area Lights   = $list{areaLight}");			}
	if ($list{cylinderLight} > 0)	{	lxout("Cyl Lights      = $list{cylinderLight}");	}
	if ($list{domeLight} > 0)		{	lxout("Dome Lights  = $list{domeLight}");			}
	if ($list{photometryLight} > 0)	{	lxout("PhotoLights   = $list{photometryLight}");	}
	if ($list{pointLight} > 0)		{	lxout("PointLights    = $list{pointLight}");		}
	if ($list{spotLight} > 0)		{	lxout("Spot Lights    = $list{spotLight}");			}
	if ($list{sunLight} > 0)		{	lxout("Sun Lights     = $list{sunLight}");			}

	#cameras
	lxout("----------------------CAMERAS----------------------");
	if ($list{camera} > 0)			{	lxout("Cameras       = $list{camera}");				}

	#shaders
	lxout("--------------------MATERIALS----------------------");
	if ($list{defaultShader} > 0)	{	lxout("Shaders         = $list{defaultShader}");	}
	if ($list{mask} > 0)			{	lxout("Masks            = $list{mask}");			}
	if ($list{advancedMaterial} > 0){	lxout("Materials        = $list{advancedMaterial}");}
	if ($list{process} > 0)			{	lxout("Processes      = $list{process}");			}
	if ($list{celluar} > 0)			{	lxout("Cellular         = $list{celluar}");			}
	if ($list{checker} > 0)			{	lxout("Checker         = $list{checker}");			}
	if ($list{constant} > 0)		{	lxout("Constants      = $list{constant}");			}
	if ($list{dots} > 0)			{	lxout("Dots               = $list{dots}");			}
	if ($list{gradient} > 0)		{	lxout("Gradient         = $list{gradient}");		}
	if ($list{grid} > 0)			{	lxout("Grid                = $list{grid}");			}
	if ($list{noise} > 0)			{	lxout("Noise             = $list{noise}");			}
	if ($list{vmapTexture} > 0)		{	lxout("Vmap             = $list{vmapTexture}");	}
	if ($list{wood} > 0)			{	lxout("Wood             = $list{wood}");			}

	#images
	lxout("--------------------IMAGES----------------------");
	my $clipCount = lxq("query layerservice clip.n ? all");
	if ($clipCount > 0)				{	lxout("Images          = $clipCount");			}
	if ($list{txtrLocator} > 0)		{	lxout("TxtrLocators  = $list{txtrLocator}");		}
}

sub renamePolyTags{
	my @layers = lxq("query layerservice layers ? all");
	my @fgLayers = lxq("query layerservice layers ? fg");
	my @bgLayers = lxq("query layerservice layers ? bg");
	$_ = lxq("query layerservice layer.id ? $_") for @layers;
	$_ = lxq("query layerservice layer.id ? $_") for @fgLayers;
	$_ = lxq("query layerservice layer.id ? $_") for @bgLayers;

	my @polys = lxq("query layerservice selection ? poly");

	foreach my $poly (@polys){
		my @polyInfo = split(/,/, $poly);
		my $layerName = lxq("query layerservice layer.name ? @polyInfo[0]");
		my @tags = lxq("query layerservice poly.tags ? @polyInfo[1]");
		quickDialog("New Material Name",string,@tags[0],"","");
		my $newName = lxq("user.value seneTempDialog ?");


		foreach my $layer (@layers){
			lx("select.subItem [$layer] set mesh;meshInst;camera;light;txtrLocator;backdrop;groupLocator [0] [1]");
			lx("poly.renameMaterial {@tags[0]} {$newName}");
		}
	}

	#restore layer visibility
	for (my $i=0; $i<@fgLayers; $i++){
		if ($i != 0){lx("select.subItem [@fgLayers[$i]] add mesh;meshInst;camera;light;txtrLocator;backdrop;groupLocator [0] [1]");}
		else		{lx("select.subItem [@fgLayers[$i]] set mesh;meshInst;camera;light;txtrLocator;backdrop;groupLocator [0] [1]");}
	}
	lx("layer.setVisibility [$_] [1] [1]") for @bgLayers;
}

sub printBBOXSize{
	my @bbox;
	my @verts;

	if    (lxq( "select.typeFrom {vertex;edge;polygon;item} ?" )){
		@verts = lxq("query layerservice verts ? selected");
	}
	elsif (lxq( "select.typeFrom {edge;polygon;item;vertex} ?" )){
		my %vertTable;
		my @edges = lxq("query layerservice edges ? selected");
		foreach my $edge (@edges){
			my @verts = lxq("query layerservice edge.vertList ? $edge");
			foreach my $vert (@verts){
				$vertTable{$vert}=1;
			}
		}

		foreach my $key (keys %vertTable){
			push(@verts,$key);
		}
	}
	elsif (lxq( "select.typeFrom {polygon;item;vertex;edge} ?" )){
		my %vertTable;
		my @polys = lxq("query layerservice polys ? selected");
		foreach my $poly (@polys){
			my @verts = lxq("query layerservice poly.vertList ? $poly");
			foreach my $vert (@verts){
				$vertTable{$vert}=1;
			}
		}
		foreach my $key (keys %vertTable){
			push(@verts,$key);
		}
	}

	@bbox = boundingbox(@verts);
	@bboxSize = ( abs(@bbox[3]-@bbox[0]) , abs(@bbox[4]-@bbox[1]) , abs(@bbox[5]-@bbox[2]) );
	@bboxCenter = ( .5*(@bbox[0]+@bbox[3]) , .5*(@bbox[1]+@bbox[4]) , .5*(@bbox[2]+@bbox[5]) );
	lxout("bbox X : size=(@bboxSize[0]) <> positions=(@bbox[0],@bbox[3])");
	lxout("bbox Y : size=(@bboxSize[1]) <> positions=(@bbox[1],@bbox[4])");
	lxout("bbox Z : size=(@bboxSize[2]) <> positions=(@bbox[2],@bbox[5])");
	lxout("bbox C : @bboxCenter");
	popup("bboxSize = @bboxSize\nbboxCenter = @bboxCenter");
	my $string = "SizX=$bboxSize[0], SizY=$bboxSize[1], SizeZ=$bboxSize[2], CenterX=$bboxCenter[0], CenterY=$bboxCenter[1], CenterZ=$bboxCenter[2]";
	lx("user.value senePrintModelInfoBbox {$string}");
	lx("!!layout.createOrClose cookie:[sen_bboxDisplay] title:[sen_bboxDisplay] layout:[sen_bboxDisplay] x:[500] y:[500] width:[1265] height:[200] persistent:[1]");
}

sub imgParents{
	lxout("===========================================================================================");
	lxout("===========================================================================================");
	lxout("printing all images in shader tree that are dupes and asking to delete all unused images");
	lxout("===========================================================================================");
	lxout("===========================================================================================");

	my %txLayers;
	my @temp;
	lxout("Duplicates=======================================");

	my $txLayers = lxq("query sceneservice txLayer.n ?");
	for (my $i=0; $i<$txLayers; $i++){
		if (lxq("query sceneservice txLayer.type ? $i") eq "imageMap"){
			my $name = lxq("query sceneservice txLayer.name ? $i");
			my $parent = lxq("query sceneservice txLayer.parent ? $i");
			push(@temp,$name);
			push(@{$txLayers{$name}}, $parent);
		}
	}

	foreach my $name (sort @temp){
		if ($name =~ /\(/){
			lxout("name = $name");
		}
	}

	lxout("Unused Images====================================");
	my $clips = lxq("query sceneservice clip.n ? all");
	my @unusedImages;
	for (my $i=0; $i<$clips; $i++){
		my $name = lxq("query sceneservice clip.name ? $i");
		$name = "Image: ".$name;
		if (!exists $txLayers{$name}){
			my $id = lxq("query sceneservice clip.id ? $i");
			push(@unusedImages, $id);
			lxout("This clip isn't being used : $name");
		}
	}

	if (@unusedImages > 0){
		popup("There are $#unusedImages+1 unused Images.\nDo you wish to delete them?");
		for (my $i=0; $i<@unusedImages; $i++){
			if ($i > 0){
				lx("select.subItem [@unusedImages[$i]] add mediaClip");
			}else{
				lx("select.subItem [@unusedImages[$i]] set mediaClip");
			}
		}
		lx("clip.delete");
	}
}

sub nonExstMats{
	lxout("===========================================================================================");
	lxout("===========================================================================================");
	lxout("printing all ptags that exist but don't have materials in the shader tree");
	lxout("===========================================================================================");
	lxout("===========================================================================================");

	my $txLayers = lxq("query sceneservice txLayer.n ?");
	my @layers = lxq("query layerservice layers ? all");
	my @fgLayers = lxq("query layerservice layers ? fg");
	my @bgLayers = lxq("query layerservice layers ? bg");
	$_ = lxq("query layerservice layer.id ? $_") for @layers;
	$_ = lxq("query layerservice layer.id ? $_") for @fgLayers;
	$_ = lxq("query layerservice layer.id ? $_") for @bgLayers;
	my @doesNotExistList;
	my %ptagList;
	my %maskList;

	lx("select.subItem $_ add mesh;meshInst;camera;light;txtrLocator;backdrop;groupLocator [0] [1]") for @layers;

	my $materialCount = lxq("query layerservice material.n ? all");
	for (my $i=0; $i<$materialCount; $i++){
		$ptagList{lxq("query layerservice material.name ? $i")} = 1;
	}

	for (my $i=0; $i<$txLayers; $i++){
		if (lxq("query sceneservice txLayer.type ? $i") eq "mask"){
			my $id = lxq("query sceneservice txLayer.id ? $i");
			my $assignedPtag = lxq("query sceneservice channel.value ? ptag");
			$maskList{$assignedPtag} = 1;
		}
	}

	lxout("--------------------------------------");
	lxout("Printing materials that exist : ");
	lxout("--------------------------------------");
	foreach my $mask (sort keys %maskList){
		lxout("mask = ---$mask---");
	}

	foreach my $ptag (sort keys %ptagList){
		if (!exists $maskList{$ptag}){
			lxout("This material doesn't exist : ---$ptag---");
			push(@doesNotExistList,$ptag);
		}
	}

	if (@doesNotExistList > 0){
		my $printName;
		my $count = 0;
		foreach my $name (sort @doesNotExistList){
			$printName .= "\n".$name;
			if ($count > 5){
				$printName .= "\netc...";
				last;
			}
			$count++;
		}

		my $result = quickDialog("You wanna recreate these ($#doesNotExistList+1) missing materials?\nMake sure you have polys selected first.\n$printName",yesNo,1,"","");
		if ($result eq "ok"){
			foreach my $material (@doesNotExistList){
				lx("poly.setMaterial $material");
			}
		}
	}

	#restore layer visibility
	for (my $i=0; $i<@fgLayers; $i++){
		if ($i != 0){lx("select.subItem [@fgLayers[$i]] add mesh;meshInst;camera;light;txtrLocator;backdrop;groupLocator [0] [1]");}
		else		{lx("select.subItem [@fgLayers[$i]] set mesh;meshInst;camera;light;txtrLocator;backdrop;groupLocator [0] [1]");}
	}
	lx("layer.setVisibility [$_] [1] [1]") for @bgLayers;
}

sub sortedPtags{
	#get layers and show them all
	my @layers = lxq("query layerservice layers ? all");
	my @fgLayers = lxq("query layerservice layers ? fg");
	my @bgLayers = lxq("query layerservice layers ? bg");
	$_ = lxq("query layerservice layer.id ? $_") for @layers;
	$_ = lxq("query layerservice layer.id ? $_") for @fgLayers;
	$_ = lxq("query layerservice layer.id ? $_") for @bgLayers;

	lx("select.subItem [$_] add mesh;meshInst;camera;light;backdrop;groupLocator;locator;deform [0] [0]") for @layers;

	my @materials = lxq("query layerservice materials ?");
	for (my $i=0; $i<@materials; $i++){
		my $name = lxq("query layerservice material.name ? @materials[$i]");
		#$name =~ s/\\/\//g;
		@materials[$i] = $name;
	}

	my $count = 0;
	lxout("--------------------------");
	lxout("Printing sorted ptags :");
	lxout("--------------------------");
	foreach my $material (sort @materials){
		lxout("($count) : material = $material");
		$count++;
	}

	#restore layer visibility
	for (my $i=0; $i<@fgLayers; $i++){
		if ($i != 0){lx("select.subItem [@fgLayers[$i]] add mesh;meshInst;camera;light;txtrLocator;backdrop;groupLocator [0] [1]");}
		else		{lx("select.subItem [@fgLayers[$i]] set mesh;meshInst;camera;light;txtrLocator;backdrop;groupLocator [0] [1]");}
	}
	lx("layer.setVisibility [$_] [1] [1]") for @bgLayers;
}


sub sortedPtagMasks{
	lxout("eh?");
	my @list;
	my @duplicates;
	my $lastName;
	my $txLayerCount = lxq("query sceneservice txLayer.n ?");
	for (my $i=0; $i<$txLayerCount; $i++){
		if (lxq("query sceneservice txLayer.type ? $i") eq "mask"){
			my $id = lxq("query sceneservice txlayer.id ? $i");
			 if (lxq("query sceneservice channel.value ? ptyp") eq "Material"){
				my $ptag = lxq("query sceneservice channel.value ? ptag");

				#temp!!!
				$ptag =~ s/\\/\//g;
				$ptag = lc($ptag);
				push(@list,$ptag.",".$id);
			}
		}
	}

	my $count=0;
	lxout("--------------------------");
	lxout("Printing sorted ptag masks :");
	lxout("--------------------------");
	foreach my $name (sort @list){
		lxout("($count) : $name");
		$count++;
	}

	foreach my $name (sort @list){
		my @nameSplit = split(/,/,$name);
		if (@nameSplit[0] eq $lastName){
			push(@duplicates,@nameSplit[1]);
		}
		$lastName = @nameSplit[0];
	}

	$count=0;
	lxout("--------------------------");
	lxout("Printing duplicate ptag masks :");
	lxout("--------------------------");
	foreach my $id (sort @duplicates){
		my $name = lxq("query sceneservice txLayer.name ? $id");
		lxout("($count) : $name : $id");
		$count++;
	}

	if (@duplicates > 0){
		my $printName;
		for (my $i=0; $i<@duplicates; $i++){
			$printName .= "\n".@duplicates[$i];
			if ($i > 5){
				$printName .= "\netc...";
				last;
			}
		}
		popup("There are $#duplicates+1 duplicates. Do you want me to delete them?$printName");
		foreach my $item (@duplicates){
			lx("select.subItem [$item] set textureLayer;render;environment;mediaClip;locator");
			lx("texture.delete");
		}
	}
}

sub sortedMaterialNames{
	my @list;
	my @duplicates;
	my $lastName;

	my $txLayerCount = lxq("query sceneservice txLayer.n ?");
	for (my $i=0; $i<$txLayerCount; $i++){
		if (lxq("query sceneservice txLayer.type ? $i") eq "mask"){
			my $id = lxq("query sceneservice txlayer.id ? $i");
			my $name = lxq("query sceneservice txLayer.name ? $i");
			$name =~ tr/()//d;
			$name =~ s/\\/\//g;
			$name =~ lc($name);
			$name = $name.",".$id;
			push(@list,$name);
		}
	}

	lxout("--------------------------");
	lxout("Printing sorted material names :");
	lxout("--------------------------");
	my $count = 0;
	foreach my $name (sort @list){
		my @nameSplit = split(/,/,$name);
		lxout("$count : @nameSplit[0]");
		if (@nameSplit[0] eq $lastName){
			lxout("    this material is a duplicate! (@nameSplit[0])");
			push(@duplicates,@nameSplit[1]);
		}
		$lastName = @nameSplit[0];
		$count++;
	}

	if (@duplicates > 0){
		my $result = quickDialog("You wanna delete these ($#duplicates+1) duplicate materials?",yesNo,1,"","");
		if ($result eq "ok"){
			foreach my $id (@duplicates){
				lx("select.subItem $id set textureLayer;render;environment;mediaClip;locator");
				lx("texture.delete");
			}
		}
	}
}

sub sortedMasksWNoPtag{
	my @noneList;
	my $txLayerCount = lxq("query sceneservice txLayer.n ?");
	for (my $i=0; $i<$txLayerCount; $i++){
		if (lxq("query sceneservice txLayer.type ? $i") eq "mask"){
			my $id = lxq("query sceneservice txlayer.id ? $i");
			if (lxq("query sceneservice channel.value ? ptyp") eq "Material"){
				my $ptag = lxq("query sceneservice channel.value ? ptag");
				lxout("ptag =...$ptag...");
				if ($ptag eq ""){
					push(@noneList,$id);
				}
			}
		}
	}

	lxout("--------------------------");
	lxout("Printing ptag masks set to (none) :");
	lxout("--------------------------");
	my $printName;
	for (my $i=0; $i<@noneList; $i++){
		$printName .= "\n".@noneList[$i];
		if ($i > 5){
			$printName .= "\netc...";
			last;
		}
	}

	if (@noneList > 0){
		my $result = quickDialog("You wanna delete these ($#noneList+1) ptag masks that are set to (none)?$printName",yesNo,1,"","");
		if ($result eq "ok"){
			foreach my $id (@noneList){
				lx("select.subItem $id set textureLayer;render;environment;mediaClip;locator");
				lx("texture.delete");
			}
		}
	}
}

sub whichPolyMats{
	lxout("===========================================================================================");
	lxout("===========================================================================================");
	lxout("Printing all the polys in the scene with these materials.");
	lxout("===========================================================================================");
	lxout("===========================================================================================");

	my $materialNames = quickDialog("Type in material names\nyou wish to find.\n(seperated by comma)",string,"","","");
	my @names = split(/,/, $materialNames);

	my %ptagList;
	my @layers = lxq("query layerservice layers ? all");
	foreach my $layer (@layers){
		my $layerName = lxq("query layerservice layer.name ? $layer");
		my $polyCount = lxq("query layerservice poly.n ? all");
		for (my $i=0; $i<$polyCount; $i++){
			my $material = lxq("query layerservice poly.material ? $i");
			foreach my $name (@names){
				if ($material eq $name){
					push (@{$ptagList{$name}},$layerName." : ".$i);
				}
			}
		}
	}

	foreach my $key (sort keys %ptagList){
		foreach my $poly (@{$ptagList{$key}}){
			lxout("This polygon has the $key material : $poly");
		}
	}
}

sub selTheseMasks{
	lxout("===========================================================================================");
	lxout("===========================================================================================");
	lxout("Now selecting all the masks that match those parameters");
	lxout("===========================================================================================");
	lxout("===========================================================================================");

	my $nameList = quickDialog("Type in the material names\nyou want to select\n(seperated by commas)",string,"","","");
	my @names = split(/,/, $nameList);
	my @foundMasks;

	my $txLayers = lxq("query sceneservice txLayer.n ?");
	for (my $i=0; $i<$txLayers; $i++){
		if (lxq("query sceneservice txLayer.type ? $i") eq "mask"){
			my $name = lxq("query sceneservice txLayer.name ? $i");
			foreach my $checkName (@names){
				if ($name =~ /$checkName/i){
					push(@foundMasks, lxq("query sceneservice txLayer.id ? $i"));
				}
			}
		}
	}

	for (my $i=0; $i<@foundMasks; $i++){
		if ($i > 0){
			lx("select.subItem [@foundMasks[$i]] add textureLayer;render;environment;mediaClip;locator");
		}else{
			lx("select.subItem [@foundMasks[$i]] set textureLayer;render;environment;mediaClip;locator");
		}
	}
}

sub clipNamesSort{
	lxout("===========================================================================================");
	lxout("===========================================================================================");
	lxout("Printing all sorted clip names and also printing duplicates");
	lxout("===========================================================================================");
	lxout("===========================================================================================");

	my %clipList;
	my $clips = lxq("query sceneservice clip.n ? all");
	for (my $i=0; $i<$clips; $i++){
		my $name = lxq("query sceneservice clip.name ? $i");
		my $id = lxq("query sceneservice clip.id ? $i");
		push (@{$clipList{$name}},$id);
	}

	foreach my $key (sort keys %clipList){
		foreach my $id (@{$clipList{$key}}){
			lxout("$key id = $id");
		}
	}

	lxout("==================================");
	lxout("These are duplicate clips:");
	lxout("==================================");
	foreach my $key (sort keys %clipList){
		if (@{$clipList{$key}} > 1){
			foreach my $id (@{$clipList{$key}}){
				lxout("$key id = $id");
			}
		}
	}
}







#=====================================================================================================================================
#=====================================================================================================================================
#=====================================================================================================================================
#=====================================================================================================================================
#===																SUBROUTINES																		====
#=====================================================================================================================================
#=====================================================================================================================================
#=====================================================================================================================================
#=====================================================================================================================================

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
#DOT PRODUCT subroutine (ver 1.1)
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE : my $dp = dotProduct(\@vector1,\@vector2);
sub dotProduct{
	return (	(${$_[0]}[0]*${$_[1]}[0])+(${$_[0]}[1]*${$_[1]}[1])+(${$_[0]}[2]*${$_[1]}[2])	);
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

