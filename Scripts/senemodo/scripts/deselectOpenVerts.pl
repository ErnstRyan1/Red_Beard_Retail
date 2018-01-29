#perl
#ver 1.0
#author : Seneca Menard

#This script is to deselect boundary verts.  If you have polys selected, it'll look at the polys' boundary verts.  If no polys are selected, it'll deselect the open edge verts.



my $mainlayer = lxq("query layerservice layers ? main");

#keep non poly border verts selected
if (lxq("select.count polygon ?") > 0){
	my %edgeTable;
	my %vertTable;
	my @verts = lxq("query layerservice verts ? selected");
	my @polys = lxq("query layerservice polys ? selected");
	foreach my $poly (@polys){
		my @polyVerts = lxq("query layerservice poly.vertList ? $poly");
		for (my $i=-1; $i<$#polyVerts; $i++){
			if ($polyVerts[$i] < $polyVerts[$i+1])	{	our $edge = $polyVerts[$i].",".$polyVerts[$i+1];	}
			else									{	our $edge = $polyVerts[$i+1].",".$polyVerts[$i];	}
			$edgeTable{$edge} += 1;
		}
	}

	foreach my $key (keys %edgeTable){
		if ($edgeTable{$key} == 1){
			my @verts = split(/,/, $key);
			$vertTable{$verts[0]} = 1;
			$vertTable{$verts[1]} = 1;
		}
	}

	lx("select.drop vertex");
	foreach my $vert (@verts){
		if ($vertTable{$vert} != 1){
			lx("select.element $mainlayer vertex add $vert");
		}
	}
}

#keep non open edge verts selected
else{
	my @verts = lxq("query layerservice verts ? selected");
	foreach my $vert (@verts){
		my @vertList = lxq("query layerservice vert.vertList ? $vert");
		foreach my $vert2 (@vertList){
			my @edgePolys = lxq("query layerservice edge.polyList ? ($vert,$vert2)");
			if (@edgePolys == 1){
				lx("select.element $mainlayer vertex remove $vert");
				last;
			}
		}
	}
}
