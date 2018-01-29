#perl
#ver 1.1
#author : Seneca Menard

#This script will instance the first selected mesh or meshInst to all the other meshes or meshInsts that are selected while having their translations transferred.

#(3-2-12 fix) : 601 changed item.duplicate syntax so it's now updated

my @selection = lxq("query sceneservice selection ? locator");
my @items;
my $itemType;

foreach my $item (@selection){
	my $type = lxq("query sceneservice item.type ? $item");
	if (($type eq "mesh") || ($type eq "meshInst")){
		push(@items,$item);
		if ($itemType eq ""){$itemType = $type;}
	}
}

for (my $i=1; $i<@items; $i++){
	lx("select.subItem {@items[0]} set mesh;meshInst;camera;light;backdrop;groupLocator;locator;deform;locdeform 0 0");
	if ($itemType eq "mesh")		{lx("item.duplicate instance:[1]");}
	elsif ($itemType eq "meshInst")	{lx("item.duplicate instance:[0]");}
	else{die("The first item wasn't a mesh or mesh instance");}
	my @currentItems = lxq("query sceneservice selection ? locator");
	lx("item.parent @currentItems[-1] @items[$i] 0 inPlace:0");
}


sub popup #(MODO2 FIX)
{
	lx("dialog.setup yesNo");
	lx("dialog.msg {@_}");
	lx("dialog.open");
	my $confirm = lxq("dialog.result ?");
	if($confirm eq "no"){die;}
}
