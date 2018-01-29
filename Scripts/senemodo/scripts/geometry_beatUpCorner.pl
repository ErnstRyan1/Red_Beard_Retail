#perl
#AUTHOR : Seneca Menard
#This script is for beating up concrete.  The way you use it is this :
#1) do a closed circular knife cut on concrete
#2) hold mouse over an inner edge and then run the geometry_beatUpCorner.LXM which will fire this

my $mainlayer = lxq("query layerservice layers ? main");
my @polys = lxq("query layerservice polys ? selected");
lxout("polys = @polys");
my %vertList;
foreach my $poly (@polys){
	my @verts = lxq("query layerservice poly.vertList ? $poly");
	foreach my $vert (@verts){
		$vertList{$vert} = 1;
	}
}
my @verts = (keys %vertList);
lxout("verts = @verts");
my @bbox = boundingbox(@verts);
my @bboxCenter = (.5 * (@bbox[0]+@bbox[3]) , .5 * (@bbox[1]+@bbox[4]) , .5 * (@bbox[2]+@bbox[5]));
lxout("bbox = @bbox");
lxout("bboxCenter = @bboxCenter");

lx("tool.set center.auto on");
lx("tool.set axis.auto on");

lx("tool.set *.bevel on");
lx("tool.attr poly.bevel group 1");
lx("tool.setAttr poly.bevel shift 0.0");
lx("tool.setAttr poly.bevel inset 0.0");
lx("tool.doApply");

lx("tool.set xfrm.scale on");
lx("tool.setAttr xfrm.scale factor [60.0 %]");
lx("tool.setAttr center.auto cenX @bboxCenter[0]");
lx("tool.setAttr center.auto cenY @bboxCenter[1]");
lx("tool.setAttr center.auto cenZ @bboxCenter[2]");
lx("tool.doApply");

lx("tool.set xfrm.smooth on");
lx("tool.setAttr xfrm.smooth strn [1.0]");
lx("tool.setAttr xfrm.smooth iter 27");
lx("tool.doApply");

lx("tool.set xfrm.jitter on");
lx("tool.setAttr xfrm.jitter seed 1924");
lx("tool.setAttr xfrm.jitter rangeX [0.104]");
lx("tool.setAttr xfrm.jitter rangeY [0.104]");
lx("tool.setAttr xfrm.jitter rangeZ [0.104]");
lx("tool.doApply");

lx("select.expand");
lx("poly.setMaterial flat smoothing:[0]");
lx("select.contract");

lx("tool.set actr.screen on");



#-----------------------------------------------------------------------------------
#BOUNDING BOX subroutine (ver 1.5)
#-----------------------------------------------------------------------------------
sub boundingbox  #minX-Y-Z-then-maxX-Y-Z
{
	lxout("[->] Using boundingbox (math) subroutine");
	my @firstVertPos = lxq("query layerservice vert.pos ? $_[0]");
	my $minX = $firstVertPos[0];
	my $minY = $firstVertPos[1];
	my $minZ = $firstVertPos[2];
	my $maxX = $firstVertPos[0];
	my $maxY = $firstVertPos[1];
	my $maxZ = $firstVertPos[2];
	my @bbVertPos;

	foreach my $bbVert (@_){
		@bbVertPos = lxq("query layerservice vert.pos ? $bbVert");
		if ($bbVertPos[0] < $minX)	{	$minX = $bbVertPos[0];	}
		if ($bbVertPos[0] > $maxX)	{	$maxX = $bbVertPos[0];	}
		if ($bbVertPos[1] < $minY)	{	$minY = $bbVertPos[1];	}
		if ($bbVertPos[1] > $maxY)	{	$maxY = $bbVertPos[1];	}
		if ($bbVertPos[2] < $minZ)	{	$minZ = $bbVertPos[2];	}
		if ($bbVertPos[2] > $maxZ)	{	$maxZ = $bbVertPos[2];	}
	}
	return ($minX,$minY,$minZ,$maxX,$maxY,$maxZ);
}