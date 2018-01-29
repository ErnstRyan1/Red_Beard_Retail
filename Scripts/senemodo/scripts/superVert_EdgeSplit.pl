#perl
#AUTHOR: Seneca Menard
#version 1.01
#This tool is to replace the default VERT.SPLIT tool.   It's just like the regular vert.split, only that it's main feature is for splitting edge rows!
#(9-9-07) : I added a progress bar


#----------------------------------------------------------------------------------------------------------------------
#IF VERTS WERE SELECTED, UNWELD
#----------------------------------------------------------------------------------------------------------------------
if(( lxq( "select.typeFrom {vertex;edge;polygon;item} ?" ) ) || ( lxq( "select.typeFrom {polygon;item;vertex;edge} ?" ) ))
{
	lxout("SPLITTING VERTS------------------------------------------");
	lx("vert.split");
}


#----------------------------------------------------------------------------------------------------------------------
#IF EDGES WERE SELECTED, SPLIT THEM
#----------------------------------------------------------------------------------------------------------------------
elsif (lxq("select.typeFrom {edge;vertex;polygon;item} ?")){
	lx("edge.split");

}


else{die("\\\\n.\\\\n[---------------------------------------------You're not in vert, edge, or polygon mode.--------------------------------------------]\\\\n[--PLEASE TURN OFF THIS WARNING WINDOW by clicking on the (In the future) button and choose (Hide Message)--] \\\\n[-----------------------------------This window is not supposed to come up, but I can't control that.---------------------------]\\\\n.\\\\n");}

sub popup #(MODO2 FIX)
{
	lx("dialog.setup yesNo");
	lx("dialog.msg {@_}");
	lx("dialog.open");
	my $confirm = lxq("dialog.result ?");
	if($confirm eq "no"){die;}
}


