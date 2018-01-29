#perl
#ver 1.0
#author : Seneca Menard

#This script is for showing/hiding/selecting/deslecting items of a specific type in the item list window. (it's commands are in the sen_popup_itemList form)

foreach my $arg (@ARGV){
	if		($arg =~ /select/i)		{	our $selMode = "add";		}
	elsif	($arg =~ /deselect/i)	{	our $selMode = "remove";	}
	elsif	($arg =~ /hide/i)		{	our $visibility = 0;		}
	elsif 	($arg =~ /show/i)		{	our $visibility = 1;		}
	elsif	($arg =~ /selNoneElse/i){	our $selNoneElse = 1;		}
	else							{	our $itemType = $arg;		}
}

lxout("itemType = $itemType");
my $runCount = 0;
my @itemSelection = lxq("query sceneservice selection ? all");
foreach my $item (@itemSelection){
	my @children = lxq("query sceneservice item.children ? $item");
	if (@children > 0){push(@itemSelection,@children);}

	my $type = lxq("query sceneservice item.type ? $item");
	lxout("type = $type");
	if ($selMode ne ""){
		if ($type eq $itemType){
			if ($runCount == 0){
				lx("select.drop item");
				$runCount = 1;
			}
			lx("!!select.subItem {$item} {$selMode} mesh;triSurf;meshInst;camera;light;backdrop;groupLocator;replicator;locator;deform;locdeform;chanModify;chanEffect 0 0");
		}
	}elsif ($visibility != -1){
		if ($type eq $itemType){
			lx("layer.setVisibility {$item} $visibility");
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
