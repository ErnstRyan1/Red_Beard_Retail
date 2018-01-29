#perl
#ver 1.2
#author : Seneca Menard

#This script is to scale your selection from the viewport position.  It's so you can have an object keep it's EXACT silhouette but move where it is in depth.  Very damn handy when placing silhouettes..

#(10-12-11 bugfix) : script now works if your layer is selected but not visible.
#(10-12-11 bugfix) : turns off workplane.
#(2-19-13 feature) : supports the camera view as well as the perspective view now.

#get mainlayer
my $mainlayer = lxq("query layerservice layers ? main");
my $mainlayerID = lxq("query layerservice layer.id ? {$mainlayer}");
my $viewportType = lxq("view3d.projection type:?");
my @cameraPos;

#turn off workplane
lx("!!workplane.reset");

#backup selection mode.
if		( lxq( "select.typeFrom {vertex;edge;polygon;item} ?" ) ){	our $selMode = "vertex";	}
elsif	( lxq( "select.typeFrom {edge;polygon;item;vertex} ?" ) ){	our $selMode = "edge";		}
elsif	( lxq( "select.typeFrom {polygon;item;vertex;edge} ?" ) ){	our $selMode = "polygon";	}
else	{die("\\\\n.\\\\n[---------------------------------------------You're not in vert, edge, or polygon mode.--------------------------------------------]\\\\n[--PLEASE TURN OFF THIS WARNING WINDOW by clicking on the (In the future) button and choose (Hide Message)--] \\\\n[-----------------------------------This window is not supposed to come up, but I can't control that.---------------------------]\\\\n.\\\\n");}

#query view center : (perspective view)
if ($viewportType eq "psp"){
	lx("!!item.create camera");
	my @cameraIDs = lxq("query sceneservice selection ? camera");
	lx("!!camera.syncView");
	@cameraPos = lxq("query sceneservice item.pos ? {$cameraIDs[0]}");
	lx("!!item.delete mask:camera");
}
#query view center : (camera view)
elsif ($viewportType eq "cam"){
	my $viewport = lxq("query view3dservice mouse.view ?");
	@cameraPos = lxq("query view3dservice view.center ? {$viewport}");
}
#query view center : (failed)
else{
	die("the current viewport is not a perspective view or camera view and so I'm cancelling the script.");
}

#set pivot pos and turn on scale tool
m3PivPos(set,$mainlayerID,$cameraPos[0],$cameraPos[1],$cameraPos[2]);
lx("!!tool.set xfrm.scale on");
lx("!!tool.set center.pivot on");
lx("!!tool.set axis.auto on");

#restore selection mode
lx("!!select.type {$selMode}");


















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
	lxout("pivotID = $pivotID");
	lxout("$_[2] <> $_[3] <> $_[4]");
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

