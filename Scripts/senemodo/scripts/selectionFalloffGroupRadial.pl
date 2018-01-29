#perl
#ver 1.2
#author : Seneca Menard
#This script will give each poly group it's own falloff value, and the falloff value is determined by how far the group is from the poly that the mouse is over.

#SCRIPT ARGUMENTS : 
#"slowerAlgorithm" = this uses each mesh island's bbox as the distance from the mouse, instead of using the mesh island's first poly pos.  thus it's more accurate but slower.

#CHANGES : 
#(6-18-13) : added "slowerAlgorithm" cvar, which if you turn it on will make the dist sorting be more accurate but slower.


#SCRIPT CVARS
foreach my $arg (@ARGV){
	if ($arg eq "slowerAlgorithm"){	our $slowerAlgorithm = 1;	}
}


#SETUP
my $mainlayer = lxq("query layerservice layers ? main");
my @polys = lxq("query layerservice polys ? selected");
my $view = lxq("query view3dservice mouse.view ?");
my $mousePoly = lxq("query view3dservice element.over ? POLY");
if ($mousePoly eq ""){die("The mouse must be over a poly in order for me to determine where the gradation should come from");}
my %touchingPolyList;
my %polysToDoList;
$polysToDoList{$_} = 1 for @polys;
my %fakeDistTable;
my $maxFakeDist;

my @mousePolyInfo = split (/[^0-9]/, $mousePoly);
my $layerName = lxq("query layerservice layer.name ? $mousePolyInfo[0]");
my @mousePolyPos = lxq("query layerservice poly.pos ? $mousePolyInfo[1]");
$layerName = lxq("query layerservice layer.name ? $mainlayer");

#DEFINE THE GROUPS
foreach my $poly (@polys){
	if ($polysToDoList{$poly} == 1){
		my @touchingPolys = listTouchingPolys2($poly);
		@{$touchingPolyList{$poly}} = @touchingPolys;
		$polysToDoList{$_} = 0 for @touchingPolys;
	}
}

printHashTableArray(\%polysToDoList,toDoList);
printHashTableArray(\%touchingPolyList,touchingList);

#GET THE WEIGHTMAP AMOUNT FOR EACH GROUP
foreach my $key (keys %touchingPolyList){
	my @pos;

	if ($slowerAlgorithm == 1){
		my @bbox;
		my %vertTable;
		foreach my $poly (@{$touchingPolyList{$key}}){
			$vertTable{$_} = 1 for lxq("query layerservice poly.vertList ? $poly");
		}
		
		my @vp = lxq("query layerservice vert.pos ? (keys %vertTable)[0]");
		@bbox[0] = ($vp[0] , $vp[1] , $vp[2] , $vp[0] , $vp[1] , $vp[2]);
		
		foreach my $vert (keys %vertTable){
			my @vertPos = lxq("query layerservice vert.pos ? $vert");
			if ($vertPos[0] < $bbox[0]){	$bbox[0] = $vertPos[0];	}
			if ($vertPos[1] < $bbox[1]){	$bbox[1] = $vertPos[1];	}
			if ($vertPos[2] < $bbox[2]){	$bbox[2] = $vertPos[2];	}
			if ($vertPos[0] > $bbox[3]){	$bbox[3] = $vertPos[0];	}
			if ($vertPos[1] > $bbox[4]){	$bbox[4] = $vertPos[1];	}
			if ($vertPos[2] > $bbox[5]){	$bbox[5] = $vertPos[2];	}
		}
		
		@pos = ( ($bbox[0] + $bbox[3]) * .5, ($bbox[1] + $bbox[4]) * .5, ($bbox[2] + $bbox[4]) * .5 );
		
	}else{
		@pos = lxq("query layerservice poly.pos ? $key");
	}
	
	my @disp = ($pos[0]-$mousePolyPos[0],$pos[1]-$mousePolyPos[1],$pos[2]-$mousePolyPos[2]);
	my $fakeDist = abs($disp[0])+abs($disp[1])+abs($disp[2]);
	if ($fakeDist > $maxFakeDist){$maxFakeDist = $fakeDist;}
	$fakeDistTable{$key} = $fakeDist;
}

#APPLY THE WEIGHTMAP AMOUNT TO EACH GROUP
lx("!!tool.set falloff.vertexMap off");
lx("!!tool.set falloff.invert off falloff");
foreach my $key (keys %touchingPolyList){
	lx("select.drop polygon");
	foreach my $poly (@{$touchingPolyList{$key}}){lx("select.element $mainlayer polygon add $poly");}
	my $weight = $fakeDistTable{$key} / $maxFakeDist;

	lx("!!select.vertexMap senetemp wght replace") or lx("vertMap.new senetemp wght false {0.78 0.78 0.78} 1.0");
	lx("tool.set vertMap.setWeight on");
	lx("tool.setAttr vertMap.setWeight weight $weight");
	lx("tool.doApply");
	lx("tool.set vertMap.setWeight off");
}

#now select the polys again and turn on weightmap falloff
lx("!!select.element $mainlayer polygon add $_") for @polys;
lx("!!tool.set falloff.vertexMap on");
lx("!!tool.set falloff.invert on falloff");
lx("tool.set xfrm.move on");


#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#PRINT ALL THE ELEMENTS IN A HASH TABLE FULL OF ARRAYS
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#usage : printHashTableArray(\%table,table);
sub printHashTableArray{
	lxout("          ------------------------------------Printing @_[1] list------------------------------------");
	my $hash = @_[0];
	foreach my $key (sort keys %{$hash}){
		lxout("          KEY = $key");
		for (my $i=0; $i<@{$$hash{$key}}; $i++){
			lxout("             $i = @{$$hash{$key}}[$i]");
		}
	}
}

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

