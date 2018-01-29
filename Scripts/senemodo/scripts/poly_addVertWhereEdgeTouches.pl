#perl
#author : Seneca Menard

#this script is for adding verts to polys where teh edge your mouse is over would intersect with it.  great for closing stupid t-junctions in meshes.

#SCRIPT ARGUMENTS :
# skipPolyDesel = use this if you don't want the last poly deselected after script runtime.


#script args
foreach my $arg (@ARGV){
	if ($arg eq "skipPolyDesel")	{our $skipPolyDesel = 1;}
}




my $mainlayer = lxq("query layerservice layers ? main");
my $view = lxq("query view3dservice mouse.view ?");
my $edge_mouseOver = lxq("query view3dservice element.over ? EDGE");
if ($edge_mouseOver eq ""){die("Your mouse is not over an edge and so I'm cancelling teh script.");}

my @edgeData = split (/[^0-9]/, $edge_mouseOver);
my @edgeVertPos1 = lxq("query layerservice vert.pos ? $edgeData[1]");
my @edgeVertPos2 = lxq("query layerservice vert.pos ? $edgeData[2]");
my @polys = lxq("query layerservice polys ? selected");
my @vertList = lxq("query layerservice poly.vertList ? $polys[-1]");
my @winningEdge;
my $winningVert;
my $winningDP = -2;

#find which edge is the most in alignment with the vert (and which one of the two)
for (my $i=-1; $i<$#vertList; $i++){
	my $vert1 = $vertList[$i];
	my $vert2 = $vertList[$i+1];
	my @vertPos1 = lxq("query layerservice vert.pos ? $vert1");
	my @vertPos2 = lxq("query layerservice vert.pos ? $vert2");
	my @edgeVector1 = unitVector(arrMath(@vertPos2,@vertPos1,subt));
	my @edgeVector2 = unitVector(arrMath(@vertPos1,@vertPos2,subt));

	my @edgeVector1_v1 = unitVector(arrMath(@vertPos2,@edgeVertPos1,subt));
	my @edgeVector2_v1 = unitVector(arrMath(@vertPos1,@edgeVertPos1,subt));

	my @edgeVector1_v2 = unitVector(arrMath(@vertPos2,@edgeVertPos2,subt));
	my @edgeVector2_v2 = unitVector(arrMath(@vertPos1,@edgeVertPos2,subt));

	my $edge1_dp1 = dotProduct(\@edgeVector1,\@edgeVector1_v1);
	my $edge1_dp2 = dotProduct(\@edgeVector1,\@edgeVector1_v2);

	my $edge2_dp1 = dotProduct(\@edgeVector2,\@edgeVector2_v1);
	my $edge2_dp2 = dotProduct(\@edgeVector2,\@edgeVector2_v2);

	my $dp_added_v1 = $edge1_dp1 + $edge2_dp1;
	my $dp_added_v2 = $edge1_dp2 + $edge2_dp2;

	if ($dp_added_v1 > $winningDP){
		$winningDP = $dp_added_v1;
		@winningEdge = ($vert1,$vert2);
		$winningVert = $edgeData[1];
	}
	if ($dp_added_v2 > $winningDP){
		$winningDP = $dp_added_v2;
		@winningEdge = ($vert2,$vert1);
		$winningVert = $edgeData[2];
	}
}

#now find the poly order now that we have the edge
for (my $i=0; $i<@vertList; $i++){
	if ($vertList[$i] == $winningEdge[0]){
		$polyOrder = 0;
		last;
	}elsif ($vertList[$i] == $winningEdge[1]){
		$polyOrder = 1;
		last;
	}
}

#now find the edgeDist to the vert
my @winningEdgePos0 = lxq("query layerservice vert.pos ? $winningEdge[0]");
my @winningEdgePos1 = lxq("query layerservice vert.pos ? $winningEdge[1]");
my @winningVertPos = lxq("query layerservice vert.pos ? $winningVert");
my @winningEdgeDisp = arrMath(@winningEdgePos1,@winningEdgePos0,subt);
my @winningEdgeVertDisp = arrMath(@winningVertPos,@winningEdgePos0,subt);
my $winningEdgeDP = dotProduct(\@winningEdgeDisp,\@winningEdgeVertDisp);

my $edgeDist = dist(@winningEdgeDisp);
my $vertDist = dist(@winningEdgeVertDisp);
my $percentage = $vertDist/$edgeDist;

#perform cut
my $edgeKnifeVertInfo0 = $mainlayer-1 . "," . $winningEdge[0];
my $edgeKnifeVertInfo1 = $mainlayer-1 . "," . $winningEdge[1];
lx("!!tool.set edge.knife on");
lx("!!tool.reset");
lx("!!tool.attr edge.knife split false");
lx("!!tool.attr edge.knife count 1");
lx("!!tool.attr edge.knife vert0 {$edgeKnifeVertInfo0}");
lx("!!tool.attr edge.knife vert1 {$edgeKnifeVertInfo1}");
lx("!!tool.attr edge.knife pos {$percentage}");
lx("!!tool.doApply");
lx("!!tool.set edge.knife off");
my @newPolys = lxq("query layerservice polys ? selected");

#now merge the two verts.
my $newVert = lxq("query layerservice vert.n ? all") - 1;
my @newVertPos = lxq("query layerservice vert.pos ? $newVert");
lx("!!vert.move vertIndex:{$winningVert} posX:{$newVertPos[0]} posY:{$newVertPos[1]} posZ:{$newVertPos[2]}");
lx("!!select.drop vertex");
lx("!!select.element $mainlayer vertex add $winningVert");
lx("!!select.element $mainlayer vertex add $newVert");
lx("!!vert.merge auto disco:false");

if ($skipPolyDesel == 0){
	lx("!!select.drop polygon");
}else{
	lx("!!select.type polygon");
	lx("!!select.element $mainlayer polygon set $newPolys[0]");
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#CALCULATE DISTANCE subroutine
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#usage : my $dist = dist(@vector);
sub dist{
	return sqrt((@_[0]*@_[0])+(@_[1]*@_[1])+(@_[2]*@_[2]));
}


#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#PERFORM MATH FROM ONE ARRAY TO ANOTHER subroutine
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE : my @disp = arrMath(@pos2,@pos1,subt);
sub arrMath{
	my @array1 = (@_[0],@_[1],@_[2]);
	my @array2 = (@_[3],@_[4],@_[5]);
	my $math = @_[6];

	my @newArray;
	if		($math eq "add")	{	@newArray = (@array1[0]+@array2[0],@array1[1]+@array2[1],@array1[2]+@array2[2]);	}
	elsif	($math eq "subt")	{	@newArray = (@array1[0]-@array2[0],@array1[1]-@array2[1],@array1[2]-@array2[2]);	}
	elsif	($math eq "mult")	{	@newArray = (@array1[0]*@array2[0],@array1[1]*@array2[1],@array1[2]*@array2[2]);	}
	elsif	($math eq "div")	{	@newArray = (@array1[0]/@array2[0],@array1[1]/@array2[1],@array1[2]/@array2[2]);	}
	return @newArray;
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#UNIT VECTOR SUBROUTINE
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE : my @unitVector = unitVector(@vector);
sub unitVector{
	my $dist1 = sqrt((@_[0]*@_[0])+(@_[1]*@_[1])+(@_[2]*@_[2]));
	@_ = ((@_[0]/$dist1),(@_[1]/$dist1),(@_[2]/$dist1));
	return @_;
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#DOT PRODUCT subroutine (ver 1.1)
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE : my $dp = dotProduct(\@vector1,\@vector2);
sub dotProduct{
	return (	(${$_[0]}[0]*${$_[1]}[0])+(${$_[0]}[1]*${$_[1]}[1])+(${$_[0]}[2]*${$_[1]}[2])	);
}