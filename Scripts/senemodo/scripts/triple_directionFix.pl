#perl
#ver 0.5
#author : Seneca Menard
#This script is for taking tripled geometry and forcing all the triple directions to be the same.  It's definitely not ready yet.

lx("select.drop edge");
lx("select.type polygon");
lx("select.boundary");

my $pi = 3.1415926535897932384626433832795;
my $mainlayer = lxq("query layerservice layers ? main");
my @polys = lxq("query layerservice polys ? selected");
my @edges = lxq("query layerservice edges ? selected");
my %boundaryEdgeTable;
my %edgeSelectTable;

&selectVmap;

foreach my $edge (@edges){
	$edge =~ s/[()]//g;
	my @verts = split/,/,$edge;
	if ($verts[0] < $verts[1]){
		$boundaryEdgeTable{$verts[0].",".$verts[1]} = 1;
	}else{
		$boundaryEdgeTable{$verts[1].",".$verts[0]} = 1;
	}
}

foreach my $poly (@polys){
	my @vertList = lxq("query layerservice poly.vertList ? $poly");
	my @vmapValues = lxq("query layerservice poly.vmapValue ? $poly");
	my @dpVector = (1,0);

	for (my $i=-1; $i<$#vertList; $i++){
		if ($vertList[$i] < $vertList[$i+1]){
			if ($boundaryEdgeTable{$vertList[$i] . "," . $vertList[$i+1]} == 1){
				#lxout("skipping this edge : $vertList[$i],$vertList[$i+1]");
				next;
			}
		}elsif ($boundaryEdgeTable{$vertList[$i+1] . "," . $vertList[$i]} == 1){
				#lxout("skipping this edge : $vertList[$i],$vertList[$i+1]");
				next;
		}

		my @uvPos1 = ( @vmapValues[$i*2] , @vmapValues[($i*2)+1] );
		my @uvPos2 = ( @vmapValues[($i+1)*2] , @vmapValues[(($i+1)*2)+1] );
		my $angle = angleCheck2d(\@uvPos1,\@uvPos2);
		if ($angle < 0){$angle += 360;}
		#lxout("angle = $angle");

		if	( ($angle > 91) && ($angle < 179) ){
			@{$edgeSelectTable{$vertList[$i] . "," . $vertList[$i+1]}} = ($vertList[$i],$vertList[$i+1]);
		}
		elsif	( ($angle > 271) && ($angle < 359) ){
			@{$edgeSelectTable{$vertList[$i] . "," . $vertList[$i+1]}} = ($vertList[$i],$vertList[$i+1]);
		}
	}
}

lx("!!select.drop edge");
foreach my $edge (keys %edgeSelectTable){
	lx("!!select.element $mainlayer edge add @{$edgeSelectTable{$edge}}[0] @{$edgeSelectTable{$edge}}[1]");
}
if ((keys %edgeSelectTable) > 0){
	lx("!!edge.spinQuads");
}





#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#2D ANGLE CHECK SUBROUTINE
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE : my $angle = angleCheck2d(\@pos1,\@pos2);
#requires $pi
sub angleCheck2d{
	my @disp = ( (${$_[1]}[0] - ${$_[0]}[0]) , (${$_[1]}[1] - ${$_[0]}[1]) );
	my $radian = atan2($disp[1],$disp[0]);
	my $angle = ($radian*180)/$pi;
	return $angle;
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#DOT PRODUCT 2D subroutine
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE : my $dp = dotProduct2d(\@vector1,\@vector2);
sub dotProduct2d{
	my @array1 = @{$_[0]};
	my @array2 = @{$_[1]};
	my $dp = (	(@array1[0]*@array2[0])+(@array1[1]*@array2[1]) );
	return $dp;
}

#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#UNIT VECTOR 2D
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
sub unitVector2d{
	my $dist1 = sqrt((@_[0]*@_[0])+(@_[1]*@_[1]));
	lxout("dist1 = $dist1");
	@_ = ((@_[0]/$dist1),(@_[1]/$dist1));
	return @_;
}

#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#SELECT THE PROPER VMAP  v2.01 (unreal)
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
sub selectVmap{
	my $defaultVmapName = lxq("pref.value application.defaultTexture ?");
	my $vmaps = lxq("query layerservice vmap.n ? all");
	my %uvMaps;
	my @selectedUVmaps;
	my $finalVmap;

	lxout("-Checking which uv maps to select or deselect");

	for (my $i=0; $i<$vmaps; $i++){
		if (lxq("query layerservice vmap.type ? $i") eq "texture"){
			if (lxq("query layerservice vmap.selected ? $i") == 1){push(@selectedUVmaps,$i);}
			my $name = lxq("query layerservice vmap.name ? $i");
			$uvMaps{$i} = $name;
		}
	}
	lxout("selectedUVmaps = @selectedUVmaps");

	#ONE SELECTED UV MAP
	if (@selectedUVmaps == 1){
		lxout("     -There's only one uv map selected <> $uvMaps{@selectedUVmaps[0]}");
		$finalVmap = @selectedUVmaps[0];
	}

	#MULTIPLE SELECTED UV MAPS  (try to select "$defaultVmapName")
	elsif (@selectedUVmaps > 1){
		my $foundVmap;
		foreach my $vmap (@selectedUVmaps){
			if ($uvMaps{$vmap} eq $defaultVmapName){
				$foundVmap = $vmap;
				last;
			}
		}
		if ($foundVmap != "")	{
			lx("!!select.vertexMap $uvMaps{$foundVmap} txuv replace");
			lxout("     -There's more than one uv map selected, so I'm deselecting all but this one <><> $uvMaps{$foundVmap}");
			$finalVmap = $foundVmap;
		}
		else{
			lx("!!select.vertexMap $uvMaps{@selectedUVmaps[0]} txuv replace");
			lxout("     -There's more than one uv map selected, so I'm deselecting all but this one <><> $uvMaps{@selectedUVmaps[0]}");
			$finalVmap = @selectedUVmaps[0];
		}
	}

	#NO SELECTED UV MAPS (try to select "$defaultVmapName" or create it)
	elsif (@selectedUVmaps == 0){
		lx("!!select.vertexMap {$defaultVmapName} txuv replace") or $fail = 1;
		if ($fail == 1){
			lx("!!vertMap.new {$defaultVmapName} txuv {0} {0.78 0.78 0.78} {1.0}");
			lxout("     -There were no uv maps selected and '$defaultVmapName' didn't exist so I created this one. <><> $defaultVmapName");
		}else{
			lxout("     -There were no uv maps selected, but '$defaultVmapName' existed and so I selected this one. <><> $defaultVmapName");
		}

		my $vmaps = lxq("query layerservice vmap.n ? all");
		for (my $i=0; $i<$vmaps; $i++){
			if (lxq("query layerservice vmap.name ? $i") eq $defaultVmapName){
				$finalVmap = $i;
			}
		}
	}

	#ask the name of the vmap just so modo knows which to query.
	my $name = lxq("query layerservice vmap.name ? $finalVmap");
}


