#perl
#AUTHOR: Seneca Menard
#version 1.53
#This script is to import an object into your current scene.  There's three ways to use it.
# * You could load up one of the guis that I've built
# * Or you could append "useLoader" to the script, and that'll just load up the file browser window instead.  ie : "@importer.pl useLoader"
# * Or say you want to bind a hotkey to just import a specific model.  To do that and have it skip all the guis and load the model you're telling it to load, use the "skipWindow" cvar.  ie : "@importer.pl moveObject skipWindow W:\Rage\base\models\test\humanProportion.lwo"
#Also, if you want to move the newly imported geometry to the center of your viewport, just append "moveObject" to the script.  ie : "@importer.pl moveObject"
#Also, there's a new "lwoOnly" cvar added so you can tell the file dialog window to only display LWO files.

#(9-7-07 bugfix) : rewrote the uv map selection code.
#(10-3-07 bugfix) : i cancel the script if the file doesn't exist and put in senetemp safety check.
#(7-30-08 bugfix) : found a tiny bug with my check to see if the scene you're in has never been saved before.
#(1-29-09 bugfix) : it now restores visibility of the meshInstances as well.
#(2-12-09 feature) : if you want to bind a key to import a specific model (in which case, you won't need a gui), add this cvar to the hotkey to stop any windows from popping up : "skipWindow".  ie : "@importer.pl moveObject skipWindow W:\Rage\base\models\test\humanProportion.lwo"
#(1-20-11 feature) : "lwoOnly" cvar added so you can tell the file dialog window to only display LWO files.
#(1-10-14 fix) : got the actr storage system up to date with 601
#(8-10-14 fix) : the script now works in 801.

my $modoVer = lxq("query platformservice appversion ?");
my $mainScene = lxq("query sceneservice scene.index ? main");
my $sceneName = lxq("query sceneservice scene.name ? main");
my $sceneChanged = lxq("query sceneservice scene.changed ? main");

if (($sceneName =~ /Untitled/) && ($sceneChanged == 0)){	&alterScene;	}
my $mainlayer = lxq("query layerservice layers ? main");
my $mainlayerID = lxq("query layerservice layer.id ? $mainlayer");


#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#SCRIPT ARGUMENTS
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
foreach my $arg (@ARGV){
	if		($arg =~ ".lwo")		{	our $newObject = $arg;	}
	elsif	($arg eq "rel")			{	our $relScale = 1;		}
	elsif	($arg eq "useLoader")	{	our $loadFile = 1;		}
	elsif 	($arg eq "moveObject")	{	our $moveObject = 1;	}
	elsif	($arg eq "skipWindow")	{	our $skipWindow = 1;	}
	elsif	($arg eq "lwoOnly")		{	our $lwoOnly = 1;		}
}
if ((!defined $newObject) && ($loadFile != 1)){  die("Hmmm.  The script wasn't told to either import a specific model or use the loader,and so I'm cancelling the script");	}


#-----------------------------------------------------------------------------------
#REMEMBER SELECTION SETTINGS and then set it to selectauto  ((MODO6 FIX)) (modified to go to origin)
#-----------------------------------------------------------------------------------
#sets the ACTR preset
my $seltype;
my $selAxis;
my $selCenter;
my $actr = 1;

if   ( lxq( "tool.set actr.auto ?") eq "on")			{	$seltype = "actr.auto";			}
elsif( lxq( "tool.set actr.select ?") eq "on")			{	$seltype = "actr.select";		}
elsif( lxq( "tool.set actr.border ?") eq "on")			{	$seltype = "actr.border";		}
elsif( lxq( "tool.set actr.selectauto ?") eq "on")		{	$seltype = "actr.selectauto";	}
elsif( lxq( "tool.set actr.element ?") eq "on")			{	$seltype = "actr.element";		}
elsif( lxq( "tool.set actr.screen ?") eq "on")			{	$seltype = "actr.screen";		}
elsif( lxq( "tool.set actr.origin ?") eq "on")			{	$seltype = "actr.origin";		}
elsif( lxq( "tool.set actr.parent ?") eq "on")			{	$seltype = "actr.parent";		}
elsif( lxq( "tool.set actr.local ?") eq "on")			{	$seltype = "actr.local";		}
elsif( lxq( "tool.set actr.pivot ?") eq "on")			{	$seltype = "actr.pivot";		}
elsif( lxq( "tool.set actr.pivotparent ?") eq "on")		{	$seltype = "actr.pivotparent";	}

elsif( lxq( "tool.set actr.worldAxis ?") eq "on")		{	$seltype = "actr.worldAxis";	}
elsif( lxq( "tool.set actr.localAxis ?") eq "on")		{	$seltype = "actr.localAxis";	}
elsif( lxq( "tool.set actr.parentAxis ?") eq "on")		{	$seltype = "actr.parentAxis";	}

else
{
	$actr = 0;
	lxout("custom Action Center");
	
	if   ( lxq( "tool.set axis.auto ?") eq "on")		{	 $selAxis = "auto";				}
	elsif( lxq( "tool.set axis.select ?") eq "on")		{	 $selAxis = "select";			}
	elsif( lxq( "tool.set axis.element ?") eq "on")		{	 $selAxis = "element";			}
	elsif( lxq( "tool.set axis.view ?") eq "on")		{	 $selAxis = "view";				}
	elsif( lxq( "tool.set axis.origin ?") eq "on")		{	 $selAxis = "origin";			}
	elsif( lxq( "tool.set axis.parent ?") eq "on")		{	 $selAxis = "parent";			}
	elsif( lxq( "tool.set axis.local ?") eq "on")		{	 $selAxis = "local";			}
	elsif( lxq( "tool.set axis.pivot ?") eq "on")		{	 $selAxis = "pivot";			}
	else												{	 $actr = 1;  $seltype = "actr.auto"; lxout("You were using an action AXIS that I couldn't read");}

	if   ( lxq( "tool.set center.auto ?") eq "on")		{	 $selCenter = "auto";			}
	elsif( lxq( "tool.set center.select ?") eq "on")	{	 $selCenter = "select";			}
	elsif( lxq( "tool.set center.border ?") eq "on")	{	 $selCenter = "border";			}
	elsif( lxq( "tool.set center.element ?") eq "on")	{	 $selCenter = "element";		}
	elsif( lxq( "tool.set center.view ?") eq "on")		{	 $selCenter = "view";			}
	elsif( lxq( "tool.set center.origin ?") eq "on")	{	 $selCenter = "origin";			}
	elsif( lxq( "tool.set center.parent ?") eq "on")	{	 $selCenter = "parent";			}
	elsif( lxq( "tool.set center.local ?") eq "on")		{	 $selCenter = "local";			}
	elsif( lxq( "tool.set center.pivot ?") eq "on")		{	 $selCenter = "pivot";			}
	else												{ 	 $actr = 1;  $seltype = "actr.auto"; lxout("You were using an action CENTER that I couldn't read");}
}
lx("tool.set actr.origin on");





#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#MAIN ROUTINE
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

#find the viewport center if we wanna move the geo
if ($moveObject == 1){
	#Remember what the workplane was and turn it off  #SENECA
	our @WPmem;
	@WPmem[0] = lxq ("workPlane.edit cenX:? ");
	@WPmem[1] = lxq ("workPlane.edit cenY:? ");
	@WPmem[2] = lxq ("workPlane.edit cenZ:? ");
	@WPmem[3] = lxq ("workPlane.edit rotX:? ");
	@WPmem[4] = lxq ("workPlane.edit rotY:? ");
	@WPmem[5] = lxq ("workPlane.edit rotZ:? ");
	lx("workPlane.reset");

	my $view = lxq("query view3dservice mouse.view ?");
	our @viewCenter = lxq("query view3dservice view.center ? $view");
}

#use the file menu to import a model instead of the form gui
if ($loadFile == 1){
	lx("dialog.setup fileOpenMulti");
	if ($modoVer > 300){
		if ($lwoOnly == 1){	lx("dialog.fileTypeCustom format:[sml] username:[Model to load] loadPattern:[*.lwo] saveExtension:[lwo]");				}
		else{				lx("dialog.fileTypeCustom format:[sml] username:[Model to load] loadPattern:[*.lxo;*.lwo;*.obj] saveExtension:[lxo]");	}
	}else{
		lx("dialog.fileType scene");
	}
	lx("dialog.title [Select a model to import...]");
	lx("dialog.open");
	my @files = lxq("dialog.result ?");
	if (!defined @files[0]){	die("\n.\n[-------------------------------------------There was no file loaded, so I'm killing the script.---------------------------------------]\n[--PLEASE TURN OFF THIS WARNING WINDOW by clicking on the (In the future) button and choose (Hide Message)--] \n[-----------------------------------This window is not supposed to come up, but I can't control that.---------------------------]\n.\n");	}
	our $newObject = @files[0];
	if (($newObject !~ /\.obj/i) && ($newObject !~ /\.lwo/i) && ($newObject !~ /\.lxo/i)){die("\n.\n[---------------------The file you selected was not an LXO, LWO, or OBJ and so I'm killing the script.------------------------]\n[--PLEASE TURN OFF THIS WARNING WINDOW by clicking on the (In the future) button and choose (Hide Message)--] \n[-----------------------------------This window is not supposed to come up, but I can't control that.---------------------------]\n.\n");}
}

$newObject = platformSlashes($newObject);
if (-e $newObject)	{lx("!!scene.open {$newObject};");}
else				{die("Either the file doesn't exist or your drive isn't mapped properly and because I can't load it, I'm cancelling the script.");}
my $newScene = lxq("query sceneservice scene.index ? main");
lx("select.type polygon");
lx("select.copy");
lx("scene.set [$mainScene]");
lx("select.subItem {$mainlayerID} set mesh;meshInst;camera;light;txtrLocator;backdrop;groupLocator;replicator;surfGen;locator;deform;locdeform;deformGroup;deformMDD2;morphDeform;itemInfluence;genInfluence;deform.wrap;softLag;ABCdeform.sample;chanModify;chanEffect;defaultShader;defaultShader 0 0");

lx("!!select.drop polygon");
lx("!!select.editSet senetemp remove");
lx("!!select.invert");
lx("!!select.paste");
lx("!!select.invert");
lx("!!select.editSet senetemp add");

lx("!!scene.set [$newScene]");
lx("!!scene.close");
lx("!!scene.set [$mainScene]");
lx("!!select.subItem {$mainlayerID} set mesh;meshInst;camera;light;txtrLocator;backdrop;groupLocator;replicator;surfGen;locator;deform;locdeform;deformGroup;deformMDD2;morphDeform;itemInfluence;genInfluence;deform.wrap;softLag;ABCdeform.sample;chanModify;chanEffect;defaultShader;defaultShader 0 0");
lx("!!select.useSet senetemp select");
lx("!!select.editSet senetemp remove");
&selectVmap;

if ($relScale == 1){
	my $viewports = lxq("query view3dservice view.n ?");
	for (my $i=0; $i<$viewports; $i++){
		my $type = lxq("query view3dservice view.type ? $i");
		if ($type eq "MO3D"){
			our $viewport = $i;
			last;
		}
	}
	my $scale = lxq("query view3dservice view.scale ? $viewport");
	my @dimensions = lxq("query view3dservice view.rect ? $viewport");
	my $objectScale = @dimensions[2] * $scale * .01;

	lx("tool.viewType xyz");
	lx("tool.set xfrm.scale on");
	lx("tool.reset");
	lx("tool.setAttr xfrm.scale factor {$objectScale}");
	lx("tool.doApply");
	lx("tool.set xfrm.scale off");
}

if ($moveObject == 1){
	#move geo to viewCenter
	lx("!!tool.set xfrm.move on");
	lx("!!tool.reset");
	lx("!!tool.setAttr xfrm.move X {@viewCenter[0]}");
	lx("!!tool.setAttr xfrm.move Y {@viewCenter[1]}");
	lx("!!tool.setAttr xfrm.move Z {@viewCenter[2]}");
	lx("!!tool.doApply");
	lx("!!tool.set xfrm.move off");

	#Put the workplane back
	lx("!!workPlane.edit {@WPmem[0]} {@WPmem[1]} {@WPmem[2]} {@WPmem[3]} {@WPmem[4]} {@WPmem[5]}");
}




#now close the window  #(modo crashes every time....  bleh..)
#if (($modoVer > 300) && ($loadFile != 1) && ($skipWindow != 1)){lx("layout.createOrClose cookie:183 layout:importerCardLayout title:huh x:[800] y:[10] width:[1024] height:[1024] persistent:[0]");}



#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#CLEANUP
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#Set the action center settings back
if ($actr == 1) {	lx( "tool.set {$seltype} on" ); }
else { lx("tool.set center.$selCenter on"); lx("tool.set axis.$selAxis on"); }





















#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------SUBROUTINES--------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

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
#ALTER THE SCENE SO IT'S NOT NEW AND OVERWRITTEN SUB
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
sub alterScene{
	lxout("[->] I kept modo from overwriting this scene because it's name is 'Untitled' and had never been changed");
	lx("tool.set xfrm.move on");
	lx("tool.setAttr xfrm.move X [0 m]");
	lx("tool.setAttr xfrm.move Y [0 m]");
	lx("tool.setAttr xfrm.move Z [0 m]");
	lx("tool.doApply");
	lx("tool.set xfrm.move off");
}

#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#PLATFORMSLASHES SUB
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# eh
# used by validateGameDir clipNameFix and findTexture
sub platformSlashes{
	my $path = @_[0];
	if ($myPlatform eq "Win32") {
		$path =~ s/\//\\/g;
	} else {
		$path =~ s/\\/\//g;
	}
	return $path;
}

#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#POPUP SUB
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
sub popup #(MODO2 FIX)
{
	lx("dialog.setup yesNo");
	lx("dialog.msg {@_}");
	lx("dialog.open");
	my $confirm = lxq("dialog.result ?");
	if($confirm eq "no"){die;}
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#ADD THE INSTANCES TO THE BGLAYERS LIST SO THAT YOU CAN UNHIDE THEM WHEN THE SCRIPT'S DONE (ver 1.1)
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE : addInstancesToBGList(\@bgLayers);
sub addInstancesToBGList{
	my $items = lxq("query sceneservice item.n ? all");
	for (my $i=0; $i<$items; $i++){
		if (lxq("query sceneservice item.type ? $i") eq "meshInst"){
			my $id = lxq("query sceneservice item.id ? $i");
			my $visible = lxq("layer.setVisibility {$id} ?");
			if ($visible == 1){push (@{$_[0]},$id);}
		}
	}
}
