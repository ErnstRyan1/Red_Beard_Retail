#perl
#ver 0.31
#author : Seneca Menard

#SCRIPT ARGUMENTS :
#"splineDeform" : select something that defines two verts. (2verts, edge, or 2ptPoly) and run the script and it create a spline in that same position with N subdivisions.  if you select something that's more than two verts (vertrow, edgeloop, etc), it'll just use those vert positions literally when it creates the spline deformer.
#"bldSkel_2PtChain" : build a skeleton from a 2pt poly chain.  select one vert and that'll be the root vert and everything else will be a child from that start point.
#"lockChannels" : this is a hack to lock channels.  it does that by creating new user channels, setting the values and then linking the original channels to these ones.

#CVARS
foreach my $arg (@ARGV){
	if		($arg eq "X")						{	our $x = 1;				}
	elsif	($arg eq "Y")						{	our $y = 1;				}
	elsif	($arg eq "Z")						{	our $z = 1;				}
	elsif	($arg =~ /bldSkel_2PtChain/i)		{	bldSkel_2PtChain();		}
	elsif	($arg =~ /bldSkel_3PtChain/i)		{	bldSkel_3PtChain();		}
	elsif	($arg =~ /conv_2PtChn_3PtChn/i)		{	conv_2PtChn_3PtChn();	}
	elsif	($arg =~ /makeMainBone/i)			{	makeMainBone();			}
	elsif	($arg =~ /splineDeform/i)			{	splineDeform();			}
	elsif	($arg =~ /setBoneUpVec/i)			{	setBoneUpVec();			}
	elsif	($arg =~ /printTransforms/i)		{	printTransforms();		}
	elsif	($arg =~ /printKeyFrameCounts/i)	{	printKeyFrameCounts();	}
	elsif	($arg =~ /removeXfrmZeros/i)		{	removeXfrmZeros();		}
	elsif	($arg =~ /addRem360/i)				{	addRem360();			}
	elsif	($arg =~ /lockChannels/i)			{	lockChannels();			}
	else										{	our $miscArg = $arg;	}
}


#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#LOCK CHANNELS : this is a hack to lock channels.  it does that by creating new user channels, setting the values and then linking the original channels to these ones.
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
sub lockChannels{
	my @channels = lxq("query sceneservice selection ? channels");
	foreach my $channelID (@channels){
		$channelID =~ s/^\(//;
		$channelID =~ s/\)$//;
		my @channelVals = split(/,/, $channelID);
		
		my $name = "senetemp_" . $channelVals[2];
		my $blahName = lxq("query sceneservice item.name ? {$channelVals[0]}");
		my $value = lxq("query sceneservice channel.value ? {$channelVals[1]}");
		
		lx("!!channel.create name:{$name} type:{float} mode:{scalar} useMin:{false} useMax:{false} default:{$value} item:{$channelVals[0]}");	
		lx("!!select.channel {$channelVals[0]:$name} set");
		lx("!!select.channel {$channelVals[0]:$channelVals[2]} add");
		lx("!!channel.link");
	}
}


#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#ADD OR REMOVE 360 to selected rotation keyframes
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
sub addRem360{
	my @locatorSel = lxq("query sceneservice selection ? locator");
	if ($miscArg eq "subtract")	{	our $addition = -360;	}
	else						{	our $addition = 360;	}
	
	#deselect all keys that aren't rotation keys
	foreach my $id (@locatorSel){
		my @xfrmItems = lxq("query sceneservice item.xfrmItems ? {$id}");
		
		foreach my $xfrmID (@xfrmItems){
			my $xfrmName = lxq("query sceneservice item.name ? $xfrmID");
			
			if ($xfrmName !~ /Rotation/i){
				my $channelCount = lxq("query sceneservice channel.n ?");
			
				for (my $i=0; $i<$channelCount; $i++){
					my $channelName = lxq("query sceneservice channel.name ? $i");
					
					if ($channelName !~ /rot\./i){
						my $keyCount = lxq("query sceneservice key.N ?");

						for (my $u=0; $u<$keyCount; $u++){
							if (lxq("query sceneservice key.isSelected ? $u") ==  1){
								my $keyTime = lxq("query sceneservice key.time ? $u");
								lx("select.key item:{$xfrmName} channel:{$i} time:{$keyTime} mode:{remove}");
							}
						}
					}
				}
			}
		}
	}
	
	#add the 360 / -360 value
	lx("key.value value:{$addition} mode:{add}");
}


#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#REMOVE TRANSFORM ZEROING (needs an argument of "pos, scl, or rot")
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
sub removeXfrmZeros{
	my @locatorSel = lxq("query sceneservice selection ? locator");

	foreach my $id (@locatorSel){
		my @xfrmItems = lxq("query sceneservice item.xfrmItems ? {$id}");
		my @val = (0,0,0);

		foreach my $xfrmID (@xfrmItems){
			if (lxq("query sceneservice item.name ? {$xfrmID}") =~ /$miscArg/i){
				$val[0] += lxq("item.channel $miscArg.X {?} set {$xfrmID}");
				$val[1] += lxq("item.channel $miscArg.Y {?} set {$xfrmID}");
				$val[2] += lxq("item.channel $miscArg.Z {?} set {$xfrmID}");

				lx("select.drop item");
				lx("select.item {$xfrmID} set transform");
				lx("item.delete");
			}
		}

		lx("!!transform.add type:{$miscArg} item:{$id}");
		lx("transform.channel $miscArg.X {$val[0]}");
		lx("transform.channel $miscArg.Y {$val[1]}");
		lx("transform.channel $miscArg.Z {$val[2]}");
	}

	lx("select.subItem {$_} set mesh;triSurf;camera;light;backdrop;groupLocator;replicator;surfGen;locator;deform;locdeform;deformGroup;deformMDD2;morphDeform;itemInfluence;genInfluence;softDeform;ABCdeform.sample;chanModify;chanEffect 0 0") for @locatorSel;
}


#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#PRINT NUMBER OF KEYFRAMES IN SELECTED ITEMS
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
sub printKeyFrameCounts{
	my @locatorSel = lxq("query sceneservice selection ? locator");
	my $minKeys = quickDialog("List channels with keys more than:",integer,0,0,9999);	
	
	foreach my $id (@locatorSel){
		my $name = lxq("query sceneservice item.name ? {$id}");
		my $channelCount = lxq("query sceneservice channel.n ?");
		my @keyNames;
		my @keyCounts;
		my @xfrmItems = lxq("query sceneservice item.xfrmItems ? {$id}");

		for (my $i=0; $i<$channelCount; $i++){
			my $channelName = lxq("query sceneservice channel.name ? $i");
			my $keyCount = lxq("query sceneservice key.N ?");
			if ($keyCount > $minKeys){
				push(@keyNames,$channelName);
				push(@keyCounts,$keyCount);
			}
		}
		
		foreach my $xfrmID (@xfrmItems){
			my $xfrmName = lxq("query sceneservice item.name ? {$xfrmID}");
			my $xfrmChannelCount = lxq("query sceneservice channel.n ?");
			for (my $i=0; $i<$xfrmChannelCount; $i++){
				my $channelName = lxq("query sceneservice channel.name ? $i");
				my $keyCount = lxq("query sceneservice key.N ?");
				if ($keyCount > $minKeys){
					push(@keyNames,$channelName);
					push(@keyCounts,$keyCount);
				}
			}
		}
		
		if (@keyNames > 0){
			lxout("$name--------------------------------");
			for (my $i=0; $i<@keyNames; $i++){
				lxout("     $keyCounts[$i] = $keyNames[$i]");
			}
		}
	}
}


#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#PRINT ALL XFRMS IN SELECTED ITEMS
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
sub printTransforms{
	my @selection = lxq("query sceneservice selection ? all");
	
	foreach my $id (@selection){
		my $name = lxq("query sceneservice item.name ? {$id}");
		my @xfrmItems = lxq("query sceneservice item.xfrmItems ? {$id}");
		
		lxout("------------------------------------");
		lxout("name = $name");
		lxout("------------------------------------");
		
		foreach my $xfrmID (@xfrmItems){
			my $xfrmName = lxq("query sceneservice item.name ? {$xfrmID}");	
			lxout("     xfrmName = $xfrmName <> id=$xfrmID");
		}
	}
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#MAKE MAIN BONE (makes the bone look prettier)
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
sub makeMainBone{
	my @locatorSel = lxq("query sceneservice selection ? locator");
	foreach my $id (@locatorSel){
		my $parentID = lxq("query sceneservice item.parent ? {$id}");
		if ($parentID eq ""){next;}
		lx("item.parent {$id} {$parentID} 0 inPlace:1");
	}
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#SET BONE UP VECTOR
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------

#usage @matrix = transposeRotMatrix_3x3(\@matrix);

#USAGE : my @3x3Matrix = Eul_ToMatrix($xRot,$yRot,$zRot,"ZXYs",degrees|radians);
# - the angles must be radians unless the fifth argument is "degrees" in which case the sub will convert it to radians for you.
# - must insert the X,Y,Z rotation values in the listed order.  the script will rearrange them internally.
# - as for the rotation order cvar, the last character is "s" or "r".  Here's what they mean:
#	"s" : "static axes"		: use this as default
#	"r" : "rotating axes"	: for body rotation axes?
# - resulting matrix must be inversed or transposed for it to be correct in modo.

#USAGE : my @angles = Eul_FromMatrix(\@3x3matrix,"XYZs",degrees|radians);
# - the output will be radians unless the third argument is "degrees" in which case the sub will convert it to degrees for you.
# - returns XrotAmt, YrotAmt, ZrotAmt, rotOrder;
# - resulting matrix must be inversed or transposed for it to be correct in modo.

sub setBoneUpVec{  #BLAH : isn't working yet. is giving incorrect rotations..
	#find poly "Y" vector (Y=longest edge)
	popup("Hover mouse over poly and hit enter");
	my $poly = lxq("query view3dservice element.over ? POLY");

	if ($poly eq ""){die("your mouse was not over a poly and so i have to cancel the script");}

	my @polyData = split (/[^0-9]/, $poly);
	$polyData[0] += 1;
	my $layerName = lxq("query layerservice layer.name ? $polyData[0]");
	my @vertList = lxq("query layerservice poly.vertList ? $polyData[1]");

	my @vertPos0 = lxq("query layerservice vert.pos ? $vertList[0]");
	my @vertPos1 = lxq("query layerservice vert.pos ? $vertList[1]");
	my @vertPos2 = lxq("query layerservice vert.pos ? $vertList[2]");

	my @vec1 = arrMath(@vertPos0,@vertPos1,subt);
	my @vec2 = arrMath(@vertPos1,@vertPos2,subt);

	my $dist1 = dist(@vec1);
	my $dist2 = dist(@vec2);

	my @polyYVector = (0,0,0);
	if ($dist1 > $dist2){	@polyYVector = unitVector(@vec1);	}
	else				{	@polyYVector = unitVector(@vec2);	}

	#put polyYVector into local space.
	my @locatorSel = lxq("query sceneservice selection ? locator");
	my $parentID = lxq("query sceneservice item.parent ? {$locatorSel[0]}");
	my @wMatrix = getItemXfrmMatrix($parentID);
	@wMatrix = transposeRotMatrix_3x3(\@wMatrix);
	$wMatrix[0][3] = 0;
	$wMatrix[1][3] = 0;
	$wMatrix[2][3] = 0;
	$wMatrix[3][3] = 1;
	$wMatrix[3][0] = 0;
	$wMatrix[3][1] = 0;
	$wMatrix[3][2] = 0;
	@polyYVector = vec_mtxMult(\@wMatrix,\@polyYVector);
	lxout("polyYVector = @polyYVector");

	#get and alter local matrix.

	my $xRot = lxq("item.channel rot.X {?} set {$locatorSel[0]}");
	my $yRot = lxq("item.channel rot.Y {?} set {$locatorSel[0]}");
	my $zRot = lxq("item.channel rot.Z {?} set {$locatorSel[0]}");
	my @lMatrix = Eul_ToMatrix($xRot,$yRot,$zRot,"ZXYs","degrees");
	@lMatrix = transposeRotMatrix_3x3(\@lMatrix);
	printMatrix(\@lMatrix);

	my @xVec = ( $lMatrix[0][0], $lMatrix[0][1], $lMatrix[0][2] );
	my @zVec = crossProduct(\@xVec,\@polyYVector);
	my @yVec = crossProduct(\@xVec,\@zVec);

	#$xVec[0] = int($xVec[0]*100+.5)*.01;
	#$xVec[1] = int($xVec[1]*100+.5)*.01;
	#$xVec[2] = int($xVec[2]*100+.5)*.01;
	#$yVec[0] = int($yVec[0]*100+.5)*.01;
	#$yVec[1] = int($yVec[1]*100+.5)*.01;
	#$yVec[2] = int($yVec[2]*100+.5)*.01;
	#$zVec[0] = int($zVec[0]*100+.5)*.01;
	#$zVec[1] = int($zVec[1]*100+.5)*.01;
	#$zVec[2] = int($zVec[2]*100+.5)*.01;

	#@zVec = arrMath(@zVec,-1,-1,-1,mult);

	lxout("xVec = @xVec");
	lxout("yVec = @yVec");
	lxout("zVec = @zVec");

	#createCube(@xVec,.2);
	#createCube(@yVec,.4);
	#createCube(@zVec,.6);

	my @lMatrix = (
		[$xVec[0],$xVec[1],$xVec[2]],
		[$yVec[0],$yVec[1],$yVec[2]],
		[$zVec[0],$zVec[1],$zVec[2]]
	);
	#@lMatrix = transposeRotMatrix_3x3(\@lMatrix);
	my @angles = Eul_FromMatrix(\@lMatrix,"ZXYs","degrees");
	lx("item.channel rot.X {$angles[0]} set {$locatorSel[0]}");
	lx("item.channel rot.Y {$angles[1]} set {$locatorSel[0]}");
	lx("item.channel rot.Z {$angles[2]} set {$locatorSel[0]}");
	lxout("angles = @angles");



								##convert bone's rotation to world matrix
								#my @locatorSel = lxq("query sceneservice selection ? locator");
								#my $xRot = lxq("item.channel rot.X {?} set {$locatorSel[0]}");
								#my $yRot = lxq("item.channel rot.Y {?} set {$locatorSel[0]}");
								#my $zRot = lxq("item.channel rot.Z {?} set {$locatorSel[0]}");
								#my @boneWPos =
#
								##my @matrix = getItemXfrmMatrix($locatorSel[0]);
								##@matrix = transposeRotMatrix_3x3(\@matrix);
#
								##recreate bone's worldRotMatrix's Y and Z.
								#my @xVec = ( $matrix[0][0], $matrix[0][1], $matrix[0][2] );
								#my @zVec = crossProduct(\@xVec,\@polyYVector);
								#my @yVec = crossProduct(\@xVec,\@zVec);
								#my @newMatrix = (
									#[$xVec[0],$xVec[1],$xVec[2]],
									#[$yVec[0],$yVec[1],$yVec[2]],
									#[$zVec[0],$zVec[1],$zVec[2]]
								#);
#
								#my @vertWPos = (17.5817,23.4263,-14.1632);
#
								##subtract parent rot from bone
								#@matrix = transposeRotMatrix_3x3(\@matrix);
								#@newMatrix = mtxMult(\@matrix,\@newMatrix);
								#@newMatrix = transposeRotMatrix_3x3(\@newMatrix);
#
								#my @angles = Eul_FromMatrix(\@newMatrix,"ZXYs",degrees);
								#lx("item.channel rot.X {$angles[0]} set {$locatorSel[0]}");
								#lx("item.channel rot.Y {$angles[1]} set {$locatorSel[0]}");
								#lx("item.channel rot.Z {$angles[2]} set {$locatorSel[0]}");
#
									##my @xVec = ( $matrix[0][0], $matrix[0][1], $matrix[0][2] );
									##my @yVec = ( $matrix[1][0], $matrix[1][1], $matrix[1][2] );
									##my @zVec = ( $matrix[2][0], $matrix[2][1], $matrix[2][2] );
#
								##@xVec = arrMath(@xVec,10,10,10,mult);
								##@yVec = arrMath(@yVec,10,10,10,mult);
								##@zVec = arrMath(@zVec,10,10,10,mult);
								##@polyYVector = arrMath(@polyYVector,10,10,10,mult);
							##
								##createTextLoc(@xVec,"X1",.01);
								##createTextLoc(@yVec,"Y1",.01);
								##createTextLoc(@zVec,"Z1",.01);
								##createTextLoc(@polyYVector,"py",.01);

}


#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#CONVERT 2PT CHAIN TO TRI CHAIN (3PT)
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
sub conv_2PtChn_3PtChn{
	my %alreadyDoneVerts;
	my %todoVerts;
	my %vert_to_boneIDTable;
	our $boneToDupeID;
	my @verts = lxq("query layerservice verts ? selected");
	if (@verts == 0){ die("You need to select the vert that's the root of the skeleton chain and run script again");	}
	$todoVerts{$verts[0]} = 1;

	#create all other bones
	while (keys %todoVerts > 0){
		my $currentVert = (keys %todoVerts)[0];
		delete $todoVerts{$currentVert};
		$alreadyDoneVerts{$currentVert} = 1;

		my @vertList = lxq("query layerservice vert.vertList ? $currentVert");
		foreach my $vert (@vertList){
			if ($alreadyDoneVerts{$vert} != 1){
				$alreadyDoneVerts{$vert} = 1;
				$todoVerts{$vert} = 1;

				my @vertPosCurrent = lxq("query layerservice vert.pos ? $vert");
				$vert_to_boneIDTable{$vert} = createBone($vert_to_boneIDTable{$currentVert},\@vertPosCurrent);
			}
		}
	}
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#BUILD SKELETON FROM TRI CHAIN (3PT)
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------


#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#BUILD SKELETON FROM 2PT CHAIN
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
sub bldSkel_2PtChain{
	my %alreadyDoneVerts;
	my %todoVerts;
	my %vert_to_boneIDTable;
	our $boneToDupeID;
	my @verts = lxq("query layerservice verts ? selected");
	if (@verts == 0){ die("You need to select the vert that's the root of the skeleton chain and run script again");	}
	$todoVerts{$verts[0]} = 1;

	my $itemCount = lxq("query sceneservice item.n ? all");
	for (my $i=0; $i<$itemCount; $i++){
		if (lxq("query sceneservice item.type ? $i") eq "locator"){
			if (lxq("query sceneservice item.name ? $i") eq "_bone"){
				$boneToDupeID = lxq("query sceneservice item.id ? $i");
				last;
			}
		}
	}

	if ($boneToDupeID eq ""){	die("Couldn't find a bone called '_bone' so please create on and then run script.");	}

	#create first bone
	my @vertPos = lxq("query layerservice vert.pos ? $verts[0]");
	my $firstBoneID = createBone("",\@vertPos);
	$vert_to_boneIDTable{$verts[0]} = $firstBoneID;

	#create all other bones
	while (keys %todoVerts > 0){
		my $currentVert = (keys %todoVerts)[0];
		delete $todoVerts{$currentVert};
		$alreadyDoneVerts{$currentVert} = 1;

		my @vertList = lxq("query layerservice vert.vertList ? $currentVert");
		foreach my $vert (@vertList){
			if ($alreadyDoneVerts{$vert} != 1){
				$alreadyDoneVerts{$vert} = 1;
				$todoVerts{$vert} = 1;

				my @vertPosCurrent = lxq("query layerservice vert.pos ? $vert");
				$vert_to_boneIDTable{$vert} = createBone($vert_to_boneIDTable{$currentVert},\@vertPosCurrent);
			}
		}
	}
}



#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#SPLINE DEFORM
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
sub splineDeform{
	#--------------------------------------------
	#SETUP
	#--------------------------------------------
	my $mainlayer = lxq("query layerservice layers ? main");
	my $mainlayerID = lxq("query layerservice layer.id ? $mainlayer");
	my $mainlayerName = lxq("query layerservice layer.name ? $mainlayer");
	my @verts;
	my @posList;

	#vert
	if		( lxq( "select.typeFrom {vertex;edge;polygon;item} ?" ) ){
		our $selType = "vertex";
		if (lxq("query layerservice vert.n ? selected") == 0){die("You don't have any verts selected so i'm canceling the script");}
		@verts = lxq("query layerservice verts ? selected");
	}
	#edge
	elsif	( lxq( "select.typeFrom {edge;polygon;item;vertex} ?" ) ){
		our $selType = "edge";
		if (lxq("query layerservice edge.n ? selected") == 0){die("You don't have any edge selected so i'm canceling the script");}

		my @edges = lxq("query layerservice edges ? selected");
		sortRowStartup(edgesSelected,@edges);
		@verts = split (/[^0-9]/, $vertRowList[0]);
		lx("select.drop vertex");
		lx("select.element $mainlayer vertex add $_") for @verts;
	}
	#poly
	elsif	( lxq( "select.typeFrom {polygon;item;vertex;edge} ?" ) ){
		our $selType = "vertex";
		if (lxq("query layerservice poly.n ? selected") == 0){die("You don't have any polys selected so i'm canceling the script");}
		lx("select.convert vertex}");
		@verts = lxq("query layerservice verts ? selected");
	}
	#die
	else	{die("\\\\n.\\\\n[---------------------------------------------You're not in vert, edge, or polygon mode.--------------------------------------------]\\\\n[--PLEASE TURN OFF THIS WARNING WINDOW by clicking on the (In the future) button and choose (Hide Message)--] \\\\n[-----------------------------------This window is not supposed to come up, but I can't control that.---------------------------]\\\\n.\\\\n");}

	#--------------------------------------------
	#GATHER VERT DATA
	#--------------------------------------------
	if (@verts == 2){our $divisions = quickDialog("Divisions on curve:",integer,5,1,100);}

	if ($divisions > 0){
		my @pos0 = lxq("query layerservice vert.pos ? $verts[0]");
		my @pos1 = lxq("query layerservice vert.pos ? $verts[1]");
		my @disp = arrMath(@pos1,@pos0,subt);
		my $dist = dist(@disp);
		my @unitVector = unitVector(@disp);
		my $sizePerSegment = $dist / ($divisions + 1);

		for (my $i=0; $i<$divisions+2; $i++){
			my @vecSize = ($unitVector[0]*$sizePerSegment*$i , $unitVector[1]*$sizePerSegment*$i , $unitVector[2]*$sizePerSegment*$i);
			my @pos = arrMath(@pos0,$vecSize[0],$vecSize[1],$vecSize[2],add);
			push(@posList,\@pos);
		}
	}else{
		foreach my $vert (@verts){
			my @pos = lxq("query layerservice vert.pos ? $vert");
			push(@posList,\@pos);
		}
	}

	#--------------------------------------------
	#DELETE VERTS
	#--------------------------------------------
	if (quickDialog("Delete original vert selection?","yesNo",1,"","") eq "ok"){
		lx("delete");
	}

	#--------------------------------------------
	#CREATE NEW LAYER
	#--------------------------------------------
	lx("layer.new");
	my @currentLayer = lxq("query sceneservice selection ? mesh");
	my $currentName = $mainlayerName . "_curveDef_rest";
	lx("item.name item:{$currentLayer[0]} name:{$currentName}");
	lx("layer.setVisibility {$currentLayer[0]} 0 0");

	#--------------------------------------------
	#CREATE CURVE
	#--------------------------------------------
	lx("tool.set prim.curve on 0");
	lx("tool.setAttr prim.curve mode add");
	lx("tool.setAttr prim.curve number 0");
	lx("tool.noChange");
	for (my $i=0; $i<@posList; $i++){
		my $number = $i+1;
		lx("tool.setAttr prim.curve number {$number}");
		lx("tool.setAttr prim.curve ptX {${$posList[$i]}[0]}");
		lx("tool.setAttr prim.curve ptY {${$posList[$i]}[1]}");
		lx("tool.setAttr prim.curve ptZ {${$posList[$i]}[2]}");
	}
	lx("tool.doApply");
	lx("tool.set prim.curve off 0");

	#--------------------------------------------
	#CREATE 2ND NEW LAYER
	#--------------------------------------------
	lx("select.type polygon");
	lx("select.copy");
	lx("layer.new");
	my @currentLayer2 = lxq("query sceneservice selection ? mesh");
	$currentName = $mainlayerName . "_curveDef_pose";
	lx("item.name item:{$currentLayer2[0]} name:{$currentName}");
	lx("select.paste");

	#--------------------------------------------
	#SETUP SPLINE DEFORM
	#--------------------------------------------
	lx("!!select.item {$mainlayerID} set");
	lx("!!item.addDeformer genInfluence");
	my $influID = lxq("query sceneservice selection ? genInfluence");
	lx("!!select.subItem {$mainlayerID}");
	lx("!!deform.spline.create true false 0 x 0.0");
	my $GrpN = lxq("query sceneservice group.N ?") - 1;
	my $SplGrp = lxq("query sceneservice group.id ? $GrpN");
	lx("!!select.item {$SplGrp} set");
	lx("!!select.item {$influID} add");
	lx("!!item.link deformers");

	lx("deform.spline.linkMesh mesh:{$currentLayer[0]} restMesh:true");
	lx("deform.spline.linkMesh mesh:{$currentLayer2[0]}");

	#--------------------------------------------
	#SETUP SELECTION
	#--------------------------------------------
	lx("select.item {$currentLayer2[0]} set");
	lx("select.type $selType");
}




#-----------------------------------------------------------------------------------------------------------------------------------------------------#
#																																					  #
#																																					  #
#																																					  #
#																																					  #
#-----------------------------------------------------------------------------------------------------------------------------------------------------#
#																ANIM SUBROUTINES																	  #
#-----------------------------------------------------------------------------------------------------------------------------------------------------#
#																																					  #
#																																					  #
#																																					  #
#																																					  #
#-----------------------------------------------------------------------------------------------------------------------------------------------------#

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#CREATE BONE sub
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE : my $newBoneID = createBone($parentID,\@pos);
sub createBone{
	lx("!!select.subItem {$boneToDupeID} set mesh;meshInst;camera;light;backdrop;groupLocator;replicator;surfGen;locator;deform;locdeform;deformGroup;deformMDD2;morphDeform;itemInfluence;genInfluence;softDeform;ABCdeform.sample;chanModify;chanEffect 0 0");
	lx("!!item.duplicate all:true");
	my @locatorSel = lxq("query sceneservice selection ? locator");

	lx("item.channel pos.X {${$_[1]}[0]} set {$locatorSel[0]}");
	lx("item.channel pos.Y {${$_[1]}[1]} set {$locatorSel[0]}");
	lx("item.channel pos.Z {${$_[1]}[2]} set {$locatorSel[0]}");

	if ($_[0] ne ""){
		lx("!!item.parent item:{$locatorSel[0]} parent:{$_[0]} position:[0] inPlace:[1]");
	}

	return $locatorSel[0];
}

#-----------------------------------------------------------------------------------------------------------------------------------------------------#
#																																					  #
#																																					  #
#																																					  #
#																																					  #
#-----------------------------------------------------------------------------------------------------------------------------------------------------#
#																MATH SUBROUTINES																	  #
#-----------------------------------------------------------------------------------------------------------------------------------------------------#
#																																					  #
#																																					  #
#																																					  #
#																																					  #
#-----------------------------------------------------------------------------------------------------------------------------------------------------#

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
#CALCULATE DISTANCE subroutine
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#usage : my $dist = dist(@vector);
sub dist{
	return sqrt((@_[0]*@_[0])+(@_[1]*@_[1])+(@_[2]*@_[2]));
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

#-----------------------------------------------------------------------------------------------------------------------------------------------------#
#																																					  #
#																																					  #
#																																					  #
#																																					  #
#-----------------------------------------------------------------------------------------------------------------------------------------------------#
#																GENERAL SUBROUTINES																	  #
#-----------------------------------------------------------------------------------------------------------------------------------------------------#
#																																					  #
#																																					  #
#																																					  #
#																																					  #
#-----------------------------------------------------------------------------------------------------------------------------------------------------#

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
#QUICK DIALOG SUB v2.1 (modded to not die if user press no to yesno)
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE : quickDialog(username,float,initialValue,min,max);
sub quickDialog{
	if ($_[1] eq "yesNo"){
		lx("dialog.setup yesNo");
		lx("dialog.msg {$_[0]}");
		lx("dialog.open");
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


#-----------------------------------------------------------------------------------------------------------------------------------------------------#
#																																					  #
#																																					  #
#																																					  #
#																																					  #
#-----------------------------------------------------------------------------------------------------------------------------------------------------#
#																MATRIX SUBROUTINES																	  #
#-----------------------------------------------------------------------------------------------------------------------------------------------------#
#																																					  #
#																																					  #
#																																					  #
#																																					  #
#-----------------------------------------------------------------------------------------------------------------------------------------------------#


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
