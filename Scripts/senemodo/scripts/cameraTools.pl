#perl
#ver 0.13
#author : Seneca Menard

#script cvars :
#"moveCamToPlayerHeight" : hold mouse over poly and it'll move the camera up 90 units above that point.  handy when making levels so you can set the camera height to be the correct heigh above the plane your mouse is over.

#(2-9-12 fix) : fixed number cvar check.
#(2-9-12 feature) : i'm querying the position the mouse is under with workplane.fitgeometry and that doesn't work on wireframe geometry and so i'm setting the viewport to not be wireframe temporarily and putting it back.
#(8-20-14 feature) : adjustFov : this brings up a channel haul tool to let you mess with the zoom amount.  unfortunately you can't type in an fov with it because fov isn't a channel.

#script cvars
foreach my $arg (@ARGV){
	if		($arg eq "moveCamToPlayerHeight")	{	moveCamToPlayerHeight();	}
	elsif	($arg eq "adjustFov")				{	adjustFov();				}
	elsif	($arg =~ /^[.0-9]+$/)				{	our $number = $arg;			}
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#ADJUST FOV
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#in camera view, brings up a channel haul tool with teh fov channel selected.
sub adjustFov{
	lx("!!select.itemType polyRender");
	my $cameraID = lxq("render.camera ?");
	lx("select.subItem {$cameraID} set mesh;camera;light;backdrop;groupLocator;replicator;surfGen;locator;deform;locdeform;deformGroup;deformMDD2;morphDeform;itemInfluence;genInfluence;softDeform;ABCdeform.sample;chanModify;chanEffect 0 0");
	lx("select.channel {$cameraID:focalLen} set");
	lx("select.channel {$cameraID:target} add");
	lx("tool.set channel.haul on");
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#MOVE CAMERA TO PLAYER HEIGHT
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#(hold mouse over ground poly and run script and it'll move cam 90 units above that point)
sub moveCamToPlayerHeight{
	my @WPmem;
	$WPmem[0] = lxq("workPlane.edit cenX:?");
	$WPmem[1] = lxq("workPlane.edit cenY:?");
	$WPmem[2] = lxq("workPlane.edit cenZ:?");
	$WPmem[3] = lxq("workPlane.edit rotX:?");
	$WPmem[4] = lxq("workPlane.edit rotY:?");
	$WPmem[5] = lxq("workPlane.edit rotZ:?");

	#set up safety viewport properties first
	lx("select.viewport fromMouse:1");
	my $shadingMode = 				lxq("view3d.shadingStyle ?");
	my $bgShadeMode = 				lxq("viewport.3dView background:?");
	if ($shadingMode eq "wire")	{	lx("view3d.shadingStyle shade");		}
	if ($bgShadeMode eq "wire")	{	lx("viewport.3dView background:flat");	}

	lx("workPlane.fitGeometry");

	my $WPmem2 = lxq("workPlane.edit cenY:?");

	my $cameraID = lxq("render.camera ?");
	if ($number == 0){$number = 90;}
	my $posY = $WPmem2 + $number;
	lx("transform.channel item:{$cameraID} name:pos.Y value:{$posY}");

	if (($WPmem[0] == 0) && ($WPmem[1] == 0) && ($WPmem[2] == 0) && ($WPmem[3] == 0) && ($WPmem[4] == 0) && ($WPmem[5] == 0)){
		lx("!!workplane.reset");
	}else{
		lx("!!workPlane.edit cenX:{$WPmem[0]}");
		lx("!!workPlane.edit cenY:{$WPmem[1]}");
		lx("!!workPlane.edit cenZ:{$WPmem[2]}");
		lx("!!workPlane.edit rotX:{$WPmem[3]}");
		lx("!!workPlane.edit rotY:{$WPmem[4]}");
		lx("!!workPlane.edit rotZ:{$WPmem[5]}");
	}

	#restore viewport properties
	if ($shadingMode eq "wire")	{	lx("view3d.shadingStyle wire");			}
	if ($bgShadeMode eq "wire")	{	lx("viewport.3dView background:wire");	}
}