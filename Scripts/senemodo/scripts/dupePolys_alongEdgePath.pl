#perl
#ver 1.0
#author : Seneca Menard

#This script is to duplicate your polygon selection along your selected edge path.  Just align your polys to your edge path, select that edge path and run script and it will be copied along the path evenly.
#note 1 : doesn't use symmetry yet
#note 2 : to dupe along a subd edgeloop, you'd have to copy/paste/freeze the geometry and use that because i'm not writing a subd emulator algorithm.  :P

#uservalue setup
userValueTools(senPathDupeDist,float,config,"Distance Between Copies:","","","",xxx,xxx,"",1,1);
lx("user.value senPathDupeDist") or die("user cancelled script");
my $senPathDupeDist = lxq("user.value senPathDupeDist ?");

#setup
my $mainlayer = lxq("query layerservice layers ? main");
my @polys = lxq("query layerservice polys ? selected");
my @edges = lxq("query layerservice edges ? selected");
my $layerVertCount = lxq("query layerservice vert.n ? all");
my $objVertCount = 0;
lx("select.type polygon");
lx("select.copy");

if ((@polys == 0) || (@edges == 0)){die("You must have some polys and edges selected in order to run this script.");}

#create temp vertlist for @polys;
my %polyVerts;
foreach my $poly (@polys){
	my @verts = lxq("query layerservice poly.vertList ? $poly");
	$polyVerts{$_} = 1 for @verts;
}
$objVertCount = (keys %polyVerts);


#sort rows
sortRowStartup(edgesSelected,@edges);
my @bboxAndCenter = bboxAndCenter_polys(\@polys);

#now run sub on the edgerow (vertlist)
foreach my $vertRow (@vertRowList){
	my @verts = split (/[^0-9]/, $vertRow);
	my @results = findPosOnPtChain(\@verts,$bboxAndCenter[6],$bboxAndCenter[7],$bboxAndCenter[8]);
	dupePolysAlong2ptChain(\@verts,$results[0],$results[1],$results[2],$senPathDupeDist);
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#DUPLICATE POLYS ALONG 2PT CHAIN
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE : dupePolysAlong2ptChain(\@vertChain,$edgeVert1,$edgeVert2,$offset1,$copyDist);
sub dupePolysAlong2ptChain{
	my ($vertChain,$edgeVert1,$edgeVert2,$offset1,$copyDist) = @_;
	my @vertChain1;
	my @vertChain2;
	my $foundIndice;
	my $offset2;

	#split vert chain into two vert chains (or just one if object is at end of chain)
	#edge is at start of chain
	if ((@$vertChain[0] == $edgeVert1) && (@$vertChain[1] == $edgeVert2)){
		@vertChain1 = @$vertChain;
		if ($offset1 > $copyDist){
			@vertChain2 = ($$vertChain[1],$$vertChain[0]);
			my $edge = "(" . $$vertChain[1] . "," . $$vertChain[0] . ")";
			$offset2 = lxq("query layerservice edge.length ? $edge") - $offset1;
		}
	}
	#edge is at middle of chain
	else{
		for (my $i=0; $i<$#$vertChain; $i++){
			lxout("sdf : $$vertChain[$i] <> $$vertChain[$i+1]");
			if (($$vertChain[$i] == $edgeVert1) && ($$vertChain[$i+1] == $edgeVert2)){
				$foundIndice = $i;
			}
		}
		for (my $i=$foundIndice; $i<@$vertChain; $i++)	{	push(@vertChain1,$$vertChain[$i]);	}
		for (my $i=$foundIndice+1; $i>=0; $i--)			{	push(@vertChain2,$$vertChain[$i]);	}

		my $edge = "(" . $edgeVert1 . "," . $edgeVert2 . ")";
		$offset2 = lxq("query layerservice edge.length ? $edge") - $offset1;
	}

	my $loopCount = 0;
	foreach my $chain (\@vertChain1,\@vertChain2){
		$loopCount++;
		lxout("====================== $loopCount");
		my $offset;
		if ($loopCount == 1)	{	$offset = $offset1;	}
		else					{	$offset = $offset2;	}
		my @lastObjPos = ($bboxAndCenter[6],$bboxAndCenter[7],$bboxAndCenter[8]);  #warning : put in safety check
		my @xfrm;

		#loop to find positions on chain
		for (my $i=0; $i<$#$chain; $i++){

			#define matrix for each vector
			my @pos1 = lxq("query layerservice vert.pos ? $$chain[$i]");
			my @pos2 = lxq("query layerservice vert.pos ? $$chain[$i+1]");
			my @pos3;
			my @vec1 = arrMath(@pos2,@pos1,subt);
			my @vec2;
			my @unitVec1 = unitVector(@vec1);
			my @unitVec2;
			my $vec1Length = sqrt(($vec1[0]*$vec1[0])+($vec1[1]*$vec1[1])+($vec1[2]*$vec1[2]));
			my $vecRemainder = $vec1Length - $offset;
			my $copyTimes = 0;
			my $loop = 1;

			my $offsetPos = $offset;
			while ($loop == 1){
				if ($offsetPos < $vec1Length){
					$copyTimes++;
					$offsetPos += $copyDist;
				}else{
					$leftOverDist = abs($vec1Length - $offsetPos);
					$loop = 0;
				}
			}

			if ($i+1 == $#$chain){
				my @lastObjPosRay = arrMath(@lastObjPos,@unitVec1,add);
				@intersectPoint = intersectRayPlaneMath(\@lastObjPos,\@lastObjPosRay,\@vec1,\@pos2);
				@lastObjPos = @intersectPoint;
			}else{
				my @lastObjPosRay = arrMath(@lastObjPos,@unitVec1,add);
				@pos3 = lxq("query layerservice vert.pos ? $$chain[$i+2]");
				@vec2 = arrMath(@pos3,@pos2,subt);
				@unitVec2 = unitVector(@vec2);
				my @avgVec1Vec2 = unitVector( ($unitVec1[0] + $unitVec2[0]) * .5 , ($unitVec1[1] + $unitVec2[1]) * .5 , ($unitVec1[2] + $unitVec2[2]) * .5 );
				@intersectPoint = intersectRayPlaneMath(\@lastObjPos,\@lastObjPosRay,\@avgVec1Vec2,\@pos2);
				@lastObjPos = @intersectPoint;
			}

			#now that we have a controlled roll, create matrix
			my @lastObjPosDisp = arrMath(unitVector(arrMath(@pos2,@lastObjPos,subt)),2,2,2,mult);
			my @cp1 = crossProduct(\@unitVec1,\@lastObjPosDisp);
			my @cp2 = unitVector(crossProduct(\@unitVec1,\@cp1));
			@cp1 = unitVector(crossProduct(\@unitVec1,\@cp2));

			#declare matrix transform if on first round
			if ($i == 0){
				#create <XFRM> matrix
				@xfrm = (
					[1,0,0,0],
					[0,1,0,0],
					[0,0,1,0],
					[0,0,0,1]
				);

				my @xfrmMov = (
					[1,0,0,-$bboxAndCenter[6]],
					[0,1,0,-$bboxAndCenter[7]],
					[0,0,1,-$bboxAndCenter[8]],
					[0,0,0,1]
				);

				my @xfrmRot = (
					[@cp1,0],
					[@unitVec1,0],
					[@cp2,0],
					[0,0,0,1]
				);

				my @offsetVec = arrMath(@unitVec1,$offset,$offset,$offset,mult);
				my @offsetPos = arrMath(@pos1,@offsetVec,add);
				my @dispVec = arrMath($bboxAndCenter[6],$bboxAndCenter[7],$bboxAndCenter[8],@offsetPos,subt);
				my @xfrmOff = (
					[1,0,0,$dispVec[0]],
					[0,1,0,$dispVec[1]],
					[0,0,1,$dispVec[2]],
					[0,0,0,1]
				);

				@xfrm = mtxMult(\@xfrmMov,\@xfrm);
				@xfrm = mtxMult(\@xfrmOff,\@xfrm);
				@xfrm = mtxMult(\@xfrmRot,\@xfrm);
			}

			#create rotation
			my @xfrmRot = (
				[@cp1,0],
				[@unitVec1,0],
				[@cp2,0],
				[0,0,0,1]
			);
			@xfrmRot = transposeRotMatrix(\@xfrmRot);

			#apply this round's move/rotate matrix
			for (my $u=0; $u<$copyTimes; $u++){
				if (($u == 0) && ($i == 0)){$offset += $copyDist; next;}

				my @pos = arrMath(@pos1,arrMath(@unitVec1,$offset,$offset,$offset,mult),add);
				my @xfrmPos = (
					[1,0,0,$pos[0]],
					[0,1,0,$pos[1]],
					[0,0,1,$pos[2]],
					[0,0,0,1]
				);
				my @xfrmTemp = ([1,0,0,0],[0,1,0,0],[0,0,1,0],[0,0,0,1]);
				@xfrmTemp = mtxMult(\@xfrmRot,\@xfrmTemp);
				@xfrmTemp = mtxMult(\@xfrmPos,\@xfrmTemp);
				my @xfrm_apply = mtxMult(\@xfrmTemp,\@xfrm);

				lx("select.paste");
				$layerVertCount += $objVertCount;
				for (my $i=$layerVertCount-$objVertCount; $i<$layerVertCount; $i++){
					my @pos = lxq("query layerservice vert.pos ? $i");
					@pos = vec_mtxMult(\@xfrm_apply,\@pos);
					lx("vert.move vertIndex:$i posX:$pos[0] posY:$pos[1] posZ:$pos[2]");
				}
				$offset += $copyDist;
			}
			$offset = $leftOverDist;
		}
	}
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
#DOT PRODUCT DETERMINED FROM 2 VERTS AND 1 POS (dp or dpDist) (vector1vert1,vector1vert2,\@pos);
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE : my $dp = findDP_fromVerts($vectorVert1,$vectorVert2,\@pos,dp|dpDist);
#REQUIRES unitVector subroutine
sub dotProduct_fromTwoVertsAndOnePos{
	my @pos1 = lxq("query layerservice vert.pos ? $_[0]");
	my @pos2 = lxq("query layerservice vert.pos ? $_[1]");
	my @vec1;
	my @vec2;

	if ($_[3] =~ /dpDist/i){
		@vec1 = unitVector($pos2[0]-$pos1[0],$pos2[1]-$pos1[1],$pos2[2]-$pos1[2]);
		@vec2 = (@{$_[2]}[0]-$pos1[0],@{$_[2]}[1]-$pos1[1],@{$_[2]}[2]-$pos1[2]);
	}else{
		@vec1 = unitVector($pos2[0]-$pos1[0],$pos2[1]-$pos1[1],$pos2[2]-$pos1[2]);
		@vec2 = unitVector(@{$_[2]}[0]-$pos1[0],@{$_[2]}[1]-$pos1[1],@{$_[2]}[2]-$pos1[2]);
	}

	my $dp = (	($vec1[0]*$vec2[0])+($vec1[1]*$vec2[1])+($vec1[2]*$vec2[2])	);
	return $dp;
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#DOT PRODUCT DETERMINED FROM 3 VERTS (dp or dpDist) (vector1vert1,vector1vert2,vert);
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE : my $dp = findDP_fromVerts($vectorVert1,$vectorVert2,$vertToQueryDPTo,dp|dpDist);
#REQUIRES unitVector subroutine
sub dotProduct_fromThreeVerts{
	my @pos1 = lxq("query layerservice vert.pos ? $_[0]");
	my @pos2 = lxq("query layerservice vert.pos ? $_[1]");
	my @pos3 = lxq("query layerservice vert.pos ? $_[2]");
	my @vec1;
	my @vec2;

	if ($_[3] =~ /dpDist/i){
		@vec1 = unitVector($pos2[0]-$pos1[0],$pos2[1]-$pos1[1],$pos2[2]-$pos1[2]);
		@vec2 = ($pos3[0]-$pos1[0],$pos3[1]-$pos1[1],$pos3[2]-$pos1[2]);
	}else{
		@vec1 = unitVector($pos2[0]-$pos1[0],$pos2[1]-$pos1[1],$pos2[2]-$pos1[2]);
		@vec2 = unitVector($pos3[0]-$pos1[0],$pos3[1]-$pos1[1],$pos3[2]-$pos1[2]);
	}

	my $dp = (	($vec1[0]*$vec2[0])+($vec1[1]*$vec2[1])+($vec1[2]*$vec2[2])	);
	return $dp;
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
#BBOX AND BBOX CENTER FROM POLYLIST : ([0]-[5]=bbox [6]-[8]=center)
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



#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#CREATE TEXT LOCATOR ITEM
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#USAGE : createTextLoc($x,$y,$z,$text,$locSize);
sub createTextLoc{
	lx("item.create locator");
	my @locatorSelection = lxq("query sceneservice selection ? locator");
	lx("transform.channel pos.X {$_[0]}");
	lx("transform.channel pos.Y {$_[1]}");
	lx("transform.channel pos.Z {$_[2]}");

	lx("item.help add label {$_[3]}");
	lx("item.channel size {$_[4]} set {$locatorSelection[-1]}");
}

#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#SET UP THE USER VALUE OR VALIDATE IT   (no popups)
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
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