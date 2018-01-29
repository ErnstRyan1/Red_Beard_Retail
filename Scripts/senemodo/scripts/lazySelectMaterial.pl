#perl
#BY: Seneca Menard
#version 1.2
#This script is to select all the touching polygons that have the same materials as the original selection..
#(8-11-07 bugfix) : doesn't select hidden polys anymore.
#(11-10-15 feature) : put in the "sen_lazySelectMode" user value which when turned on will tell the script to not select polys by matching materials, but by matching selection sets.

#---------------------------------------------------------------------------------------------
#USER VALUES
#---------------------------------------------------------------------------------------------
userValueTools(sen_lazySelectMode,boolean,config,"lazySelSet?","","","",xxx,xxx,"",0);
my $selSetMode = lxq("user.value sen_lazySelectMode ?");

#---------------------------------------------------------------------------------------------
#SETUP
#---------------------------------------------------------------------------------------------
my $mainlayer = lxq("query layerservice layers ? main");
my @originalPolys = lxq("query layerservice polys ? selected");
my @currentPolyList = @originalPolys;
my %ignorePolyList;
foreach my $poly (@originalPolys){ 	$ignorePolyList{$poly} = 1;	}
my @finalPolyList;
my %materialList;
my $loop = 1;
my $round = 1;

#---------------------------------------------------------------------------------------------
#BUILD THE MATERIAL HASH TABLE
#---------------------------------------------------------------------------------------------
foreach my $poly (@originalPolys){
	if ($selSetMode == 1){
		my @selSets = lxq("query layerservice poly.selSets ? $poly");
		$materialList{$_} = 1 for @selSets;
	}else{
		my $material = lxq("query layerservice poly.material ? $poly");
		$materialList{$material} = 1;
	}
}


#---------------------------------------------------------------------------------------------
#LOOP THRU POLYS AND SELECT THE POLYS WITH SIMILAR MATERIAL.
#---------------------------------------------------------------------------------------------
while (@currentPolyList > 0){
	lxout("Round [$round]");

	#create and clean up all the variables that need to be created or cleaned.
	my %vertList;
	my %polyList;
	my @foundPolys;

	#go through all polys in the last list and find their verts.
	foreach my $poly (@currentPolyList){
		my @verts = lxq("query layerservice poly.vertList ? $poly");
		foreach my $vert (@verts){
			$vertList{$vert} = 1;
		}
	}

	#go through all the verts and find the polys (ignoring the ones that have already been checked.
	foreach my $vert (keys %vertList){
		my @polys = lxq("query layerservice vert.polyList ? $vert");
		foreach my $poly (@polys){
			if (lxq("query layerservice poly.hidden ? $poly") == 0){
				if ($ignorePolyList{$poly} == ""){
					$polyList{$poly} = 1;
				}
			}
		}
	}

	#go through all the "new" polys and check their materials.  add 'em to the list if they match
	foreach my $poly (keys %polyList){
		if ($selSetMode == 1){
			my @selSets = lxq("query layerservice poly.selSets ? $poly");
			foreach my $set (@selSets){
				if ($materialList{$set} == 1)	{	push(@foundPolys,$poly);	last;}
			}
		}else{
			my $material = lxq("query layerservice poly.material ? $poly");
			if ($materialList{$material} == 1)	{	push(@foundPolys,$poly);	}
		}

		#add all the polys to the ignore list for the next round
		$ignorePolyList{$poly} = 1;
	}

	#add the found poly list to the final poly list
	push (@finalPolyList, @foundPolys);

	#replace the currentPolyList with the found poly list so it's ready for next round.
	@currentPolyList = @foundPolys;

	#up the round count.
	$round++;
}



#---------------------------------------------------------------------------------------------
#SELECT ALL THE FOUND POLYS
#---------------------------------------------------------------------------------------------
foreach my $poly (@finalPolyList){
	lx("select.element $mainlayer polygon add $poly");
}





















#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#SET UP THE USER VALUE OR VALIDATE IT   (no popups)
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#userValueTools(name,type,life,username,list,listnames,argtype,min,max,action,value);
sub userValueTools{
	if (lxq("query scriptsysservice userValue.isdefined ? @_[0]") == 0){
		lxout("Setting up @_[0]--------------------------");
		lxout("Setting up @_[0]--------------------------");
		lxout("0=@_[0],1=@_[1],2=@_[2],3=@_[3],4=@_[4],5=@_[6],6=@_[6],7=@_[7],8=@_[8],9=@_[9],10=@_[10]");
		lxout("@_[0] didn't exist yet so I'm creating it.");
		lx( "user.defNew name:[@_[0]] type:[@_[1]] life:[@_[2]]");
		if (@_[3] ne "")	{	lxout("running user value setup 3");	lx("user.def [@_[0]] username [@_[3]]");	}
		if (@_[4] ne "")	{	lxout("running user value setup 4");	lx("user.def [@_[0]] list [@_[4]]");		}
		if (@_[5] ne "")	{	lxout("running user value setup 5");	lx("user.def [@_[0]] listnames [@_[5]]");	}
		if (@_[6] ne "")	{	lxout("running user value setup 6");	lx("user.def [@_[0]] argtype [@_[6]]");		}
		if (@_[7] ne "xxx")	{	lxout("running user value setup 7");	lx("user.def [@_[0]] min @_[7]");			}
		if (@_[8] ne "xxx")	{	lxout("running user value setup 8");	lx("user.def [@_[0]] max @_[8]");			}
		if (@_[9] ne "")	{	lxout("running user value setup 9");	lx("user.def [@_[0]] action [@_[9]]");		}
		if (@_[1] eq "string"){
			if (@_[10] eq ""){lxout("woah.  there's no value in the userVal sub!");							}		}
		elsif (@_[10] == ""){lxout("woah.  there's no value in the userVal sub!");									}
								lx("user.value [@_[0]] [@_[10]]");		lxout("running user value setup 10");
	}else{
		#STRING-------------
		if (@_[1] eq "string"){
			if (lxq("user.value @_[0] ?") eq ""){
				lxout("user value @_[0] was a blank string");
				lx("user.value [@_[0]] [@_[10]]");
			}
		}
		#BOOLEAN------------
		elsif (@_[1] eq "boolean"){

		}
		#LIST---------------
		elsif (@_[4] ne ""){
			if (lxq("user.value @_[0] ?") == -1){
				lxout("user value @_[0] was a blank list");
				lx("user.value [@_[0]] [@_[10]]");
			}
		}
		#ALL OTHER TYPES----
		elsif (lxq("user.value @_[0] ?") == ""){
			lxout("user value @_[0] was a blank number");
			lx("user.value [@_[0]] [@_[10]]");
		}
	}
}