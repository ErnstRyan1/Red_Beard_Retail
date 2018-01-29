#perl
my $mainlayer = lxq("query layerservice layers ? main");
my @verts = lxq("query layerservice verts ? selected");

foreach my $vert (@verts){
	my @pos = lxq("query layerservice vert.pos ? $vert");
	lxout("vert ($vert) = @pos");
}
