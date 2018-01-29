#perl
#ver 1.5
#author : Seneca Menard

#This script has two EXECUTION MODES and two SELECTION MODES
# VERTEX 		: This will assign weighting to the vertices based off of their selection order.
# VERTEX + PART : This will assign weighting to the vertices based off of their selection order, but also in groups.  The number you enter defines how many verts per group.
# POLY			: This will assign weighting to each poly mesh based off of their selection order.
# POLY + PART 	: This will assign weighting to each polygon "part" based off of their selection order.

#SCRIPT ARGUMENTS :
# part			: on polys, this will group each piece by it's part name.  On verts, it'll group verts by selection order chunks
# randomOrder	: this will randomize the selection order



#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#SCRIPT ARGUMENTS
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
foreach my $arg (@ARGV){
	if		($arg eq "part")		{	our $selectByPart = 1;		}
	elsif	($arg eq "weight")		{	our $selectByWeight = 1;	}
	elsif	($arg eq "randomOrder")	{	our $randomOrder = 1;		}
	elsif	($arg eq "polySize")	{	our $polySize = 1;			}
}


#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#SETUP
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
my $mainlayer = lxq("query layerservice layers ? main");

#NEW tool preset--------------------------------------------------------
if		(lxq( "tool.set xfrm.move ?") eq "on")			{	our $tool = "xfrm.move";			}
elsif	(lxq("tool.set xfrm.rotate ?") eq "on")			{	our $tool = "xfrm.rotate";			}
elsif 	(lxq("tool.set xfrm.stretch ?") eq "on")		{	our $tool = "xfrm.stretch";			}
elsif 	(lxq("tool.set xfrm.scale ?") eq "on")			{	our $tool = "xfrm.scale";			}
elsif	(lxq("tool.set Transform ?") eq "on")			{	our $tool = "Transform";			}
elsif	(lxq("tool.set TransformMove ?") eq "on")		{	our $tool = "TransformMove";		}
elsif	(lxq("tool.set TransformScale ?") eq "on")		{	our $tool = "TransformScale";		}
elsif	(lxq("tool.set TransformUScale ?") eq "on")		{	our $tool = "TransformUScale";		}
elsif	(lxq("tool.set TransformRotate ?") eq "on")		{	our $tool = "TransformRotate";		}
else													{	our $tool = "TransformMove";		}
#------------------------------------------------------------------------------




#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#EDGE MODE
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
if( lxq( "select.typeFrom {edge;polygon;item;vertex} ?" ) ){



}




#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#POLY MODE
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
elsif( lxq( "select.typeFrom {polygon;item;vertex;edge} ?" ) ){
	my @polys = lxq("query layerservice polys ? selected");
	my $polyTable;
	my @tempPolys = @polys;
	my $count = 1;
	lx("tool.set falloff.vertexMap off");
	lx("!!select.vertexMap senetemp wght replace") or $fail = 1;
	if ($fail == 1){
		lxout("failed to select the senetemp weight map and so I created a new one");
		lx("!!vertMap.new senetemp wght");
		lx("!!select.vertexMap senetemp wght replace")
	}


	#--------------------------------------------------
	#SELECT BY PART POLY MODE
	#--------------------------------------------------
	if ($selectByPart == 1){
		lxout("[->] Assigning weight falloff groups by whichever polys touch each other");
		my @partOrder;

		foreach my $poly (@polys){
			my $part = lxq("query layerservice poly.part ? $poly");
			if (@{$polyTable{$part}} == 0){	push(@partOrder,$part);	}
			push(@{$polyTable{$part}},$poly);
		}
	}

	#--------------------------------------------------
	#SELECT BY WEIGHT POLY MODE
	#--------------------------------------------------
	elsif ($selectByWeight == 1){
		lxout("[->] Assigning weight falloff groups by averaging the falloff per poly group");

	}

	#--------------------------------------------------
	#REGULAR POLY MODE
	#--------------------------------------------------
	else{
		lxout("[->] Assigning weight falloff groups by whichever polys touch each other");

		while (@tempPolys > 0){
			my @touchingPolys = listTouchingPolys2(@tempPolys[0]);
			@tempPolys = removeListFromArray(\@tempPolys,\@touchingPolys);
			$polyTable{$count} = \@touchingPolys;
			$count++;
		}
	}

	#--------------------------------------------------
	#NOW PERFORM THE WEIGHTING AND CLEANUP
	#--------------------------------------------------
	my $weightDiv = 1/(keys %polyTable);
	if ($randomOrder == 0){
		our @keys = (sort { $a <=> $b } keys %polyTable);
	}else{
		our @keys = (keys %polyTable);
		randomizeArray(\@keys);
	}


	#hack utility to set weight based off of polysize. setup code.
	if ($polySize == 1){
		our $offset = quickDialog("Weight offset value (higher makes more even results)",float,0.5,0,100);
		our @totalEdgeLengthList;
		our $mintotalEdgeLength = 10000000000000000;
		our $maxtotalEdgeLength = 0;
		our $scalar;

		for (my $i=0; $i<@keys; $i++){
			my @vertList = lxq("query layerservice poly.vertList ? ${$polyTable{$keys[$i]}}[0]");
			my $totalEdgeLength;
			for (my $i=0; $i<@vertList; $i++){
				my @vertPos1 = lxq("query layerservice vert.pos ? $vertList[$i-1]");
				my @vertPos2 = lxq("query layerservice vert.pos ? $vertList[$i]");
				my @disp = arrMath(@vertPos1,@vertPos2,subt);
				$totalEdgeLength += abs($_) for @disp;
				lxout("totalEdgeLength = $totalEdgeLength");
			}

			$totalEdgeLengthList[$i] = $totalEdgeLength;
			if ($totalEdgeLength < $mintotalEdgeLength)	{	$mintotalEdgeLength = $totalEdgeLength;	}
			if ($totalEdgeLength > $maxtotalEdgeLength)	{	$maxtotalEdgeLength = $totalEdgeLength;	}
		}

		lxout("mintotalEdgeLength = $mintotalEdgeLength");
		lxout("maxtotalEdgeLength = $maxtotalEdgeLength");

		$scalar = 1 / ($maxtotalEdgeLength - $mintotalEdgeLength);
		lxout("scalar = $scalar");
	}

	#apply weighting
	for (my $i=0; $i<@keys; $i++){
		lx("select.drop polygon");
		foreach my $poly (@{$polyTable{$keys[$i]}}){
			lx("select.element $mainlayer polygon add {$poly}");
		}

		my $weight =  $weightDiv * $i;

		#hack utility to set weight based off of polysize. utiliztion code.
		if ($polySize == 1){
			$weight = ($totalEdgeLengthList[$i] - $mintotalEdgeLength) * $scalar + $offset;
		}

		lx("tool.set vertMap.setWeight on");
		lx("tool.attr vertMap.setWeight weight {$weight}");
		lx("tool.doApply");
		lx("tool.set vertMap.setWeight off");
	}

	lx("select.drop polygon");
	lx("select.element $mainlayer polygon add {$_}") for @polys;
	lx("tool.set falloff.vertexMap on");
	lx("tool.set $tool on");
}



#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#VERTEX MODE
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
elsif( lxq( "select.typeFrom {vertex;edge;polygon;item} ?" ) ){
	my @verts = lxq("query layerservice verts ? selected");
	my $weightDiv = 1/@verts;
	lx("tool.set falloff.vertexMap off");
	lx("!!select.vertexMap senetemp wght replace") or $fail = 1;
	if ($fail == 1){
		lxout("failed to select the senetemp weight map and so I created a new one");
		lx("!!vertMap.new senetemp wght");
		lx("!!select.vertexMap senetemp wght replace")
	}

	#--------------------------------------------------
	#GROUP VERT MODE
	#--------------------------------------------------
	if ($selectByPart == 1){
		lxout("[->] Assigning weight falloff on vert selection order with vert grouping by number");
		my $groupCount = quickDialog("How many verts per group?","integer",4,1,20000);
		my %vertGroups;
		my @vertGroups;
		my $weightDiv = 1/(@verts/$groupCount);
		my $count = 1;

		for ($i=0; $i<@verts; $i+=$groupCount){
			for (my $u=0; $u<$groupCount; $u++){
				if ($i+$u < @verts){
					push(@{$vertGroups{$count}},$verts[$i+$u]);
					my $vert = $verts[$i+$u];
				}
			}
			$count++;
		}

		if ($randomOrder == 0){
			@vertGroups = (sort { $a <=> $b } keys %vertGroups);
		}else{
			@vertGroups = (keys %vertGroups);
			randomizeArray(\@vertGroups);
		}

		for (my $i=0; $i<@vertGroups; $i++){
			lx("select.drop vertex");
			lx("select.element $mainlayer vertex add $_") for @{$vertGroups{$vertGroups[$i]}};

			my $weight = $weightDiv * ($i+1);
			lx("tool.set vertMap.setWeight on");
			lx("tool.attr vertMap.setWeight weight $weight");
			lx("tool.doApply");
			lx("tool.set vertMap.setWeight off");
			$count++;
		}
	}

	#--------------------------------------------------
	#REGULAR VERT MODE
	#--------------------------------------------------
	else{
		lxout("[->] Assigning weight falloff on vert selection order");
		if ($randomOrder == 1){randomizeArray(\@verts);}
		for (my $i=0; $i<@verts; $i++){
			lx("select.element $mainlayer vertex set @verts[$i]");
			my $weight = $weightDiv * $i;
			lx("tool.set vertMap.setWeight on");
			lx("tool.attr vertMap.setWeight weight $weight");
			lx("tool.doApply");
			lx("tool.set vertMap.setWeight off");
		}
	}

	#--------------------------------------------------
	#NOW PERFORM THE CLEANUP
	#--------------------------------------------------
	lx("select.drop vertex");
	lx("select.element $mainlayer vertex add $_") for @verts;
	lx("tool.set falloff.vertexMap on");
	lx("tool.set $tool on");
}


#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#DIE
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
else{
	die("\n.\n[---------------------------------------------You're not in vert, edge, or polygon mode.--------------------------------------------]\n[--PLEASE TURN OFF THIS WARNING WINDOW by clicking on the (In the future) button and choose (Hide Message)--] \n[-----------------------------------This window is not supposed to come up, but I can't control that.---------------------------]\n.\n");
}











#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#-------------------------------------------------SUBROUTINES------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#OPTIMIZED SELECT TOUCHING POLYGONS sub  (if only visible polys, you put a "hidden" check before vert.polyList point)
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE : my @connectedPolys = listTouchingPolys2(@polys[-$i]);
sub listTouchingPolys2{
	lxout("[->] LIST TOUCHING subroutine");
	my @lastPolyList = @_;
	my $stopScript = 0;
	our %totalPolyList = ();
	my %vertList;
	my %vertWorkList;
	my $vertCount;
	my $i = 0;

	#create temp vertList
	foreach my $poly (@lastPolyList){
		my @verts = lxq("query layerservice poly.vertList ? $poly");
		foreach my $vert (@verts){
			if ($vertList{$vert} == ""){
				$vertList{$vert} = 1;
				$vertWorkList{$vert}=1;
			}
		}
	}

	#--------------------------------------------------------
	#FIND CONNECTED VERTS LOOP
	#--------------------------------------------------------
	while ($stopScript == 0)
	{
		my @currentList = keys(%vertWorkList);
		%vertWorkList=();

		foreach my $vert (@currentList){
			my @verts = lxq("query layerservice vert.vertList ? $vert");
			foreach my $vert(@verts){
				if ($vertList{$vert} == ""){
					$vertList{$vert} = 1;
					$vertWorkList{$vert}=1;
				}
			}
		}

		$i++;

		#stop script when done.
		if (keys(%vertWorkList) == 0){
			#popup("round ($i) : it says there's no more verts in the hash table <><> I've hit the end of the loop");
			$stopScript = 1;
		}
	}

	#--------------------------------------------------------
	#CREATE CONNECTED POLY LIST
	#--------------------------------------------------------
	foreach my $vert (keys %vertList){
		my @polys = lxq("query layerservice vert.polyList ? $vert");
		foreach my $poly(@polys){
			$totalPolyList{$poly} = 1;
		}
	}

	return (keys %totalPolyList);
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#REMOVE ARRAY2 FROM ARRAY1 SUBROUTINE v1.1
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE : my @newArray = removeListFromArray(\@full_list,\@small_list);
sub removeListFromArray{
	my @fullList = @{$_[0]};
	for (my $i=0; $i<@{$_[1]}; $i++){
		for (my $u=0; $u<@fullList; $u++){
			if ($fullList[$u] eq ${$_[1]}[$i]){
				splice(@fullList, $u,1);
				last;
			}
		}
	}
	return @fullList;
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
#RANDOMIZE ARRAY SUB (fisher_yates_shuffle)
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE : randomizeArray(\@array);
sub randomizeArray{
    my $array = shift;
    my $i;
    for ($i=@$array; --$i; ){
        my $j = int rand ($i+1);
        next if $i == $j;
        @$array[$i,$j] = @$array[$j,$i];
    }
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

