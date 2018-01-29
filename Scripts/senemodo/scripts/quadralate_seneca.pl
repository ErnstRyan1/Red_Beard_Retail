#perl
#ver 0.88
#author : Seneca Menard
#This script is to select the longest edges inbetween tris. (basically, just a different quadrangulate algo than dion's)

#(3-27-11 fix) : 501 sp2 had an annoying syntax change.  grrr.
#(5-17-11 feature) : the script can now skip removing edges that have disco uvs.  To use that, run the script with the "skipDiscoUVEdges" argument appended.

foreach my $arg (@ARGV){
	if ($arg =~ /skipDiscoUVEdges/i)	{	our $skipDiscoUVEdges = 1;	}
}

my $modoBuild = lxq("query platformservice appbuild ?");
if ($modoBuild > 41320){our $selectPolygonArg = "psubdiv";}else{our $selectPolygonArg = "curve";}
my $pi=3.1415926535897932384626433832795;
userValueTools(seneQuadralateAngle,float,config,"Coplanar Angle:","","","",xxx,xxx,"",5);
my $seneQuadralateAngle = lxq("user.value seneQuadralateAngle ?");
   $seneQuadralateAngle = $seneQuadralateAngle*($pi/180);	#convert angle to radian.
   $seneQuadralateAngle = cos($seneQuadralateAngle);		#convert radian to DP.

my $mainlayer = lxq("query layerservice layers ? main");
my %usedPolys;
my @foundEdges;

if (lxq("select.count polygon ?") > 0){
	lx("select.polygon remove vertex spatch 3");
	lx("select.polygon remove vertex {$selectPolygonArg} 2");
	lx("select.polygon remove vertex {$selectPolygonArg} 1");
}else{
	lx("select.polygon set vertex {$selectPolygonArg} 3");
}

my %selectedPolys;
my @polys = lxq("query layerservice polys ? selected");
$selectedPolys{$_} = 1 for @polys;

foreach my $poly (@polys){
	my @verts = lxq("query layerservice poly.vertList ? $poly");
	my @touchingTriPolys = ();
	my %touchingPolys = ();
	my $longestEdgeLength;
	my $longestEdge = 0;
	my $longestEdgePoly = -1;

	if ($usedPolys{$poly} != 1){
		for (my $i=0; $i<@verts; $i++){
			my @polyList = lxq("query layerservice edge.polyList ? (@verts[$i-1],@verts[$i])");
			foreach my $touchingPoly (@polyList){
				if (($touchingPoly != $poly) && ($selectedPolys{$touchingPoly} == 1) && ($usedPolys{$touchingPoly} != 1) && (lxq("query layerservice poly.numVerts ? $touchingPoly") == 3) && (lxq("query layerservice poly.material ? $poly") eq lxq("query layerservice poly.material ? $touchingPoly"))){
					#lxout("poly=$poly <> touchingPoly = $touchingPoly");
					my @normal1 = lxq("query layerservice poly.normal ? $touchingPoly");
					my @normal2 = lxq("query layerservice poly.normal ? $poly");
					my $dp = dotProduct(\@normal1,\@normal2);

					if ($dp > $seneQuadralateAngle){
						my $edgeLength = lxq("query layerservice edge.length ? (@verts[$i-1],@verts[$i])");
						if ($edgeLength > $longestEdgeLength){
							$longestEdgeLength = $edgeLength;
							$longestEdge = "(".@verts[$i-1].",".@verts[$i].")";
							$longestEdgePoly = $touchingPoly;
						}
					}
				}
			}
		}
		#lxout("-------longestEdge = $longestEdge");
		if ($longestEdgePoly != -1){
			$usedPolys{$longestEdgePoly} = 1;
			push(@foundEdges,$longestEdge);
		}
	}
}


if ($skipDiscoUVEdges == 1){ #pay attention to uvs and skip disco edges
	selectVmap();
	lx("select.drop edge");
	foreach my $edge (@foundEdges){
		my @polyList = lxq("query layerservice edge.polyList ? $edge");
		my @edgeUVValues1 = findEdgeUVValues($polyList[0],$edge);
		my @edgeUVValues2 = findEdgeUVValues($polyList[1],$edge);
		if ( ($edgeUVValues1[0] == $edgeUVValues2[0]) && ($edgeUVValues1[1] == $edgeUVValues2[1]) && ($edgeUVValues1[2] == $edgeUVValues2[2]) && ($edgeUVValues1[3] == $edgeUVValues2[3])){
			my @verts = split (/[^0-9]/, $edge);
			lx("select.element $mainlayer edge add @verts[1] @verts[2]");
		}
	}
}else{ #don't pay attention to disco edges.
	lx("select.drop edge");
	foreach my $edge (@foundEdges){
		my @verts = split (/[^0-9]/, $edge);
		lx("select.element $mainlayer edge add @verts[1] @verts[2]");
	}
}

if (@foundEdges > 0){lx("remove"); lx("select.type polygon");}





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



#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#FIND EDGE UV VALUES
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#usage : my @edgeUVValues = findEdgeUVValues($poly,$edge);
#note : (selectVmap has to have been run first)
#note : $edge has to be in this text format : (123,234);
sub findEdgeUVValues{
	my @vertList = lxq("query layerservice poly.vertList ? $_[0]");
	my @vmapValues = lxq("query layerservice poly.vmapValue ? $_[0]");
	my @edgeVerts = split(/[^0-9]/,$_[1]); #1,2 are the verts
	my $vmapValuesVertIndice1;
	my $vmapValuesVertIndice2;

	for (my $i=0; $i<@vertList; $i++){
		if ($vertList[$i] == $edgeVerts[1]){
			$vmapValuesVertIndice1 = $i;
		}elsif ($vertList[$i] == $edgeVerts[2]){
			$vmapValuesVertIndice2 = $i;
		}
	}

	return($vmapValues[$vmapValuesVertIndice1*2],$vmapValues[$vmapValuesVertIndice1*2+1],$vmapValues[$vmapValuesVertIndice2*2],$vmapValues[$vmapValuesVertIndice2*2+1]);
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

#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#SET UP THE USER VALUE OR VALIDATE IT   (no popups)
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
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

