#perl
#This script is to select all the polys touching the selected edges
#Or all edges touching the vert if in edge mode.
my $mainlayer = lxq("query layerservice layers ? main");

if (lxq( "select.typeFrom {vertex;edge;polygon;item} ?" )){
	my @verts = lxq("query layerservice verts ? selected");
	my %edgeList;

	foreach my $vert (@verts){
		my @vertList = lxq("query layerservice vert.vertList ? $vert");
		foreach my $newVert (@vertList){
			if ($vert < $newVert){
				$edgeList{$vert,$newVert} = 1;
			}else{
				$edgeList{$newVert,$vert} = 1;
			}
		}
	}

	lx("select.drop edge");
	foreach my $edge (keys %edgeList){
		my @verts = split (/[^0-9]/, $edge);
		lx("select.element $mainlayer edge add @verts[0] @verts[1]");
	}
}

elsif (lxq( "select.typeFrom {edge;polygon;item;vertex} ?" )){
	my @edges = lxq("query layerservice edges ? selected");
	my %polyList;

	if (@ARGV[0] eq "selectAll"){
		foreach my $edge (@edges){
			foreach (lxq("query layerservice edge.vertList ? $edge")){
				my @polys = lxq("query layerservice vert.polyList ? $_");
				lxout("polys = @polys");
				$polyList{$_} = 1 for @polys;
			}
		}
	}else{
		foreach my $edge (@edges){
			my @polys = lxq("query layerservice edge.polyList ? $edge");
			$polyList{$_} = 1 for @polys;
		}
	}

	lx("select.drop polygon");
	foreach my $key (keys %polyList){lx("select.element $mainlayer polygon add $key");}
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
