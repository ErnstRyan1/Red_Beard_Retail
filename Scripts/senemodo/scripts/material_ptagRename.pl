#perl
#author : Seneca Menard
#This script looks at the ptag on the first poly and does a ptag rename in all layers

#============================================
#type in the ptag name you wish to replace
#============================================
my $mainlayer = lxq("query layerservice layers ? main");
my @polys = lxq("query layerservice polys ? selected") or die("You must have a polygon selected in order to run the script.");
my @ptags = lxq("query layerservice poly.tags ? @polys[0]");
my $ptagName = quickDialog("ptag name to replace:",string,@ptags[0],"","");

#============================================
#go thru all layers and change the poly material names
#============================================
my @layers = lxq("query layerservice layers ? all");
my @fgLayers = lxq("query layerservice layers ? fg");
my @bgLayers = lxq("query layerservice layers ? bg");
foreach my $layer (@layers){
	my $layerID = lxq("query layerservice layer.id ? $layer");
	lx("select.subItem [$layerID] set mesh;meshInst;camera;light;txtrLocator;backdrop;groupLocator [0] [1]");
	lx("poly.renameMaterial {@ptags[0]} {$ptagName}");
}

#============================================
#restore the original layer visibilites
#============================================

#FG LAYERS-------
for (my $i=0; $i<@fgLayers; $i++){
	my $layerID = lxq("query layerservice layer.id ? @fgLayers[$i]");
	if ($i == 0){	lx("select.subItem [$layerID] set mesh;meshInst;camera;light;txtrLocator;backdrop;groupLocator [0] [1]");	}
	else{			lx("select.subItem [$layerID] add mesh;meshInst;camera;light;txtrLocator;backdrop;groupLocator [0] [1]");	}
}

#BG LAYERS-------
foreach my $layer (@bgLayers){
	my $layerID = lxq("query layerservice layer.id ? $layer");
	lx("layer.setVisibility [$layerID] [-1] [1]");
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
