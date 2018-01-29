#perl
#AUTHOR: Seneca Menard
#version 1.1
#This script is for removing edge rows.  You can "define" the edge rows in a couple of different ways.  For example :
 # - if you select two verts in a row, it knows that'll be an edge row
 # - if you select some touching polys, it'll remove the edge row inbetween those polys
 # - if you have any edges selected, it'll remove the edge rows those edges are on.

#UPDATES :
#(7-7-09 bugfix) : cleaned up the really old script and also now have the script deselect border edges, so it doesn't cause any errors when it removes them.


#----------------------------------------------------------------------
#EDGE MODE : select edges and remove 'em
#----------------------------------------------------------------------
if ((lxq("select.typeFrom {edge;vertex;polygon;item} ?")) && (lxq("select.count edge ?") > 0)){
	lx("select.loop");
	lx("!!select.edge remove bond equal (none)");
	if (lxq("select.count edge ?") > 0){lx("remove" );}
}


#----------------------------------------------------------------------
#VERTEX MODE : select edges and remove 'em
#----------------------------------------------------------------------
elsif ((lxq("select.typeFrom {vertex;edge;polygon;item} ?")) && (lxq("select.count vertex ?") > 1)){
	lx("select.loop");
	lx("select.convert edge");
	lx("!!select.edge remove bond equal (none)");
	if (lxq("select.count edge ?") > 0){lx("remove" );}
	lx("select.type vertex");
}


#----------------------------------------------------------------------
#POLY MODE: select edges and remove 'em
#----------------------------------------------------------------------
elsif ((lxq("select.typeFrom {polygon;vertex;edge;item} ?")) && (lxq("select.count polygon ?") > 1)){
	lx( "select.convert edge" );
	lx( "select.contract" );
	lx( "select.edge remove poly equal 1" );
	if (lxq("select.count edge ?") == 0){
		die( "Need to select at least 2 touching polys" );
	}else{
		#lxout("before anything vertexselected = $vertexselected");
		lx("select.loop" );
		lx("!!select.edge remove bond equal (none)");
		if (lxq("select.count edge ?") > 0){lx("remove" );}
		lx( "select.type polygon");
	}
}



#subroutines
sub popup()
{
	lx("dialog.setup yesNo");
	lx("dialog.msg {@_}");
	lx("dialog.open");
}
