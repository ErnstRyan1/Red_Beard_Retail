#perl
#ver 0.5
#author : Seneca Menard

#Stone Wall Builder : This script will build a stone wall out of mesh instances.  
#DIRECTIONS : The way you use this is you make a bunch of rectangular brick meshes and just put 'em in a group.  Then select the group and run the script.
#NOTES 1 : The brick meshes must be unit sized (like 1x1 or 4x2 or whatever).  
#NOTES 2 : There MUST be some 1x1 and 2x1 bricks right now because it's hardcoded to need them for tight crevice packs.
#NOTES 3 : There are no rotations yet.  Only random horizontal/vertical flips.
#NOTES 4 : There is no weighting for how often certain stones get chosen. It's random.  To have a certain size show up more often than the other bricks, just make lots of bricks of this size.



##------------------------------------------------------------------------------------------------------------
##SETUP
##------------------------------------------------------------------------------------------------------------
srand;
my $count = quickDialog("Wall Divisions (32 is normal)",integer,32,2,256);
my $forceBBOX = quickDialog("Turn on BBOX drawing for instances?",boolean,0,"","");
my %itemSizeTable;
my %itemSizeDimensions;
my @itemSizes;
my @itemSizes_Nx1;
my @itemSizes_2x1;
my @itemSizes_1x1;
my %itemLastUsedTable;
my %usedBlocks;
my $blocksLeft = $count*$count;
my $consecutiveFailCount = 0;
my $padding = 2;
my $tempCounter = 0;
my @createdInstances;

my @groupSel = lxq("query sceneservice selection ? groupLocator");
if (@groupSel == 0){die("You don't have any groups selected, so I'm canceling the script");}
my @children = lxq("query sceneservice item.children ? $groupSel[-1]");


##------------------------------------------------------------------------------------------------------------
##BUILD TABLE OF ITEMS SORTED BY SIZE
##------------------------------------------------------------------------------------------------------------
foreach my $id (@children){
	my @bounds;
	if (lxq("query sceneservice item.type ? {$id}") eq "triSurf")	{	@bounds = lxq("query sceneservice item.bounds ? {$id}");	}
	else															{	@bounds = lxq("query layerservice layer.bounds ? {$id}");	}
	lxout("bounds = @bounds");
	my @intSize_2d = ( int($bounds[3] - $bounds[0]+.5) , int($bounds[4] - $bounds[1]+.5) );
	my $size = $intSize_2d[0].",".$intSize_2d[1];
	push(@{$itemSizeTable{$size}},$id);
	push(@itemSizes,$size);
	
	if ($intSize_2d[1] == 1)							{	push(@itemSizes_Nx1,$size);	}
	if (($intSize_2d[0] == 2) && ($intSize_2d[1] == 1))	{	push(@itemSizes_2x1,$size);	}
	if (($intSize_2d[0] == 1) && ($intSize_2d[1] == 1))	{	push(@itemSizes_1x1,$size);	}
}

##------------------------------------------------------------------------------------------------------------
##CREATE ORIGINAL MESH TRANSFORMS IF MISSING
##------------------------------------------------------------------------------------------------------------
foreach my $id (@children){
	my $posXfrmID = lxq("query sceneservice item.xfrmPos ? {$id}");
	my $sclXfrmID = lxq("query sceneservice item.xfrmScl ? {$id}");
	if ($posXfrmID eq ""){lx("!!transform.add type:{pos} item:{$id}");}
	if ($sclXfrmID eq ""){lx("!!transform.add type:{scl} item:{$id}");}
}

##------------------------------------------------------------------------------------------------------------
##SETUP TABLES FOR LAST USED MESHES AND DIMENSIONS
##------------------------------------------------------------------------------------------------------------
foreach my $key (keys %itemSizeTable){
	$itemLastUsedTable{$key} = 0;
	@{$itemSizeDimensions{$key}} = split/,/,$key;
}

##------------------------------------------------------------------------------------------------------------
##START PLACING BRICKS RANDOMLY UNTIL THE ODDS OF FINDING A FREE SPOT RANDOMLY BECOME TOO LOW
##------------------------------------------------------------------------------------------------------------
while ($blocksLeft > 0){
	if ($consecutiveFailCount >= 50){
		#popup("hrmm. i've failed more than 50 times in a row.  it's getting slow so i should give up and pack the remaining gaps unrandomly..");
		last;
	}
	
	my $randPosU = int(rand($count+.5));
	my $randPosV = int(rand($count+.5));
	my $randItemType = $itemSizes[int(rand($#itemSizes+.5))];
	my $meshID = findNextID($randItemType); 
	my @size = @{$itemSizeDimensions{$randItemType}};
	my @answer = findSpaceForBlock($randPosU,$randPosV,$size[0],$size[1]);
	placeRock($meshID,\@size,\@answer);
}

##------------------------------------------------------------------------------------------------------------
##NOW FILL THE HOLES THAT ARE TOO HARD TO FIND RANDOMLY
##------------------------------------------------------------------------------------------------------------
for (my $v=0; $v<$count; $v++){
	for (my $u=0; $u<$count; $u++){
		if (${$usedBlocks{$u}}{$v} == 0){
			my $emptyBlocksToRight = findNumEmptyBlocksToRight($u,$v);
			while ($emptyBlocksToRight > 0){
				my $debug = 0;
				my $blockWidth = 0;
				my $meshID = "";
				my @pos = (0,$v);
				
				if ($emptyBlocksToRight > 2){
					my $randBlockSize = $itemSizes_Nx1[int(rand($#itemSizes_Nx1 + .5))];
					my @size = split/,/,$randBlockSize;
					
					if ($size[0] <= $emptyBlocksToRight){
						$blockWidth = $size[0];
						$meshID = findNextID($randBlockSize);
						$pos[0] = $u + $blockWidth-1;
					}
				}
				
				elsif	($emptyBlocksToRight == 2){
					$blockWidth = 2;
					$meshID = findNextID("2,1");
					$pos[0] = $u+1;
				}
				
				elsif	($emptyBlocksToRight == 1){
					$blockWidth = 1;
					$meshID = findNextID("1,1");
					$pos[0] = $u;
				}
				
				if ($meshID ne ""){
					my @size = ($blockWidth,1);
					my @answer = (1,$pos[0],$pos[1]);
					$u += $blockWidth;
					$emptyBlocksToRight -= $blockWidth;
					placeRock($meshID,\@size,\@answer);
				}
			}
		}
	}
}

##------------------------------------------------------------------------------------------------------------
##NOW PUT ALL THE NEW MESHES INTO A GROUP AND PUT IT IN THE ROOT
##------------------------------------------------------------------------------------------------------------
lx("!!select.drop item");
lx("!!select.subItem {$_} add mesh;meshInst;camera;light;txtrLocator;backdrop;groupLocator;replicator;surfGen;locator;deform;locdeform;deformGroup;deformMDD2;morphDeform;itemInfluence;genInfluence;deform.wrap;softLag;ABCCurvesDeform.sample;ABCdeform.sample;chanModify;chanEffect;defaultShader;defaultShader 0 0") for @createdInstances;
lx("!!layer.groupSelected");
my @groupLocatorSel = lxq("query sceneservice selection ? groupLocator");
lx("!!item.parent {$groupLocatorSel[0]} {} -1 inPlace:1");
lx("item.name {Stone Wall Group} groupLocator");










##------------------------------------------------------------------------------------------------------------
##------------------------------------------------------------------------------------------------------------
##FIND CONSECUTIVE EMPTY BLOCKS TO RIGHT
##------------------------------------------------------------------------------------------------------------
##------------------------------------------------------------------------------------------------------------
sub findNumEmptyBlocksToRight{
	my $unusedBlocks = 1;
	for (my $i=1; $i<$count; $i++){
		if		($_[0]+1 >= $count)						{	return $unusedBlocks;	}
		elsif	(${$usedBlocks{$_[0]+$i}}{$_[1]} == 0)	{	$unusedBlocks++;		}
		else											{	return $unusedBlocks;	}
	}
}

##------------------------------------------------------------------------------------------------------------
##------------------------------------------------------------------------------------------------------------
##PLACE ROCK sub
##------------------------------------------------------------------------------------------------------------
##------------------------------------------------------------------------------------------------------------
#usage : placeRock($meshID,\@size,\@answer);
sub placeRock{
	if (${$_[2]}[0] == 1){
		#fill used blocks into table
		my $tilingMeshU = 0;
		my $tilingMeshV = 0;
		my $randFlipX = int(rand(1.5));
		my $randFlipY = int(rand(1.5));


		for (my $u=0; $u<${$_[1]}[0]; $u++){
			for (my $v=0; $v<${$_[1]}[1]; $v++){
				my $celA = ${$_[2]}[1]-$u;
				my $celB = ${$_[2]}[2]-$v;
				if		($celA < 0)			{	$celA += $count;	$tilingMeshU = 1;	}
				elsif	($celA >= $count)	{	$celA -= $count;	$tilingMeshU = 2;	}
				if		($celB < 0)			{	$celB += $count;	$tilingMeshV = 1;	}
				elsif	($celB >= $count)	{	$celB -= $count;	$tilingMeshV = 2;	}
				${$usedBlocks{$celA}}{$celB} = 1;
			}
		}
		$blocksLeft -= ${$_[1]}[0]*${$_[1]}[1];
		$consecutiveFailCount = 0;

		#place brick
		my $posX = ${$_[2]}[1]+1 - (${$_[1]}[0]*.5);
		my $posY = ${$_[2]}[2]+1 - (${$_[1]}[1]*.5);
		
		instanceCreate($posX,$posY,0,$_[0]);
		if		($tilingMeshU == 1)								{	instanceCreate($posX+$count,$posY,0,$_[0],$randFlipX,$randFlipY);			} 
		elsif	($tilingMeshU == 2)								{	instanceCreate($posX-$count,$posY,0,$_[0],$randFlipX,$randFlipY);			}
		if		($tilingMeshV == 1)								{	instanceCreate($posX,$posY+$count,0,$_[0],$randFlipX,$randFlipY);			}
		elsif	($tilingMeshV == 2)								{	instanceCreate($posX,$posY-$count,0,$_[0],$randFlipX,$randFlipY);			}
		if		(($tilingMeshU == 1) && ($tilingMeshV == 1))	{	instanceCreate($posX+$count,$posY+$count,0,$_[0],$randFlipX,$randFlipY);	}
		elsif	(($tilingMeshU == 2) && ($tilingMeshV == 2))	{	instanceCreate($posX-$count,$posY-$count,0,$_[0],$randFlipX,$randFlipY);	}
	}else{
		#lxout("BLOCK COULDN'T FIT : (${$_[1]}[0],${$_[1]}[1])");
		$consecutiveFailCount++;
	}
}


##------------------------------------------------------------------------------------------------------------
##------------------------------------------------------------------------------------------------------------
##FIND NEXT MESHID sub
##------------------------------------------------------------------------------------------------------------
##------------------------------------------------------------------------------------------------------------
#usage : my $id = findNextID($randItemType);
sub findNextID{
	my $id = ${$itemSizeTable{$_[0]}}[$itemLastUsedTable{$_[0]}];
	
	if ($itemLastUsedTable{$_[0]} >= $#{$itemSizeTable{$_[0]}})	{	$itemLastUsedTable{$_[0]} = 0;	}
	else														{	$itemLastUsedTable{$_[0]}++;	}
	
	return $id;
}


##------------------------------------------------------------------------------------------------------------
##------------------------------------------------------------------------------------------------------------
##INSTANCE CREATOR sub
##------------------------------------------------------------------------------------------------------------
##------------------------------------------------------------------------------------------------------------
#usage : instanceCreate($posX,$posY,$posZ,$meshID,$flipX,$flipY);
sub instanceCreate{
	lx("!!select.item {$_[3]} set");
	lx("!!item.duplicate true locator");
	my $id = lxq("query sceneservice selection ? meshInst");
	lx("item.channel pos.X {$_[0]} set {$id}");
	lx("item.channel pos.Y {$_[1]} set {$id}");
	lx("item.channel pos.Z {0} set {$id}");
	if ($randFlipX == 1){	lx("!!item.channel scl.X {-1} set {$id}");			}
	if ($randFlipY == 1){	lx("!!item.channel scl.Y {-1} set {$id}");			}
	if ($forceBBOX == 1){	lx("!!item.channel drawShape {custom} set {$id}");	}
	push(@createdInstances,$id);
}




##------------------------------------------------------------------------------------------------------------
##------------------------------------------------------------------------------------------------------------
##FIND SPACE FOR BLOCK sub
##------------------------------------------------------------------------------------------------------------
##------------------------------------------------------------------------------------------------------------
#usage : my @position = findSpaceForBlock($chosenPointU,$chosenPointV,$blockWidth,$blockHeight);
#note1 : returns (0,0) if it couldn't find any empty spot around the chosen point
#note2 : the subroutine searches the exact amount of width and height of the block for an empty spot plus padding
#note3 : uses the $padding cvar to see how much area around the chosen point it should search)
#note4 : requires %table that lists all the open and full slots and $count that lists the table dimensions
sub findSpaceForBlock{
	my $roundsU = $_[2]+$padding;
	my $roundsV = $_[3]+$padding;

	for (my $i=0; $i<$roundsU; $i++){
		for (my $j=0; $j<$roundsV; $j++){
			my $fail = 0;

			LINE:
			for (my $u=0; $u<$_[2]; $u++){

				for (my $v=0; $v<$_[3]; $v++){
					my $celA = $_[0]-$i-$u;
					my $celB = $_[1]-$j-$v;
					if		($celA < 0)			{	$celA += $count;	}
					elsif	($celA >= $count)	{	$celA -= $count;	}
					if		($celB < 0)			{	$celB += $count;	}
					elsif	($celB >= $count)	{	$celB -= $count;	}
					
					if (${$usedBlocks{$celA}}{$celB} == 1){
						$fail = 1;
						last LINE;
					}
				}
			}

			if ($fail == 0){
				return(1,$_[0]-$i,$_[1]-$j);
			}
		}
	}
	
	return (0,0);
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