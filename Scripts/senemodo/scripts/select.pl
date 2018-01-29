#perl
#AUTHOR: Seneca Menard
#version 1.1
#Thiis script is to batch select or deselect elements or items by type.
#To install it (on windows):
# : copy the .PL and .CFG to this dir : C:\Documents and Settings\{username}\Application Data\Luxology\Scripts
# : open up the form editor : toolbar-->system-->Form editor
# : scroll down to the "sen_Select form and right click on it and choose "Assign to key" and you're all set.

my $modoVer = lxq("query platformservice appversion ?");
my $mainlayer = lxq("query layerservice layers ? main");
my @types;

foreach my $arg (@ARGV){
	if		($arg eq "only")		{	our $mode = "only";																			}
	elsif	($arg eq "add")			{	our $mode = "add";																			}
	elsif	($arg eq "remove")		{	our $mode = "remove";																		}
	elsif	($arg eq "allLights")	{	@types = (sunLight,pointLight,areaLight,cylinderLight,photometryLight,domeLight,spotLight);	}
	else							{	push(@types,$arg);																			}
}

my $items = lxq("query sceneservice item.n ?");
lxout("items = $items");
lxout("types = @types");


#========================================================
#========================================================
#SETUP
#========================================================
#========================================================
if ($mode eq "only"){
	$mode = "add";
	&selectDropAll;
}

#========================================================
#========================================================
#ELEMENTS
#========================================================
#========================================================
if ((@types[0] eq "vertex") || (@types[0] eq "edge") || (@types[0] eq "polygon")){
	lxout("[->] RAW ELEMENTS");
	lx("select.type @types[0]");
	if ($mode eq "add"){
		if ($modoVer < 300){
			lx("!!select.drop @types[0]");
			lx("!!select.invert");
		}else{
			lx("!!select.all");
		}
	}else{
		lx("!!select.drop @types[0]");
	}
}

#========================================================
#========================================================
#ITEMS
#========================================================
#========================================================
else{
	lxout("[->] ITEMS");
	my @items;

	for (my $i=0; $i<$items; $i++){
		lxout("$i");
		my $type = lxq("query sceneservice item.type ? $i");
		lxout("type = $type");
		foreach my $checkType (@types){
			if ($type eq $checkType){
				my $id = lxq("query sceneservice item.id ? $i");
				push(@items,$id);
				lxout("deselecting $type <> about to fire LAST");
				last;
			}
		}
	}

	foreach my $id (@items){
		lx("!!select.subItem [$id] $mode mesh;meshInst;camera;light;txtrLocator;backdrop;groupLocator [0] [0]");
	}
}



sub selectDropAll{
	lx("!!select.drop vertex");
	lx("!!select.drop edge");
	lx("!!select.drop polygon");
	lx("!!select.drop polygon");
	lx("!!select.drop item");
}