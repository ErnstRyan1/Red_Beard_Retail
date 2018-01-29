#perl
#ver 0.5
#author : Seneca Menard
#this script is hardcoded to create a sunlight at each selected vert.  I need to let you create any type of item...

my $mainlayer = lxq("query layerservice layers ? main");
my @verts = lxq("query layerservice verts ? selected");
foreach my $vert (@verts){
	my @pos = lxq("query layerservice vert.pos ? $vert");
	lx("item.create sunLight");
	lx("transform.channel pos.X $pos[0]");
	lx("transform.channel pos.Y $pos[1]");
	lx("transform.channel pos.Z $pos[2]");

	#lx("item.channel locator(translation)\$pos.X @pos[0]");
	#lx("item.channel locator(translation)\$pos.Y @pos[1]");
	#lx("item.channel locator(translation)\$pos.Z @pos[2]");
}

