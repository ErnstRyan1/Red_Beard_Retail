#perl
#AUTHOR: Seneca Menard
#version 2.01

#This script is to offset the workplane to the location in 3d space that's underneath your mouse cursor.

#I always have trouble creating new geometry in modo's 3d window because the geometry's pretty much never created at the exact depth I wanted and will
#thus be totally different than what I thought I was creating because it was either much closer or farther away from the camera than I had expected.  So, I wrote
#this little script to offset the workplane to the exact spot in 3d space under your mouse.  It's pretty similar to the "workplane.fitGeometry" command, only it has three differences :
#(--1--) : You keep your current workplane's angle, whether it's custom or not.
#(--2--) : The new workplane is now a 3dworkplane, not a 2dworkplane.
#(--3--) : The script offsets the workplane to other layers' geometry as well, so you don't have to ever switch layers first.
#Because it's a 3d workplane, you can now create geometry on the perpendicular axes.  But, because it's now a hack-workplane, that means that modo's depth
#guesstimates will come back into the fray.  What that means is that if your camera's focal point is far away from the workplane, it'll offset the workplane for you to
#some other guesstimate depth.  To try and counter that, I put in a "viewport.goto" command into the script that forces your camera's focal point to go to the exact
#same spot that the workplane's going to.  This is good because modo won't move the workplane against your will.  The bad part is that the camera jumps.
#If you hate the camera jumping, you can take that out.  Just append "dontMove" to the script.   You just have a small percentage chance that geometry won't be created at the depth you wanted..
#example "@workplane_offsetToCursor.pl dontMove"

#(4-1-07 new feature.  arg = "justGoTo") : you can now use this script INSTEAD OF viewport.goto.  The problem with viewport.goto is that it only works on foreground layers and so you can use this script instead because it works on both.
#To only use the viewport.goto and don't change the workplane, append "justGoTo" to the script and it'll fire the viewport.goto command but not change the workplane.
#(9-7-07 bugfix) : the viewport.goto wasn't working properly on items in groups.  fixed.
#(4-27-08 bugfix) : if the mainlayer was active, but not "visible", it used to cause a problem.  That's now fixed.
#(7-29-08 new feature. arg = "1D") : This will only change the workplane position on the one world axis the user is looking towards the most, so you can set the workplane on a wall or floor and not mess up modo's grid snap.
#(10-24-08 bugfix) : i fixed two bugs.  One related to whether or not instances were getting selected on accident. The other is that you don't run into any more problems if the mainlayer is visible, yet not selected, or selected but not visible.
#(2-10-09 bugfix) : The script now forces visibility of the mainlayer and any of it's parents if they're hidden so the item selection will not fail.
#(3-14-09 speedup) : The script now runs much faster.
#(3-25-09 bugfix) : had to put in {} around variable names to stop a query fail.
#(3-31-09 bugfix) : found it's possible to have an active layer that's neither selected nor visible and put in a fix.
#(5-29-09 bugfix) : "goToElem" now works with multiple layers selected
#(12-7-10 feature) : the viewport.goto now works when you're in wireframe mode. (i'm forcing the viewport to temporarily be shaded so that viewport.goto works.)
#(12-20-10 feature) : added "setPolyWP" routine.  It will not offset the cursor to the point under the mouse, but instead use the poly under the mouse's axis as the workplane.  It's the same as workplane.fitSelect, only you don't lose your selection, it works on background layers, and is only one click.
#(1-21-11 bugfix) : if you had NO layers selected when running the script, it would complain about the further queries I ran.  i'm now forcing the selection of the item under teh mouse in case this failure happens.
#(3-21-11 bugfix) : the script can't work properly if the mouse is over a static mesh or mesh instance and so I'm basically cancelling the script now if it's over that, that way you don't get the error windows popping up anymore.

#ALL SCRIPT ARGUMENTS EXPLAINED:
# "dontMove" = This argument stops the camera from performing the viewport.goto.
# "justGoTo" = This argument stops the workplane from being adjusted.  All it's for is to just duplicate modo's viewport.goto command, only working with both foreground AND background layers.
# "goToElem" = This will center the workplane on the last selected vert, edge, or poly, depending on which selection mode you're currently in.
# "1D" = This will only change the workplane position on the one world axis the user is looking towards the most, so you can set the workplane on a wall or floor and not mess up modo's grid snap.
# "setPolyWP" = This will do a workplane.fitSel on the polygon under the mouse.  The reason why it's handy is so you can have your mouse over a poly in an inactive layer and it will still work.  Also, it aligns the workplane to the center of the element instead of where the mouse is.
# "force2dWP" = 2D and 3D workplanes aren't the same.  2D doesn't move the plane in depth in the 2D axis, but it does on the other 2 axes, whereas when you use 3d, it offsets in all 3d axes. (offset = moves the workplane to the nearest large grid point nearest the viewer)


#[[--------------------------------------------------------------------------------------]]
#SCRIPT ARGUMENTS
#[[--------------------------------------------------------------------------------------]]
foreach my $arg (@ARGV){
	if		($arg =~ /dontmove/i)		{	our $dontMove = 1;		}
	elsif	($arg =~ /justgoto/i)		{	our $justGoTo = 1;		}
	elsif	($arg =~ /gotoElem/i)		{	our $gotoElem = 1;		}
	elsif	($arg =~ /setPolyWP/i)		{	our $setPolyWP = 1;		}
	elsif	($arg =~ /1d/i)				{	our $onedimension = 1;	}
	elsif	($arg =~ /force2dWP/i)		{	our $force2dWP = 1;		}
}

#remember selection mode
if		(lxq("select.typeFrom {vertex;edge;polygon;item} ?"))		{	our $type = "vertex";	}
elsif	(lxq("select.typeFrom {edge;polygon;item;vertex} ?"))		{	our $type = "edge";		}
elsif	(lxq("select.typeFrom {polygon;item;vertex;edge} ?")) 		{	our $type = "polygon";	}
elsif	(lxq("select.typeFrom {ptag;vertex;edge;polygon;item} ?"))	{	our $type = "ptag";		}
elsif	(lxq("select.typeFrom {item;vertex;edge;polygon;ptag} ?"))	{	our $type = "item";		}

my $mainlayer = lxq("query layerservice layers ? main");
if ($mainlayer eq ""){  #temp hack to get mainlayer query to work when nothing's selected.  it's not hiding obstructions of course.
	lx("select.type item");
	lx("select.3DElementUnderMouse add");
	my @currentSelection = lxq("query sceneservice selection ? all");
	my $type = lxq("query sceneservice item.type ? $currentSelection[-1]");
	if ($type eq "mesh"){   #basically cancel script if mouse is not over a mesh. :(
		$mainlayer = lxq("query layerservice layers ? main");
	}elsif ($justGoTo == 1){
		lx("viewport.goto");
		return;
	}else{
		die("The mouse is over a ($type) and unfortunately I can't query where that point in space is and so I'm cancelling the script");
	}
}
my $mainlayerID = lxq("query layerservice layer.id ? {$mainlayer}");
if (lxq("query sceneservice item.isSelected ? $mainlayerID") == 0){lx("select.subItem {$mainlayerID} add mesh;triSurf;meshInst;camera;light;backdrop;groupLocator;replicator;locator;deform;locdeform;chanModify;chanEffect 0 0");}
my @selectedItems = lxq("query sceneservice selection ? all");

my @WPmem;
#backup the old workplane.
@WPmem[0] = lxq("workPlane.edit cenX:? ");
@WPmem[1] = lxq("workPlane.edit cenY:? ");
@WPmem[2] = lxq("workPlane.edit cenZ:? ");
@WPmem[3] = lxq("workPlane.edit rotX:? ");
@WPmem[4] = lxq("workPlane.edit rotY:? ");
@WPmem[5] = lxq("workPlane.edit rotZ:? ");

#[[--------------------------------------------------------------------------------------]]
#USE THE SCREEN FOR THE WORKPLANE
#[[--------------------------------------------------------------------------------------]]
#force the mainlayer to be visible
if ($gotoElem == 0){
	our @verifyMainlayerVisibilityList = verifyMainlayerVisibility();	#to collect hidden parents and show them
	lx("select.type item");
	#select the item under the mouse, and hide any obstructions that might have been in the way as well.
	&hideObstructions2();
	our @selectedItemsAfter = lxq("query sceneservice selection ? all");
	our $layerName = lxq("query layerservice layer.name ? {$mainlayerID}"); #refresh mainlayer name so the vert queries will work.
}


#hijacking script!  this will set workplane to poly under mouse.
if ($setPolyWP == 1){
	lx("select.type polygon");
	my $polyCountBefore = lxq("select.count polygon ?");
	if ($polyCountBefore > 0){	lx("select.editSet senetemp add");	}
	lx("select.3DElementUnderMouse set");

	lx("workplane.fitSelect");
	@WPmem[0] = lxq("workPlane.edit cenX:?");
	@WPmem[1] = lxq("workPlane.edit cenY:?");
	@WPmem[2] = lxq("workPlane.edit cenZ:?");
	@WPmem[3] = lxq("workPlane.edit rotX:?");
	@WPmem[4] = lxq("workPlane.edit rotY:?");
	@WPmem[5] = lxq("workPlane.edit rotZ:?");
	if ($force2dWP != 1) {lx("workplane.reset");}
	lx("!!workPlane.edit cenX:{$WPmem[0]} cenY:{$WPmem[1]} cenZ:{$WPmem[2]} rotX:{$WPmem[3]} rotY:{$WPmem[4]} rotZ:{$WPmem[5]}");

	lx("select.3DElementUnderMouse remove");
	lx("viewport.goto");
	if ($polyCountBefore != 0){	lx("select.useSet senetemp select"); lx("select.editSet senetemp remove"); }

	if ($hijackLayerVis == 1){lx("layer.setVisibility item:$mainlayerID visible:0");}
	&showObstructions();
	verifyMainlayerVisibility(\@verifyMainlayerVisibilityList);		#to hide the hidden parents (and mainlayer) again.

	if (@selectedItemsAfter > @selectedItems){
		my @removeLayers = removeListFromArray (\@selectedItemsAfter,\@selectedItems);
		lx("select.subItem [@removeLayers[0]] remove mesh;meshInst;camera;light;backdrop;groupLocator;locator;deform;locdeform 0 0");
	}

	lx("select.type {$type}");
	return;
}

#set the workplane to the pos of the last selected element
if ($gotoElem == 1){
	#lxout("[->] : centering on where the last selected geometry is");
	our @pos;
	if ($type eq "vertex"){
		my @verts = lxq("query layerservice selection ? vert") || die("You don't have any VERTS selected so I'm killing the script");
		my @vertInfo = split (/[^0-9]/, @verts[-1]);
		my $layername = lxq("query layerservice layer.name ? @vertInfo[1]");
		@pos = lxq("query layerservice vert.pos ? {@vertInfo[2]}");
	}elsif ($type eq "edge"){
		my @edges = lxq("query layerservice selection ? edge") || die("You don't have any EDGES selected so I'm killing the script");
		my @edgeInfo = split (/[^0-9]/, @edges[-1]);
		my $layerName = lxq("query layerservice layer.name ? @edgeInfo[1]");
		@pos = lxq("query layerservice edge.pos ? (@edgeInfo[2],@edgeInfo[3])");
	}elsif ($type eq "polygon"){
		my @polys = lxq("query layerservice selection ? poly") || die("You don't have any POLYS selected so I'm killing the script");
		my @polyInfo = split (/[^0-9]/, @polys[-1]);
		my $layername = lxq("query layerservice layer.name ? @polyInfo[1]");
		@pos = lxq("query layerservice poly.pos ? @polyInfo[2]");
	}else{
		die("\n.\n[---------------------------------------------You're not in vert, edge, or polygon mode.--------------------------------------------]\n[--PLEASE TURN OFF THIS WARNING WINDOW by clicking on the (In the future) button and choose (Hide Message)--] \n[-----------------------------------This window is not supposed to come up, but I can't control that.---------------------------]\n.\n");
	}
}


#set the workplane to the mouse pos (using workplane.fitGeometry)
elsif ($justGoTo == 0){
	#lxout("[->] : centering on where the mouse is");
	lx("workplane.fitGeometry");
	our @pos;
	@pos[0] = lxq ("workPlane.edit cenX:? ");
	@pos[1] = lxq ("workPlane.edit cenY:? ");
	@pos[2] = lxq ("workPlane.edit cenZ:? ");
}
#viewport goto, deselect layer, put selection back.
lx("select.type $type");
if (($dontMove == 0)&&($gotoElem == 0)){
	my $wire = 0;
	if (lxq("view3d.shadingStyle ?") eq "wire"){
		lx("!!view3d.shadingStyle shade");
		$wire = 1;
	}
	lx("viewport.goto");
	if ($wire == 1){
		lx("!!view3d.shadingStyle wire");
	}
}
#lxout("selectedItems = @selectedItems\nselectedItemsAfter = @selectedItemsAfter");
if (@selectedItemsAfter > @selectedItems){
	my @removeLayers = removeListFromArray (\@selectedItemsAfter,\@selectedItems);
	#lxout("removeLayers[0] = @removeLayers[0]");
	lx("select.subItem [@removeLayers[0]] remove mesh;meshInst;camera;light;backdrop;groupLocator;locator;deform;locdeform 0 0");
}
#set the workplane
if ($justGoTo == 0){
	#lxout("pos = @pos");
	lx("workplane.reset");

	#only use the axis the user is looking towards if he asked that.
	if ($onedimension == 1){
		my $viewport = lxq("query view3dservice mouse.view ?");
		my @axis = lxq("query view3dservice view.axis ? $viewport");
		my @xAxis = (1,0,0);
		my @yAxis = (0,1,0);
		my @zAxis = (0,0,1);
		my $dp0 = dotProduct(\@axis,\@xAxis);
		my $dp1 = dotProduct(\@axis,\@yAxis);
		my $dp2 = dotProduct(\@axis,\@zAxis);
		if 		((abs($dp0) >= abs($dp1)) && (abs($dp0) >= abs($dp2)))	{	@pos[1]=0; @pos[2]=0;}	#lxout("[->] : Using world X axis");}
		elsif	((abs($dp1) >= abs($dp0)) && (abs($dp1) >= abs($dp2)))	{	@pos[0]=0; @pos[2]=0;}	#lxout("[->] : Using world Y axis");}
		else															{	@pos[0]=0; @pos[1]=0;}	#lxout("[->] : Using world Z axis");}
	}

	if ($force2dWP == 1){lx("workplane.fitView");}
	lx("workPlane.edit {@pos[0]} {@pos[1]} {@pos[2]} {@WPmem[3]} {@WPmem[4]} {@WPmem[5]}");
}

if ($gotoElem == 0){
	#restore the mainlayer visibility if I had to hijack it to get around the modo bug
	if ($hijackLayerVis == 1){lx("layer.setVisibility item:$mainlayerID visible:0");}
	#show all backdrops and whatnot that would get in the way.
	&showObstructions();
	#restore visibility of the mainlayer related items
	verifyMainlayerVisibility(\@verifyMainlayerVisibilityList);		#to hide the hidden parents (and mainlayer) again.
}






#=====================================================================================================================================
#=====================================================================================================================================
#=====================================================================================================================================
#=====================================================================================================================================
#===																	 SUBROUTINES																	====
#=====================================================================================================================================
#=====================================================================================================================================
#=====================================================================================================================================
#=====================================================================================================================================


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
#HIDE THE OBSTRUCTIONS SUB(lights,backdrop items,etc) <version 2>
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
sub hideObstructions2{
	our @hidItems;
	my @hideTypes = ("backdrop","light","camera","meshInst","txtrLocator");
	my $selectFail = 0;

	lx("select.3DElementUnderMouse add");
	my @currentSelection = lxq("query sceneservice selection ? all");
	my $lastSelectedType = lxq("query sceneservice item.type ? {@currentSelection[-1]}");
	foreach my $type (@hideTypes){
		if ($lastSelectedType eq $type){
			my $id = lxq("query sceneservice item.id ? {@currentSelection[-1]}");
			lx("select.subItem {$id} remove mesh;meshInst;camera;light;backdrop;groupLocator;locator;deform;locdeform 0 0");
			lx("layer.setVisibility ${id} 0");
			push(@hidItems,$id);
			$selectFail = 1;
			last;
		}
	}

	if ($selectFail == 1){
		&hideObstructions2;
	}
}


#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#SHOW THE OBSTRUCTIONS SUB(lights,backdrop items,etc)
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
sub showObstructions{
	if (@hidItems > 0){foreach my $id (@hidItems){lx("!!layer.setVisibility $id 1");}}
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
			#lxout("[->] : showing $mainlayerID");
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