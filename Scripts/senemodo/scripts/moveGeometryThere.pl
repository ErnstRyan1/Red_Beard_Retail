#perl
#ver 0.93  #NOTE : needs symmetry code
#author : Seneca Menard

#This script will take the selected geometry and move it in front of the geometry where the mouse is pointing. (so you can put a garbage can on the ground or a painting on a wall or a lamp on a table or a ceiling light on the ceiling)

#SCRIPT ARGUMENTS :
# 1d : This will make it so the geometry only moves along the poly normal you held your mouse over. (good for aligning one thing to another, but only in 1d)

#(1-10-14 fix) : got the actr storage system up to date with 601



my %vertTable;
my $mainlayer = lxq("query layerservice layers ? main");
my $mainlayerID = lxq("query layerservice layer.id ? main");



#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#--------------------------------------SAFETY CHECKS------------------------------------------
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------

#script CVARS
foreach my $arg (@ARGV){
	if ($arg =~ /1d/i)			{	our $oneDimMove = 1;}
	elsif	($arg =~ /multi/i)	{	our $multi = 1;		}
}

#save tool preset
lx("!!tool.makePreset name:tool.previous");
lx("tool.viewType xyz");

#symm
our $symmAxis = lxq("select.symmetryState ?");
if 		($symmAxis eq "none")	{	$symmAxis = 3;	}
elsif	($symmAxis eq "x")		{	$symmAxis = 0;	}
elsif	($symmAxis eq "y")		{	$symmAxis = 1;	}
elsif	($symmAxis eq "z")		{	$symmAxis = 2;	}
if ($symmAxis != 3){
	lx("select.symmetryState none");
}

#Remember what the workplane was
my @WPmem;
@WPmem[0] = lxq ("workPlane.edit cenX:? ");
@WPmem[1] = lxq ("workPlane.edit cenY:? ");
@WPmem[2] = lxq ("workPlane.edit cenZ:? ");
@WPmem[3] = lxq ("workPlane.edit rotX:? ");
@WPmem[4] = lxq ("workPlane.edit rotY:? ");
@WPmem[5] = lxq ("workPlane.edit rotZ:? ");
lx("workPlane.reset ");


#-----------------------------------------------------------------------------------
#REMEMBER SELECTION SETTINGS and then set it to selectauto  ((MODO6 FIX))
#-----------------------------------------------------------------------------------
#sets the ACTR preset
our $seltype;
our $selAxis;
our $selCenter;
our $actr = 1;

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

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#SETUP SELECTION TABLE
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
if ((lxq( "select.typeFrom {vertex;edge;polygon;item} ?" )) && (lx("select.count vertex ?") > 0)){
	our $selType = "vertex";
}elsif ((lxq( "select.typeFrom {edge;polygon;item;vertex} ?" )) && (lx("select.count edge ?") > 0)){
	our $selType = "edge";
	lx("select.convert vertex");
}elsif ((lxq( "select.typeFrom {polygon;item;vertex;polygon} ?" )) && (lx("select.count polygon ?") > 0)){
	our $selType = "polygon";
	lx("select.convert vertex");
}else{
	die("\\\\n.\\\\n[---------------------------------------------You're not in vert, edge, or polygon mode.--------------------------------------------]\\\\n[--PLEASE TURN OFF THIS WARNING WINDOW by clicking on the (In the future) button and choose (Hide Message)--] \\\\n[-----------------------------------This window is not supposed to come up, but I can't control that.---------------------------]\\\\n.\\\\n");
}

my @selection = lxq("query layerservice selection ? vert");
foreach my $vert (@selection){
	my @vertInfo = split (/[^0-9]/, $vert);
	push(@{$vertTable{@vertInfo[1]}},@vertInfo[2]);
}


#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#grab mouse pos and poly normal under mouse
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
my @viewAxis;
my @polyNormal;
my $polyUnderMouse;
my @mousePos;
my $greatestDP = -99999999999999999999999999999999999999999999999999999999999999;
my $chosenLayer;
my $chosenVert;
&getViewAxisAndPolyNormal;

my $planeDist = dotProduct(\@polyNormal,\@mousePos);

#find first vert pos
my $layerName = lxq("query layerservice layer.name ? @keys[0]");
my @firstVertPos = lxq("query layerservice vert.pos ? @{$vertTable{@keys[0]}}[0]");


foreach my $layer (keys %vertTable){
	my $layerName = lxq("query layerservice layer.name ? $layer");

	foreach my $vert (@{$vertTable{$layer}}){
		my @vertPos = lxq("query layerservice vert.pos ? $vert");
		my @pos = lxq("query layerservice vert.pos ? $vert");
		my $dp =  -1 * (dotProduct(\@pos,\@polyNormal)-$planeDist);
		if ($dp > $greatestDP){
			$greatestDP = $dp;
			$chosenLayer = $layer;
			$chosenVert = $vert;
		}
	}
}

my $layerName = lxq("query layerservice layer.name ? $chosenLayer");
my @chosenVertPos = lxq("query layerservice vert.pos ? $chosenVert");

if ($oneDimMove == 1){
	our @movePos = arrMath(@polyNormal,$greatestDP,$greatestDP,$greatestDP,mult);
}else{
	our @movePos = arrMath(@mousePos,@chosenVertPos,subt);
}
lx("select.type $selType");
lx("tool.set xfrm.move on");
lx("tool.setAttr xfrm.move X {@movePos[0]}");
lx("tool.setAttr xfrm.move Y {@movePos[1]}");
lx("tool.setAttr xfrm.move Z {@movePos[2]}");
lx("tool.doApply");
lx("tool.set xfrm.move off");




#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#CLEANUP
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------

#put the tool back
lx("!!tool.set tool.previous on");

#put the WORKPLANE and UNIT MODE back to what you were in before.
if ($workplane == 1){
	lxout("workplane is on....");
	if (($symmAxis != 3) && (@wpBackup[$symmAxis] > 0))	{	lx("workPlane.edit {@wpBackup[0]} {@wpBackup[1]} {@wpBackup[2]} {@wpBackup[3]} {@wpBackup[4]} {@wpBackup[5]}");		lxout("[->] Restoring backup workplane");	}
	else												{	lx("workPlane.edit {$Xcenter} {$Ycenter} {$Zcenter} {$Xrotate} {$Yrotate} {$Zrotate}");								lxout("[->] Restoring regular workplane");	}
	lx("tool.set actr.origin on");
}else{
	lx("workPlane.edit {@WPmem[0]} {@WPmem[1]} {@WPmem[2]} {@WPmem[3]} {@WPmem[4]} {@WPmem[5]}");
	#Set the action center settings back
	if ($actr == 1) {	lx( "tool.set {$seltype} on" ); }
	else { lx("tool.set center.$selCenter on"); lx("tool.set axis.$selAxis on"); }
}

#Set Symmetry back
if ($symmAxis != 3)
{
	#CONVERT MY OLDSCHOOL SYMM AXIS TO MODO's NEWSCHOOL NAME
	if 		($symmAxis == "3")	{	$symmAxis = "none";	}
	elsif	($symmAxis == "0")	{	$symmAxis = "x";		}
	elsif	($symmAxis == "1")	{	$symmAxis = "y";		}
	elsif	($symmAxis == "2")	{	$symmAxis = "z";		}
	lxout("turning symm back on ($symmAxis)"); lx("!!select.symmetryState $symmAxis");
}


























#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#--------------------------------------------------------------------------------SUBROUTINES-----------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

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
#PERFORM MATH FROM ONE ARRAY TO ANOTHER subroutine
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
sub arrMath{
	my @array1 = (@_[0],@_[1],@_[2]);
	my @array2 = (@_[3],@_[4],@_[5]);
	my $math = @_[6];
	my @newArray;
	if ($math eq "add")		{	@newArray = (@array1[0]+@array2[0],@array1[1]+@array2[1],@array1[2]+@array2[2]);	}
	elsif ($math eq "subt")	{	@newArray = (@array1[0]-@array2[0],@array1[1]-@array2[1],@array1[2]-@array2[2]);	}
	elsif ($math eq "mult")	{	@newArray = (@array1[0]*@array2[0],@array1[1]*@array2[1],@array1[2]*@array2[2]);	}
	elsif ($math eq "div")		{	@newArray = (@array1[0]/@array2[0],@array1[1]/@array2[1],@array1[2]/@array2[2]);	}
	return @newArray;
}

#------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------
#GET VIEW AXIS AND POLYNORMAL subroutine
#------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------
sub getViewAxisAndPolyNormal{
	my $viewport =		lxq("query view3dservice mouse.view ?");
	my $shadingMode =	lxq("viewport.3dView background:?");

	#make sure the main layer is visible!
	my @verifyMainlayerVisibilityList = verifyMainlayerVisibility();

	#only select the item if the current viewport isn't set to wireframe mode.
	if ($shadingMode ne "wire"){
		our $fgLayerCount1 = lxq("query layerservice layer.n ? fg");
		lx("select.type item");
		lx("select.3DElementUnderMouse add");
		our $fgLayerCount2 = lxq("query layerservice layer.n ? fg");
	}

	$polyUnderMouse =	lxq("query view3dservice element.over ? POLY");
	@viewAxis =			lxq("query view3dservice view.axis ? $viewport");

	lx("workplane.fitGeometry");
	@mousePos[0] = lxq ("workPlane.edit cenX:? ");
	@mousePos[1] = lxq ("workPlane.edit cenY:? ");
	@mousePos[2] = lxq ("workPlane.edit cenZ:? ");
	lx("workplane.reset");

	if ($shadingMode ne "wire"){
		if ($fgLayerCount1 < $fgLayerCount2){	lx("select.3DElementUnderMouse remove");	}
		lx("select.type polygon");
	}

	my @poly = split(/,/, $polyUnderMouse);
	if  ($polyUnderMouse =~ /,/){
		my $layer = @poly[0]+1;
		my $layerName1 = lxq("query layerservice layer.name ? $layer");
		@polyNormal = lxq("query layerservice poly.normal ? @poly[1]");
		my $layerName2 = lxq("query layerservice layer.name ? $mainlayer");
	}
	else{die("Your mouse apparently wasn't any geometry in a 3d viewport, so I'm canceling the script");}

	#put back the mainlayer visibility.
	verifyMainlayerVisibility(\@verifyMainlayerVisibilityList);
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#MAINLAYER VISIBILITY ASSURANCE SUBROUTINE (toggles vis of mainlayer and/or parents if any are hidden)
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
# USAGE : (requires mainlayerID)
# my @verifyMainlayerVisibilityList = verifyMainlayerVisibility();	#to collect hidden parents and show them
# verifyMainlayerVisibility(\@verifyMainlayerVisibilityList);		#to hide the hidden parents (and mainlayer) again.
sub verifyMainlayerVisibility{
	my @hiddenParents;

	#hide the items again.
	if (@_ > 0){
		foreach my $id (@{@_[0]}){
			#lxout("[->] : hiding $id");
			lx("layer.setVisibility {$id} 0");
		}
	}

	#show the mainlayer and all the mainlayer parents that are hidden (and retain a list for later use)
	else{
		if( lxq( "select.typeFrom {vertex;edge;polygon;item} ?" ) ){	our $tempSelMode = "vertex";	}
		if( lxq( "select.typeFrom {edge;polygon;item;vertex} ?" ) ){	our $tempSelMode = "edge";		}
		if( lxq( "select.typeFrom {polygon;item;vertex;edge} ?" ) ){	our $tempSelMode = "polygon";	}
		if( lxq( "select.typeFrom {item;vertex;edge;polygon} ?" ) ){	our $tempSelMode = "item";		}
		lx("select.type item");
		if (lxq("layer.setVisibility $mainlayerID ?") == 0){
			lxout("[->] : showing $mainlayerID");
			lx("layer.setVisibility $mainlayerID 1");
			push(@hiddenParents,$mainlayerID);
		}
		lx("select.type $tempSelMode");

		my $parentFind = 1;
		my $currentID = $mainlayerID;
		while ($parentFind == 1){
			my $parent = lxq("query sceneservice item.parent ? {$currentID}");
			if ($parent ne ""){
				$currentID = $parent;

				if (lxq("layer.setVisibility {$parent} ?") == 0){
					#lxout("[->] : showing $parent");
					lx("layer.setVisibility {$parent} 1");
					push(@hiddenParents,$parent);
				}
			}else{
				$parentFind = 0;
			}
		}

		return(@hiddenParents);
	}
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

#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#PRINT ALL THE ELEMENTS IN A HASH TABLE FULL OF ARRAYS
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#usage : printHashTableArray(\%table,table);
sub printHashTableArray{
	lxout("          ------------------------------------Printing @_[1] list------------------------------------");
	my $hash = @_[0];
	foreach my $key (sort keys %{$hash}){
		lxout("          KEY = $key");
		for (my $i=0; $i<@{$$hash{$key}}; $i++){
			lxout("             $i = @{$$hash{$key}}[$i]");
		}
	}
}
