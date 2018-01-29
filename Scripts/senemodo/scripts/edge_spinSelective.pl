#perl
#AUTHOR : Seneca Menard
#This script is for spinning only the edges that are similar in direction to the first one that's selected.
#The way you use the script is this :
# 1) : select an edge that points in a direction that you don't like
# 2) : select a bunch of other edges that you may or may not want to spin (a quick lasso select will work)
# 3) : run the script and a dialog window will pop up that asks you how many degrees in similarity all the edges have to have in relation to the first edge for them to be spun or not.
# 4) : just type in your similarity number and hit enter or click ok and it'll only spin the edges that are similar enough.


my $pi=3.14159265358979323;
my $mainlayer = lxq("query layerservice layers ? main");
my @edges = lxq("query layerservice selection ? edge");
my @strsplit = split (/[^0-9]/, @edges[0]);
my @mainVector = unitVector(lxq("query layerservice edge.vector ? (@strsplit[2],@strsplit[3])"));

my $dpCheck = quickDialog("How many degrees of leeway\nshould be allowed on the\nedges that should be spun?",float,15,0,90);
$dpCheck = $dpCheck*($pi/180);	#convert angle to radian.
$dpCheck = cos($dpCheck);		#convert radian to DP.
lxout("mainVector = @mainVector");
lxout("dpCheck = $dpCheck");

foreach my $edge (@edges){
	my @strsplit = split (/[^0-9]/, $edge);
	my @vector = unitVector(lxq("query layerservice edge.vector ? (@strsplit[2],@strsplit[3])"));
	my $dp = dotProduct(\@vector,\@mainVector);

	if (abs($dp) > $dpCheck){
		lx("!!select.element $mainlayer edge set @strsplit[2] @strsplit[3]");
		lx("!!edge.spinQuads");
	}
}
lx("!!select.drop edge");









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