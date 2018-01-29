#perl
#ver 1.1 (speedup)
#author : Seneca Menard


my $mainlayer = lxq("query layerservice layers ? main");
my @verts = lxq("query layerservice verts ? selected");

#CHECK IF SYMMETRY IS ON or OFF, CONVERT THE SYMM AXIS TO MY OLDSCHOOL NUMBER, TURN IT OFF.
our $symmAxis = lxq("select.symmetryState ?");
if 		($symmAxis eq "none")	{	$symmAxis = 3;	}
elsif	($symmAxis eq "x")		{	$symmAxis = 0;	}
elsif	($symmAxis eq "y")		{	$symmAxis = 1;	}
elsif	($symmAxis eq "z")		{	$symmAxis = 2;	}

my @pos1 = lxq("query layerservice vert.pos ? @verts[-1]");
my @pos2 = lxq("query layerservice vert.pos ? @verts[-2]");

if ($symmAxis != 3){
	lxout("flipping axis because of asymmetrical selection");
	@pos1[$symmAxis] = abs(@pos1[$symmAxis]);
}

lx("vert.set x @pos1[0]");
lx("vert.set y @pos1[1]");
lx("vert.set z @pos1[2]");
lx("!!vert.merge auto [0] [1 um]");
lx("select.drop vertex");

my $vert = lxq("query layerservice vert.n ? all") - 1;
lx("!!select.element $mainlayer vertex set $vert");