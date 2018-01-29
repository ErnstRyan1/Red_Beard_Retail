#perl
#this script is for halving or doubling the scale of the selected items

foreach my $arg (@ARGV){
	if ($arg =~ /halve/i)	{our $halve = 1;}
}

my @selection = lxq("query sceneservice selection ? all");
my %itemTypes;
	$itemTypes{mesh} = 1;
	$itemTypes{meshInst} = 1;
	$itemTypes{triSurf} = 1;
	$itemTypes{groupLocator} = 1;
	$itemTypes{backdrop} = 1;

foreach my $id (@selection){
	my $type = lxq("query sceneservice item.type ? {$id}");
	if ($itemTypes{$type} == 1){
		my $transformScaleID = lxq("query sceneservice item.xfrmScl ? {$id}");
		if ($transformScaleID eq ""){
			lxout("adding");
			lx("!!transform.add type:{scl} item:{$id} pos:{post} adv:{1}");
			$transformScaleID = lxq("query sceneservice item.xfrmScl ? {$id}");

		}
		lxout("transformScaleID = $transformScaleID");
		my $scaleX = lxq("item.channel scl.X {?} set {$transformScaleID}");
		my $scaleY = lxq("item.channel scl.Y {?} set {$transformScaleID}");
		my $scaleZ = lxq("item.channel scl.Z {?} set {$transformScaleID}");

		if ($halve == 1){
			$scaleX *= .75;
			$scaleY *= .75;
			$scaleZ *= .75;
		}else{
			$scaleX *= 1.5;
			$scaleY *= 1.5;
			$scaleZ *= 1.5;
		}

		lx("item.channel scl.X {$scaleX} set {$transformScaleID}");
		lx("item.channel scl.Y {$scaleY} set {$transformScaleID}");
		lx("item.channel scl.Z {$scaleZ} set {$transformScaleID}");
	}
}
