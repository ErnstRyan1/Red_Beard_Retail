#perl 
#ver 1.01
#author : Seneca Menard
#note : requires strawberry perl and the Win32::clipboard module is installed beforehand.  You install the clipboard module by running ""
#This script will take note of your selected meshInstances and copy their names/transforms to the windows clipboard.  You can then go into ue4 and paste the entities into place.  The instances must have the same names as the meshes and the meshes must be in a dir called "Meshes"


#(4-23-15 fix) : put in more rounding into item scales to try and get it to snap to .25 increments if close enough.

#setup
my $pi = 3.14159265358979323;
my $scriptDir = lxq("query platformservice path.path ? scripts");
$scriptDir =~ s/\\/\//g;
my $textFile = $scriptDir . "\/" . "unreal_clipboard.txt";

#start the unreal text
my $text = "";
$text .= "Begin Map\n";
$text .= "   Begin Level\n";
my @meshInsts = lxq("query sceneservice selection ? meshInst");
if (@meshInsts == 0){die("You don't have any mesh instances selected and so i'm cancelling the script");}


#create empty group locator
lx("!!item.create groupLocator");
my $groupID = lxq("query sceneservice selection ? groupLocator");
lx("!!transform.add type:{rot} item:{$groupID}");

#go through each item and get their transforms and add to text cvar
my $count = 0;
foreach my $id (@meshInsts){
	#setup
	$count++;
	my $name = lxq("query sceneservice item.name ? {$id}");
	$name =~ s/ \([0-9]+\)$//;
	my $entityName = $name . "_" . $count;
	my @worldPos = lxq("query sceneservice item.worldPos ? {$id}");
	my @worldScl = lxq("query sceneservice item.scale ? {$id}");
	my @worldRot = ();

	#get unreal rotation
	lx("!!item.channel rot.X {0} set {$groupID}");
	lx("item.parent {$id} {$groupID} 0 inPlace:1");
	lx("!!item.channel rot.X {90} set {$groupID}");
	lx("!!item.parent {$id} {} -1 inPlace:1");
	lx("select.subItem {$id} set mesh;meshInst;camera;light;txtrLocator;backdrop;groupLocator;replicator;surfGen;locator;deform;locdeform;deformGroup;deformMDD2;morphDeform;itemInfluence;genInfluence;deform.wrap;softLag;ABCdeform.sample;chanModify;chanEffect;defaultShader;defaultShader 0 0");
	
	@worldRot = (
		(lxq("item.channel rot.X {?} set {$id}") - 90) * -1,
		 lxq("item.channel rot.Y {?} set {$id}"),
		 lxq("item.channel rot.Z {?} set {$id}") * -1,
	);
	$worldRot[0] *= -1;
	$worldRot[1] *= -1;
	
	#wheher to ignore xfrms or not
	my $ignorePos = 0;
	my $ignoreRot = 0;
	my $ignoreScl = 0;
		if ((abs(0 - $worldPos[0])< 0.00001) && (abs(0 - $worldPos[1])< 0.00001) && (abs(0 - $worldPos[2])< 0.00001)){	$ignorePos = 1;	}
		if ((abs(0 - $worldRot[0])< 0.00001) && (abs(0 - $worldRot[1])< 0.00001) && (abs(0 - $worldRot[2])< 0.00001)){	$ignoreRot = 1;	}
		if ((abs(1 - $worldScl[0])< 0.00001) && (abs(1 - $worldScl[1])< 0.00001) && (abs(1 - $worldScl[2])< 0.00001)){	$ignoreScl = 1;	}

	#round decimals
	if ($ignorePos == 0){	for (my $i=0; $i<@worldPos; $i++){	$worldPos[$i] = roundDecimal($worldPos[$i],6);	}	}
	if ($ignoreRot == 0){	for (my $i=0; $i<@worldRot; $i++){	$worldRot[$i] = roundDecimal($worldRot[$i],6);	}	}
	if ($ignoreScl == 0){	for (my $i=0; $i<@worldScl; $i++){	$worldScl[$i] = roundDecimal(roundNumberIfInRange($worldScl[$i],.25,.0401),6);	}	}
	lxout("ignoreScl = $ignoreScl <> worldScl = @worldScl");

	#print text
	$text .= "      Begin Actor Class=StaticMeshActor Name=".$entityName." Archetype=StaticMeshActor'/Script/Engine.Default__StaticMeshActor'\n";
	$text .= "         Begin Object Class=StaticMeshComponent Name=\"StaticMeshComponent0\" Archetype=StaticMeshComponent'/Script/Engine.Default__StaticMeshActor:StaticMeshComponent0'\n";
	$text .= "         End Object\n";
	$text .= "         Begin Object Name=\"StaticMeshComponent0\"\n";
	$text .= "            StaticMesh=StaticMesh'/Game/Meshes/".$name.".".$name."'\n";
	#$text .= "            StaticMeshDerivedDataKey=\"STATICMESH_46A8778361B442A9523C54440EA1E9D_0db5412b27ab480f844cc7f0be5abaff_59DE079E471240709F0C8BB2A7DFA8F500000000010000000100000000000000010000004000000000000000010000000000803F0000803F0000803F0000803F000000000000803F00000000000000000000344203030300000000\"\n";
	#$text .= "            bHasCachedStaticLighting=True\n";
	#$text .= "            VisibilityId=20\n";
	#$text .= "            Materials(0)=MaterialInstanceConstant'/Game/Materials/pebbles_snow.pebbles_snow'";
	if ($ignoreScl == 0){	$text .= "            BodyInstance=(Scale3D=(X=".$worldScl[0].",Y=".$worldScl[2].",Z=".$worldScl[1]."))\n";		}
	if ($ignorePos == 0){	$text .= "            RelativeLocation=(X=".$worldPos[0].",Y=".$worldPos[2].",Z=".$worldPos[1].")\n";			}
	if ($ignoreRot == 0){	$text .= "            RelativeRotation=(Pitch=".$worldRot[1].",Yaw=".$worldRot[2].",Roll=".$worldRot[0].")\n";	}
	if ($ignoreScl == 0){	$text .= "            RelativeScale3D=(X=".$worldScl[0].",Y=".$worldScl[2].",Z=".$worldScl[1].")\n";			}
	$text .= "            CustomProperties \n";
	$text .= "         End Object\n";
	$text .= "         StaticMeshComponent=StaticMeshComponent0\n";
	$text .= "         RootComponent=StaticMeshComponent0\n";
	$text .= "         ActorLabel=\"".$entityName."\"\n";
	$text .= "      End Actor\"\n";
}

$text .= "   End Level\n";
$text .= "Begin Surface\n";
$text .= "End Surface\n";
$text .= "End Map\n";


open (FILE, ">$textFile");
print FILE ($text);
close (FILE);
my $perlFile = $scriptDir."\/senemodo\/scripts\/copyFileTextToWinCopyBuffer.pl";
my @args = ("perl.exe" , $perlFile , $textFile);
system(@args);

die("I'm killing the script to undo all the item moves.  disregard this popup");



#=====================================================================================================================================================================================================================
#=====================================================================================================================================================================================================================
#=====================================================================================================================================================================================================================
#=====================================================================================================================================================================================================================
#=====================================================================================================================================================================================================================
#=====================================================================================================================================================================================================================
#=====================================================================================================================================================================================================================
#=====================================================================================================================================================================================================================
#===															 SUBROUTINES										          ========================================================================================
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


#FRotationTranslationMatrix::FRotationTranslationMatrix(const FRotator& Rot, const FVector& Origin)
#{
	#const FLOAT       SR           = GMath.SinTab(Rot.Roll);
	#const FLOAT       SP           = GMath.SinTab(Rot.Pitch);
	#const FLOAT       SY           = GMath.SinTab(Rot.Yaw);
	#const FLOAT       CR           = GMath.CosTab(Rot.Roll);
	#const FLOAT       CP           = GMath.CosTab(Rot.Pitch);
	#const FLOAT       CY           = GMath.CosTab(Rot.Yaw);
	#
	#M[0][0]                = CP * CY;
	#M[0][1]                = CP * SY;
	#M[0][2]                = SP;
	#M[0][3]                = 0.f;
	#
	#M[1][0]                = SR * SP * CY - CR * SY;
	#M[1][1]                = SR * SP * SY + CR * CY;
	#M[1][2]                = - SR * CP;
	#M[1][3]                = 0.f;
	#
	#M[2][0]                = -( CR * SP * CY + SR * SY );
	#M[2][1]                = CY * SR - CR * SP * SY;
	#M[2][2]                = CR * CP;
	#M[2][3]                = 0.f;
	#
	#M[3][0]                = Origin.X;
	#M[3][1]                = Origin.Y;
	#M[3][2]                = Origin.Z;
	#M[3][3]                = 1.f;
#} 

sub mtxToEuler_epic{
	my $x_x = ${$_[0]}[0][0];
	my $x_y = ${$_[0]}[0][1];
	my $x_z = ${$_[0]}[0][2];

	my $x = atan2( $x_z, sqrt(square($x_x)+square($x_y)) ) * 180 / $pi; 
	my $y = atan2( $x_y, $x_x ) * 180 / $pi;
	my $z = 0 ;
	
	lxout("yaw=$x pitch=$y roll=$z");
	
	return ($x,$y,$z);
	#$z = atan2( dotProduct(ZAxis,SYAxis) , dotProduct(YAxis,SYAxis) ) * 180 / $pi;
}

sub square{
	return $_[0] * $_[0];
}

sub mtxHandFlip2{
	my $b = $_[0];
	lxout("blah <> ${$_[0]}[0][0]");
	
	my @mtx = (
		[ ${$_[0]}[2][0] , ${$_[0]}[2][1] , ${$_[0]}[2][2] , 0 ],
		#[ -1*${$_[0]}[2][0] , -1*${$_[0]}[2][1] , -1*${$_[0]}[2][2] , 0 ],
		[ ${$_[0]}[0][0] , ${$_[0]}[0][1] , ${$_[0]}[0][2] , 0 ],
		[ ${$_[0]}[1][0] , ${$_[0]}[1][1] , ${$_[0]}[1][2] , 0 ],
		[ 0              , 0              , 0              , 1 ]
	);
	
	printMatrix(\@mtx);
	
	return @mtx;
}

sub mtxHandFlip{
	my $b = $_[0];
	lxout("blah <> ${$_[0]}[0][0]");
	
	my @mtx = (
		[ ${$_[0]}[0][0] , ${$_[0]}[0][2] , ${$_[0]}[0][1] , 0 ],
		[ ${$_[0]}[1][0] , ${$_[0]}[1][2] , ${$_[0]}[1][1] , 0 ],
		[ ${$_[0]}[2][0] , ${$_[0]}[2][2] , ${$_[0]}[2][1] , 0 ],
		[ ${$_[0]}[3][0] , ${$_[0]}[3][2] , ${$_[0]}[3][1] , 1 ]
	);
	
	return @mtx;
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
#PRINT MATRIX (3x3)
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#usage : printMatrix(\@matrix);
sub printMatrix{
	lxout("==========");
	for (my $i=0; $i<3; $i++){
		for (my $u=0; $u<3; $u++){
			my $blah = roundDecimal(${$_[0][$i]}[$u],3);
			lxout("[$i][$u] = $blah");
		}
		lxout("\n");
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

#=====================================================================================================================================================================================================================
#=====================================================================================================================================================================================================================
#=====================================================================================================================================================================================================================
#=====================================================================================================================================================================================================================
#=====================================================================================================================================================================================================================
#=====================================================================================================================================================================================================================
#=====================================================================================================================================================================================================================
#=====================================================================================================================================================================================================================
#===														EXAMPLE COPY										          ========================================================================================
#=====================================================================================================================================================================================================================
#=====================================================================================================================================================================================================================
#=====================================================================================================================================================================================================================
#=====================================================================================================================================================================================================================
#=====================================================================================================================================================================================================================
#=====================================================================================================================================================================================================================
#=====================================================================================================================================================================================================================
#=====================================================================================================================================================================================================================

#Begin Map
#   Begin Level
#      Begin Actor Class=StaticMeshActor Name=boards4 Archetype=StaticMeshActor'/Script/Engine.Default__StaticMeshActor'
#         Begin Object Class=StaticMeshComponent Name="StaticMeshComponent0" Archetype=StaticMeshComponent'/Script/Engine.Default__StaticMeshActor:StaticMeshComponent0'
#         End Object
#         Begin Object Name="StaticMeshComponent0"
#            StaticMesh=StaticMesh'/Game/Meshes/boards1.boards1'
#            StaticMeshDerivedDataKey="STATICMESH_46A8778361B442A9523C54440EA1E9D_0db5412b27ab480f844cc7f0be5abaff_59DE079E471240709F0C8BB2A7DFA8F500000000010000000100000000000000010000004000000000000000010000000000803F0000803F0000803F0000803F000000000000803F00000000000000000000344203030300000000"
#            bHasCachedStaticLighting=True
#            VisibilityId=20
#            RelativeLocation=(X=1333.105591,Y=-268.105560,Z=167.000000)
#            RelativeRotation=(Pitch=-15.000000,Yaw=-45.000000,Roll=179.999893)
#            CustomProperties 
#         End Object
#         StaticMeshComponent=StaticMeshComponent0
#         RootComponent=StaticMeshComponent0
#         ActorLabel="boards4"
#      End Actor
#      Begin Actor Class=StaticMeshActor Name=boards7_26 Archetype=StaticMeshActor'/Script/Engine.Default__StaticMeshActor'
#         Begin Object Class=StaticMeshComponent Name="StaticMeshComponent0" Archetype=StaticMeshComponent'/Script/Engine.Default__StaticMeshActor:StaticMeshComponent0'
#         End Object
#         Begin Object Name="StaticMeshComponent0"
#            StaticMesh=StaticMesh'/Game/Meshes/boards1.boards1'
#            IrrelevantLights(0)=08351E9C44680FADB4F9B9B816D2BE35
#            StaticMeshDerivedDataKey="STATICMESH_46A8778361B442A9523C54440EA1E9D_0db5412b27ab480f844cc7f0be5abaff_59DE079E471240709F0C8BB2A7DFA8F500000000010000000100000000000000010000004000000000000000010000000000803F0000803F0000803F0000803F000000000000803F00000000000000000000344203030300000000"
#            bHasCachedStaticLighting=True
#            VisibilityId=24
#            RelativeLocation=(X=759.485168,Y=-304.284302,Z=209.000000)
#            RelativeRotation=(Pitch=-81.398621,Yaw=134.996796,Roll=0.000776)
#            CustomProperties 
#         End Object
#         StaticMeshComponent=StaticMeshComponent0
#         RootComponent=StaticMeshComponent0
#         ActorLabel="boards7"
#      End Actor
#   End Level
#Begin Surface
#End Surface
#End Map