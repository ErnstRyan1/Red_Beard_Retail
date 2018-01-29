#perl
#ver 1.21
#author : Seneca Menard
#This script will join averaged the selection without merging their uvs.
#(5-22-08 fix) : made the script not reselect any verts if the vert merge didn't do anything.
#(5-27-08 fix) : i sped up teh script a little bit

my $mainlayer = lxq("query layerservice layers ? main");
if( lxq( "select.typeFrom {vertex;polygon;item;edge} ?" ) ) {

}elsif( lxq( "select.typeFrom {edge;vertex;polygon;item} ?" ) ) {
	lx("!!select.convert vertex") || die("You didn't have any edges or verts selected, so I'm killing the script");
}elsif( lxq( "select.typeFrom {polygon;item;vertex;edge} ?" ) ) {
	lx("!!select.convert vertex") || die("You didn't have any polys or verts selected, so I'm killing the script");
}else{
	die("\\\\n.\\\\n[---------------------------------------------You're not in vert, edge, or polygon mode.--------------------------------------------]\\\\n[--PLEASE TURN OFF THIS WARNING WINDOW by clicking on the (In the future) button and choose (Hide Message)--] \\\\n[-----------------------------------This window is not supposed to come up, but I can't control that.---------------------------]\\\\n.\\\\n");
}

my $vertCount1 = lxq("query layerservice vert.n ? all");
my @verts = lxq("query layerservice verts ? selected");
my @avgPos = (0,0,0);
foreach my $vert (@verts){
	my @pos = lxq("query layerservice vert.pos ? $vert");
	@avgPos = (@avgPos[0]+@pos[0] , @avgPos[1]+@pos[1] , @avgPos[2]+@pos[2]);
}
@avgPos = (@avgPos[0]/@verts,@avgPos[1]/@verts,@avgPos[2]/@verts);
lx("!!vert.move posX:{@avgPos[0]} posY:{@avgPos[1]} posZ:{@avgPos[2]}");
lx("!!vert.merge auto false 0.001");
my $vertCount2 = lxq("query layerservice vert.n ? all");
if ($vertCount1 != $vertCount2){
	my $vert = $vertCount2 - 1;
	lx("!!select.element $mainlayer vertex set $vert");
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
