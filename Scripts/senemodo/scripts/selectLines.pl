#perl
#AUTHOR: Seneca Menard
#version 1.0
#This tool is for selecting outer edge lines.  It's exactly the same as what you'd normally get with the select.loop command, only it stops the edge expansion when it finds that the current edge selected the same poly as the one before it.
#So what you basically get is that it selects only that one side of the mesh, and doesn't do a full loop like select.loop normally does..  Very handy when you want to quickly select only one side for a quick extrude....


#-----------------------------------------------------------------------
#-----------------------------------------------------------------------
#SETUP
#-----------------------------------------------------------------------
#-----------------------------------------------------------------------
my $mainlayer = lxq("query layerservice layers ? main");
my %edgeList;
lx("select.edge remove poly more 1");
my @origEdges = lxq("query layerservice edges ? selected");
if (@origEdges < 1)	{	die("You don't have any non-border edges selected so I'm killing the script");	}



#-----------------------------------------------------------------------
#-----------------------------------------------------------------------
#FIND EACH EDGE LINE
#-----------------------------------------------------------------------
#-----------------------------------------------------------------------
for (my $i=0; $i<@origEdges; $i++){
	#-----------------------------------------------------------------------
	#select the root edge
	#-----------------------------------------------------------------------
	my $firstCutoffPoint;
	my $lastCutoffPoint;
	my $edge = @origEdges[$i];
	$edge =~ tr/()//d;
	my @verts = split(/,/, $edge);
	lx("select.element $mainlayer edge set @verts[0] @verts[1]");

	#-----------------------------------------------------------------------
	#select the loop
	#-----------------------------------------------------------------------
	lx("select.loop");
	my @loopSelection = lxq("query layerservice selection ? edge");
	s/\(\d{0,},/\(/  for @loopSelection;
	tr/()//d for @loopSelection;

	#-----------------------------------------------------------------------
	#look for the first double poly
	#-----------------------------------------------------------------------
	my $lastPoly = lxq("query layerservice edge.polyList ? (@loopSelection[0])");
	for (my $i=1; $i<@loopSelection; $i++){
		my $poly = lxq("query layerservice edge.polyList ? (@loopSelection[$i])");
		#popup("lp = $lastPoly <><> poly = $poly");
		if ($lastPoly == $poly){
			#popup("This edge is a breaking point : [$i]@loopSelection[$i]");
			$firstCutoffPoint = $i-1;
			last;
		}
		else{
			$lastPoly = $poly;
		}
	}

	#-----------------------------------------------------------------------
	#look for the last double poly
	#-----------------------------------------------------------------------
	$lastPoly = lxq("query layerservice edge.polyList ? (@loopSelection[0])");
	for (my $i=-1; $i>($#loopSelection*-1); $i--){
		my $poly = lxq("query layerservice edge.polyList ? (@loopSelection[$i])");
		if ($lastPoly == $poly){
			#popup("This edge is a breaking point : [$i]@loopSelection[$i]");
			$lastCutoffPoint = $i+1;
			last;
		}
		else{
			$lastPoly = $poly;
		}
	}

	#-----------------------------------------------------------------------
	#rebuild the edgeRow and put it in the hash table.
	#-----------------------------------------------------------------------
	#popup("first=$firstCutoffPoint <> last=$lastCutoffPoint");
	@tempLoop = splice(@loopSelection, ($firstCutoffPoint+1),($#loopSelection-$firstCutoffPoint));
	@tempLoop2 = splice(@tempLoop, $lastCutoffPoint, ($lastCutoffPoint*-1));
	unshift(@loopSelection,@tempLoop2);
	$edgeList{$i} = \@loopSelection;
}


#-----------------------------------------------------------------------
#-----------------------------------------------------------------------
#SELECT THE EDGE LINES
#-----------------------------------------------------------------------
#-----------------------------------------------------------------------
lx("select.drop edge");
foreach my $key (keys %edgeList){
	#popup("key($key) = @{$edgeList{$key}}");
	foreach my $edge (@{$edgeList{$key}}){
		my @verts = split(/,/, $edge);
		lx("select.element $mainlayer edge add @verts[0] @verts[1]");
	}
}







#-----------------------------------------------------------------------
#-----------------------------------------------------------------------
#POPUP SUB
#-----------------------------------------------------------------------
#-----------------------------------------------------------------------
sub popup #(MODO2 FIX)
{
	lx("dialog.setup yesNo");
	lx("dialog.msg {@_}");
	lx("dialog.open");
	my $confirm = lxq("dialog.result ?");
	if($confirm eq "no"){die;}
}
