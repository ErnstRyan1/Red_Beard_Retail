#perl
#ver 1.01
#author : Seneca Menard

#This script is to tell you how big the edge length is in comparison to the layer bbox. (handy for trying to figure out a renderbump trace distance)

my $mainlayer = lxq("query layerservice layers ? main");
my @layerBBOX = lxq("query layerservice layer.bounds ? $mainlayer");
my $layerBBOX_xDist = @layerBBOX[3]-@layerBBOX[0];
my $layerBBOX_yDist = @layerBBOX[4]-@layerBBOX[1];
my $layerBBOX_zDist = @layerBBOX[5]-@layerBBOX[2];

my $maxDist = $layerBBOX_xDist;
if ($layerBBOX_yDist > $maxDist)	{$maxDist = $layerBBOX_yDist;}
if ($layerBBOX_zDist > $maxDist)	{$maxDist = $layerBBOX_zDist;}

my @edges = lxq("query layerservice edges ? selected");
my $edgeDist = lxq("query layerservice edge.length ? @edges[0]");
my $edge_BBOX_percentage = $edgeDist / $maxDist;
lxout("the edge is this size in relationship to the layer bbox : $edge_BBOX_percentage");
popup("the edge is this size in relationship to the layer bbox : $edge_BBOX_percentage");

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

