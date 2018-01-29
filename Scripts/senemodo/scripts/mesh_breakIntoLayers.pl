#perl
#ver 1.2
#author : Seneca Menard
#This script looks at what polys are currently selected and breaks them into seperate meshes based off of what polygons are touching each other or by {polygon part selection groups}

#CREATE TEMP LAYER
my $initialLayerID = lxq("query layerservice layer.id ? main");
lx("select.cut");
lx("item.create mesh");
lx("select.paste");
my $deleteMesh = lxq("query sceneservice selection ? mesh");

my $mainlayer = lxq("query layerservice layers ? main");
my $mainlayerID = lxq("query layerservice layer.id ? $mainlayer");
my $centerItem = popupMultChoice("Center Geometry?","none;X;Y;Z;XZ;XY;YZ;XYZ;rest on ground;center rest on ground",0);
my $selectByPart = quickDialog("Select by Part?",boolean,0,"","");
my $meshName = quickDialog("Mesh names:",string,"Mesh","","");  if ($meshName eq ""){$meshName = "Mesh";}
my $newGroupName = quickDialog("Name for the new group:",string,"Group","","");
my @meshList;

while (1){
	lx("select.subItem [$mainlayerID] set mesh;meshInst;camera;light;backdrop;groupLocator;locator;deform [0] [0]");
	lx("select.element $mainlayer polygon add 0");
	if (lxres != 0){
		last;
	}

	my $layerName = lxq("query layerservice layer.name ? $deleteMesh");
	my @polys = lxq("query layerservice polys ? selected");
	if (@polys < 1){last;}
	lx("select.element $mainlayer polygon set @polys[0]");

	if ($selectByPart == 1){
		my @ptags = lxq("query layerservice poly.tags ? 0");
		if (@ptags[1] ne "Default"){
			lx("select.polygon add part face @ptags[1]");
		}else{
			lx("select.connect");
		}
	}else{
		lx("select.connect");
	}
	lx("select.cut");
	lx("item.create mesh");
	lx("item.name {$meshName}");
	lx("select.paste");
	if ($centerItem ne "none"){
		if     ($centerItem eq "X"){
			lx("vert.center x");
		}elsif ($centerItem eq "Y"){
			lx("vert.center y");
		}elsif ($centerItem eq "Z"){
			lx("vert.center z");
		}elsif ($centerItem eq "XZ"){
			lx("vert.center zx");
		}elsif ($centerItem eq "XY"){
			lx("vert.center xy");
		}elsif ($centerItem eq "YZ"){
			lx("vert.center yz");
		}elsif ($centerItem eq "XYZ"){
			lx("vert.center all");
		}elsif ($centerItem eq "rest on ground"){
			lx("tool.set actr.auto on");
			my @bbox = lxq("query layerservice layer.bounds ? main");
			my $dist = @bbox[1] * -1;
			lx("tool.set TransformMove on");
			lx("tool.reset");
			lx("tool.setAttr xfrm.transform TY {$dist}");
			lx("tool.doApply");
			lx("tool.set TransformMove off");
		}elsif ($centerItem eq "center rest on ground"){
			lx("vert.center zx");
			my @bbox = lxq("query layerservice layer.bounds ? main");
			my $dist = @bbox[1] * -1;
			lx("tool.set TransformMove on");
			lx("tool.reset");
			lx("tool.setAttr xfrm.transform TY {$dist}");
			lx("tool.doApply");
			lx("tool.set TransformMove off");
		}else{
			die("You selected a center option outside the bounds. (Only 0-9 are allowed)");
		}
	}

	my @meshes = lxq("query sceneservice selection ? mesh");
	push(@meshList,@meshes[0]);
}

lx("select.drop item");
foreach my $item (@meshList){
	lx("select.subItem [$item] add mesh;meshInst;camera;light;backdrop;groupLocator;locator;deform [0] [0]");
}
lx("layer.groupSelected");
lx("item.name $newGroupName");

#now delete the mesh
lx("!!select.subItem [$deleteMesh] set mesh;meshInst;camera;light;backdrop;groupLocator;locator;deform [0] [0]");
lx("!!delete");

#if no polys in initial layer, delete that too.
my $initialLayerName = lxq("query layerservice layer.name ? $initialLayerID");
if (lxq("query layerservice poly.n ? all") == 0){
	lx("!!select.subItem {$initialLayerID} set mesh;meshInst;triSurf;gear.item;RPC.Mesh;camera;light;backdrop;groupLocator;replicator;deform;locdeform;chanModify;chanEffect 0 0");
	lx("!!delete");
	our $deleteInitialLayer = 1;
}

#restore original layer visibility
if ($deleteInitialLayer == 0){
	lx("select.subItem [$initialLayerID] set mesh;meshInst;camera;light;backdrop;groupLocator;locator;deform [0] [0]");
	lx("select.type polygon");
}
foreach my $item (@meshList){
	lx("select.subItem [$item] add mesh;meshInst;camera;light;backdrop;groupLocator;locator;deform [0] [0]");
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

##------------------------------------------------------------------------------------------------------------
##------------------------------------------------------------------------------------------------------------
#POPUP MULTIPLE CHOICE (ver 3) (forces return of your word choice because modo sometimes would return a number instead of word)
##------------------------------------------------------------------------------------------------------------
##------------------------------------------------------------------------------------------------------------
#USAGE : my $answer = popupMultChoice("question name","yes;no;maybe;blahblah",$defaultChoiceInt);
sub popupMultChoice{
	if (lxq("query scriptsysservice userValue.isdefined ? seneTempDialog2") == 1){lx("user.defDelete {seneTempDialog2}");	}
	lx("user.defNew name:[seneTempDialog2] type:[integer] life:[momentary]");
	lx("user.def seneTempDialog2 username [$_[0]]");
	lx("user.def seneTempDialog2 list {$_[1]}");
	lx("user.value seneTempDialog2 {$_[2]}");

	lx("user.value seneTempDialog2");
	if (lxres != 0){	die("The user hit the cancel button");	}
	
	my $answer = lxq("user.value seneTempDialog2 ?");
	if ($answer =~ /[^0-9]/){
		return($answer);
	}else{
		my @guiTextArray = split (/\;/, $_[1]);
		return($guiTextArray[$answer]);
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

