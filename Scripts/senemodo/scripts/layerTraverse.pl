#perl
my $mainlayer  = lxq("query layerservice layers ? main");
my $layerCount = lxq("query layerservice layer.n ? all");

#GO TO PREVIOUS LAYER
my $layer;
if (@ARGV[0] eq "up"){
	if ($mainlayer == 1)			{	$layer = $layerCount;		}
	else							{	$layer = $mainlayer-1;	}
}else{
	if ($mainlayer == $layerCount)	{	$layer = 1;				}
	else							{	$layer = $mainlayer+1;	}
}
my $layerID = lxq("query layerservice layer.id ? $layer");
lx("select.subItem [$layerID] set locator");


