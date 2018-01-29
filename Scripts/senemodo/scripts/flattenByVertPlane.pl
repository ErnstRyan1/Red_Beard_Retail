#perl
#ver 1.31
#author : Seneca Menard

#This script will flatten your current poly selection onto the arbitrary axis you defined with the 3 points you have selected.

#(1-10-14 fix) : got the actr storage system up to date with 601

#-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#SETUP
#-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
my $mainlayer = lxq("query layerservice layers ? main");
my $selectionOverride = 0;
lx("!!tool.makePreset name:tool.previous");

#Remember what the workplane was and turn it off
my @WPmem;
@WPmem[0] = lxq ("workPlane.edit cenX:? ");
@WPmem[1] = lxq ("workPlane.edit cenY:? ");
@WPmem[2] = lxq ("workPlane.edit cenZ:? ");
@WPmem[3] = lxq ("workPlane.edit rotX:? ");
@WPmem[4] = lxq ("workPlane.edit rotY:? ");
@WPmem[5] = lxq ("workPlane.edit rotZ:? ");
lx("workPlane.reset");


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



#-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#LEARN AXIS
#-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#VERTS
if		( lxq( "select.typeFrom {vertex;edge;polygon;item} ?" ) )	{
	our $selType = "vertex";
	our @verts = lxq("query layerservice verts ? selected");
	our @vertPlaneMatrix;
	if ((lxq("select.symmetryState ?") ne "none") && (@verts > 5))	{@vertPlaneMatrix = getVertPlaneMatrix(@verts[0],@verts[2],@verts[4]);	}
	else															{@vertPlaneMatrix = getVertPlaneMatrix(@verts);							}
}
#EDGES
elsif	( lxq( "select.typeFrom {edge;polygon;item;vertex} ?" ) )	{
	our $selType = "edge";
	if (lxq("select.count edge ?") > 1){
		lx("select.convert vertex");
		our @verts = lxq("query layerservice verts ? selected");
		our @vertPlaneMatrix = getVertPlaneMatrix(@verts);
	}else{
		die("You don't have more than 1 edge selected, so I can't define the plane you wish to flatten the geometry to");
	}
}
#POLYS
elsif	( lxq( "select.typeFrom {polygon;item;vertex;edge} ?" ) )	{
	our $selType = "polygon";
	my $view = lxq("query view3dservice mouse.view ?");
	my $poly = lxq("query view3dservice element.over ? POLY");
	if ($poly eq ""){die("Your mouse was not over a poly, (which defines the plane in which to flatten the other selected polys) and so I'm cancelling the script.");}
	my @polySplit = split(/,/, $poly);
	$poly = @polySplit[1];

	my @y = lxq("query layerservice poly.normal ? $poly");
	my @x = (1,0,0); if (abs(@y[0]) > .8){@x = (0,1,0);}
	my @z = unitVector(crossProduct(\@y,\@x));
	my @x = unitVector(crossProduct(\@y,\@z));
	my @center = lxq("query layerservice poly.pos ? $poly");
	our @vertPlaneMatrix = (@x,@y,@z,@center);
}
#ELSE
else															{die("\\\\n.\\\\n[---------------------------------------------You're not in vert, edge, or polygon mode.--------------------------------------------]\\\\n[--PLEASE TURN OFF THIS WARNING WINDOW by clicking on the (In the future) button and choose (Hide Message)--] \\\\n[-----------------------------------This window is not supposed to come up, but I can't control that.---------------------------]\\\\n.\\\\n");}
if (lxq("select.count polygon ?") > 0){lx("select.type polygon");}
else{
	my $view = lxq("query view3dservice mouse.view ?");
	lx("select.drop polygon");
	my $poly = lxq("query view3dservice element.over ? POLY");
	if ($poly ne ""){
		lx("select.3DElementUnderMouse set");
		$selectionOverride = 1;
	}
}


#-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#STRETCH
#-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
lx("tool.set actr.element on");

lx("tool.set xfrm.stretch on");
lx("tool.reset");
lx("tool.setAttr center.element cenX {@vertPlaneMatrix[9]}");
lx("tool.setAttr center.element cenY {@vertPlaneMatrix[10]}");
lx("tool.setAttr center.element cenZ {@vertPlaneMatrix[11]}");
lx("tool.setAttr axis.element axisX {@vertPlaneMatrix[0]}");
lx("tool.setAttr axis.element axisY {@vertPlaneMatrix[1]}");
lx("tool.setAttr axis.element axisZ {@vertPlaneMatrix[2]}");
lx("tool.setAttr axis.element axis {-1}");
lx("tool.setAttr axis.element upX {@vertPlaneMatrix[3]}");
lx("tool.setAttr axis.element upY {@vertPlaneMatrix[4]}");
lx("tool.setAttr axis.element upZ {@vertPlaneMatrix[5]}");
lx("tool.setAttr xfrm.stretch factX {1}");
lx("tool.setAttr xfrm.stretch factY {0}");
lx("tool.setAttr xfrm.stretch factZ {1}");
lx("tool.doApply");
lx("tool.set xfrm.stretch off");


#-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#CLEANUP
#-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
if ($selectionOverride == 1){lx("!!select.drop polygon");}
lx("select.type {$selType}");

#put the tool back
lx("!!tool.set tool.previous on");

#Set the action center settings back
if ($actr == 1) {	lx( "tool.set {$seltype} on" ); }
else { lx("tool.set center.$selCenter on"); lx("tool.set axis.$selAxis on"); }

#Put the workplane back
lx("workPlane.edit {@WPmem[0]} {@WPmem[1]} {@WPmem[2]} {@WPmem[3]} {@WPmem[4]} {@WPmem[5]}");


















#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#GET VERT PLANE MATRIX SUB (3 verts in, 3 vectors and 1 center out) (note, Y needs to be determined if it should be flipped or not by checking the poly normals.  this script doesn't need that and that's why it's not there yet)
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE : getVertPlaneMatrix($layerIndex,@verts);
sub getVertPlaneMatrix{
	if (@_ < 3){die("At least 3 verts must be specified in order for the subroutine that defines a plane from 3 verts to work");}
	my $currentlyQueriedLayer = lxq("query layerservice layer.index ?");
	my $layerName = lxq("query layerservice layer.name ? $layerIndex");
	my @pos1 = lxq("query layerservice vert.pos ? @_[0]");
	my @pos2 = lxq("query layerservice vert.pos ? @_[1]");
	my @pos3 = lxq("query layerservice vert.pos ? @_[2]");

	my @x = unitVector(arrMath(@pos3,@pos1,subt));
	my @z = unitVector(arrMath(@pos2,@pos1,subt));
	my @y = unitVector(crossProduct(\@x,\@z));
	   @z = unitVector(crossProduct(\@y,\@x));
	my @center = arrMath(arrMath(arrMath(@pos1,@pos2,add),@pos3,add),3,3,3,div);

	return(@x,@y,@z,@center);
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
#CROSSPRODUCT SUBROUTINE (ver 1.1)
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE : my @crossProduct = crossProduct(\@vector1,\@vector2);
sub crossProduct{
	return ( (${$_[0]}[1]*${$_[1]}[2])-(${$_[1]}[1]*${$_[0]}[2]) , (${$_[0]}[2]*${$_[1]}[0])-(${$_[1]}[2]*${$_[0]}[0]) , (${$_[0]}[0]*${$_[1]}[1])-(${$_[1]}[0]*${$_[0]}[1]) );
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