#perl
#AUTHOR: Seneca Menard
#version 1.01
#This script is to toggle the selection of all polys with the same number of vertices as the one under the mouse so you don't
#have to open the INFO+STATS window in order to do that anymore.  Now you just point at a poly and fire the script.  So by default, if
#your mouse is over a 3point poly that's not selected, it will select all the 3point polys in the layer.  If it was already selected,
#it will deselect them.  If you only want to toggle the selection of the polys on the single mesh under the mouse, or the only meshes
#in the scene that already had some polys selected on them, there's some script arguments for that:

#SCRIPT ARGUMENTS
#1) "thisMesh" : This will only toggle the polys on the mesh under the mouse.
#2) "allSelectedMeshes" : This will only toggle the polys on the meshes in the current layer that already had some of their polys selected.

#(3-25-11 fix) : 501 sp2 had an annoying syntax change.  grrr.




#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#SCRIPT ARGUMENTS
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
foreach my $arg (@ARGV){
	if		($arg =~ /thisMesh/i)			{	our $thisMesh = 1;	}
	elsif	($arg =~ /allSelectedMeshes/i)	{	our $allMesh = 1;	}
}



#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#SETUP
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
my $modoBuild = lxq("query platformservice appbuild ?");
if ($modoBuild > 41320){our $selectPolygonArg = "psubdiv";}else{our $selectPolygonArg = "curve";}
my $poly = lxq("query view3dservice element.over ? POLY");
my @poly = split(/,/, $poly);
my $mainlayer = @poly[0]+1;
my $layerName = lxq("query layerservice layer.name ? $mainlayer");
my $selected = lxq("query layerservice poly.selected ? @poly[1]");
my $vertCount = lxq("query layerservice poly.numVerts ? @poly[1]");
if ($selected == 0)	{	our $selType = "add";		}
else				{	our $selType = "remove";	}


#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#MAIN ROUTINE
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
if (($thisMesh == 1) || ($allMesh == 1)){
	if ($thisMesh == 1){
		lxout("[->] Running ONLY THIS MESH routine");
		&listTouchingPolys2(@poly[1]);
	}else{
		lxout("[->] Running ALL SELECTED MESHES routine");
		my @polys = lxq("query layerservice polys ? selected");
		&listTouchingPolys2(@polys);
	}
	foreach my $poly (keys %totalPolyList){
		my $verts = lxq("query layerservice poly.numVerts ? $poly");
		if ($verts == $vertCount){
			lx("select.element $mainlayer polygon $selType $poly");
		}
	}
}

else{
	lxout("[->] Running SELECT ALL routine");
	lxout("selType = $selType");
	lxout("vertCount = $vertCount");
	lx("select.polygon $selType vertex {$selectPolygonArg} {$vertCount}");
}









#=====================================================================================================================================
#=====================================================================================================================================
#=====================================================================================================================================
#=====================================================================================================================================
#===																 SUBROUTINES													==
#=====================================================================================================================================
#=====================================================================================================================================
#=====================================================================================================================================
#=====================================================================================================================================



#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#OPTIMIZED SELECT TOUCHING POLYGONS sub
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



