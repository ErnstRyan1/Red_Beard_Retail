#perl
#ver 0.91
#author : Seneca Menard
#this script is a quick hack script to simulate sketchup's awesome poly bevel tool that only leaves behind the noncoplanar original edges.

#SCRIPT ARGUMENTS :
# "transform"	: you can type in any name and the script will turn that tool on after you run the script.
# ".25"			: you can type in any number and the script	will adjust the angle difference in poly normals that determines whether or not to keep the old edge. .95=only remove edges if they're close to 90 degrees.  .5=remove edges up to 40 degrees or so.  .1 = remove edges up to about 5 degrees or so.

#(2-9-12 feature) : added the features so you can tell it to turn on whatever tool you want after the script is done and you can adjust the angle cutoff point that decides whether or not the old edges should be left or not.

#setup
my $mainlayer = lxq("query layerservice layers ? main");
my @polys = lxq("query layerservice polys ? selected");
my @borderEdges = returnBorderEdges(\@polys);
my $tool = "xfrm.move";
my $number = .5;


#--------------------------------------------
#CVARS
#--------------------------------------------
foreach my $arg (@ARGV){
	if		($arg =~ /[A-Z]/i)		{	$tool = $arg;	}
	elsif	($arg =~ /^[.0-9]+$/)	{	$number = $arg;	}
}

#--------------------------------------------
#SELECT BORDER EDGES
#--------------------------------------------
lx("select.drop edge");
foreach my $edge (@borderEdges){
	my @verts = split(/,/, $edge);
	lx("select.element $mainlayer edge add $verts[0] $verts[1]");
}

#--------------------------------------------
#now bevel polys
#--------------------------------------------
lx("select.type polygon");
lx("tool.set poly.bevel on");
lx("tool.attr poly.bevel group true");
lx("tool.setAttr poly.bevel inset 0.0");
lx("tool.setAttr poly.bevel shift .1");
lx("tool.doApply");
lx("tool.set poly.bevel off 0");

#--------------------------------------------
#NOW DESELECT EDGES WHOSE DP IS NEAR -1 OR 1
#--------------------------------------------
lx("select.type edge");
my @edges = lxq("query layerservice edges ? selected");
foreach my $edge (@edges){
	my @verts = split (/[^0-9]/, $edge);
	my @polyList = lxq("query layerservice edge.polyList ? $edge");
	if (@polyList > 1){
		my @polyNormal1 = lxq("query layerservice poly.normal ? $polyList[0]");
		my @polyNormal2 = lxq("query layerservice poly.normal ? $polyList[1]");
		my $dp = dotProduct(\@polyNormal1,\@polyNormal2);
		if (abs($dp) < $number){
			lx("select.element $mainlayer edge remove $verts[1] $verts[2]");
		}
	}
}

my @edges2 = lxq("query layerservice edges ? selected");
if (@edges2 > 0){lx("remove");}

#--------------------------------------------
#GO TO POLY MODE AND TURN ON MOVE TOOL
#--------------------------------------------
lx("select.type polygon");
lx("tool.set {$tool} on");









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
#RETURN BORDER EDGES FROM POLY LIST
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE : my @borderEdges = returnBorderEdges(\@polys);
sub returnBorderEdges{
	my %edgeList;
	foreach my $poly (@{$_[0]}){
		my @verts = lxq("query layerservice poly.vertList ? $poly");
		for (my $i=-1; $i<$#verts; $i++){
			my $edge;
			if (@verts[$i]<@verts[$i+1])	{	$edge = @verts[$i].",".@verts[$i+1];	}
			else							{	$edge = @verts[$i+1].",".@verts[$i];	}
			$edgeList{$edge} += 1;
		}
	}

	foreach my $key (keys %edgeList)	{	if ($edgeList{$key} != 1)	{	delete $edgeList{$key};	}	}
	return (keys %edgeList);
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
