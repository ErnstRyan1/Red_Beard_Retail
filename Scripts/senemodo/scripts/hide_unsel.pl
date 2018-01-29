#perl
#ver 1.33
#author : Seneca Menard

#This script is to hide all of your selection that's not selected and the only diff between this and modo's default is that it'll unhide your mesh's parents if they were hidden as well.
#(2-12-10 feature) : also, it now ignores the "Texture Group" group, because changing the visibility of that is ridiculously slow on large scenes. (oh, and it only pays attention to meshes, meshInstances, lights, and groupLocators, btw)
#(11-2-10 fix) : put in a {} fix for item names
#(9-29-12 feature) : the script doesn't hide lights now unless you run it with the "hideLights" argument.

#script arguments :
# forceItemSel : this will force the script to unhide items and not mesh data.  Handy so you can be in vert selection mode, but fire this script from the item view window and it'll unhide items as you expect
# unhideChildren : this will unhide all the children of the currently selected items.  The script normally only unhides the children of groupLocators only.
# hideLights : this will hide lights as well.

foreach my $arg (@ARGV){
	if		($arg eq "forceItemSel")	{	our $forceItemSel = 1;		}
	elsif	($arg eq "unhideChildren")	{	our $unhideChildren = 1;	}
	elsif	($arg eq "hideLights")		{	our $hideLights = 1;		}
}

my %itemTypes;
	$itemTypes{"mesh"} = 1;
	$itemTypes{"meshInst"} = 1;
	$itemTypes{"triSurf"} = 1;
	if ($hideLights == 1){
		$itemTypes{"light"} = 1;
		$itemTypes{"sunLight"} = 1;
		$itemTypes{"pointLight"} = 1;
		$itemTypes{"spotLight"} = 1;
		$itemTypes{"areaLight"} = 1;
		$itemTypes{"cylinderLight"} = 1;
		$itemTypes{"domeLight"} = 1;
		$itemTypes{"photometryLight"} = 1;
	}
	$itemTypes{"locator"} = 1;
	$itemTypes{"replicator"} = 1;


if ( ((lxq("select.typeFrom {vertex;edge;polygon;item} ?")) || (lxq("select.typeFrom {edge;polygon;item;vertex} ?")) || (lxq("select.typeFrom {polygon;item;vertex;edge} ?"))) && ($forceItemSel != 1) ){
	lx("hide.unsel");
}else{
	my $itemCount = lxq("query sceneservice item.n ? all");
	for (my $i=0; $i<$itemCount; $i++){
		my $itemType = lxq("query sceneservice item.type ? $i");
		if ($itemTypes{$itemType} == 1){
			my $id = lxq("query sceneservice item.id ? $i");
			my $selected = lxq("query sceneservice item.isSelected ? $i");
			if (lxq("query sceneservice item.isSelected ? $i") == 1)	{	lx("layer.setVisibility {$id} 1");	}
			else														{	lx("layer.setVisibility {$id} 0");	}
		}elsif ($itemType eq "groupLocator"){
			my $name = lxq("query sceneservice item.name ? $i");
			if ($name =~ /texture group/i){next;}
			my $id = lxq("query sceneservice item.id ? $i");
			if (lxq("query sceneservice item.isSelected ? $i") == 1)	{	lx("layer.setVisibility {$id} 1");	}
			else														{	lx("layer.setVisibility {$id} 0");	}
		}
	}

	my @selection = lxq("query sceneservice selection ? all");
	showParents(\@selection);
	if ($unhideChildren == 1){
		showChildren(\@selection);
	}else{
		my @groupLocators;
		foreach my $item (@selection){
			if (lxq("query sceneservice item.type ? {$item}") eq "groupLocator"){
				push(@groupLocators,$item);
			}
		}
		if (@groupLocators > 0){showChildren(\@groupLocators);}
	}

}


##------------------------------------------------------------------------------------------------------------
##------------------------------------------------------------------------------------------------------------
##SHOW CHILDREN SUB
##------------------------------------------------------------------------------------------------------------
##------------------------------------------------------------------------------------------------------------
sub showChildren{
	my @items = @{$_[0]};

	while (1){
		my @children;
		foreach my $item (@items){
			my @itemChildren = lxq("query sceneservice item.children ? {$item}");
			push(@children,@itemChildren);
			foreach my $child (@itemChildren){ lx("layer.setVisibility {$child} 1"); lxout("child = $child");}
		}

		if (@children == 0){
			last;
		}else{
			@items = @children;
		}
	}
}


##------------------------------------------------------------------------------------------------------------
##------------------------------------------------------------------------------------------------------------
##SHOW PARENTS SUB
##------------------------------------------------------------------------------------------------------------
##------------------------------------------------------------------------------------------------------------
#usage : showParents(\@items);
sub showParents{
	my @parentUnhideList;
	my @selection = @{$_[0]};
	while (1){
		my @parents;
		foreach my $item (@selection){
			my $parent = lxq("query sceneservice item.parent ? {$item}");
			if ($parent ne ""){
				lx("layer.setVisibility {$parent} 1");
				push(@parents,$parent);
			}
		}

		if ($#parents < 0){
			last;
		}else{
			@selection = @parents;
		}
	}
}


##------------------------------------------------------------------------------------------------------------
##------------------------------------------------------------------------------------------------------------
##POPUP SUB
##------------------------------------------------------------------------------------------------------------
##------------------------------------------------------------------------------------------------------------
sub popup #(MODO2 FIX)
{
	lx("dialog.setup yesNo");
	lx("dialog.msg {@_}");
	lx("dialog.open");
	my $confirm = lxq("dialog.result ?");
	if($confirm eq "no"){die;}
}
