#perl

#This script looks at mesh number one that's selected and queries it's world pos and world rotation.  Then it applies that pos and rot to mesh 2 that's selected.  It's just a temp hack script and doesn't have any channel pre-creation, so if you don't create the movement transform or the rotation transform, modo will puke.  also, it's hardcoded for mesh items only.

my $pi = 3.14159265358979323;
my @meshSelection = lxq("query sceneservice selection ? mesh");
my @worldPos = lxq("query sceneservice item.worldPos ? @meshSelection[0]");
my @worldRotMat = lxq("query sceneservice item.worldRot ? {@meshSelection[0]}");

my @m0 = (@worldRotMat[0],@worldRotMat[1],@worldRotMat[2]);
my @m1 = (@worldRotMat[3],@worldRotMat[4],@worldRotMat[5]);
my @m2 = (@worldRotMat[6],@worldRotMat[7],@worldRotMat[8]);
my @rot = matrixToEuler(\@m0,\@m1,\@m2);
$_ = ($_*180)/$pi for @rot;
$_ = $_ * -1 for @rot;
lxout("rot = @rot");


lx("item.channel rot.X {@rot[2]} set {@meshSelection[-1]}");
lx("item.channel rot.Y {@rot[0]} set {@meshSelection[-1]}");
lx("item.channel rot.Z {@rot[1]} set {@meshSelection[-1]}");

lx("item.channel pos.X {@worldPos[0]} set {@meshSelection[-1]}");
lx("item.channel pos.Y {@worldPos[1]} set {@meshSelection[-1]}");
lx("item.channel pos.Z {@worldPos[2]} set {@meshSelection[-1]}");


#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#CONVERT MATRIX TO EULER (9char matrix)
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE : my @rotations = matrixToEuler(\@matrix0,\@matrix1,\@matrix2);
sub matrixToEuler{
	my @x = @{$_[0]};
	my @y = @{$_[1]};
	my @z = @{$_[2]};


	my ($heading,$attitude,$bank);
	my $pi = 3.14159265358979323;

	if (@y[0] > 0.998){						#except when M10=1 (north pole)
		$heading = atan2(@x[2],@z[2]);		#heading = atan2(M02,M22)
		$attitude = asin(@y[0]);		 	#
		$bank = 0;							#bank = 0
	}elsif (@y[0] < -0.998){				#except when M10=-1 (south pole)
		$heading = atan2(@x[2],@z[2]);		#heading = atan2(M02,M22)
		$attitude = asin(@y[0]);			#
		$bank = 0;							#bank = 0
	}else{
		$heading = atan2(-@z[0],@x[0]);		#heading = atan2(-m20,m00)
		$attitude = asin(@y[0]);		  	#attitude = asin(m10)
		$bank = atan2(-@y[2],@y[1]);		#bank = atan2(-m12,m11)
	}

	return ($heading,$attitude,$bank);
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#ASIN subroutine (haven't tested it to make sure it works tho)
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE :
#my $ydeg =  &rad2deg(&asin($axis[1]/$yhyp));
sub asin{
	atan2($_[0], sqrt(1 - $_[0] * $_[0]));
}
