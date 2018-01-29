#perl
#ver 2.0
#author : Seneca Menard
#This script will create a new layer and parent it to the group you have selected or the parent of the item you currently have selected.

#(6-13-09 fix) : the script was creating a new item, but breaking it's rotation order pulldown because of the item.parent command.  That's now fixed.
#(2-29-12 feature) : the script now creates a new layer at the position after your currently selected item in the item list.  so it won't end up at the bottom anymore thank god.

my %itemTypes;
	$itemTypes{"mesh"} = 1;
	$itemTypes{"meshInst"} = 1;
	$itemTypes{"triSurf"} = 1;
	$itemTypes{"groupLocator"} = 1;
	$itemTypes{"locator"} = 1;
	$itemTypes{"camera"} = 1;
	$itemTypes{"sunLight"} = 1;
	$itemTypes{"pointLight"} = 1;
	$itemTypes{"spotLight"} = 1;
	$itemTypes{"photometryLight"} = 1;
	$itemTypes{"domeLight"} = 1;
	$itemTypes{"cylinderLight"} = 1;
	$itemTypes{"areaLight"} = 1;

my $parent = "";
my $lastSelID;
my @selection = lxq("query sceneservice selection ? all");

for (my $i=$#selection; $i>-1; $i--){
	if ($itemTypes{lxq("query sceneservice item.type ? {$selection[$i]}")} == 1){
		$lastSelID = $selection[$i];
		$parent = lxq("query sceneservice item.parent ? {$selection[$i]}");
		last;
	}
}

if ($parent ne ""){
	my $orderInGroup = 0;
	my @children = lxq("query sceneservice item.children ? {$parent}");
	for (my $i=0; $i<@children; $i++){
		if ($children[$i] eq $lastSelID){
			$orderInGroup = $i + 1;
			last;
		}
	}

	lx("item.create mesh");
	my @meshes = lxq("query sceneservice selection ? mesh");
	lx("item.parent {$meshes[-1]} {$parent} {$orderInGroup}");
}elsif ($lastSelID ne ""){
	my $itemListPos = lxq("query sceneservice item.rootIndex ? {$lastSelID}") + 1;
	lx("item.create mesh");
	my @meshes = lxq("query sceneservice selection ? mesh");
	my $currentItemListPos = lxq("query sceneservice item.rootIndex ? {$meshes[-1]}");
	lx("layer.move $currentItemListPos $itemListPos 0");
}else{
	lx("item.create mesh");
}



