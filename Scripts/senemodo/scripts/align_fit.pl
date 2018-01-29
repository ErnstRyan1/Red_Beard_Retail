#perl
#AUTHOR: Seneca Menard
#version 3.11

#This script is for ALIGNING and/or STRETCHING whatever's currently selected to whatever OTHER elements are also selected.
#The way it figures out what you want to align TO is by checking what SELECTION MODE you're currently in.  So if you're in VERT mode, but also have some POLYGONS selected, it'll align your VERTS to your POLYGONS.  I just added in a new feature, so that if you've only got one set
#...of elements selected and it won't align to any other geometry because nothing else is selected, it will align itself to the world ORIGIN in that case.
#There's ALIGNING (OVER/CENTER/UNDER) and SCALING/STRETCHING.

#There's also POINT TO POINT ALIGNING, which is a different system.  The way that system works is that it ALIGNS one point to another, so if you want the very TOP of a sphere to be aligned with the very TOP of a cube in the Yaxis, all you would...
#...have to do is select the edges or polygons of the sphere and two verts.  The two verts would be a vert on top of the sphere and then a vert on top of the cube.  Then you would press the (p2p align Y) button.   Another thing to mention is that it has a safety...
#...check on what verts are selected so if you accidentally selected more than 2 verts, when you were only supposed to select 2 verts, it'll only pay attention to whatever other vert is the farthest away from the first vert in whatever axes it's supposed to pay attention to.

#Then there's POINT TO POINT SCALING, which is also a little different, in that it requires 4 points to be selected, and will measure the distance between the first 2 points and compare it to the distance of the second 2 points and will then scale the selected edges or polygons...
#...by exactly the amount it takes to get those first two points to be the exact same length as the second two points.   For example, say you have two cubes in your scene and one's smaller than the other...  All you have to do is select two points on the first cube...
#...and then basically the same 2 points on the second cube, hit the (p2p Scale) button and now the first cube will be exactly the same size as the second cube.   Another thing to mention is that I put in a safety check for determining what verts are selected.
#I'm only trying to pay attention to 4 verts, but sometimes it's hard to select only 4 verts.  For example, if you're in the TOP DOWN 2D VIEW and you have two cubes in the scene and only mean to select 2 verts on each cube, you'll actually select 4 verts on each cube
#...because the cubes are 3d and their bottom verts were right under the top verts as you know....  So I put in an option into the GUI that lets you tell me what window you were selecting those verts from so I can know which selected verts to ignore.  The "ANY WINDOW"
#...button is just there to ignore all of my safety checks, so if you know you only selected 4 verts (which is what happens 99% of the time), you don't have to pay attention to what window button to press.

#There's also POINT TO POINT STRETCHING, which is similar to POINT TO POINT SCALE, only it allows you to do non-proportional scale.

#Then there's PIVOT ALIGNMENT, which has FOUR parts to it:
#1) ALIGN TO PIVOT: Which aligns the selected ELEMENT to WHERE the pivot point is in the current layer
#2) ALIGN FROM PIVOT: Which aligns the selected elements FROM the pivot point to whatever other elements that are selected in the scene. (so selecting a POLYGON CUBE and then selecting POINTS and running the script will ALIGN THE SELECTED POINTS AND THE PIVOT POINT to the POLYGONS.
#3) SET PIVOT HERE: Which will align the pivot point to the selected elements.  There's also a reset pivot point button in there to easily set the pivot back to 0,0,0.
#4) ANCHOR TO PIVOT: This is so if you align an object TO the pivot point, but dont' want it to align from the center of the object.  What you do is select some VERTS or EDGES that you want to be centered on the pivot, and then selected the POLYGONS that you actually want moved.

#Then there's "SnapPos", which is to snap your geometry to the nearest grid point.  The way it works is it will snap your edge or poly selection from the last selected vert to the nearest grid point.  You can do a 1D, 2D, or 3D snap if you type in those arguments.

#If you wanted to build a new form and not use mine, here are the script arguments needed to tell it what to do:
#ALIGNMENT: "alX" "alY" "alZ" "over" "under"
#STRETCHING: "fitX" "fitY" "fitZ" "prop" (prop is to turn on proportional SCALING, instead of STRETCHING)
#POINT TO POINT: "p2p" "alX" "alY" "alZ"
#POINT TO POINT SCALE: "p2pScale" "x" "y" "z" (the x,y,z is just to tell it what "window" you're using so i can check for duplicate verts)
#POINT TO POINT STRETCH: "p2pStretch" "x" "y" "z" (the x,y,z is to tell it which dimensions to stretch it in)
#PIVOT ALIGNMENT: "pivFrom" "pivTo" "setPiv" "pivReset"
#ANCHOR TO PIVOT : "anchor2piv " "alX" "alY" "alZ" "over" "under"
#SNAP POS : "snapPos" "1D" "2D" "3D"
#oh yeah, and don't forget that modo's Z-axis is flipped, so you'll wanna flip OVER and UNDER when you're inputting the commands for the Z alignment

#(9-23-05 new feature) : if you're using "ALIGNING" and don't have a "destination" selected, it will just align to the world origin.
#(1-1-07 new feature) : I put in the ANCHOR TO PIVOT feature and I reorder the layer reference command to hide modo's workplane flip bug.
#(8-21-07 fix) : the script now works properly with M3 as well.
#(12-14-07 fix) : noticed a variable name typo with the ANCHOR2PIV routine.
#(4-1-07 fix) : get or set piv point subroutine update
#(7-24-08 fix) : fixed a bug with setting the pivot point an item that's "active", but not actually selected.
#(7-29-08 new feature) : "snapPos 1D" or "snapPos 2D" or "snapPos 3D" : what this is for is so you can select a vert and have it move the selected edges or polys over to the nearest grid point by the vert.  "3D" means it'll bind to the nearest true gridpoint.  "2D" means it'll bind to the nearest 2d gridpoint and ignore depth away from the camera.  "1D" means it'll only bind to the camera depth gridpoint and ignore the other 2 axes.   Note that I can't put this feature in the gui.  I can't because that will break my ability to query which viewport you're in.
#(7-31-08 fix) : I went and removed the square brackets so that the numbers will always be read as metric units and also because my prior safety check would leave the unit system set to metric system if the script was canceled because changing that preference doesn't get undone if a script is cancelled.
#(10-7-09 fix) : Changed the m3pivpos subroutine so it won't deselect any items if all that's being done is just querying the pivot position.
#(9-10-10 feature) : If using P2P, it will auto select the polys for you if you didn't have any selected.
#(10-26-10 fix) : it's possible to have a layer selected without it actually being selected and that would break a query, so that's now fixed.
#(3-29-11 fix) : fixed a layer reference bug
#(1-10-14 fix) : got the actr storage system up to date with 601
#(2-5-14 fix) : fixed a possibility of dividing by zero.
#(2-16-15 fix) : fixed a bug in the roundNumber sub
#(3-15-15 fix) : fixed the two quantization scripts to work with the METERS PER GAME UNIT option.

my $modoVer = lxq("query platformservice appversion ?");
my $mainlayer = lxq("query layerservice layers ? main");
my $mainlayerID = lxq("query layerservice layer.id ? $mainlayer");
#sourceDest cvars
my $sourceDest = 0;
my $dest_selType;
my $source_selType;
my $ignoreDestVerts = 0;
my @destVerts;
my @sourceVerts;
#bbox cvars
my @start_bbox;
my @dest_bbox;
my @start_center;
my @dest_center;
my $selectMode;
my $debug;
#arguments
my $alignX;
my $alignY;
my $alignX;
my $fitX;
my $fitY;
my $fitZ;
my $prop;
my $pivFrom;
my $pivTo;
my $setPiv;
my $reset;
my $X;
my $Y;
my $Z;
#align values
my $X;
my $Y;
my $Z;
#fit values
my @scaleCenter;
#prop fit value
my $greaterAxis;
#grid settings
my $gridDiv = lxq("pref.value units.gameScale ?");
my $gridMult = 1/$gridDiv;



#-----------------------------------------------------------------------------------
#SAFETY CHECKS
#-----------------------------------------------------------------------------------
#Turn off and protect Symmetry
my $symmAxis = lxq("select.symmetryState ?");
if ($symmAxis ne "none")	{	lx("select.symmetryState none");	}

#Remember what the workplane was and turn it off
my @WPmem;
@WPmem[0] = lxq ("workPlane.edit cenX:? ");
@WPmem[1] = lxq ("workPlane.edit cenY:? ");
@WPmem[2] = lxq ("workPlane.edit cenZ:? ");
@WPmem[3] = lxq ("workPlane.edit rotX:? ");
@WPmem[4] = lxq ("workPlane.edit rotY:? ");
@WPmem[5] = lxq ("workPlane.edit rotZ:? ");
lx("workPlane.reset ");

#NEW tool preset--------------------------------------------------------
if		(lxq( "tool.set xfrm.move ?") eq "on")			{	our $tool = "xfrm.move";			}
elsif	(lxq("tool.set xfrm.rotate ?") eq "on")			{	our $tool = "xfrm.rotate";			}
elsif 	(lxq("tool.set xfrm.stretch ?") eq "on")		{	our $tool = "xfrm.stretch";			}
elsif 	(lxq("tool.set xfrm.scale ?") eq "on")			{	our $tool = "xfrm.scale";			}
elsif	(lxq("tool.set Transform ?") eq "on")			{	our $tool = "Transform";			}
elsif	(lxq("tool.set TransformMove ?") eq "on")		{	our $tool = "TransformMove";		}
elsif	(lxq("tool.set TransformScale ?") eq "on")		{	our $tool = "TransformScale";		}
elsif	(lxq("tool.set TransformUScale ?") eq "on")		{	our $tool = "TransformUScale";		}
elsif	(lxq("tool.set TransformRotate ?") eq "on")		{	our $tool = "TransformRotate";		}
else													{	our $tool = "none";					}
#------------------------------------------------------------------------------



#-----------------------------------------------------------------------------------
#REMEMBER SELECTION SETTINGS and then set it to selectauto  ((MODO6 FIX))
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
lx("tool.set actr.selectauto on");


#-----------------------------------------------------------------------------------
#CHECK SCRIPT ARGUMENTS
#-----------------------------------------------------------------------------------
foreach $arg(@ARGV)
{
	if    ($arg eq "alX")				{	$alignX = 1;			}
	elsif ($arg eq "alY")				{	$alignY = 1;			}
	elsif ($arg eq "alZ")				{	$alignZ = 1;			}
	elsif ($arg eq "fitX")				{	$fitX = 1;				}
	elsif ($arg eq "fitY")				{	$fitY = 1;				}
	elsif ($arg eq "fitZ")				{	$fitZ=1;				}
	elsif ($arg eq "X")					{	$X=1;					}
	elsif ($arg eq "Y")					{	$Y=1;					}
	elsif ($arg eq "Z")					{	$Z=1;					}
	elsif ($arg eq "p2p")				{	$p2p = 1;				}
	elsif ($arg eq "p2pScale")			{	$p2pScale = 1;			}
	elsif ($arg eq "p2pStretch")		{	$p2pStretch = 1;		}
	elsif ($arg eq "over")				{	$over = 1;				}
	elsif ($arg eq "under")				{	$under = 1;				}
	elsif ($arg eq "prop")				{	$prop = 1;				}
	elsif ($arg eq "anchor2piv")		{	$anchor2piv=1;			}
	elsif ($arg eq "pivFrom")			{	$pivFrom = 1;			}
	elsif ($arg eq "pivTo")				{	$pivTo = 1;				}
	elsif ($arg eq "setPiv")			{	$setPiv= 1;				}
	elsif ($arg eq "pivReset")			{	$pivReset = 1;			}
	elsif ($arg eq "snapPos")			{	our $snapPos = 1;		}
	elsif ($arg eq "quantizeBBox")		{	our $quantizeBBoX = 1;	}
	elsif ($arg eq "setOriginHere")		{	our $setOriginHere = 1;	}
	elsif ($arg =~ /1d/i)				{	our $snapPosDim = 1;	}
	elsif ($arg =~ /2d/i)				{	our $snapPosDim = 2;	}
}


#set the main layer to be "reference" to get the true vert positions.
my $layerReference = lxq("layer.setReference ?");
lx("!!layer.setReference $mainlayerID");





#------------------------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------------------------
#NOW RUN THE CHOSEN SUBROUTINES
#------------------------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------------------------
#ALIGN-----------------------------------------------------------------
if ((($p2p != 1) && ($anchor2piv != 1) && ($pivFrom != 1) && ($setPiv != 1) && ($pivTo != 1)) && (($alignX == 1) || ($alignY == 1) || ($alignZ == 1)))
{
	lxout("[->] align");
	&sourceVerts;
	&destVerts;
	&BBoxChecks;
	&align;
}

#FIT---------------------------------------------------------------------------------------------------------------------------
if (($p2p != 1) && (($fitX == 1) || ($fitY == 1) || ($fitZ == 1)))
{
	lxout("[->] fit");
	if ($sourceDest == 0) {&sourceVerts; &destVerts; &BBoxChecks;}
	&fit;
}

#P2P---------------------------------------------------------------------------------------------------------------------------
if ($p2p == 1)
{
	lxout("[->] p2p");
	&p2p;
}

#P2PSCALE----------------------------------------------------------------------------------------------------------------------
if ($p2pScale==1)
{
	lxout("[->] p2p scale");
	&p2pScale;
}

#P2PSTRETCH--------------------------------------------------------------------------------------------------------------------
if ($p2pStretch == 1)
{
	lxout("[->] p2p stretch");
	&p2pStretch;
}

#anchor2pivOT (move sel from anchor2pivot)-------------------------------------------------------------------------------------
if ($anchor2piv==1)
{
	lxout("[->] Moving from point to pivot");
	&anchor2piv;
}

#MOVE SEL TO PIVOT-------------------------------------------------------------------------------------------------------------
if ($pivTo==1)
{
	lxout("[->] Pivot to");
	&sourceVerts;
	&pivTo;
}

#MOVE SEL WITH PIVOT---------------------------------------------------------------------------------------------------------
if ($pivFrom==1)
{
	lxout("[->] Move sel with pivot");

	#remember the source_type just for the dest subroutine
	if (lxq( "select.typeFrom {vertex;edge;polygon;item} ?" ))		{ $source_selType = vertex; }
	elsif (lxq( "select.typeFrom {edge;polygon;item;vertex} ?" ))	{ $source_selType = edge;	}
	elsif (lxq( "select.typeFrom {polygon;item;vertex;edge} ?" ))	{ $source_selType = polygon;}
	&destVerts;
	&pivFrom;
}

#ALIGN PIVOT TO SELECTION-----------------------------------------------------------------------------------------------------
if ($setPiv==1)
{
	lxout("[->] Setting the pivot point");
	&sourceVerts;
	&setPiv;
}

#RESET THE PIVOT POINT--------------------------------------------------------------------------------------------------------
if ($pivReset==1)
{
	lxout("[->] Resetting the pivot point");
	&pivReset;
}

#SNAP GEOMETRY TO NEAREST GRID POINT-------------------------------------------------------------------------------------------
if ($snapPos == 1)
{
	lxout("[->] Snapping the geometry to the grid, using the last selected vert as the snap origin.");
	if(lxq( "select.typeFrom {item;vertex;edge;polygon} ?" ))	{&itemPos;}
	else														{&snapPos;}

}

#QUANTIZE THE ITEM POSITIONS---------------------------------------------------------------------------------------------------
if ($itemPos == 1){
	lxout("[->] Quantizing the currently selected meshItems and meshInstances to the grid.");
	&itemPos;
}

#QUANTIZE GEOMETRY BBOXES------------------------------------------------------------------------------------------------------
if ($quantizeBBoX == 1){
	lxout("[->] Quantizing the selected geometry's bbox to the grid");
	&quantizeBBoX;
}

#SET ORIGIN HERE---------------------------------------------------------------------------------------------------------------
if ($setOriginHere == 1){
	lxout("[->] Setting the origin of the object to where the selected vert is");
	setOriginHere();
}

#------------------------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------------------------
#SET ORIGIN TO SELECTED VERT POSITION (and move object right back into place)
#------------------------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------------------------
sub setOriginHere{
	my $mainlayer = lxq("query layerservice layers ? main");
	my $mainlayerID = lxq("query layerservice layer.id ? $mainlayer");
	my @verts = lxq("query layerservice verts ? selected");
	my $vertCount = @verts;
	my @pos = (0,0,0);
	my @currentItemPos = (0,0,0);
	foreach my $vert (@verts){
		my @vertPos = lxq("query layerservice vert.pos ? $vert");
		@pos = arrMath(@pos,@vertPos,add);
	}
	@pos = arrMath(@pos,$vertCount,$vertCount,$vertCount,div);
	my @polyMoveAmt = arrMath(@pos,-1,-1,-1,mult);
	
	lx("!!select.drop polygon");
	lx("!!unhide");

	lx("tool.viewType xyz");
	lx("tool.set actr.auto on");
	lx("tool.set xfrm.move on");
	lx("tool.reset");
	lx("tool.setAttr axis.auto axis {2}");
	lx("tool.setAttr xfrm.move X {$polyMoveAmt[0]}");
	lx("tool.setAttr xfrm.move Y {$polyMoveAmt[1]}");
	lx("tool.setAttr xfrm.move Z {$polyMoveAmt[2]}");
	lx("tool.doApply");
	lx("tool.set xfrm.move off");
	
	my $posXfrmID = lxq("query sceneservice item.xfrmPos ? {$mainlayerID}");
	if ($posXfrmID eq ""){lx("transform.add type:{pos} item:{$mainlayerID}");}
	else{
		$currentItemPos[0] = lxq("item.channel pos.X ? set {$mainlayerID}");
		$currentItemPos[1] = lxq("item.channel pos.Y ? set {$mainlayerID}");
		$currentItemPos[2] = lxq("item.channel pos.Z ? set {$mainlayerID}");
	}
	
	@pos = arrMath(@pos,@currentItemPos,add);

	lx("item.channel pos.X {$pos[0]} set {$mainlayerID}");
	lx("item.channel pos.Y {$pos[1]} set {$mainlayerID}");
	lx("item.channel pos.Z {$pos[2]} set {$mainlayerID}");
	
	lx("select.type vertex");
}


#------------------------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------------------------
#FIGURE OUT what the SOURCE is (verts? edges? polys?) and send the vertlist back.
#------------------------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------------------------
sub sourceVerts
{
	lxout("[->] Using the SOURCE SELECTION checking routine");
	$sourceDest = 1;

	#--------------------------
	#SOURCE VERTS-----
	#--------------------------
	if(lxq( "select.typeFrom {vertex;edge;polygon;item} ?" ) && lxq( "select.count vertex ?" ))
	{
		lxout("[->]SOURCE TYPE = VERTEX");
		$source_selType = vertex;
		@sourceVerts = lxq("query layerservice verts ? selected");
	}

	#--------------------------
	#SOURCE EDGES-----
	#--------------------------
	elsif(lxq( "select.typeFrom {edge;polygon;item;vertex} ?" ) && lxq( "select.count edge ?" ))
	{
		lxout("[->]SOURCE TYPE = EDGE");
		$source_selType = edge;
		my $tempVerts=",";

		#CREATE AND EDIT the edge list.  [remove ( )] (FIXED FOR M2.  I'm not using the multilayer query anymore)
		my @tempEdges = lxq("query layerservice edges ? selected");
		s/\(// for @tempEdges;
		s/\)// for @tempEdges;

		#sort the edge list into a new vertlist (remove duplicates)
		foreach my $edge(@tempEdges)
		{
			my @edge = split(/,/, $edge);
			if ($tempVerts =~ /,@edge[0],/)	{		}else{$tempVerts = $tempVerts . @edge[0] . ",";}
			if ($tempVerts =~ /,@edge[1],/)	{		}else{$tempVerts = $tempVerts . @edge[1] . ",";}
		}

		#turn that new vertlist string into an array (and delete the first blank character)
		@sourceVerts = split(/,/, $tempVerts);
		shift(@sourceVerts);
	}

	#--------------------------
	#SOURCE POLYS-----
	#--------------------------
	elsif(lxq( "select.typeFrom {polygon;item;vertex;edge} ?" ) && lxq( "select.count polygon ?" ))
	{
		lxout("[->] SOURCE TYPE = POLYGON");
		$source_selType = polygon;
		my $tempVerts=",";

		#create the temp polyList
		my @tempPolys = lxq("query layerservice polys ? selected");

		#create the vertlist from the polylist
		foreach my $poly(@tempPolys)
		{
			my @polyVerts = lxq("query layerservice poly.vertList ? $poly");
			foreach my $vert(@polyVerts)
			{
				if ($tempVerts =~ /,$vert,/)	{		}else{$tempVerts = $tempVerts . $vert . ",";}
			}
		}

		#turn that new vertlist string into an array (and delete the first blank character)
		@sourceVerts = split(/,/, $tempVerts);
		shift(@sourceVerts);
	}

	#--------------------------
	#CAN'T FIND SOURCE
	#--------------------------
	else
	{
		die("\n.\n[-----------------------------------------You don't have any of these ELEMENTS selected-----------------------------------------]\n[--PLEASE TURN OFF THIS WARNING WINDOW by clicking on the (In the future) button and choose (Hide Message)--] \n[-----------------------------------This window is not supposed to come up, but I can't control that.---------------------------]\n.\n");
	}
}








#------------------------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------------------------
#FIGURE OUT what the DESTINATION is (verts? edges? polys?) and send the vertlist back.
#------------------------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------------------------
sub destVerts
{
	lxout("[->] Using the DEST SELECTION checking routine");
	#-------------------------------
	#DEST VERTS-----
	#-------------------------------
	if (($source_selType ne "vertex") && (lxq("select.count vertex ?")))
	{
		lxout("[->] DEST TYPE = VERTEX");
		$dest_selType = vertex;
		@destVerts = lxq("query layerservice verts ? selected");
	}

	#-------------------------------
	#DEST EDGES-----
	#-------------------------------
	elsif (($source_selType ne "edge") && (lxq("select.count edge ?")))
	{
		lxout("[->]DEST TYPE = EDGE");
		$dest_selType = edge;
		my $tempVerts=",";

		#CREATE AND EDIT the edge list.  [remove ( )] (FIXED FOR M2.  I'm not using the multilayer query anymore)
		my @tempEdges = lxq("query layerservice edges ? selected");
		s/\(// for @tempEdges;
		s/\)// for @tempEdges;

		#sort the edge list into a new vertlist (remove duplicates)
		foreach my $edge(@tempEdges)
		{
			my @edge = split(/,/, $edge);
			if ($tempVerts =~ /,@edge[0],/)	{		}else{$tempVerts = $tempVerts . @edge[0] . ",";}
			if ($tempVerts =~ /,@edge[1],/)	{		}else{$tempVerts = $tempVerts . @edge[1] . ",";}
		}

		#turn that new vertlist string into an array (and delete the first blank character)
		@destVerts = split(/,/, $tempVerts);
		shift(@destVerts);
	}

	#-------------------------------
	#DEST POLYS-----
	#-------------------------------
	elsif (($source_selType ne "polygon") && (lxq("select.count polygon ?")))
	{
		lxout("[->]DEST TYPE = POLYGON");
		$dest_selType = polygon;
		my $tempVerts=",";

		#create the temp polyList
		my @tempPolys = lxq("query layerservice polys ? selected");

		#create the vertlist from the polylist
		foreach my $poly(@tempPolys)
		{
			my @polyVerts = lxq("query layerservice poly.vertList ? $poly");
			foreach my $vert(@polyVerts)
			{
				if ($tempVerts =~ /,$vert,/)	{		}else{$tempVerts = $tempVerts . $vert . ",";}
			}
		}

		#turn that new vertlist string into an array (and delete the first blank character)
		@destVerts = split(/,/, $tempVerts);
		shift(@destVerts);
	}

	#-------------------------------
	#CANT FIND DEST-----
	#-------------------------------
	else
	{
		$ignoreDestVerts=1;
	}
}









#------------------------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------------------------
#GET BBOX of the start object and dest selection
#------------------------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------------------------
sub BBoxChecks
{
	lxout("[->] Using BBOX subroutine");
	#-----------------------------------------------------------------------------
	#start object bbox
	#-----------------------------------------------------------------------------
	@start_bbox = boundingbox(@sourceVerts);
	#lxout("The start object(@sourceVerts) bounding box is this:@start_bbox");

	#PICK THE CORRECT START CENTER -----------------------------------------------------------------
	#((START TOP))- - - - - - -
	if ($over == 1)
	{
		@start_center = (@start_bbox[0],@start_bbox[1],@start_bbox[2]);
		#lxout("USING OVER : The start object's top is this:@start_center");
	}
	#((START CENTER))- - - - - -
	elsif (($over != 1) && ($under != 1))
	{
		@start_center = (((@start_bbox[0]+@start_bbox[3]) / 2) , ((@start_bbox[1]+@start_bbox[4]) / 2) , ((@start_bbox[2]+@start_bbox[5]) / 2));
		#lxout("USING CENTER : The start object's center is this:@start_center");
	}
	#--((START BOTTOM))- - - - - -
	elsif ($under == 1)
	{
		@start_center = (@start_bbox[3],@start_bbox[4],@start_bbox[5]);
		#lxout("USING UNDER : The start object's center is this:@start_center");
	}
	#------------------------------------------------------------------------------------------------------------------------------


	#-----------------------------------------------------------------------------
	#dest selection bbox
	#-----------------------------------------------------------------------------
	if ($ignoreDestVerts != 1)
	{
		@dest_bbox = boundingbox(@destVerts);
		#lxout("The dest selection (@destVerts) bounding box is this:@dest_bbox");

		#PICK THE CORRECT DEST CENTER -----------------------------------------------------------------
		@dest_center = (((@dest_bbox[0]+@dest_bbox[3]) / 2) , ((@dest_bbox[1]+@dest_bbox[4]) / 2) , ((@dest_bbox[2]+@dest_bbox[5]) / 2));
		#((DEST TOP))- - - - - - -
		if ($over == 1)
		{
			@dest_center = (@dest_bbox[3],@dest_bbox[4],@dest_bbox[5]);
			#lxout("USING OVER : The dest object's top is this:@dest_center");
		}
		#((DEST CENTER))- - - - - -
		elsif (($over != 1) && ($under != 1))
		{
			@dest_center = (((@dest_bbox[0]+@dest_bbox[3]) / 2) , ((@dest_bbox[1]+@dest_bbox[4]) / 2) , ((@dest_bbox[2]+@dest_bbox[5]) / 2));
			#lxout("USING CENTER : The dest object's center is this:@dest_center");
		}
		#--((DEST BOTTOM))- - - - - -
		elsif ($under == 1)
		{
			@dest_center = (@dest_bbox[0],@dest_bbox[1],@dest_bbox[2]);
			#lxout("USING UNDER : The dest object's center is this:@dest_center");
		}
	}
	else
	{
		@dest_bbox = (0,0,0,1,1,1);
		@dest_center = (0,0,0,0,0,0);
	}
	#------------------------------------------------------------------------------------------------------------------------------
}










#------------------------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------------------------
#RESETTING THE PIVOT POINT
#------------------------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------------------------
sub pivReset
{
	lxout("[->] RESETTING the pivot point");

	#MOVE THE PIVOT
	if ($modoVer < 300){
		lx("tool.set pivot.move on");
		lx("tool.setAttr pivot.move posX 0");
		lx("tool.setAttr pivot.move posY 0");
		lx("tool.setAttr pivot.move posZ 0");
		lx("tool.doApply");
		lx("tool.set pivot.move off");
	}else{
		m3PivPos(set,lxq("query layerservice layer.id ? $mainlayer"),0,0,0);
	}
}








#------------------------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------------------------
#ALIGN PIVOT TO SELECTION
#------------------------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------------------------
sub setPiv
{
	lxout("[->] Using the SET PIVOT subroutine");
	#check whether to RESET the pivot or MOVE the pivot to the current selection

	#-----------------------------------------------------------------------------
	#get source object bbox (MODDED)
	#-----------------------------------------------------------------------------
	@source_bbox = boundingbox(@sourceVerts);
	#pick the correct source center
	#TOP
	if ($under == 1)					{	@source_center = (@source_bbox[0],@source_bbox[1],@source_bbox[2]);	}
	#CENTER
	elsif (($over != 1)&&($under != 1))	{	@source_center = (((@source_bbox[0]+@source_bbox[3]) / 2) , ((@source_bbox[1]+@source_bbox[4]) / 2) , ((@source_bbox[2]+@source_bbox[5]) / 2));	}
	#BOTTOM
	elsif ($over == 1)					{	@source_center = (@source_bbox[3],@source_bbox[4],@source_bbox[5]);	}

	#check args and only move in the requested AXES
	if ($modoVer < 300){
		our @pivotPos = lxq("query layerservice layer.pivot ? $mainlayer");
	}else{
		our @pivotPos = m3PivPos(get,lxq("query layerservice layer.id ? $mainlayer"));
	}

	if ($alignX != 1)	{@source_center[0]=@pivotPos[0];}
	if ($alignY != 1)	{@source_center[1]=@pivotPos[1];}
	if ($alignZ != 1)	{@source_center[2]=@pivotPos[2];}

	#MOVE THE PIVOT
	if ($modoVer < 300){
		lx("tool.set pivot.move on");
		lx("tool.setAttr pivot.move posX {@source_center[0]}");
		lx("tool.setAttr pivot.move posY {@source_center[1]}");
		lx("tool.setAttr pivot.move posZ {@source_center[2]}");
		lx("tool.doApply");
		lx("tool.set pivot.move off");
	}else{
		m3PivPos(set,lxq("query layerservice layer.id ? $mainlayer"),@source_center[0],@source_center[1],@source_center[2]);
	}
}








#------------------------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------------------------
#ALIGN source object to PIVOT
#------------------------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------------------------
sub pivTo
{
	lxout("[->] Using the PIVOT TO subroutine");

	#-----------------------------------------------------------------------------
	#get start object bbox
	#-----------------------------------------------------------------------------
	@start_bbox = boundingbox(@sourceVerts);
	#pick the correct start center
	#TOP
	if ($over == 1)						{	@start_center = (@start_bbox[0],@start_bbox[1],@start_bbox[2]);	}
	#CENTER
	elsif (($over != 1)&&($under != 1))	{	@start_center = (((@start_bbox[0]+@start_bbox[3]) / 2) , ((@start_bbox[1]+@start_bbox[4]) / 2) , ((@start_bbox[2]+@start_bbox[5]) / 2));	}
	#BOTTOM
	elsif ($under == 1)					{	@start_center = (@start_bbox[3],@start_bbox[4],@start_bbox[5]);	}

	#get PIVOT position
	if ($modoVer < 300){
		our @pivotPos = lxq("query layerservice layer.pivot ? $mainlayer");
	}else{
		our @pivotPos = m3PivPos(get,lxq("query layerservice layer.id ? $mainlayer"));
	}

	#find disp between object's start center and the pivot point
	my @disp = ((@pivotPos[0]-@start_center[0]),(@pivotPos[1]-@start_center[1]),(@pivotPos[2]-@start_center[2]));

	#check args and only move in the requested AXES
	if ($alignX != 1)	{@disp[0]=0;}
	if ($alignY != 1)	{@disp[1]=0;}
	if ($alignZ != 1)	{@disp[2]=0;}

	#MOVE
	lx("tool.set xfrm.move on");
	lx("tool.reset");
	lx("tool.setAttr xfrm.move X {@disp[0]}");
	lx("tool.setAttr xfrm.move Y {@disp[1]}");
	lx("tool.setAttr xfrm.move Z {@disp[2]}");
	lx("tool.doApply");
	lx("tool.set xfrm.move off");
}








#------------------------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------------------------
#ALIGN source object FROM pivot to destination
#------------------------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------------------------
sub pivFrom
{
	lxout("[->] Using the PIVOT FROM subroutine");

	#-----------------------------------------------------------------------------
	#get dest object bbox (MODDED)
	#-----------------------------------------------------------------------------
	@dest_bbox = boundingbox(@destVerts);
	#pick the correct start center
	#TOP
	if ($under == 1)					{	@dest_center = (@dest_bbox[0],@dest_bbox[1],@dest_bbox[2]);	}
	#CENTER
	elsif (($over != 1)&&($under != 1))	{	@dest_center = (((@dest_bbox[0]+@dest_bbox[3]) / 2) , ((@dest_bbox[1]+@dest_bbox[4]) / 2) , ((@dest_bbox[2]+@dest_bbox[5]) / 2));	}
	#BOTTOM
	elsif ($over == 1)					{	@dest_center = (@dest_bbox[3],@dest_bbox[4],@dest_bbox[5]);	}

	#get PIVOT position
	if ($modoVer < 300){
		our @pivotPos = lxq("query layerservice layer.pivot ? $mainlayer");
	}else{
		our @pivotPos = m3PivPos(get,lxq("query layerservice layer.id ? $mainlayer"));
	}

	#find disp between object's pivot point and the dest center
	my @disp = ((@dest_center[0]-@pivotPos[0]),(@dest_center[1]-@pivotPos[1]),(@dest_center[2]-@pivotPos[2]));

	#check args and only move in the requested AXES
	if ($alignX != 1)	{@disp[0]=0;}
	if ($alignY != 1)	{@disp[1]=0;}
	if ($alignZ != 1)	{@disp[2]=0;}

	#MOVE
	lx("tool.set xfrm.move on");
	lx("tool.reset");
	lx("tool.setAttr xfrm.move X {@disp[0]}");
	lx("tool.setAttr xfrm.move Y {@disp[1]}");
	lx("tool.setAttr xfrm.move Z {@disp[2]}");
	lx("tool.doApply");
	lx("tool.set xfrm.move off");

	#MOVE THE PIVOT WITH IT
	if ($modoVer < 300){
		my @amount = ( (@pivotPos[0]+@disp[0]) , (@pivotPos[1]+@disp[1]) , (@pivotPos[2]+@disp[2]) );
		lx("tool.set pivot.move on");
		lx("tool.reset");
		lx("tool.setAttr pivot.move posX {@amount[0]}");
		lx("tool.setAttr pivot.move posY {@amount[1]}");
		lx("tool.setAttr pivot.move posZ {@amount[2]}");
		lx("tool.doApply");
		lx("tool.set pivot.move off");
	}else{
		m3PivPos(set,lxq("query layerservice layer.id ? $mainlayer"),(@pivotPos[0]+@disp[0]),(@pivotPos[1]+@disp[1]),(@pivotPos[2]+@disp[2]));
	}
}



#------------------------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------------------------
#ALIGN selection from 1st selected point to pivot
#------------------------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------------------------
sub anchor2piv
{
	lxout("[->] Using anchor to pivot subroutine");
	my $moveType;

	#figure out the anchor
	if (lxq( "select.typeFrom {vertex;edge;polygon;item} ?" ))		{ $source_selType = vertex;	}
	elsif (lxq( "select.typeFrom {edge;polygon;item;vertex} ?" ))	{ $source_selType = edge;	}
	elsif (lxq( "select.typeFrom {polygon;item;vertex;edge} ?" ))	{ $source_selType = polygon;	}
	else{	die("\n.\n[---------------------------------------------You're not in vert, edge, or polygon mode.--------------------------------------------]\n[--PLEASE TURN OFF THIS WARNING WINDOW by clicking on the (In the future) button and choose (Hide Message)--] \n[-----------------------------------This window is not supposed to come up, but I can't control that.---------------------------]\n.\n");}


	#get the verts of the anchor.
	&sourceVerts;

	#get the anchor bbox
	@start_bbox = boundingbox(@sourceVerts);
	#TOP
	if ($over == 1)							{	@start_center = (@start_bbox[0],@start_bbox[1],@start_bbox[2]);	}
	#CENTER
	elsif (($over != 1) && ($under != 1))	{	@start_center = (((@start_bbox[0]+@start_bbox[3]) / 2) , ((@start_bbox[1]+@start_bbox[4]) / 2) , ((@start_bbox[2]+@start_bbox[5]) / 2));	}
	#BOTTOM
	elsif ($under == 1)						{	@start_center = (@start_bbox[3],@start_bbox[4],@start_bbox[5]);	}

	#figure out what's supposed to be moved
	my $vertCount =	lxq("query layerservice vert.n ? selected");
	my $edgeCount =	lxq("query layerservice edge.n ? selected");
	my $polyCount =	lxq("query layerservice poly.n ? selected");

	if ($source_selType eq "vertex"){
		if ($polyCount > 0)			{	$moveType = polygon;	}
		elsif ($edgeCount > 0)		{	$moveType = edge;		}
		else						{	$moveType = vertex;		}
	}
	elsif ($source_selType eq "edge"){
		if ($polyCount > 0)			{	$moveType = polygon;	}
		elsif ($vertCount > 0)		{	$moveType = vertex;		}
		else						{	$moveType = edge;		}
	}
	elsif ($source_selType eq "polygon"){
		if ($edgeCount > 0)			{	$moveType = edge;		}
		elsif ($vertCount > 0)		{	$moveType = vertex;		}
		else						{	$moveType = polygon;	}
	}

	#get PIVOT position
	if ($modoVer < 300){
		our @pivotPos = lxq("query layerservice layer.pivot ? $mainlayer");
	}else{
		our @pivotPos = m3PivPos(get,lxq("query layerservice layer.id ? $mainlayer"));
	}

	#find disp between anchor's start center and the pivot point
	my @disp = ((@pivotPos[0]-@start_center[0]),(@pivotPos[1]-@start_center[1]),(@pivotPos[2]-@start_center[2]));

	#check args and only move in the requested AXES
	if ($alignX != 1)	{@disp[0]=0;}
	if ($alignY != 1)	{@disp[1]=0;}
	if ($alignZ != 1)	{@disp[2]=0;}

	#put the user in the moveType selection mode.
	lx("select.type $moveType");

	#MOVE
	lx("tool.set xfrm.move on");
	lx("tool.reset");
	lx("tool.setAttr xfrm.move X {@disp[0]}");
	lx("tool.setAttr xfrm.move Y {@disp[1]}");
	lx("tool.setAttr xfrm.move Z {@disp[2]}");
	lx("tool.doApply");
	lx("tool.set xfrm.move off");

	#restore selection
	lx("select.type $source_selType");
}




#------------------------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------------------------
#ALIGN start object to destination
#------------------------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------------------------
sub align
{
	lxout("[->] Using the ALIGN subroutine");

	#determing the displacement
	my @disp = ((@dest_center[0]-@start_center[0]),(@dest_center[1]-@start_center[1]),(@dest_center[2]-@start_center[2]));
	#lxout("--------ALIGNING IS ON:  This is the displacement=@disp-----------");

	#checking which align axes are on:
	if ($alignX == 1) {$X = @disp[0];} else {$X = 0; }
	if ($alignY == 1) {$Y = @disp[1];} else {$Y = 0; }
	if ($alignZ == 1) {$Z = @disp[2];} else {$Z = 0; }

	#go to the SOURCE select type
	#lx("select.type $source_selType"); #temp

	#alignment MOVE
	lx("tool.set xfrm.move on");
	lx("tool.reset");
	lx("tool.setAttr xfrm.move X {$X}");
	lx("tool.setAttr xfrm.move Y {$Y}");
	lx("tool.setAttr xfrm.move Z {$Z}");
	lx("tool.doApply");
	lx("tool.set xfrm.move off");
}









#------------------------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------------------------
#POINT TO POINT ALIGN start object to destination
#------------------------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------------------------
sub p2p
{
	lxout("[->] Using the P2P subroutine");

	#determing the displacement
	my @p2pVertSel = pointDispSort();
	my @p2pVertPos0  = lxq("query layerservice vert.pos ? @p2pVertSel[0]");
	my @p2pVertPos1  = lxq("query layerservice vert.pos ? @p2pVertSel[-1]");
	my @p2pDisp = ((@p2pVertPos1[0]-@p2pVertPos0[0]),(@p2pVertPos1[1]-@p2pVertPos0[1]),(@p2pVertPos1[2]-@p2pVertPos0[2]));

	#determining the SOURCE selection mode
	if(lxq( "select.typeFrom {polygon;item;vertex;edge} ?" ) && lxq( "select.count polygon ?" )) {$source_selType = polygon;}
	elsif(lxq( "select.typeFrom {edge;polygon;item;vertex} ?" ) && lxq( "select.count edge ?" )) {$source_selType = edge;}
	elsif (lxq( "select.count polygon ?" )) {$source_selType = polygon;}
	elsif (lxq( "select.count edge ?" )) {$source_selType = edge;}
	else {
		$source_selType = polygon;
		lx("select.type vertex");
		lx("select.element $mainlayer vertex set {@p2pVertSel[0]}");
		lx("select.connect");
		lx("select.convert polygon");
	}

	#checking which align axes are on:
	if ($alignX == 1) {$X = @p2pDisp[0];} else {$X = 0; }
	if ($alignY == 1) {$Y = @p2pDisp[1];} else {$Y = 0; }
	if ($alignZ == 1) {$Z = @p2pDisp[2];} else {$Z = 0; }

	#go to the SOURCE selection mode
	lx("select.type $source_selType");

	#p2p alignment MOVE
	lx("tool.set xfrm.move on");
	lx("tool.reset");
	lx("tool.setAttr xfrm.move X {$X}");
	lx("tool.setAttr xfrm.move Y {$Y}");
	lx("tool.setAttr xfrm.move Z {$Z}");
	lx("tool.doApply");
	lx("tool.set xfrm.move off");
}









#------------------------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------------------------
#POINT TO POINT SCALE object's (two points) to the other two selected (two points') scale
#------------------------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------------------------
sub p2pScale
{
	lxout("[->] Using the P2PScale subroutine");

	#determining the SOURCE selection mode
	if(lxq( "select.typeFrom {polygon;item;vertex;edge} ?" ) && lxq( "select.count polygon ?" )) {$source_selType = polygon;}
	elsif(lxq( "select.typeFrom {edge;polygon;item;vertex} ?" ) && lxq( "select.count edge ?" )) {$source_selType = edge;}
	elsif (lxq( "select.count polygon ?" )) {$source_selType = polygon;}
	elsif (lxq( "select.count edge ?" )) {$source_selType = edge;}
	else {die("\n.\n[-------------------------You must have some edges or polys selected when using point to point-------------------------------]\n[--PLEASE TURN OFF THIS WARNING WINDOW by clicking on the (In the future) button and choose (Hide Message)--] \n[-----------------------------------This window is not supposed to come up, but I can't control that.---------------------------]\n.\n");}

	#grab the vert positions (check for dupes if the user asks for that)
	our @selVerts = remDupeAxVerts();

	my @vertPos1 = lxq("query layerservice vert.pos ? @selVerts[0]");
	my @vertPos2 = lxq("query layerservice vert.pos ? @selVerts[1]");
	my @vertPos3 = lxq("query layerservice vert.pos ? @selVerts[2]");
	my @vertPos4 = lxq("query layerservice vert.pos ? @selVerts[3]");

	my @disp1 = ((@vertPos2[0]-@vertPos1[0]),(@vertPos2[1]-@vertPos1[1]),(@vertPos2[2]-@vertPos1[2]));
	my @disp2 = ((@vertPos4[0]-@vertPos3[0]),(@vertPos4[1]-@vertPos3[1]),(@vertPos4[2]-@vertPos3[2]));

	#lxout("1=@vertPos1 <><> 2=@vertPos2");
	#lxout("3=@vertPos3 <><> 4=@vertPos4");
	#lxout("disp 1 @disp1");
	#lxout("disp 2 @disp2");


	#figure out which axis to pay attention to to determine the scaling
	my $biggestDisp=@disp1[0];
	my $biggestDispAxis;
	my $i=0;
	foreach (@disp1)
	{
		$_ = abs($_);
		if ($_ >= $biggestDisp)
		{
			$biggestDisp = $_;
			$biggestDispAxis = $i;
		}
		$i++;
		#lxout("biggest disp so far: $biggestDispAxis <> $_");
	}


	#figure out the difference between both disps.
	my $dispDiff = (abs(@disp2[$biggestDispAxis]) / abs(@disp1[$biggestDispAxis]));
	#lxout("the difference is this: $dispDiff");


	#go to the SOURCE selection mode
	lx("select.type $source_selType");

	#scale the object
	lx("tool.set actr.auto on");
	lx("tool.set xfrm.scale on");
	lx("tool.reset");
	lx("tool.setAttr center.auto cenX {@vertPos1[0]}");
	lx("tool.setAttr center.auto cenY {@vertPos1[1]}");
	lx("tool.setAttr center.auto cenZ {@vertPos1[2]}");
	lx("tool.setAttr xfrm.scale factor {$dispDiff}");
	lx("tool.doApply");
	lx("tool.set xfrm.scale off");
}





#------------------------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------------------------
#POINT TO POINT STRETCH object's (two points) to the other two selected (two points') scale
#------------------------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------------------------
sub p2pStretch
{
	lxout("[->] Using the P2PStretch subroutine");

	#determining the SOURCE selection mode
	if(lxq( "select.typeFrom {polygon;item;vertex;edge} ?" ) && lxq( "select.count polygon ?" )) {$source_selType = polygon;}
	elsif(lxq( "select.typeFrom {edge;polygon;item;vertex} ?" ) && lxq( "select.count edge ?" )) {$source_selType = edge;}
	elsif (lxq( "select.count polygon ?" )) {$source_selType = polygon;}
	elsif (lxq( "select.count edge ?" )) {$source_selType = edge;}
	else {die("\n.\n[-------------------------You must have some edges or polys selected when using point to point-------------------------------]\n[--PLEASE TURN OFF THIS WARNING WINDOW by clicking on the (In the future) button and choose (Hide Message)--] \n[-----------------------------------This window is not supposed to come up, but I can't control that.---------------------------]\n.\n");}

	#EDIT : let's not check for dupe verts because there's no way to fit two options into one button. :(
	#grab the vert positions (check for dupes if the user asks for that)
	#our @selVerts = remDupeAxVerts();
	my @selVerts = lxq("query layerservice verts ? selected");

	my @vertPos1 = lxq("query layerservice vert.pos ? @selVerts[0]");
	my @vertPos2 = lxq("query layerservice vert.pos ? @selVerts[1]");
	my @vertPos3 = lxq("query layerservice vert.pos ? @selVerts[2]");
	my @vertPos4 = lxq("query layerservice vert.pos ? @selVerts[3]");

	my @disp1 = ((@vertPos2[0]-@vertPos1[0]),(@vertPos2[1]-@vertPos1[1]),(@vertPos2[2]-@vertPos1[2]));
	my @disp2 = ((@vertPos4[0]-@vertPos3[0]),(@vertPos4[1]-@vertPos3[1]),(@vertPos4[2]-@vertPos3[2]));

	#lxout("1=@vertPos1 <><> 2=@vertPos2");
	#lxout("3=@vertPos3 <><> 4=@vertPos4");
	#lxout("disp 1 @disp1");
	#lxout("disp 2 @disp2");


	#figure out which axis to pay attention to to determine the scaling  (and gotta remove any zeros)
	for (my $i=0; $i<@disp1; $i++){	if (@disp1[$i] == 0){	@disp1[$i] = 0.000001;	}}
	for (my $i=0; $i<@disp2; $i++){	if (@disp2[$i] == 0){	@disp2[$i] = 0.000001;	}}
	my @dispDifference = (abs(@disp2[0]) / abs(@disp1[0])	, abs(@disp2[1]) / abs(@disp1[1]) , abs(@disp2[2]) / abs(@disp1[2]));
	lxout("dispDifference = @dispDifference");

	#go to the SOURCE selection mode
	lx("select.type $source_selType");


	#stretch the object
	lx("tool.set actr.auto on");
	lx("tool.set xfrm.stretch on");
	lx("tool.reset");
	lx("tool.setAttr center.auto cenX {@vertPos1[0]}");
	lx("tool.setAttr center.auto cenY {@vertPos1[1]}");
	lx("tool.setAttr center.auto cenZ {@vertPos1[2]}");
	if ($X == 1)	{	lx("tool.setAttr xfrm.stretch factX {@dispDifference[0]}");	}
	else			{	lx("tool.setAttr xfrm.stretch factX {1}");				}
	if ($Y == 1)	{	lx("tool.setAttr xfrm.stretch factY {@dispDifference[1]}");	}
	else			{	lx("tool.setAttr xfrm.stretch factY {1}");				}
	if ($Z == 1)	{	lx("tool.setAttr xfrm.stretch factZ {@dispDifference[2]}");	}
	else			{	lx("tool.setAttr xfrm.stretch factZ {1}");				}
	lx("tool.doApply");
	lx("tool.set xfrm.stretch off");
}






#------------------------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------------------------
#SCALE start object to match destination's scale
#------------------------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------------------------
sub fit
{
	lxout("[->] Using the FIT subroutine");

	#determining the bounding box scales
	my @start_bbox_scale = ((@start_bbox[3] - @start_bbox[0]),(@start_bbox[4] - @start_bbox[1]),(@start_bbox[5] - @start_bbox[2]));
	my @dest_bbox_scale = ((@dest_bbox[3] - @dest_bbox[0]),(@dest_bbox[4] - @dest_bbox[1]),(@dest_bbox[5] - @dest_bbox[2]));
	#lxout("--------------------BEFORE--------------------------------");
	#lxout("start scale = @start_bbox_scale ");
	#lxout("dest scale = @dest_bbox_scale ");
	#lxout("------------------------------------------------------------------");

	#putting in a special case to fix any ZERO subdivisions
	if (@start_bbox_scale[0] == 0)	{	@start_bbox_scale[0] = .00000001;	}
	if (@start_bbox_scale[1] == 0)	{	@start_bbox_scale[1] = .00000001;	}
	if (@start_bbox_scale[2] == 0)	{	@start_bbox_scale[2] = .00000001;	}
	if (@dest_bbox_scale[0] == 0)	{	@dest_bbox_scale[0] = .00000001;	}
	if (@dest_bbox_scale[1] == 0)	{	@dest_bbox_scale[1] = .00000001;	}
	if (@dest_bbox_scale[2] == 0)	{	@dest_bbox_scale[2] = .00000001;	}

	#lxout("------------------------AFTER-------------------------------");
	#lxout("start scale = @start_bbox_scale ");
	#lxout("dest scale = @dest_bbox_scale ");
	#lxout("------------------------------------------------------------------");


	#determining the bounding box scale differences
	my @scale = ((@dest_bbox_scale[0]/@start_bbox_scale[0]),(@dest_bbox_scale[1]/@start_bbox_scale[1]),(@dest_bbox_scale[2]/@start_bbox_scale[2]));
	#lxout("FINAL SCALE IS THIS: @scale");

	if ($prop != 1)
	{
		#-----------------------------------
		#non proportional scaling
		#-----------------------------------
		#checking which fit axes are on:
		if ($fitX == 1) {$X = @scale[0];} else {$X = 1; lxout("X off");}
		if ($fitY == 1) {$Y = @scale[1];} else {$Y = 1; lxout("Y off");}
		if ($fitZ == 1) {$Z = @scale[2];} else {$Z = 1; lxout("Z off");}
		if (($alignX == 1) || ($alignY == 1) || ($alignZ == 1))
		{
			@scaleCenter = @dest_center;
			#lxout("Scaling from dest selection's center");
		}
		else
		{
			@scaleCenter = @start_center;
			#lxout("Scaling from start object's center");
		}

		#scale tool
		lx("tool.set xfrm.stretch on");
		lx("tool.reset");
		lx("tool.setAttr center.select cenX {@scaleCenter[0]}");
		lx("tool.setAttr center.select cenY {@scaleCenter[1]}");
		lx("tool.setAttr center.select cenZ {@scaleCenter[2]}");
		lx("tool.setAttr xfrm.stretch factX {$X}");
		lx("tool.setAttr xfrm.stretch factY {$Y}");
		lx("tool.setAttr xfrm.stretch factZ {$Z}");
		lx("tool.doApply");
		lx("tool.set xfrm.stretch off");
	}
	else
	{
		#-----------------------------------
		#proportional scaling
		#-----------------------------------
		lxout("PROPORTIONAL SCALING IS ON");
		#check which scale axis should be used
		if ((@start_bbox_scale[0] >= @start_bbox_scale[1]) && (@start_bbox_scale[0] >= @start_bbox_scale[2]))
		{
			lxout("aspect X is the biggest");
			$greaterAxis = 0;
		}
		elsif ((@start_bbox_scale[1] >= @start_bbox_scale[0]) && (@start_bbox_scale[1] >= @start_bbox_scale[2]))
		{
			lxout("aspect Y is the biggest");
			$greaterAxis = 1;
		}
		else
		{
			lxout("aspect Z is the biggest");
			$greaterAxis = 2;
		}

		#check which action center to use for the scale tool
		if (($alignX == 1) || ($alignY == 1) || ($alignZ == 1))
		{
			@scaleCenter = @dest_center;
			#lxout("Scaling from dest selection's center");
		}
		else
		{
			@scaleCenter = @start_center;
			#lxout("Scaling from start object's center");
		}


		#scale tool
		lx("tool.set xfrm.stretch on");
		lx("tool.reset");
		lx("tool.setAttr center.select cenX {@scaleCenter[0]}");
		lx("tool.setAttr center.select cenY {@scaleCenter[1]}");
		lx("tool.setAttr center.select cenZ {@scaleCenter[2]}");
		lx("tool.setAttr xfrm.stretch factX {@scale[$greaterAxis]}");
		lx("tool.setAttr xfrm.stretch factY {@scale[$greaterAxis]}");
		lx("tool.setAttr xfrm.stretch factZ {@scale[$greaterAxis]}");
		lx("tool.doApply");
		lx("tool.set xfrm.stretch off");
	}
}



#------------------------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------------------------
#SNAP THE SELECTED GEOMETRY TO THE GRID BY IT'S ANCHOR POINT
#------------------------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------------------------
sub snapPos{
	if (lxq( "select.typeFrom {vertex;edge;polygon;item} ?"))		{our $selType = "vertex";}
	elsif (lxq( "select.typeFrom {edge;polygon;item;vertex} ?"))	{our $selType = "edge";}
	elsif (lxq( "select.typeFrom {polygon;item;vertex;edge} ?"))	{our $selType = "polygon";}
	else {die("\\\\n.\\\\n[---------------------------------------------You're not in vert, edge, or polygon mode.--------------------------------------------]\\\\n[--PLEASE TURN OFF THIS WARNING WINDOW by clicking on the (In the future) button and choose (Hide Message)--] \\\\n[-----------------------------------This window is not supposed to come up, but I can't control that.---------------------------]\\\\n.\\\\n");}

	if (lxq("select.count vertex ?") == 0){die("\\\\n.\\\\n[------------------------You don't have any vertices selected so I'm cancelling the script.--------------------------]\\\\n[--PLEASE TURN OFF THIS WARNING WINDOW by clicking on the (In the future) button and choose (Hide Message)--] \\\\n[-----------------------------------This window is not supposed to come up, but I can't control that.---------------------------]\\\\n.\\\\n");}

	#find the grid numeric system
	if (lxq("pref.value units.system ?") eq "game"){
		our $power = 2;
	}else{
		our $power = 10;
	}

	#find grid size
	my $viewport = lxq("query view3dservice mouse.view ?");
	my @axis = lxq("query view3dservice view.axis ? $viewport");
	my @frame = lxq("query view3dservice view.frame ?");
	my $scale = lxq("query view3dservice view.scale ? $viewport");
	my @viewBbox = lxq("query view3dservice view.rect ? $viewport");
	my @viewScale = (($scale * @viewBbox[2]),($scale * @viewBbox[3]));
	my @div = ((@viewScale[0]/16),(@viewScale[1]/16));
	my $log = int(.65 + (log(@div[0])/log($power)));
	my $grid = $power ** $log;
	#if METERS PER UNIT option is on, scale grid up and then round to power of 2
	if ($gridDiv != 1){	$grid = findClosestPowerOf2($grid * $gridMult);	}

	#find primary axis
	my @xAxis = (1,0,0);
	my @yAxis = (0,1,0);
	my @zAxis = (0,0,1);
	my $dp0 = dotProduct(\@axis,\@xAxis);
	my $dp1 = dotProduct(\@axis,\@yAxis);
	my $dp2 = dotProduct(\@axis,\@zAxis);
	if 		((abs($dp0) >= abs($dp1)) && (abs($dp0) >= abs($dp2)))	{	our $axis = 0;	lxout("[->] : Using world X axis");}
	elsif	((abs($dp1) >= abs($dp0)) && (abs($dp1) >= abs($dp2)))	{	our $axis = 1;	lxout("[->] : Using world Y axis");}
	else															{	our $axis = 2;	lxout("[->] : Using world Z axis");}

	#find vert pos and move polys to nearest grid point.
	my $mainlayer = lxq("query layerservice layers ? main");
	my @verts = lxq("query layerservice verts ? selected");
	my @vertPos = lxq("query layerservice vert.pos ? $verts[-1]");
	my @vertPosCopy = @vertPos;
	my @keepNegative;
	my @roundedVertPos;
	if ($vertPosCopy[0] < 1){$keepNegative[0] = -1; $vertPosCopy[0] *= -1;}	else {$keepNegative[0] = 1;}
	if ($vertPosCopy[1] < 1){$keepNegative[1] = -1; $vertPosCopy[1] *= -1;}	else {$keepNegative[1] = 1;}
	if ($vertPosCopy[2] < 1){$keepNegative[2] = -1; $vertPosCopy[2] *= -1;}	else {$keepNegative[2] = 1;}
	
	#ignore the METERS PER GAME UNIT OPTION if it's set to it's default value
	if ($gridMult == 1){
		@roundedVertPos =  (int(($vertPosCopy[0] / $grid) + .5) * $grid * $keepNegative[0] ,
							int(($vertPosCopy[1] / $grid) + .5) * $grid * $keepNegative[1] ,
							int(($vertPosCopy[2] / $grid) + .5) * $grid * $keepNegative[2] );
	}
	#or use the METERS PER GAME UNIT OPTION if it is being used
	else{
		@roundedVertPos =  (int(($vertPosCopy[0] * $gridMult / $grid) + .5) * $grid * $gridDiv * $keepNegative[0] ,
							int(($vertPosCopy[1] * $gridMult / $grid) + .5) * $grid * $gridDiv * $keepNegative[1] ,
							int(($vertPosCopy[2] * $gridMult / $grid) + .5) * $grid * $gridDiv * $keepNegative[2] );
	}

	my @vertPosDiff = ( ($roundedVertPos[0] - $vertPos[0]) , ($roundedVertPos[1] - $vertPos[1]) , ($roundedVertPos[2] - $vertPos[2]) );

	#now zero out the axes the user doesn't want to move.
	if ($snapPosDim == 1){
		if ($axis != 0){ @vertPosDiff[0] = 0; }
		if ($axis != 1){ @vertPosDiff[1] = 0; }
		if ($axis != 2){ @vertPosDiff[2] = 0; }
	}elsif ($snapPosDim == 2){
		if ($axis == 0){ @vertPosDiff[0] = 0; }
		if ($axis == 1){ @vertPosDiff[1] = 0; }
		if ($axis == 2){ @vertPosDiff[2] = 0; }
	}

	#now move the polys, verts, or edges to the vert's grid point.
	if (lxq("select.count polygon ?"))	{lx("select.type polygon");	}
	elsif (lxq("select.count edge ?"))	{lx("select.type edge");	}
	else								{lx("select.type vertex");	}
	#MOVE
	lx("tool.set xfrm.move on");
	lx("tool.reset");
	lx("tool.setAttr xfrm.move X {@vertPosDiff[0]}");
	lx("tool.setAttr xfrm.move Y {@vertPosDiff[1]}");
	lx("tool.setAttr xfrm.move Z {@vertPosDiff[2]}");
	lx("tool.doApply");
	lx("tool.set xfrm.move off");

	#restore the original selection type
	lx("select.type $selType");
}


#------------------------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------------------------
#SNAP THE SELECTED ITEM(s) POSITION TO THE GRID
#------------------------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------------------------
sub itemPos{
		my @selection = lxq("query sceneservice selection ? all");
		if ($#selection == -1){die("You don't have any items selected, so I'm cancelling the script.");}


		#find the grid numeric system
		if (lxq("pref.value units.system ?") eq "game"){
			our $power = 2;
		}else{
			our $power = 10;
		}

		#find grid size
		my $viewport = lxq("query view3dservice mouse.view ?");
		my @axis = lxq("query view3dservice view.axis ? $viewport");
		my @frame = lxq("query view3dservice view.frame ?");
		my $scale = lxq("query view3dservice view.scale ? $viewport");
		my @viewBbox = lxq("query view3dservice view.rect ? $viewport");
		my @viewScale = (($scale * @viewBbox[2]),($scale * @viewBbox[3]));
		my @div = ((@viewScale[0]/16),(@viewScale[1]/16));
		my $log = int(.65 + (log(@div[0])/log($power)));
		my $grid = $power ** $log;

		#find primary axis
		my @xAxis = (1,0,0);
		my @yAxis = (0,1,0);
		my @zAxis = (0,0,1);
		my $dp0 = dotProduct(\@axis,\@xAxis);
		my $dp1 = dotProduct(\@axis,\@yAxis);
		my $dp2 = dotProduct(\@axis,\@zAxis);
		if 		((abs($dp0) >= abs($dp1)) && (abs($dp0) >= abs($dp2)))	{	our $axis = 0;	lxout("[->] : Using world X axis");}
		elsif	((abs($dp1) >= abs($dp0)) && (abs($dp1) >= abs($dp2)))	{	our $axis = 1;	lxout("[->] : Using world Y axis");}
		else															{	our $axis = 2;	lxout("[->] : Using world Z axis");}

		#find item pos and quantize it to the nearest grid point
		foreach my $item (@selection){
			my @pos = lxq("query sceneservice item.pos ? $item");
			my @posCopy = @pos;
			my @keepNegative;
			if (@pos[0] < 1){@keepNegative[0] = -1; @pos[0] *= -1;}	else {@keepNegative[0] = 1;}
			if (@pos[1] < 1){@keepNegative[1] = -1; @pos[1] *= -1;}	else {@keepNegative[1] = 1;}
			if (@pos[2] < 1){@keepNegative[2] = -1; @pos[2] *= -1;}	else {@keepNegative[2] = 1;}
			my @roundedItemPos =   (int((@pos[0] / $grid) + .5) * $grid * @keepNegative[0] ,
									int((@pos[1] / $grid) + .5) * $grid * @keepNegative[1] ,
									int((@pos[2] / $grid) + .5) * $grid * @keepNegative[2] );

			#now zero out the axes the user doesn't want to move.
			if ($snapPosDim == 1){
				if ($axis != 0){ @roundedItemPos[0] = @posCopy[0]; }
				if ($axis != 1){ @roundedItemPos[1] = @posCopy[1]; }
				if ($axis != 2){ @roundedItemPos[2] = @posCopy[2]; }
			}elsif ($snapPosDim == 2){
				if ($axis == 0){ @roundedItemPos[0] = @posCopy[0]; }
				if ($axis == 1){ @roundedItemPos[1] = @posCopy[1]; }
				if ($axis == 2){ @roundedItemPos[2] = @posCopy[2]; }
			}

			lxout("posCopy = @posCopy");
			lxout("roundedItemPos = @roundedItemPos");



			#now move the item
			lx("select.subItem {$item} set mesh;meshInst;camera;light;backdrop;groupLocator;locator;deform;locdeform 0 0");
			lx("item.channel locator(translation)\$pos.X {@roundedItemPos[0]}");
			lx("item.channel locator(translation)\$pos.Y {@roundedItemPos[1]}");
			lx("item.channel locator(translation)\$pos.Z {@roundedItemPos[2]}");
		}

		#now reselect the original items
		lx("select.drop item");
		foreach my $item (@selection){lx("select.subItem {$item} add mesh;meshInst;camera;light;backdrop;groupLocator;locator;deform;locdeform 0 0");}
}

#------------------------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------------------------
#QUANTIZE BBOX SUB
#------------------------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------------------------
sub quantizeBBoX{
	my $selType;


	#find the grid numeric system
	if (lxq("pref.value units.system ?") eq "game"){
		our $power = 2;
	}else{
		our $power = 10;
	}

	#find grid size
	my $viewport = lxq("query view3dservice mouse.view ?");
	my @axis = lxq("query view3dservice view.axis ? $viewport");
	my @frame = lxq("query view3dservice view.frame ?");
	my $scale = lxq("query view3dservice view.scale ? $viewport");
	my @viewBbox = lxq("query view3dservice view.rect ? $viewport");
	my @viewScale = (($scale * @viewBbox[2]),($scale * @viewBbox[3]));
	my @div = ((@viewScale[0]/16),(@viewScale[1]/16));
	my $log = int(.65 + (log(@div[0])/log($power)));
	my $grid = $power ** $log;
	#if METERS PER UNIT option is on, scale grid up and then round to power of 2
	if ($gridDiv != 1){	$grid = findClosestPowerOf2($grid * $gridMult);	}
	
	#find primary axis
	my @xAxis = (1,0,0);
	my @yAxis = (0,1,0);
	my @zAxis = (0,0,1);
	my $dp0 = dotProduct(\@axis,\@xAxis);
	my $dp1 = dotProduct(\@axis,\@yAxis);
	my $dp2 = dotProduct(\@axis,\@zAxis);
	if 		((abs($dp0) >= abs($dp1)) && (abs($dp0) >= abs($dp2)))	{	our $axis = 0;	lxout("[->] : Using world X axis");}
	elsif	((abs($dp1) >= abs($dp0)) && (abs($dp1) >= abs($dp2)))	{	our $axis = 1;	lxout("[->] : Using world Y axis");}
	else															{	our $axis = 2;	lxout("[->] : Using world Z axis");}




	#convert selection to verts
	if ( lxq( "select.typeFrom {vertex;edge;polygon;item} ?" ) ){
		$selType = "vertex";
		if (lxq("select.count vertex ?") == 0){lx("select.all");}
		@verts = lxq("query layerservice verts ? selected");
	}
	elsif ( lxq( "select.typeFrom {edge;polygon;item;vertex} ?" ) ){
		$selType = "edge";
		if (lxq("select.count edge ?") == 0){
			lx("select.type vertex");
			lx("select.all");
		}else{
			lx("select.convert vertex");
		}
	}
	elsif ( lxq( "select.typeFrom {polygon;item;vertex;edge} ?" ) ){
		$selType = "polygon";
		if (lxq("select.count polygon ?") == 0){
			lx("select.type vertex");
			lx("select.all");
		}else{
			lx("select.convert vertex");
		}
	}
	else{
		#die("\\\\n.\\\\n[---------------------------------------------You're not in vert, edge, or polygon mode.--------------------------------------------]\\\\n[--PLEASE TURN OFF THIS WARNING WINDOW by clicking on the (In the future) button and choose (Hide Message)--] \\\\n[-----------------------------------This window is not supposed to come up, but I can't control that.---------------------------]\\\\n.\\\\n");
	}



	my @verts = lxq("query layerservice verts ? selected");
	lxout("verts = @verts");
	my @bbox = boundingbox(@verts);
	
	my @bboxCenter = ( ($bbox[0]+$bbox[3])*0.5 , ($bbox[1]+$bbox[4])*0.5 , ($bbox[2]+$bbox[5])*0.5 );
	my @roundedBbox = ( roundNumber($bbox[0],$grid), roundNumber($bbox[1],$grid), roundNumber($bbox[2],$grid), roundNumber($bbox[3],$grid), roundNumber($bbox[4],$grid), roundNumber($bbox[5],$grid) );
	my @roundedCenter = ( ($roundedBbox[0]+$roundedBbox[3])*0.5 , ($roundedBbox[1]+$roundedBbox[4])*0.5 , ($roundedBbox[2]+$roundedBbox[5])*0.5 );
	
	#determine scale amount
	my @size = ( $bbox[3]-$bbox[0] , $bbox[4]-$bbox[1] , $bbox[5]-$bbox[2] );
	lxout("size = @size");
	my @roundedSize = ( roundNumber($roundedBbox[3]-$roundedBbox[0],$grid) , roundNumber($roundedBbox[4]-$roundedBbox[1],$grid) , roundNumber($roundedBbox[5]-$roundedBbox[2],$grid) );
	
	lxout("roundedSize = @roundedSize");
	for (my $i=0; $i<@roundedSize; $i++){if ($roundedSize[$i] == 0){$roundedSize[$i] = $grid;}}

	if ($snapPosDim == 1){
		if ($axis != 0){ $size[0] = 1; $roundedSize[0] = 1;}
		if ($axis != 1){ $size[1] = 1; $roundedSize[1] = 1;}
		if ($axis != 2){ $size[2] = 1; $roundedSize[2] = 1;}
	}elsif ($snapPosDim == 2){
		if ($axis == 0){ $size[0] = 1; $roundedSize[0] = 1;}
		if ($axis == 1){ $size[1] = 1; $roundedSize[1] = 1;}
		if ($axis == 2){ $size[2] = 1; $roundedSize[2] = 1;}
	}

	my @scaleAmount = ( $roundedSize[0]/$size[0] , $roundedSize[1]/$size[1] , $roundedSize[2]/$size[2] );

	#determine tool center and move amount
	my @pivPos = ($bbox[0],$bbox[1],$bbox[2]);
	my @roundedPivPos;
	my @moveAmount = (0,0,0);
	if ($snapPosDim == 1){
		if ($axis == 0){
			my $roundXMin = roundNumber($bbox[0],$grid);
			my $roundXMax = roundNumber($bbox[3],$grid);
			if ( abs($roundXMin - $bbox[0]) < abs($roundXMax - $bbox[3]) ){
				$pivPos[0] = $bbox[0];
				@moveAmount = 	($roundXMin-$bbox[0],0,0);
			}else{
				$pivPos[0] = $bbox[3];
				@moveAmount = 	($roundXMax-$bbox[3],0,0);
			}
		}elsif ($axis == 1){
			my $roundYMin = roundNumber($bbox[1],$grid);
			my $roundYMax = roundNumber($bbox[4],$grid);
			if ( abs($roundYMin - $bbox[1]) < abs($roundYMax - $bbox[4]) ){
				$pivPos[1] = $bbox[1];
				@moveAmount = 	(0,$roundYMin-$bbox[1],0);
			}else{
				$pivPos[1] = $bbox[4];
				@moveAmount = 	(0,$roundYMax-$bbox[4],0);
			}
		}else{
			my $roundYMin = roundNumber($bbox[2],$grid);
			my $roundZMax = roundNumber($bbox[5],$grid);
			if ( abs($roundZMin - $bbox[2]) < abs($roundZMax - $bbox[5]) ){
				$pivPos[2] = $bbox[2];
				@moveAmount = 	(0,0,$roundZMin-$bbox[2]);
			}else{
				$pivPos[2] = $bbox[5];
				@moveAmount = 	(0,0,$roundZMax-$bbox[5]);
			}
		}
	}elsif ($snapPosDim == 2){
		if ($axis == 0){
			my $roundYMin = roundNumber($bbox[1],$grid);
			my $roundYMax = roundNumber($bbox[4],$grid);
			my $roundZMin = roundNumber($bbox[2],$grid);
			my $roundZMax = roundNumber($bbox[5],$grid);
			if ( abs($roundYMin - $bbox[1]) < abs($roundYMax - $bbox[4]) ){
				$pivPos[1] = $bbox[1];
				$moveAmount[1] = $roundYMin-$bbox[1];
			}else{
				$pivPos[1] = $bbox[4];
				$moveAmount[1] = $roundYMax-$bbox[4];
			}
			if ( abs($roundZMin - $bbox[2]) < abs($roundZMax - $bbox[5]) ){
				$pivPos[2] = $bbox[2];
				$moveAmount[2] = $roundZMin-$bbox[2];
			}else{
				$pivPos[2] = $bbox[5];
				$moveAmount[2] = $roundZMax-$bbox[5];
			}
		}elsif ($axis == 1){
			my $roundXMin = roundNumber($bbox[0],$grid);
			my $roundXMax = roundNumber($bbox[3],$grid);
			my $roundZMin = roundNumber($bbox[2],$grid);
			my $roundZMax = roundNumber($bbox[5],$grid);
			if ( abs($roundXMin - $bbox[0]) < abs($roundXMax - $bbox[3]) ){
				$pivPos[0] = $bbox[0];
				$moveAmount[0] = $roundXMin-$bbox[0];
			}else{
				$pivPos[0] = $bbox[3];
				$moveAmount[0] = $roundXMax-$bbox[3];
			}
			if ( abs($roundZMin - $bbox[2]) < abs($roundZMax - $bbox[5]) ){
				$pivPos[2] = $bbox[2];
				$moveAmount[2] = $roundZMin-$bbox[2];
			}else{
				$pivPos[2] = $bbox[5];
				$moveAmount[2] = $roundZMax-$bbox[5];
			}
		}else{
			my $roundXMin = roundNumber($bbox[0],$grid);
			my $roundXMax = roundNumber($bbox[3],$grid);
			my $roundYMin = roundNumber($bbox[1],$grid);
			my $roundYMax = roundNumber($bbox[4],$grid);
			if ( abs($roundXMin - $bbox[0]) < abs($roundXMax - $bbox[3]) ){
				$pivPos[0] = $bbox[0];
				$moveAmount[0] = $roundXMin-$bbox[0];
			}else{
				$pivPos[0] = $bbox[3];
				$moveAmount[0] = $roundXMax-$bbox[3];
			}
			if ( abs($roundYMin - $bbox[1]) < abs($roundYMax - $bbox[4]) ){
				$pivPos[1] = $bbox[1];
				$moveAmount[1] = $roundYMin-$bbox[1];
			}else{
				$pivPos[1] = $bbox[4];
				$moveAmount[1] = $roundYMax-$bbox[4];
			}
		}
	}else{
		my $roundXMin = roundNumber($bbox[0],$grid);
		my $roundXMax = roundNumber($bbox[3],$grid);
		my $roundYMin = roundNumber($bbox[1],$grid);
		my $roundYMax = roundNumber($bbox[4],$grid);
		my $roundZMin = roundNumber($bbox[2],$grid);
		my $roundZMax = roundNumber($bbox[5],$grid);
		if ( abs($roundXMin - $bbox[0]) < abs($roundXMax - $bbox[3]) ){
			$pivPos[0] = $bbox[0];
			$moveAmount[0] = $roundXMin-$bbox[0];
		}else{
			$pivPos[0] = $bbox[3];
			$moveAmount[0] = $roundXMax-$bbox[3];
		}
		if ( abs($roundYMin - $bbox[1]) < abs($roundYMax - $bbox[4]) ){
			$pivPos[1] = $bbox[1];
			$moveAmount[1] = $roundYMin-$bbox[1];
		}else{
			$pivPos[1] = $bbox[4];
			$moveAmount[1] = $roundYMax-$bbox[4];
		}
		if ( abs($roundZMin - $bbox[2]) < abs($roundZMax - $bbox[5]) ){
			$pivPos[2] = $bbox[2];
			$moveAmount[2] = $roundZMin-$bbox[2];
		}else{
			$pivPos[2] = $bbox[5];
			$moveAmount[2] = $roundZMax-$bbox[5];
		}
	}



	#scale and move the geometry
	lx("tool.set actr.auto on");
	lx("tool.set xfrm.stretch on");
	lx("tool.reset");
	lx("tool.setAttr center.auto cenX {$pivPos[0]}");
	lx("tool.setAttr center.auto cenY {$pivPos[1]}");
	lx("tool.setAttr center.auto cenZ {$pivPos[2]}");
	lx("tool.setAttr xfrm.stretch factX {$scaleAmount[0]}");
	lx("tool.setAttr xfrm.stretch factY {$scaleAmount[1]}");
	lx("tool.setAttr xfrm.stretch factZ {$scaleAmount[2]}");
	lx("tool.doApply");
	lx("tool.set xfrm.stretch off");

	lx("tool.set xfrm.move on");
	lx("tool.reset");
	lx("tool.setAttr xfrm.move X {$moveAmount[0]}");
	lx("tool.setAttr xfrm.move Y {$moveAmount[1]}");
	lx("tool.setAttr xfrm.move Z {$moveAmount[2]}");
	lx("tool.doApply");
	lx("tool.set xfrm.move off");

	lx("select.type $selType");
}



#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#--------------------------          SUBROUTINES          ---------------------------------------
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------

sub timer
{
	$end = times;
	$time = $end-$start;
	lxout("             (@_ TIMER==>>$time)");
}


#-----------------------------------------------------------------------------------
#POPUP SUBROUTINE
#-----------------------------------------------------------------------------------
sub popup #(MODO2 FIX)
{
	lx("dialog.setup yesNo");
	lx("dialog.msg {@_}");
	lx("dialog.open");
	my $confirm = lxq("dialog.result ?");
	if($confirm eq "no"){die;}
}


#-----------------------------------------------------------------------------------
#CHECK FOR FARTHEST (axes) DISPLACED VERTS subroutine
#-----------------------------------------------------------------------------------
sub pointDispSort
{
	#GO thru the ARGs and see which disp axes we wanna check. [MODDED]
	lxout("[->] Using pointDispSort subroutine");
	#lxout("alignX = $alignX");
	#lxout("alignY = $alignY");
	#lxout("alignZ = $alignZ");

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
		#lxout("[ROUND $i]disp = @disp");
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

#-----------------------------------------------------------------------------------
#IGNORE VERTS THAT accidentally SHARE THE SAME NEEDED INFO subroutine
#-----------------------------------------------------------------------------------
sub remDupeAxVerts
{
	lxout("[->] Using remDupeAxVerts subroutine");

	#GO thru the vars and see which disp axes we wanna check.
	my $alignX = 1;
	my $alignY = 1;
	my $alignZ = 1;
	foreach $arg(@ARGV)
	{
		if ($arg eq "x")	{$alignX=0; lxout("using X window to determine 'duplicate' verts!!!!");}
		if ($arg eq "y")	{$alignY=0; lxout("using Y window to determine 'duplicate' verts!!!!");}
		if ($arg eq "z")	{$alignZ=0; lxout("using Z window to determine 'duplicate' verts!!!!");}
	}

	if (($alignX == 1) && ($alignY == 1) && ($alignZ == 1))
	{
		lxout("[->] User's telling me not to check for dupe verts");
		our @nonDupeVerts = lxq("query layerservice verts ? selected");
	}
	else
	{
		#Begin script
		my @verts = lxq("query layerservice verts ? selected");
		our @nonDupeVerts;
		my $vertPositions;
		my $i = 0;

		foreach my $vert (@verts)
		{
			$i++;
			my @vertPos = lxq("query layerservice vert.pos ? $vert");
			#lxout("BEFORE : vertPos = @vertPos");
			if ($alignX == 0) { @vertPos[0] = 0; }
			if ($alignY == 0) { @vertPos[1] = 0; }
			if ($alignZ == 0) { @vertPos[2] = 0; }
			#lxout("AFTER : vertPos = @vertPos");
			my  $vertPos = "(@vertPos[0],@vertPos[1],@vertPos[2])";

			if ($vertPositions =~ /$vertPos/)
			{
				#lxout("DO NOTHING");
			}
			else
			{
				$vertPositions = $vertPositions . "," . $vertPos;
				#lxout("[ROUND $i] <> vertPositions=$vertPositions");
				push(@nonDupeVerts,$vert);
			}
		}
		if ($#nonDupeVerts > 3) { die("\n.\n[---------------Oops.  Even after trying to deselect duplicate verts, there are more than 4 verts selected!----------------]\n[--PLEASE TURN OFF THIS WARNING WINDOW by clicking on the (In the future) button and choose (Hide Message)--] \n[-----------------------------------This window is not supposed to come up, but I can't control that.---------------------------]\n.\n");}
	}

	return(@nonDupeVerts);
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
#GET OR SET THE PIVOT POINT FOR AN OBJECT (ver 1.2)
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE : m3PivPos(set,lxq("query layerservice layer.id ? $mainlayer"),34,22.5,37);
#USAGE : my @pos = m3PivPos(get,lxq("query layerservice layer.id ? $mainlayer"));
sub m3PivPos{
	#find out if pivot "translation" exists and if not, create it.
	if (@_[0] eq "set"){lx("select.subItem {@_[1]} set mesh;meshInst;camera;light;backdrop;groupLocator;locator;deform;locdeform 0 0");}
	else{
		if (lxq("query sceneservice mesh.isSelected ? $mainlayerID") == 0){
			lx("select.subItem {$mainlayerID} set mesh;triSurf;meshInst;camera;light;backdrop;groupLocator;replicator;deform;locdeform;chanModify;chanEffect 0 0");
		}
	}
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
#DOT PRODUCT subroutine (ver 1.1)
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE : my $dp = dotProduct(\@vector1,\@vector2);
sub dotProduct{
	return (	(${$_[0]}[0]*${$_[1]}[0])+(${$_[0]}[1]*${$_[1]}[1])+(${$_[0]}[2]*${$_[1]}[2])	);
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#FIND CLOSEST POWER OF 2 NUMBER (for the modo grid)
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE : my $closestPowerOf2 = findClosestPowerOf2(34.9); (returns 32)
#note : only works on positive numbers and only checks the numbers between (0.0000152879 and 65,536) and ignores 0 because modo doesn't have a grid size of 0
sub findClosestPowerOf2{
	my $closestPowerOf2 = 1;
	my $currentPowerOf2 = 1;
	my $closestDifference = abs($_[0] - 1);
	my $lastDiff = 99999999999999;
	my $result = 0;
	
	if ($_[0] > 0.75){
		if ($_[0] < 1.5){
			$result = 1;
		}else{
			for (my $i=0; $i<16; $i++){
				$currentPowerOf2 *= 2;
				my $diff = abs($currentPowerOf2 - $_[0]);
				if ($diff < $closestDifference){
					$closestPowerOf2 = $i;
					$closestDifference = $diff;
					$result = $currentPowerOf2;
					$lastDiff = $diff;
				}
				if ($diff > $lastDiff){
					last;
				}
			}
		}
	}elsif ($_[0] <= 0.75){
		if ($_[0] > 0.375){
			$result = 0.5;
		}else{
			for (my $i=0; $i<16; $i++){
				$currentPowerOf2 *= 0.5;
				my $diff = abs($currentPowerOf2 - $_[0]);
				if ($diff < $closestDifference){
					$closestPowerOf2 = $i;
					$closestDifference = $diff;
					$result = $currentPowerOf2;
					$lastDiff = $diff;
				}
				if ($diff > $lastDiff){
					last;
				}
			}
		}
	}
	
	return $result;
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
#THIS WILL ROUND THE CURRENT NUMBER to the amount you define. (modded to pay attention to METERS PER GAME UNIT grid)
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE : my $rounded = roundNumber(-1.45,1);
sub roundNumber(){
	my $flip = 0;
	my $number = $_[0];
	my $roundTo = $_[1];
	if ($roundTo < 0)	{	$roundTo *= -1;				}
	if ($number < 0)	{	$number *= -1;	$flip = 1;	}

	my $result = int(($number * $gridMult /$roundTo)+.5) * $roundTo * $gridDiv;
	if ($flip == 1)	{	return -$result;	}
	else			{	return $result;		}
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#------------[SCRIPT IS FINISHED] SAFETY REIMPLEMENTING-----------------
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------

#uses the new tool preset-------------------------------------------
if ($tool ne "none"){
	lx("tool.set $tool on");
	if (($modoVer < 300) && ($tool eq "TransformMove")){
		lx("tool.attr xfrm.transform H translate");
	}
}
#------------------------------------------------------------------------------

#Set the action center settings back
if ($actr == 1) {	lx( "tool.set {$seltype} on" ); }
else { lx("tool.set center.$selCenter on"); lx("tool.set axis.$selAxis on"); }

#Put symmetry back
if ($symmAxis ne "none")	{	lx("select.symmetryState $symmAxis");	}

#Set the layer reference back
lx("!!layer.setReference [$layerReference]");

#Put workplane back
lx("workPlane.edit {@WPmem[0]} {@WPmem[1]} {@WPmem[2]} {@WPmem[3]} {@WPmem[4]} {@WPmem[5]}");
