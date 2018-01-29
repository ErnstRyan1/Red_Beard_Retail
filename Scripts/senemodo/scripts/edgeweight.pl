#perl
#AUTHOR: Seneca Menard
#version 2.2
#This script is for applying edge weighting.  If you don't have a weightmap selected, then it'll select the subd weightmap for you.  If you want the tool to be interactive, then just run the script as usual. If you want the script to set the weight to a specific amount and then turn off the weight tool, just run the script with a numeric argument appended.  ie : "@edgeweight.pl 95"

#arguments :
# any number : If you want the tool to be interactive, then just run the script as usual. If you want the script to set the weight to a specific amount and then turn off the weight tool, just run the script with a numeric argument appended.  ie : "@edgeweight.pl 95" or "@edgeweight.pl 0"


my $mainlayer = lxq("query layerservice layers ? main");
my @weightMaps = lxq("query layerservice vmaps ? weight");
my $weightMapSelected = 0;
my $cvar = "void";
if (@ARGV > 0){$cvar = @ARGV[0];}

#remember tool
rememberTool();

#find selected vmap
foreach my $weightMap (@weightMaps){
	lxout("weightMap = $weightMap");
	if (lxq("query layerservice vmap.selected ? $weightMap") == 1){
		lxout("-There was a weightmap already selected, so I'm keeping it selected");
		$weightMapSelected = 1;
	}
}

#desel rgb weightmaps
my @rgbMaps = lxq("query layerservice vmaps ? rgb");
foreach my $indice (@rgbMaps){
	if (lxq("query layerservice vmap.selected ? $indice") == 1){
		my $name = lxq("query layerservice vmap.name ? $indice");
		lx("select.vertexMap type:{rgb} name:{$name} mode:{remove}");
	}
}

#desel rgba weightmaps
my @rgbaMaps = lxq("query layerservice vmaps ? rgba");
foreach my $indice (@rgbaMaps){
	if (lxq("query layerservice vmap.selected ? $indice") == 1){
		my $name = lxq("query layerservice vmap.name ? $indice");
		lx("select.vertexMap type:{rgba} name:{$name} mode:{remove}");
	}
}

#only select "subdivision" if no vmaps are selected.
if ($weightMapSelected == 0){	lx("select.vertexMap Subdivision subd replace");	}

#turn on the weightmap tool
lx("tool.set vertMap.setWeight on");

#if user entered a cvar, apply that specific weighting and turn off the tool.
if ($cvar ne "void"){
	lx("tool.setAttr vertMap.setWeight weight [$cvar %]");
	lx("tool.doApply");
	lx("select.nextMode");
	lx("tool.set vertMap.setWeight off");
}

#turn tool back on
if ($restoreTool == 1) {lx("tool.set $tool on");}


#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#REMEMBER TOOL SUB
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
sub rememberTool{
	if		(lxq( "tool.set xfrm.move ?") eq "on")			{	our $tool = "xfrm.move";			our $restoreTool = 1;		}
	elsif	(lxq("tool.set xfrm.rotate ?") eq "on")			{	our $tool = "xfrm.rotate";			our $restoreTool = 1;		}
	elsif 	(lxq("tool.set xfrm.stretch ?") eq "on")		{	our $tool = "xfrm.stretch";			our $restoreTool = 1;		}
	elsif 	(lxq("tool.set xfrm.scale ?") eq "on")			{	our $tool = "xfrm.scale";			our $restoreTool = 1;		}
	elsif	(lxq("tool.set Transform ?") eq "on")			{	our $tool = "Transform";			our $restoreTool = 1; 		}
	elsif	(lxq("tool.set TransformMove ?") eq "on")		{	our $tool = "TransformMove";		our $restoreTool = 1;		}
	elsif	(lxq("tool.set TransformRotate ?") eq "on")		{	our $tool = "TransformRotate";		our $restoreTool = 1;		}
	elsif	(lxq("tool.set TransformScale ?") eq "on")		{	our $tool = "TransformScale";		our $restoreTool = 1;		}
	elsif	(lxq("tool.set TransformUScale ?") eq "on")		{	our $tool = "TransformUScale";		our $restoreTool = 1;		}
}
