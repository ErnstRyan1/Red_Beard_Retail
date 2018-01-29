#perl
#author : Seneca Menard
#ver 1.03

#This script will select the PARENTS, CHILDREN, or SIBLINGS of the selected items.  By default, it selects PARENTS. To select either the SIBLINGS or CHILDREN, you must type in the specific script argument.

#arguments :
#selectChildren" : This will select all the CHILDREN items of the current item(s) you have selected.
#selectSiblings" : This will select all the SIBLING items (ie, the other items that share the same PARENTS as the ones you currently have selected.

#(7-8-11 fix) : select siblings had a silly little error
#(4-12-15 fix) : put in {} symbols to fix syntax errors with complex item names




if (@ARGV[0] =~ /selectSiblings/i)		{our $selectSiblings = 1;}
elsif (@ARGV[0] =~ /selectChildren/i)	{our $selectChildren = 1;}

my @items = lxq("query sceneservice selection ? locator");
foreach my $item (@items){
	my $parent = lxq("query sceneservice item.parent ? {$item}");
	if ($selectChildren == 0){
		lxout("parent = $parent");
		if ($selectSiblings == 1){
			lxout("[->] selecting brother(s)");
			my @children = lxq("query sceneservice item.children ? {$parent}");
			foreach my $child (@children){
				lx("select.subItem {$child} add mesh;meshInst;camera;light;backdrop;groupLocator;locator;deform [0] [0]");
			}
		}elsif ($parent ne ""){
			lxout("[->] selecting parent(s)");
			lx("select.subItem {$parent} add mesh;meshInst;camera;light;backdrop;groupLocator;locator;deform [0] [0]");
			lx("select.subItem {$item} remove mesh;meshInst;camera;light;backdrop;groupLocator;locator;deform [0] [0]");
			lx("layer.setVisibility item:{$parent} visible:[1] recur:[0]");
		}else{
			lxout("not selecting parent because there didn't appear to be one");
		}
	}elsif ($selectChildren == 1){
			lxout("[->] selecting children");
			my @children = lxq("query sceneservice item.children ? {$item}");
			foreach my $child (@children){lx("select.subItem {$child} add mesh;meshInst;camera;light;backdrop;groupLocator;locator;deform [0] [0]");}
			lx("select.subItem {$item} remove mesh;meshInst;camera;light;backdrop;groupLocator;locator;deform [0] [0]");
	}
}




#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#POPUP SUB
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
sub popup #(MODO2 FIX)
{
	lx("dialog.setup yesNo");
	lx("dialog.msg {@_}");
	lx("dialog.open");
	my $confirm = lxq("dialog.result ?");
	if($confirm eq "no"){die;}
}
