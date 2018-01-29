#perl
#ver 0.51
#author : Seneca Menard

#This script will instance your background layers to the centers of the currently selected elements

#(3-2-12 fix) : 601 changed item.duplicate syntax so it's now updated

lxout("eh?");
srand;
my $percentage = quickDialog("Percentage of elems to use?",percent,100,0,1);
my @bgLayers = lxq("query layerservice layers ? bg");
my @bgLayerIDs;
my @meshInstIDs;
for (my $i=0; $i<@bgLayers; $i++){ @bgLayerIDs[$i] = lxq("query layerservice layer.id ? $bgLayers[$i]"); }
my $mainlayer = lxq("query layerservice layers ? main");
my $mainlayerID = lxq("query layerservice layer.id ? $mainlayer");
my %posTable;



#build position table for all verts, edges or polys in scene
if (lxq( "select.typeFrom {vertex;edge;polygon;item} ?" )){
	if (lxq("select.count vertex ? ") == 0){lx("select.all");}
	my @verts = lxq("query layerservice verts ? selected");
	foreach my $vert (@verts){ @{$posTable{$vert}} = lxq("query layerservice vert.pos ? $vert"); }
}
elsif (lxq( "select.typeFrom {edge;polygon;item;vertex} ?" )){
	if (lxq("select.count edge ? ") == 0){lx("select.all");}
	my @edges = lxq("query layerservice edges ? selected");
	foreach my $edge (@edges){ @{$posTable{$edge}} = lxq("query layerservice edge.pos ? $edge"); }
}
elsif (lxq( "select.typeFrom {polygon;item;vertex;edge} ?" )){
	if (lxq("select.count polygon ? ") == 0){lxout("yes nothing's selected"); lx("select.all");}
	my @polys = lxq("query layerservice polys ? selected");
	foreach my $poly (@polys){ @{$posTable{$poly}} = lxq("query layerservice poly.pos ? $poly"); }
}
else{
	die("You're not in vert, edge, or poly mode and so i'm cancelling the script");
}


#now instance geometry to those positions.
foreach my $key (keys %posTable){
	if (rand*1 <= $percentage){
		my $itemID = @bgLayerIDs[int(($#bgLayers + 0.5) * rand)];
		lxout("itemID = $itemID");

		lx("select.subItem {$itemID} set mesh;triSurf;meshInst;camera;light;backdrop;groupLocator;replicator;locator;deform;locdeform;chanModify;chanEffect 0 0");
		lx("item.duplicate instance:[1] type:[locator]");
		push(@meshInstIDs , lxq("query sceneservice selection ? meshInst"));

		my $rot = int(3.5 * rand);
		my $rotAmount = 90 * $rot;
		lx("transform.channel pos.X {@{$posTable{$key}}[0]}");
		lx("transform.channel pos.Y {@{$posTable{$key}}[1]}");
		lx("transform.channel pos.Z {@{$posTable{$key}}[2]}");
		if ($rot != 0){lx("transform.channel rot.Y {$rotAmount}");}
	}
}

#now put all the new instances in a group and parent it to mainlayer
lx("select.drop item");
lx("select.subItem {$_} add mesh;triSurf;meshInst;camera;light;backdrop;groupLocator;replicator;locator;deform;locdeform;chanModify;chanEffect 0 0") for @meshInstIDs;
lx("layer.groupSelected");
my $groupID = lxq("query sceneservice selection ? groupLocator");
lx("item.parent {$groupID} {$mainlayerID} 0 inPlace:1");
lx("select.subItem {$mainlayerID} set mesh;triSurf;meshInst;camera;light;backdrop;groupLocator;replicator;locator;deform;locdeform;chanModify;chanEffect 0 0");



#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#PRINT ALL THE ELEMENTS IN A HASH TABLE FULL OF ARRAYS
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#usage : printHashTableArray(\%table,table);
sub printHashTableArray{
	lxout("          ------------------------------------Printing @_[1] list------------------------------------");
	my $hash = @_[0];
	foreach my $key (sort keys %{$hash}){
		lxout("          KEY = $key");
		for (my $i=0; $i<@{$$hash{$key}}; $i++){
			lxout("             $i = @{$$hash{$key}}[$i]");
		}
	}
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#QUICK DIALOG SUB
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE : quickDialog(username,float,initialValue,min,max);
sub quickDialog{
	if (@_[1] eq "yesNo"){
		lx("dialog.setup yesNo");
		lx("dialog.msg {@_[0]}");
		lx("dialog.open");
		if (lxres != 0){	die("The user hit the cancel button");	}
		return (lxq("dialog.result ?"));
	}else{
		if (lxq("query scriptsysservice userValue.isdefined ? seneTempDialog") == 0){
			lxout("-The seneTempDialog cvar didn't exist so I just created one");
			lx("user.defNew name:[seneTempDialog] life:[temporary]");
		}
		lx("user.def seneTempDialog username [@_[0]]");
		lx("user.def seneTempDialog type [@_[1]]");
		if ((@_[3] != "") && (@_[4] != "")){
			lx("user.def seneTempDialog min [@_[3]]");
			lx("user.def seneTempDialog max [@_[4]]");
		}
		lx("user.value seneTempDialog [@_[2]]");
		lx("user.value seneTempDialog ?");
		if (lxres != 0){	die("The user hit the cancel button");	}
		return(lxq("user.value seneTempDialog ?"));
	}
}