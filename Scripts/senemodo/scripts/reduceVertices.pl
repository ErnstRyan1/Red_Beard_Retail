#perl
#author : Seneca Menard
#ver 0.5
#This script will reduce the vertices on the currently selected polys, using the angle specified by the user.
#it's still a little bit of a WIP. I don't think it's perfectly accurate yet.


my $pi=3.14159265358979323;
my $angle = quickDialog("angle:",float,5,0,180);	#get angle
my $rad = $angle*($pi/180);							#convert angle to radian.
my $userDP = cos($rad);								#convert radian to DP.
lxout("userDP = $userDP");

my $mainlayer = lxq("query layerservice layers ? main");
my @polys = lxq("query layerservice polys ? selected");
my @delVerts;
my $deleted = 0;

foreach my $poly (@polys){
	my %vertPositions;
	my @verts = lxq("query layerservice poly.vertList ? $poly");
	for (my $i=0; $i<@verts; $i++){	@{$vertPositions{@verts[$i]}} = lxq("query layerservice vert.pos ? @verts[$i]");}

	my $sumDP = 1;
	for (my $i=0; $i<@verts; $i++){
		my @v1 = (@verts[$i-1],@verts[$i]);
		if ($i == $#verts)	{our @v2 = (@verts[$i],@verts[0]);}
		else				{our @v2 = (@verts[$i],@verts[$i+1]);}

		my @vector1 = unitVector(arrMath(@{$vertPositions{@v1[0]}},@{$vertPositions{@v1[1]}},subt));
		my @vector2 = unitVector(arrMath(@{$vertPositions{@v2[0]}},@{$vertPositions{@v2[1]}},subt));
		my $dp = dotProduct(\@vector1,\@vector2);

		#lxout(" \nv1 = @v1 <> v2 = @v2");
		#lxout("v1 (@v1) = @{$vertPositions{@v1[0]}} , @{$vertPositions{@v1[1]}}");
		#lxout("v2 (@v2) = @{$vertPositions{@v2[0]}} , @{$vertPositions{@v2[1]}}");
#
		#lxout("vector1 = @vector1");
		#lxout("vector2 = @vector2");
		#lxout("sumDP = $sumDP");
		my $DPDiff = 1 - $dp;
		$sumDP -= $DPDiff;
		#lxout("userDP = $userDP <> sumDP = $sumDP");

		if (($deleted == 0) && ($sumDP < $userDP)){
			#lxout("1");
			$sumDP = 1;
		}elsif ($sumDP > $userDP){
			#lxout("2");
			push(@delVerts,@verts[$i]);
			$deleted = 1;
		}elsif ($deleted == 1){
			#lxout("3");
			$sumDP = 1;
			$deleted = 0;
		}
	}
}


lx("select.drop vertex");
lx("select.element $mainlayer vertex add $_") for @delVerts;









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

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#QUICK DIALOG SUB v2.1
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE : quickDialog(username,float,initialValue,min,max);
sub quickDialog{
	if (@_[1] eq "yesNo"){
		lx("dialog.setup yesNo");
		lx("dialog.msg {$_[0]}");
		lx("dialog.open");
		if (lxres != 0){	die("The user hit the cancel button");	}
		return (lxq("dialog.result ?"));
	}else{
		if (lxq("query scriptsysservice userValue.isdefined ? seneTempDialog") == 1){
			lx("user.defDelete seneTempDialog");
		}
		lx("user.defNew name:[seneTempDialog] type:{$_[1]} life:[momentary]");		
		lx("user.def seneTempDialog username [$_[0]]");
		if (($_[3] != "") && ($_[4] != "")){
			lx("user.def seneTempDialog min [$_[3]]");
			lx("user.def seneTempDialog max [$_[4]]");
		}
		lx("user.value seneTempDialog [$_[2]]");
		lx("user.value seneTempDialog ?");
		if (lxres != 0){	die("The user hit the cancel button");	}
		return(lxq("user.value seneTempDialog ?"));
	}
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

