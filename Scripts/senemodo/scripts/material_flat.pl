#perl
#FLAT material creation/assignment.
my @numMaterials = lxq("query layerservice materials ?");
my $material_index = 3210; #3210 is just a BS check
lxout("bleh"); #

foreach my $material (@numMaterials)
{
	my $materialName = lxq("query layerservice material.name ? $material");
	lxout("material name = $materialName");
	if ($materialName eq "flat")
	{
		$material_index = $material;
	}
}

lxout("material index=$material_index"); #

if ($material_index == 3210)
{
	lx("poly.setMaterial flat");
	my $flat_index = (@numMaterials);
	lxout("CREATING NEW SHADER:the flat number=$flat_index"); #

	lx("select.material [d00000$flat_index] replace");
	lx("item.channel polySurface$smAngle [0.0 °]");
	lx("item.channel polySurface$color {1.0 0.6 0.6}");
	#lx( "select.typeFrom {polygon;item;edge;vertex} 1" );
}
else
{
	lxout("not creating new shader"); #
	lx("poly.setMaterial flat");
}


