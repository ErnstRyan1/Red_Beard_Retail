#perl
#ver 0.40
#author : Seneca Menard

#this script is to do miscellaneous modeling things.
# illegalTris : select illegal tris that have no area
# scale : scale element selection by double or half
# array : will array your selected polys by the distance between the first two selected verts by the number of clones you tell it to clone.
# buildCalNums : will build a series of number items in the exact positions of your selected polys.  useful for creating a calendar mockup illustration.  :)
# shiftIndices : have n polyislands selected and select a poly whose indice you want the current selection to start with.  
# spinConcaveEdges : spins concave edges : can also type in a dotproduct if you want to define the cutoff point.  ie here i'm setting it to 0.02 : "@geometryTools.pl 0.02 spinConcaveEdges"
# buildPolysInNewLayer : this is for filling holes in photoscan data.  creating polys in this layer is way too slow.
# straightenEdges : will flatten all selected edges to their most orthogonal axis.

#(4-9-11 fix) : the illegal tris search routine now only pays attention to tris.
#(7-17-12 fix): illegalTris now catches edges of 0 length.
#(7-17-12 fix): oops.  typo.
#(1-10-14 fix) : got the actr storage system up to date with 601
#(2-27-14 feature) : put in a selection set function to either apply selSets or clear all selSets from vert/edge/poly selection.  uses sen_selSets gui
#(7-25-14 fix) : fixed a typo with user value checking.
#(9-9-14 fix) : fixed a bug with layer indices not being 0 based.
#(8-3-15 feature) : added straightenEdges feature

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#ARGUMENTS
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
foreach my $arg (@ARGV){
	if		($arg eq "up")					{	our $direction = "up";			}
	elsif	($arg eq "down")				{	our $direction = "down";		}
	elsif	($arg eq "left")				{	our $direction = "left";		}
	elsif	($arg eq "right")				{	our $direction = "right";		}
	elsif	($arg eq "scale")				{	our $scale = 1;					}
	elsif	($arg eq "array")				{	our $array = 1;					}
	elsif	($arg eq "illegalTris")			{	our $illegalTris = 1;			}
	elsif	($arg eq "spinPolys")			{	our $spinPolys = 1;				}
	elsif	($arg eq "buildCalNums")		{	our $buildCalNums = 1;			}
	elsif	($arg eq "shiftIndices")		{	our $shiftIndices = 1;			}
	elsif	($arg eq "assignSelSet")		{	our $assignSelSet = 1;			}
	elsif	($arg eq "clearSelSets")		{	our $clearSelSets = 1;			}
	elsif	($arg eq "moveToRefLayer")		{	our $moveToRefLayer = 1;		}
	elsif	($arg eq "spinConcaveEdges")	{	our $spinConcaveEdges = 1;		}
	elsif	($arg eq "buildPolysInNewLayer"){	our $buildPolysInNewLayer =1 ;	}
	elsif	($arg eq "closePipeLoops")		{	our $closePipeLoops = 1;		}
	elsif	($arg eq "subDivideRects")		{	our $subDivideRects = 1;		}
	elsif	($arg eq "splitSmGroupPolys")	{	our $splitSmGroupPolys = 1;		}
	elsif	($arg eq "straightenEdges")		{	our $straightenEdges = 1;		}
	else									{	our $miscArg = $arg;			}
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#SETUP
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
my $mainlayer = lxq("query layerservice layers ? main");


#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USER VARIABLES
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
userValueTools(sene_refLayerName,string,config,sene_refLayerName,"","","",xxx,xxx,"","_ref");

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#WHICH SUBROUTINES TO RUN
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
if ($scale == 1){
	safetyChecks();
	scale();
	cleanup();
}
elsif ($illegalTris == 1){
	selectIllegalTris();
}
elsif ($array == 1){
	array();
}
elsif ($spinPolys == 1){
	spinPolys();
}
elsif ($buildCalNums == 1){
	buildCalNums();
}
elsif ($shiftIndices == 1){
	shiftIndices();
}
elsif ($assignSelSet == 1){
	assignSelSet();
}
elsif ($clearSelSets == 1){
	clearSelSets();
}
elsif ($moveToRefLayer == 1){
	moveToRefLayer();
}
elsif ($spinConcaveEdges == 1){
	spinConcaveEdges();
}
elsif ($buildPolysInNewLayer == 1){
	buildPolysInNewLayer();
}
elsif ($closePipeLoops == 1){
	closePipeLoops();
}
elsif ($subDivideRects == 1){
	subDivideRects();
}
elsif ($splitSmGroupPolys == 1){
	splitSmGroupPolys();
}
elsif ($straightenEdges == 1){
	straightenEdges();
}



#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#STRAIGHTEN EDGES : flatten all edges to their nearest orthogonal axis.
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
sub straightenEdges{
	my $mainlayer = lxq("query layerservice layers ? main");
	my @edges = lxq("query layerservice edges ? selected");
	foreach my $edge (@edges){
		my @vector = lxq("query layerservice edge.vector ? {$edge}");
		my @edgePos = lxq("query layerservice edge.pos ? {$edge}");
		my $longestDimension = 0;
		my $longestSize = 0;
		for (my $i=0; $i<@vector; $i++){
			if (abs($vector[$i]) >= $longestSize){
				$longestSize = abs($vector[$i]);
				$longestDimension = $i;
			}
		}	
		
		my @verts = split (/[^0-9]/, $edge);
		for (my $i=1; $i<@verts; $i++){
			my @vertPos = lxq("query layerservice vert.pos ? $verts[$i]");
			$edgePos[$longestDimension] = $vertPos[$longestDimension];
			lx("!!vert.move vertIndex:{$verts[$i]} posX:{$edgePos[0]} posY:{$edgePos[1]} posZ:{$edgePos[2]}");
		}
	}
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#SPLIT SMOOTHING GROUP POLYS INTO DIFFERENT MESH ISLANDS AND MOVE THEM (for handplane baking)
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
sub splitSmGroupPolys{
	my $mainlayer = lxq("query layerservice layers ? main");
	my @polys = lxq("query layerservice polys ? selected");
	if (@polys == 0){	@polys = lxq("query layerservice polys ? visible");	}
	my %smGroups;
	my $count = 1;
	my @changedPolys;
	
	foreach my $poly (@polys){
		my @tagTypes = lxq("query layerservice poly.tagTypes ? $poly");
		for (my $i=0; $i<@tagTypes; $i++){
			if ($tagTypes[$i] eq "SMGP"){
				my @tags = lxq("query layerservice poly.tags ? $poly");
				push(@{$smGroups{$tags[$i]}},$poly);
			}
		}
	}
	
	foreach my $key (keys %smGroups){
		lxout("moving smGroup ($key)");
		my $moveAmt = .01432 * $count;
		$count++;
		
		returnCorrectIndice($smGroups{$key},\@changedPolys);
		
		lx("select.drop polygon");
		lx("select.element $mainlayer polygon add $_") for @{$smGroups{$key}};
		lx("select.cut");
		lx("select.invert");
		lx("select.paste");
		lx("select.invert");

		lx("!!tool.set xfrm.move on");
		lx("!!tool.setAttr xfrm.move X {0}");
		lx("!!tool.setAttr xfrm.move Y {$moveAmt}");
		lx("!!tool.setAttr xfrm.move Z {0}");
		lx("!!tool.doApply");
		lx("!!tool.set xfrm.move off");
	}
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#SUBDIVIDE RECTANGLES EVENLY (useful for turning simple rectangles into quad strips for displacement)
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
sub subDivideRects{
	my @polys = lxq("query layerservice polys ? selected");
	@polys = sort { $b <=> $a } @polys;
	
	foreach my $poly (@polys){
		my @vertList = lxq("query layerservice poly.vertList ? $poly");
		
		#find longest and shortest edges and sizes
		my $longestEdgeSize = 0;
		my $smallestEdgeSize = 999999999999999999999999999;
		my @longestEdge;
		
		for (my $i=0; $i<@vertList; $i++){
			my $vertA = $vertList[$i];
			my $vertB = $vertList[$i-1];
			my @vertPosA = lxq("query layerservice vert.pos ? $vertA");
			my @vertPosB = lxq("query layerservice vert.pos ? $vertB");
			my $fakeDist = abs($vertPosB[0] - $vertPosA[0]) + abs($vertPosB[1] - $vertPosA[1]) + abs($vertPosB[2] - $vertPosA[2]);
			if ($fakeDist < $smallestEdgeSize){
				$smallestEdgeSize = $fakeDist;
			}
			if ($fakeDist > $longestEdgeSize){
				$longestEdgeSize = $fakeDist;
				@longestEdge = ($vertA,$vertB);
			}
		}
		
		#now select edges and perform loop slice
		my $loopCuts = int($longestEdgeSize / $smallestEdgeSize) - 1;
		if ($loopCuts > 0){
			lx("select.drop edge");
			lx("!!select.element $mainlayer edge add $longestEdge[0] $longestEdge[1]");
			lx("!!select.ring");
			
			lx("!!tool.set poly.loopSlice on");
			lx("!!tool.reset");
			lx("!!tool.attr poly.loopSlice count {$loopCuts}");
			lx("!!tool.doApply");
			lx("!!tool.set poly.loopSlice off");
		}
	}
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#BUILD POLYS IN NEW LAYER : this is for filling holes in photoscan data.  creating polys in this layer is way too slow.
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
sub closePipeLoops{
	my @polys = lxq("query layerservice polys ? selected");
	getPolyPieces(polyIsland,\@polys); 
	
	foreach my $key (keys %getPolyPiecesGroups){ 
		lx("!!select.drop vertex");
		lx("!!select.drop edge");
		lx("!!select.drop polygon");
		lx("select.element $mainlayer polygon add $_") for @{$getPolyPiecesGroups{$key}};
		lx("select.boundary");
		if (lxq("select.count edge ?") == 0){next;}
		lx("!!select.convert vertex");
		
		my @verts = lxq("query layerservice verts ? selected");
		for (my $i=0; $i<@verts*.5; $i++){
			my $vert1 = $verts[$i];
			my $vert2 = $verts[$i+(@verts*.5)];
			my @vert2Pos = lxq("query layerservice vert.pos ? $vert2");
			lx("!!vert.move vertIndex:{$vert1} posX:{$vert2Pos[0]} posY:{$vert2Pos[1]} posZ:{$vert2Pos[2]}");
		}
	}
	
	lx("!!select.drop edge");
	lx("!!select.drop polygon");
	lx("!!select.element $mainlayer polygon add $_") for @polys;
	lx("!!select.boundary");
	lx("!!vert.merge auto disco:false");
	lx("!!select.type polygon");
}


#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#BUILD POLYS IN NEW LAYER : this is for filling holes in photoscan data.  creating polys in this layer is way too slow.
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#usage : select edge loop(s) in HP layer and run this script and it'll make polys and triple 'em in the new layer.  You will probably need to flip some of the polys
sub buildPolysInNewLayer{
	if		( lxq( "select.typeFrom {edge;polygon;item;vertex} ?" ) )	{	our $selType = "edge";	}
	elsif	( lxq( "select.typeFrom {vertex;edge;polygon;item} ?" ) )	{	our $selType = "vert";	}
	else	{die("You're not using vertex or edge selection mode so I'm cancelling the script");}

	#build edge list
	my $mainlayer = lxq("query layerservice layers ? main");
	my $mainlayerID = lxq("query layerservice layer.id ? $mainlayer");
	if ($selType eq "vert")	{	our @verts = lxq("query layerservice verts ? selected");	}
	else					{	our @edges = lxq("query layerservice edges ? selected");	}
	if ($selType eq "edge") {	sortRowStartup(edgesSelected,@edges);						}
	my $vertCount;

	#find the layer called "newPolys" or create it. (and select it)
	my $itemCount = lxq("query sceneservice item.n ? all");
	my $newPolysID;
	my $newPolysIndex;
	for (my $i=0; $i<$itemCount; $i++){
		if ( (lxq("query sceneservice item.type ? $i") eq "mesh") && (lxq("query sceneservice item.name ? $i") eq "newPolys") ){
			$newPolysID = lxq("query sceneservice item.id ? $i");
			lx("!!select.subItem {$newPolysID} set mesh;camera;light;txtrLocator;backdrop;groupLocator;replicator;surfGen;locator;deform;locdeform;deformGroup;deformMDD2;morphDeform;itemInfluence;genInfluence;deform.wrap;softLag;ABCdeform.sample;chanModify;chanEffect;defaultShader;defaultShader 0 0");
			last;
		}
	}

	if ($newPolysID eq ""){
		lx("!!item.create mesh");
		lx("!!item.name {newPolys} mesh");
		my @meshes = lxq("query sceneservice selection ? mesh");
		$newPolysID = $meshes[0];
	}

	$newPolysIndex = lxq("query layerservice layer.index ? {$newPolysID}");
	$vertCount = lxq("query layerservice vert.n ? all");

	#build the poly (vert mode)
	if ($selType eq "vert"){
		my $mainlayerName = lxq("query layerservice layer.name ? $mainlayer");
		foreach my $vert (@verts){
			my @vertPos = lxq("query layerservice vert.pos ? {$vert}");
			lx("!!vert.new $vertPos[0] $vertPos[1] $vertPos[2]");
		}
		lx("select.drop vertex");
		for (my $i=$vertCount; $i<$vertCount+@verts; $i++){
			lx("!!select.element {$newPolysIndex} vertex add {$i}");
		}
		lx("!!poly.make auto false");
		$vertCount += @verts;
	}
	#build each poly (edge mode)
	else{
		foreach my $vertRow (@vertRowList){
			my @verts = split (/[^0-9]/, $vertRow);
			my $mainlayerName = lxq("query layerservice layer.name ? $mainlayer");
			foreach my $vert (@verts){
				my @vertPos = lxq("query layerservice vert.pos ? {$vert}");
				lx("!!vert.new $vertPos[0] $vertPos[1] $vertPos[2]");
			}

			lx("select.drop vertex");
			for (my $i=$vertCount; $i<$vertCount+$#verts; $i++){
				lx("!!select.element {$newPolysIndex} vertex add {$i}");
			}
			lx("!!poly.make auto false");
			$vertCount += @verts;
		}
	}

	#triple polys
	lx("!!select.drop polygon");
	lx("!!poly.triple");

	#select original layer again
	lx("!!select.subItem {$mainlayerID} set mesh;camera;light;txtrLocator;backdrop;groupLocator;replicator;surfGen;locator;deform;locdeform;deformGroup;deformMDD2;morphDeform;itemInfluence;genInfluence;deform.wrap;softLag;ABCdeform.sample;chanModify;chanEffect;defaultShader;defaultShader 0 0");
	if ($selType eq "edge")	{	lx("!!select.drop edge");	}
	else					{	lx("!!select.drop vertex");	}
}


#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#SPIN CONCAVE EDGES : (works with polys selected and edges selected (can type in a dp manually to set the flatness cutoff point))
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
sub spinConcaveEdges{
	my $mainlayer = lxq("query layerservice layers ? main");
	my @edges;
	my @edgeToSpin;
	my $dp = 0.02;
	if ($miscArg > 0){$dp = $miscArg;}
	
	#get list of edges to spin
	if (lxq( "select.typeFrom {edge;vertex;polygon;item} ?" )){
		@edges = lxq("query layerservice edges ? selected");
		if (@edges == 0){	@edges = lxq("query layerservice edges ? visible");	}
	}elsif (lxq( "select.typeFrom {polygon;item;edge;vertex} ?" )){
		my @polys = lxq("query layerservice polys ? selected");
		if (@polys == 0){
			@edges = lxq("query layerservice edges ? visible");	
		}else{
			my %edges;
			foreach my $poly (@polys){
				my @verts = lxq("query layerservice poly.vertList ? $poly");
				for (my $i=-1; $i<$#verts; $i++){
					if ($verts[$i] < $verts[$i+1]){
						$edges{"(".$verts[$i].",".$verts[$i+1].")"} = 1;
					}else{
						$edges{"(".$verts[$i+1].",".$verts[$i].")"} = 1;
					}
				}
			}
			push(@edges,(keys %edges));
		}
	}else{
		die("You're not in polygon or edge selection mode so I'm cancelling the script");
	}
	
	#find edges to spin
	foreach my $edge (@edges){
		my @polys = lxq("query layerservice edge.polyList ? {$edge}");
		if (@polys > 1){
			my @normal1 = lxq("query layerservice poly.normal ? $polys[0]");
			my @polyPos1 = lxq("query layerservice poly.pos ? $polys[0]");
			my @polyPos2 = lxq("query layerservice poly.pos ? $polys[1]");
			my @polyToPolyVector = unitVector(arrMath(@polyPos2,@polyPos1,subt));
			
			if ( dotProduct(\@normal1,\@polyToPolyVector) > $dp ){
				push(@edgesToSpin,$edge);
			}
		}
	}
	
	#spin edges
	foreach my $edge (@edgesToSpin){
		my @verts = split (/[^0-9]/, $edge);
		lx("!!select.element $mainlayer edge set $verts[1] $verts[2]");
		lx("!!edge.spinQuads");
	}
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#MOVE TO REF LAYER : cut/pastes geo and puts it in designated ref layer
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
sub moveToRefLayer{
	#startup
	my $layerID;
	my $refLayerName = lxq("user.value sene_refLayerName ?");
	if ($refLayerName eq ""){lx("!!user.value sene_refLayerName {_ref}");}
	my $layerCount = lxq("query layerservice layer.n ? all");
	my @selectedMeshes = lxq("query sceneservice selection ? mesh");
	if (lxq("select.count polygon ?") == 0){die("You don't have any polys selected and so I'm cancelling the script");}
	
	#find layer with "_ref" name.
	for (my $i=1; $i<$layerCount+1; $i++){
	my $layerName = lxq("query layerservice layer.name ? $i");
		if (lxq("query layerservice layer.name ? $i") eq $refLayerName){
			$layerID = lxq("query layerservice layer.id ? $i");
			last;
		}
	}
	
	#if no ref layer exists, create it and put geo there.
	if ($layerID eq ""){
		lxout("[->] : Couldn't find a reference layer with a name of : '$refLayerName' so I'm creating a new one");
		lx("!!select.cut");
		lx("!!layer.new");
		lx("!!select.paste");
		lx("!!item.name name:{$refLayerName} type:{mesh}");
	}
	#if ref layer exists, put the geo there.
	else{
		lx("!!select.cut");
		lx("!!select.subItem {$layerID} set mesh;meshInst;camera;light;txtrLocator;backdrop;groupLocator;replicator;surfGen;locator;deform;locdeform;deformGroup;deformMDD2;morphDeform;itemInfluence;genInfluence;deform.wrap;softLag;ABCdeform.sample;chanModify;chanEffect;defaultShader;defaultShader 0 0");
		lx("!!select.paste");
	}
	
	#reselect original meshes
	lx("!!select.drop item");
	lx("!!select.subItem {$_} add mesh;meshInst;camera;light;txtrLocator;backdrop;groupLocator;replicator;surfGen;locator;deform;locdeform;deformGroup;deformMDD2;morphDeform;itemInfluence;genInfluence;deform.wrap;softLag;ABCdeform.sample;chanModify;chanEffect;defaultShader;defaultShader 0 0") for @selectedMeshes;
	lx("!!select.type polygon");
}


#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#ASSIGN SELECTION SET SUB (assigns the cvar you type in as the selection set (and removes the 0.25,0.5,1,2,3,4 selSets as well beforehand))
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
sub assignSelSet{
	if		(lxq("select.typeFrom {vertex;edge;polygon;item} ?")){}
	elsif	(lxq("select.typeFrom {edge;polygon;item;vertex} ?")){}
	elsif	(lxq("select.typeFrom {polygon;item;vertex;edge} ?")){}
	else{	die("You're not in vert, edge, or polygon selection mode and so I'm cancelling the script");}
	
	lx("!!select.editSet {0.25} remove {}");
	lx("!!select.editSet {0.5} remove {}");
	lx("!!select.editSet {1} remove {}");
	lx("!!select.editSet {2} remove {}");
	lx("!!select.editSet {3} remove {}");
	lx("!!select.editSet {4} remove {}");
	
	lx("!!select.editSet {$miscArg} add {}");
}


#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#CLEAR SELECTION SETS SUB (removes all selection sets from selected elems)
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
sub clearSelSets{
	my @meshes = lxq("query sceneservice selection ? mesh");
	my %selSets;
	my $selMode = "";
	my $selMode2 = "";

	if	(lxq("select.typeFrom {vertex;edge;polygon;item} ?")){
		$selMode = "verts";
		$selMode2 = "vert";
	}elsif	(lxq("select.typeFrom {edge;polygon;item;vertex} ?")){
		$selMode = "edges";
		$selMode2 = "edge";
	}elsif	(lxq("select.typeFrom {polygon;item;vertex;edge} ?")){
		$selMode = "polys";
		$selMode2 = "poly";
	}else{
		die("You're not in vert, edge, or poly selection mode so I'm canceling the script");
	}
	
	foreach my $meshID (@meshes){
		my $layerName = lxq("query layerservice layer.name ? {$meshID}");
		my @elems = lxq("query layerservice $selMode ? selected");
		foreach my $elem (@elems){
			my @selSets = lxq("query layerservice $selMode2.selSets ? {$elem}");
			foreach my $selSet (@selSets){
				$selSets{$selSet} = 1;
			}
		}
	}
	
	foreach my $key (keys %selSets){
		lxout("Removing '$key' selSet from the selected polys");
		lx("!!select.editSet {$key} remove {}");
	}
}



#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#SHIFT INDICES SUB : (fates forever) : all poly islands will get lower poly indices than the last selected poly.
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
sub shiftIndices{
	my @polys = lxq("query layerservice polys ? selected");
	my @lastPolyIsland = listTouchingPolys2($polys[-1]);
	my $lowestPolyIndice = $lastPolyIsland[0];
	my $polyCount_layer = lxq("query layerservice poly.n ? all");
	my %polysToIgnore;
	my @cutPastePolys;
	
	
	for (my $i=0; $i<@lastPolyIsland; $i++){	
		if ($lastPolyIsland[$i] < $lowestPolyIndice)		{	$lowestPolyIndice = $lastPolyIsland[$i];			}
		if (lxq("query layerservice poly.selected ? $lastPolyIsland[$i]") == 1)	{	pop(@polys);					}
	}
	
	$polysToIgnore{$_} = 1 for @polys;
	
	lx("select.drop polygon");
	for (my $i=$lowestPolyIndice; $i<$polyCount_layer; $i++){
		if ($polysToIgnore{$i} != 1){
			lx("select.element $mainlayer polygon add $i");
			push(@cutPastePolys,$i);
		}
	}
	lx("select.cut");
	lx("select.paste");
	
	@polys = sort { $a <=> $b } @polys;
	returnCorrectIndice(\@polys,\@cutPastePolys);

	lx("select.drop polygon");
	lx("select.element $mainlayer polygon add $_") for @polys;
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#BUILD CALENDAR NUMBERS (select polys in order where you want numbers to go and it will place them there)
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
sub buildCalNums{
	my $lastMonthDaysVisible = quickDialog("last month's days visible","integer",0,0,33);
	my $lastMonthsLastDay = quickDialog("number of last month's last day","integer",0,0,33);
	my $thisMonthDays = quickDialog("how many days in this month","integer",0,0,33);
	my $textSize = quickDialog("text size","float",32,"","");
	my $createPolysOrLayers = popupMultChoice("Create polys or layers","polys;layers",1);

	my $mainlayer = lxq("query layerservice layers ? main");
	my $polyCount = lxq("query layerservice poly.n ? all") - 1;
	my @polys = lxq("query layerservice polys ? selected");
	my @layerList;

	lx("tool.set actr.auto on");
	for (my $i=0; $i<@polys; $i++){
		my @polyPos = lxq("query layerservice poly.pos ? $polys[$i]");

		my $day;
		if ($i < $lastMonthDaysVisible){
			$day = $lastMonthsLastDay - ($lastMonthDaysVisible-$i-1);
		}elsif ($i < $lastMonthDaysVisible + $thisMonthDays){
			$day = ($i - $lastMonthDaysVisible)+1;
		}else{
			$day = $i - ($lastMonthDaysVisible + $thisMonthDays) + 1;
		}

		if ($createPolysOrLayers eq "layers"){
			lx("layer.new");
			our $layerID = lxq("query sceneservice selection ? mesh");
		}

		lx("tool.set prim.text on");
		lx("tool.setAttr prim.text text {$day}");
		lx("tool.attr prim.text size {$textSize}");
		lx("tool.attr prim.text justification center");
		lx("tool.attr prim.text location middle");
		lx("tool.attr prim.text posX 0");
		lx("tool.attr prim.text posY 0");
		lx("tool.attr prim.text posZ 0");
		lx("tool.doApply");
		lx("tool.set prim.text off");

		if ($createPolysOrLayers eq "polys"){
			$polyCount++;
			lx("!!select.element $mainlayer polygon set $polyCount");
			lx("poly.setPart {calendarNumbers}");
		}

		if ($createPolysOrLayers eq "polys"){
			lx("tool.set xfrm.move on");
			lx("tool.setAttr xfrm.move X {$polyPos[0]}");
			lx("tool.setAttr xfrm.move Y {$polyPos[1]}");
			lx("tool.setAttr xfrm.move Z {$polyPos[2]}");
			lx("tool.doApply");
			lx("tool.set xfrm.move off");
		}else{
			lx("!!transform.add type:{pos} item:{$layerID}");
			lx("!!item.channel pos.X {$polyPos[0]} set {$layerID}");
			lx("!!item.channel pos.Y {$polyPos[1]} set {$layerID}");
			lx("!!item.channel pos.Z {$polyPos[2]} set {$layerID}");
			push(@layerList,$layerID);
		}
	}

	if ($createPolysOrLayers eq "layers"){
		lx("!!select.drop item");
		lx("!!select.subItem {$_} add mesh;camera;light;backdrop;groupLocator;replicator;surfGen;locator;deform;locdeform;deformGroup;deformMDD2;morphDeform;itemInfluence;genInfluence;softDeform;ABCdeform.sample;chanModify;chanEffect 0 0") for @layerList;
		lx("!!layer.groupSelected");
		my @groupSelection = lxq("query sceneservice selection ? groupLocator");
		lx("!!item.name name:{numbers} item:{$groupSelection[0]}");
	}
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#SPIN POLYS sub (loses all poly info, but spins it)
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
sub spinPolys{
	my $mainlayer = lxq("query layerservice layers ? main");
	my @polys = lxq("query layerservice polys ? selected");
	foreach my $poly (@polys){
		my @vertList = lxq("query layerservice poly.vertList ? $poly");
		#lxout("vertList = @vertList");
		lx("select.drop vertex");
		lx("select.element $mainlayer vertex add $_") for @vertList;
		lx("poly.make auto false");
	}

	lx("select.drop polygon");
	lx("select.element $mainlayer polygon add $_") for @polys;
	lx("delete");
	lx("!!poly.align");

	my $polyCount = lxq("query layerservice poly.n ? all");
	for (my $i=0; $i<@polys; $i++){
		my $poly = $polyCount - ($i + 1);
		lx("select.element $mainlayer polygon add $poly");
	}
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#ARRAY subroutine
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
sub array{
	my @verts = lxq("query layerservice verts ? selected");
	my @polys = lxq("query layerservice polys ? selected");

	if (@polys == 0){die("You don't have any polys selected and so I'm cancelling the script");}
	if (@verts < 2){die("You have less than two verts selected and so I'm cancelling the script");}

	#gather number of clones
	my $cloneAmount = quickDialog("Number of tiles:","integer",10,1,1000) - 1;

	#gather matrix data
	my @itemXfrmMatrix = getItemXfrmMatrix($mainlayerID);
	my @wpMatrix = queryWorkPlaneMatrix_4x4();
	my @itemRefMatrix = queryItemRefMatrix();
	my @matrix = @itemXfrmMatrix;
	@matrix = mtxMult(\@itemRefMatrix,\@matrix);
	@matrix = mtxMult(\@wpMatrix,\@matrix);

	#gather vert pos and apply matrix data
	my @vertPos0 = lxq("query layerservice vert.pos ? $verts[0]");
	my @vertPos1 = lxq("query layerservice vert.pos ? $verts[1]");
	@vertPos0 = vec_mtxMult(\@matrix,\@vertPos0);
	@vertPos1 = vec_mtxMult(\@matrix,\@vertPos1);
	my @disp = arrMath(@vertPos1,@vertPos0,subt);

	#use array tool
	lx("select.type polygon");
	lx("tool.set actr.auto on");
	lx("tool.set *.clone on");
	lx("tool.reset");
	lx("tool.attr gen.linear num {$cloneAmount}");
	lx("tool.setAttr gen.linear offX {$disp[0]}");
	lx("tool.setAttr gen.linear offY {$disp[1]}");
	lx("tool.setAttr gen.linear offZ {$disp[2]}");
	lx("tool.doApply");
	lx("tool.set *.clone off");
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#SELECT ILLEGAL TRIS
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
sub selectIllegalTris{
	lxout("sdf");
	my $mainlayer = lxq("query layerservice layers ? main");
	my @polys = lxq("query layerservice polys ? selected");
	if (@polys == 0){@polys = lxq("query layerservice polys ? visible");}

	lx("select.drop polygon");
	foreach my $poly (@polys){
		my @vertList = lxq("query layerservice poly.vertList ? $poly");
		if (@vertList > 3){next;}
		my @vertPos1 = lxq("query layerservice vert.pos ? $vertList[0]");
		my @vertPos2 = lxq("query layerservice vert.pos ? $vertList[1]");
		my @vertPos3 = lxq("query layerservice vert.pos ? $vertList[2]");

		my @disp1 = arrMath(@vertPos2,@vertPos1,subt);
		if (($disp1[0] == 0) && ($disp1[1] == 0) && ($disp1[2] == 0)){
			lx("select.element $mainlayer polygon add $poly");
			next;
		}else{
			@disp1 = unitVector(@disp1);
		}

		my @disp2 = arrMath(@vertPos3,@vertPos1,subt);
		if (($disp2[0] == 0) && ($disp2[1] == 0) && ($disp2[2] == 0)){
			lx("select.element $mainlayer polygon add $poly");
			next;
		}else{
			@disp2 = unitVector(@disp2);
		}

		my $dp = dotProduct(\@disp1,\@disp2);

		if (abs($dp) > .99999){
			lx("select.element $mainlayer polygon add $poly");
		}
	}
}


#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#SCALE SUBROUTINE
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
sub scale{
	if		(lxq("select.typeFrom {vertex;edge;polygon;item} ?"))	{	our $mode = "vert";		our $selectionMode = "vertex";														}
	elsif	(lxq("select.typeFrom {edge;polygon;item;vertex} ?"))	{	our $mode = "edge";		our $selectionMode = "edge";		lx("select.convert vertex");					}
	elsif	(lxq("select.typeFrom {polygon;item;vertex;edge} ?"))	{	our $mode = "poly";		our $selectionMode = "polygon";														}
	else															{	die("You're not in vertex, edge, or poly mode and so I'm cancelling the script");	}
	my @fewElems;

	if ($selectionMode eq "polygon"){
		my @polys = lxq("query layerservice polys ? selected");
		@fewElems = gatherEveryXElemsFromArray(\@polys,10);
	}else{
		my @verts = lxq("query layerservice verts ? selected");
		@fewElems = gatherEveryXElemsFromArray(\@verts,10);
	}

	my @bboxCenter = (0,0,0);
	foreach my $elem (@fewElems){
		my @pos = lxq("query layerservice $mode.pos ? $elem");
		$bboxCenter[0] += $pos[0];
		$bboxCenter[1] += $pos[1];
		$bboxCenter[2] += $pos[2];
	}
	@bboxCenter = arrMath(@bboxCenter,$#fewElems+1,$#fewElems+1,$#fewElems+1,div);

	if ($direction eq "up")	{	our $scaleAmount = 2;	}
	else					{	our $scaleAmount = .5;	}

	lx("tool.viewType xyz");
	lx("tool.set xfrm.scale on");
	lx("tool.reset");
	lx("tool.attr center.auto cenX {$bboxCenter[0]}");
	lx("tool.attr center.auto cenY {$bboxCenter[1]}");
	lx("tool.attr center.auto cenZ {$bboxCenter[2]}");
	lx("tool.setAttr xfrm.scale factor {$scaleAmount}");
	lx("tool.doApply");
	lx("tool.set xfrm.scale off");
}


#
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

#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#-----------------------------------------------SCRIPTING SUBROUTINES----------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

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
#PRINT MATRIX (4x4)
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#usage : printMatrix(\@matrix);
sub printMatrix{
	lxout("==========");
	for (my $i=0; $i<4; $i++){
		for (my $u=0; $u<4; $u++){
			lxout("[$i][$u] = @{$_[0][$i]}[$u]");
		}
		lxout("\n");
	}
}

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





