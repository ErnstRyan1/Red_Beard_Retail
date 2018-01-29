#perl
#AUTHOR: Seneca Menard
#version 1.27 (modo2)
#-This script rests your geometry on the ground.

#- There is also a "center" option if you want to center your geometry as well.  To use "center", just append it to the end of the script:
#- example:@restOnGround.pl center

#(12-18-06 fix) : It now works properly no matter what ACTR you're in.
#(12-18-08 fix) : I went and removed the square brackets so that the numbers will always be read as metric units and also because my prior safety check would leave the unit system set to metric system if the script was canceled because changing that preference doesn't get undone if a script is cancelled.
#(1-10-14 fix) : got the actr storage system up to date with 601

my $mainlayer = lxq("query layerservice layers ? main");
my @bbox;
my $selectMode;

#-----------------------------------------------------------------------------------
#SAFETY CHECKS
#-----------------------------------------------------------------------------------
#make sure all of the object is selected
lx("!!select.connect");

#Turn off and protect Symmetry (MODO2 FIX)
my $symmAxis = lxq("select.symmetryState ?");
if ($symmAxis ne "none")	{lx("select.symmetryState none");}

#Remember what the workplane was and turn it off (M2safe)
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
#STORE SELECTION AND CONVERT TO VERTS (M2safe)
#-----------------------------------------------------------------------------------
if( lxq( "select.typeFrom {polygon;item;vertex;edge} ?" ) )
{
	if (lxq("select.count polygon ?") eq 0)
	{
		lxout("no polygons are selected");
		lx("select.invert");
	}
	lx("select.convert vertex");
	$selectMode = polygon;
}
elsif( lxq( "select.typeFrom {edge;polygon;item;vertex} ?" ) )
{
	if (lxq("select.count polygon ?") eq 0)
	{
		lxout("no edges are selected");
		lx("select.invert");
	}
	lx("select.convert vertex");
	$selectMode = edge;
}
elsif( lxq( "select.typeFrom {vertex;edge;polygon;item} ?" ) )
{
	if (lxq("select.count vertex ?") eq 0)
	{
		lxout("no verts are selected");
		lx("select.invert");
	}
	$selectMode = vertex;
}
elsif( lxq( "select.typeFrom {item;vertex;edge;polygon} ?" ) )
{
	lx("select.convert vertex");
	$selectMode = item;
}



#-----------------------------------------------------------------------------------
#SEND SELECTED VERTS to subroutine to get BBox and then MOVE
#-----------------------------------------------------------------------------------
my @selectedVerts = lxq("query layerservice verts ? selected");
@bbox = boundingbox(@selectedVerts);
#lxout("bounding box = [-X]=@bbox[0],[-Y]=@bbox[1],[-Z]=@bbox[2],[X]=@bbox[3],[Y]=@bbox[4],[Z]=bbox[5]"); #
my $dist = (@bbox[1] * -1);

#MOVE TO GROUND
lx("tool.set xfrm.move on");
lx("tool.setAttr axis.auto upY {1}");

lx("tool.setAttr xfrm.move X {0}");
lx("tool.setAttr xfrm.move Y {$dist}");
lx("tool.setAttr xfrm.move Z {0}");

lx("tool.doApply");
lx("tool.set xfrm.move off");

#IF CENTER variable is on
if (@ARGV[0] eq "center")
{
	lxout("[->] USING the CENTER feature");
	lx("vert.center x");
	lx("vert.center z");
}


#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#--------------------------------------------SUBROUTINES---------------------------------------
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
sub popup() #(MODO2 FIX)
{
	lx("dialog.setup yesNo");
	lx("dialog.msg {@_}");
	lx("dialog.open");
	my $confirm = lxq("dialog.result ?");
	if($confirm eq "no"){die;}
}



sub boundingbox #[-------MODDED-------]
{
	lxout("[->] USING the boundingbox subroutine");
	my @bbVerts = @_;
	my $firstVert = @bbVerts[0];
	my @firstVertPos = lxq("query layerservice vert.pos ? $firstVert");
	my $minX = @firstVertPos[0];
	my $minY = @firstVertPos[1];
	my $minZ = @firstVertPos[2];
	my $maxX = @firstVertPos[0];
	my $maxY = @firstVertPos[1];
	my $maxZ = @firstVertPos[2];
	my @bbVertPos;

	#progress meter
	#lxmonInit(@bbVerts);

	foreach my $bbVert(@bbVerts)
	{
		@bbVertPos = lxq("query layerservice vert.pos ? $bbVert");
		#minY
		if (@bbVertPos[1] < $minY)
		{
			$minY = @bbVertPos[1];
		}
		#maxY
		if (@bbVertPos[1] > $maxY)
		{
			$maxY = @bbVertPos[1];
		}
	}
	my @bbox = ($minX,$minY,$minZ,$maxX,$maxY,$maxZ);
	return @bbox;
}


#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#------------[SCRIPT IS FINISHED] SAFETY REIMPLEMENTING-----------------
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#Put ACTR / selection / symmetry mode / workplane / unit mode back
#Put ACTR back
if ($actr == 1) { lx( "tool.set {$seltype} on" ); }
else { lx("tool.set center.$selCenter on"); lx("tool.set axis.$selAxis on"); }

lx("select.type $selectMode");
if ($symmAxis ne "none")	{lx("select.symmetryState $symmAxis");}
lx("workPlane.edit {@WPmem[0]} {@WPmem[1]} {@WPmem[2]} {@WPmem[3]} {@WPmem[4]} {@WPmem[5]}");

