#perl
#AUTHOR: Seneca Menard
#version 1.23
#This script is to perform a poly slice across the screen using the viewport's axis, and the angle you defined by selecting (2 verts) or (1 edge).
#OPTIONS :
# : "fullCut" : If you want the knife cut to extend beyond the bounds of your currently selected "angle", append this cvar and the knife cut will be expanded until it's a little bit bigger than the current viewport (so it should always make a knife cut that's big enough).
# : "worldAxis" : If you don't want to use the screen axis, but actually want to use one of the 3 world axes, append this cvar.  You don't have to choose which world axis, the script will do it automatically for you based off of which axis you're looking down the most.
# : "edgeAxis" : Use this cvar to cut your polys by the chosen edge's edge normal.

#here's an example of what you bind a key to if you want to have it perform a cut that will cover the screen, using the world axis.  "@knifeScreen.pl fullCut worldAxis"

#INSTALLATION INSTRUCTIONS :
#1) : copy the icons dir to your scripts dir.  (ie, in windows it's here : C:\Documents and Settings\{USERNAME}\Application Data\Luxology\Scripts\icons)
#2) : copy the .CFG and .PL files to your scripts dir : (C:\Documents and Settings\{USERNAME}\Application Data\Luxology\Scripts)
#3) : open modo and bind a hotkey to the sen_KnifeScreen form and you're all set.

#SPECIAL NOTE :
#this script queries which 3d viewport is under the mouse and so if you bind this script to a button that's outside the 3d modeling windows, the script will not correctly guess which window was the last active 3d window and so you won't get the cut you were looking for..

#(8-1-08 bugfix) : I removed all the [] chars and swapped them for {} chars to get around the measurement system issue
#(4-23-10 feature) : edgeAxis cut is added, so you can have some polys selected and select an edge and it will cut the polys along the edge's normal.
#(6-29-10 bugfix) : reordered the item ref application to stop the viewport from being moved.
#(2-15-12 feature) : the script now works if you're using (workplanes, item references, and item transforms). the screen actr cuts aren't working right now though because a feature's been removed apparently.
#(3-24-12 bugfix) : missing subroutine
#(1-10-14 fix) : got the actr storage system up to date with 601

my $mainlayer = lxq("query layerservice layers ? main");
my $mainlayerID = lxq("query layerservice layer.id ? $mainlayer");
my $pi = 3.14159265358979323;
my $selType;

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#---------------------------------------------------ARGS-------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
foreach my $arg (@ARGV){
	if		($arg =~ /fullCut/i)	{our $fullCut = 1;		}
	elsif	($arg =~ /worldAxis/i)	{our $worldAxis = 1;	}
	elsif	($arg =~ /vertical/i)	{our $vertical = 1;		}
	elsif	($arg =~ /horizontal/i)	{our $horizontal = 1;	}
	elsif	($arg =~ /edgeAxis/i)	{our $edgeAxis = 1;		}
	elsif	($arg =~ /polyNormal/i)	{our $polyNormal = 1;	}
}


#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#--------------------------------------SAFETY CHECKS---------------------------------------------
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------

#symm
our $symmAxis = lxq("select.symmetryState ?");
if 		($symmAxis eq "none")	{	$symmAxis = 3;	}
elsif	($symmAxis eq "x")		{	$symmAxis = 0;	}
elsif	($symmAxis eq "y")		{	$symmAxis = 1;	}
elsif	($symmAxis eq "z")		{	$symmAxis = 2;	}
if ($symmAxis != 3){
	lx("select.symmetryState none");
}

my @WPmem;
@WPmem[0] = lxq ("workPlane.edit cenX:?");
@WPmem[1] = lxq ("workPlane.edit cenY:?");
@WPmem[2] = lxq ("workPlane.edit cenZ:?");
@WPmem[3] = lxq ("workPlane.edit rotX:?");
@WPmem[4] = lxq ("workPlane.edit rotY:?");
@WPmem[5] = lxq ("workPlane.edit rotZ:?");

#gather viewport matrix
my $viewport = lxq("query view3dservice mouse.view ?");
my @axis = lxq("query view3dservice view.axis ? $viewport");
my @viewAngles = lxq("query view3dservice view.angles ?");
my @vpMatrix = queryViewportMatrix(@viewAngles);
my @axisRoundedVpMatrix;
for (my $i=0; $i<3; $i++){
	my $grtIndice = 0;
	my $grtValue = -1000;
	my $negOrNot = 1;
	my @array = (0,0,0);

	for (my $j=0; $j<3; $j++){
		if (abs(@{$vpMatrix[$i]}[$j]) > $grtValue){
			$grtIndice = $j;
			$grtValue = abs(@{$vpMatrix[$i]}[$j]);
			if (@{$vpMatrix[$i]}[$j] < 0){$negOrNot = -1;}else{$negOrNot = 1;}
		}
	}

	$array[$grtIndice] = $negOrNot;
	@{axisRoundedVpMatrix[$i]} = \@array;
}

#gather workplane, item ref, and item translation matrix data.
my @itemXfrmMatrix = getItemXfrmMatrix($mainlayerID);
my @wpMatrix = queryWorkPlaneMatrix_4x4(@WPmem);
my @itemRefMatrix = queryItemRefMatrix();
my @matrix = @itemXfrmMatrix;
@matrix = mtxMult(\@itemRefMatrix,\@matrix);
if ($polyNormal != 1){	@matrix = mtxMult(\@wpMatrix,\@matrix);	}


#-----------------------------------------------------------------------------------
#REMEMBER SELECTION SETTINGS  ((MODO6 FIX)) (modded : removed the selectauto setting)
#-----------------------------------------------------------------------------------
#sets the ACTR preset
my $seltype;
my $selAxis;
my $selCenter;
my $actr = 1;

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



#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#------------------------------------------MAIN ROUTINE---------------------------------------------
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------

#determine the axis
if ($worldAxis == 1){
	our $axis;
	my @xAxis = (1,0,0);
	my @yAxis = (0,1,0);
	my @zAxis = (0,0,1);
	my $dp0 = dotProduct(\@axis,\@xAxis);
	my $dp1 = dotProduct(\@axis,\@yAxis);
	my $dp2 = dotProduct(\@axis,\@zAxis);
	if 		((abs($dp0) >= abs($dp1)) && (abs($dp0) >= abs($dp2)))	{	$axis = 0;	lxout("[->] : Using world X axis");}
	elsif	((abs($dp1) >= abs($dp0)) && (abs($dp1) >= abs($dp2)))	{	$axis = 1;	lxout("[->] : Using world Y axis");}
	else															{	$axis = 2;	lxout("[->] : Using world Z axis");}
	lx("tool.set actr.auto on");
}elsif ($edgeAxis == 1){
	if (lxq("select.count edge ?") == 0){&die;}
	our @edges = lxq("query layerservice edges ? selected");

	if ($polyNormal == 1){
		my @polys = lxq("query layerservice edge.polyList ? $edges[-1]");
		my @edgeCenter = lxq("query layerservice edge.pos ? $edges[-1]");
		@edgeCenter = vec_mtxMult(\@matrix,\@edgeCenter);
		my $polysIndice = -1;
		my @edgeVerts;
		my @xVec;
		my @yVec;
		my @zVec;

		my $edge = $edges[-1];
		$edge =~ s/[()]//g;
		@verts = split(/,/, $edge);
		my @edgeVertPos1 = lxq("query layerservice vert.pos ? $verts[0]");
		@edgeVertPos1 = vec_mtxMult(\@matrix,\@edgeVertPos1);

		@xVec = unitVector(arrMath(@edgeCenter,@edgeVertPos1,subt));
		if (@polys == 1){
			@yVec = lxq("query layerservice poly.normal ? $polys[0]");
			@yVec = vec_mtxMult(\@matrix,\@yVec);
		}else{
			my @normal1 = lxq("query layerservice poly.normal ? $polys[0]");
			my @normal2 = lxq("query layerservice poly.normal ? $polys[1]");
			@yVec = unitVector(arrMath(arrMath(@normal1,@normal2,add),.5,.5,.5,mult));
			@yVec = vec_mtxMult(\@matrix,\@yVec);
		}

		@zVec = unitVector(crossProduct(\@yVec,\@xVec));
		my @rotMatrix = (
			[@xVec],
			[@yVec],
			[@zVec]
		);
		printMatrix(\@rotMatrix);

		my @rotations = Eul_FromMatrix(\@rotMatrix,"ZXYs","degrees");

		lx("workPlane.edit {$edgeCenter[0]} {$edgeCenter[1]} {$edgeCenter[2]} {$rotations[0]} {$rotations[1]} {$rotations[2]}");
	}
	lx("tool.set actr.auto on");
	our $axis = 1;
}else{
	our $axis = -1;
	lx("tool.set actr.screen on");
	lxout("[->] : Using SCREEN axis");
}

if ($edgeAxis == 1){
	my $edgeLength = lxq("query layerservice edge.length ? $edges[-1]");
	our @pos1 = ($edgeLength * -0.5 , 0 , 0);
	our @pos2 = ($edgeLength * 0.5 , 0 , 0);
	$selType = "polygon";
}else{
	if((lxq( "select.typeFrom {edge;polygon;item;vertex} ?" )) || ( lxq( "select.typeFrom {polygon;item;vertex;edge} ?" ))){
		if(lxq( "select.typeFrom {edge;polygon;item;vertex} ?" ))		{	$selType = "edge";	}else{	$selType = "polygon";	}
		if (lxq("query layerservice edge.n ? selected") > 0)												{	&getEdgePos;	}
		elsif ((($vertical == 1) || ($horizontal == 1)) && lxq("query layerservice vert.n ? selected") > 0)	{	&getVertPos;	}
		elsif (lxq("query layerservice vert.n ? selected") > 1)												{	&getVertPos;	}
		else																								{	&die;			}
	}
	elsif ( lxq( "select.typeFrom {vertex;edge;polygon;item} ?" ) ){
		$selType = "vertex";
		if ((($vertical == 1) || ($horizontal == 1)) && lxq("query layerservice vert.n ? selected") > 0)	{	&getVertPos;	}
		elsif (lxq("query layerservice vert.n ? selected") > 1)												{	&getVertPos;	}
		elsif (lxq("query layerservice edge.n ? selected") > 0)												{	&getEdgePos;	}
		else																								{	&die;			}
	}
	else{
		&die;
	}
}

if ($fullCut == 1){	&resizeCut;	}
lx("select.type polygon");
lx("tool.set poly.knife on");
lx("tool.reset");
if ( ($edgeAxis != 1) && ($worldAxis != 1) ){
	#doesn't exist anymore in 501 or 601!
	#lx("tool.setAttr axis.view axis $axis");
	#lx("tool.setAttr axis.view axisX {@axis[0]}");
	#lx("tool.setAttr axis.view axisY {@axis[1]}");
	#lx("tool.setAttr axis.view axisZ {@axis[2]}");
}else{
	lx("tool.setAttr axis.auto axis {$axis}");
}

lx("tool.setAttr poly.knife startX {@pos1[0]}");
lx("tool.setAttr poly.knife startY {@pos1[1]}");
lx("tool.setAttr poly.knife startZ {@pos1[2]}");
lx("tool.setAttr poly.knife endX {@pos2[0]}");
lx("tool.setAttr poly.knife endY {@pos2[1]}");
lx("tool.setAttr poly.knife endZ {@pos2[2]}");
lx("tool.doApply");
lx("tool.set poly.knife off");

if ($symmAxis != 3){
	lxout("[->] : Performing a symmetry slice");
	@axis[$symmAxis]*=-1;
	@pos1[$symmAxis]*=-1;
	@pos2[$symmAxis]*=-1;

	lx("tool.set poly.knife on");
	lx("tool.reset");
	if ($worldAxis != 1){
		#doesn't exist anymore in 501 or 601!
		#lx("tool.setAttr axis.view axis $axis");
		#lx("tool.setAttr axis.view axisX {@axis[0]}");
		#lx("tool.setAttr axis.view axisY {@axis[1]}");
		#lx("tool.setAttr axis.view axisZ {@axis[2]}");
	}else{
		lx("tool.setAttr axis.auto axis {$axis}");
	}
	lx("tool.setAttr poly.knife startX {@pos1[0]}");
	lx("tool.setAttr poly.knife startY {@pos1[1]}");
	lx("tool.setAttr poly.knife startZ {@pos1[2]}");
	lx("tool.setAttr poly.knife endX {@pos2[0]}");
	lx("tool.setAttr poly.knife endY {@pos2[1]}");
	lx("tool.setAttr poly.knife endZ {@pos2[2]}");
	lx("tool.doApply");
	lx("tool.set poly.knife off");
}




#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#------------[SCRIPT IS FINISHED] SAFETY REIMPLEMENTING-----------------
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------

#put the WORKPLANE and UNIT MODE back to what you were in before.
if ($polyNormal == 1){lx("workPlane.edit {@WPmem[0]} {@WPmem[1]} {@WPmem[2]} {@WPmem[3]} {@WPmem[4]} {@WPmem[5]}");}

#Set the action center settings back
if ($actr == 1) {	lx( "tool.set {$seltype} on" ); }
else { lx("tool.set center.$selCenter on"); lx("tool.set axis.$selAxis on"); }

#restore selection mode.
lx("select.type $selType");

#Set Symmetry back
if ($symmAxis != 3)
{
	#CONVERT MY OLDSCHOOL SYMM AXIS TO MODO's NEWSCHOOL NAME
	if 		($symmAxis == "3")	{	$symmAxis = "none";		}
	elsif	($symmAxis == "0")	{	$symmAxis = "x";		}
	elsif	($symmAxis == "1")	{	$symmAxis = "y";		}
	elsif	($symmAxis == "2")	{	$symmAxis = "z";		}
	lxout("turning symm back on ($symmAxis)"); lx("!!select.symmetryState {$symmAxis}");
}











#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#-------------------------------------------------------------------------------------------------SUBROUTINES-------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#RESIZE CUT SUB
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
sub resizeCut{
	lxout("[->] : Using 'fullCut' to perform a cut that will be as big as the current viewport.");
	my $scale = lxq("query view3dservice view.scale ? $viewport");
	my @dimensions = lxq("query view3dservice view.rect ? $viewport");
	my $diagDist = sqrt(@dimensions[2]*$scale*@dimensions[2]*$scale + @dimensions[3]*$scale*@dimensions[3]*$scale);
	my @posCenter = arrMath(arrMath(@pos1,@pos2,add),0.5,0.5,0.5,mult);
	my @disp1 = arrMath(@pos1,@posCenter,subt);
	my $dist = sqrt((@disp1[0]*@disp1[0])+(@disp1[1]*@disp1[1])+(@disp1[2]*@disp1[2]));
	my $mult = $diagDist/$dist;
	@pos1 = arrMath(@posCenter,arrMath(@disp1,$mult,$mult,$mult,mult),add);
	@pos2 = arrMath(@posCenter,arrMath(@disp1,-$mult,-$mult,-$mult,mult),add);
}


#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#DIE SUB
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
sub die{
	die("\n.\n[----------------------You didn't have at least (2 verts) or (1 edge) selected so I'm killing the script.--------------------------]\n[--PLEASE TURN OFF THIS WARNING WINDOW by clicking on the (In the future) button and choose (Hide Message)--] \n[-----------------------------------This window is not supposed to come up, but I can't control that.---------------------------]\n.\n");
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#GET VERT POSITIONS SUB
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
sub getVertPos{
	lxout("[->] : VERT MODE : Using the first and last selected verts to determine the cut angle");
	my @verts = lxq("query layerservice verts ? selected");
	our @pos1 = lxq("query layerservice vert.pos ? @verts[0]");
	our @pos2 = lxq("query layerservice vert.pos ? @verts[-1]");
	@pos1 = vec_mtxMult(\@matrix,\@pos1);
	@pos2 = vec_mtxMult(\@matrix,\@pos2);

	#override the first vert Pos if horizontal or vertical is on. (don't think this'll work with screen axis)
	if ($vertical == 1){
		@pos1 = @pos2;
		@pos1 = arrMath(@pos1,@{$axisRoundedVpMatrix[1]},add);
	}
	elsif ($horizontal == 1){
		@pos1 = @pos2;
		@pos1 = arrMath(@pos1,@{$axisRoundedVpMatrix[0]},add);
	}
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#GET EDGE POSITION SUB
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
sub getEdgePos{
	lxout("[->] : EDGE MODE : Using the last selected edge to determine the cut angle");
	my @edges = lxq("query layerservice selection ? edge");
	@edges[-1] =~ s/\(\d{0,},/\(/;
	@edges[-1] =~ tr/()//d;
	my @verts = split(/,/, @edges[-1]);
	our @pos1 = lxq("query layerservice vert.pos ? @verts[0]");
	our @pos2 = lxq("query layerservice vert.pos ? @verts[1]");
	@pos1 = vec_mtxMult(\@matrix,\@pos1);
	@pos2 = vec_mtxMult(\@matrix,\@pos2);
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
#PERFORM MATH FROM ONE ARRAY TO ANOTHER subroutine
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE : my @disp = arrMath(@pos2,@pos1,subt);
sub arrMath{
	my @array1 = (@_[0],@_[1],@_[2]);
	my @array2 = (@_[3],@_[4],@_[5]);
	my $math = @_[6];

	my @newArray;
	if ($math eq "add")		{	@newArray = (@array1[0]+@array2[0],@array1[1]+@array2[1],@array1[2]+@array2[2]);	}
	elsif ($math eq "subt")	{	@newArray = (@array1[0]-@array2[0],@array1[1]-@array2[1],@array1[2]-@array2[2]);	}
	elsif ($math eq "mult")	{	@newArray = (@array1[0]*@array2[0],@array1[1]*@array2[1],@array1[2]*@array2[2]);	}
	elsif ($math eq "div")	{	@newArray = (@array1[0]/@array2[0],@array1[1]/@array2[1],@array1[2]/@array2[2]);	}
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
#CONVERT MATRIX TO EULER (9char matrix)
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
#CROSSPRODUCT SUBROUTINE (ver 1.1)
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE : my @crossProduct = crossProduct(\@vector1,\@vector2);
sub crossProduct{
	return ( (${$_[0]}[1]*${$_[1]}[2])-(${$_[1]}[1]*${$_[0]}[2]) , (${$_[0]}[2]*${$_[1]}[0])-(${$_[1]}[2]*${$_[0]}[0]) , (${$_[0]}[0]*${$_[1]}[1])-(${$_[1]}[0]*${$_[0]}[1]) );
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