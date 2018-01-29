#perl
#ver 2.02
#author : Seneca Menard
#This script will look at all the currently visible layers (and instances) and hide all but the main.  When you run the script again, it'll unhide 'em again.

#SCRIPT ARGUMENTS :
# "onlyOneActiveLayer" : Say you have 5 visible background layers and 3 visible foreground layers and you don't want all the foreground layers visible.  You only want the "main" foreground layer visible.  Well, just run the script with this argument and it will hide all the other layers, including the active ones.  ie : "@layerHideAllToggle.pl onlyOneActiveLayer"
# *anything you type in* : if you type in any other words, it'll add that type to the list of items this script hides or not.  so if you wanna put bones in that list, just types in "locator" as an argument.

#(5-26-08 fix) : The script wasn't working completely properly plus instances and if you had a really large scene, the script would overflow the user.value so I'm now writing the visible objects to a text file instead of a user.value
#(1-31-09 fix) : The script wasn't keeping the additionally selected foreground layers selected.
#(1-31-08 feature) : There's now a script argument so that if you had 3 foreground layers selected and only want to see the "main" layer, you can use the script with this argument : "@layerHideAllToggle.pl onlyOneActiveLayer"
#(4-9-10 feature) : The script now hides static mesh items as well.
#(10-20-10 fix) : If current scene is not the same as the scene name that was written to the text file, it will now forcibly hide, so we shouldn't have to run the script twice in a row anymore.
#(6-27-14 feature) : i'm now stripping out "_####" from teh end of the filename so this script will still work after you use the SAVE INCREMENTAL feature...
#(2-10-15 fix) : fixed a syntax annoyance with queries returning errors when references are in teh scene

#==========================================================
#SETUP
#==========================================================
my $userDir = lxq("query platformservice path.path ? user");
my $textFile = $userDir."\\layerHideAllToggleTEMP.txt";
my $fileName = lxq("query sceneservice scene.name ? current");
$fileName =~ s/_[0-9]+\././;
my @fgLayers = lxq("query layerservice layers ? fg");
my @bgLayers = lxq("query layerservice layers ? bg");
my %types;	$types{"meshInst"} = 1;	$types{"triSurf"} = 1;
my @instances;

#==========================================================
#SCRIPT ARGUMENTS
#==========================================================
foreach my $arg (@ARGV){
	if ($arg eq "onlyOneActiveLayer")	{	our $onlyOnelayer = 1;	}
	else								{	$types{$arg} = 1;		}
}

#==========================================================
#ADD SPECIAL ITEMS TO HIDE LIST
#==========================================================
addInstancesToBGList(\@instances);

#==========================================================
#READ TEXT FILE
#==========================================================
my $string = "";
if (-e $textFile){
	open (FILE, "<$textFile") or die("I couldn't open the file : $textFile");
	while ($line = <FILE>){
		$string = $line;
		last;
	}
}
my @list = split(/<>/, $string);

#==========================================================
#MAIN
#==========================================================
if (($string eq "") || ($string eq "void")){
	hide();
}elsif (($fileName eq @list[0]) && (@list > 1)){
	show();
}else{
	hide();
}

#==========================================================
#HIDE ALL THE LAYERS BUT MAIN
#==========================================================
sub hide{
	#build list of layers to restore
	lxout("[->] : HIDING OBJECTS");
	my @foregroundList;
	my @backgroundList;
	for (my $i=1; $i<@fgLayers; $i++){
		my $id = lxq("query layerservice layer.id ? {$fgLayers[$i]}");
		push(@foregroundList,$id);
	}
	for (my $i=0; $i<@bgLayers; $i++){
		my $id = lxq("query layerservice layer.id ? {$bgLayers[$i]}");
		push(@backgroundList,$id);
	}
	for (my $i=0; $i<@instances; $i++){
		my $name = lxq("query sceneservice item.name ? {$instances[$i]}");
		push(@backgroundList,@instances[$i]);
	}

	#write out string and hide the layers
	if ((@foregroundList > 0) || (@backgroundList > 0)){
		$string = $fileName."<>";
	}
	foreach my $layer (@foregroundList){
		if ($onlyOnelayer == 1){
			lx("select.subItem [$layer] remove mesh;meshInst;camera;light;backdrop;groupLocator;locator;deform;locdeform 0 0");
			$string .= "fg:".$layer."<>";
			lx("layer.setVisibility [$layer] [0]");
		}
	}
	foreach my $layer (@backgroundList){
		lx("layer.setVisibility [$layer] [0]");
		$string .= "bg:".$layer."<>";
	}

	open (FILE, ">$textFile") or die("I couldn't open the file : $textFile");
	print FILE $string;
	close(FILE);
}

#==========================================================
#SHOW ALL THE LAYERS SPECIFIED IN THE USER VALUE
#==========================================================
sub show{
	lxout("[->] : SHOWING OBJECTS");
	lxout("[->] : the filename matches, so I'm going to try to restore layer visibility");
	for (my $i=1; $i<@list; $i++){
		if		(@list[$i] =~ /fg:/){
			@list[$i] =~ s/fg://;
			if (@list[$i] =~ /[a-z0-9]/i){
				lx("select.subItem {@list[$i]} add mesh;meshInst;camera;light;backdrop;groupLocator;locator;deform;locdeform 0 0");
				lx("layer.setVisibility {@list[$i]} [1]");
			}
		}elsif	(@list[$i] =~ /bg:/){
			@list[$i] =~ s/bg://;
			if (@list[$i] =~ /[a-z0-9]/i){lx("layer.setVisibility {@list[$i]} [1]");}
		}
	}

	open (FILE, ">$textFile") or die("I couldn't open the file : $textFile");
	print FILE "void";
	close(FILE);
}



#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#ADD THE INSTANCES TO THE BGLAYERS LIST SO THAT YOU CAN UNHIDE THEM WHEN THE SCRIPT'S DONE (ver 1.1) (modded to include static meshes)
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE : addInstancesToBGList(\@bgLayers);
sub addInstancesToBGList{
	my $items = lxq("query sceneservice item.n ? all");
	for (my $i=0; $i<$items; $i++){
		if ($types{lxq("query sceneservice item.type ? $i")} == 1){
			my $id = lxq("query sceneservice item.id ? $i");
			my $visible = lxq("layer.setVisibility {$id} ?");
			if ($visible == 1){push (@{$_[0]},$id);}
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


