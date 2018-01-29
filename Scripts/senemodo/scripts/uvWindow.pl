#perl
#AUTHOR: Seneca Menard
#version 1.2
#This script was made because I load up UV the window all the time and was getting sick and tired of having to select the UV map over and over.

#-It opens a UV window
#-It automatically selects the UV map for you.
#-It frames the UVs for you. (only works if you're converting a viewport.  doesn't work with popup windows because that command queriest the viewport your mouse is over and popup windows don't always show up under your mouse.)

#SCRIPT ARGUMENTS :
# convert : if you don't want to popup a window, but use the one under your mouse, use this.  ie : @uvWindow.pl convert
# <layoutName> : if you want to load your own layout, then use this argument.  ie, @uvWindow.pl senecaUVLayout

#CHANGES :
#(1-3-07) : put in custom senUVWindow code (just for me)
#(9-7-07) : rewrote UV map selection code
#(7-11-11): it's not forced to use hardcoded layouts anymore.


#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#SCRIPT ARGUMENTS
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
foreach my $arg (@ARGV){
	if ($arg eq "convert")	{	our $convert = 1;		}
	else					{	our $layout = $arg;		}
}


#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#MAIN FUNCTIONS
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
my $mainlayer = lxq("query layerservice layers ? main");
&selectVmap;
&createWindow;


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
#LOAD UP THE WINDOW NOW.
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
sub createWindow{
	#CONVERT WINDOW
	if ($convert == 1){
		lx("select.viewport fromMouse:1");
		if ($layout ne ""){
			lx("layout.restore {$layout} 1");
		}else{
			lx("viewport.restore [UV Single] [0] vpgroup");
		}
		lx("tool.viewType UV");
		lx("viewport.fitSelected");
	}
	#POPUP NEW WINDOW
	else{
		if ($layout ne ""){
			my $layoutCount1 = lxq("layout.count ?");
			lx("layout.createOrClose cookie:[6] layout:[$layout] title:[UV Window (UVmap = $name)] x:[810] y:[5] width:[1200] height:[480] persistent:[1]");
			my $layoutCount2 = lxq("layout.count ?");
			if ($layoutCount2 > $layoutCount1){
				lx("tool.viewType UV");
			}
		}else{
			my $layoutCount1 = lxq("layout.count ?");
			lx("layout.createOrClose cookie:[6] title:[UV Window (UVmap = $name)] width:[600] height:[400] persistent:[1]");
			my $layoutCount2 = lxq("layout.count ?");
			if ($layoutCount2 > $layoutCount1){
				lx("viewport.restore [UV Single] [0] vpgroup");
				lx("tool.viewType UV");
			}
		}
	}
}