#perl
#AUTHOR: Seneca Menard
#version 1.5
#This script is to deselect polys, verts, or edge loops.
# - VERTS : This script will deselect all the verts connected to the mesh under the mouse.
# - EDGES : This script will deselect the edgeloop underneath the mouse.
# - POLYS : This script will deselect all the polys connected to the mesh under the mouse.
#(12-15-06) : The script is now much faster.

my $mainlayer = lxq("query layerservice layers ? main");

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#ARGUMENTS
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
foreach my $arg (@ARGV){
	if ($arg =~ /keepSelection/i)	{	our $keepSel = 1;	}
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#SCRIPT USAGE
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------

if( lxq( "select.typeFrom {vertex;edge;polygon;item} ?" ) == 1){
	&fastVertMode
}
elsif( lxq( "select.typeFrom {edge;polygon;item;vertex} ?" ) == 1){
	&fastEdgeMode;
}
elsif( lxq( "select.typeFrom {polygon;item;vertex;edge} ?" ) == 1){
	&uberFastWay;
}
else{
	die("\n.\n[---------------------------------------------You're not in vert, edge, or polygon mode.--------------------------------------------]\n[--PLEASE TURN OFF THIS WARNING WINDOW by clicking on the (In the future) button and choose (Hide Message)--] \n[-----------------------------------This window is not supposed to come up, but I can't control that.---------------------------]\n.\n");
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#VERT MODE
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
sub fastVertMode{
	#should it keep the poly selection?  it's slower but good.
	lx("select.editSet senDeselect add");
	lx("select.type polygon");
	if ($keepSel == 1){	lx("!!select.editSet senDeselect add");	}
	lx("select.3DElementUnderMouse set");
	if (lxq("select.count polygon ?") == 0){die("\n.\n[-----------------------------------Cancelling script because the mouse wasn't over an object-----------------------------------]\n[--PLEASE TURN OFF THIS WARNING WINDOW by clicking on the (In the future) button and choose (Hide Message)--] \n[-----------------------------------This window is not supposed to come up, but I can't control that.---------------------------]\n.\n");}

	lx("select.convert vertex");
	lx("select.connect");
	lx("!!select.editSet senDeselect remove");
	lx("select.drop vertex");
	lx("!!select.useSet senDeselect select");
	lx("!!select.editSet senDeselect remove");

	if ($keepSel == 1){
		lx("select.drop polygon");
		lx("!!select.useSet senDeselect select");
		lx("!!select.editSet senDeselect remove");
		lx("select.type vertex");
	}
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#EDGE MODE
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
sub fastEdgeMode{
	lx("select.editSet senDeselect add");
	lx("select.3DElementUnderMouse set");
	if (lxq("select.count edge ?") == 0){die("\n.\n[---------------------------You didn't have your mouse over an edge and so I couldn't deselect it's loop----------------------]\n[--PLEASE TURN OFF THIS WARNING WINDOW by clicking on the (In the future) button and choose (Hide Message)--] \n[-----------------------------------This window is not supposed to come up, but I can't control that.---------------------------]\n.\n");	}
	lx("select.loop");
	lx("select.editSet senDeselect remove");
	lx("select.drop edge");
	lx("!!select.useSet senDeselect select");
	lx("!!select.editSet senDeselect remove");
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#POLY MODE
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------

#DESELECT POLYS (selSet way)  (0.3 seconds for spheres)
sub uberFastWay{
	lx("!!select.editSet senDeselect add");
	lx("!!select.3DElementUnderMouse set");
	if (lxq("select.count polygon ?") == 0){ die("\n.\n[----------------------------------Cancelling script because the mouse wasn't over a polygon-----------------------------------]\n[--PLEASE TURN OFF THIS WARNING WINDOW by clicking on the (In the future) button and choose (Hide Message)--] \n[-----------------------------------This window is not supposed to come up, but I can't control that.---------------------------]\n.\n");}

	lx("!!select.connect");
	lx("!!select.editSet senDeselect remove");
	lx("!!select.drop polygon");
	lx("!!select.useSet senDeselect select");
	lx("!!select.editSet senDeselect remove");
}
