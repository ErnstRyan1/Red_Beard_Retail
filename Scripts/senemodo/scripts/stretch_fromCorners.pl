#perl
#ver 1.0
#author : Seneca Menard

#this script will set the pivot point on the corner of the selection's bbox in the direction you specify through the popup gui.  it's good for stretching things from the bottom left or top right or whatnot

##------------------------------------------------------------------------------------------------------------
# SCRIPT ARGS
##------------------------------------------------------------------------------------------------------------
foreach my $arg (@ARGV){
	if		($arg eq "up")			{	our @mouseAxis = (1,2);	}
	elsif	($arg eq "upRight")		{	our @mouseAxis = (2,2);	}
	elsif	($arg eq "right")		{	our @mouseAxis = (2,1);	}
	elsif	($arg eq "downRight")	{	our @mouseAxis = (2,0);	}
	elsif	($arg eq "down")		{	our @mouseAxis = (1,0);	}
	elsif	($arg eq "downLeft")	{	our @mouseAxis = (0,0);	}
	elsif	($arg eq "down")		{	our @mouseAxis = (1,0);	}
	elsif	($arg eq "left")		{	our @mouseAxis = (0,1);	}
	elsif	($arg eq "upLeft")		{	our @mouseAxis = (0,2);	}
}


##------------------------------------------------------------------------------------------------------------
# GET VIEWPORT DIR
##------------------------------------------------------------------------------------------------------------
my $viewport = lxq("query view3dservice mouse.view ?");
my $viewportType = lxq("query view3dservice view.type ? $viewport");
my @axis = lxq("query view3dservice view.axis ? $viewport");
my $viewportAxis;
my @xAxis = (1,0,0);
my @yAxis = (0,1,0);
my @zAxis = (0,0,1);
my $dp0 = dotProduct(\@axis,\@xAxis);
my $dp1 = dotProduct(\@axis,\@yAxis);
my $dp2 = dotProduct(\@axis,\@zAxis);
if 		((abs($dp0) >= abs($dp1)) && (abs($dp0) >= abs($dp2)))	{	$viewportAxis = 0;	lxout("[->] : Using world X axis");	}
elsif	((abs($dp1) >= abs($dp0)) && (abs($dp1) >= abs($dp2)))	{	$viewportAxis = 1;	lxout("[->] : Using world Y axis");	}
else															{	$viewportAxis = 2;	lxout("[->] : Using world Z axis");	}
if (($moveDir eq "up") || ($moveDir eq "right"))				{	$lesserOrGreater = "greater";							}


##------------------------------------------------------------------------------------------------------------
# MAIN
##------------------------------------------------------------------------------------------------------------
my $mainlayer = lxq("query layerservice layers ? main");
my $selType;
my @bbox;
my @pivotPos;
if		( lxq( "select.typeFrom {vertex;edge;polygon;item} ?" ) ) {$selType = "vertex";}
elsif	( lxq( "select.typeFrom {edge;polygon;item;vertex} ?" ) ) {lx("select.convert vertex"); $selType = "edge";}
elsif	( lxq( "select.typeFrom {polygon;item;vertex;edge} ?" ) ) {lx("select.convert vertex"); $selType = "polygon";}
else	{die("\\\\n.\\\\n[---------------------------------------------You're not in vert, edge, or polygon mode.--------------------------------------------]\\\\n[--PLEASE TURN OFF THIS WARNING WINDOW by clicking on the (In the future) button and choose (Hide Message)--] \\\\n[-----------------------------------This window is not supposed to come up, but I can't control that.---------------------------]\\\\n.\\\\n");}

my @verts = lxq("query layerservice verts ? selected");
if (@verts == 0){die("You don't have any geometry selected and so I'm cancelling the script");}
@bbox = boundingbox(\@verts);

if		($viewportAxis == 0){
	my @bboxU = ($bbox[5] , ($bbox[2]+$bbox[5])*.5 , $bbox[2]);
	my @bboxV = ($bbox[1] , ($bbox[1]+$bbox[4])*.5 , $bbox[4]);
	@pivotPos = (($bbox[0]+$bbox[3])*.5 , $bboxV[$mouseAxis[1]] , $bboxU[$mouseAxis[0]]);
}elsif	($viewportAxis == 1){
	my @bboxU = ($bbox[0] , ($bbox[0]+$bbox[3])*.5 , $bbox[3]);
	my @bboxV = ($bbox[5] , ($bbox[2]+$bbox[5])*.5 , $bbox[2]);
	@pivotPos = ($bboxU[$mouseAxis[0]] , ($bbox[1]+$bbox[4])*.5 , $bboxV[$mouseAxis[1]]);
}elsif	($viewportAxis == 2){
	my @bboxU = ($bbox[0] , ($bbox[0]+$bbox[3])*.5 , $bbox[3]);
	my @bboxV = ($bbox[1] , ($bbox[1]+$bbox[4])*.5 , $bbox[4]);
	@pivotPos = ($bboxU[$mouseAxis[0]] , $bboxV[$mouseAxis[1]] , ($bbox[2]+$bbox[5])*.5);
}

m3PivPos(set,lxq("query layerservice layer.id ? $mainlayer"),@pivotPos);
lx("select.type $selType");
lx("tool.set xfrm.stretch on");
lx("tool.set center.pivot on");
lx("tool.set axis.auto on");




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
#BOUNDING BOX (modded to use the original array and not dupe it)
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE : my @bbox = boundingbox(\@selectedVerts);
sub boundingbox #minX-Y-Z-then-maxX-Y-Z
{
	my $firstVert = @{$_[0]}[0];
	lxout("firstVert = $firstVert");
	my @firstVertPos = lxq("query layerservice vert.pos ? $firstVert");
	lxout("firstVertPos = @firstVertPos");
	my $minX = @firstVertPos[0];
	my $minY = @firstVertPos[1];
	my $minZ = @firstVertPos[2];
	my $maxX = @firstVertPos[0];
	my $maxY = @firstVertPos[1];
	my $maxZ = @firstVertPos[2];

	foreach my $bbVert(@{$_[0]}){
		lxout("bbVert = $bbVert");
		my @bbVertPos = lxq("query layerservice vert.pos ? $bbVert");
		lxout("@bbVertPos[2]");
		if (@bbVertPos[0] < $minX)	{	$minX = @bbVertPos[0];	}
		if (@bbVertPos[1] < $minY)	{	$minY = @bbVertPos[1];	}
		if (@bbVertPos[2] < $minZ)	{	$minZ = @bbVertPos[2];	}
		if (@bbVertPos[0] > $maxX)	{	$maxX = @bbVertPos[0];	}
		if (@bbVertPos[1] > $maxY)	{	$maxY = @bbVertPos[1];	}
		if (@bbVertPos[2] > $maxZ)	{	$maxZ = @bbVertPos[2];	}
	}
	my @bbox = ($minX,$minY,$minZ,$maxX,$maxY,$maxZ);
	return @bbox;
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