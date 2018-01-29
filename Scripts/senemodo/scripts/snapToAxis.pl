#perl
#author : Seneca Menard
#ver 1.7
#This script is to snap the selected verts to the grid on the axis you choose.  Just type in the axis you want after the scriptname in the hotkeys.  For example, "@snapToAxis.pl X"
#It can also do 1D, 2D, or 3D snaps if you want, using the axis the current viewport is looking towards the most.  So if you're looking down the Z axis and fire "1D", it'll snap the verts to the Z, if you fire "2D", it'll snap the verts to the two complimentary axes, ie X and Y.  If you fire "3D" it'll snap to all three axes.
#(7-11-08 fix) : fixed a small bug with negative rounding
#(8-1-08 feature) : Added 1D, 2D, or 3D snapping : It snaps the geometry using the axis the current viewport is looking towards the most.  So if you're looking down the Z axis and fire "1D", it'll snap the verts to the Z, if you fire "2D", it'll snap the verts to the two complimentary axes, ie X and Y.  If you fire "3D" it'll snap to all three axes.
#(3-15-15 fix) : I found out that with unreal, we have to scale our meshes to 1% of their original size because unreal imports 'em 100% bigger than it's supposed to.  So then you have to change your METERS PER UNIT option in the prefs to get modo to match that and that was breaking this script because it wasn't paying attention to that.
#(3-17-15 feature) : the script can now quantize item positions. just be in item mode and run the script same as usual.

#check whether to run the script or not.
if		(lxq( "select.typeFrom {vertex;edge;polygon;item} ?" ) == 1)	{our $selType = "vertex";									}
elsif	(lxq( "select.typeFrom {edge;polygon;item;vertex} ?" ) == 1)	{our $selType = "edge";		lx("select.convert vertex");	}
elsif	(lxq( "select.typeFrom {polygon;item;vertex;edge} ?" ) == 1)	{our $selType = "polygon";	lx("select.convert vertex");	}
elsif	(lxq( "select.typeFrom {item;vertex;edge;polygon} ?" ) == 1)	{our $selType = "item";										}
else{die("\\\\n.\\\\n[---------------------------------------------You're not in vert, edge, polygon or item mode.--------------------------------------------]\\\\n[--PLEASE TURN OFF THIS WARNING WINDOW by clicking on the (In the future) button and choose (Hide Message)--] \\\\n[-----------------------------------This window is not supposed to come up, but I can't control that.---------------------------]\\\\n.\\\\n");}


lxout("sdf");

#=====================================================================================================================================
#===															SETUP			    											  ====
#=====================================================================================================================================

#setup
my $mainlayer = lxq("query layerservice layers ? main");
my @axisSetup;
my @vertPos = (0,0,0);
my @newVertPos = (0,0,0);
my $primaryAxis;
my $gridDiv = lxq("pref.value units.gameScale ?");
my $gridMult = 1/$gridDiv;

if (lxq("pref.value units.system ?") eq "game")	{	our $power = 2;	}
else											{	our $power = 10;}

#find grid size
my $view = lxq("query view3dservice mouse.view ?");
my @axis = lxq("query view3dservice view.axis ? $view");
my @frame = lxq("query view3dservice view.frame ?");
my $scale = lxq("query view3dservice view.scale ? $view");
my @viewBbox = lxq("query view3dservice view.rect ? $view");
my @viewScale = (($scale * @viewBbox[2]),($scale * $viewBbox[3]));
my @div = ((@viewScale[0]/16),(@viewScale[1]/16));
my $log = int(.55 + (log(@div[0])/log($power)));
my $grid = $power ** $log;

#find primary axis
my @xAxis = (1,0,0);
my @yAxis = (0,1,0);
my @zAxis = (0,0,1);
my $dp0 = dotProduct(\@axis,\@xAxis);
my $dp1 = dotProduct(\@axis,\@yAxis);
my $dp2 = dotProduct(\@axis,\@zAxis);
if 		((abs($dp0) >= abs($dp1)) && (abs($dp0) >= abs($dp2)))	{	$primaryAxis = 0;	lxout("[->] : Using world X axis");}
elsif	((abs($dp1) >= abs($dp0)) && (abs($dp1) >= abs($dp2)))	{	$primaryAxis = 1;	lxout("[->] : Using world Y axis");}
else															{	$primaryAxis = 2;	lxout("[->] : Using world Z axis");}

#determine which axes to move the verts on.
if (@ARGV[0] =~ /d/i){
	if 		(@ARGV[0] =~ /1d/i)	{@axisSetup = (0,0,0);		$axisSetup[$primaryAxis] = 1;	}
	elsif	(@ARGV[0] =~ /2d/i)	{@axisSetup = (1,1,1);		$axisSetup[$primaryAxis] = 0;	}
	elsif	(@ARGV[0] =~ /3d/i)	{@axisSetup = (1,1,1);										}
	else	{die("You must type in a '1D', '2D', '3D', or 'X', 'Y', 'Z' for me to know which axes you want to snap the verts to the grid on");}
}else{
	if 		(@ARGV[0] =~ /x/i)	{@axisSetup = (1,0,0);}
	elsif 	(@ARGV[0] =~ /y/i)	{@axisSetup = (0,1,0);}
	elsif 	(@ARGV[0] =~ /z/i)	{@axisSetup = (0,0,1);}
	else	{die("You must type in a '1D', '2D', '3D', or 'X', 'Y', 'Z' for me to know which axes you want to snap the verts to the grid on");}
}


#=====================================================================================================================================
#===													RUN SUBROUTINES			    											  ====
#=====================================================================================================================================
if ($selType eq "item")	{	itemSnap();	}
else					{	elemSnap();	}


#=====================================================================================================================================
#===													ITEM SNAP SUB			    											  ====
#=====================================================================================================================================
sub itemSnap{ 
	#build list of snappable item types
	my %itemTypes;
		$itemTypes{"mesh"} = 1;
		$itemTypes{"meshInst"} = 1;
		$itemTypes{"triSurf"} = 1;
		$itemTypes{"groupLocator"} = 1;
		$itemTypes{"locator"} = 1;
		$itemTypes{"camera"} = 1;
		$itemTypes{"sunLight"} = 1;
		$itemTypes{"pointLight"} = 1;
		$itemTypes{"spotLight"} = 1;
		$itemTypes{"photometryLight"} = 1;
		$itemTypes{"domeLight"} = 1;
		$itemTypes{"cylinderLight"} = 1;
		$itemTypes{"areaLight"} = 1;
		
	#round item positions
	my @selection = lxq("query sceneservice selection ? locator");
	foreach my $item (@selection){
		my $type = lxq("query sceneservice item.type ? $item");
		if ($itemTypes{$type} == 1){
			my $posX = lxq("item.channel pos.X [?] set {$item}");
			my $posY = lxq("item.channel pos.Y [?] set {$item}");
			my $posZ = lxq("item.channel pos.Z [?] set {$item}");
			
			if ($axisSetup[0] == 1)	{	
				$posX = roundNumber($posX,$grid);
				lx("!!item.channel pos.X [$posX] set {$item}");	
			}
			if ($axisSetup[1] == 1)	{	
				$posY = roundNumber($posY,$grid);
				lx("!!item.channel pos.Y [$posY] set {$item}");	
			}
			if ($axisSetup[2] == 1)	{	
				$posZ = roundNumber($posZ,$grid);
				lx("!!item.channel pos.Z [$posZ] set {$item}");	
			}
		}
	}
}


#=====================================================================================================================================
#===													ELEM SNAP SUB			    											  ====
#=====================================================================================================================================
sub elemSnap{

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


	#move the verts
	my @verts = lxq("query layerservice verts ? selected");
	foreach my $vert (@verts){
		@vertPos = lxq("query layerservice vert.pos ? $vert");

		for (my $i=0; $i<@newVertPos; $i++){
			if ($axisSetup[$i] == 1){
				#ignore the METERS PER GAME UNIT OPTION if it's set to it's default value
				if ($gridMult == 1){
					my $div = $vertPos[$i] / $grid;
					$newVertPos[$i] = int(0.5 + abs($div)) * $grid;
				}
				#or use the METERS PER GAME UNIT OPTION if it is being used
				else{
					my $div = $vertPos[$i] * $gridMult / $grid;
					$newVertPos[$i] = int(0.5 + abs($div)) * $grid * $gridDiv;
				}
				
				if ($vertPos[$i] < 0){$newVertPos[$i] *= -1;}
			}else{
				$newVertPos[$i] = $vertPos[$i];
			}
		}

		lx("vert.move vertIndex:$vert posX:{$newVertPos[0]} posY:{$newVertPos[1]} posZ:{$newVertPos[2]}");
	}

	#cleanup
	lx("select.type $selType");
	#uses the new tool preset-------------------------------------------
	if ($tool ne "none"){
		lx("tool.set $tool on");
		if (($modoVer < 300) && ($tool eq "TransformMove")){
			lx("tool.attr xfrm.transform H translate");
		}
	}
	#------------------------------------------------------------------------------
}






#=====================================================================================================================================
#=====================================================================================================================================
#=====================================================================================================================================
#=====================================================================================================================================
#===														SUBROUTINES			    											  ====
#=====================================================================================================================================
#=====================================================================================================================================
#=====================================================================================================================================
#=====================================================================================================================================

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

