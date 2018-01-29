#perl
#ver 1.0
#author : Seneca Menard

#This script will deselect polys based off of their similarity in size to the last selected poly.  So if you type in 25%, it will deselect all polys that are different in size by over 25% from the last selected one.


my $percentage = 1 / 100 * quickDialog("percentage difference :",float,75,0,1000000);
my $mainlayer = lxq("query layerservice layers ? main");
my @polys = lxq("query layerservice polys ? selected");
my $fakeAreaSize = findPolyAreaHack($polys[-1]);

foreach my $poly (@polys){
	my $diff = abs(findPolyAreaHack($poly) - $fakeAreaSize);
	my $diffSize = $diff / $fakeAreaSize;
	if ($diffSize > $percentage){
		lx("select.element $mainlayer polygon remove $poly");
	}
}




#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#FIND POLY AREA HACK SUB (hack for 2 reasons : using disp, not dist.  only queries first 2 edges)
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE : my $fakeArea = findPolyAreaHack($poly);
sub findPolyAreaHack{
	my @vertList = lxq("query layerservice poly.vertList ? $_[0]");
	my @pos1 = lxq("query layerservice vert.pos ? $vertList[0]");
	my @pos2 = lxq("query layerservice vert.pos ? $vertList[1]");
	my @pos3 = lxq("query layerservice vert.pos ? $vertList[2]");

	my @dispA = arrMath(@pos1,@pos2,subt);
	my @dispB = arrMath(@pos2,@pos3,subt);
	my $fakeArea = (abs($dispA[0])+abs($dispA[1])+abs($dispA[2])) * (abs($dispB[0])+abs($dispB[1])+abs($dispB[2]));
	return $fakeArea;
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
