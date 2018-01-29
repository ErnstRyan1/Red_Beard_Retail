#perl
#ver 1.0
#author : Seneca Menard

#this script will look at your poly selection and then select any edges that appear to be spun incorrectly (ie, you have an extremely narrow polygon that have a better shape if that edge were spun)

#script arguments :
# 0-1 : type in any number between 0 and 1 to specify the cutoff point for which edges will be selected.  0.9 is the default, and if you use a lower number, you'll select more edges


my $mainlayer = lxq("query layerservice layers ? main");
my @polys = lxq("query layerservice polys ? selected");
my $dpCutoff = 0.9;
my $scriptSuccess = 0;
lx("select.drop edge");

#script arguments
foreach my $arg (@ARGV){
	if (($arg <= 1) && ($arg > 0)){$dpCutoff = $arg;}
}


foreach my $poly (@polys){
	my @verts = lxq("query layerservice poly.vertList ? $poly");
	if (@verts > 3){next;}
	my @pos1 = lxq("query layerservice vert.pos ? $verts[0]");
	my @pos2 = lxq("query layerservice vert.pos ? $verts[1]");
	my @pos3 = lxq("query layerservice vert.pos ? $verts[2]");

	my @vec1 = arrMath(@pos1,@pos2,subt);
	my @vec2 = arrMath(@pos1,@pos3,subt);
	my @vec3 = arrMath(@pos2,@pos3,subt);
	my @unitVec1 = unitVector(@vec1);
	my @unitVec2 = unitVector(@vec2);
	my @unitVec3 = unitVector(@vec3);

	my $dp1 = abs(dotProduct(\@unitVec1,\@unitVec2));
	my $dp2 = abs(dotProduct(\@unitVec1,\@unitVec3));

	if (($dp1 > $dpCutoff) && ($dp2 > $dpCutoff)){
		$scriptSuccess = 1;
		my $disp1 = abs($vec1[0]) + abs($vec1[1]) + abs($vec1[2]);
		my $disp2 = abs($vec2[0]) + abs($vec2[1]) + abs($vec2[2]);
		my $disp3 = abs($vec3[0]) + abs($vec3[1]) + abs($vec3[2]);

		if (($disp1 >= $disp2) && ($disp1 >= $disp3)){
			lx("select.element $mainlayer edge set $verts[0] $verts[1]");
			lx("edge.spinQuads");
		}elsif (($disp2 >= $disp1) && ($disp2 > $disp3)){
			lx("select.element $mainlayer edge set $verts[0] $verts[2]");
			lx("edge.spinQuads");
		}else{
			lx("select.element $mainlayer edge set $verts[1] $verts[2]");
			lx("edge.spinQuads");
		}
	}
}

#if ($scriptSuccess == 0){
	lx("select.type polygon");
#}

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
