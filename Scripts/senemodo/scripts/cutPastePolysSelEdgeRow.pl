#perl
#ver 1.0
#author : Seneca Menard

#this script will cut/paste your polys and then select one of it's border edge rows. (whichever is shortest)


my $mainlayer = lxq("query layerservice layers ? main");
my @finalEdgesToSelect;
if (lxq("select.count polygon ?") == 0){die("No polys are selected and so I'm cancelling the script");}
lx("!!select.type polygon");
lx("!!select.cut");
lx("!!select.drop polygon");
lx("!!select.invert");
lx("!!select.paste");
lx("!!select.invert");

my @polys = lxq("query layerservice polys ? selected");
my %polyTable; $polyTable{$_} = 1 for @polys;

while ((keys %polyTable) > 0){
	my $poly = (keys %polyTable)[0];

	#find poly island
	lx("!!select.drop polygon");
	lx("!!select.element $mainlayer polygon set $poly");
	lx("!!select.connect");
	my @currentPolys = lxq("query layerservice polys ? selected");
	delete $polyTable{$_} for @currentPolys;

	#find corner vert
	my %verts;
	my $foundVert;
	foreach my $poly (@currentPolys){
		my @vertList = lxq("query layerservice poly.vertList ? $poly");
		$verts{$_} = 1 for @vertList;
	}
	foreach my $vert (keys %verts){
		my @polyList = lxq("query layerservice vert.polyList ? $vert");
		if (@polyList == 1){
			$foundVert = $vert;
			last;
		}
	}

	#find which edge row has less polys
	my @cornerVertList = lxq("query layerservice vert.vertList ? $foundVert");
	my @edges1 = selectMoreUntilHitPolyCorner($foundVert,$cornerVertList[0]);
	my @edges2 = selectMoreUntilHitPolyCorner($foundVert,$cornerVertList[1]);
	if (@edges1 <= @edges2)	{push(@finalEdgesToSelect,@edges1);pop(@finalEdgesToSelect);}
	else					{push(@finalEdgesToSelect,@edges2);pop(@finalEdgesToSelect);}
}

lx("select.drop edge");
foreach my $edge (@finalEdgesToSelect){
	my @verts = split (/[^0-9]/, $edge);
	lx("select.element $mainlayer edge add @verts[1] @verts[2]");
}



sub selectMoreUntilHitPolyCorner{
	lx("!!select.drop vertex");
	lx("!!select.element $mainlayer vertex set $_[0]");
	lx("!!select.element $mainlayer vertex add $_[1]");

	my $edge = "(".$_[0].",".$_[1].")";
	my @lastPolys = lxq("query layerservice edge.polyList ? $edge");
	my $lastVert = $_[1];
	my @edges = $edge;

	while(1){
		lx("!!select.more");
		my @newVerts = lxq("query layerservice verts ? selected");
		if	($newVerts[-1] < $lastVert)	{our $newEdge = "(".$newVerts[-1].",".$lastVert.")";}
		else							{our $newEdge = "(".$lastVert.",".$newVerts[-1].")";}

		my @newPolys = lxq("query layerservice edge.polyList ? $newEdge");
		push(@edges,$newEdge);

		if ($lastPolys[-1] == $newPolys[-1]){
			last;
		}else{
			@lastPolys = $newPolys[-1];
			$lastVert = $newVerts[-1];
		}
	}
	return(@edges);
}

