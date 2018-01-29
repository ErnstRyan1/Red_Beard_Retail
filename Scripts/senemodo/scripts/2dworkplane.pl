#perl
#AUTHOR: Seneca Menard
#version 2.01

# Select two verts and then run script with proper "AXIS" appended to the end of script:
# example: @2dworkplane.pl y
# -NOTE: if you have multiple layers selected, the script only works for the "main" selected layer (the one you selected first)
# -It now works if you had selected more than 2 verts (or 1 edge).
# -modo2 update : it now handles edges better.
# -(11-27-06 update) : it now properly "rounds" the angle and so the workplane's angle will now be as close to the original angle as possible.
# -(12-18-08 fix) : I went and removed the square brackets so that the numbers will always be read as metric units and also because my prior safety check would leave the unit system set to metric system if the script was canceled because changing that preference doesn't get undone if a script is cancelled.
# -(2-16-15 fix) : fixed a bug in the roundNumber sub

my $mainlayer = lxq("query layerservice layers ? main");
my $pi=3.1415926535897932384626433832795;
my $radian;
my $angle;
my $disp1;
my $disp2;
my $sel_type;
my @firstVertPos;
my @secondVertPos;
my $greatestAxis;

#------------------------------------------------------------------------------------
#Looks at what's selected
#------------------------------------------------------------------------------------
if (lxq( "select.typeFrom {edge;vertex;polygon;item} ?" ) && lxq( "select.count edge ?" )){
	$sel_type= "edge";
	#Get and edit the original edge list *throw away all edges that aren't in mainlayer* (FIXED FOR MODO2)
	my @origEdgeList = lxq("query layerservice selection ? edge");
	my @tempEdgeList;
	foreach my $edge (@origEdgeList){	if ($edge =~ /\($mainlayer/){	push(@tempEdgeList,$edge);		}	}
	#[remove layer info] [remove ( ) ]
	@origEdgeList = @tempEdgeList;
	s/\(\d{0,},/\(/  for @origEdgeList;
	tr/()//d for @origEdgeList;

	my @verts = split (/[^0-9]/, @origEdgeList[0]);
	lx("select.drop vertex");
	lx("select.element [$mainlayer] vertex add index:@verts[0]");
	lx("select.element [$mainlayer] vertex add index:@verts[1]");
	&angleCheck;
}
elsif (lxq( "select.typeFrom {vertex;edge;polygon;item} ?" ) && lxq( "select.count vertex ?" )){
	$sel_type= "vertex";
	my @importantVerts = pointDispSort();
	lx("select.drop vertex");
	lx("select.element [$mainlayer] vertex add index:@importantVerts[0]");
	lx("select.element [$mainlayer] vertex add index:@importantVerts[1]");
	&angleCheck;
}
else{
	die("\n.\n[------------------------------------------------You must select an edge or two vertices--------------------------------------------]\n[--PLEASE TURN OFF THIS WARNING WINDOW by clicking on the (In the future) button and choose (Hide Message)--] \n[-----------------------------------This window is not supposed to come up, but I can't control that.---------------------------]\n.\n");
}


#------------------------------------------------------------------------------------
#Finds the angle of the line.
#------------------------------------------------------------------------------------
sub angleCheck{
	my @selectedVerts = lxq("query layerservice verts ? selected");
	@firstVertPos = lxq("query layerservice vert.pos ? @selectedVerts[0]");
	@secondVertPos = lxq("query layerservice vert.pos ? @selectedVerts[1]");

	my @displacement = (@secondVertPos[0]-@firstVertPos[0],@secondVertPos[1]-@firstVertPos[1],@secondVertPos[2]-@firstVertPos[2]);

	if		($ARGV[0] eq "x"){
		$disp1 = @displacement[1];
		$disp2 = @displacement[2];
	}
	elsif	($ARGV[0] eq "y")	{
		$disp1 = @displacement[2];
		$disp2 = @displacement[0];
	}
	elsif	($ARGV[0] eq "z"){
		$disp1 = @displacement[0];
		$disp2 = @displacement[1];
	}
	elsif	($ARGV[0] eq "auto"){
		my $viewport = lxq("query view3dservice mouse.view ?");
		my @axis = lxq("query view3dservice view.axis ? $viewport");
		my @xAxis = (1,0,0);
		my @yAxis = (0,1,0);
		my @zAxis = (0,0,1);
		my @dpAxes = ( abs(dotProduct(\@axis,\@xAxis)) , abs(dotProduct(\@axis,\@yAxis)) , abs(dotProduct(\@axis,\@zAxis)) );

		if ($dpAxes[0] > $dpAxes[1])				{	$greatestAxis = 0;	}
		else										{	$greatestAxis = 1;	}
		if ($dpAxes[2] > $dpAxes[$greatestAxis])	{	$greatestAxis = 2;	}

		if		($greatestAxis == 0){
			$disp1 = @displacement[1];
			$disp2 = @displacement[2];
		}elsif	($greatestAxis == 1){
			$disp1 = @displacement[2];
			$disp2 = @displacement[0];
		}else{
			$disp1 = @displacement[0];
			$disp2 = @displacement[1];
		}
	}

	my @vector = correct3DVectorDir($disp1,$disp2);
	$radian=atan2(@vector[0],@vector[1]);
	$angle=($radian*180)/$pi;

	#-------------------------------------------------------------------
	#NOW I MUST ROUND OUT THE ANGLE.
	#-------------------------------------------------------------------
	if		($angle > 315)	{	$angle = 360 - $angle;	}
	elsif	($angle > 270)	{	$angle = 270 - $angle;	}
	elsif	($angle > 225)	{	$angle = 270 - $angle;	}
	elsif	($angle > 180)	{	$angle = 180 - $angle;	}
	elsif	($angle > 135)	{	$angle = 180 - $angle;	}
	elsif	($angle > 90)	{	$angle = 90 - $angle;	}
	elsif	($angle > 45)	{	$angle = 90 - $angle;	}
	else					{	$angle = 360 - $angle;	}
}



#------------------------------------------------------------------------------------
#sets the workplane
#------------------------------------------------------------------------------------
my $WP_X;
my $WP_Y;
my $WP_Z;

if ($flipped == 1){
	$WP_X = @secondVertPos[0];
	$WP_Y = @secondVertPos[1];
	$WP_Z = @secondVertPos[2];
}else{
	$WP_X = @firstVertPos[0];
	$WP_Y = @firstVertPos[1];
	$WP_Z = @firstVertPos[2];
}

if 		($ARGV[0] eq "z")		{	lx("workPlane.edit {$WP_X} {$WP_Y} {0} {0} {0} {$angle}");	}
elsif	($ARGV[0] eq "y")		{	lx("workPlane.edit {$WP_X} {0} {$WP_Z} {0} {$angle} {0}");	}
elsif 	($ARGV[0] eq "x")		{	lx("workPlane.edit {0} {$WP_Y} {$WP_Z} {$angle} {0} {0}");	}
elsif	($ARGV[0] eq "auto")	{
	if    ($greatestAxis == 0)	{	lx("workPlane.edit {0} {$WP_Y} {$WP_Z} {$angle} {0} {0}");	}
	elsif ($greatestAxis == 1)	{	lx("workPlane.edit {$WP_X} {0} {$WP_Z} {0} {$angle} {0}");	}
	elsif ($greatestAxis == 2)	{	lx("workPlane.edit {$WP_X} {$WP_Y} {0} {0} {0} {$angle}");	}
}



#------------------------------------------------------------------------------------
#set the selection settings back
#------------------------------------------------------------------------------------
lx("select.type $sel_type");









#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------SUBROUTINES--------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#POPUP SUB #(MODO2 FIX)
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
sub popup{
	lx("dialog.setup yesNo");
	lx("dialog.msg {@_}");
	lx("dialog.open");
	my $confirm = lxq("dialog.result ?");
	if($confirm eq "no"){die;}
}

#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#CHECK FOR FARTHEST (axes) DISPLACED VERTS subroutine
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
sub pointDispSort{
	#GO thru the args and see which disp axes we wanna check.
	lxout("[->] Using pointDispSort subroutine-------------------------------------");
	my $alignX = 1;
	my $alignY = 1;
	my $alignZ = 1;
	foreach $arg(@ARGV)
	{
		if ($arg eq "x")	{ $alignX = 0; }
		if ($arg eq "y")	{ $alignY = 0; }
		if ($arg eq "z")	{ $alignZ = 0; }
	}
	lxout("alignX = $alignX");
	lxout("alignY = $alignY");
	lxout("alignZ = $alignZ");


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
		#lxout("disp = @disp");
		my $addedDisp = (abs(@disp[0]) + abs(@disp[1]) + abs(@disp[2]));
		#lxout("GD = $greatestDisp <> addedDisp = $addedDisp");

		if ($addedDisp > $greatestDisp)
		{
			$greatestDisp = $addedDisp;
			$farthestVert = @verts[$i];
		}
		#lxout("$farthestVert has the greatest addedDisp! ($greatestDisp)");
	}
	return($firstVert,$farthestVert);
}




#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#CORRECT THE VECTOR DIRECTION
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
sub correct3DVectorDir{
	my @vector = @_;

	#find important axis
	if (abs(@vector[0]) > abs(@vector[1]))	{	our $importantAxis = 0;	}
	else								{	our $importantAxis = 1;	}

	#if both rounded axes are equal and U is negative, flip it.
	if (int(abs(@vector[0]*1000000)+.5) == int(abs(@vector[1]*1000000)+.5)){
		if (@vector[0] < 0){
			our $flipped = 1;
			@vector[0] *= -1;
			@vector[1] *= -1;
		}
	}

	#else if the important axis is negative, flip it.
	elsif (@vector[$importantAxis]<0){
		our $flipped = 1;
		@vector[0] *= -1;
		@vector[1] *= -1;
	}

	return @vector;
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
#DOT PRODUCT subroutine (ver 1.1)
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE : my $dp = dotProduct(\@vector1,\@vector2);
sub dotProduct{
	return (	(${$_[0]}[0]*${$_[1]}[0])+(${$_[0]}[1]*${$_[1]}[1])+(${$_[0]}[2]*${$_[1]}[2])	);
}